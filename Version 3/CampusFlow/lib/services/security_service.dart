import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:campus_flow/widgets/secure_storage.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final SecureStorage _storage = SecureStorage();

  // ==================== TOKEN MANAGEMENT ====================

  Future<void> storeAuthToken(String token) async {
    await _storage.write('auth_token', token);
  }

  Future<String?> getAuthToken() async {
    return await _storage.read('auth_token');
  }

  Future<void> clearAuthData() async {
    await _storage.clearAll();
    await FirebaseAuth.instance.signOut();
  }

  // ==================== INPUT SANITIZATION ====================

  static String sanitizeInput(String input) {
    String sanitized = input.replaceAll(RegExp('<|>|"'), '');
    sanitized = sanitized.replaceAll(RegExp("'"), '');
    sanitized = sanitized.replaceAll(RegExp(';'), '');
    sanitized = sanitized.replaceAll(RegExp('{'), '');
    sanitized = sanitized.replaceAll(RegExp('}'), '');
    return sanitized;
  }

  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // ==================== PASSWORD STRENGTH ====================

  static PasswordStrength checkPasswordStrength(String password) {
    int score = 0;

    if (password.length >= 12) {
      score += 2;
    } else if (password.length >= 8) {
      score += 1;
    }

    if (password.contains(RegExp(r'[A-Z]'))) {
      score += 1;
    }

    if (password.contains(RegExp(r'[a-z]'))) {
      score += 1;
    }

    if (password.contains(RegExp(r'[0-9]'))) {
      score += 1;
    }

    if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      score += 1;
    }

    if (score >= 6) {
      return PasswordStrength.strong;
    }
    if (score >= 4) {
      return PasswordStrength.medium;
    }
    return PasswordStrength.weak;
  }

  // ==================== RATE LIMITING ====================

  final Map<String, List<DateTime>> _loginAttempts = {};
  static const int maxAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);

  bool isRateLimited(String identifier) {
    final now = DateTime.now();
    _loginAttempts.putIfAbsent(identifier, () => []);

    _loginAttempts[identifier] = _loginAttempts[identifier]!
        .where((time) => now.difference(time) < lockoutDuration)
        .toList();

    if (_loginAttempts[identifier]!.length >= maxAttempts) {
      return true;
    }

    return false;
  }

  void recordLoginAttempt(String identifier) {
    _loginAttempts.putIfAbsent(identifier, () => []);
    _loginAttempts[identifier]!.add(DateTime.now());
  }

  void resetLoginAttempts(String identifier) {
    _loginAttempts.remove(identifier);
  }

  // ==================== SESSION MANAGEMENT ====================

  Future<bool> isSessionValid() async {
    final token = await getAuthToken();
    if (token == null) {
      return false;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return false;
      }
      return user.uid.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ==================== ENCRYPTION HELPERS ====================

  static String generateDeviceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  static String hashString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

enum PasswordStrength {
  weak,
  medium,
  strong,
}
