import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:easycasher/core/api/cloud_api.dart';
import 'package:easycasher/core/database/app_database.dart';
import 'package:easycasher/core/database/database_provider.dart';
import 'package:easycasher/features/auth/models/staff.dart';
import 'package:easycasher/features/cashier/models/category.dart';
import 'package:easycasher/features/cashier/models/menu_item.dart';
import 'package:easycasher/features/cashier/models/modifier.dart';
import 'package:easycasher/features/tables/models/restaurant_table.dart';

/// Where the device stands with the cloud.
class CloudState {
  final bool connected;
  final String baseUrl;
  final String tenantName;
  final String? lastPullAt; // ISO string, null = never
  final bool busy;
  final String? error;

  const CloudState({
    this.connected = false,
    this.baseUrl = 'https://app.easycasherorder.online',
    this.tenantName = '',
    this.lastPullAt,
    this.busy = false,
    this.error,
  });

  CloudState copyWith({
    bool? connected,
    String? baseUrl,
    String? tenantName,
    String? lastPullAt,
    bool? busy,
    String? error,
    bool clearError = false,
  }) =>
      CloudState(
        connected: connected ?? this.connected,
        baseUrl: baseUrl ?? this.baseUrl,
        tenantName: tenantName ?? this.tenantName,
        lastPullAt: lastPullAt ?? this.lastPullAt,
        busy: busy ?? this.busy,
        error: clearError ? null : (error ?? this.error),
      );
}

/// Keys used in the settings KV store.
class _K {
  static const token = 'cloud_token';
  static const baseUrl = 'cloud_base_url';
  static const tenantName = 'cloud_tenant_name';
  static const tenantSlug = 'cloud_tenant_slug';
  static const lastPullAt = 'cloud_last_pull_at';
  static const drivers = 'cloud_drivers';
  static const areas = 'cloud_delivery_areas';
}

/// Phase 1+2 of the sync plan: cloud login (Sanctum token on device) and the
/// initial catalog pull into the local Drift database. The POS keeps reading
/// ONLY from the local DB — the cloud just refreshes it.
class CloudSyncNotifier extends StateNotifier<CloudState> {
  CloudSyncNotifier(this._db) : super(const CloudState()) {
    _restore();
  }

  final AppDatabase _db;

  /// Load the saved connection (if any) when the app starts.
  Future<void> _restore() async {
    final token = await _db.kvGet(_K.token);
    if (token == null || token.isEmpty) return;
    state = state.copyWith(
      connected: true,
      baseUrl: await _db.kvGet(_K.baseUrl) ?? state.baseUrl,
      tenantName: await _db.kvGet(_K.tenantName) ?? '',
      lastPullAt: await _db.kvGet(_K.lastPullAt),
    );
  }

  /// Phase 1: email login → token stored on the device, then Phase 2 pull.
  Future<bool> connect(String baseUrl, String email, String password) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final api = CloudApi(baseUrl: baseUrl);
      final session = await api.login(email, password);

      await _db.kvSet(_K.token, session.token);
      await _db.kvSet(_K.baseUrl, baseUrl);
      await _db.kvSet(_K.tenantName, session.tenantName);
      await _db.kvSet(_K.tenantSlug, session.tenantSlug);

      state = state.copyWith(
        connected: true,
        baseUrl: baseUrl,
        tenantName: session.tenantName,
      );

