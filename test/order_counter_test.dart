import 'package:flutter_test/flutter_test.dart';
import 'package:easycasher/core/database/app_database.dart';

/// The daily order counter must advance and persist — takeout sales in
/// particular used to never bump it (payment_screen now claims a number at
/// pay time), so consecutive takeouts shared an Order #.
void main() {
  test('the order counter starts at zero, persists and reloads', () async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);

    expect(await db.loadTodayCounter(), 0); // a fresh day starts at zero
    await db.persistCounter(7);
    expect(await db.loadTodayCounter(), 7); // and the count survives a reload
  });
}
