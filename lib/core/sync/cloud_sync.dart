import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:easycasher/core/api/cloud_api.dart';
import 'package:easycasher/core/database/app_database.dart';
import 'package:easycasher/core/database/database_provider.dart';
import 'package:easycasher/features/auth/models/staff.dart';
import 'package:easycasher/features/cashier/models/category.dart';
import 'package:easycasher/features/cashier/models/menu_item.dart';
import 'package:easycasher/features/cashier/models/modifier.dart';
import 'package:easycasher/features/cashier/providers/menu_provider.dart';
import 'package:easycasher/features/payment/models/payment.dart';
import 'package:easycasher/features/settings/providers/settings_provider.dart';
import 'package:easycasher/features/tables/models/restaurant_table.dart';
import 'package:easycasher/features/tables/providers/tables_provider.dart';

/// How this device runs: full POS, or locked to one screen.
enum DeviceMode { full, kds }

/// Where the device stands with the cloud.
class CloudState {
  final bool connected;
  final String baseUrl;
  final String tenantName;
  final String? lastPullAt; // ISO string, null = never
  final int pendingSales; // queued sales waiting to reach the cloud
  final DeviceMode deviceMode;
  final bool busy;
  final String? error;

  const CloudState({
    this.connected = false,
    this.baseUrl = 'https://app.easycasherorder.online',
    this.tenantName = '',
    this.lastPullAt,
    this.pendingSales = 0,
    this.deviceMode = DeviceMode.full,
    this.busy = false,
    this.error,
  });

  CloudState copyWith({
    bool? connected,
    String? baseUrl,
    String? tenantName,
    String? lastPullAt,
    int? pendingSales,
    DeviceMode? deviceMode,
    bool? busy,
    String? error,
    bool clearError = false,
  }) =>
      CloudState(
        connected: connected ?? this.connected,
        baseUrl: baseUrl ?? this.baseUrl,
        tenantName: tenantName ?? this.tenantName,
        lastPullAt: lastPullAt ?? this.lastPullAt,
        pendingSales: pendingSales ?? this.pendingSales,
        deviceMode: deviceMode ?? this.deviceMode,
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
  static const lastSyncedAt = 'cloud_last_synced_at'; // server_time checkpoint
  static const outbox = 'cloud_outbox'; // JSON array of server-shape orders
  static const drivers = 'cloud_drivers';
  static const areas = 'cloud_delivery_areas';
  static const deviceMode = 'cloud_device_mode';
}

/// RFC-4122 v4 UUID without adding a package dependency.
String _uuid4() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40; // version 4
  b[8] = (b[8] & 0x3f) | 0x80; // variant 10xx
  String hex(int start, int end) => b
      .sublist(start, end)
      .map((x) => x.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}

/// The Foodics-style sync engine (plan phases 1–5).
///
/// - Phase 1: email login → Sanctum token on the device
/// - Phase 2: initial pull → catalog/tables/staff into the local DB
/// - Phase 3: every completed sale is queued locally (outbox) first
/// - Phase 4: flush loop — push queue + apply the server's pull delta;
///   60s heartbeat, flush after every sale, 401 = session expired but
///   the queue is NEVER lost
/// - Phase 5: device mode (full POS vs dedicated KDS screen)
///
/// The POS reads ONLY from the local database — the cloud just feeds it.
class CloudSyncNotifier extends StateNotifier<CloudState> {
  CloudSyncNotifier(this._ref, this._db) : super(const CloudState()) {
    _restore();
  }

  final Ref _ref;
  final AppDatabase _db;
  Timer? _heartbeat;
  bool _flushing = false;

  @override
  void dispose() {
    _heartbeat?.cancel();
    super.dispose();
  }

  /// Load the saved connection (if any) when the app starts.
  Future<void> _restore() async {
    final modeName = await _db.kvGet(_K.deviceMode);
    final mode = DeviceMode.values.asNameMap()[modeName ?? ''] ?? DeviceMode.full;

    final token = await _db.kvGet(_K.token);
    state = state.copyWith(
      deviceMode: mode,
      pendingSales: (await _readOutbox()).length,
    );
    if (token == null || token.isEmpty) return;

    state = state.copyWith(
      connected: true,
      baseUrl: await _db.kvGet(_K.baseUrl) ?? state.baseUrl,
      tenantName: await _db.kvGet(_K.tenantName) ?? '',
      lastPullAt: await _db.kvGet(_K.lastPullAt),
    );
    _startHeartbeat();
    flush(); // push anything queued from a previous session
  }

  // ── Phase 1: connect ──────────────────────────────────────────────────────

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

