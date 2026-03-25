/// The outcome of a feature gate check, with an optional upgrade prompt.
///
/// Usage:
/// ```dart
/// final result = GateResult.check(
///   allowed: gates.canCreateReminder(count),
///   upsellMessageAr: 'لقد وصلت إلى الحد الأقصى للتذكيرات المجانية',
///   upsellMessageEn: 'You've reached the free reminder limit',
/// );
/// if (result.isDenied) showUpgradeSheet(result.upsellMessageAr);
/// ```
class GateResult {
  const GateResult._({
    required this.allowed,
    this.upsellMessageAr,
    this.upsellMessageEn,
  });

  final bool allowed;
  final String? upsellMessageAr;
  final String? upsellMessageEn;

  bool get isDenied => !allowed;

  factory GateResult.check({
    required bool allowed,
    String? upsellMessageAr,
    String? upsellMessageEn,
  }) =>
      GateResult._(
        allowed: allowed,
        upsellMessageAr: upsellMessageAr,
        upsellMessageEn: upsellMessageEn,
      );

  static const GateResult open = GateResult._(allowed: true);
}
