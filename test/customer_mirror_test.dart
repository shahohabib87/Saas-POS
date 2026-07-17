import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/database/app_database.dart';
import 'package:easycasher/core/database/database_provider.dart';
import 'package:easycasher/features/delivery/models/driver.dart';
import 'package:easycasher/features/delivery/providers/delivery_provider.dart';

/// The customer book is mirrored locally so a repeat caller auto-fills with no
/// internet. The terminal never writes to it — the server owns creation.
void main() {
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

  Future<void> seedCustomer({
    String id = 'c1',
    String phone = '0770 111 2222',
    String name = 'Rawa',
    String? areaId = 'a1',
    String directions = 'blue gate, 2nd floor',
  }) =>
      db.upsertCustomer(CustomersCompanion.insert(
        id: id,
        phone: phone,
        name: Value(name),
        areaId: Value(areaId),
        directions: Value(directions),
      ));

  test('a customer is found by exact phone', () async {
    await seedCustomer();

    final found = await db.findCustomerByPhone('0770 111 2222');
    expect(found, isNotNull);
    expect(found!.name, 'Rawa');
    expect(found.directions, 'blue gate, 2nd floor');
  });

  test('an unknown phone finds nothing rather than throwing', () async {
    await seedCustomer();
    expect(await db.findCustomerByPhone('0000'), isNull);
    expect(await db.findCustomerByPhone(''), isNull);
  });

  test('autofill fills name, area, fee and directions from the book', () async {
    await seedCustomer();
    const areas = [DeliveryArea(id: 'a1', name: 'Ankawa', fee: 2000)];

    final notifier = container.read(deliveryDetailsProvider.notifier);
    notifier.setPhone('0770 111 2222');
    final found = await notifier.autofillFromPhone('0770 111 2222', areas);

    expect(found, isNotNull);
    final d = container.read(deliveryDetailsProvider);
    expect(d.customerName, 'Rawa');
    expect(d.areaId, 'a1');
    expect(d.areaFee, 2000); // the fee follows the area onto the bill
    expect(d.notes, 'blue gate, 2nd floor');
  });

  test('autofill never overwrites what the cashier already typed', () async {
    await seedCustomer();
    const areas = [DeliveryArea(id: 'a1', name: 'Ankawa', fee: 2000)];

    final notifier = container.read(deliveryDetailsProvider.notifier);
    notifier.setPhone('0770 111 2222');
    // The cashier is correcting a stale record — the mirror must not win.
    notifier.setCustomerName('Rawa (new name)');
    notifier.setNotes('moved — red door');
    await notifier.autofillFromPhone('0770 111 2222', areas);

    final d = container.read(deliveryDetailsProvider);
    expect(d.customerName, 'Rawa (new name)');
    expect(d.notes, 'moved — red door');
  });

  test('an unknown caller leaves the form untouched', () async {
    const areas = [DeliveryArea(id: 'a1', name: 'Ankawa', fee: 2000)];

    final notifier = container.read(deliveryDetailsProvider.notifier);
    final found = await notifier.autofillFromPhone('0999 999 9999', areas);

    expect(found, isNull);
    expect(container.read(deliveryDetailsProvider).customerName, isEmpty);
  });

  test('a phone reassigned to a new customer replaces the old row', () async {
    await seedCustomer(id: 'c1', phone: '0770 111 2222', name: 'Rawa');
    // Same phone, different id — the unique index would otherwise collide.
    await seedCustomer(id: 'c2', phone: '0770 111 2222', name: 'Dara');

    final found = await db.findCustomerByPhone('0770 111 2222');
    expect(found!.id, 'c2');
    expect(found.name, 'Dara');
  });

  test('drivers and areas read back from their tables', () async {
    await db.replaceDrivers([
      DriversCompanion.insert(id: 'd1', name: 'Karwan'),
      DriversCompanion.insert(id: 'd2', name: 'Aram', active: const Value(false)),
    ]);
    await db.replaceDeliveryAreas([
      DeliveryAreasCompanion.insert(id: 'a1', name: 'Ankawa', fee: const Value(2000)),
    ]);

    // An inactive driver cannot be handed an order.
    final drivers = await container.read(driversProvider.future);
    expect(drivers.map((d) => d.name), ['Karwan']);

    final areas = await container.read(deliveryAreasProvider.future);
    expect(areas.single.fee, 2000);
  });

  test('replacing drivers drops the ones the server no longer sends', () async {
    await db.replaceDrivers([DriversCompanion.insert(id: 'd1', name: 'Karwan')]);
    await db.replaceDrivers([DriversCompanion.insert(id: 'd2', name: 'Aram')]);

    final drivers = await db.getDrivers();
    expect(drivers.map((d) => d.id), ['d2']);
  });
}
