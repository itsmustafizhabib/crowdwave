import 'package:flutter/material.dart';
import '../core/validation_messages.dart';
import '../widgets/enhanced_snackbar.dart';

class FormValidatorHelper {
  /// Validates and shows appropriate error for email field
  static String? validateEmailField(String? value) {
    return ValidationMessages.validateEmail(value);
  }

  /// Validates and shows appropriate error for password field
  static String? validatePasswordField(String? value) {
    return ValidationMessages.validatePassword(value);
  }

  /// Validates and shows appropriate error for name field
  static String? validateNameField(String? value, {String fieldName = 'Name'}) {
    return ValidationMessages.validateName(value, fieldName: fieldName);
  }

  /// Validates and shows appropriate error for phone field
  static String? validatePhoneField(String? value) {
    return ValidationMessages.validatePhoneNumber(value);
  }

  /// Shows a user-friendly error message with context
  static void showFormError(
      BuildContext context, String fieldName, String? error) {
    if (error != null) {
      EnhancedSnackBar.showError(context, error);
    }
  }

  /// Validates entire form and shows first error found
  static bool validateForm(
    BuildContext context,
    GlobalKey<FormState> formKey, {
    String? email,
    String? password,
    String? confirmPassword,
    String? fullName,
    String? phoneNumber,
  }) {
    // First check FormState validation
    if (!formKey.currentState!.validate()) {
      EnhancedSnackBar.showError(context, 'Please fix the highlighted fields');
      return false;
    }

    // Additional custom validations
    if (password != null &&
        confirmPassword != null &&
        password != confirmPassword) {
      EnhancedSnackBar.showError(context, 'Passwords do not match');
      return false;
    }

    return true;
  }

  /// Creates a validator function for TextFormField
  static String? Function(String?)? createValidator(String fieldType) {
    switch (fieldType.toLowerCase()) {
      case 'email':
        return ValidationMessages.validateEmail;
      case 'password':
        return ValidationMessages.validatePassword;
      case 'fullname':
      case 'name':
        return (value) =>
            ValidationMessages.validateName(value, fieldName: 'Full name');
      case 'phone':
      case 'phonenumber':
        return ValidationMessages.validatePhoneNumber;
      case 'required':
        return (value) =>
            ValidationMessages.validateRequired(value, 'This field');
      default:
        return null;
    }
  }
}
