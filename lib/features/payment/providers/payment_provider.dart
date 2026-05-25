import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/database/app_database.dart';
import 'package:easycasher/core/database/database_provider.dart';
import 'package:easycasher/features/payment/models/payment.dart';

class PaymentHistoryNotifier extends StateNotifier<List<CompletedPayment>> {
  final AppDatabase _db;

  PaymentHistoryNotifier(this._db) : super([]) {
    _load();
  }

  Future<void> _load() async {
    state = await _db.getOrders();
  }

  void add(CompletedPayment payment) {
    state = [payment, ...state];
    _db.insertOrder(payment);
  }
}

final paymentHistoryProvider =
    StateNotifierProvider<PaymentHistoryNotifier, List<CompletedPayment>>(
  (ref) => PaymentHistoryNotifier(ref.watch(appDatabaseProvider)),
);
