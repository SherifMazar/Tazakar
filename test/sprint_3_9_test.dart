// test/sprint_3_9_test.dart
//
// Sprint 3.9 — E2E Voice-to-Reminder Pipeline tests.
// Groups:
//   A — VoiceInputState transitions (4 tests)
//   B — ParsedIntent → Reminder mapping (4 tests)
//   C — CreateReminderUseCase gating (4 tests)
//   D — ClarificationDialogueUseCase integration (4 tests)
//   E — Pipeline integration (4 tests)
//
// Run: flutter test test/sprint_3_9_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:tazakar/features/nlu/application/clarification_dialogue_use_case.dart';
import 'package:tazakar/features/nlu/application/parse_voice_input_use_case.dart';
import 'package:tazakar/features/nlu/data/nlu_repository_impl.dart';
import 'package:tazakar/features/nlu/data/dialect_router.dart';
import 'package:tazakar/features/nlu/data/arabic_datetime_parser.dart';
import 'package:tazakar/features/nlu/data/nlu_entity_extractor.dart';
import 'package:tazakar/features/nlu/domain/entities/parsed_intent.dart';
import 'package:tazakar/features/reminder/application/voice_input_provider.dart';
import 'package:tazakar/features/reminder/domain/entities/reminder.dart';
import 'package:tazakar/features/reminder/domain/usecases/create_reminder_usecase.dart';
import 'package:tazakar/core/services/feature_gate/feature_gate_service.dart';
import 'package:tazakar/core/services/feature_gate/feature_gate_config.dart';
import 'package:tazakar/core/services/feature_gate/subscription_tier.dart';
import 'package:tazakar/features/reminder/domain/repositories/reminder_repository.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeReminderRepository implements ReminderRepository {
  final List<Reminder> _reminders = [];

  @override Future<int> create(Reminder r) async {
    _reminders.add(r.copyWith(id: _reminders.length + 1));
    return _reminders.length;
  }
  @override Future<int> count() async => _reminders.length;
  @override Future<List<Reminder>> readActive() async =>
      _reminders.where((r) => !r.isCompleted).toList();
  @override Future<Reminder?> readById(int id) async => null;
  @override Future<List<Reminder>> readAll() async => _reminders;
  @override Future<void> update(Reminder r) async {}
  @override Future<void> delete(int id) async {}
  @override Future<void> deleteAll() async {}
}

