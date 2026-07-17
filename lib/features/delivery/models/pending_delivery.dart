import 'package:easycasher/features/payment/models/payment.dart';

/// An order that has left with a driver but has not been paid for yet.
///
/// Own-delivery here is cash on delivery: the driver collects the money from
/// the customer and hands it in when they get back. The order sits in this
/// list — persisted so it survives a restart while the driver is out — until
/// the cashier settles it on the Delivery screen, at which point it becomes a
/// normal completed cash sale.
class PendingDelivery {
  final String id;
  final String orderNumber;
  final String staffName;

  final String driverId;
  final String driverName;

  final String customerName;
  final String customerPhone;
  final String deliveryNotes;
  final String? areaId;
  final double deliveryFee;

  final List<CompletedItem> items;
  final double subtotal;
  final double discountAmount;
  final double tax;
  final double total;

  final DateTime placedAt;

  const PendingDelivery({
    required this.id,
    required this.orderNumber,
    required this.staffName,
    required this.driverId,
    required this.driverName,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryNotes,
    required this.areaId,
    required this.deliveryFee,
    required this.items,
    required this.subtotal,
    required this.discountAmount,
    required this.tax,
    required this.total,
    required this.placedAt,
  });

  int get totalItems => items.fold(0, (s, i) => s + i.quantity);

  /// Turn the settled delivery into the cash sale it always was — the driver
  /// tendered the exact total, so there is no change. Recorded through the
  /// normal payment path, it lands in the shift takings and syncs to the cloud.
  CompletedPayment toCompletedPayment({required String collectedBy}) {
    return CompletedPayment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      orderNumber: orderNumber,
      orderType: 'Delivery',
      staffName: collectedBy,
      tableId: '',
      tableNumber: 0,
      items: items,
      subtotal: subtotal,
      discountAmount: discountAmount,
      tax: tax,
      tip: 0,
      total: total,
      method: PaymentMethod.cash,
      cashPaid: total,
      cardPaid: 0,
      change: 0,
      timestamp: DateTime.now(),
      customerName: customerName,
      customerPhone: customerPhone,
      deliveryNotes: deliveryNotes,
      driverId: driverId,
      deliveryAreaId: areaId,
      deliveryFee: deliveryFee,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderNumber': orderNumber,
        'staffName': staffName,
        'driverId': driverId,
        'driverName': driverName,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'deliveryNotes': deliveryNotes,
        'areaId': areaId,
        'deliveryFee': deliveryFee,
        'subtotal': subtotal,
        'discountAmount': discountAmount,
        'tax': tax,
        'total': total,
        'placedAt': placedAt.toIso8601String(),
        'items': [
          for (final i in items)
            {
              'name': i.name,
              'emoji': i.emoji,
              'quantity': i.quantity,
              'unitPrice': i.unitPrice,
              'modifiersLabel': i.modifiersLabel,
            },
        ],
      };

  static PendingDelivery fromJson(Map<String, dynamic> j) {
    double d(dynamic v) => (v as num?)?.toDouble() ?? 0;
    return PendingDelivery(
      id: '${j['id']}',
      orderNumber: '${j['orderNumber'] ?? ''}',
      staffName: '${j['staffName'] ?? ''}',
      driverId: '${j['driverId'] ?? ''}',
      driverName: '${j['driverName'] ?? ''}',
      customerName: '${j['customerName'] ?? ''}',
      customerPhone: '${j['customerPhone'] ?? ''}',
      deliveryNotes: '${j['deliveryNotes'] ?? ''}',
      areaId: j['areaId'] as String?,
      deliveryFee: d(j['deliveryFee']),
      subtotal: d(j['subtotal']),
      discountAmount: d(j['discountAmount']),
      tax: d(j['tax']),
      total: d(j['total']),
      placedAt: DateTime.tryParse('${j['placedAt']}') ?? DateTime.now(),
      items: [
        for (final raw in (j['items'] as List? ?? const []))
          CompletedItem(
            name: '${raw['name'] ?? ''}',
            emoji: '${raw['emoji'] ?? '🍽️'}',
            quantity: (raw['quantity'] as num?)?.toInt() ?? 1,
            unitPrice: d(raw['unitPrice']),
            modifiersLabel: '${raw['modifiersLabel'] ?? ''}',
          ),
      ],
    );
  }
}
