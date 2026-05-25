import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/database/app_database.dart';
import 'package:easycasher/core/database/database_provider.dart';
import 'package:easycasher/features/tables/models/restaurant_table.dart';

final activeTableProvider = StateProvider<RestaurantTable?>((ref) => null);

class TablesNotifier extends StateNotifier<List<RestaurantTable>> {
  final AppDatabase _db;

  TablesNotifier(this._db) : super([]) {
    _load();
  }

  Future<void> _load() async {
    state = await _db.getTables();
  }

  void setStatus(String id, TableStatus status) {
    state = [
      for (final t in state)
        if (t.id == id) t.copyWith(status: status) else t,
    ];
    final updated = state.firstWhere((t) => t.id == id);
    _db.upsertTable(updated);
  }

  void add(int number, int capacity) {
    final id = 'T${DateTime.now().millisecondsSinceEpoch}';
    final table = RestaurantTable(id: id, number: number, capacity: capacity);
    state = [...state, table];
    _db.upsertTable(table);
  }

  void update(String id, {required int number, required int capacity}) {
    state = [
      for (final t in state)
        if (t.id == id) t.copyWith(number: number, capacity: capacity) else t,
    ];
    final updated = state.firstWhere((t) => t.id == id);
    _db.upsertTable(updated);
  }

  void remove(String id) {
    state = state.where((t) => t.id != id).toList();
    _db.deleteTable(id);
  }

  int nextSuggestedNumber() {
    if (state.isEmpty) return 1;
    return state.map((t) => t.number).reduce((a, b) => a > b ? a : b) + 1;
  }
}

final tablesProvider =
    StateNotifierProvider<TablesNotifier, List<RestaurantTable>>((ref) {
  return TablesNotifier(ref.watch(appDatabaseProvider));
});
