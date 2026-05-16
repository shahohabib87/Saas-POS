enum KotStatus { pending, inProgress, ready }

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
  final DateTime createdAt;

  const KitchenOrder({
    required this.id,
    required this.kotNumber,
    required this.tableId,
    required this.tableLabel,
    required this.items,
    required this.status,
    required this.createdAt,
  });

  KitchenOrder copyWith({KotStatus? status, List<KotItem>? items}) => KitchenOrder(
        id: id,
        kotNumber: kotNumber,
        tableId: tableId,
        tableLabel: tableLabel,
        items: items ?? this.items,
        status: status ?? this.status,
        createdAt: createdAt,
      );

  Duration get elapsed => DateTime.now().difference(createdAt);

  double get total => items.fold(0.0, (s, i) => s + i.subtotal);
}
