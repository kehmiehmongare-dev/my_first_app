import 'package:flutter/material.dart';
import 'package:campus_flow/core/routes.dart';
import 'package:campus_flow/core/theme.dart';
import 'package:campus_flow/features/auth/screens/login_screen.dart';

class CampusFlowApp extends StatelessWidget {
  const CampusFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Flow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      home: const LoginScreen(),
    );
  }
}