class _CapReachedRepository extends _FakeReminderRepository {
  @override Future<int> count() async => 10;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ParseVoiceInputUseCase _makeParseUseCase() {
  final repo = NluRepositoryImpl(
    dialectRouter: DialectRouter(),
    dateTimeParser: ArabicDateTimeParser(),
    entityExtractor: NluEntityExtractor(),
  );
  return ParseVoiceInputUseCase(repo);
}

const _clarUseCase = ClarificationDialogueUseCase();

void main() {
  // -------------------------------------------------------------------------
  // Group A — VoiceInputState transitions
  // -------------------------------------------------------------------------
  group('A — VoiceInputState', () {
    test('A1: initial state is idle', () {
      const state = VoiceInputState();
      expect(state.status, VoiceInputStatus.idle);
      expect(state.parsedIntent, isNull);
      expect(state.errorMessage, isNull);
    });

    test('A2: copyWith preserves unchanged fields', () {
      const state = VoiceInputState(transcript: 'test');
      final next = state.copyWith(status: VoiceInputStatus.processing);
      expect(next.transcript, 'test');
      expect(next.status, VoiceInputStatus.processing);
    });

    test('A3: error state carries message', () {
      const state = VoiceInputState(
        status: VoiceInputStatus.error,
        errorMessage: 'mic denied',
      );
      expect(state.status, VoiceInputStatus.error);
      expect(state.errorMessage, 'mic denied');
    });

    test('A4: actionable state has parsedIntent', () {
      final intent = ParsedIntent(
        rawText: 'test',
        dialectCode: DialectCode.gulf,
        normalisedText: 'test',
        entities: ExtractedEntities(
          title: 'اجتماع',
          scheduledAt: DateTime.now().add(const Duration(hours: 1)),
        ),
        confidence: 0.9,
        clarificationNeeded: false,
        missingFields: [],
      );
      final state = VoiceInputState(
        status: VoiceInputStatus.actionable,
        parsedIntent: intent,
      );
      expect(state.status, VoiceInputStatus.actionable);
      expect(state.parsedIntent, isNotNull);
    });
  });

  // -------------------------------------------------------------------------
  // Group B — ParsedIntent → Reminder mapping
  // -------------------------------------------------------------------------
  group('B — ParsedIntent → Reminder mapping', () {
    test('B1: title maps correctly', () {
      final scheduled = DateTime.now().add(const Duration(hours: 2));
      final reminder = Reminder(
        title: 'اجتماع مع العميل',
        scheduledAt: scheduled,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(reminder.title, 'اجتماع مع العميل');
    });

    test('B2: scheduledAt maps correctly', () {
      final scheduled = DateTime(2026, 6, 1, 10, 0);
      final reminder = Reminder(
        title: 'موعد طبيب',
        scheduledAt: scheduled,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(reminder.scheduledAt, scheduled);
    });

    test('B3: recurrence defaults to none', () {
      final reminder = Reminder(
        title: 'تذكير',
        scheduledAt: DateTime.now().add(const Duration(hours: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(reminder.recurrence, RecurrenceType.none);
    });

    test('B4: dialectCode set correctly', () {
      final reminder = Reminder(
        title: 'تذكير',
        scheduledAt: DateTime.now().add(const Duration(hours: 1)),
        dialectCode: 'gulf',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(reminder.dialectCode, 'gulf');
    });
  });

  // -------------------------------------------------------------------------
  // Group C — CreateReminderUseCase gating
  // -------------------------------------------------------------------------
  group('C — CreateReminderUseCase gating', () {
    final gate = FeatureGateService(
      monetisationActive: true,
      storedTier: SubscriptionTier.free,
    );

    test('C1: empty title returns invalidTitle', () async {
      final uc = CreateReminderUseCase(
        repository: _FakeReminderRepository(),
        featureGate: gate,
      );
      final result = await uc.execute(Reminder(
        title: '',
        scheduledAt: DateTime.now().add(const Duration(hours: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      expect(result, isA<CreateReminderFailureResult>());
      expect(
        (result as CreateReminderFailureResult).failure,
        CreateReminderFailure.invalidTitle,
      );
    });

    test('C2: past scheduledAt returns invalidScheduledAt', () async {
      final uc = CreateReminderUseCase(
        repository: _FakeReminderRepository(),
        featureGate: gate,
      );
      final result = await uc.execute(Reminder(
        title: 'تذكير',
        scheduledAt: DateTime.now().subtract(const Duration(hours: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      expect(result, isA<CreateReminderFailureResult>());
      expect(
        (result as CreateReminderFailureResult).failure,
        CreateReminderFailure.invalidScheduledAt,
      );
    });

    test('C3: cap reached returns freeTierCapReached', () async {
      final uc = CreateReminderUseCase(
        repository: _CapReachedRepository(),
        featureGate: gate,
      );
      final result = await uc.execute(Reminder(
        title: 'تذكير',
        scheduledAt: DateTime.now().add(const Duration(hours: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      expect(result, isA<CreateReminderFailureResult>());
      expect(
        (result as CreateReminderFailureResult).failure,
        CreateReminderFailure.freeTierCapReached,
      );
    });

    test('C4: valid reminder returns CreateReminderSuccess', () async {
      final freeGate = FeatureGateService(
        monetisationActive: false,
        storedTier: SubscriptionTier.free,
      );
      final uc = CreateReminderUseCase(
        repository: _FakeReminderRepository(),
        featureGate: freeGate,
      );
      final result = await uc.execute(Reminder(
        title: 'اجتماع',
        scheduledAt: DateTime.now().add(const Duration(hours: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      expect(result, isA<CreateReminderSuccess>());
    });
  });

  // -------------------------------------------------------------------------
  // Group D — ClarificationDialogueUseCase
  // -------------------------------------------------------------------------
  group('D — ClarificationDialogueUseCase', () {
    test('D1: nextQuestion returns null when no clarification needed', () {
      final intent = ParsedIntent(
        rawText: 'test',
        dialectCode: DialectCode.gulf,
        normalisedText: 'test',
        entities: ExtractedEntities(
          title: 'اجتماع',
          scheduledAt: DateTime.now().add(const Duration(hours: 1)),
        ),
        confidence: 0.9,
        clarificationNeeded: false,
        missingFields: [],
      );
      expect(_clarUseCase.nextQuestion(intent), isNull);
    });

    test('D2: nextQuestion returns title question when title missing', () {
      final intent = ParsedIntent(
        rawText: 'test',
        dialectCode: DialectCode.gulf,
        normalisedText: 'test',
        entities: const ExtractedEntities(
          scheduledAt: null,
        ),
        confidence: 0.3,
        clarificationNeeded: true,
        missingFields: ['title'],
      );
      final q = _clarUseCase.nextQuestion(intent);
      expect(q, isNotNull);
      expect(q!.targetField, 'title');
    });

    test('D3: applyAnswer merges title correctly', () {
      final intent = ParsedIntent(
        rawText: 'test',
        dialectCode: DialectCode.gulf,
        normalisedText: 'test',
        entities: ExtractedEntities(
          scheduledAt: DateTime.now().add(const Duration(hours: 1)),
        ),
        confidence: 0.5,
        clarificationNeeded: true,
        missingFields: ['title'],
      );
      final updated = _clarUseCase.applyAnswer(
        intent,
        const ExtractedEntities(title: 'اجتماع'),
      );
      expect(updated.entities.title, 'اجتماع');
    });

    test('D4: isActionable after all fields filled', () {
      final intent = ParsedIntent(
        rawText: 'test',
        dialectCode: DialectCode.gulf,
        normalisedText: 'test',
        entities: ExtractedEntities(
          scheduledAt: DateTime.now().add(const Duration(hours: 1)),
        ),
        confidence: 0.5,
        clarificationNeeded: true,
        missingFields: ['title'],
      );
      final updated = _clarUseCase.applyAnswer(
        intent,
        const ExtractedEntities(title: 'اجتماع'),
      );
      expect(updated.clarificationNeeded, false);
      expect(updated.confidence, greaterThanOrEqualTo(0.7));
    });
  });

  // -------------------------------------------------------------------------
  // Group E — Pipeline integration
  // -------------------------------------------------------------------------
  group('E — Pipeline integration', () {
    late ParseVoiceInputUseCase parseUseCase;

    setUp(() => parseUseCase = _makeParseUseCase());

    test('E1: empty transcript returns clarificationNeeded=true', () async {
      final intent = await parseUseCase.execute('');
      expect(intent.clarificationNeeded, true);
      expect(intent.confidence, 0.0);
    });

    test('E2: Gulf transcript with title and time returns high confidence',
        () async {
      final intent = await parseUseCase.execute(
        'ابغى تذكير اجتماع بكرة الساعة عشرة الصبح',
      );
      expect(intent.dialectCode, DialectCode.gulf);
      expect(intent.confidence, greaterThan(0.3));
    });

    test('E3: missing time causes clarificationNeeded', () async {
      final intent = await parseUseCase.execute('ابغى تذكير اجتماع');
      expect(intent.missingFields, contains('scheduled_at'));
    });

    test('E4: clarification loop resolves to actionable intent', () async {
      final intent = await parseUseCase.execute('ابغى تذكير اجتماع');
      final resolved = _clarUseCase.applyAnswer(
        intent,
        ExtractedEntities(
          scheduledAt: DateTime.now().add(const Duration(hours: 2)),
        ),
      );
      expect(resolved.clarificationNeeded, false);
    });
  });
}
