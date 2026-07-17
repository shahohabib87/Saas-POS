import 'package:flutter_test/flutter_test.dart';
import 'package:easycasher/core/entitlement/entitlement.dart';

/// This decides whether a paying customer's till keeps working, so the date
/// boundaries are pinned exactly. Mirrors Tenant::hasActiveAccess() plus the
/// terminal's grace window.
void main() {
  final now = DateTime.utc(2026, 7, 17, 12, 0);
  Entitlement trial(DateTime ends) =>
      Entitlement(status: 'trial', trialEndsAt: ends);
  Entitlement active(DateTime ends) =>
      Entitlement(status: 'active', subscriptionEndsAt: ends);

  group('level', () {
    test('active with plenty of time left is active', () {
      expect(active(now.add(const Duration(days: 30))).levelAt(now),
          EntitlementLevel.active);
    });

    test('within the warning window warns', () {
      expect(active(now.add(const Duration(days: 5))).levelAt(now),
          EntitlementLevel.warning);
      // Exactly at the warn threshold still warns.
      expect(active(now.add(const Duration(days: 7, hours: 1))).levelAt(now),
          EntitlementLevel.warning);
    });

    test('just past expiry is grace, not locked', () {
      expect(active(now.subtract(const Duration(hours: 1))).levelAt(now),
          EntitlementLevel.grace);
      expect(active(now.subtract(const Duration(days: 2))).levelAt(now),
          EntitlementLevel.grace);
    });

    test('past the grace window is locked', () {
      // graceDays = 3
      expect(active(now.subtract(const Duration(days: 4))).levelAt(now),
          EntitlementLevel.locked);
    });

    test('trial follows the same rules as a paid subscription', () {
      expect(trial(now.add(const Duration(days: 30))).levelAt(now),
          EntitlementLevel.active);
      expect(trial(now.subtract(const Duration(days: 4))).levelAt(now),
          EntitlementLevel.locked);
    });

    test('suspended and cancelled are locked regardless of dates', () {
      expect(
        Entitlement(status: 'suspended', subscriptionEndsAt: now.add(const Duration(days: 30)))
            .levelAt(now),
        EntitlementLevel.locked,
      );
      expect(Entitlement(status: 'cancelled').levelAt(now),
          EntitlementLevel.locked);
    });

    test('a null expiry date on an active status is locked, not open forever', () {
      expect(const Entitlement(status: 'active').levelAt(DateTime.utc(2026)),
          EntitlementLevel.locked);
    });

    test('unknown (never synced) is treated as active so a fresh install works',
        () {
      expect(const Entitlement().levelAt(now), EntitlementLevel.active);
      expect(const Entitlement().isUnknown, isTrue);
    });
  });

  group('new orders', () {
    test('blocked only once locked', () {
      expect(active(now.add(const Duration(days: 1))).canStartNewOrder(now), isTrue);
      expect(active(now.subtract(const Duration(days: 2))).canStartNewOrder(now),
          isTrue); // grace still sells
      expect(active(now.subtract(const Duration(days: 5))).canStartNewOrder(now),
          isFalse);
    });
  });

  group('messaging', () {
    test('days until expiry', () {
      expect(active(now.add(const Duration(days: 5, hours: 2))).daysUntilExpiry(now), 5);
      expect(active(now.subtract(const Duration(days: 1))).daysUntilExpiry(now), isNull);
    });

    test('grace days left', () {
      // Expired 1 day ago, 3-day grace → grace ends in 2 days.
      expect(active(now.subtract(const Duration(days: 1))).graceDaysLeft(now), 2);
      // Not expired yet → no grace figure.
      expect(active(now.add(const Duration(days: 1))).graceDaysLeft(now), isNull);
      // Well past grace → 0.
      expect(active(now.subtract(const Duration(days: 5))).graceDaysLeft(now), 0);
    });
  });

  group('parsing round-trip', () {
    test('from tenant json', () {
      final e = Entitlement.fromTenantJson({
        'status': 'active',
        'subscription_ends_at': '2026-08-01T00:00:00.000000Z',
        'trial_ends_at': null,
        'plan': 'pro',
      });
      expect(e.status, 'active');
      expect(e.subscriptionEndsAt, DateTime.utc(2026, 8, 1));
      expect(e.plan, 'pro');
    });

    test('blank status becomes unknown', () {
      expect(Entitlement.fromTenantJson({'status': ''}).status, 'unknown');
      expect(Entitlement.fromTenantJson({}).status, 'unknown');
    });

    test('kv survives a round trip', () {
      final e = active(DateTime.utc(2026, 8, 1));
      final back = Entitlement.fromKv(
          {...e.toKv(), 'entitlement_status': 'active'});
      expect(back.subscriptionEndsAt, e.subscriptionEndsAt);
      expect(back.status, 'active');
    });
  });
}