      await _pull(api);
      return true;
    } catch (e) {
      state = state.copyWith(error: CloudApi.errorMessage(e));
      return false;
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  /// Phase 2 on demand: re-download the catalog with the saved token.
  Future<bool> pullNow() async {
    final token = await _db.kvGet(_K.token);
    if (token == null) {
      state = state.copyWith(error: 'Not connected.');
      return false;
    }
    state = state.copyWith(busy: true, clearError: true);
    try {
      await _pull(CloudApi(baseUrl: state.baseUrl, token: token));
      return true;
    } catch (e) {
      state = state.copyWith(error: CloudApi.errorMessage(e));
      return false;
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  /// Forget the cloud connection (local data stays on the device).
  Future<void> disconnect() async {
    for (final k in [_K.token, _K.tenantName, _K.tenantSlug, _K.lastPullAt]) {
      await _db.kvDelete(k);
    }
    state = CloudState(baseUrl: state.baseUrl);
  }

  // ── The pull itself ─────────────────────────────────────────────────────

  Future<void> _pull(CloudApi api) async {
    final results = await Future.wait([
      api.fetchCategories(),
      api.fetchMenuItems(),
      api.fetchTables(),
      api.fetchStaff(),
      api.fetchDrivers(),
      api.fetchDeliveryAreas(),
    ]);

    final cats = results[0].map(_categoryFromJson).toList();
    final items = results[1]
        .where((j) => (j as Map)['is_available'] != false)
        .map(_menuItemFromJson)
        .toList();
    final tables = results[2].map(_tableFromJson).toList();
    final staff =
        results[3].map(_staffFromJson).whereType<Staff>().toList();

    await _db.replaceCatalog(cats, items);
    await _db.replaceTables(tables);
    if (staff.isNotEmpty) await _db.replaceStaff(staff);

    // Drivers + delivery areas: no Drift tables yet — cache raw JSON
    // (same pattern the locations feature uses).
    await _db.kvSet(_K.drivers, jsonEncode(results[4]));
    await _db.kvSet(_K.areas, jsonEncode(results[5]));

    final now = DateTime.now().toIso8601String();
    await _db.kvSet(_K.lastPullAt, now);
    state = state.copyWith(lastPullAt: now);
  }

  // ── Server JSON → local models ──────────────────────────────────────────

  Category _categoryFromJson(dynamic j) => Category(
        id: j['id'] as String,
        name: j['name'] as String,
        emoji: (j['emoji'] as String?)?.isNotEmpty == true
            ? j['emoji'] as String
            : '🍽️',
      );

  MenuItem _menuItemFromJson(dynamic j) => MenuItem(
        id: j['id'] as String,
        categoryId: (j['category_id'] as String?) ?? 'all',
        name: j['name'] as String,
        price: double.tryParse(j['price'].toString()) ?? 0,
        emoji: (j['emoji'] as String?)?.isNotEmpty == true
            ? j['emoji'] as String
            : '🍽️',
        modifierGroups: _modifierGroupsFromJson(j['modifier_groups']),
      );

  List<ModifierGroup> _modifierGroupsFromJson(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((g) {
      final options = (g['options'] as List? ?? const [])
          .asMap()
          .entries
          .map((e) => ModifierOption(
                id: 'o${e.key}',
                name: e.value['name'] as String,
                price: double.tryParse(e.value['price'].toString()) ?? 0,
              ))
          .toList();
      return ModifierGroup(
        name: g['name'] as String,
        multiSelect: g['multiSelect'] == true,
        options: options,
      );
    }).toList();
  }

  RestaurantTable _tableFromJson(dynamic j) => RestaurantTable(
        id: j['id'] as String,
        number: j['number'] as int,
        capacity: j['capacity'] as int,
        status: TableStatus.values.byName((j['status'] as String?) ?? 'available'),
      );

  /// Cloud staff → local PIN-login staff. Users without a PIN (or with a
  /// role this app doesn't know) are skipped.
  Staff? _staffFromJson(dynamic j) {
    final pin = j['pin'] as String?;
    final roleName = j['role'] as String?;
    if (pin == null || pin.isEmpty || roleName == null) return null;
    final role = StaffRole.values.asNameMap()[roleName];
    if (role == null) return null;
    return Staff(
      id: j['id'].toString(),
      name: j['name'] as String,
      role: role,
      pin: pin,
      avatar: (j['avatar'] as String?)?.isNotEmpty == true
          ? j['avatar'] as String
          : '👤',
    );
  }
}

final cloudSyncProvider =
    StateNotifierProvider<CloudSyncNotifier, CloudState>((ref) {
  return CloudSyncNotifier(ref.watch(appDatabaseProvider));
});
