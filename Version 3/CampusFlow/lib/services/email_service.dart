import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  static Future<void> sendCredentials({
    required String email,
    required String name,
    required String identifier, // regNumber or employeeId
    required String password,
    required String role, // 'student' or 'lecturer'
  }) async {
    try {
      // For production, use your actual SMTP credentials
      // This is a demo using Gmail SMTP
      final username = 'your-email@gmail.com';
      final password = 'your-app-password'; // Use App Password

      final smtpServer = gmail(username, password);

      final subject = 'Welcome to Campus Flow - Your Login Credentials';

      String body;
      if (role == 'student') {
        body = '''
Dear $name,

Welcome to Campus Flow - Student Management System!

Your account has been created successfully. Here are your login details:

📋 Registration Number: $identifier
🔑 Temporary Password: $password
📧 Your Email: $email

🔐 Login Instructions:
1. Go to the Campus Flow login page
2. Enter your Registration Number and temporary password
3. You will be prompted to change your password on first login

⚠️ Please change your password immediately after logging in for security purposes.

If you have any issues, please contact the IT Support team.

Best regards,
Campus Flow Team
''';
      } else {
        body = '''
Dear $name,

Welcome to Campus Flow - Lecturer Management System!

Your account has been created successfully. Here are your login details:

👨‍🏫 Employee ID: $identifier
🔑 Temporary Password: $password
📧 Your Email: $email

🔐 Login Instructions:
1. Go to the Campus Flow login page
2. Enter your Email and temporary password
3. You will be prompted to change your password on first login

⚠️ Please change your password immediately after logging in for security purposes.

If you have any issues, please contact the IT Support team.

Best regards,
Campus Flow Team
''';
      }

      final message = Message()
        ..from = Address(username, 'Campus Flow System')
        ..recipients.add(email)
        ..subject = subject
        ..text = body;

      final sendReport = await send(message, smtpServer);
      print('✅ Email sent to $email: ${sendReport.toString()}');
    } catch (e) {
      print('❌ Failed to send email to $email: $e');
      rethrow;
    }
  }

  static Future<void> sendBulkCredentials(
    List<Map<String, dynamic>> users,
    String role,
  ) async {
    for (var user in users) {
      try {
        await sendCredentials(
          email: user['email'],
          name: user['fullName'],
          identifier: user['regNumber'] ?? user['employeeId'],
          password: user['tempPassword'] ?? 'Temp@123',
          role: role,
        );
        // Wait a bit between emails to avoid rate limiting
        await Future.delayed(const Duration(seconds: 1));
      } catch (e) {
        print('❌ Failed to send email to ${user['email']}: $e');
      }
    }
  }
}
