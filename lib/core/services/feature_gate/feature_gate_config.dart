import 'subscription_tier.dart';

/// Immutable configuration describing what each tier may do.
///
/// All limits are defined here in one place — never scattered across UI code.
class FeatureGateConfig {
  const FeatureGateConfig._();

  // ── Free-tier limits (DEC-22, DEC-26, DEC-27) ────────────────────────────

  /// Maximum reminders a Free user may have active simultaneously (DEC-22).
  static const int freeReminderCap = 10;

  /// Recurrence options available on the Free tier (DEC-26).
  /// Monthly only — daily/weekly/yearly/custom are Pro-only.
  static const Set<RecurrenceType> freeRecurrenceOptions = {
    RecurrenceType.monthly,
  };

  // ── Gate helpers ─────────────────────────────────────────────────────────

  /// Returns true if [tier] may create another reminder given [currentCount].
  static bool canCreateReminder(SubscriptionTier tier, int currentCount) {
    if (tier.isPro) return true;
    return currentCount < freeReminderCap;
  }

  /// Returns true if [tier] may use [recurrence].
  static bool canUseRecurrence(
      SubscriptionTier tier, RecurrenceType recurrence) {
    if (tier.isPro) return true;
    return freeRecurrenceOptions.contains(recurrence);
  }

  /// Returns true if [tier] may export local data (DEC-27).
  /// Export is Pro-only; Free tier has no export capability.
  static bool canExportData(SubscriptionTier tier) => tier.isPro;
}

/// All supported recurrence types across the app.
enum RecurrenceType {
  none,
  daily,
  weekly,
  monthly,
  yearly,
  custom;

  /// Human-readable Arabic label for each type.
  String get labelAr {
    switch (this) {
      case RecurrenceType.none:
        return 'مرة واحدة';
      case RecurrenceType.daily:
        return 'يومياً';
      case RecurrenceType.weekly:
        return 'أسبوعياً';
      case RecurrenceType.monthly:
        return 'شهرياً';
      case RecurrenceType.yearly:
        return 'سنوياً';
      case RecurrenceType.custom:
        return 'مخصص';
    }
  }

  /// Human-readable English label for each type.
  String get labelEn {
    switch (this) {
      case RecurrenceType.none:
        return 'Once';
      case RecurrenceType.daily:
        return 'Daily';
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.monthly:
        return 'Monthly';
      case RecurrenceType.yearly:
        return 'Yearly';
      case RecurrenceType.custom:
        return 'Custom';
    }
  }
}
