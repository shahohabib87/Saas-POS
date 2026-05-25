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
  });

  int get totalItems => items.fold(0, (s, i) => s + i.quantity);
}
