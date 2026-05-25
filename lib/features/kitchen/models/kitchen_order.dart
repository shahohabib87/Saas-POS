enum KotStatus { pending, inProgress, ready }

enum KotOrderType { dineIn, takeout, delivery, deliveryApp }

extension KotOrderTypeX on KotOrderType {
  String get label => switch (this) {
    KotOrderType.dineIn      => 'Dine-In',
    KotOrderType.takeout     => 'Takeout',
    KotOrderType.delivery    => 'Delivery',
    KotOrderType.deliveryApp => 'Delivery App',
  };
  int get priority => switch (this) {
    KotOrderType.dineIn      => 1,
    KotOrderType.deliveryApp => 2,
    KotOrderType.delivery    => 3,
    KotOrderType.takeout     => 4,
  };
}

class KotItem {
  final String name;
  final int quantity;
  final String modifierSummary;
  final double unitPrice;

  const KotItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.modifierSummary = '',
  });

  double get subtotal => unitPrice * quantity;
}

class KitchenOrder {
  final String id;
  final int kotNumber;
  final String tableId;
  final String tableLabel;
  final List<KotItem> items;
  final KotStatus status;
  final KotOrderType orderType;
  final DateTime createdAt;

  const KitchenOrder({
    required this.id,
    required this.kotNumber,
    required this.tableId,
    required this.tableLabel,
    required this.items,
    required this.status,
    required this.orderType,
    required this.createdAt,
  });

  KitchenOrder copyWith({
    KotStatus? status,
    List<KotItem>? items,
    String? tableId,
    String? tableLabel,
  }) => KitchenOrder(
        id: id,
        kotNumber: kotNumber,
        tableId: tableId ?? this.tableId,
        tableLabel: tableLabel ?? this.tableLabel,
        items: items ?? this.items,
        status: status ?? this.status,
        orderType: orderType,
        createdAt: createdAt,
      );

  Duration get elapsed => DateTime.now().difference(createdAt);

  double get total => items.fold(0.0, (s, i) => s + i.subtotal);
}
