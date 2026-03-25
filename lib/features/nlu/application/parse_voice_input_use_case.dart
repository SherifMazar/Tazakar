// lib/features/nlu/application/parse_voice_input_use_case.dart
//
// Sprint 3.7 — ParseVoiceInputUseCase (F-V05, F-V09)
// Entry point for all voice-to-intent parsing.
// Called by the AI platform channel handler after Whisper transcription.

import '../domain/entities/parsed_intent.dart';
import '../domain/repositories/nlu_repository.dart';

class ParseVoiceInputUseCase {
  final NluRepository _nluRepository;

  const ParseVoiceInputUseCase(this._nluRepository);

  /// Parse a Whisper transcript into a [ParsedIntent].
  ///
  /// [transcript]  — raw text from Whisper.
  /// [dialectHint] — optional hint from the Whisper channel metadata.
  Future<ParsedIntent> execute(
    String transcript, {
    DialectCode? dialectHint,
  }) async {
    if (transcript.trim().isEmpty) {
      return ParsedIntent(
        rawText: transcript,
        dialectCode: dialectHint ?? DialectCode.unknown,
        normalisedText: transcript,
        entities: const ExtractedEntities(),
        confidence: 0.0,
        clarificationNeeded: true,
        missingFields: ['title', 'scheduled_at'],
      );
    }

    return _nluRepository.parse(transcript, dialectHint: dialectHint);
  }
}
