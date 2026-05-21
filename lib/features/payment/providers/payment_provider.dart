import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/features/payment/models/payment.dart';

class PaymentHistoryNotifier extends StateNotifier<List<CompletedPayment>> {
  PaymentHistoryNotifier() : super([]);

  void add(CompletedPayment payment) {
    state = [...state, payment];
  }
}

final paymentHistoryProvider =
    StateNotifierProvider<PaymentHistoryNotifier, List<CompletedPayment>>(
  (ref) => PaymentHistoryNotifier(),
);
