import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }

  // ==================== FIREBASE ====================
  static String get firebaseApiKey => dotenv.env['FIREBASE_API_KEY'] ?? '';

  static String get firebaseProjectId =>
      dotenv.env['FIREBASE_PROJECT_ID'] ?? '';

  // ==================== MPESA ====================
  static String get mpesaConsumerKey => dotenv.env['MPESA_CONSUMER_KEY'] ?? '';

  static String get mpesaConsumerSecret =>
      dotenv.env['MPESA_CONSUMER_SECRET'] ?? '';

  static String get mpesaPaybill => dotenv.env['MPESA_PAYBILL'] ?? '';

  // ==================== API ====================
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? '';

  static String get apiKey => dotenv.env['API_KEY'] ?? '';

  // ==================== ENCRYPTION ====================
  static String get encryptionKey => dotenv.env['ENCRYPTION_KEY'] ?? '';
}
