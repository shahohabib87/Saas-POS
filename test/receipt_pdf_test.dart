import 'package:flutter_test/flutter_test.dart';
import 'package:easycasher/features/payment/models/payment.dart';
import 'package:easycasher/features/payment/services/receipt_pdf.dart';
import 'package:easycasher/features/settings/models/app_settings.dart';

/// The Print button used to only show a toast. It now builds a real PDF; this
/// exercises the builder end-to-end (no printer needed) so a broken receipt is
/// caught in CI rather than at the counter.
void main() {
  CompletedPayment sample({double tax = 750, double change = 500}) =>
      CompletedPayment(
        id: '1',
        orderNumber: 'Order #001',
        orderType: 'Takeout',
        staffName: 'Sara',
        tableId: 'takeout',
        tableNumber: 0,
        items: const [
          CompletedItem(
              name: 'Burger',
              emoji: '🍔',
              quantity: 2,
              unitPrice: 2500,
              modifiersLabel: 'No onion'),
        ],
        subtotal: 5000,
        discountAmount: 0,
        tax: tax,
        tip: 0,
        total: 5000 + tax,
        method: PaymentMethod.cash,
        cashPaid: 6000,
        cardPaid: 0,
        change: change,
        timestamp: DateTime(2026, 7, 18, 14, 30),
        customerName: '',
        customerPhone: '',
        deliveryNotes: '',
        driverId: null,
        deliveryAreaId: null,
        deliveryFee: 0,
      );

  test('the receipt builds into a non-empty PDF', () async {
    final doc = buildReceipt(sample(), const AppSettings(restaurantName: 'Demo'));
    final bytes = await doc.save();
    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(500)); // a real document, not an empty page
  });

  test('a delivery receipt with customer details still builds', () async {
    final p = CompletedPayment(
      id: '2',
      orderNumber: 'Order #002',
      orderType: 'Delivery',
      staffName: 'Sara',
      tableId: '',
      tableNumber: 0,
      items: const [
        CompletedItem(
            name: 'Pizza', emoji: '🍕', quantity: 1, unitPrice: 8000, modifiersLabel: ''),
      ],
      subtotal: 8000,
      discountAmount: 0,
      tax: 0,
      tip: 0,
      total: 10500,
      method: PaymentMethod.cash,
      cashPaid: 10500,
      cardPaid: 0,
      change: 0,
      timestamp: DateTime(2026, 7, 18, 15, 0),
      customerName: 'Rawa',
      customerPhone: '07701234567',
      deliveryNotes: 'blue gate, 2nd floor',
      driverId: 'd1',
      deliveryAreaId: 'a1',
      deliveryFee: 2500,
    );
    final bytes = await buildReceipt(p, const AppSettings()).save();
    expect(bytes, isNotEmpty);
  });
}
