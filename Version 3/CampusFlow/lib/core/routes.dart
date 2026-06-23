import 'package:flutter/material.dart';
import 'package:campus_flow/features/auth/screens/login_screen.dart';
import 'package:campus_flow/features/student/screens/student_dashboard.dart';
import 'package:campus_flow/features/lecturer/screens/lecturer_dashboard.dart';
import 'package:campus_flow/features/admin/screens/admin_dashboard.dart';
import 'package:campus_flow/screens/record_management_screen.dart';
import 'package:campus_flow/screens/api_consumer_screen.dart';
import 'package:campus_flow/screens/data_management_screen.dart';
import 'package:campus_flow/screens/firebase_test_screen.dart';

class AppRoutes {
  static const String login = '/';
  static const String register = '/register';
  static const String studentDashboard = '/student-dashboard';
  static const String lecturerDashboard = '/lecturer-dashboard';
  static const String adminDashboard = '/admin-dashboard';
  static const String recordManagement = '/record-management';
  static const String apiConsumer = '/api-consumer';
  static const String dataManagement = '/data-management';
  static const String firebaseTest = '/firebase-test';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    recordManagement: (context) => const RecordManagementScreen(),
    apiConsumer: (context) => const ApiConsumerScreen(),
    dataManagement: (context) => const DataManagementScreen(),
    firebaseTest: (context) => const FirebaseTestScreen(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case studentDashboard:
        return MaterialPageRoute(
          builder: (context) =>
              const StudentDashboard(), // ✅ No parameters needed
        );
      case lecturerDashboard:
        return MaterialPageRoute(
          builder: (context) =>
              const LecturerDashboard(), // ✅ No parameters needed
        );
      case adminDashboard:
        return MaterialPageRoute(
          builder: (context) => const AdminDashboard(),
        );
      default:
        return null;
    }
  }
}
