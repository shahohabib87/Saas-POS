enum PaymentMethod { cash, card }

class CompletedItem {
  final String name;
  final String emoji;
  final int quantity;
  final double unitPrice;
  final String modifiersLabel;

  const CompletedItem({
    required this.name,
    required this.emoji,
    required this.quantity,
    required this.unitPrice,
    this.modifiersLabel = '',
  });

  double get subtotal => unitPrice * quantity;
}

class CompletedPayment {
  final String id;
  final String orderNumber;
  final String orderType;
  final String staffName;

  // Table info (0 / empty for non-table orders)
  final String tableId;
  final int tableNumber;

  final List<CompletedItem> items;
  final double subtotal;
  final double discountAmount;
  final double tax;
  final double tip;
  final double total;

  final PaymentMethod method;
  final double cashPaid;
  final double cardPaid;
  final double change;

  final DateTime timestamp;

  // Delivery info — empty for every other order type. Captured at the till
  // because the driver needs it, and because the server builds the customer
  // book from it: SyncController upserts a Customer by customer_phone on every
  // delivery order, so this is the only way a customer is ever created.
  final String customerName;
  final String customerPhone;

  /// Landmark / street / floor. Maps to the server's `delivery_notes`, which
  /// seeds `Customer.directions` the first time we see this phone.
  final String deliveryNotes;

  final String? driverId;

  /// Not stored on the order server-side — it is what tells the customer
  /// upsert which area this person lives in. Must be a uuid or null.
  final String? deliveryAreaId;

  /// Charged on top of tax and already included in [total]. Sent separately
  /// too: `orders.delivery_fee` is a real column, and the receipt itemises it.
  final double deliveryFee;

  const CompletedPayment({
    required this.id,
    required this.orderNumber,
    required this.orderType,
    required this.staffName,
    required this.tableId,
    required this.tableNumber,
    required this.items,
    required this.subtotal,
    required this.discountAmount,
    required this.tax,
    required this.tip,
    required this.total,
    required this.method,
    required this.cashPaid,
    required this.cardPaid,
    required this.change,
    required this.timestamp,
    this.customerName = '',
    this.customerPhone = '',
    this.deliveryNotes = '',
    this.driverId,
    this.deliveryAreaId,
    this.deliveryFee = 0,
  });

  int get totalItems => items.fold(0, (s, i) => s + i.quantity);
}
