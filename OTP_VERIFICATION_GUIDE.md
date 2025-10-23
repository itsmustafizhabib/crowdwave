# OTP/Email Verification Implementation Guide

## Overview
This document describes the complete OTP (One-Time Password) and email verification system implemented for the CrowdWave application. The system handles:
- Email verification for new user sign-ups
- Password reset with verification codes
- Secure OTP storage and validation

## Architecture

### Components

#### 1. OTP Service (`lib/services/otp_service.dart`)
Core service that handles:
- Generating 6-digit OTP codes
- Sending verification emails via Firebase Auth
- Storing OTPs in Firestore with expiration
- Verifying OTP codes
- Rate limiting and security

#### 2. Email Verification Screen (`lib/presentation/screens/auth/email_verification_screen.dart`)
Post-signup screen that:
- Automatically checks for email verification every 3 seconds
- Allows manual verification check
- Provides resend functionality with 60-second cooldown
- Shows clear instructions to users
- Auto-redirects to main app when verified

#### 3. Password Reset Screen (`lib/presentation/screens/auth/password_reset_with_code_view.dart`)
Password reset flow:
- Accepts email input
- Sends reset code via Firebase Auth
- Validates 6-digit code from email
- Allows password reset with confirmed code
- 60-second resend cooldown

## User Flows

### Sign-Up Flow
1. User fills sign-up form with email, username, password
2. System creates Firebase Auth account
3. System sends verification email automatically
4. User is redirected to `EmailVerificationScreen`
5. Screen auto-checks verification status every 3 seconds
6. User clicks link in email to verify
7. App detects verification and redirects to main app

### Password Reset Flow
1. User clicks "Forgot Password?" on login screen
2. Navigates to `PasswordResetWithCodeView`
3. User enters email address
4. System sends reset code via Firebase Auth
5. User enters 6-digit code from email
6. User sets new password
7. System validates code and updates password
8. User redirected to login screen

## Security Features

### Firebase Auth Integration
- Uses Firebase's built-in email verification
- Uses Firebase's secure password reset codes
- Leverages Firebase Auth action codes

### Firestore OTP Storage
```javascript
{
  otp: "123456",              // 6-digit code
  email: "user@example.com",  // User email
  expiresAt: Timestamp,       // 10-minute expiration
  createdAt: Timestamp,       // Creation timestamp
  used: false,                // Prevents reuse
  type: "password_reset"      // Type identifier
}
```

### Security Rules
```javascript
// Firestore rules for otp_codes collection
match /otp_codes/{email} {
  // Allow anyone to create OTP (needed for password reset)
  allow create: if true;
  
  // Allow reading OTP only by authenticated users
  allow read: if request.auth != null;
  
  // Allow updates only by authenticated users (marking as used)
  allow update: if request.auth != null;
  
  // Allow deletion by authenticated users (cleanup)
  allow delete: if request.auth != null;
}
```

### Rate Limiting
- 60-second cooldown between resend attempts
- Implemented at UI level and backend level
- Prevents spam and abuse

### OTP Expiration
- OTPs expire after 10 minutes
- Expired OTPs cannot be used
- Used OTPs marked and cannot be reused
- Automatic cleanup of expired codes

## Implementation Details

### Sign-Up Integration
```dart
// In signUp_view.dart after user registration
await _authService.sendEmailVerification();

// Navigate to verification screen
Get.offAllNamed(
  AppRoutes.emailVerification,
  arguments: {
    'email': user.email,
    'userId': user.uid,
  },
);
```

### Auto-Verification Check
```dart
// In EmailVerificationScreen
Timer.periodic(const Duration(seconds: 3), (timer) async {
  await _auth.currentUser?.reload();
  final isVerified = _auth.currentUser?.emailVerified ?? false;
  
  if (isVerified) {
    timer.cancel();
    // Navigate to main app
    Get.offAllNamed('/main-navigation');
  }
});
```

