import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobile Application Development', // 1. App title changed
      home: Scaffold(
        appBar: AppBar(
          title: Text('Welcome to BIT 4107'), // 4. AppBar title changed
          backgroundColor: Colors.deepPurple,
        ),
        body: Center(
          child: Text(
            'Hello Boss! Welcome to Mobile Application Development where you will learn to build amazing mobile apps!',
            style: TextStyle(
              fontSize: 28, // 2. Font size changed
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: Colors.amber.shade50, // 3. Background color changed
      ),
    );
  }
}
