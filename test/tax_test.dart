import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/database/app_database.dart';
import 'package:easycasher/core/database/database_provider.dart';
import 'package:easycasher/features/settings/models/app_settings.dart';
import 'package:easycasher/features/settings/providers/settings_provider.dart';

/// Tax used to be a hardcoded `AppConstants.taxRate = 0`, so enabling it in
/// Settings did nothing anywhere. It now flows from the tenant's settings via
/// `taxMultiplierProvider` — the single source the cart, payment screen and
/// receipt all read. These pin that behaviour.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting());
  tearDown(() => db.close());

  /// Seed the settings first so the notifier's async load reads the same value
  /// we assert on, then set it synchronously too, and drain the load before the
  /// db closes.
  Future<ProviderContainer> containerWith(AppSettings s) async {
    await db.saveSettings(s);
    final c = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(c.dispose);
    c.read(settingsProvider.notifier).update(s);
    return c;
  }

  test('tax is zero when disabled, whatever the rate', () async {
    final c = await containerWith(const AppSettings(taxEnabled: false, taxRate: 15));
    expect(c.read(taxMultiplierProvider), 0.0);
    await Future<void>.delayed(const Duration(milliseconds: 20));
  });

  test('an enabled rate applies as a fraction of the stored percent', () async {
    final c = await containerWith(const AppSettings(taxEnabled: true, taxRate: 15));
    expect(c.read(taxMultiplierProvider), 0.15);
    // A 10,000 bill is taxed 1,500 — the case the old hardcoded 0 always missed.
    expect(10000 * c.read(taxMultiplierProvider), 1500);
    await Future<void>.delayed(const Duration(milliseconds: 20));
  });

  test('a fresh install applies no tax until it is switched on', () async {
    final c = await containerWith(const AppSettings());
    expect(c.read(taxMultiplierProvider), 0.0);
    await Future<void>.delayed(const Duration(milliseconds: 20));
  });
}
