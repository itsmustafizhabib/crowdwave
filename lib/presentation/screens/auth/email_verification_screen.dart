import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import '../../../services/otp_service.dart';
import '../../../routes/app_routes.dart';

/// Email verification screen with OTP input
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

  // Verify OTP code
  Future<void> _verifyOTP() async {
    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      _showSnackbar('Error', 'Please enter the verification code',
          isError: true);
      return;
    }

    if (otp.length != 6) {
      _showSnackbar('Error', 'Code must be 6 digits', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Verify OTP
      await _otpService.verifyEmailVerificationOTP(email, otp);

      // Reload user to update verification status
      await _auth.currentUser?.reload();

      setState(() => _isLoading = false);

      _onVerificationSuccess();
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar(
        'Verification Failed',
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  // Resend verification OTP
  Future<void> _resendVerificationOTP() async {
    if (_resendCountdown > 0) return;

    setState(() => _isLoading = true);

    try {
      await _otpService.resendVerificationOTP(email);

      _startResendCountdown();

      _showSnackbar(
        'Code Sent!',
        'A new 6-digit code has been sent to $email',
        isSuccess: true,
      );
    } catch (e) {
      _showSnackbar(
        'Error',
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }

    setState(() => _isLoading = false);
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
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
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
        body: Column(
          children: [
            // Wave animation positioned at the top like login screen
            Lottie.asset(
              'assets/animations/wave.json',
              height: size.height * 0.2,
              width: size.width,
              fit: BoxFit.fill,
            ),

            // Content below the animation
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      _isVerified ? 'Email Verified!' : 'Verify Your Email',
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
                          : 'Enter the 6-digit code sent to:',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 10),

                    // Email display
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
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

                    const SizedBox(height: 40),

                    // OTP Input
                    if (!_isVerified) ...[
                      // Instructions
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF008080),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(0xFF008080)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Color(0xFF008080)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Check your email for the 6-digit code (check spam folder if needed)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // OTP TextField
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          hintText: '------',
                          hintStyle: TextStyle(
                            fontSize: 32,
                            color: Colors.grey.shade300,
                            letterSpacing: 8,
                          ),
                          counterText: '',
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.deepPurple,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          // Auto-submit when 6 digits entered
                          if (value.length == 6) {
                            _verifyOTP();
                          }
                        },
                      ),

                      const SizedBox(height: 30),

                      // Verify Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _verifyOTP,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text('common.verify_code'.tr(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Resend button
                      TextButton.icon(
                        onPressed: _resendCountdown > 0 || _isLoading
                            ? null
                            : _resendVerificationOTP,
                        icon: const Icon(Icons.refresh),
                        label: Text(
                          _resendCountdown > 0
                              ? 'Resend code in ${_resendCountdown}s'
                              : 'Didn\'t receive code? Resend',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Help text
                      Text(
                        'Code expires in 10 minutes',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),

                      const SizedBox(height: 30),

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
          ],
        ),
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
