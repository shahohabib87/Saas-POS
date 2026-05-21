import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/features/auth/models/staff.dart';
import 'package:easycasher/features/settings/models/app_settings.dart';

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings());
  void update(AppSettings s) => state = s;
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(),
);

class StaffListNotifier extends StateNotifier<List<Staff>> {
  StaffListNotifier() : super(List.from(kDemoStaff));

  void add(Staff s) => state = [...state, s];

  void update(Staff s) => state = [
        for (final e in state)
          if (e.id == s.id) s else e,
      ];

  void remove(String id) =>
      state = state.where((s) => s.id != id).toList();

  String nextId() =>
      's${DateTime.now().millisecondsSinceEpoch}';
}

final staffListProvider =
    StateNotifierProvider<StaffListNotifier, List<Staff>>(
  (ref) => StaffListNotifier(),
);
