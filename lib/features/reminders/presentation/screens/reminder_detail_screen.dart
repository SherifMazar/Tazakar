import 'package:flutter/material.dart';
class ReminderDetailScreen extends StatelessWidget {
  final String reminderId;
  const ReminderDetailScreen({super.key, required this.reminderId});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(child: Text('Reminder $reminderId — Sprint 3.9')));
}
