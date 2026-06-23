import 'package:intl/intl.dart';

class Helpers {
  static String formatCurrency(double amount) {
    return 'KSh ${NumberFormat('#,###.00').format(amount)}';
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidRegNumber(String regNumber) {
    return RegExp(r'^[A-Za-z]{2,4}[0-9]{6,9}$').hasMatch(regNumber);
  }
}
