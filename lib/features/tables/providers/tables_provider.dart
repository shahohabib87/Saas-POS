import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/features/tables/models/restaurant_table.dart';

final activeTableProvider = StateProvider<RestaurantTable?>((ref) => null);

class TablesNotifier extends StateNotifier<List<RestaurantTable>> {
  TablesNotifier() : super(_generate());

  void setStatus(String id, TableStatus status) {
    state = [
      for (final t in state)
        if (t.id == id) t.copyWith(status: status) else t,
    ];
  }

  static List<RestaurantTable> _generate() {
    const capacities = [2, 4, 4, 6, 2, 4, 6, 2, 4, 4, 6, 2, 4, 2, 4, 6, 4, 2, 4, 6];
    return [
      for (int i = 0; i < 20; i++)
        RestaurantTable(
          id: 'T${i + 1}',
          number: i + 1,
          capacity: capacities[i],
        ),
    ];
  }
}

final tablesProvider =
    StateNotifierProvider<TablesNotifier, List<RestaurantTable>>(
  (ref) => TablesNotifier(),
);
