import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'subscription_tier.dart';
import 'feature_gate_service.dart';

// ---------------------------------------------------------------------------
// Internal primitive providers — swap these when Remote Config is wired.
// ---------------------------------------------------------------------------

/// Reflects Firebase Remote Config MONETIZATION_ACTIVE flag.
/// Defaults to false at launch (SC-07).
final monetisationActiveProvider = StateProvider<bool>((ref) => false);

/// The user's stored subscription tier (persisted in app_settings table).
/// Defaults to free; upgraded by in-app purchase flow.
final storedTierProvider =
    StateProvider<SubscriptionTier>((ref) => SubscriptionTier.free);

// ---------------------------------------------------------------------------
// FeatureGateService provider
// ---------------------------------------------------------------------------

/// App-wide feature gate service.
///
/// Rebuilds automatically when [monetisationActiveProvider] or
/// [storedTierProvider] changes — UI gates react with no extra wiring.
final featureGateProvider = Provider<FeatureGateService>((ref) {
  final monetisationActive = ref.watch(monetisationActiveProvider);
  final storedTier = ref.watch(storedTierProvider);

  return FeatureGateService(
    monetisationActive: monetisationActive,
    storedTier: storedTier,
  );
});

// ---------------------------------------------------------------------------
// Convenience derived providers — use these directly in widgets
// ---------------------------------------------------------------------------

/// True when the user's effective tier is Pro.
final isProProvider = Provider<bool>(
  (ref) => ref.watch(featureGateProvider).effectiveTier.isPro,
);

/// Reminder cap for the current tier (null = unlimited).
final reminderCapProvider = Provider<int?>(
  (ref) => ref.watch(featureGateProvider).reminderCap,
);

/// Recurrence options available for the current tier.
final availableRecurrenceProvider = Provider<Set<RecurrenceType>>(
  (ref) => ref.watch(featureGateProvider).availableRecurrenceOptions,
);

/// Whether the current tier may export data.
final canExportDataProvider = Provider<bool>(
  (ref) => ref.watch(featureGateProvider).canExportData,
);
