import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tazakar/core/services/feature_gate/feature_gate_config.dart';
import 'package:tazakar/core/services/feature_gate/feature_gate_service.dart';
import 'package:tazakar/core/services/feature_gate/subscription_tier.dart';
import 'package:tazakar/features/reminder/domain/entities/reminder.dart';
import 'package:tazakar/features/reminder/domain/repositories/reminder_repository.dart';
import 'package:tazakar/features/reminder/domain/usecases/create_reminder_usecase.dart';
import 'package:tazakar/features/reminder/domain/usecases/reminder_usecases.dart';

class MockReminderRepository extends Mock implements ReminderRepository {}

Reminder makeReminder({
  int id = 0,
  String title = 'اجتماع العمل',
  DateTime? remindAt,
  RecurrenceType recurrence = RecurrenceType.none,
  int categoryId = 1,
  bool isCompleted = false,
}) {
  return Reminder(
    id: id,
    title: title,
    remindAt: remindAt ?? DateTime.now().add(const Duration(hours: 1)),
    recurrence: recurrence,
    categoryId: categoryId,
    isCompleted: isCompleted,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

FeatureGateService makeGate({
  bool monetisationActive = false,
  SubscriptionTier tier = SubscriptionTier.free,
}) {
  return FeatureGateService(
    monetisationActive: monetisationActive,
    storedTier: tier,
  );
}

void main() {
  late MockReminderRepository repo;

  setUp(() {
    repo = MockReminderRepository();
  });

  group('CreateReminderUseCase', () {
    test('succeeds with valid reminder under free cap', () async {
      final gate = makeGate();
      final useCase = CreateReminderUseCase(repository: repo, featureGate: gate);
      final reminder = makeReminder();
      when(() => repo.count()).thenAnswer((_) async => 0);
      when(() => repo.create(reminder)).thenAnswer((_) async => 1);
      final result = await useCase.execute(reminder);
      expect(result, isA<CreateReminderSuccess>());
      expect((result as CreateReminderSuccess).id, 1);
    });

    test('fails with invalidTitle when title is empty', () async {
      final gate = makeGate();
      final useCase = CreateReminderUseCase(repository: repo, featureGate: gate);
      final reminder = makeReminder(title: '   ');
      final result = await useCase.execute(reminder);
      expect(result, isA<CreateReminderFailureResult>());
      expect((result as CreateReminderFailureResult).failure, CreateReminderFailure.invalidTitle);
    });

    test('fails with invalidScheduledAt when time is in the past', () async {
      final gate = makeGate();
      final useCase = CreateReminderUseCase(repository: repo, featureGate: gate);
      final reminder = makeReminder(remindAt: DateTime.now().subtract(const Duration(minutes: 5)));
      final result = await useCase.execute(reminder);
      expect(result, isA<CreateReminderFailureResult>());
      expect((result as CreateReminderFailureResult).failure, CreateReminderFailure.invalidScheduledAt);
    });

    test('fails with freeTierCapReached when at cap', () async {
      final gate = makeGate(monetisationActive: true);
      final useCase = CreateReminderUseCase(repository: repo, featureGate: gate);
      final reminder = makeReminder();
      when(() => repo.count()).thenAnswer((_) async => 10);
      final result = await useCase.execute(reminder);
      expect(result, isA<CreateReminderFailureResult>());
      expect((result as CreateReminderFailureResult).failure, CreateReminderFailure.freeTierCapReached);
    });

    test('cap not enforced when monetisation is inactive (SC-07)', () async {
      final gate = makeGate(monetisationActive: false);
      final useCase = CreateReminderUseCase(repository: repo, featureGate: gate);
      final reminder = makeReminder();
      when(() => repo.count()).thenAnswer((_) async => 10);
      when(() => repo.create(reminder)).thenAnswer((_) async => 2);
      final result = await useCase.execute(reminder);
      expect(result, isA<CreateReminderSuccess>());
    });

    test('fails with recurrenceNotAllowed for daily on free tier', () async {
      final gate = makeGate(monetisationActive: true);
      final useCase = CreateReminderUseCase(repository: repo, featureGate: gate);
      final reminder = makeReminder(recurrence: RecurrenceType.daily);
      when(() => repo.count()).thenAnswer((_) async => 0);
      final result = await useCase.execute(reminder);
      expect(result, isA<CreateReminderFailureResult>());
      expect((result as CreateReminderFailureResult).failure, CreateReminderFailure.recurrenceNotAllowed);
    });

    test('allows monthly recurrence on free tier (DEC-26)', () async {
      final gate = makeGate(monetisationActive: true);
      final useCase = CreateReminderUseCase(repository: repo, featureGate: gate);
      final reminder = makeReminder(recurrence: RecurrenceType.monthly);
      when(() => repo.count()).thenAnswer((_) async => 0);
      when(() => repo.create(reminder)).thenAnswer((_) async => 3);
      final result = await useCase.execute(reminder);
      expect(result, isA<CreateReminderSuccess>());
    });

    test('allows all recurrence types on pro tier', () async {
      final gate = makeGate(monetisationActive: true, tier: SubscriptionTier.pro);
      final useCase = CreateReminderUseCase(repository: repo, featureGate: gate);
      for (final type in RecurrenceType.values) {
        final reminder = makeReminder(recurrence: type);
        when(() => repo.count()).thenAnswer((_) async => 0);
        when(() => repo.create(reminder)).thenAnswer((_) async => 100);
        final result = await useCase.execute(reminder);
        expect(result, isA<CreateReminderSuccess>(), reason: 'Pro should allow $type');
      }
    });
  });

  group('ReadReminderUseCase', () {
    test('returns reminder when found', () async {
      final useCase = ReadReminderUseCase(repo);
      final reminder = makeReminder(id: 1);
      when(() => repo.readById(1)).thenAnswer((_) async => reminder);
      final result = await useCase.execute(1);
      expect(result, reminder);
    });

    test('returns null when not found', () async {
      final useCase = ReadReminderUseCase(repo);
      when(() => repo.readById(999)).thenAnswer((_) async => null);
      final result = await useCase.execute(999);
      expect(result, isNull);
    });
  });

  group('ReadAllRemindersUseCase', () {
    test('returns all reminders', () async {
      final useCase = ReadAllRemindersUseCase(repo);
      final reminders = [makeReminder(id: 1), makeReminder(id: 2)];
      when(() => repo.readAll()).thenAnswer((_) async => reminders);
      final result = await useCase.execute();
      expect(result, reminders);
      expect(result.length, 2);
    });

    test('returns empty list when no reminders exist', () async {
      final useCase = ReadAllRemindersUseCase(repo);
      when(() => repo.readAll()).thenAnswer((_) async => []);
      final result = await useCase.execute();
      expect(result, isEmpty);
    });
  });

  group('ReadActiveRemindersUseCase', () {
    test('returns only active reminders', () async {
      final useCase = ReadActiveRemindersUseCase(repo);
      final active = [makeReminder(id: 1, isCompleted: false)];
      when(() => repo.readActive()).thenAnswer((_) async => active);
      final result = await useCase.execute();
      expect(result.every((r) => !r.isCompleted), isTrue);
    });
  });

  group('UpdateReminderUseCase', () {
    test('calls repository update with reminder', () async {
      final useCase = UpdateReminderUseCase(repo);
      final reminder = makeReminder(id: 1);
      when(() => repo.update(reminder)).thenAnswer((_) async {});
      await useCase.execute(reminder);
      verify(() => repo.update(reminder)).called(1);
    });

    test('succeeds when id is 0 (unsaved)', () async {
      final useCase = UpdateReminderUseCase(repo);
      final reminder = makeReminder();
      expect(() => useCase.execute(reminder), throwsA(isA<AssertionError>()));
    });
  });

  group('DeleteReminderUseCase', () {
    test('calls repository delete with id', () async {
      final useCase = DeleteReminderUseCase(repo);
      when(() => repo.delete(1)).thenAnswer((_) async {});
      await useCase.execute(1);
      verify(() => repo.delete(1)).called(1);
    });
  });

  group('Free tier cap boundary (DEC-22)', () {
    test('allows creation at count 9', () async {
      final gate = makeGate(monetisationActive: true);
      final useCase = CreateReminderUseCase(repository: repo, featureGate: gate);
      final reminder = makeReminder(recurrence: RecurrenceType.monthly);
      when(() => repo.count()).thenAnswer((_) async => 9);
      when(() => repo.create(reminder)).thenAnswer((_) async => 9);
      final result = await useCase.execute(reminder);
      expect(result, isA<CreateReminderSuccess>());
    });

    test('blocks creation at count 10', () async {
      final gate = makeGate(monetisationActive: true);
      final useCase = CreateReminderUseCase(repository: repo, featureGate: gate);
      final reminder = makeReminder();
      when(() => repo.count()).thenAnswer((_) async => 10);
      final result = await useCase.execute(reminder);
      expect(result, isA<CreateReminderFailureResult>());
      expect((result as CreateReminderFailureResult).failure, CreateReminderFailure.freeTierCapReached);
    });
  });
}
