import 'package:flutter_riverpod/flutter_riverpod.dart';

enum OrderType { dineIn, takeaway, delivery, deliveryApp }

enum AppView { pos, orders, kds, delivery, talabat, settings, menu }

final orderTypeProvider =
    StateProvider<OrderType>((ref) => OrderType.dineIn);

final tableNumberProvider = StateProvider<String>((ref) => '');

final orderNoteProvider = StateProvider<String>((ref) => '');

final appViewProvider = StateProvider<AppView>((ref) => AppView.pos);

/// Auto-incrementing order counter — bump at the start of every new order.
final orderCounterProvider = StateProvider<int>((ref) => 1);

final orderNumberProvider = Provider<String>((ref) {
  final n = ref.watch(orderCounterProvider);
  return 'Order #${n.toString().padLeft(3, '0')}';
});


enum DiscountType { percent, fixed }

final discountTypeProvider = StateProvider<DiscountType>((ref) => DiscountType.percent);
final discountValueProvider = StateProvider<double>((ref) => 0.0);
