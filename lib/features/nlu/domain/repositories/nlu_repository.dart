// lib/features/nlu/domain/repositories/nlu_repository.dart
//
// Sprint 3.7 — NLU Engine
// Abstract contract. Implementation is TFLite-backed (NluRepositoryImpl).

import '../entities/parsed_intent.dart';

abstract class NluRepository {
  /// Parse a raw Arabic utterance into a [ParsedIntent].
  ///
  /// [rawText]     — transcript from Whisper channel.
  /// [dialectHint] — optional caller-supplied hint; router may override.
  Future<ParsedIntent> parse(
    String rawText, {
    DialectCode? dialectHint,
  });

  /// Warm up the TFLite interpreter. Call once on app init (optional).
  Future<void> warmUp();

  /// Release native resources. Call on dispose.
  Future<void> dispose();
}
