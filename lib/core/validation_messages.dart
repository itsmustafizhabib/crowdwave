class ValidationMessages {
  // Email validation
  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Please enter your email address';
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // Password validation with user-friendly messages
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Please create a password';
    }

    List<String> issues = [];

    if (password.length < 8) {
      issues.add('at least 8 characters');
    }
    if (password.length > 20) {
      issues.add('maximum 20 characters');
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      issues.add('one uppercase letter');
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      issues.add('one lowercase letter');
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      issues.add('one number');
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      issues.add('one special character');
    }

    if (issues.isNotEmpty) {
      return 'Your password needs: ${issues.join(', ')}';
    }

    return null;
  }

  // Name validation
  static String? validateName(String? name, {String fieldName = 'Name'}) {
    if (name == null || name.trim().isEmpty) {
      return 'Please enter your $fieldName';
    }

    if (name.trim().length < 2) {
      return '$fieldName must be at least 2 characters long';
    }

    if (name.trim().length > 50) {
      return '$fieldName cannot be longer than 50 characters';
    }

    return null;
  }

  // Phone number validation
  static String? validatePhoneNumber(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return 'Please enter your phone number';
    }

    // Remove all non-digit characters for validation
    String digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.length < 10) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  // Package description validation
  static String? validatePackageDescription(String? description) {
    if (description == null || description.trim().isEmpty) {
      return 'Please describe what you\'re sending';
    }

    if (description.trim().length < 10) {
      return 'Please provide more details about your package (at least 10 characters)';
    }

    if (description.trim().length > 500) {
      return 'Description is too long (maximum 500 characters)';
    }

    return null;
  }

  // Location validation
  static String? validateLocation(dynamic location, String locationType) {
    if (location == null) {
      return 'Please select your $locationType location';
    }
    return null;
  }

  // Compensation validation
  static String? validateCompensation(double? amount) {
    if (amount == null || amount <= 0) {
      return 'Please set a fair compensation amount';
    }

    if (amount > 1000) {
      return 'Compensation amount seems too high. Please verify';
    }

    return null;
  }

  // Generic required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}
