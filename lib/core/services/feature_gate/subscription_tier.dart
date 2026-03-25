/// Represents the user's current subscription tier.
///
/// Constitutional constraint: SC-07 — MONETIZATION_ACTIVE = false at launch.
/// When false, all users are treated as [SubscriptionTier.pro] so no gates
/// fire in production until monetisation is enabled via Remote Config.
enum SubscriptionTier {
  free,
  pro;

  bool get isPro => this == SubscriptionTier.pro;
  bool get isFree => this == SubscriptionTier.free;
}
