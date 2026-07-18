import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/database/app_database.dart';
import 'package:easycasher/core/database/database_provider.dart';
import 'package:easycasher/core/sync/cloud_sync.dart';
import 'package:easycasher/features/payment/models/payment.dart';

/// The sync endpoint filters incoming orders with `Arr::only(ORDER_FIELDS)`,
/// so a misspelled key is dropped in silence — no error, no 422, the data just
/// vanishes. That is exactly how `phone` vs `customer_phone` shipped unnoticed
/// and broke customer creation. These tests pin the contract.
void main() {
  /// SyncController::ORDER_FIELDS, verbatim.
  const serverOrderFields = {
    'id', 'order_number', 'order_type', 'staff_name', 'table_id', 'table_number',
    'subtotal', 'discount_amount', 'tax', 'tip', 'delivery_fee', 'total',
    'method', 'cash_paid', 'card_paid', 'change_amount', 'status', 'note',
    'placed_at', 'customer_name', 'customer_phone', 'delivery_address',
    'delivery_notes', 'driver_id', 'driver_settled_at', 'platform',
    'online_status', 'platform_ref',
  };

  /// Keys the endpoint reads but does not persist on the order.
  const serverExtraFields = {'delivery_area_id', 'kots', 'items'};

  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting();
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() {
    container.dispose();
    db.close();
  });

  CompletedPayment delivery({
    String phone = '0770 123 4567',
    String name = 'Rawa',
    String notes = 'blue gate, 2nd floor',
    String? driverId = 'd1',
    String? areaId = '3f8b9c1e-2a4d-4f6b-8c1e-9a7d5b3f2e10',
    double fee = 2000,
  }) =>
      CompletedPayment(
        id: '1',
        orderNumber: '006',
        orderType: 'Delivery',
        staffName: 'Sara',
        tableId: '',
        tableNumber: 0,
        items: const [],
        subtotal: 10000,
        discountAmount: 0,
        tax: 0,
        tip: 0,
        total: 12000,
        method: PaymentMethod.cash,
        cashPaid: 12000,
        cardPaid: 0,
        change: 0,
        timestamp: DateTime.now(),
        customerName: name,
        customerPhone: phone,
        deliveryNotes: notes,
        driverId: driverId,
        deliveryAreaId: areaId,
        deliveryFee: fee,
      );

  Future<Map<String, dynamic>> queuedOrder() async {
    final raw = await db.kvGet('cloud_outbox');
    expect(raw, isNotNull, reason: 'the sale should be queued in the outbox');
    return (jsonDecode(raw!) as List).single as Map<String, dynamic>;
  }

  test('every key we push is one the server actually reads', () async {
    await container.read(cloudSyncProvider.notifier).enqueueSale(delivery());
    final order = await queuedOrder();

    final unknown = order.keys.toSet()
      ..removeAll(serverOrderFields)
      ..removeAll(serverExtraFields);

    expect(
      unknown,
      isEmpty,
      reason: 'these keys are silently discarded by Arr::only(): $unknown',
    );
  });

  test('the phone goes out as customer_phone', () async {
    await container.read(cloudSyncProvider.notifier).enqueueSale(delivery());
    final order = await queuedOrder();

    // The customer upsert is gated on customer_phone. Under the old key name
    // it was dropped, so no customer was ever created from a delivery.
    expect(order['customer_phone'], '0770 123 4567');
    expect(order.containsKey('phone'), isFalse);
  });

  test('delivery fee and area reach the server', () async {
    await container.read(cloudSyncProvider.notifier).enqueueSale(delivery());
    final order = await queuedOrder();

    expect(order['delivery_fee'], 2000);
    expect(order['delivery_area_id'], '3f8b9c1e-2a4d-4f6b-8c1e-9a7d5b3f2e10');
    expect(order['customer_name'], 'Rawa');
    expect(order['delivery_notes'], 'blue gate, 2nd floor');
    expect(order['driver_id'], 'd1');
  });

  test('a non-uuid area id is nulled rather than wedging the whole queue',
      () async {
    // delivery_area_id is validated `nullable|uuid`; a 422 fails the entire
    // batch, stranding every other sale behind it.
    await container
        .read(cloudSyncProvider.notifier)
        .enqueueSale(delivery(areaId: '17'));
    final order = await queuedOrder();

    expect(order['delivery_area_id'], isNull);
    expect(order['customer_phone'], isNotNull, reason: 'the rest still goes');
  });

  test('a non-delivery sale sends no customer details', () async {
    await container.read(cloudSyncProvider.notifier).enqueueSale(
          CompletedPayment(
            id: '2',
            orderNumber: '007',
            orderType: 'Takeout',
            staffName: 'Sara',
            tableId: '',
            tableNumber: 0,
            items: const [],
            subtotal: 5000,
            discountAmount: 0,
            tax: 0,
            tip: 0,
            total: 5000,
            method: PaymentMethod.cash,
            cashPaid: 5000,
            cardPaid: 0,
            change: 0,
            timestamp: DateTime.now(),
          ),
        );
    final order = await queuedOrder();

    // Empty strings must not arrive as "": the server would store them and the
    // upsert gate (`$order->customer_phone`) is truthiness-based.
    expect(order['customer_phone'], isNull);
    expect(order['customer_name'], isNull);
    expect(order['delivery_notes'], isNull);
    expect(order['delivery_fee'], 0);
  });
}
