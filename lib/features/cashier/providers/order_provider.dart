import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/database/app_database.dart';
import 'package:easycasher/core/database/database_provider.dart';

/// How an order reaches us. `deliveryApp` is no longer offered as a till
/// button — those orders arrive from the aggregators — but the value stays:
/// it is persisted on past orders and is part of the `/api/sync` contract
/// (see cloud_sync.dart, which maps it to `delivery_app`).
enum OrderType { dineIn, takeaway, delivery, deliveryApp }

/// Screens this terminal can show. Menu and Reports intentionally absent —
/// they live in the web console now.
enum AppView { pos, orders, onlineOrders, kds, dispatch, settings }

final orderTypeProvider =
    StateProvider<OrderType>((ref) => OrderType.dineIn);

final tableNumberProvider = StateProvider<String>((ref) => '');

final orderNoteProvider = StateProvider<String>((ref) => '');

final appViewProvider = StateProvider<AppView>((ref) => AppView.pos);

class OrderCounterNotifier extends StateNotifier<int> {
  final AppDatabase _db;

  OrderCounterNotifier(this._db) : super(0) {
    _load();
  }

  Future<void> _load() async {
    state = await _db.loadTodayCounter();
  }

  void bump() {
    state = state + 1;
    _db.persistCounter(state);
  }
}

final orderCounterProvider =
    StateNotifierProvider<OrderCounterNotifier, int>(
  (ref) => OrderCounterNotifier(ref.watch(appDatabaseProvider)),
);

final orderNumberProvider = Provider<String>((ref) {
  final n = ref.watch(orderCounterProvider);
  return 'Order #${n.toString().padLeft(3, '0')}';
});


enum DiscountType { percent, fixed }

final discountTypeProvider = StateProvider<DiscountType>((ref) => DiscountType.percent);
final discountValueProvider = StateProvider<double>((ref) => 0.0);
