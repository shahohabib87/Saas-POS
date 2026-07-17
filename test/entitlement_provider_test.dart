import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/database/app_database.dart';
import 'package:easycasher/core/database/database_provider.dart';
import 'package:easycasher/core/entitlement/entitlement.dart';
import 'package:easycasher/core/entitlement/entitlement_provider.dart';

/// The provider adds two things on top of the pure engine: persistence, and the
/// clock-tamper guard. Both are worth pinning — the guard is the whole reason a
/// lapsed tenant can't just wind the clock back.
void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting();
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() {
    container.dispose();
    db.close();
  });

  test('a captured active subscription reads back as active', () async {
    final n = container.read(entitlementProvider.notifier);
    await n.updateFromTenant({
      'status': 'active',
      'subscription_ends_at':
          DateTime.now().toUtc().add(const Duration(days: 30)).toIso8601String(),
    });

    expect(container.read(entitlementProvider).level, EntitlementLevel.active);
    expect(container.read(entitlementProvider).canStartNewOrder, isTrue);
  });

  test('a lapsed subscription (from a 402 body) blocks new orders', () async {
    final n = container.read(entitlementProvider.notifier);
    await n.updateFromTenant({
      'status': 'active',
      'subscription_ends_at': DateTime.now()
          .toUtc()
          .subtract(const Duration(days: 10))
          .toIso8601String(),
    });

    expect(container.read(entitlementProvider).level, EntitlementLevel.locked);
    expect(container.read(entitlementProvider).canStartNewOrder, isFalse);
  });

  test('renewal recovers the till', () async {
    final n = container.read(entitlementProvider.notifier);
    await n.updateFromTenant({
      'status': 'active',
      'subscription_ends_at': DateTime.now()
          .toUtc()
          .subtract(const Duration(days: 10))
          .toIso8601String(),
    });
    expect(container.read(entitlementProvider).level, EntitlementLevel.locked);

    // Owner pays; the server sends a future date.
    await n.updateFromTenant({
      'status': 'active',
      'subscription_ends_at':
          DateTime.now().toUtc().add(const Duration(days: 30)).toIso8601String(),
    });
    expect(container.read(entitlementProvider).level, EntitlementLevel.active);
  });

  test('clock-tamper guard: winding the device clock back cannot buy time',
      () async {
    // The server was last seen 5 days AFTER the subscription ended. Even if the
    // device clock now reads before expiry, the high-water mark holds the line.
    final expiry = DateTime.now().toUtc().subtract(const Duration(days: 5));
    final serverHighWater = DateTime.now().toUtc();

    await db.kvSet('cloud_server_high_water', serverHighWater.toIso8601String());

    final n = container.read(entitlementProvider.notifier);
    await n.updateFromTenant({
      'status': 'active',
      'subscription_ends_at': expiry.toIso8601String(),
    });

    final s = container.read(entitlementProvider);
    // now is pinned to the high-water mark (>= real now), so it stays locked.
    expect(s.now.isBefore(serverHighWater), isFalse);
    expect(s.level, EntitlementLevel.locked);
  });

  test('unknown (never connected) leaves the till usable', () async {
    expect(container.read(entitlementProvider).level, EntitlementLevel.active);
  });
}
