import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/database/app_database.dart';
import 'package:easycasher/core/database/database_provider.dart';
import 'package:easycasher/core/entitlement/entitlement.dart';

/// Reads the cached subscription and judges it against a clock-guarded "now".
///
/// The device never trusts its own clock alone: a lapsed tenant could wind it
/// back to before expiry. So the effective now is `max(deviceNow, highWater)`,
/// where highWater is the latest server time this device has ever seen
/// (advanced from every sync's `server_time`). Winding the clock back only
/// makes enforcement stricter, never looser.
class EntitlementState {
  final Entitlement entitlement;
  final DateTime now; // the guarded now used for evaluation
  final bool clockSuspect; // device clock is behind the server high-water mark

  const EntitlementState({
    required this.entitlement,
    required this.now,
    this.clockSuspect = false,
  });

  EntitlementLevel get level => entitlement.levelAt(now);
  bool get canStartNewOrder => entitlement.canStartNewOrder(now);
  int? get daysUntilExpiry => entitlement.daysUntilExpiry(now);
  int? get graceDaysLeft => entitlement.graceDaysLeft(now);
}

class EntitlementNotifier extends StateNotifier<EntitlementState> {
  final AppDatabase _db;

  EntitlementNotifier(this._db)
      : super(EntitlementState(
          entitlement: const Entitlement(),
          now: DateTime.now().toUtc(),
        )) {
    refresh();
  }

  static const _highWaterKey = 'cloud_server_high_water';

  Future<DateTime> _guardedNow() async {
    final device = DateTime.now().toUtc();
    final hwRaw = await _db.kvGet(_highWaterKey);
    final hw = hwRaw == null ? null : DateTime.tryParse(hwRaw);
    if (hw != null && hw.isAfter(device)) return hw;
    return device;
  }

  /// Re-read the cached entitlement and re-evaluate. Cheap; call on launch and
  /// whenever the subscription state may have changed (after sync / on 402).
  Future<void> refresh() async {
    final ent = Entitlement.fromKv({
      'entitlement_status': await _db.kvGet('entitlement_status'),
      'entitlement_trial_ends': await _db.kvGet('entitlement_trial_ends'),
      'entitlement_sub_ends': await _db.kvGet('entitlement_sub_ends'),
      'entitlement_plan': await _db.kvGet('entitlement_plan'),
    });
    final device = DateTime.now().toUtc();
    final now = await _guardedNow();
    state = EntitlementState(
      entitlement: ent,
      now: now,
      clockSuspect: now.isAfter(device),
    );
  }

  /// Persist a fresh tenant object (from login, /me, or a 402 body) and
  /// re-evaluate.
  Future<void> updateFromTenant(Map<String, dynamic> tenantJson) async {
    final ent = Entitlement.fromTenantJson(tenantJson);
    for (final entry in ent.toKv().entries) {
      await _db.kvSet(entry.key, entry.value);
    }
    await refresh();
  }
}

final entitlementProvider =
    StateNotifierProvider<EntitlementNotifier, EntitlementState>((ref) {
  return EntitlementNotifier(ref.watch(appDatabaseProvider));
});
