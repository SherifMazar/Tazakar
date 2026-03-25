// lib/features/nlu/data/nlu_entity_extractor.dart
//
// Sprint 3.7 — NLU Entity Extractor (F-V08, F-V10)
// Extracts: title, recurrence type, category slug.
// Pure Dart heuristics — TFLite model integration for AraBERT NER is
// wired in NluRepositoryImpl and delegates back here for post-processing.

import '../domain/entities/parsed_intent.dart';

class NluEntityExtractor {
  // ---------------------------------------------------------------------------
  // Recurrence keyword table
  // ---------------------------------------------------------------------------
  static const _dailyTokens = [
    'يومياً', 'يوميا', 'كل يوم', 'يومي', 'كل يومٍ',
  ];
  static const _weeklyTokens = [
    'أسبوعياً', 'اسبوعيا', 'كل أسبوع', 'كل اسبوع', 'كل أسبوعٍ',
    'أسبوعي',
  ];
  static const _monthlyTokens = [
    'شهرياً', 'شهريا', 'كل شهر', 'شهري', 'كل شهرٍ',
  ];

  // ---------------------------------------------------------------------------
  // Category keyword table — aligned with 8 system categories in DB seed.
  // ---------------------------------------------------------------------------
  static const _categoryKeywords = <String, List<String>>{
    'work': [
      'اجتماع', 'ميتينج', 'عمل', 'مشروع', 'تقرير', 'بريد', 'ايميل',
      'مهمة', 'مهام', 'موعد عمل', 'مكتب', 'زميل', 'رئيس',
    ],
    'health': [
      'دواء', 'دكتور', 'طبيب', 'عيادة', 'مستشفى', 'موعد طبي',
      'علاج', 'فيتامين', 'رياضة', 'تمرين', 'نظام غذائي',
    ],
    'personal': [
      'شخصي', 'نفسي', 'عائلة', 'أهل', 'أصدقاء', 'صديق', 'بيت', 'منزل',
    ],
    'finance': [
      'فاتورة', 'دفع', 'راتب', 'بنك', 'حساب', 'إيجار', 'قسط', 'مصاريف',
      'ميزانية', 'ضريبة',
    ],
    'education': [
      'درس', 'مراجعة', 'امتحان', 'كورس', 'دورة', 'كتاب', 'مكتبة',
      'محاضرة', 'واجب',
    ],
    'travel': [
      'سفر', 'طيران', 'حجز', 'فندق', 'فيزا', 'جواز', 'رحلة', 'مطار',
    ],
    'shopping': [
      'تسوق', 'شراء', 'سوبرماركت', 'بقالة', 'مول', 'أوردر', 'طلب',
    ],
    'other': [],
  };

  // ---------------------------------------------------------------------------
  // Stopwords — stripped before title extraction.
  // ---------------------------------------------------------------------------
  static const _stopwords = [
    'ذكرني', 'تذكرني', 'ذكر', 'أريد', 'ابغى', 'أبغى', 'بدي', 'عايز',
    'عاوز', 'ممكن', 'من فضلك', 'لو سمحت', 'أضف', 'سجل', 'ضع',
  ];

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Extract recurrence type from normalised text.
  NluRecurrenceType extractRecurrence(String text) {
    for (final token in _dailyTokens) {
      if (text.contains(token)) return NluRecurrenceType.daily;
    }
    for (final token in _weeklyTokens) {
      if (text.contains(token)) return NluRecurrenceType.weekly;
    }
    for (final token in _monthlyTokens) {
      if (text.contains(token)) return NluRecurrenceType.monthly;
    }
    return NluRecurrenceType.none;
  }

  /// Extract category slug from normalised text.
  String? extractCategory(String text) {
    for (final entry in _categoryKeywords.entries) {
      if (entry.key == 'other') continue;
      for (final kw in entry.value) {
        if (text.contains(kw)) return entry.key;
      }
    }
    return null;
  }

  /// Extract reminder title from normalised text.
  ///
  /// Strategy:
  /// 1. Strip intent trigger stopwords.
  /// 2. Strip time/recurrence clauses.
  /// 3. Trim and return remainder.
  String? extractTitle(String text) {
    String working = text;

    // Strip intent trigger words.
    for (final sw in _stopwords) {
      working = working.replaceAll(sw, '');
    }

    // Strip recurrence tokens.
    for (final t in [..._dailyTokens, ..._weeklyTokens, ..._monthlyTokens]) {
      working = working.replaceAll(t, '');
    }

    // Strip common time expressions (rough heuristic).
    working = working
        .replaceAll(
            RegExp(
                r'(اليوم|غداً|غدا|بعد غد|الساعة|صباحاً|مساءً|ليلاً|في تمام|عند)'),
            '')
        .replaceAll(RegExp(r'\d{1,2}[:.،]\d{2}'), '')
        .replaceAll(RegExp(r'\d{1,2}[/\-]\d{1,2}'), '');

    // Strip punctuation and extra whitespace.
    working = working
        .replaceAll(RegExp(r'[،,؟?!.]'), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();

    return working.isEmpty ? null : working;
  }

  /// Assess completeness and return list of missing required fields.
  List<String> missingFields({
    required String? title,
    required DateTime? scheduledAt,
  }) {
    final missing = <String>[];
    if (title == null || title.isEmpty) missing.add('title');
    if (scheduledAt == null) missing.add('scheduled_at');
    return missing;
  }
}
