import 'package:flutter_test/flutter_test.dart';
import 'package:easycasher/features/delivery/models/driver.dart';

/// The cached driver/area JSON is whatever Laravel sent. These parsers are
/// deliberately tolerant, because a shape surprise must not take the till down.
void main() {
  group('Driver.tryFromJson', () {
    test('reads the documented shape', () {
      final d = Driver.tryFromJson({
        'id': 7,
        'name': 'Karwan',
        'phone': '0770 123 4567',
        'active': true,
      });

      expect(d, isNotNull);
      expect(d!.id, '7'); // ints are normalised to strings
      expect(d.name, 'Karwan');
      expect(d.phone, '0770 123 4567');
      expect(d.active, isTrue);
    });

    test('accepts active as 0/1 or a string', () {
      expect(Driver.tryFromJson({'id': 1, 'name': 'A', 'active': 0})!.active,
          isFalse);
      expect(Driver.tryFromJson({'id': 2, 'name': 'B', 'active': 1})!.active,
          isTrue);
      expect(Driver.tryFromJson({'id': 3, 'name': 'C', 'active': '1'})!.active,
          isTrue);
      expect(
          Driver.tryFromJson({'id': 4, 'name': 'D', 'active': 'false'})!.active,
          isFalse);
    });

    test('defaults to active when the server omits the flag', () {
      expect(Driver.tryFromJson({'id': 1, 'name': 'A'})!.active, isTrue);
    });

    test('rejects a row with no id or name rather than inventing one', () {
      expect(Driver.tryFromJson({'name': 'no id'}), isNull);
      expect(Driver.tryFromJson({'id': 1}), isNull);
    });
  });

  group('DeliveryArea.tryFromJson', () {
    test('reads name and fee', () {
      final a = DeliveryArea.tryFromJson({'id': 3, 'name': 'Ankawa', 'fee': 2000});
      expect(a!.name, 'Ankawa');
      expect(a.fee, 2000);
      expect(a.isFree, isFalse);
    });

    test('fee 0 means free delivery', () {
      final a = DeliveryArea.tryFromJson({'id': 1, 'name': 'City centre', 'fee': 0});
      expect(a!.isFree, isTrue);
    });

    test('a missing fee is free, not a crash', () {
      final a = DeliveryArea.tryFromJson({'id': 1, 'name': 'Somewhere'});
      expect(a!.fee, 0);
      expect(a.isFree, isTrue);
    });

    test('accepts a decimal string fee', () {
      // Laravel casts decimals to strings in JSON often enough to matter.
      expect(
        DeliveryArea.tryFromJson({'id': 1, 'name': 'X', 'fee': '2500.00'})!.fee,
        2500,
      );
    });

    test('falls back to delivery_fee if that is the field name', () {
      expect(
        DeliveryArea.tryFromJson({'id': 1, 'name': 'X', 'delivery_fee': 1500})!.fee,
        1500,
      );
    });
  });
}
