import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/features/tables/models/restaurant_table.dart';

final activeTableProvider = StateProvider<RestaurantTable?>((ref) => null);

class TablesNotifier extends StateNotifier<List<RestaurantTable>> {
  TablesNotifier() : super(_generate());

  // Track next id counter above the pre-seeded 20 tables
  int _nextId = 21;

  void setStatus(String id, TableStatus status) {
    state = [
      for (final t in state)
        if (t.id == id) t.copyWith(status: status) else t,
    ];
  }

  void add(int number, int capacity) {
    final id = 'T$_nextId';
    _nextId++;
    state = [
      ...state,
      RestaurantTable(id: id, number: number, capacity: capacity),
    ];
  }

  void update(String id, {required int number, required int capacity}) {
    state = [
      for (final t in state)
        if (t.id == id) t.copyWith(number: number, capacity: capacity) else t,
    ];
  }

  void remove(String id) {
    state = state.where((t) => t.id != id).toList();
  }

  /// Returns the next suggested table number (max existing + 1).
  int nextSuggestedNumber() {
    if (state.isEmpty) return 1;
    return state.map((t) => t.number).reduce((a, b) => a > b ? a : b) + 1;
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
