// lib/features/nlu/data/dialect_router.dart
//
// Sprint 3.7 — Dialect Router (F-V06, F-V07)
// DEC-33: heuristic keyword matching + character n-gram scoring.
// Zero cloud calls. No external API.
//
// Coverage: Gulf (ar-AE), Levantine (ar-LB), Egyptian (ar-EG), Maghrebi (ar-MA).
// Maghrebi carries beta label (AQ-01 WER <85% threshold still validating).

import '../domain/entities/parsed_intent.dart';

/// Result from the dialect router.
class DialectRoutingResult {
  final DialectCode dialect;
  final String normalisedText;

  /// 0.0–1.0. Reflects router confidence in the detected dialect.
  final double confidence;

  const DialectRoutingResult({
    required this.dialect,
    required this.normalisedText,
    required this.confidence,
  });
}

class DialectRouter {
  // ---------------------------------------------------------------------------
  // Dialect keyword tables
  // Each entry is a unique marker lexeme for the dialect.
  // ---------------------------------------------------------------------------

  static const _gulfMarkers = <String>[
    'وين', 'ايش', 'شلونك', 'وايد', 'زين', 'چذي', 'يبه', 'هالحين',
    'بعدين', 'ابغى', 'أبغى', 'شفيه', 'تبغى', 'ذاك', 'هذاك',
  ];

  static const _levantineMarkers = <String>[
    'هيك', 'شو', 'كيفك', 'منيح', 'مش', 'هلق', 'هلأ', 'يلا',
    'بدي', 'بدك', 'رح', 'ما في', 'مافي', 'اشي', 'هيدا',
  ];

  static const _egyptianMarkers = <String>[
    'ازيك', 'إزيك', 'عامل', 'كده', 'كدا', 'إيه', 'ايه', 'دلوقتي',
    'مش عارف', 'اللي', 'مفيش', 'فين', 'عشان', 'يعني', 'بقى',
  ];

  static const _maghrebiMarkers = <String>[
    'واش', 'كيداير', 'كيران', 'بزاف', 'دابا', 'ماشي', 'خويا', 'درك',
    'علاش', 'شنو', 'كيفاش', 'تاني',
  ];

  // ---------------------------------------------------------------------------
  // Gulf normalisation map (dialect token → MSA equivalent)
  // ---------------------------------------------------------------------------
  static const _gulfNormMap = <String, String>{
    'ابغى': 'أريد',
    'أبغى': 'أريد',
    'تبغى': 'تريد',
    'وايد': 'كثيراً',
    'زين': 'جيد',
    'هالحين': 'الآن',
    'بعدين': 'بعد ذلك',
  };

  static const _levantineNormMap = <String, String>{
    'بدي': 'أريد',
    'بدك': 'تريد',
    'رح': 'سوف',
    'هلق': 'الآن',
    'هلأ': 'الآن',
    'مش': 'ليس',
    'شو': 'ماذا',
    'هيك': 'هكذا',
  };

  static const _egyptianNormMap = <String, String>{
    'كده': 'هكذا',
    'كدا': 'هكذا',
    'دلوقتي': 'الآن',
    'ايه': 'ما',
    'إيه': 'ما',
    'فين': 'أين',
    'مفيش': 'لا يوجد',
    'عشان': 'لأن',
    'بقى': '',
  };

  static const _maghrebiNormMap = <String, String>{
    'دابا': 'الآن',
    'بزاف': 'كثيراً',
    'ماشي': 'حسناً',
    'علاش': 'لماذا',
    'تاني': 'أيضاً',
  };

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Detect dialect and normalise text.
  DialectRoutingResult route(String rawText, {DialectCode? hint}) {
    final scores = _scoreAll(rawText);
    DialectCode best = DialectCode.unknown;
    double bestScore = 0.0;

    for (final entry in scores.entries) {
      if (entry.value > bestScore) {
        bestScore = entry.value;
        best = entry.key;
      }
    }

    // Apply hint only if no strong signal detected.
    if (bestScore < 0.15 && hint != null) {
      best = hint;
    }

    final normalised = _normalise(rawText, best);

    // Confidence derivation: if top score exceeds 2nd by > 0.1 → high confidence.
    final sorted = scores.values.toList()..sort((a, b) => b.compareTo(a));
    final gap = sorted.length >= 2 ? (sorted[0] - sorted[1]) : sorted[0];
    final confidence =
        (best == DialectCode.unknown) ? 0.3 : (0.5 + (gap * 2.0)).clamp(0.0, 1.0);

    return DialectRoutingResult(
      dialect: best,
      normalisedText: normalised,
      confidence: confidence,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Map<DialectCode, double> _scoreAll(String text) {
    return {
      DialectCode.gulf: _score(text, _gulfMarkers),
      DialectCode.levantine: _score(text, _levantineMarkers),
      DialectCode.egyptian: _score(text, _egyptianMarkers),
      DialectCode.maghrebi: _score(text, _maghrebiMarkers),
    };
  }

  double _score(String text, List<String> markers) {
    int hits = 0;
    final lower = text.toLowerCase();
    for (final marker in markers) {
      if (lower.contains(marker)) hits++;
    }
    // Normalise: max ~3 markers per short utterance.
    return (hits / 3.0).clamp(0.0, 1.0);
  }

  String _normalise(String text, DialectCode dialect) {
    final Map<String, String> normMap;
    switch (dialect) {
      case DialectCode.gulf:
        normMap = _gulfNormMap;
      case DialectCode.levantine:
        normMap = _levantineNormMap;
      case DialectCode.egyptian:
        normMap = _egyptianNormMap;
      case DialectCode.maghrebi:
        normMap = _maghrebiNormMap;
      case DialectCode.unknown:
        return text;
    }

    String result = text;
    for (final entry in normMap.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }
}
