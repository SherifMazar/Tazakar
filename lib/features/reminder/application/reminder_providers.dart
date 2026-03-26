// lib/features/reminder/application/reminder_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tazakar/core/services/feature_gate/feature_gate_provider.dart';
import '../data/datasources/reminder_dao.dart';
import '../data/repositories/reminder_repository_impl.dart';
import '../domain/repositories/reminder_repository.dart';
import '../domain/usecases/create_reminder_usecase.dart';
import '../domain/usecases/reminder_usecases.dart';
import '../domain/entities/reminder.dart';

// ── Infrastructure ────────────────────────────────────────────────────────────

final reminderDaoProvider = Provider<ReminderDao>((ref) {
  return ReminderDao();
});

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final dao = ref.watch(reminderDaoProvider);
  return ReminderRepositoryImpl(dao);
});

// ── Use Cases ─────────────────────────────────────────────────────────────────

final createReminderUseCaseProvider = Provider<CreateReminderUseCase>((ref) {
  final repo = ref.watch(reminderRepositoryProvider);
  final gate = ref.watch(featureGateProvider);
  return CreateReminderUseCase(repository: repo, featureGate: gate);
});

final readReminderUseCaseProvider = Provider<ReadReminderUseCase>((ref) {
  final repo = ref.watch(reminderRepositoryProvider);
  return ReadReminderUseCase(repo);
});

final readAllRemindersUseCaseProvider =
    Provider<ReadAllRemindersUseCase>((ref) {
  final repo = ref.watch(reminderRepositoryProvider);
  return ReadAllRemindersUseCase(repo);
});

final readActiveRemindersUseCaseProvider =
    Provider<ReadActiveRemindersUseCase>((ref) {
  final repo = ref.watch(reminderRepositoryProvider);
  return ReadActiveRemindersUseCase(repo);
});

final updateReminderUseCaseProvider = Provider<UpdateReminderUseCase>((ref) {
  final repo = ref.watch(reminderRepositoryProvider);
  return UpdateReminderUseCase(repo);
});

final deleteReminderUseCaseProvider = Provider<DeleteReminderUseCase>((ref) {
  final repo = ref.watch(reminderRepositoryProvider);
  return DeleteReminderUseCase(repo);
});

// ── Derived State ─────────────────────────────────────────────────────────────

/// Watches all active reminders. Refresh by calling ref.invalidate().
final activeRemindersProvider = FutureProvider<List<Reminder>>((ref) async {
  final useCase = ref.watch(readActiveRemindersUseCaseProvider);
  return useCase.execute();
});
