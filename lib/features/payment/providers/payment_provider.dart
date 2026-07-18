import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/database/app_database.dart';
import 'package:easycasher/core/database/database_provider.dart';
import 'package:easycasher/core/sync/cloud_sync.dart';
import 'package:easycasher/features/payment/models/payment.dart';

class PaymentHistoryNotifier extends StateNotifier<List<CompletedPayment>> {
  final AppDatabase _db;
  final Ref _ref;

  PaymentHistoryNotifier(this._db, this._ref) : super([]) {
    _load();
  }

  Future<void> _load() async {
    final rows = await _db.getOrders();
    if (!mounted) return; // sync may invalidate/dispose us mid-load
    state = rows;
  }

  void add(CompletedPayment payment) {
    state = [payment, ...state];
    _db.insertOrder(payment);
    // Queue for the cloud (outbox) — never blocks or fails the sale.
    _ref.read(cloudSyncProvider.notifier).enqueueSale(payment);
  }
}

final paymentHistoryProvider =
    StateNotifierProvider<PaymentHistoryNotifier, List<CompletedPayment>>(
  (ref) => PaymentHistoryNotifier(ref.watch(appDatabaseProvider), ref),
);