      await _initialPull(api);
      _startHeartbeat();
      flush(); // deliver any sales made before (re)connecting
      return true;
    } catch (e) {
      state = state.copyWith(error: CloudApi.errorMessage(e));
      return false;
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  /// Forget the cloud connection (local data + queued sales stay on device).
  Future<void> disconnect() async {
    _heartbeat?.cancel();
    for (final k in [
      _K.token,
      _K.tenantName,
      _K.tenantSlug,
      _K.lastPullAt,
      _K.lastSyncedAt,
    ]) {
      await _db.kvDelete(k);
    }
    state = CloudState(
      baseUrl: state.baseUrl,
      pendingSales: state.pendingSales,
      deviceMode: state.deviceMode,
    );
  }

  // ── Phase 2: full pull ────────────────────────────────────────────────────

  Future<bool> pullNow() async {
    final token = await _db.kvGet(_K.token);
    if (token == null) {
      state = state.copyWith(error: 'Not connected.');
      return false;
    }
    state = state.copyWith(busy: true, clearError: true);
    try {
      await _initialPull(CloudApi(baseUrl: state.baseUrl, token: token));
      return true;
    } catch (e) {
      state = state.copyWith(error: CloudApi.errorMessage(e));
      return false;
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  Future<void> _initialPull(CloudApi api) async {
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
    final staff = results[3].map(_staffFromJson).whereType<Staff>().toList();

    await _db.replaceCatalog(cats, items);
    await _db.replaceTables(tables);
    if (staff.isNotEmpty) await _db.replaceStaff(staff);

    // Drivers + delivery areas: no Drift tables yet — cache raw JSON
    // (same pattern the locations feature uses).
    await _db.kvSet(_K.drivers, jsonEncode(results[4]));
    await _db.kvSet(_K.areas, jsonEncode(results[5]));

    final now = DateTime.now().toIso8601String();
    await _db.kvSet(_K.lastPullAt, now);
    // A full pull supersedes any delta checkpoint.
    await _db.kvSet(_K.lastSyncedAt, DateTime.now().toUtc().toIso8601String());
    state = state.copyWith(lastPullAt: now);

    _reloadProviders();
  }

  /// The list-style providers load once at construction — poke them so the
  /// UI shows freshly pulled data without an app restart.
  void _reloadProviders() {
    _ref.invalidate(categoriesProvider);
    _ref.invalidate(menuItemsProvider);
    _ref.invalidate(tablesProvider);
    _ref.invalidate(staffListProvider);
  }

  // ── Phase 3: the outbox ───────────────────────────────────────────────────

  Future<List<dynamic>> _readOutbox() async {
    final raw = await _db.kvGet(_K.outbox);
    if (raw == null || raw.isEmpty) return [];
    return jsonDecode(raw) as List<dynamic>;
  }

  Future<void> _writeOutbox(List<dynamic> orders) async {
    await _db.kvSet(_K.outbox, jsonEncode(orders));
    state = state.copyWith(pendingSales: orders.length);
  }

  /// Queue a completed sale for the cloud (called after every payment).
  /// The payload is server-shaped once, here — ids stay stable across retries.
  Future<void> enqueueSale(CompletedPayment p) async {
    final kotId = _uuid4();
    final placedAt = p.timestamp.toUtc().toIso8601String();

    final order = {
      'id': _uuid4(),
      'order_number': p.orderNumber,
      'order_type': _serverOrderType(p.orderType),
      'staff_name': p.staffName,
      'table_id': null, // local table ids aren't cloud uuids; number suffices
      'table_number': p.tableNumber,
      'subtotal': p.subtotal,
      'discount_amount': p.discountAmount,
      'tax': p.tax,
      'tip': p.tip,
      'delivery_fee': p.deliveryFee,
      'total': p.total,
      'method': p.method.name,
      'cash_paid': p.cashPaid,
      'card_paid': p.cardPaid,
      'change_amount': p.change,
      'status': 'completed',
      'note': null,
      'placed_at': placedAt,
      // Delivery details. Field names must match SyncController::ORDER_FIELDS
      // exactly — it filters with Arr::only(), so a wrong key is dropped in
      // silence rather than rejected. `customer_phone` in particular also gates
      // the customer upsert: get it wrong and no customer is ever created.
      'customer_name': p.customerName.isEmpty ? null : p.customerName,
      'customer_phone': p.customerPhone.isEmpty ? null : p.customerPhone,
      'delivery_notes': p.deliveryNotes.isEmpty ? null : p.deliveryNotes,
      'driver_id': p.driverId,
      // Not an order column — the server reads it to set the customer's area.
      // It is validated as `nullable|uuid`, and a 422 fails the whole batch,
      // so anything that isn't a uuid is sent as null rather than wedging the
      // outbox for every other queued sale.
      'delivery_area_id': _uuidOrNull(p.deliveryAreaId),
      'kots': [
        {
          'id': kotId,
          'kot_number': 1,
          'kitchen_status': 'done',
          'placed_at': placedAt,
        }
      ],
      'items': [
        for (final it in p.items)
          {
            'id': _uuid4(),
            'menu_item_id': null,
            'kot_id': kotId,
            'kot_number': 1,
            'name': it.name,
            'emoji': it.emoji,
            'quantity': it.quantity,
            'unit_price': it.unitPrice,
            'modifiers_label': it.modifiersLabel,
            'voided': false,
          }
      ],
    };

    final outbox = await _readOutbox();
    outbox.add(order);
    await _writeOutbox(outbox);

    flush(); // try to deliver right away — never blocks the sale
  }

  /// The sync endpoint validates `delivery_area_id` as a uuid and rejects the
  /// entire push otherwise — one malformed id would strand every queued sale
  /// behind it. Losing the area on one order is survivable; losing the queue
  /// is not.
  static String? _uuidOrNull(String? v) {
    if (v == null || v.isEmpty) return null;
    return _uuidPattern.hasMatch(v) ? v : null;
  }

  static final _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  String _serverOrderType(String label) => switch (label) {
        'Dine-In' => 'dine_in',
        'Takeout' => 'takeaway',
        'Delivery' => 'delivery',
        'Delivery App' => 'delivery_app',
        _ => 'takeaway',
      };

  // ── Phase 4: the sync loop ────────────────────────────────────────────────

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 60), (_) => flush());
  }

