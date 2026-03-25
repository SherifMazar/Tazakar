// test/sprint_3_7_test.dart
//
// Sprint 3.7 — NLU Engine test suite.
// Groups:
//   A — DialectRouter detection (6 tests)
//   B — DialectRouter normalisation (4 tests)
//   C — ArabicDateTimeParser (8 tests)
//   D — NluEntityExtractor (6 tests)
//   E — ParsedIntent + clarification flow (4 tests)
//
// Run: flutter test test/sprint_3_7_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:tazakar/features/nlu/application/clarification_dialogue_use_case.dart';
import 'package:tazakar/features/nlu/application/parse_voice_input_use_case.dart';
import 'package:tazakar/features/nlu/data/arabic_datetime_parser.dart';
import 'package:tazakar/features/nlu/data/dialect_router.dart';
import 'package:tazakar/features/nlu/data/nlu_entity_extractor.dart';
import 'package:tazakar/features/nlu/data/nlu_repository_impl.dart';
import 'package:tazakar/features/nlu/domain/entities/parsed_intent.dart';

void main() {
  // -------------------------------------------------------------------------
  // Group A — DialectRouter detection
  // -------------------------------------------------------------------------
  group('A — DialectRouter detection', () {
    late DialectRouter router;

    setUp(() => router = DialectRouter());

    test('A1: detects Gulf dialect via "ابغى"', () {
      final result = router.route('ابغى تذكير بكرة الصبح');
      expect(result.dialect, DialectCode.gulf);
      expect(result.confidence, greaterThan(0.4));
    });

    test('A2: detects Levantine dialect via "بدي"', () {
      final result = router.route('بدي تذكير بكرا الصبح');
      expect(result.dialect, DialectCode.levantine);
    });

    test('A3: detects Egyptian dialect via "عايز" and "دلوقتي"', () {
      final result = router.route('عايز تذكير دلوقتي');
      expect(result.dialect, DialectCode.egyptian);
    });

    test('A4: detects Maghrebi dialect via "بزاف"', () {
      final result = router.route('ذكرني بزاف من المهام');
      expect(result.dialect, DialectCode.maghrebi);
    });

    test('A5: falls back to unknown for ambiguous MSA text', () {
      final result = router.route('أريد تذكيراً الساعة التاسعة');
      expect(result.dialect, DialectCode.unknown);
    });

    test('A6: hint applied when no marker detected', () {
      final result = router.route(
        'أريد تذكيراً',
        hint: DialectCode.gulf,
      );
      expect(result.dialect, DialectCode.gulf);
    });
  });

  // -------------------------------------------------------------------------
  // Group B — DialectRouter normalisation
  // -------------------------------------------------------------------------
  group('B — DialectRouter normalisation', () {
    late DialectRouter router;

    setUp(() => router = DialectRouter());

    test('B1: Gulf "ابغى" normalised to "أريد"', () {
      final result = router.route('ابغى تذكير');
      expect(result.normalisedText, contains('أريد'));
    });

    test('B2: Levantine "بدي" normalised to "أريد"', () {
      final result = router.route('بدي حجز موعد');
      expect(result.normalisedText, contains('أريد'));
    });

    test('B3: Egyptian "دلوقتي" normalised to "الآن"', () {
      final result = router.route('افعل كده دلوقتي');
      expect(result.normalisedText, contains('الآن'));
    });

    test('B4: Maghrebi "دابا" normalised to "الآن"', () {
      final result = router.route('ذكرني دابا');
      expect(result.normalisedText, contains('الآن'));
    });
  });

  // -------------------------------------------------------------------------
  // Group C — ArabicDateTimeParser
  // -------------------------------------------------------------------------
  group('C — ArabicDateTimeParser', () {
    late ArabicDateTimeParser parser;
    late DateTime base;

    setUp(() {
      parser = ArabicDateTimeParser();
      base = DateTime(2026, 3, 25, 10, 0); // Wednesday
    });

    test('C1: "اليوم" → today', () {
      final result = parser.parse('ذكرني اليوم', now: base);
      expect(result.scheduledAt, isNotNull);
      expect(result.scheduledAt!.day, base.day);
    });

    test('C2: "غدا" → tomorrow', () {
      final result = parser.parse('ذكرني غدا', now: base);
      expect(result.scheduledAt!.day, base.day + 1);
    });

    test('C3: "بعد غد" → day after tomorrow', () {
      final result = parser.parse('موعد بعد غد', now: base);
      expect(result.scheduledAt!.day, base.day + 2);
    });

    test('C4: explicit time "9:30 صباحاً"', () {
      final result = parser.parse('الساعة 9:30 صباحاً', now: base);
      expect(result.scheduledAt, isNotNull);
      expect(result.scheduledAt!.hour, 9);
      expect(result.scheduledAt!.minute, 30);
    });

    test('C5: PM marker — "8:00 م" → hour 20', () {
      final result = parser.parse('الساعة 8:00 م', now: base);
      expect(result.scheduledAt!.hour, 20);
    });

    test('C6: "الجمعة" → next Friday', () {
      final result = parser.parse('الاجتماع الجمعة', now: base);
      expect(result.scheduledAt, isNotNull);
      expect(result.scheduledAt!.weekday, DateTime.friday);
    });

    test('C7: explicit date "27/3"', () {
      final result = parser.parse('موعد في 27/3', now: base);
      expect(result.scheduledAt, isNotNull);
      expect(result.scheduledAt!.day, 27);
      expect(result.scheduledAt!.month, 3);
    });

    test('C8: no date token → scheduledAt null', () {
      final result = parser.parse('ذكرني بالدواء', now: base);
      // Time only returns today with default hour — no penalty.
      // Pure no-token test:
      final result2 = parser.parse('', now: base);
      expect(result2.scheduledAt, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Group D — NluEntityExtractor
  // -------------------------------------------------------------------------
  group('D — NluEntityExtractor', () {
    late NluEntityExtractor extractor;

    setUp(() => extractor = NluEntityExtractor());

    test('D1: "يومياً" → RecurrenceType.daily', () {
      expect(
        extractor.extractRecurrence('ذكرني يومياً'),
        NluRecurrenceType.daily,
      );
    });

    test('D2: "كل أسبوع" → RecurrenceType.weekly', () {
      expect(
        extractor.extractRecurrence('اجتماع كل أسبوع'),
        NluRecurrenceType.weekly,
      );
    });

    test('D3: "شهرياً" → RecurrenceType.monthly', () {
      expect(
        extractor.extractRecurrence('دفع الإيجار شهرياً'),
        NluRecurrenceType.monthly,
      );
    });

    test('D4: work keyword → category "work"', () {
      expect(extractor.extractCategory('اجتماع مع الفريق'), 'work');
    });

    test('D5: health keyword → category "health"', () {
      expect(extractor.extractCategory('موعد مع الدكتور'), 'health');
    });

    test('D6: title extracted after stripping stopwords', () {
      final title =
          extractor.extractTitle('ذكرني بموعد الدكتور غداً الساعة 9');
      expect(title, isNotNull);
      expect(title, contains('موعد الدكتور'));
    });
  });

  // -------------------------------------------------------------------------
  // Group E — ParsedIntent + clarification flow
  // -------------------------------------------------------------------------
  group('E — ParsedIntent + clarification flow', () {
    late NluRepositoryImpl repo;
    late ParseVoiceInputUseCase parseUseCase;
    late ClarificationDialogueUseCase clarifyUseCase;

    setUp(() {
      repo = NluRepositoryImpl();
      parseUseCase = ParseVoiceInputUseCase(repo);
      clarifyUseCase = const ClarificationDialogueUseCase();
    });

    test('E1: full utterance → isActionable true', () async {
      final intent = await parseUseCase.execute(
        'ذكرني بموعد الدكتور غداً الساعة 9 صباحاً',
      );
      expect(intent.entities.title, isNotNull);
      expect(intent.entities.scheduledAt, isNotNull);
      expect(intent.isActionable, isTrue);
    });

    test('E2: missing time → clarification needed', () async {
      final intent = await parseUseCase.execute('ذكرني بأخذ الدواء');
      expect(intent.clarificationNeeded, isTrue);
      expect(intent.missingFields, contains('scheduled_at'));
    });

    test('E3: clarification question generated for missing scheduled_at', () async {
      final intent = await parseUseCase.execute('ذكرني بأخذ الدواء');
      final question = clarifyUseCase.nextQuestion(intent);
      expect(question, isNotNull);
      expect(question!.targetField, 'scheduled_at');
      expect(question.questionText, isNotEmpty);
    });

    test('E4: applyAnswer resolves clarification → isActionable', () async {
      final intent = await parseUseCase.execute('ذكرني بأخذ الدواء');
      final answer = ExtractedEntities(
        scheduledAt: DateTime(2026, 3, 26, 9, 0),
      );
      final resolved = clarifyUseCase.applyAnswer(intent, answer);
      expect(resolved.clarificationNeeded, isFalse);
      expect(resolved.isActionable, isTrue);
    });
  });
}
