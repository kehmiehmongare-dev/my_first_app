class Validators {
  // Email validation - blocks fake/temporary emails
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Please enter email';

    final blockedDomains = [
      'tempmail.com',
      '10minutemail.com',
      'guerrillamail.com',
      'mailinator.com',
      'yopmail.com',
      'throwaway.com',
      'fakeinbox.com',
      'temp-mail.org',
      'mailnator.com'
    ];
    final domain = value.split('@').last.toLowerCase();
    if (blockedDomains.contains(domain)) {
      return 'Please use a real email address, not temporary email';
    }

    final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.(com|co\.ke|ac\.ke|org|net|edu|info|biz)$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email (e.g., name@gmail.com or name@university.ac.ke)';
    }
    return null;
  }

  // Name validation - requires 2-4 names
  static String? validateFullName(String? value) {
    if (value == null || value.isEmpty) return 'Please enter full name';

    final nameParts = value.trim().split(RegExp(r'\s+'));
    if (nameParts.length < 2) {
      return 'Please enter both First and Last name';
    }
    if (nameParts.length > 4) {
      return 'Name too long (max 4 parts)';
    }
    return null;
  }

  // Strong password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter password';
    if (value.length < 8) return 'Password must be at least 8 characters';

    bool hasUpper = value.contains(RegExp(r'[A-Z]'));
    bool hasLower = value.contains(RegExp(r'[a-z]'));
    bool hasDigit = value.contains(RegExp(r'[0-9]'));
    bool hasSpecial = value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));

    if (!hasUpper) return 'Password must contain an uppercase letter (A-Z)';
    if (!hasLower) return 'Password must contain a lowercase letter (a-z)';
    if (!hasDigit) return 'Password must contain a number (0-9)';
    if (!hasSpecial) {
      return 'Password must contain a special character (!@#\$%^&*)';
    }

    return null;
  }

  // Registration number validation
  static String? validateRegNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter registration number';
    }
    if (value.length < 8) {
      return 'Registration number must be at least 8 characters';
    }
    return null;
  }

  // Phone number validation (Kenyan format)
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Please enter phone number';
    final phoneRegex = RegExp(r'^(07|01)[0-9]{8}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Enter a valid phone number (e.g., 0712345678)';
    }
    return null;
  }
}
