// lib/features/nlu/data/nlu_repository_impl.dart
//
// Sprint 3.7 — NluRepository implementation (F-V06 through F-V10, F-V14–F-V16)
// DEC-33: TFLite slot. Current implementation uses heuristic pipeline.
//         TFLite AraBERT model integration deferred to Phase 4 (OQ-13).
//         Architecture is structured so model can be dropped in without
//         changing the repository interface or use-case layer.
//
// SC-01 compliant: zero cloud calls. All processing on-device.

import '../domain/entities/parsed_intent.dart';
import '../domain/repositories/nlu_repository.dart';
import 'arabic_datetime_parser.dart';
import 'dialect_router.dart';
import 'nlu_entity_extractor.dart';

class NluRepositoryImpl implements NluRepository {
  final DialectRouter _dialectRouter;
  final ArabicDateTimeParser _dateTimeParser;
  final NluEntityExtractor _entityExtractor;

  NluRepositoryImpl({
    DialectRouter? dialectRouter,
    ArabicDateTimeParser? dateTimeParser,
    NluEntityExtractor? entityExtractor,
  })  : _dialectRouter = dialectRouter ?? DialectRouter(),
        _dateTimeParser = dateTimeParser ?? ArabicDateTimeParser(),
        _entityExtractor = entityExtractor ?? NluEntityExtractor();

  @override
  Future<ParsedIntent> parse(
    String rawText, {
    DialectCode? dialectHint,
  }) async {
    // 1. Dialect detection + normalisation.
    final routing = _dialectRouter.route(rawText, hint: dialectHint);

    // 2. DateTime extraction.
    final dtResult = _dateTimeParser.parse(routing.normalisedText);

    // 3. Entity extraction.
    final recurrence =
        _entityExtractor.extractRecurrence(routing.normalisedText);
    final category =
        _entityExtractor.extractCategory(routing.normalisedText);
    final title = _entityExtractor.extractTitle(routing.normalisedText);

    // 4. Missing field assessment.
    final missing = _entityExtractor.missingFields(
      title: title,
      scheduledAt: dtResult.scheduledAt,
    );

    final clarificationNeeded = missing.isNotEmpty;

    // 5. Composite confidence score.
    //    Weights: dialect (0.2), datetime (0.4), title presence (0.4).
    final titleScore = title != null ? 1.0 : 0.0;
    final compositeConf = (routing.confidence * 0.2) +
        (dtResult.confidence * 0.4) +
        (titleScore * 0.4);

    final entities = ExtractedEntities(
      scheduledAt: dtResult.scheduledAt,
      title: title,
      recurrenceType: recurrence,
      categorySlug: category,
    );

    return ParsedIntent(
      rawText: rawText,
      dialectCode: routing.dialect,
      normalisedText: routing.normalisedText,
      entities: entities,
      confidence: compositeConf.clamp(0.0, 1.0),
      clarificationNeeded: clarificationNeeded,
      missingFields: missing,
    );
  }

  @override
  Future<void> warmUp() async {
    // TFLite warm-up slot. No-op in heuristic implementation.
    // Phase 4 (OQ-13): load AraBERT TFLite model from assets here.
  }

  @override
  Future<void> dispose() async {
    // TFLite interpreter release slot.
  }
}
