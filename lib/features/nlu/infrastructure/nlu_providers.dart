// lib/features/nlu/infrastructure/nlu_providers.dart
//
// Sprint 3.7 — Riverpod providers for NLU feature.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/clarification_dialogue_use_case.dart';
import '../application/parse_voice_input_use_case.dart';
import '../data/arabic_datetime_parser.dart';
import '../data/dialect_router.dart';
import '../data/nlu_entity_extractor.dart';
import '../data/nlu_repository_impl.dart';
import '../domain/repositories/nlu_repository.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

final dialectRouterProvider = Provider<DialectRouter>(
  (_) => DialectRouter(),
);

final arabicDateTimeParserProvider = Provider<ArabicDateTimeParser>(
  (_) => ArabicDateTimeParser(),
);

final nluEntityExtractorProvider = Provider<NluEntityExtractor>(
  (_) => NluEntityExtractor(),
);

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

final nluRepositoryProvider = Provider<NluRepository>((ref) {
  return NluRepositoryImpl(
    dialectRouter: ref.watch(dialectRouterProvider),
    dateTimeParser: ref.watch(arabicDateTimeParserProvider),
    entityExtractor: ref.watch(nluEntityExtractorProvider),
  );
});

// ---------------------------------------------------------------------------
// Use-case providers
// ---------------------------------------------------------------------------

final parseVoiceInputUseCaseProvider = Provider<ParseVoiceInputUseCase>((ref) {
  return ParseVoiceInputUseCase(ref.watch(nluRepositoryProvider));
});

final clarificationDialogueUseCaseProvider =
    Provider<ClarificationDialogueUseCase>(
  (_) => const ClarificationDialogueUseCase(),
);
