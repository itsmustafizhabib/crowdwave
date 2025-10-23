import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import '../../../services/otp_service.dart';

/// Email verification screen shown after sign-up
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final OTPService _otpService = OTPService();
  final TextEditingController _otpController = TextEditingController();

  String email = '';
  String userId = '';

  bool _isLoading = false;
  bool _isVerified = false;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();

    // Get arguments from navigation
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      email = args['email'] as String? ?? _auth.currentUser?.email ?? '';
      userId = args['userId'] as String? ?? _auth.currentUser?.uid ?? '';
    } else {
      email = _auth.currentUser?.email ?? '';
      userId = _auth.currentUser?.uid ?? '';
    }

    // Send initial OTP
    _sendInitialOTP();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  // Send initial OTP when screen loads
  Future<void> _sendInitialOTP() async {
    try {
      await _otpService.sendSignUpVerificationOTP(email);
      _showSnackbar(
        'Code Sent!',
        'We\'ve sent a 6-digit code to $email',
        isSuccess: true,
      );
    } catch (e) {
      _showSnackbar(
        'Error',
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  // Handle successful verification
  void _onVerificationSuccess() {
    setState(() => _isVerified = true);

    // Show success message
    _showSnackbar(
      'Email Verified!',
      'Your email has been verified successfully.',
      isSuccess: true,
    );

    // Navigate to main app after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Get.offAllNamed('/main-navigation');
      }
    });
  }

  // Manually check if email is verified
  Future<void> _manualCheckVerification() async {
    setState(() => _isLoading = true);

    try {
      // Reload user to get latest verification status
      await _auth.currentUser?.reload();

      final user = _auth.currentUser;

      if (user?.emailVerified == true) {
        _onVerificationSuccess();
      } else {
        _showSnackbar(
          'Not Verified Yet',
          'Please check your email and click the verification link first.',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackbar(
        'Error',
        'Failed to check verification status: ${e.toString()}',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Resend verification email
  Future<void> _resendVerificationEmail() async {
    if (_resendCountdown > 0) return;

    setState(() => _isLoading = true);

    try {
      // Send verification email through Firebase
      await _auth.currentUser?.sendEmailVerification();

      _startResendCountdown();

      _showSnackbar(
        'Email Sent!',
        'A new verification email has been sent to $email',
        isSuccess: true,
      );
    } catch (e) {
      _showSnackbar(
        'Error',
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Start countdown for resend button
  void _startResendCountdown() {
    setState(() => _resendCountdown = 60);

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() => _resendCountdown--);
        return _resendCountdown > 0;
      }
      return false;
    });
  }

  // Sign out and go back
  Future<void> _signOutAndGoBack() async {
    await _auth.signOut();
    Get.offAllNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _signOutAndGoBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: _signOutAndGoBack,
          ),
          title: Text('profile.verify_email'.tr(),
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Email animation
                Lottie.asset(
                  'assets/animations/wave.json',
                  height: 200,
                  width: 200,
                  repeat: true,
                ),

                const SizedBox(height: 30),

                // Title
                Text(
                  _isVerified ? 'Email Verified!' : 'Check Your Email',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _isVerified ? Colors.green : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 15),

                // Subtitle
                Text(
                  _isVerified
                      ? 'Your email has been verified successfully!'
                      : 'We\'ve sent a verification email to:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 10),

                // Email display
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    email,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 30),

                // Instructions
                if (!_isVerified) ...[
                  _buildInstructionCard(
                    icon: Icons.email,
                    title: 'auth.check_inbox'.tr(),
                    description:
                        'Open the verification email we sent you (check spam folder too)',
                  ),
                  const SizedBox(height: 12),
                  _buildInstructionCard(
                    icon: Icons.link,
                    title: 'auth.click_link'.tr(),
                    description: 'kyc.click_the_verification_link_in_the_email_to_verify'.tr(),
                  ),
                  const SizedBox(height: 12),
                  _buildInstructionCard(
                    icon: Icons.check_circle,
                    title: 'You\'re all set!',
                    description:
                        'Once verified, you\'ll be automatically redirected',
                  ),
                ],

                const SizedBox(height: 40),

                // Verification status indicator
                if (!_isVerified)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFF008080),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFF008080)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF008080)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('kyc.waiting_for_verification'.tr(),
                            style: TextStyle(
                              color: Color(0xFF008080),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 30),

                // Action buttons
                if (!_isVerified) ...[
                  // Check verification button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _manualCheckVerification,
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        _isLoading ? 'Checking...' : 'I\'ve Verified, Continue',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Resend email button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _resendCountdown > 0 || _isLoading
                          ? null
                          : _resendVerificationEmail,
                      icon: const Icon(Icons.mail_outline),
                      label: Text(
                        _resendCountdown > 0
                            ? 'Resend in ${_resendCountdown}s'
                            : 'Resend Verification Email',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.deepPurple,
                        side: const BorderSide(color: Colors.deepPurple),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Sign out button
                  TextButton(
                    onPressed: _signOutAndGoBack,
                    child: Text('auth.sign_out_and_try_again'.tr(),
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.deepPurple,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String title, String message,
      {bool isSuccess = false, bool isError = false}) {
    Color backgroundColor;
    IconData iconData;

    if (isError) {
      backgroundColor = Colors.red.shade600;
      iconData = Icons.error_outline;
    } else if (isSuccess) {
      backgroundColor = Colors.green.shade600;
      iconData = Icons.check_circle_outline;
    } else {
      backgroundColor = Color(0xFF008080);
      iconData = Icons.info_outline;
    }

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      icon: Icon(
        iconData,
        color: Colors.white,
        size: 28,
      ),
      shouldIconPulse: false,
      duration: const Duration(seconds: 4),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
    );
  }
}
