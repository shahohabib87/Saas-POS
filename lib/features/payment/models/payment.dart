enum PaymentMethod { cash, card }

class CompletedPayment {
  final String id;
  final String tableId;
  final int tableNumber;
  final double total;
  final PaymentMethod method;
  final double cashPaid;
  final double cardPaid;
  final double change;
  final DateTime timestamp;

  const CompletedPayment({
    required this.id,
    required this.tableId,
    required this.tableNumber,
    required this.total,
    required this.method,
    required this.cashPaid,
    required this.cardPaid,
    required this.change,
    required this.timestamp,
  });
}
