import 'package:flutter/material.dart';
import '../../domain/entities/reminder.dart';
import '../../../../core/services/feature_gate/feature_gate_config.dart';

class ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;

  const ReminderCard({
    super.key,
    required this.reminder,
    this.onTap,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheduledAt = reminder.scheduledAt;
    final timeStr = TimeOfDay.fromDateTime(scheduledAt).format(context);
    final dateStr = '${scheduledAt.day}/${scheduledAt.month}/${scheduledAt.year}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: IconButton(
          icon: Icon(
            reminder.isCompleted
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: reminder.isCompleted
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
          onPressed: onComplete,
        ),
        title: Text(
          reminder.title,
          style: theme.textTheme.bodyLarge?.copyWith(
            decoration:
                reminder.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text('$dateStr  $timeStr', style: theme.textTheme.bodySmall),
        trailing: reminder.recurrence != RecurrenceType.none
            ? Icon(Icons.repeat, size: 16, color: theme.colorScheme.secondary)
            : null,
      ),
    );
  }
}
