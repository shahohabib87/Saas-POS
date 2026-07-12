import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:easycasher/features/auth/models/app_permission.dart';
import 'package:easycasher/features/auth/models/staff.dart';
import 'package:easycasher/features/cashier/models/category.dart';
import 'package:easycasher/features/cashier/models/menu_item.dart';
import 'package:easycasher/features/cashier/models/modifier.dart';
import 'package:easycasher/features/payment/models/payment.dart';
import 'package:easycasher/features/locations/models/location.dart';
import 'package:easycasher/features/settings/models/app_settings.dart';
import 'package:easycasher/features/tables/models/restaurant_table.dart';

part 'app_database.g.dart';

// ── Table definitions ─────────────────────────────────────────────────────────

@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get emoji => text().withDefault(const Constant('🍽️'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MenuItemRow')
class MenuItems extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text()();
  TextColumn get name => text()();
  RealColumn get price => real()();
  TextColumn get emoji => text().withDefault(const Constant('🍽️'))();
  TextColumn get modifierGroupsJson =>
      text().withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('StaffRow')
class StaffMembers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get role => text()();
  TextColumn get pin => text()();
  TextColumn get avatar => text().withDefault(const Constant('👤'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RolePermRow')
class RolePerms extends Table {
  TextColumn get role => text()();
  TextColumn get permission => text()();

  @override
  Set<Column> get primaryKey => {role, permission};
}

@DataClassName('RestaurantTableRow')
class RestaurantTables extends Table {
  TextColumn get id => text()();
  IntColumn get number => integer()();
  IntColumn get capacity => integer()();
  TextColumn get status =>
      text().withDefault(const Constant('available'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('OrderRow')
class Orders extends Table {
  TextColumn get id => text()();
  TextColumn get orderNumber => text()();
  TextColumn get orderType => text()();
  TextColumn get staffName => text()();
  TextColumn get tableId => text().withDefault(const Constant(''))();
  IntColumn get tableNumber => integer().withDefault(const Constant(0))();
  RealColumn get subtotal => real()();
  RealColumn get discountAmount =>
      real().withDefault(const Constant(0.0))();
  RealColumn get tax => real().withDefault(const Constant(0.0))();
  RealColumn get tip => real().withDefault(const Constant(0.0))();
  RealColumn get total => real()();
  TextColumn get method => text()();
  RealColumn get cashPaid => real().withDefault(const Constant(0.0))();
  RealColumn get cardPaid => real().withDefault(const Constant(0.0))();
  RealColumn get changeAmount =>
      real().withDefault(const Constant(0.0))();
  IntColumn get timestamp => integer()(); // unix milliseconds

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('OrderItemRow')
class OrderItems extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text()();
  TextColumn get name => text()();
  TextColumn get emoji => text().withDefault(const Constant('🍽️'))();
  IntColumn get quantity => integer()();
  RealColumn get unitPrice => real()();
  TextColumn get modifiersLabel =>
      text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SettingsKvRow')
class SettingsKv extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

// ── Database ──────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [
  Categories,
  MenuItems,
  StaffMembers,
  RolePerms,
  RestaurantTables,
  Orders,
  OrderItems,
  SettingsKv,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'easycasher.db'));
      return NativeDatabase.createInBackground(file);
    });
  }

  // ── Seeding ───────────────────────────────────────────────────────────────

  Future<void> seedIfEmpty() async {
    final seeded = await _getSetting('_seeded');
    if (seeded == '1') return;

    await batch((b) {
      b.insertAll(categories, [
        const CategoriesCompanion(
            id: Value('all'), name: Value('All Items'), emoji: Value('🍽️')),
        const CategoriesCompanion(
            id: Value('burgers'), name: Value('Burgers'), emoji: Value('🍔')),
        const CategoriesCompanion(
            id: Value('pizza'), name: Value('Pizza'), emoji: Value('🍕')),
        const CategoriesCompanion(
            id: Value('drinks'), name: Value('Drinks'), emoji: Value('🥤')),
        const CategoriesCompanion(
            id: Value('desserts'),
            name: Value('Desserts'),
            emoji: Value('🍰')),
        const CategoriesCompanion(
            id: Value('sides'), name: Value('Sides'), emoji: Value('🍟')),
      ]);

      b.insertAll(menuItems, _defaultMenuItems());

      b.insertAll(staffMembers, [
        const StaffMembersCompanion(
            id: Value('s0'),
            name: Value('Admin'),
            role: Value('admin'),
            pin: Value('9999'),
            avatar: Value('👨‍💻')),
        const StaffMembersCompanion(
            id: Value('s1'),
            name: Value('Ahmed'),
            role: Value('waiter'),
            pin: Value('1234'),
            avatar: Value('👨‍🍳')),
        const StaffMembersCompanion(
            id: Value('s2'),
            name: Value('Sara'),
            role: Value('cashier'),
            pin: Value('5678'),
            avatar: Value('👩‍💼')),
        const StaffMembersCompanion(
            id: Value('s3'),
            name: Value('Kitchen'),
            role: Value('kitchen'),
            pin: Value('1111'),
            avatar: Value('🧑‍🍳')),
        const StaffMembersCompanion(
            id: Value('s4'),
            name: Value('Manager'),
            role: Value('manager'),
            pin: Value('0000'),
            avatar: Value('👨‍💼')),
      ]);

      for (final entry in kDefaultRolePermissions.entries) {
        for (final perm in entry.value) {
          b.insert(
            rolePerms,
            RolePermsCompanion(
              role: Value(entry.key.name),
              permission: Value(perm.name),
            ),
          );
        }
      }

      const caps = [2, 4, 4, 6, 2, 4, 6, 2, 4, 4, 6, 2, 4, 2, 4, 6, 4, 2, 4, 6];
      for (int i = 0; i < 20; i++) {
        b.insert(
          restaurantTables,
          RestaurantTablesCompanion(
            id: Value('T${i + 1}'),
            number: Value(i + 1),
            capacity: Value(caps[i]),
            status: const Value('available'),
          ),
        );
      }
    });

    await _setSetting('_seeded', '1');
  }

  static Map<String, dynamic> _mg(
          String name, bool multi, List<List<dynamic>> opts) =>
      {
        'name': name,
        'multiSelect': multi,
        'options': opts
            .map((o) => {'id': o[0], 'name': o[1], 'price': o[2]})
            .toList(),
      };

  static List<MenuItemsCompanion> _defaultMenuItems() {
    String enc(List<Map<String, dynamic>> groups) => jsonEncode(groups);

    return [
      MenuItemsCompanion(
        id: const Value('1'),
        categoryId: const Value('burgers'),
        name: const Value('Classic Burger'),
        price: const Value(5500),
        emoji: const Value('🍔'),
        modifierGroupsJson: Value(enc([
          _mg('Size', false, [
            ['b_reg', 'Regular', 5500.0],
            ['b_lg', 'Large', 7500.0]
          ]),
          _mg('Extras', true, [
            ['cheese', 'Extra Cheese', 500.0],
            ['bacon', 'Bacon', 1000.0],
            ['jalapeno', 'Jalapeños', 250.0],
            ['sauce', 'Extra Sauce', 250.0]
          ]),
        ])),
      ),
      MenuItemsCompanion(
        id: const Value('2'),
        categoryId: const Value('burgers'),
        name: const Value('Cheese Burger'),
        price: const Value(6500),
        emoji: const Value('🍔'),
        modifierGroupsJson: Value(enc([
          _mg('Size', false, [
            ['b_reg', 'Regular', 6500.0],
            ['b_lg', 'Large', 8500.0]
          ]),
          _mg('Extras', true, [
            ['cheese', 'Extra Cheese', 500.0],
            ['bacon', 'Bacon', 1000.0],
            ['jalapeno', 'Jalapeños', 250.0],
            ['sauce', 'Extra Sauce', 250.0]
          ]),
        ])),
      ),
      MenuItemsCompanion(
          id: const Value('3'),
          categoryId: const Value('burgers'),
          name: const Value('Double Smash'),
          price: const Value(8000),
          emoji: const Value('🍔'),
          modifierGroupsJson: const Value('[]')),
      MenuItemsCompanion(
          id: const Value('4'),
          categoryId: const Value('burgers'),
          name: const Value('BBQ Bacon Burger'),
          price: const Value(9500),
          emoji: const Value('🍔'),
          modifierGroupsJson: const Value('[]')),
      MenuItemsCompanion(
        id: const Value('5'),
        categoryId: const Value('pizza'),
        name: const Value('Margherita'),
        price: const Value(10000),
        emoji: const Value('🍕'),
        modifierGroupsJson: Value(enc([
          _mg('Size', false, [
            ['p_sm', 'Small', 8000.0],
            ['p_md', 'Medium', 10000.0],
            ['p_lg', 'Large', 13000.0]
          ]),
          _mg('Toppings', true, [
            ['xtra_cheese', 'Extra Cheese', 500.0],
            ['mushrooms', 'Mushrooms', 500.0],
            ['olives', 'Olives', 500.0],
            ['peppers', 'Peppers', 500.0]
          ]),
        ])),
      ),
      MenuItemsCompanion(
        id: const Value('6'),
        categoryId: const Value('pizza'),
        name: const Value('Pepperoni'),
        price: const Value(12000),
        emoji: const Value('🍕'),
        modifierGroupsJson: Value(enc([
          _mg('Size', false, [
            ['p_sm', 'Small', 10000.0],
            ['p_md', 'Medium', 12000.0],
            ['p_lg', 'Large', 15000.0]
          ]),
          _mg('Toppings', true, [
            ['xtra_cheese', 'Extra Cheese', 500.0],
            ['mushrooms', 'Mushrooms', 500.0],
            ['olives', 'Olives', 500.0],
            ['peppers', 'Peppers', 500.0]
          ]),
        ])),
      ),
      MenuItemsCompanion(
          id: const Value('7'),
          categoryId: const Value('pizza'),
          name: const Value('BBQ Chicken'),
          price: const Value(13500),
          emoji: const Value('🍕'),
          modifierGroupsJson: const Value('[]')),
      MenuItemsCompanion(
          id: const Value('8'),
          categoryId: const Value('pizza'),
          name: const Value('Four Cheese'),
          price: const Value(11500),
          emoji: const Value('🍕'),
          modifierGroupsJson: const Value('[]')),
      MenuItemsCompanion(
          id: const Value('9'),
          categoryId: const Value('drinks'),
          name: const Value('Pepsi'),
          price: const Value(1500),
          emoji: const Value('🥤'),
          modifierGroupsJson: const Value('[]')),
      MenuItemsCompanion(
          id: const Value('10'),
          categoryId: const Value('drinks'),
          name: const Value('Fresh Orange Juice'),
          price: const Value(3000),
          emoji: const Value('🧃'),
          modifierGroupsJson: const Value('[]')),
      MenuItemsCompanion(
          id: const Value('11'),
          categoryId: const Value('drinks'),
          name: const Value('Mineral Water'),
          price: const Value(1000),
          emoji: const Value('💧'),
          modifierGroupsJson: const Value('[]')),
      MenuItemsCompanion(
          id: const Value('12'),
          categoryId: const Value('drinks'),
          name: const Value('Lemonade'),
          price: const Value(2500),
          emoji: const Value('🍋'),
          modifierGroupsJson: const Value('[]')),
      MenuItemsCompanion(
          id: const Value('13'),
          categoryId: const Value('desserts'),
          name: const Value('Chocolate Cake'),
          price: const Value(4000),
          emoji: const Value('🎂'),
          modifierGroupsJson: const Value('[]')),
      MenuItemsCompanion(
          id: const Value('14'),
          categoryId: const Value('desserts'),
          name: const Value('Ice Cream'),
          price: const Value(2500),
          emoji: const Value('🍦'),
          modifierGroupsJson: const Value('[]')),
      MenuItemsCompanion(
          id: const Value('15'),
          categoryId: const Value('desserts'),
          name: const Value('Cheesecake'),
          price: const Value(4500),
          emoji: const Value('🍰'),
          modifierGroupsJson: const Value('[]')),
      MenuItemsCompanion(
          id: const Value('16'),
          categoryId: const Value('sides'),
          name: const Value('French Fries'),
          price: const Value(2500),
          emoji: const Value('🍟'),
          modifierGroupsJson: const Value('[]')),
      MenuItemsCompanion(
          id: const Value('17'),
          categoryId: const Value('sides'),
          name: const Value('Onion Rings'),
          price: const Value(3000),
          emoji: const Value('🧅'),
          modifierGroupsJson: const Value('[]')),
      MenuItemsCompanion(
          id: const Value('18'),
          categoryId: const Value('sides'),
          name: const Value('Coleslaw'),
          price: const Value(1500),
          emoji: const Value('🥗'),
          modifierGroupsJson: const Value('[]')),
    ];
  }

  // ── Categories ────────────────────────────────────────────────────────────

  Future<List<Category>> getCategories() async {
    final rows = await select(categories).get();
    return rows
        .map((r) => Category(id: r.id, name: r.name, emoji: r.emoji))
        .toList();
  }

  Future<void> upsertCategory(Category cat) => into(categories)
      .insertOnConflictUpdate(CategoriesCompanion(
        id: Value(cat.id),
        name: Value(cat.name),
        emoji: Value(cat.emoji),
      ));

  Future<void> deleteCategory(String id) =>
      (delete(categories)..where((t) => t.id.equals(id))).go();

  // ── Menu Items ────────────────────────────────────────────────────────────

  Future<List<MenuItem>> getMenuItems() async {
    final rows = await select(menuItems).get();
    return rows.map(_menuItemFromRow).toList();
  }

  Future<void> upsertMenuItem(MenuItem item) =>
      into(menuItems).insertOnConflictUpdate(MenuItemsCompanion(
        id: Value(item.id),
        categoryId: Value(item.categoryId),
        name: Value(item.name),
        price: Value(item.price),
        emoji: Value(item.emoji),
        modifierGroupsJson:
            Value(_encodeModifierGroups(item.modifierGroups)),
      ));

  Future<void> deleteMenuItem(String id) =>
      (delete(menuItems)..where((t) => t.id.equals(id))).go();

  MenuItem _menuItemFromRow(MenuItemRow r) => MenuItem(
        id: r.id,
        categoryId: r.categoryId,
        name: r.name,
        price: r.price,
        emoji: r.emoji,
        modifierGroups: _decodeModifierGroups(r.modifierGroupsJson),
      );

  String _encodeModifierGroups(List<ModifierGroup> groups) =>
      jsonEncode(groups
          .map((g) => {
                'name': g.name,
                'multiSelect': g.multiSelect,
                'options': g.options
                    .map((o) =>
                        {'id': o.id, 'name': o.name, 'price': o.price})
                    .toList(),
              })
          .toList());

  List<ModifierGroup> _decodeModifierGroups(String json) {
    final list = jsonDecode(json) as List;
    return list.map((g) {
      final opts = (g['options'] as List)
          .map((o) => ModifierOption(
                id: o['id'] as String,
                name: o['name'] as String,
                price: (o['price'] as num).toDouble(),
              ))
          .toList();
      return ModifierGroup(
        name: g['name'] as String,
        multiSelect: g['multiSelect'] as bool,
        options: opts,
      );
    }).toList();
  }

  // ── Staff ─────────────────────────────────────────────────────────────────

  Future<List<Staff>> getStaff() async {
    final rows = await select(staffMembers).get();
    return rows
        .map((r) => Staff(
              id: r.id,
              name: r.name,
              role: StaffRole.values.byName(r.role),
              pin: r.pin,
              avatar: r.avatar,
            ))
        .toList();
  }

  Future<void> upsertStaff(Staff staff) =>
      into(staffMembers).insertOnConflictUpdate(StaffMembersCompanion(
        id: Value(staff.id),
        name: Value(staff.name),
        role: Value(staff.role.name),
        pin: Value(staff.pin),
        avatar: Value(staff.avatar),
      ));

  Future<void> deleteStaff(String id) =>
      (delete(staffMembers)..where((t) => t.id.equals(id))).go();

  // ── Role Permissions ──────────────────────────────────────────────────────

  Future<Map<StaffRole, Set<AppPermission>>> getRolePermissions() async {
    final rows = await select(rolePerms).get();
    final result = <StaffRole, Set<AppPermission>>{
      for (final role in StaffRole.values) role: {},
    };
    for (final row in rows) {
      final role = StaffRole.values.byName(row.role);
      final perm = AppPermission.values.byName(row.permission);
      result[role]!.add(perm);
    }
    return result;
  }

  Future<void> setRolePermission(
      StaffRole role, AppPermission perm, bool enabled) async {
    if (enabled) {
      await into(rolePerms).insertOnConflictUpdate(RolePermsCompanion(
        role: Value(role.name),
        permission: Value(perm.name),
      ));
    } else {
      await (delete(rolePerms)
            ..where((t) =>
                t.role.equals(role.name) &
                t.permission.equals(perm.name)))
          .go();
    }
  }

  // ── Restaurant Tables ─────────────────────────────────────────────────────

  Future<List<RestaurantTable>> getTables() async {
    final rows = await select(restaurantTables).get();
    return rows
        .map((r) => RestaurantTable(
              id: r.id,
              number: r.number,
              capacity: r.capacity,
              status: TableStatus.values.byName(r.status),
            ))
        .toList();
  }

  Future<void> upsertTable(RestaurantTable table) =>
      into(restaurantTables)
          .insertOnConflictUpdate(RestaurantTablesCompanion(
        id: Value(table.id),
        number: Value(table.number),
        capacity: Value(table.capacity),
        status: Value(table.status.name),
      ));

  Future<void> deleteTable(String id) =>
      (delete(restaurantTables)..where((t) => t.id.equals(id))).go();

  // ── Orders ────────────────────────────────────────────────────────────────

  Future<List<CompletedPayment>> getOrders() async {
    final orderRows = await (select(orders)
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
        .get();
    final itemRows = await select(orderItems).get();

    return orderRows.map((o) {
      final items = itemRows
          .where((i) => i.orderId == o.id)
          .map((i) => CompletedItem(
                name: i.name,
                emoji: i.emoji,
                quantity: i.quantity,
                unitPrice: i.unitPrice,
                modifiersLabel: i.modifiersLabel,
              ))
          .toList();

      return CompletedPayment(
        id: o.id,
        orderNumber: o.orderNumber,
        orderType: o.orderType,
        staffName: o.staffName,
        tableId: o.tableId,
        tableNumber: o.tableNumber,
        items: items,
        subtotal: o.subtotal,
        discountAmount: o.discountAmount,
        tax: o.tax,
        tip: o.tip,
        total: o.total,
        method: PaymentMethod.values.byName(o.method),
        cashPaid: o.cashPaid,
        cardPaid: o.cardPaid,
        change: o.changeAmount,
        timestamp: DateTime.fromMillisecondsSinceEpoch(o.timestamp),
      );
    }).toList();
  }

  Future<void> insertOrder(CompletedPayment payment) async {
    await into(orders).insert(OrdersCompanion(
      id: Value(payment.id),
      orderNumber: Value(payment.orderNumber),
      orderType: Value(payment.orderType),
      staffName: Value(payment.staffName),
      tableId: Value(payment.tableId),
      tableNumber: Value(payment.tableNumber),
      subtotal: Value(payment.subtotal),
      discountAmount: Value(payment.discountAmount),
      tax: Value(payment.tax),
      tip: Value(payment.tip),
      total: Value(payment.total),
      method: Value(payment.method.name),
      cashPaid: Value(payment.cashPaid),
      cardPaid: Value(payment.cardPaid),
      changeAmount: Value(payment.change),
      timestamp: Value(payment.timestamp.millisecondsSinceEpoch),
    ));

    await batch((b) {
      for (int i = 0; i < payment.items.length; i++) {
        final item = payment.items[i];
        b.insert(
          orderItems,
          OrderItemsCompanion(
            id: Value('${payment.id}_$i'),
            orderId: Value(payment.id),
            name: Value(item.name),
            emoji: Value(item.emoji),
            quantity: Value(item.quantity),
            unitPrice: Value(item.unitPrice),
            modifiersLabel: Value(item.modifiersLabel),
          ),
        );
      }
    });
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  Future<AppSettings> getSettings() async {
    final rows = await select(settingsKv).get();
    final map = {for (final r in rows) r.key: r.value};
    return AppSettings(
      restaurantName: map['restaurantName'] ?? 'My Restaurant',
      restaurantAddress: map['restaurantAddress'] ?? '',
      restaurantPhone: map['restaurantPhone'] ?? '',
      serviceMode: ServiceMode.values
          .byName(map['serviceMode'] ?? 'fullService'),
      taxEnabled: map['taxEnabled'] == 'true',
      taxRate: double.tryParse(map['taxRate'] ?? '0') ?? 0,
      receiptFooter: map['receiptFooter'] ??
          'Thank you for your visit! Come back again 😊',
    );
  }

  Future<void> saveSettings(AppSettings s) async {
    final pairs = {
      'restaurantName': s.restaurantName,
      'restaurantAddress': s.restaurantAddress,
      'restaurantPhone': s.restaurantPhone,
      'serviceMode': s.serviceMode.name,
      'taxEnabled': s.taxEnabled.toString(),
      'taxRate': s.taxRate.toString(),
      'receiptFooter': s.receiptFooter,
    };
    await batch((b) {
      for (final entry in pairs.entries) {
        b.insert(
          settingsKv,
          SettingsKvCompanion(
              key: Value(entry.key), value: Value(entry.value)),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  // ── Locations (delivery neighbourhoods) ───────────────────────────────────
  // Stored as a JSON blob in settingsKv (key 'locations') so no schema change
  // is needed. Mirrors the modifier-groups JSON approach used for menu items.

  Future<List<Location>> getLocations() async {
    final raw = await _getSetting('locations');
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => Location.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveLocations(List<Location> locations) => _setSetting(
        'locations',
        jsonEncode(locations.map((l) => l.toJson()).toList()),
      );

  // ── Order counter (daily reset) ───────────────────────────────────────────

  Future<int> loadTodayCounter() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = await _getSetting('_orderDate');
    if (savedDate != today) {
      await batch((b) {
        b.insert(
          settingsKv,
          SettingsKvCompanion(key: const Value('_orderDate'), value: Value(today)),
          mode: InsertMode.insertOrReplace,
        );
        b.insert(
          settingsKv,
          const SettingsKvCompanion(key: Value('_orderCounter'), value: Value('0')),
          mode: InsertMode.insertOrReplace,
        );
      });
      return 0;
    }
    return int.tryParse(await _getSetting('_orderCounter') ?? '0') ?? 0;
  }

  Future<void> persistCounter(int value) =>
      _setSetting('_orderCounter', value.toString());

  Future<String?> _getSetting(String key) async {
    final row = await (select(settingsKv)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> _setSetting(String key, String value) =>
      into(settingsKv).insertOnConflictUpdate(
          SettingsKvCompanion(key: Value(key), value: Value(value)));
}