  /// Push the queue and consume the server's delta. Safe to call anytime;
  /// silently does nothing when offline (next heartbeat retries).
  Future<void> flush() async {
    if (_flushing || !state.connected) return;
    final token = await _db.kvGet(_K.token);
    if (token == null || token.isEmpty) return;

    _flushing = true;
    try {
      final outbox = await _readOutbox();
      final since = await _db.kvGet(_K.lastSyncedAt);

      final res = await CloudApi(baseUrl: state.baseUrl, token: token)
          .sync(orders: outbox, lastSyncedAt: since);

      // Remove only what the server confirmed.
      final applied = ((res['applied'] as List?) ?? const [])
          .map((e) => e.toString())
          .toSet();
      if (applied.isNotEmpty) {
        final remaining =
            outbox.where((o) => !applied.contains(o['id'])).toList();
        await _writeOutbox(remaining);
      }

      await _applyPull(res['pull'] as Map<String, dynamic>? ?? const {});

      final serverTime = res['server_time'] as String?;
      if (serverTime != null) await _db.kvSet(_K.lastSyncedAt, serverTime);

      if (state.error != null) state = state.copyWith(clearError: true);
    } catch (e) {
      if (CloudApi.isUnauthorized(e)) {
        // Token revoked/expired: keep the queue, ask for a fresh login.
        await _db.kvDelete(_K.token);
        _heartbeat?.cancel();
        state = state.copyWith(
          connected: false,
          error:
              'Cloud session expired — reconnect to keep syncing. Queued sales are safe on this device.',
        );
      }
      // Network errors: stay quiet, the heartbeat will retry.
    } finally {
      _flushing = false;
    }
  }

  /// Apply the server's changed-since delta to the local DB.
  Future<void> _applyPull(Map<String, dynamic> pull) async {
    var changed = false;

    for (final j in (pull['categories'] as List?) ?? const []) {
      changed = true;
      if (j['deleted_at'] != null) {
        await _db.deleteCategory(j['id'] as String);
      } else {
        await _db.upsertCategory(_categoryFromJson(j));
      }
    }

    for (final j in (pull['menu_items'] as List?) ?? const []) {
      changed = true;
      // Deleted OR 86'd items disappear from the register.
      if (j['deleted_at'] != null || j['is_available'] == false) {
        await _db.deleteMenuItem(j['id'] as String);
      } else {
        await _db.upsertMenuItem(_menuItemFromJson(j));
      }
    }

    for (final j in (pull['tables'] as List?) ?? const []) {
      changed = true;
      if (j['deleted_at'] != null) {
        await _db.deleteTable(j['id'] as String);
      } else {
        await _db.upsertTable(_tableFromJson(j));
      }
    }

    if (changed) _reloadProviders();
  }

  // ── Phase 5: device mode ──────────────────────────────────────────────────

  Future<void> setDeviceMode(DeviceMode mode) async {
    await _db.kvSet(_K.deviceMode, mode.name);
    state = state.copyWith(deviceMode: mode);
  }

  // ── Server JSON → local models ────────────────────────────────────────────

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
        status:
            TableStatus.values.byName((j['status'] as String?) ?? 'available'),
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
  return CloudSyncNotifier(ref, ref.watch(appDatabaseProvider));
});
