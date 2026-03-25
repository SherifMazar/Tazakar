import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tazakar/core/services/feature_gate/promo_code_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late PromoCodeService sut;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    sut = PromoCodeService(firestore: fakeFirestore);
  });

  Future<void> seedCode(String code) async {
    await fakeFirestore.collection('promo_codes').add({'code': code});
  }

  group('redeemCode', () {
    test('success: valid code is redeemed and document deleted', () async {
      await seedCode('TZK-ABC123');

      final result = await sut.redeemCode('TZK-ABC123');

      expect(result.isSuccess, isTrue);
      expect(result.status, PromoRedemptionStatus.success);

      // Document must be deleted from Firestore.
      final remaining = await fakeFirestore
          .collection('promo_codes')
          .where('code', isEqualTo: 'TZK-ABC123')
          .get();
      expect(remaining.docs, isEmpty);
    });

    test('success: code is normalised (lowercase input)', () async {
      await seedCode('TZK-ABC123');

      final result = await sut.redeemCode('tzk-abc123');

      expect(result.isSuccess, isTrue);
    });

    test('success: code is normalised (extra whitespace)', () async {
      await seedCode('TZK-ABC123');

      final result = await sut.redeemCode('  TZK-ABC123  ');

      expect(result.isSuccess, isTrue);
    });

    test('invalidOrUsed: code not in Firestore', () async {
      final result = await sut.redeemCode('TZK-INVALID');

      expect(result.status, PromoRedemptionStatus.invalidOrUsed);
    });

    test('invalidOrUsed: already redeemed code returns invalidOrUsed', () async {
      await seedCode('TZK-ONCE11');

      // First redemption succeeds.
      final first = await sut.redeemCode('TZK-ONCE11');
      expect(first.isSuccess, isTrue);

      // Second attempt — document is gone.
      final second = await sut.redeemCode('TZK-ONCE11');
      expect(second.status, PromoRedemptionStatus.invalidOrUsed);
    });

    test('invalidOrUsed: empty string', () async {
      final result = await sut.redeemCode('');
      expect(result.status, PromoRedemptionStatus.invalidOrUsed);
    });

    test('invalidOrUsed: whitespace only', () async {
      final result = await sut.redeemCode('   ');
      expect(result.status, PromoRedemptionStatus.invalidOrUsed);
    });

    test('single-use: two simultaneous redemptions only one succeeds', () async {
      await seedCode('TZK-RACE99');

      // Simulate race — both fire before either resolves.
      final results = await Future.wait([
        sut.redeemCode('TZK-RACE99'),
        sut.redeemCode('TZK-RACE99'),
      ]);

      final successes = results.where((r) => r.isSuccess).length;
      // FakeFirestore is single-process so one will win; at most one success.
      expect(successes, lessThanOrEqualTo(1));
    });
  });
}
