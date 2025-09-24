import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../services/firebase_auth_service.dart';
import '../../../core/error_handler.dart';
import '../../../core/theme/app_colors.dart';

class PasswordResetWithCodeView extends StatefulWidget {
  const PasswordResetWithCodeView({Key? key}) : super(key: key);

  @override
  State<PasswordResetWithCodeView> createState() =>
      _PasswordResetWithCodeViewState();
}

class _PasswordResetWithCodeViewState extends State<PasswordResetWithCodeView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final FirebaseAuthService _authService = Get.find<FirebaseAuthService>();

  bool _isLoading = false;
  bool _isCodeSent = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  int _resendCountdown = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Send password reset code
  Future<void> _sendResetCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Send password reset email
      await _authService.sendPasswordResetEmail(_emailController.text.trim());

      setState(() {
        _isCodeSent = true;
        _isLoading = false;
      });

      _startResendCountdown();

      _showSnackbar('Code Sent!',
          'Password reset code has been sent to ${_emailController.text}',
          isSuccess: true);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar('Error', ErrorHandler.getReadableError(e), isError: true);
    }
  }

  // Verify code and reset password
  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Confirm password reset with code
      await _authService.confirmPasswordReset(
          _codeController.text.trim(), _newPasswordController.text.trim());

      setState(() => _isLoading = false);

      _showSnackbar('Success!',
          'Your password has been reset successfully. You can now sign in with your new password.',
          isSuccess: true);

      // Navigate to login after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        Get.offAllNamed('/login');
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar('Error', ErrorHandler.getReadableError(e), isError: true);
    }
  }

  // Resend reset code
  Future<void> _resendCode() async {
    if (_resendCountdown > 0) return;

    setState(() => _isLoading = true);

    try {
      await _authService.sendPasswordResetEmail(_emailController.text.trim());
      _startResendCountdown();
      _showSnackbar(
          'Code Resent!', 'A new reset code has been sent to your email.',
          isSuccess: true);
    } catch (e) {
      _showSnackbar('Error', ErrorHandler.getReadableError(e), isError: true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Reset Password',
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const SizedBox(height: 20),
                Center(
                  child: Icon(
                    _isCodeSent ? Icons.lock_reset : Icons.email,
                    size: 80,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),

                Center(
                  child: Text(
                    _isCodeSent ? 'Enter Reset Code' : 'Reset Your Password',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Center(
                  child: Text(
                    _isCodeSent
                        ? 'Enter the 6-digit code sent to your email and create a new password'
                        : 'Enter your email address and we\'ll send you a reset code',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Email field (always visible but disabled after code is sent)
                _buildEmailField(),

                if (_isCodeSent) ...[
                  const SizedBox(height: 20),
                  _buildCodeField(),
                  const SizedBox(height: 20),
                  _buildNewPasswordField(),
                  const SizedBox(height: 20),
                  _buildConfirmPasswordField(),
                  const SizedBox(height: 12),
                  _buildResendCodeButton(),
                ],

                const SizedBox(height: 32),

                // Main action button
                _buildActionButton(),

                if (!_isCodeSent) ...[
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: Text(
                        'Back to Sign In',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
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

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      enabled: !_isCodeSent,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Email Address',
        hintText: 'Enter your email',
        prefixIcon: const Icon(Icons.email_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!GetUtils.isEmail(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildCodeField() {
    return TextFormField(
      controller: _codeController,
      keyboardType: TextInputType.number,
      maxLength: 6,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: 8,
      ),
      decoration: InputDecoration(
        labelText: 'Reset Code',
        hintText: '000000',
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter the reset code';
        }
        if (value.length != 6) {
          return 'Code must be 6 digits';
        }
        return null;
      },
    );
  }

  Widget _buildNewPasswordField() {
    return TextFormField(
      controller: _newPasswordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: 'New Password',
        hintText: 'Enter new password',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() => _isPasswordVisible = !_isPasswordVisible);
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a new password';
        }
        if (value.length < 8) {
          return 'Password must be at least 8 characters';
        }
        if (!RegExp(
                r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]')
            .hasMatch(value)) {
          return 'Password must contain uppercase, lowercase, number, and special character';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: !_isConfirmPasswordVisible,
      decoration: InputDecoration(
        labelText: 'Confirm New Password',
        hintText: 'Confirm new password',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(
                () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please confirm your new password';
        }
        if (value != _newPasswordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Widget _buildResendCodeButton() {
    return Center(
      child: TextButton(
        onPressed: _resendCountdown > 0 ? null : _resendCode,
        child: Text(
          _resendCountdown > 0
              ? 'Resend code in ${_resendCountdown}s'
              : 'Resend code',
          style: TextStyle(
            color: _resendCountdown > 0 ? Colors.grey : AppColors.primary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed:
            _isLoading ? null : (_isCodeSent ? _resetPassword : _sendResetCode),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : Text(
                _isCodeSent ? 'Reset Password' : 'Send Reset Code',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  void _showSnackbar(String title, String message,
      {bool isError = false, bool isSuccess = false}) {
    Color backgroundColor;
    IconData iconData;

    if (isError) {
      backgroundColor = Colors.red.shade600;
      iconData = Icons.error_outline;
    } else if (isSuccess) {
      backgroundColor = Colors.green.shade600;
      iconData = Icons.check_circle_outline;
    } else {
      backgroundColor = Colors.blue.shade600;
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
      forwardAnimationCurve: Curves.easeOutBack,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          spreadRadius: 1,
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}
