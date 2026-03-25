// lib/features/nlu/data/arabic_datetime_parser.dart
//
// Sprint 3.7 — Arabic DateTime Entity Extractor (F-V08)
// Pure Dart. Zero cloud calls. SC-01 compliant.
//
// Handles: explicit dates, explicit times, relative expressions (today/tomorrow/
// day names), hijri is NOT supported in v1 (OQ-12 logged for Phase 4).

import '../domain/entities/parsed_intent.dart';

/// Result from the datetime parser.
class DateTimeParseResult {
  final DateTime? scheduledAt;

  /// 0.0–1.0 confidence in the parsed result.
  final double confidence;

  const DateTimeParseResult({this.scheduledAt, this.confidence = 0.0});
}

class ArabicDateTimeParser {
  // ---------------------------------------------------------------------------
  // Time patterns (24-hour and 12-hour with Arabic AM/PM markers)
  // ---------------------------------------------------------------------------
  static final _timePattern = RegExp(
    r'(?:الساعة\s*)?(\d{1,2}):(\d{2})\s*(?:(ص|صباحاً|صباحا)|(م|مساءً|مساءا|ليلاً|ليلا))?',
  );

  // ---------------------------------------------------------------------------
  // Relative time tokens
  // ---------------------------------------------------------------------------
  static const _relativeDay = <String, int>{
    'اليوم': 0,
    'غداً': 1,
    'غدا': 1,
    'بعد غد': 2,
    'بعد غدٍ': 2,
    'بعد يومين': 2,
    'الأسبوع القادم': 7,
    'الأسبوع المقبل': 7,
    'الأسبوع الجاي': 7,
    'الأسبوع الجاية': 7,
  };

  static const _dayNames = <String, int>{
    'الأحد': DateTime.sunday,
    'الاثنين': DateTime.monday,
    'الإثنين': DateTime.monday,
    'الثلاثاء': DateTime.tuesday,
    'الأربعاء': DateTime.wednesday,
    'الخميس': DateTime.thursday,
    'الجمعة': DateTime.friday,
    'السبت': DateTime.saturday,
  };

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  DateTimeParseResult parse(String normalisedText, {DateTime? now}) {
    final base = now ?? DateTime.now();

    // 1. Try relative day expressions.
    final relResult = _parseRelativeDay(normalisedText, base);

    // 2. Try explicit day names.
    final dayResult = _parseDayName(normalisedText, base);

    // 3. Try explicit DD/MM or MM-DD patterns.
    final explicitResult = _parseExplicitDate(normalisedText, base);

    // 4. Extract time.
    final timeResult = _parseTime(normalisedText);

    // Choose the best date base.
    DateTime? dateBase;
    double dateConf = 0.0;

    if (explicitResult != null) {
      dateBase = explicitResult;
      dateConf = 0.9;
    } else if (relResult != null) {
      dateBase = relResult;
      dateConf = 0.85;
    } else if (dayResult != null) {
      dateBase = dayResult;
      dateConf = 0.8;
    }

    if (dateBase == null && timeResult == null) {
      return const DateTimeParseResult();
    }

    // Combine date + time.
    DateTime? scheduledAt;
    double finalConf = 0.0;

    if (dateBase != null && timeResult != null) {
      scheduledAt = DateTime(
        dateBase.year,
        dateBase.month,
        dateBase.day,
        timeResult.hour,
        timeResult.minute,
      );
      finalConf = (dateConf + timeResult.confidence) / 2.0;
    } else if (dateBase != null) {
      // No time — default to 09:00.
      scheduledAt = DateTime(
          dateBase.year, dateBase.month, dateBase.day, 9, 0);
      finalConf = dateConf * 0.8;
    } else if (timeResult != null) {
      // No date — assume today; if time already passed, use tomorrow.
      final candidate = DateTime(
          base.year, base.month, base.day, timeResult.hour, timeResult.minute);
      scheduledAt = candidate.isBefore(base)
          ? candidate.add(const Duration(days: 1))
          : candidate;
      finalConf = timeResult.confidence * 0.75;
    }

    return DateTimeParseResult(
      scheduledAt: scheduledAt,
      confidence: finalConf.clamp(0.0, 1.0),
    );
  }

  // ---------------------------------------------------------------------------
  // Private parsers
  // ---------------------------------------------------------------------------

  DateTime? _parseRelativeDay(String text, DateTime base) {
    for (final entry in _relativeDay.entries) {
      if (text.contains(entry.key)) {
        return base.add(Duration(days: entry.value));
      }
    }
    return null;
  }

  DateTime? _parseDayName(String text, DateTime base) {
    for (final entry in _dayNames.entries) {
      if (text.contains(entry.key)) {
        return _nextWeekday(base, entry.value);
      }
    }
    return null;
  }

  DateTime? _parseExplicitDate(String text, DateTime base) {
    // Pattern: DD/MM or D-M (Arabic numerals or ASCII).
    final pattern = RegExp(r'(\d{1,2})[/\-](\d{1,2})(?:[/\-](\d{2,4}))?');
    final match = pattern.firstMatch(text);
    if (match == null) return null;

    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    if (day == null || month == null) return null;

    int year = base.year;
    final rawYear = match.group(3);
    if (rawYear != null) {
      year = int.tryParse(rawYear) ?? base.year;
      if (year < 100) year += 2000;
    }

    try {
      final candidate = DateTime(year, month, day);
      // If date has passed this year, roll to next year.
      return candidate.isBefore(base) && rawYear == null
          ? DateTime(year + 1, month, day)
          : candidate;
    } catch (_) {
      return null;
    }
  }

  _TimeResult? _parseTime(String text) {
    final match = _timePattern.firstMatch(text);
    if (match == null) return null;

    final hour0 = int.tryParse(match.group(1)!);
    final minute0 = int.tryParse(match.group(2)!) ?? 0;
    if (hour0 == null || hour0 > 23 || minute0 > 59) return null;

    // group(4) = PM marker (م / مساءً / ليلاً)
    int hour = hour0;
    if (match.group(4) != null && hour < 12) hour += 12;

    return _TimeResult(hour: hour, minute: minute0, confidence: 0.9);
  }

  DateTime _nextWeekday(DateTime from, int weekday) {
    int daysUntil = weekday - from.weekday;
    if (daysUntil <= 0) daysUntil += 7;
    return from.add(Duration(days: daysUntil));
  }
}

class _TimeResult {
  final int hour;
  final int minute;
  final double confidence;

  const _TimeResult(
      {required this.hour, required this.minute, required this.confidence});
}
