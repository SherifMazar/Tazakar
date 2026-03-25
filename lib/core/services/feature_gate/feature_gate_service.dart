import 'package:flutter/foundation.dart';
import 'subscription_tier.dart';
import 'feature_gate_config.dart';

/// Domain-layer service that evaluates feature gates for the active tier.
///
/// SC-07: At launch [monetisationActive] = false, so [effectiveTier] is always
/// [SubscriptionTier.pro] and no gate ever fires.  When Firebase Remote Config
/// flips MONETIZATION_ACTIVE to true, gates become live automatically.
class FeatureGateService {
  FeatureGateService({
    required bool monetisationActive,
    required SubscriptionTier storedTier,
  })  : _monetisationActive = monetisationActive,
        _storedTier = storedTier;

  final bool _monetisationActive;
  final SubscriptionTier _storedTier;

  /// The tier that actually governs gate checks.
  ///
  /// Returns [SubscriptionTier.pro] when monetisation is inactive (SC-07),
  /// otherwise returns the user's stored tier.
  SubscriptionTier get effectiveTier =>
      _monetisationActive ? _storedTier : SubscriptionTier.pro;

  // ── Public gate API ───────────────────────────────────────────────────────

  /// Whether the user may create another reminder.
  bool canCreateReminder(int currentCount) =>
      FeatureGateConfig.canCreateReminder(effectiveTier, currentCount);

  /// Whether the user may schedule with [recurrence].
  bool canUseRecurrence(RecurrenceType recurrence) =>
      FeatureGateConfig.canUseRecurrence(effectiveTier, recurrence);

  /// Whether the user may export their local data.
  bool get canExportData => FeatureGateConfig.canExportData(effectiveTier);

  /// Reminder cap for the effective tier (null = unlimited).
  int? get reminderCap =>
      effectiveTier.isFree ? FeatureGateConfig.freeReminderCap : null;

  /// Recurrence options available for the effective tier.
  Set<RecurrenceType> get availableRecurrenceOptions =>
      effectiveTier.isPro
          ? RecurrenceType.values.toSet()
          : FeatureGateConfig.freeRecurrenceOptions;

  @override
  String toString() =>
      'FeatureGateService(monetisationActive: $_monetisationActive, '
      'storedTier: $_storedTier, effectiveTier: $effectiveTier)';
}
