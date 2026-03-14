import 'package:flutter/material.dart';

class ReminderDetailScreen extends StatelessWidget {
  final String reminderId;
  const ReminderDetailScreen({super.key, required this.reminderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Reminder Detail: $reminderId — Coming Soon')),
    );
  }
}
