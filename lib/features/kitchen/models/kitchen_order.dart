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

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'modifierSummary': modifierSummary,
      };

  factory KotItem.fromJson(Map<String, dynamic> j) => KotItem(
        name: '${j['name'] ?? ''}',
        quantity: (j['quantity'] as num?)?.toInt() ?? 1,
        unitPrice: (j['unitPrice'] as num?)?.toDouble() ?? 0,
        modifierSummary: '${j['modifierSummary'] ?? ''}',
      );
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

  // Tickets travel between the till and LAN kitchen displays as JSON, so a
  // shape surprise from a mismatched app version must never crash the board —
  // parse tolerantly and skip what can't be read.

  Map<String, dynamic> toJson() => {
        'id': id,
        'kotNumber': kotNumber,
        'tableId': tableId,
        'tableLabel': tableLabel,
        'items': [for (final i in items) i.toJson()],
        'status': status.name,
        'orderType': orderType.name,
        'createdAt': createdAt.toIso8601String(),
      };

  static KitchenOrder? tryFromJson(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    final id = raw['id'];
    if (id is! String || id.isEmpty) return null;
    return KitchenOrder(
      id: id,
      kotNumber: (raw['kotNumber'] as num?)?.toInt() ?? 1,
      tableId: '${raw['tableId'] ?? ''}',
      tableLabel: '${raw['tableLabel'] ?? ''}',
      items: [
        for (final e in (raw['items'] as List? ?? const []))
          if (e is Map<String, dynamic>) KotItem.fromJson(e),
      ],
      status: KotStatus.values.asNameMap()[raw['status']] ?? KotStatus.pending,
      orderType: KotOrderType.values.asNameMap()[raw['orderType']] ??
          KotOrderType.dineIn,
      createdAt:
          DateTime.tryParse('${raw['createdAt']}') ?? DateTime.now(),
    );
  }
}
