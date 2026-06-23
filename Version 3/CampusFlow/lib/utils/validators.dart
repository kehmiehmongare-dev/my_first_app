import 'package:campus_flow/services/security_service.dart';

class Validators {
  // ==================== EMAIL VALIDATION ====================

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final sanitized = SecurityService.sanitizeInput(value);

    if (!SecurityService.isValidEmail(sanitized)) {
      return 'Please enter a valid email address';
    }

    // Block temporary/throwaway emails
    final blockedDomains = [
      'tempmail.com',
      '10minutemail.com',
      'guerrillamail.com',
      'mailinator.com',
      'yopmail.com',
      'throwaway.com',
    ];
    final domain = value.split('@').last.toLowerCase();
    if (blockedDomains.contains(domain)) {
      return 'Please use a real email address';
    }

    return null;
  }

  // ==================== PASSWORD VALIDATION ====================

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain an uppercase letter';
    }

    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain a lowercase letter';
    }

    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain a number';
    }

    if (!value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain a special character';
    }

    final commonPasswords = [
      'password123',
      '12345678',
      'qwerty123',
      'admin123',
      'letmein123',
      'welcome123',
      'password1',
    ];
    if (commonPasswords.contains(value.toLowerCase())) {
      return 'This password is too common. Please choose a stronger one.';
    }

    return null;
  }

  // ==================== PHONE VALIDATION ====================

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    final sanitized = SecurityService.sanitizeInput(value);
    final phoneRegex = RegExp(r'^(07|01)\d{8}$');

    if (!phoneRegex.hasMatch(sanitized)) {
      return 'Enter a valid phone number (e.g., 0712345678)';
    }

    return null;
  }

  // ==================== NAME VALIDATION ====================

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    final sanitized = SecurityService.sanitizeInput(value);
    final nameParts = sanitized.trim().split(RegExp(r'\s+'));

    if (nameParts.length < 2) {
      return 'Please enter first and last name';
    }

    return null;
  }

  // ==================== AMOUNT VALIDATION ====================

  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }

    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      return 'Please enter a valid amount';
    }

    return null;
  }
}
