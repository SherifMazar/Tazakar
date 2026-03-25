import 'package:flutter_test/flutter_test.dart';
import 'package:tazakar/core/services/feature_gate/feature_gate_service.dart';
import 'package:tazakar/core/services/feature_gate/feature_gate_config.dart';
import 'package:tazakar/core/services/feature_gate/subscription_tier.dart';

void main() {
  // ── SC-07: monetisation inactive → all Pro ────────────────────────────────
  group('SC-07 — monetisation inactive', () {
    late FeatureGateService sut;

    setUp(() {
      sut = FeatureGateService(
        monetisationActive: false,
        storedTier: SubscriptionTier.free,
      );
    });

    test('effectiveTier is pro regardless of storedTier', () {
      expect(sut.effectiveTier, SubscriptionTier.pro);
    });

    test('canCreateReminder returns true even at cap', () {
      expect(sut.canCreateReminder(10), isTrue);
      expect(sut.canCreateReminder(100), isTrue);
    });

    test('canUseRecurrence returns true for all types', () {
      for (final r in RecurrenceType.values) {
        expect(sut.canUseRecurrence(r), isTrue);
      }
    });

    test('canExportData is true', () {
      expect(sut.canExportData, isTrue);
    });

    test('reminderCap is null (unlimited)', () {
      expect(sut.reminderCap, isNull);
    });
  });

  // ── Free tier gates ───────────────────────────────────────────────────────
  group('Free tier — monetisation active', () {
    late FeatureGateService sut;

    setUp(() {
      sut = FeatureGateService(
        monetisationActive: true,
        storedTier: SubscriptionTier.free,
      );
    });

    test('effectiveTier is free', () {
      expect(sut.effectiveTier, SubscriptionTier.free);
    });

    test('canCreateReminder: allows up to cap', () {
      expect(sut.canCreateReminder(0), isTrue);
      expect(sut.canCreateReminder(9), isTrue);
    });

    test('canCreateReminder: blocks at cap', () {
      expect(sut.canCreateReminder(10), isFalse);
      expect(sut.canCreateReminder(11), isFalse);
    });

    test('reminderCap equals freeReminderCap', () {
      expect(sut.reminderCap, FeatureGateConfig.freeReminderCap);
    });

    test('canUseRecurrence: monthly allowed', () {
      expect(sut.canUseRecurrence(RecurrenceType.monthly), isTrue);
    });

    test('canUseRecurrence: daily/weekly/yearly/custom blocked', () {
      expect(sut.canUseRecurrence(RecurrenceType.daily), isFalse);
      expect(sut.canUseRecurrence(RecurrenceType.weekly), isFalse);
      expect(sut.canUseRecurrence(RecurrenceType.yearly), isFalse);
      expect(sut.canUseRecurrence(RecurrenceType.custom), isFalse);
    });

    test('canExportData is false', () {
      expect(sut.canExportData, isFalse);
    });

    test('availableRecurrenceOptions contains only monthly', () {
      expect(
        sut.availableRecurrenceOptions,
        {RecurrenceType.monthly},
      );
    });
  });

  // ── Pro tier gates ────────────────────────────────────────────────────────
  group('Pro tier — monetisation active', () {
    late FeatureGateService sut;

    setUp(() {
      sut = FeatureGateService(
        monetisationActive: true,
        storedTier: SubscriptionTier.pro,
      );
    });

    test('effectiveTier is pro', () {
      expect(sut.effectiveTier, SubscriptionTier.pro);
    });

    test('canCreateReminder: no cap', () {
      expect(sut.canCreateReminder(10), isTrue);
      expect(sut.canCreateReminder(1000), isTrue);
    });

    test('canUseRecurrence: all types allowed', () {
      for (final r in RecurrenceType.values) {
        expect(sut.canUseRecurrence(r), isTrue);
      }
    });

    test('canExportData is true', () {
      expect(sut.canExportData, isTrue);
    });

    test('reminderCap is null', () {
      expect(sut.reminderCap, isNull);
    });
  });
}
