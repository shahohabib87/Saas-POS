import 'package:flutter_riverpod/flutter_riverpod.dart';

enum OrderType { dineIn, takeaway, delivery }

enum AppView { pos, orders, kds }

final orderTypeProvider =
    StateProvider<OrderType>((ref) => OrderType.dineIn);

final tableNumberProvider = StateProvider<String>((ref) => '');

final orderNoteProvider = StateProvider<String>((ref) => '');

final appViewProvider = StateProvider<AppView>((ref) => AppView.pos);
