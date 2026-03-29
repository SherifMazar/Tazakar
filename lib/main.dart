import 'package:flutter/material.dart';

void main() {
  runApp(const TazakarApp());
}

class TazakarApp extends StatelessWidget {
  const TazakarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tazakar',
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text('مرحباً بك في تذكر', style: TextStyle(fontSize: 24)),
        ),
      ),
    );
  }
}
