import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/nlu/domain/entities/parsed_intent.dart';
import '../../application/reminder_providers.dart';
import '../../domain/entities/reminder.dart';
import '../../../../core/services/feature_gate/feature_gate_config.dart';
import '../../../../infrastructure/providers/notification_provider.dart';
import '../../../../infrastructure/database/database_service.dart';
import '../../domain/usecases/create_reminder_usecase.dart';

class CreateReminderScreen extends ConsumerStatefulWidget {
  final ParsedIntent intent;
  const CreateReminderScreen({super.key, required this.intent});

  @override
  ConsumerState<CreateReminderScreen> createState() =>
      _CreateReminderScreenState();
}

class _CreateReminderScreenState extends ConsumerState<CreateReminderScreen> {
  bool _isSubmitting = false;

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    final entities = widget.intent.entities;
    final now = DateTime.now();

    // Map ParsedIntent → Reminder (F-C01, DEC-35)
    final reminder = Reminder(
      title: entities.title ?? '',
      scheduledAt: entities.scheduledAt ?? now.add(const Duration(hours: 1)),
      recurrence: _mapRecurrence(entities.recurrenceType),
      dialectCode: widget.intent.dialectCode.name,
      createdAt: now,
      updatedAt: now,
    );

    // F-C02: CreateReminderUseCase (cap + recurrence gating)
    final createUseCase = ref.read(createReminderUseCaseProvider);
    final result = await createUseCase.execute(reminder);

    if (!mounted) return;

    switch (result) {
      case CreateReminderSuccess(:final id):
        // F-N01: Schedule notification
        final notifService = ref.read(notificationServiceProvider);
        final db = ref.read(databaseServiceProvider).valueOrNull;
        if (db != null) {
          await notifService.scheduleReminder(
            reminderId: id,
            title: reminder.title,
            body: reminder.title,
            scheduledAt: reminder.scheduledAt,
            db: db,
          );
        }
        // F-U01: Invalidate active reminders list
        ref.invalidate(activeRemindersProvider);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم حفظ التذكير\nReminder saved'),
            duration: Duration(seconds: 2),
          ),
        );
        context.go('/');

      case CreateReminderFailureResult(:final failure):
        setState(() => _isSubmitting = false);
        final msg = switch (failure) {
          CreateReminderFailure.freeTierCapReached =>
            'وصلت للحد الأقصى (١٠ تذكيرات).\nFree tier limit reached (10 reminders).',
          CreateReminderFailure.recurrenceNotAllowed =>
            'هذا النوع من التكرار غير متاح في النسخة المجانية.\nRecurrence type not available on free tier.',
          CreateReminderFailure.invalidTitle =>
            'يرجى إدخال عنوان للتذكير.\nPlease enter a reminder title.',
          CreateReminderFailure.invalidScheduledAt =>
            'يجب أن يكون وقت التذكير في المستقبل.\nScheduled time must be in the future.',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
    }
  }

  RecurrenceType _mapRecurrence(NluRecurrenceType? nlu) {
    return switch (nlu) {
      NluRecurrenceType.daily => RecurrenceType.daily,
      NluRecurrenceType.weekly => RecurrenceType.weekly,
      NluRecurrenceType.monthly => RecurrenceType.monthly,
      _ => RecurrenceType.none,
    };
  }

  @override
  Widget build(BuildContext context) {
    final entities = widget.intent.entities;
    final scheduledAt = entities.scheduledAt;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تأكيد التذكير\nConfirm Reminder'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InfoRow(
              label: 'التذكير / Reminder',
              value: entities.title ?? '-',
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'الوقت / Time',
              value: scheduledAt != null
                  ? '${scheduledAt.day}/${scheduledAt.month}/${scheduledAt.year}  '
                      '${TimeOfDay.fromDateTime(scheduledAt).format(context)}'
                  : '-',
            ),
            if (entities.recurrenceType != NluRecurrenceType.none) ...[
              const SizedBox(height: 16),
              _InfoRow(
                label: 'التكرار / Recurrence',
                value: entities.recurrenceType.name,
              ),
            ],
            const Spacer(),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('حفظ التذكير / Save Reminder',
                      style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        const Divider(),
      ],
    );
  }
}
