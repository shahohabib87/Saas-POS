/// A delivery driver, as sent down by the cloud (`GET /api/drivers`).
///
/// Drivers are created, edited and settled in the web console — the terminal
/// only picks from the list it is given.
class Driver {
  final String id;
  final String name;
  final String phone;
  final bool active;

  const Driver({
    required this.id,
    required this.name,
    this.phone = '',
    this.active = true,
  });

  /// Tolerant of the server's exact shape: ids may arrive as ints, `active`
  /// may be a bool, 0/1, or absent. A malformed row must not break the till.
  static Driver? tryFromJson(Map<String, dynamic> j) {
    final id = j['id'];
    final name = j['name'];
    if (id == null || name == null) return null;
    return Driver(
      id: '$id',
      name: '$name',
      phone: '${j['phone'] ?? ''}',
      active: switch (j['active']) {
        null => true,
        final bool b => b,
        final num n => n != 0,
        final String s => s == '1' || s.toLowerCase() == 'true',
        _ => true,
      },
    );
  }
}

/// A delivery neighbourhood and what it costs to deliver there
/// (`GET /api/delivery-areas`). A fee of 0 means free delivery.
class DeliveryArea {
  final String id;
  final String name;
  final double fee;

  const DeliveryArea({
    required this.id,
    required this.name,
    this.fee = 0,
  });

  bool get isFree => fee <= 0;

  static DeliveryArea? tryFromJson(Map<String, dynamic> j) {
    final id = j['id'];
    final name = j['name'];
    if (id == null || name == null) return null;
    final rawFee = j['fee'] ?? j['delivery_fee'];
    return DeliveryArea(
      id: '$id',
      name: '$name',
      fee: switch (rawFee) {
        null => 0,
        final num n => n.toDouble(),
        final String s => double.tryParse(s) ?? 0,
        _ => 0,
      },
    );
  }
}
