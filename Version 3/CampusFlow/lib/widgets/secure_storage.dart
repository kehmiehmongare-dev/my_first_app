import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();
  factory SecureStorage() => _instance;
  SecureStorage._internal();

  // ✅ Simple storage using flutter_secure_storage
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Store sensitive data
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  // Read sensitive data
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  // Delete sensitive data
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  // Delete all data (logout)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Check if data exists
  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }

  // Read all keys
  Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }
}
