// test/sprint_3_9_test.dart
//
// Sprint 3.9 — Incremental tests (Groups A–E, built alongside each group)
// Run with: flutter test test/sprint_3_9_test.dart
//
// Group A — VoiceInputService (5 tests)

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tazakar/features/nlu/application/clarification_dialogue_use_case.dart';
import 'package:tazakar/features/nlu/application/parse_voice_input_use_case.dart';
import 'package:tazakar/features/nlu/domain/entities/parsed_intent.dart';
import 'package:tazakar/features/voice/application/voice_input_service.dart';
import 'package:tazakar/features/voice/domain/errors/voice_error.dart';
import 'package:tazakar/features/voice/domain/states/voice_input_state.dart';
import 'package:tazakar/infrastructure/platform/ai_channel.dart';

@GenerateMocks([ParseVoiceInputUseCase, AiChannel])
import 'sprint_3_9_test.mocks.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

final _dummyAudio = Uint8List.fromList([1, 2, 3]);

ParsedIntent _makeIntent({
  double confidence = 0.85,
  bool clarificationNeeded = false,
  List<String> missingFields = const [],
  DateTime? scheduledAt,
  String? title = 'الاجتماع',
}) {
  return ParsedIntent(
    rawText: 'ذكرني بالاجتماع',
    dialectCode: DialectCode.gulf,
    normalisedText: 'ذكرني بالاجتماع',
    entities: ExtractedEntities(
      title: title,
      scheduledAt:
          scheduledAt ?? DateTime.now().add(const Duration(hours: 1)),
    ),
    confidence: confidence,
    clarificationNeeded: clarificationNeeded,
    missingFields: missingFields,
  );
}

VoiceInputService _makeService(
  MockParseVoiceInputUseCase parseUseCase,
  MockAiChannel aiChannel,
) {
  return VoiceInputService(
    parseUseCase: parseUseCase,
    clarificationUseCase: const ClarificationDialogueUseCase(),
    aiChannel: aiChannel,
  );
}

// ---------------------------------------------------------------------------
// Group A — VoiceInputService
// ---------------------------------------------------------------------------

void main() {
  group('Group A — VoiceInputService', () {
    late MockParseVoiceInputUseCase mockParseUseCase;
    late MockAiChannel mockAiChannel;

    setUp(() {
      mockParseUseCase = MockParseVoiceInputUseCase();
      mockAiChannel = MockAiChannel();
    });

    // A-T1: happy path — collects all states then checks in order
    test(
        'A-T1: happy path emits Listening → Transcribing → VoiceParsedIntent',
        () async {
      when(mockAiChannel.startRecording()).thenAnswer((_) async => true);
      when(mockAiChannel.stopRecording())
          .thenAnswer((_) async => _dummyAudio);
      when(mockAiChannel.transcribeAudio(_dummyAudio))
          .thenAnswer((_) async => 'ذكرني بالاجتماع');
      when(mockParseUseCase.execute(any,
              dialectHint: anyNamed('dialectHint')))
          .thenAnswer((_) async => _makeIntent());

      final service = _makeService(mockParseUseCase, mockAiChannel);

      // Collect states emitted during startListening
      final statesFuture =
          service.stream.take(3).toList();

      await service.startListening();
      final states = await statesFuture;
      service.dispose();

      expect(states[0], isA<VoiceListening>());
      expect(states[1], isA<VoiceTranscribing>());
      expect(states[2], isA<VoiceParsedIntent>());
      expect((states[2] as VoiceParsedIntent).intent.entities.title,
          'الاجتماع');
    });

    // A-T2: mic denied — startRecording returns false
    test('A-T2: startRecording false → VoiceErrorState(micDenied)', () async {
      when(mockAiChannel.startRecording()).thenAnswer((_) async => false);

      final service = _makeService(mockParseUseCase, mockAiChannel);

      // Listening is emitted first, then the error
      final statesFuture = service.stream.take(2).toList();

      await service.startListening();
      final states = await statesFuture;
      service.dispose();

      expect(states.last, isA<VoiceErrorState>());
      expect((states.last as VoiceErrorState).error, VoiceError.micDenied);
    });

    // A-T3: stopRecording returns null → whisperTimeout
    test('A-T3: stopRecording null → VoiceErrorState(whisperTimeout)',
        () async {
      when(mockAiChannel.startRecording()).thenAnswer((_) async => true);
      when(mockAiChannel.stopRecording()).thenAnswer((_) async => null);

      final service = _makeService(mockParseUseCase, mockAiChannel);

      // Listening + Transcribing + Error = 3 states
      final statesFuture = service.stream.take(3).toList();

      await service.startListening();
      final states = await statesFuture;
      service.dispose();

      expect(states.last, isA<VoiceErrorState>());
      expect((states.last as VoiceErrorState).error,
          VoiceError.whisperTimeout);
    });

    // A-T4: missing scheduledAt → clarification triggered
    test(
        'A-T4: missing scheduledAt → VoiceClarifying with scheduled_at question',
        () async {
      when(mockAiChannel.startRecording()).thenAnswer((_) async => true);
      when(mockAiChannel.stopRecording())
          .thenAnswer((_) async => _dummyAudio);
      when(mockAiChannel.transcribeAudio(_dummyAudio))
          .thenAnswer((_) async => 'ذكرني');
      when(mockParseUseCase.execute(any,
              dialectHint: anyNamed('dialectHint')))
          .thenAnswer((_) async => _makeIntent(
                confidence: 0.4,
                clarificationNeeded: true,
                missingFields: ['scheduled_at'],
                scheduledAt: null,
              ));

      final service = _makeService(mockParseUseCase, mockAiChannel);

      final statesFuture = service.stream.take(3).toList();

      await service.startListening();
      final states = await statesFuture;
      service.dispose();

      expect(states.last, isA<VoiceClarifying>());
      expect(
          (states.last as VoiceClarifying).question.targetField,
          'scheduled_at');
    });

    // A-T5: applyClarification with complete entities → VoiceParsedIntent
    test(
        'A-T5: applyClarification with full entities → VoiceParsedIntent',
        () async {
      final service = _makeService(mockParseUseCase, mockAiChannel);

      final statesFuture = service.stream.take(1).toList();

      final original = _makeIntent(
        clarificationNeeded: true,
        missingFields: ['scheduled_at'],
        scheduledAt: null,
      );

      final updatedEntities = ExtractedEntities(
        title: 'الاجتماع',
        scheduledAt: DateTime.now().add(const Duration(hours: 2)),
      );

      service.applyClarification(original, updatedEntities);
      final states = await statesFuture;
      service.dispose();

      expect(states.last, isA<VoiceParsedIntent>());
    });
  });
}
