import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class MpesaService {
  static const String _baseUrl = 'https://api.safaricom.co.ke';

  // ✅ These should be in your .env file or secure storage
  static const String _consumerKey = 'YOUR_CONSUMER_KEY';
  static const String _consumerSecret = 'YOUR_CONSUMER_SECRET';
  static const String _businessShortCode = '174379';
  static const String _passkey = 'YOUR_PASSKEY';
  static const String _callbackUrl = 'https://your-app.com/mpesa/callback';

  // ✅ Get access token
  static Future<String> _getAccessToken() async {
    final auth = base64Encode(utf8.encode('$_consumerKey:$_consumerSecret'));
    final response = await http.post(
      Uri.parse('$_baseUrl/oauth/v1/generate?grant_type=client_credentials'),
      headers: {
        'Authorization': 'Basic $auth',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['access_token'];
    }
    throw Exception('Failed to get access token: ${response.body}');
  }

  // ✅ REAL STK Push - Use this in production
  static Future<Map<String, dynamic>> initiateStkPush({
    required String phoneNumber,
    required double amount,
    required String accountReference,
    required String transactionDesc,
  }) async {
    try {
      final accessToken = await _getAccessToken();

      // Format phone number (remove leading 0 or +254)
      String formattedPhone = phoneNumber;
      if (formattedPhone.startsWith('0')) {
        formattedPhone = '254${formattedPhone.substring(1)}';
      } else if (formattedPhone.startsWith('+254')) {
        formattedPhone = formattedPhone.substring(1);
      } else if (!formattedPhone.startsWith('254')) {
        formattedPhone = '254$formattedPhone';
      }

      // Generate timestamp
      final now = DateTime.now();
      final timestamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}'
          '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';

      final password = base64Encode(
        utf8.encode('$_businessShortCode$_passkey$timestamp'),
      );

      final requestBody = {
        'BusinessShortCode': _businessShortCode,
        'Password': password,
        'Timestamp': timestamp,
        'TransactionType': 'CustomerPayBillOnline',
        'Amount': amount.toStringAsFixed(0),
        'PartyA': formattedPhone,
        'PartyB': _businessShortCode,
        'PhoneNumber': formattedPhone,
        'CallBackURL': _callbackUrl,
        'AccountReference': accountReference,
        'TransactionDesc': transactionDesc,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/mpesa/stkpush/v1/processrequest'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['ResponseCode'] == '0') {
          return result;
        } else {
          throw Exception('STK Push failed: ${result['ResponseDescription']}');
        }
      }
      throw Exception('STK Push failed: ${response.body}');
    } catch (e) {
      throw Exception('M-Pesa error: $e');
    }
  }

  // ✅ SIMULATED STK Push - For testing without real API
  static Future<Map<String, dynamic>> simulatePayment({
    required String phoneNumber,
    required double amount,
    required String accountReference,
  }) async {
    // ✅ Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // ✅ Simulate successful payment
    return {
      'MerchantRequestID': 'SIM_${DateTime.now().millisecondsSinceEpoch}',
      'CheckoutRequestID': 'CHECKOUT_${DateTime.now().millisecondsSinceEpoch}',
      'ResponseCode': '0',
      'ResponseDescription': 'Success. Request accepted for processing',
      'CustomerMessage': 'Success. Request accepted for processing',
    };
  }

  // ✅ Check STK Push status
  static Future<Map<String, dynamic>> checkPaymentStatus(
    String checkoutRequestId,
  ) async {
    try {
      final accessToken = await _getAccessToken();

      final response = await http.post(
        Uri.parse('$_baseUrl/mpesa/stkpush/v1/query'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'BusinessShortCode': _businessShortCode,
          'Password': base64Encode(
            utf8.encode(
              '$_businessShortCode$_passkey${DateTime.now().millisecondsSinceEpoch}',
            ),
          ),
          'Timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          'CheckoutRequestID': checkoutRequestId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to check payment status: ${response.body}');
    } catch (e) {
      throw Exception('Status check error: $e');
    }
  }

  // ✅ Save transaction to Firestore
  static Future<void> saveTransaction({
    required String studentId,
    required String studentName,
    required String studentRegNumber,
    required double amount,
    required String method,
    required String status,
    String? reference,
    String? checkoutRequestId,
  }) async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('payments').add({
      'studentId': studentId,
      'studentName': studentName,
      'studentRegNumber': studentRegNumber,
      'amount': amount,
      'method': method,
      'status': status,
      'date': FieldValue.serverTimestamp(),
      'reference': reference,
      'checkoutRequestId': checkoutRequestId,
    });
  }
}
