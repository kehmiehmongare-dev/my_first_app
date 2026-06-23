import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  static const String _keyUserEmail = 'user_email';
  static const String _keyUserUid = 'user_uid';
  static const String _keyUserName = 'user_name';
  static const String _keyUserRole = 'user_role';
  static const String _keyRememberMe = 'remember_me';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyUserRegNumber = 'user_reg_number';

  late SharedPreferences _prefs;

  // ✅ Initialize preferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ==================== USER SESSION ====================

  // ✅ Save user session
  Future<void> saveUserSession({
    required String email,
    required String uid,
    required String name,
    required String role,
    String? regNumber,
  }) async {
    await _prefs.setString(_keyUserEmail, email);
    await _prefs.setString(_keyUserUid, uid);
    await _prefs.setString(_keyUserName, name);
    await _prefs.setString(_keyUserRole, role);
    await _prefs.setBool(_keyIsLoggedIn, true);
    if (regNumber != null) {
      await _prefs.setString(_keyUserRegNumber, regNumber);
    }
  }

  // ✅ Get user session
  Map<String, String?> getUserSession() {
    return {
      'email': _prefs.getString(_keyUserEmail),
      'uid': _prefs.getString(_keyUserUid),
      'name': _prefs.getString(_keyUserName),
      'role': _prefs.getString(_keyUserRole),
      'regNumber': _prefs.getString(_keyUserRegNumber),
    };
  }

  // ✅ Check if user is logged in
  bool isLoggedIn() {
    return _prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // ✅ Get user email
  String? getUserEmail() {
    return _prefs.getString(_keyUserEmail);
  }

  // ✅ Get user UID
  String? getUserUid() {
    return _prefs.getString(_keyUserUid);
  }

  // ✅ Get user role
  String? getUserRole() {
    return _prefs.getString(_keyUserRole);
  }

  // ✅ Clear user session (logout)
  Future<void> clearUserSession() async {
    await _prefs.remove(_keyUserEmail);
    await _prefs.remove(_keyUserUid);
    await _prefs.remove(_keyUserName);
    await _prefs.remove(_keyUserRole);
    await _prefs.remove(_keyUserRegNumber);
    await _prefs.setBool(_keyIsLoggedIn, false);
  }

  // ==================== REMEMBER ME ====================

  // ✅ Save remember me preference
  Future<void> setRememberMe(bool remember) async {
    await _prefs.setBool(_keyRememberMe, remember);
  }

  // ✅ Get remember me preference
  bool getRememberMe() {
    return _prefs.getBool(_keyRememberMe) ?? false;
  }

  // ==================== THEME PREFERENCE ====================

  // ✅ Save theme mode (0 = light, 1 = dark, 2 = system)
  Future<void> setThemeMode(int themeMode) async {
    await _prefs.setInt(_keyThemeMode, themeMode);
  }

  // ✅ Get theme mode
  int getThemeMode() {
    return _prefs.getInt(_keyThemeMode) ?? 0;
  }

  // ==================== UTILITY METHODS ====================

  // ✅ Clear all preferences (for testing)
  Future<void> clearAll() async {
    await _prefs.clear();
  }

  // ✅ Check if a key exists
  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }

  // ✅ Remove specific key
  Future<void> removeKey(String key) async {
    await _prefs.remove(key);
  }
}