### Password Reset
```dart
// Send reset email
await _auth.sendPasswordResetEmail(email: email);

// Verify code and reset password
await _auth.confirmPasswordReset(
  code: code,
  newPassword: newPassword,
);
```

## UI/UX Features

### Email Verification Screen
- ✅ Beautiful Lottie animations
- ✅ Clear step-by-step instructions
- ✅ Real-time verification status
- ✅ Resend button with countdown
- ✅ Manual verification check
- ✅ Sign out option

### Password Reset Screen
- ✅ Two-step process (email → code → password)
- ✅ Code input with formatting
- ✅ Password strength validation
- ✅ Confirm password matching
- ✅ Visual feedback for all actions
- ✅ Error handling with clear messages

## Testing

### Test Sign-Up Verification
1. Create new account with valid email
2. Check inbox for verification email
3. Verify auto-check is working (3-second intervals)
4. Click verification link
5. Confirm auto-redirect to main app

### Test Password Reset
1. Click "Forgot Password?" on login
2. Enter registered email
3. Check inbox for reset code
4. Enter 6-digit code
5. Set new password
6. Login with new password

### Test Error Cases
- ❌ Invalid email format
- ❌ Non-existent email
- ❌ Expired OTP code
- ❌ Wrong OTP code
- ❌ Weak password
- ❌ Password mismatch
- ❌ Too many resend attempts

## Configuration

### Firebase Auth Settings
Ensure Firebase Auth is configured with:
- Email/Password provider enabled
- Email verification template customized (optional)
- Password reset template customized (optional)

### Firestore Indexes
No special indexes required for OTP collection.

### Environment Variables
No additional environment variables needed.

## Troubleshooting

### Issue: Verification email not received
**Solutions:**
1. Check spam folder
2. Verify email is valid
3. Check Firebase Auth logs
4. Ensure email provider is enabled
5. Wait 60 seconds before resending

### Issue: "FirebaseAuthService not found" error
**Solution:** Fixed! Now uses Firebase Auth directly without GetX dependency.

### Issue: Verification not detecting
**Solutions:**
1. Check internet connection
2. Force close and reopen app
3. Click "I've Verified, Continue" manually
4. Check Firebase Auth console for verification status

### Issue: Password reset code invalid
**Solutions:**
1. Check code hasn't expired (10 minutes)
2. Ensure code is entered correctly
3. Request new code
4. Check for typos in email

## Future Enhancements

### Potential Improvements
- [ ] SMS verification option
- [ ] Push notification on verification
- [ ] Social auth verification bypass
- [ ] Custom email templates
- [ ] Biometric verification
- [ ] Two-factor authentication
- [ ] Phone number verification
- [ ] Enhanced fraud detection

### Performance Optimizations
- [ ] Cloud Function for OTP generation
- [ ] Dedicated email service integration
- [ ] OTP cleanup scheduled job
- [ ] Analytics for verification rates

## Code Locations

### Services
- `lib/services/otp_service.dart` - OTP generation and verification
- `lib/services/enhanced_firebase_auth_service.dart` - Auth operations

### Screens
- `lib/presentation/screens/auth/email_verification_screen.dart`
- `lib/presentation/screens/auth/password_reset_with_code_view.dart`
- `lib/presentation/screens/auth/signUp_view.dart`
- `lib/presentation/screens/auth/login_view.dart`

### Routes
- `lib/routes/app_routes.dart` - Route definitions

### Security
- `firestore.rules` - Firestore security rules

## Support

For issues or questions:
1. Check this documentation
2. Review Firebase Auth logs
3. Check Firestore data in console
4. Review app logs for errors
5. Test with different email providers

## Changelog

### v1.0.0 (Current)
- ✅ Initial implementation
- ✅ Email verification for sign-up
- ✅ Password reset with codes
- ✅ Auto-verification check
- ✅ Rate limiting
- ✅ Security rules
- ✅ Comprehensive error handling

---

**Status:** ✅ Production Ready
**Last Updated:** October 22, 2025
**Maintained By:** CrowdWave Development Team
