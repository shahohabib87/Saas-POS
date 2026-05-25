enum TableStatus { available, occupied, reserved }

class RestaurantTable {
  final String id;
  final int number;
  final int capacity;
  final TableStatus status;

  const RestaurantTable({
    required this.id,
    required this.number,
    required this.capacity,
    this.status = TableStatus.available,
  });

  RestaurantTable copyWith({
    int? number,
    int? capacity,
    TableStatus? status,
  }) =>
      RestaurantTable(
        id: id,
        number: number ?? this.number,
        capacity: capacity ?? this.capacity,
        status: status ?? this.status,
      );
}
