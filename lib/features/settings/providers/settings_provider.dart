import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/database/app_database.dart';
import 'package:easycasher/core/database/database_provider.dart';
import 'package:easycasher/features/auth/models/staff.dart';
import 'package:easycasher/features/settings/models/app_settings.dart';

class SettingsNotifier extends StateNotifier<AppSettings> {
  final AppDatabase _db;

  SettingsNotifier(this._db) : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    state = await _db.getSettings();
  }

  void update(AppSettings s) {
    state = s;
    _db.saveSettings(s);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.watch(appDatabaseProvider));
});

/// The tax multiplier to apply to a bill: the configured rate as a fraction
/// (the setting stores a percentage, e.g. 15 for 15%), or zero when tax is
/// switched off. One source of truth so the cart, the payment screen and the
/// receipt always agree — the old hardcoded `AppConstants.taxRate = 0` meant
/// enabling tax in Settings had no effect anywhere.
final taxMultiplierProvider = Provider<double>((ref) {
  final s = ref.watch(settingsProvider);
  return s.taxEnabled ? (s.taxRate / 100.0) : 0.0;
});

class StaffListNotifier extends StateNotifier<List<Staff>> {
  final AppDatabase _db;

  StaffListNotifier(this._db) : super([]) {
    _load();
  }

  Future<void> _load() async {
    state = await _db.getStaff();
  }

  void add(Staff s) {
    state = [...state, s];
    _db.upsertStaff(s);
  }

  void update(Staff s) {
    state = [for (final e in state) e.id == s.id ? s : e];
    _db.upsertStaff(s);
  }

  void remove(String id) {
    state = state.where((s) => s.id != id).toList();
    _db.deleteStaff(id);
  }

  String nextId() => 's${DateTime.now().millisecondsSinceEpoch}';
}

final staffListProvider =
    StateNotifierProvider<StaffListNotifier, List<Staff>>((ref) {
  return StaffListNotifier(ref.watch(appDatabaseProvider));
});
