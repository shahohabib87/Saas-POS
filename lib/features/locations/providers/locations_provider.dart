import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/database/app_database.dart';
import 'package:easycasher/core/database/database_provider.dart';
import 'package:easycasher/features/locations/models/location.dart';

class LocationsNotifier extends StateNotifier<List<Location>> {
  final AppDatabase _db;

  LocationsNotifier(this._db) : super([]) {
    _load();
  }

  Future<void> _load() async {
    final rows = await _db.getLocations();
    if (!mounted) return; // sync may invalidate/dispose us mid-load
    state = rows;
  }

  void add(String name) {
    final location = Location(id: nextId(), name: name);
    state = [...state, location];
    _db.saveLocations(state);
  }

  void update(String id, String name) {
    state = [
      for (final l in state)
        if (l.id == id) l.copyWith(name: name) else l,
    ];
    _db.saveLocations(state);
  }

  void remove(String id) {
    state = state.where((l) => l.id != id).toList();
    _db.saveLocations(state);
  }

  String nextId() => 'loc${DateTime.now().millisecondsSinceEpoch}';
}

final locationsProvider =
    StateNotifierProvider<LocationsNotifier, List<Location>>((ref) {
  return LocationsNotifier(ref.watch(appDatabaseProvider));
});
