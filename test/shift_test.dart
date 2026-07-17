// drift exports its own isNull/isNotNull for query building, which collide
// with the matchers — only Value is needed here.
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:easycasher/core/database/app_database.dart';

/// The drawer maths decides whether a cashier is accused of being short, so
/// it gets tested rather than eyeballed.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting());
  tearDown(() => db.close());

  Future<void> insertOrder({
    required int timestamp,
    required double total,
    double cashPaid = 0,
    double changeAmount = 0,
    double cardPaid = 0,
  }) =>
      db.into(db.orders).insert(OrdersCompanion.insert(
            id: 'o-$timestamp-${cashPaid}_$cardPaid',
            orderNumber: '001',
            orderType: 'takeaway',
            staffName: 'Sara',
            subtotal: total,
            total: total,
            method: cashPaid > 0 ? 'cash' : 'card',
            cashPaid: Value(cashPaid),
            cardPaid: Value(cardPaid),
            changeAmount: Value(changeAmount),
            timestamp: timestamp,
          ));

  test('opening a shift returns it as the open shift', () async {
    expect(await db.getOpenShift(), isNull);

    final shift = await db.openShift(
      staffId: 's2',
      staffName: 'Sara',
      openingFloat: 50000,
    );

    final open = await db.getOpenShift();
    expect(open, isNotNull);
    expect(open!.id, shift.id);
    expect(open.openingFloat, 50000);
    expect(open.closedAt, isNull);
  });

  test('a second shift cannot be opened while one is live', () async {
    await db.openShift(staffId: 's2', staffName: 'Sara', openingFloat: 50000);

    // Sales are attributed to a shift by time window, so two open shifts would
    // double-count every order.
    expect(
      () => db.openShift(staffId: 's1', staffName: 'Ahmed', openingFloat: 10000),
      throwsA(isA<StateError>()),
    );
  });

  test('closing a shift frees the terminal for the next one', () async {
    final shift =
        await db.openShift(staffId: 's2', staffName: 'Sara', openingFloat: 50000);

    await db.closeShift(
      shiftId: shift.id,
      countedCash: 61000,
      expectedCash: 60000,
    );

    expect(await db.getOpenShift(), isNull);
    final closed = (await db.getRecentShifts()).single;
    expect(closed.countedCash, 61000);
    expect(closed.expectedCash, 60000);
    expect(closed.closedAt, isNotNull);
  });

  test('cash takings are net of change given back', () async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Customer pays 20,000 for a 15,000 order and takes 5,000 back: only
    // 15,000 stays in the drawer.
    await insertOrder(
      timestamp: now,
      total: 15000,
      cashPaid: 20000,
      changeAmount: 5000,
    );

    final t = await db.getShiftTakings(openedAt: now - 1000);
    expect(t.cashSales, 15000);
    expect(t.gross, 15000);
    expect(t.orderCount, 1);
  });

  test('takings ignore orders outside the shift window', () async {
    // Shift opened two minutes ago; the window runs from then until now.
    final openedAt = DateTime.now().millisecondsSinceEpoch - 120000;

    await insertOrder(
      timestamp: openedAt - 60000, // last shift's sale
      total: 9000,
      cashPaid: 9000,
    );
    await insertOrder(
      timestamp: openedAt + 60000, // this shift's sale
      total: 7000,
      cashPaid: 7000,
    );

    final t = await db.getShiftTakings(openedAt: openedAt);
    expect(t.orderCount, 1);
    expect(t.cashSales, 7000);
  });

  test('a closed shift only counts orders up to its close', () async {
    final openedAt = DateTime.now().millisecondsSinceEpoch - 120000;
    final closedAt = openedAt + 60000;

    await insertOrder(timestamp: openedAt + 1000, total: 7000, cashPaid: 7000);
    await insertOrder(
      timestamp: closedAt + 1000, // rung up after the drawer was closed
      total: 4000,
      cashPaid: 4000,
    );

    final t = await db.getShiftTakings(openedAt: openedAt, until: closedAt);
    expect(t.orderCount, 1);
    expect(t.cashSales, 7000);
  });

  test('card sales do not land in the cash drawer', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await insertOrder(timestamp: now, total: 12000, cardPaid: 12000);

    final t = await db.getShiftTakings(openedAt: now - 1000);
    expect(t.cardSales, 12000);
    expect(t.cashSales, 0);
    expect(t.gross, 12000);
  });

  test('cash movements are recorded with direction and reason', () async {
    final shift =
        await db.openShift(staffId: 's2', staffName: 'Sara', openingFloat: 50000);

    await db.addCashMovement(
      shiftId: shift.id,
      isIn: false,
      amount: 20000,
      reason: 'bank drop',
      staffName: 'Sara',
    );
    await db.addCashMovement(
      shiftId: shift.id,
      isIn: true,
      amount: 5000,
      reason: 'float top-up',
      staffName: 'Sara',
    );

    final movements = await db.getCashMovements(shift.id);
    expect(movements.length, 2);
    expect(movements.map((m) => m.reason),
        containsAll(<String>['bank drop', 'float top-up']));
    // Amount is always stored positive; `kind` carries the direction.
    expect(movements.every((m) => m.amount > 0), isTrue);
  });

  test('a negative movement amount is stored as its magnitude', () async {
    final shift =
        await db.openShift(staffId: 's2', staffName: 'Sara', openingFloat: 0);

    await db.addCashMovement(
      shiftId: shift.id,
      isIn: false,
      amount: -3000,
      reason: 'paid supplier',
      staffName: 'Sara',
    );

    expect((await db.getCashMovements(shift.id)).single.amount, 3000);
  });
}
