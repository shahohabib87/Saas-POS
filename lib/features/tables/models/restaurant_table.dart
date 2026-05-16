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

  RestaurantTable copyWith({TableStatus? status}) => RestaurantTable(
        id: id,
        number: number,
        capacity: capacity,
        status: status ?? this.status,
      );
}
