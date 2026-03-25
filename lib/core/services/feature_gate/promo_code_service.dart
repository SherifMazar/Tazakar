import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'subscription_tier.dart';

/// Result of a promo code redemption attempt.
enum PromoRedemptionStatus {
  /// Code was valid and has been redeemed. Pro unlocked.
  success,

  /// Code does not exist in Firestore (invalid or already used).
  invalidOrUsed,

  /// Network unavailable — user should retry when online.
  networkError,

  /// Unexpected Firestore error.
  unknownError,
}

class PromoRedemptionResult {
  const PromoRedemptionResult({
    required this.status,
    this.errorMessage,
  });

  final PromoRedemptionStatus status;
  final String? errorMessage;

  bool get isSuccess => status == PromoRedemptionStatus.success;
}

/// Validates and redeems promo codes against the Firestore `promo_codes`
/// collection.
///
/// Flow:
///   1. Normalise the entered code (trim + uppercase).
///   2. Query Firestore for a document where `code == normalisedCode`.
///   3. If found → delete the document (single-use enforcement).
///   4. Caller is responsible for persisting the Pro unlock locally.
///
/// DEC-28: Firestore used exclusively for promo redemption. Only the
/// normalised code string is transmitted — no user data ever leaves
/// the device for any other purpose (FR-P02 narrow exception).
class PromoCodeService {
  PromoCodeService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _collection = 'promo_codes';
  static const String _codeField = 'code';

  /// Attempts to redeem [rawCode].
  ///
  /// Returns [PromoRedemptionResult] indicating outcome.
  /// On success the Firestore document is deleted — the code cannot be
  /// reused by any other device.
  Future<PromoRedemptionResult> redeemCode(String rawCode) async {
    final code = _normalise(rawCode);

    if (code.isEmpty) {
      return const PromoRedemptionResult(
        status: PromoRedemptionStatus.invalidOrUsed,
        errorMessage: 'Code cannot be empty.',
      );
    }

    try {
      // Query for the document matching this code.
      final snapshot = await _firestore
          .collection(_collection)
          .where(_codeField, isEqualTo: code)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        // Code not found — either invalid or already redeemed + deleted.
        return const PromoRedemptionResult(
          status: PromoRedemptionStatus.invalidOrUsed,
        );
      }

      // Delete the document — single-use enforcement (DEC-28).
      await snapshot.docs.first.reference.delete();

      return const PromoRedemptionResult(
        status: PromoRedemptionStatus.success,
      );
    } on FirebaseException catch (e) {
      debugPrint('[PromoCodeService] FirebaseException: ${e.code} ${e.message}');

      if (e.code == 'unavailable' || e.code == 'network-request-failed') {
        return PromoRedemptionResult(
          status: PromoRedemptionStatus.networkError,
          errorMessage: e.message,
        );
      }

      return PromoRedemptionResult(
        status: PromoRedemptionStatus.unknownError,
        errorMessage: e.message,
      );
    } catch (e) {
      debugPrint('[PromoCodeService] Unexpected error: $e');
      return PromoRedemptionResult(
        status: PromoRedemptionStatus.unknownError,
        errorMessage: e.toString(),
      );
    }
  }

  /// Normalises a user-entered code: trim whitespace, uppercase.
  String _normalise(String raw) => raw.trim().toUpperCase();
}
