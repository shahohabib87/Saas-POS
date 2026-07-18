import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/features/cashier/models/cart_item.dart';
import 'package:easycasher/features/kitchen/models/kitchen_order.dart';

class KitchenNotifier extends StateNotifier<List<KitchenOrder>> {
  KitchenNotifier() : super([]);

  void send({
    required String tableId,
    required String tableLabel,
    required List<CartItem> cartItems,
    required KotOrderType orderType,
  }) {
    final kotNumber =
        state.where((o) => o.tableId == tableId).length + 1;

    final items = cartItems
        .map((ci) => KotItem(
              name: ci.item.name,
              quantity: ci.quantity,
              unitPrice: ci.unitPrice,
              modifierSummary: ci.modifierSummary,
            ))
        .toList();

    final order = KitchenOrder(
      id: '${tableId}_${DateTime.now().millisecondsSinceEpoch}',
      kotNumber: kotNumber,
      tableId: tableId,
      tableLabel: tableLabel,
      items: items,
      status: KotStatus.pending,
      orderType: orderType,
      createdAt: DateTime.now(),
    );

    state = [...state, order];
  }

  void bump(String id) {
    KitchenOrder? target;
    for (final o in state) {
      if (o.id == id) {
        target = o;
        break;
      }
    }
    if (target == null) return;

    // A finished takeout/delivery ticket has no open check to settle later, so
    // bumping it once it's ready clears it off the board (handed to the customer
    // / out with the driver). A dine-in ticket stays until the table pays.
    if (target.status == KotStatus.ready &&
        target.orderType != KotOrderType.dineIn) {
      state = state.where((o) => o.id != id).toList();
      return;
    }

    state = [
      for (final o in state)
        if (o.id == id)
          o.copyWith(
            status: switch (o.status) {
              KotStatus.pending    => KotStatus.inProgress,
              KotStatus.inProgress => KotStatus.ready,
              KotStatus.ready      => KotStatus.ready,
            },
          )
        else
          o,
    ];
  }

  void voidItem(String kotId, int itemIndex) {
    state = [
      for (final o in state)
        if (o.id == kotId)
          o.copyWith(
            items: [
              for (int i = 0; i < o.items.length; i++)
                if (i != itemIndex) o.items[i],
            ],
          )
        else
          o,
    ].where((o) => o.items.isNotEmpty).toList();
  }

  void clearTable(String tableId) {
    state = state.where((o) => o.tableId != tableId).toList();
  }

  void transferTable(String fromTableId, String toTableId) {
    final tableNum = toTableId.replaceAll(RegExp(r'[^0-9]'), '');
    state = [
      for (final o in state)
        if (o.tableId == fromTableId)
          o.copyWith(tableId: toTableId, tableLabel: 'Table $tableNum')
        else
          o,
    ];
  }

  int kotCountForTable(String tableId) =>
      state.where((o) => o.tableId == tableId).length;

  /// A KDS device mirrors the till: every snapshot that arrives over the LAN
  /// replaces the whole board. The till itself never calls this — it is the
  /// authority and mutates through send/bump/void.
  void replaceAll(List<KitchenOrder> orders) {
    state = orders;
  }
}

final kitchenProvider =
    StateNotifierProvider<KitchenNotifier, List<KitchenOrder>>(
  (ref) => KitchenNotifier(),
);

final activeKotsProvider = Provider<List<KitchenOrder>>(
  (ref) => ref
      .watch(kitchenProvider)
      .where((o) => o.status != KotStatus.ready)
      .toList(),
);

final pendingKotCountProvider = Provider<int>(
  (ref) => ref.watch(activeKotsProvider).length,
);

final tableKotsProvider =
    Provider.family<List<KitchenOrder>, String>((ref, tableId) {
  return ref
      .watch(kitchenProvider)
      .where((o) => o.tableId == tableId)
      .toList();
});

final tableKotTotalProvider =
    Provider.family<double, String>((ref, tableId) {
  return ref
      .watch(tableKotsProvider(tableId))
      .fold(0.0, (sum, o) => sum + o.total);
});
