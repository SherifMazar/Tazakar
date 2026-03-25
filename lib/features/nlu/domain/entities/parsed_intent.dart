// lib/features/nlu/domain/entities/parsed_intent.dart
//
// Sprint 3.7 — NLU Engine
// DEC-33: TFLite on-device NLU (CAMeL Tools / AraBERT variant). SC-01 compliant.
// Zero cloud calls. All inference on-device.

import 'package:equatable/equatable.dart';

/// Supported Arabic dialects for routing and entity extraction.
enum DialectCode {
  gulf('ar-AE'),
  levantine('ar-LB'),
  egyptian('ar-EG'),
  maghrebi('ar-MA'),
  unknown('ar');

  const DialectCode(this.bcp47);
  final String bcp47;

  static DialectCode fromBcp47(String code) {
    return DialectCode.values.firstWhere(
      (d) => d.bcp47 == code,
      orElse: () => DialectCode.unknown,
    );
  }
}

/// Recurrence type extracted from natural language.
/// Mirrors RecurrenceType in reminder domain — kept separate to avoid coupling.
enum NluRecurrenceType {
  none,
  daily,
  weekly,
  monthly,
}

/// Raw entities extracted from the Arabic utterance.
class ExtractedEntities extends Equatable {
  /// Resolved scheduled datetime. Null if not found or ambiguous.
  final DateTime? scheduledAt;

  /// Human-readable reminder title / subject text.
  final String? title;

  /// Recurrence type inferred from utterance.
  final NluRecurrenceType recurrenceType;

  /// Category slug matched against the 8 system categories.
  /// E.g. "health", "work", "personal". Null if unclassified.
  final String? categorySlug;

  const ExtractedEntities({
    this.scheduledAt,
    this.title,
    this.recurrenceType = NluRecurrenceType.none,
    this.categorySlug,
  });

  ExtractedEntities copyWith({
    DateTime? scheduledAt,
    String? title,
    NluRecurrenceType? recurrenceType,
    String? categorySlug,
  }) {
    return ExtractedEntities(
      scheduledAt: scheduledAt ?? this.scheduledAt,
      title: title ?? this.title,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      categorySlug: categorySlug ?? this.categorySlug,
    );
  }

  @override
  List<Object?> get props =>
      [scheduledAt, title, recurrenceType, categorySlug];
}

/// Full result of NLU processing on a single Arabic utterance.
class ParsedIntent extends Equatable {
  /// Original raw transcript from Whisper.
  final String rawText;

  /// Dialect detected by DialectRouter.
  final DialectCode dialectCode;

  /// Normalised text after dialect processing.
  final String normalisedText;

  /// Extracted entities from the utterance.
  final ExtractedEntities entities;

  /// Confidence score 0.0–1.0.
  /// Threshold for auto-create: >= 0.7 (F-V09).
  final double confidence;

  /// True when one or more required fields are ambiguous or missing.
  /// Triggers clarification dialogue (F-V14/F-V15).
  final bool clarificationNeeded;

  /// Which fields need clarification. Empty when [clarificationNeeded] = false.
  final List<String> missingFields;

  const ParsedIntent({
    required this.rawText,
    required this.dialectCode,
    required this.normalisedText,
    required this.entities,
    required this.confidence,
    this.clarificationNeeded = false,
    this.missingFields = const [],
  });

  /// Convenience: intent is complete enough to create a reminder directly.
  bool get isActionable =>
      !clarificationNeeded && confidence >= 0.7 && entities.title != null;

  @override
  List<Object?> get props => [
        rawText,
        dialectCode,
        normalisedText,
        entities,
        confidence,
        clarificationNeeded,
        missingFields,
      ];
}
