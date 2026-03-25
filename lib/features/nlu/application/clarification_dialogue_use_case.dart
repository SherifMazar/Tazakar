// lib/features/nlu/application/clarification_dialogue_use_case.dart
//
// Sprint 3.7 — Clarification Dialogue (F-V14, F-V15, F-V16)
// Generates dialect-aware clarification prompts for missing entities.
// Immutable. No state.

import '../domain/entities/parsed_intent.dart';

/// A clarification question to present to the user.
class ClarificationQuestion {
  /// The question text in Arabic (dialect-aware).
  final String questionText;

  /// The field this question targets. E.g. 'title', 'scheduled_at'.
  final String targetField;

  const ClarificationQuestion({
    required this.questionText,
    required this.targetField,
  });
}

class ClarificationDialogueUseCase {
  const ClarificationDialogueUseCase();

  /// Returns the next clarification question for the first missing field.
  ///
  /// Returns null if [intent] is already complete ([clarificationNeeded] = false).
  ClarificationQuestion? nextQuestion(ParsedIntent intent) {
    if (!intent.clarificationNeeded || intent.missingFields.isEmpty) {
      return null;
    }

    final field = intent.missingFields.first;
    return ClarificationQuestion(
      questionText: _questionFor(field, intent.dialectCode),
      targetField: field,
    );
  }

  /// Returns all clarification questions needed (one per missing field).
  List<ClarificationQuestion> allQuestions(ParsedIntent intent) {
    return intent.missingFields
        .map((field) => ClarificationQuestion(
              questionText: _questionFor(field, intent.dialectCode),
              targetField: field,
            ))
        .toList();
  }

  /// Merge a clarification answer back into an existing [ParsedIntent].
  ///
  /// Called after the user responds to a clarification prompt.
  /// [updatedEntities] contains the corrected/added entities.
  ParsedIntent applyAnswer(
    ParsedIntent original,
    ExtractedEntities updatedEntities,
  ) {
    final merged = original.entities.copyWith(
      scheduledAt:
          updatedEntities.scheduledAt ?? original.entities.scheduledAt,
      title: updatedEntities.title ?? original.entities.title,
      recurrenceType: updatedEntities.recurrenceType != NluRecurrenceType.none
          ? updatedEntities.recurrenceType
          : original.entities.recurrenceType,
      categorySlug:
          updatedEntities.categorySlug ?? original.entities.categorySlug,
    );

    final missing = _computeMissing(merged);

    return ParsedIntent(
      rawText: original.rawText,
      dialectCode: original.dialectCode,
      normalisedText: original.normalisedText,
      entities: merged,
      confidence: missing.isEmpty ? 0.9 : original.confidence,
      clarificationNeeded: missing.isNotEmpty,
      missingFields: missing,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  String _questionFor(String field, DialectCode dialect) {
    return switch (field) {
      'title' => _titleQuestion(dialect),
      'scheduled_at' => _timeQuestion(dialect),
      _ => 'هل يمكنك إعطائي مزيداً من التفاصيل؟',
    };
  }

  String _titleQuestion(DialectCode dialect) {
    return switch (dialect) {
      DialectCode.gulf => 'شو التذكير اللي تبغاه؟',
      DialectCode.levantine => 'شو بدك تتذكر؟',
      DialectCode.egyptian => 'إيه اللي عايز تتذكره؟',
      DialectCode.maghrebi => 'شنو اللي تحب تتذكره؟',
      _ => 'ما الذي تريد أن تتذكره؟',
    };
  }

  String _timeQuestion(DialectCode dialect) {
    return switch (dialect) {
      DialectCode.gulf => 'وقتاه تبغى أذكرك؟',
      DialectCode.levantine => 'امتى بدك تتذكر؟',
      DialectCode.egyptian => 'إمتى عايز أفكرك؟',
      DialectCode.maghrebi => 'فوقاش تحب نذكرك؟',
      _ => 'متى تريد أن تُذكَّر؟',
    };
  }

  List<String> _computeMissing(ExtractedEntities entities) {
    final missing = <String>[];
    if (entities.title == null || entities.title!.isEmpty) {
      missing.add('title');
    }
    if (entities.scheduledAt == null) missing.add('scheduled_at');
    return missing;
  }
}
