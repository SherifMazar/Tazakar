import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'promo_code_service.dart';
import 'feature_gate_provider.dart';
import 'subscription_tier.dart';

/// Singleton PromoCodeService provider.
final promoCodeServiceProvider = Provider<PromoCodeService>(
  (ref) => PromoCodeService(),
);

/// State for the redemption flow.
class PromoRedemptionState {
  const PromoRedemptionState({
    this.isLoading = false,
    this.result,
  });

  final bool isLoading;
  final PromoRedemptionResult? result;

  PromoRedemptionState copyWith({
    bool? isLoading,
    PromoRedemptionResult? result,
  }) =>
      PromoRedemptionState(
        isLoading: isLoading ?? this.isLoading,
        result: result ?? this.result,
      );
}

/// Notifier that drives the promo code redemption UI.
///
/// On success it upgrades [storedTierProvider] to Pro so all feature
/// gates react immediately with no additional wiring.
class PromoCodeNotifier extends StateNotifier<PromoRedemptionState> {
  PromoCodeNotifier(this._ref) : super(const PromoRedemptionState());

  final Ref _ref;

  Future<void> redeem(String code) async {
    state = state.copyWith(isLoading: true, result: null);

    final service = _ref.read(promoCodeServiceProvider);
    final result = await service.redeemCode(code);

    if (result.isSuccess) {
      // Upgrade tier in-memory immediately — UI gates react at once.
      _ref.read(storedTierProvider.notifier).state = SubscriptionTier.pro;

      // TODO Sprint 4.1: persist SubscriptionTier.pro to app_settings table
      // via DatabaseService so the upgrade survives app restart.
    }

    state = state.copyWith(isLoading: false, result: result);
  }

  void reset() => state = const PromoRedemptionState();
}

final promoCodeNotifierProvider =
    StateNotifierProvider<PromoCodeNotifier, PromoRedemptionState>(
  (ref) => PromoCodeNotifier(ref),
);
