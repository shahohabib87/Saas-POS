import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/database/app_database.dart';
import 'package:easycasher/core/database/database_provider.dart';
import 'package:easycasher/features/delivery/models/pending_delivery.dart';

/// Orders that are out with a driver and not yet paid. Kept in the KV store
/// (not a new table) on purpose — it rides in the existing settings store and
/// survives a restart with no schema change, exactly like the cloud outbox
/// does. (The migration is additive now, so a table would be safe too; this
/// just avoided a bump when the store was first added.)
class PendingDeliveriesNotifier extends StateNotifier<List<PendingDelivery>> {
  final AppDatabase _db;
  static const _key = 'pending_deliveries';

  PendingDeliveriesNotifier(this._db) : super(const []) {
    _load();
  }

  Future<void> _load() async {
    final raw = await _db.kvGet(_key);
    if (!mounted) return; // sync may invalidate/dispose us mid-load
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List;
      state = [
        for (final e in list) PendingDelivery.fromJson(e as Map<String, dynamic>),
      ];
    } catch (_) {
      // A corrupt blob must never wedge the till — start clean.
      state = const [];
    }
  }

  Future<void> _persist() async {
    await _db.kvSet(_key, jsonEncode([for (final d in state) d.toJson()]));
  }

  /// Send an order out with its driver.
  void add(PendingDelivery delivery) {
    state = [delivery, ...state];
    _persist();
  }

  /// Settle / remove an order once the driver has handed in the cash.
  void remove(String id) {
    state = state.where((d) => d.id != id).toList();
    _persist();
  }
}

final pendingDeliveriesProvider =
    StateNotifierProvider<PendingDeliveriesNotifier, List<PendingDelivery>>(
  (ref) => PendingDeliveriesNotifier(ref.watch(appDatabaseProvider)),
);

/// Out-for-delivery orders bucketed by driver, so the Delivery screen can show
/// how much each driver owes when they get back.
final deliveriesByDriverProvider =
    Provider<Map<String, List<PendingDelivery>>>((ref) {
  final all = ref.watch(pendingDeliveriesProvider);
  final map = <String, List<PendingDelivery>>{};
  for (final d in all) {
    (map[d.driverId] ??= []).add(d);
  }
  return map;
});
