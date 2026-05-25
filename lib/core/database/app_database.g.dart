// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
    'emoji',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('🍽️'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, emoji];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('emoji')) {
      context.handle(
        _emojiMeta,
        emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      emoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final String id;
  final String name;
  final String emoji;
  const CategoryRow({
    required this.id,
    required this.name,
    required this.emoji,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['emoji'] = Variable<String>(emoji);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      emoji: Value(emoji),
    );
  }

  factory CategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      emoji: serializer.fromJson<String>(json['emoji']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'emoji': serializer.toJson<String>(emoji),
    };
  }

  CategoryRow copyWith({String? id, String? name, String? emoji}) =>
      CategoryRow(
        id: id ?? this.id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
      );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('emoji: $emoji')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, emoji);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.emoji == this.emoji);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> emoji;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.emoji = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String name,
    this.emoji = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<CategoryRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? emoji,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (emoji != null) 'emoji': emoji,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? emoji,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('emoji: $emoji, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MenuItemsTable extends MenuItems
    with TableInfo<$MenuItemsTable, MenuItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MenuItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
    'emoji',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('🍽️'),
  );
  static const VerificationMeta _modifierGroupsJsonMeta =
      const VerificationMeta('modifierGroupsJson');
  @override
  late final GeneratedColumn<String> modifierGroupsJson =
      GeneratedColumn<String>(
        'modifier_groups_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    categoryId,
    name,
    price,
    emoji,
    modifierGroupsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'menu_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<MenuItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('emoji')) {
      context.handle(
        _emojiMeta,
        emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta),
      );
    }
    if (data.containsKey('modifier_groups_json')) {
      context.handle(
        _modifierGroupsJsonMeta,
        modifierGroupsJson.isAcceptableOrUnknown(
          data['modifier_groups_json']!,
          _modifierGroupsJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MenuItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MenuItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price'],
      )!,
      emoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji'],
      )!,
      modifierGroupsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modifier_groups_json'],
      )!,
    );
  }

  @override
  $MenuItemsTable createAlias(String alias) {
    return $MenuItemsTable(attachedDatabase, alias);
  }
}

class MenuItemRow extends DataClass implements Insertable<MenuItemRow> {
  final String id;
  final String categoryId;
  final String name;
  final double price;
  final String emoji;
  final String modifierGroupsJson;
  const MenuItemRow({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.price,
    required this.emoji,
    required this.modifierGroupsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['category_id'] = Variable<String>(categoryId);
    map['name'] = Variable<String>(name);
    map['price'] = Variable<double>(price);
    map['emoji'] = Variable<String>(emoji);
    map['modifier_groups_json'] = Variable<String>(modifierGroupsJson);
    return map;
  }

  MenuItemsCompanion toCompanion(bool nullToAbsent) {
    return MenuItemsCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      name: Value(name),
      price: Value(price),
      emoji: Value(emoji),
      modifierGroupsJson: Value(modifierGroupsJson),
    );
  }

  factory MenuItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MenuItemRow(
      id: serializer.fromJson<String>(json['id']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      name: serializer.fromJson<String>(json['name']),
      price: serializer.fromJson<double>(json['price']),
      emoji: serializer.fromJson<String>(json['emoji']),
      modifierGroupsJson: serializer.fromJson<String>(
        json['modifierGroupsJson'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'categoryId': serializer.toJson<String>(categoryId),
      'name': serializer.toJson<String>(name),
      'price': serializer.toJson<double>(price),
      'emoji': serializer.toJson<String>(emoji),
      'modifierGroupsJson': serializer.toJson<String>(modifierGroupsJson),
    };
  }

  MenuItemRow copyWith({
    String? id,
    String? categoryId,
    String? name,
    double? price,
    String? emoji,
    String? modifierGroupsJson,
  }) => MenuItemRow(
    id: id ?? this.id,
    categoryId: categoryId ?? this.categoryId,
    name: name ?? this.name,
    price: price ?? this.price,
    emoji: emoji ?? this.emoji,
    modifierGroupsJson: modifierGroupsJson ?? this.modifierGroupsJson,
  );
  MenuItemRow copyWithCompanion(MenuItemsCompanion data) {
    return MenuItemRow(
      id: data.id.present ? data.id.value : this.id,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      name: data.name.present ? data.name.value : this.name,
      price: data.price.present ? data.price.value : this.price,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      modifierGroupsJson: data.modifierGroupsJson.present
          ? data.modifierGroupsJson.value
          : this.modifierGroupsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MenuItemRow(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('price: $price, ')
          ..write('emoji: $emoji, ')
          ..write('modifierGroupsJson: $modifierGroupsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, categoryId, name, price, emoji, modifierGroupsJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MenuItemRow &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.name == this.name &&
          other.price == this.price &&
          other.emoji == this.emoji &&
          other.modifierGroupsJson == this.modifierGroupsJson);
}

class MenuItemsCompanion extends UpdateCompanion<MenuItemRow> {
  final Value<String> id;
  final Value<String> categoryId;
  final Value<String> name;
  final Value<double> price;
  final Value<String> emoji;
  final Value<String> modifierGroupsJson;
  final Value<int> rowid;
  const MenuItemsCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.name = const Value.absent(),
    this.price = const Value.absent(),
    this.emoji = const Value.absent(),
    this.modifierGroupsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MenuItemsCompanion.insert({
    required String id,
    required String categoryId,
    required String name,
    required double price,
    this.emoji = const Value.absent(),
    this.modifierGroupsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       categoryId = Value(categoryId),
       name = Value(name),
       price = Value(price);
  static Insertable<MenuItemRow> custom({
    Expression<String>? id,
    Expression<String>? categoryId,
    Expression<String>? name,
    Expression<double>? price,
    Expression<String>? emoji,
    Expression<String>? modifierGroupsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (name != null) 'name': name,
      if (price != null) 'price': price,
      if (emoji != null) 'emoji': emoji,
      if (modifierGroupsJson != null)
        'modifier_groups_json': modifierGroupsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MenuItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? categoryId,
    Value<String>? name,
    Value<double>? price,
    Value<String>? emoji,
    Value<String>? modifierGroupsJson,
    Value<int>? rowid,
  }) {
    return MenuItemsCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      price: price ?? this.price,
      emoji: emoji ?? this.emoji,
      modifierGroupsJson: modifierGroupsJson ?? this.modifierGroupsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (modifierGroupsJson.present) {
      map['modifier_groups_json'] = Variable<String>(modifierGroupsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MenuItemsCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('price: $price, ')
          ..write('emoji: $emoji, ')
          ..write('modifierGroupsJson: $modifierGroupsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StaffMembersTable extends StaffMembers
    with TableInfo<$StaffMembersTable, StaffRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StaffMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pinMeta = const VerificationMeta('pin');
  @override
  late final GeneratedColumn<String> pin = GeneratedColumn<String>(
    'pin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avatarMeta = const VerificationMeta('avatar');
  @override
  late final GeneratedColumn<String> avatar = GeneratedColumn<String>(
    'avatar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('👤'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, role, pin, avatar];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'staff_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<StaffRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('pin')) {
      context.handle(
        _pinMeta,
        pin.isAcceptableOrUnknown(data['pin']!, _pinMeta),
      );
    } else if (isInserting) {
      context.missing(_pinMeta);
    }
    if (data.containsKey('avatar')) {
      context.handle(
        _avatarMeta,
        avatar.isAcceptableOrUnknown(data['avatar']!, _avatarMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StaffRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StaffRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      pin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pin'],
      )!,
      avatar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar'],
      )!,
    );
  }

  @override
  $StaffMembersTable createAlias(String alias) {
    return $StaffMembersTable(attachedDatabase, alias);
  }
}

class StaffRow extends DataClass implements Insertable<StaffRow> {
  final String id;
  final String name;
  final String role;
  final String pin;
  final String avatar;
  const StaffRow({
    required this.id,
    required this.name,
    required this.role,
    required this.pin,
    required this.avatar,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['role'] = Variable<String>(role);
    map['pin'] = Variable<String>(pin);
    map['avatar'] = Variable<String>(avatar);
    return map;
  }

  StaffMembersCompanion toCompanion(bool nullToAbsent) {
    return StaffMembersCompanion(
      id: Value(id),
      name: Value(name),
      role: Value(role),
      pin: Value(pin),
      avatar: Value(avatar),
    );
  }

  factory StaffRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StaffRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      role: serializer.fromJson<String>(json['role']),
      pin: serializer.fromJson<String>(json['pin']),
      avatar: serializer.fromJson<String>(json['avatar']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'role': serializer.toJson<String>(role),
      'pin': serializer.toJson<String>(pin),
      'avatar': serializer.toJson<String>(avatar),
    };
  }

  StaffRow copyWith({
    String? id,
    String? name,
    String? role,
    String? pin,
    String? avatar,
  }) => StaffRow(
    id: id ?? this.id,
    name: name ?? this.name,
    role: role ?? this.role,
    pin: pin ?? this.pin,
    avatar: avatar ?? this.avatar,
  );
  StaffRow copyWithCompanion(StaffMembersCompanion data) {
    return StaffRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      role: data.role.present ? data.role.value : this.role,
      pin: data.pin.present ? data.pin.value : this.pin,
      avatar: data.avatar.present ? data.avatar.value : this.avatar,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StaffRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('pin: $pin, ')
          ..write('avatar: $avatar')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, role, pin, avatar);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StaffRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.role == this.role &&
          other.pin == this.pin &&
          other.avatar == this.avatar);
}

class StaffMembersCompanion extends UpdateCompanion<StaffRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> role;
  final Value<String> pin;
  final Value<String> avatar;
  final Value<int> rowid;
  const StaffMembersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.role = const Value.absent(),
    this.pin = const Value.absent(),
    this.avatar = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StaffMembersCompanion.insert({
    required String id,
    required String name,
    required String role,
    required String pin,
    this.avatar = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       role = Value(role),
       pin = Value(pin);
  static Insertable<StaffRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? role,
    Expression<String>? pin,
    Expression<String>? avatar,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (role != null) 'role': role,
      if (pin != null) 'pin': pin,
      if (avatar != null) 'avatar': avatar,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StaffMembersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? role,
    Value<String>? pin,
    Value<String>? avatar,
    Value<int>? rowid,
  }) {
    return StaffMembersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      pin: pin ?? this.pin,
      avatar: avatar ?? this.avatar,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (pin.present) {
      map['pin'] = Variable<String>(pin.value);
    }
    if (avatar.present) {
      map['avatar'] = Variable<String>(avatar.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StaffMembersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('pin: $pin, ')
          ..write('avatar: $avatar, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RolePermsTable extends RolePerms
    with TableInfo<$RolePermsTable, RolePermRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RolePermsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _permissionMeta = const VerificationMeta(
    'permission',
  );
  @override
  late final GeneratedColumn<String> permission = GeneratedColumn<String>(
    'permission',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [role, permission];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'role_perms';
  @override
  VerificationContext validateIntegrity(
    Insertable<RolePermRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('permission')) {
      context.handle(
        _permissionMeta,
        permission.isAcceptableOrUnknown(data['permission']!, _permissionMeta),
      );
    } else if (isInserting) {
      context.missing(_permissionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {role, permission};
  @override
  RolePermRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RolePermRow(
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      permission: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}permission'],
      )!,
    );
  }

  @override
  $RolePermsTable createAlias(String alias) {
    return $RolePermsTable(attachedDatabase, alias);
  }
}

class RolePermRow extends DataClass implements Insertable<RolePermRow> {
  final String role;
  final String permission;
  const RolePermRow({required this.role, required this.permission});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['role'] = Variable<String>(role);
    map['permission'] = Variable<String>(permission);
    return map;
  }

  RolePermsCompanion toCompanion(bool nullToAbsent) {
    return RolePermsCompanion(role: Value(role), permission: Value(permission));
  }

  factory RolePermRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RolePermRow(
      role: serializer.fromJson<String>(json['role']),
      permission: serializer.fromJson<String>(json['permission']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'role': serializer.toJson<String>(role),
      'permission': serializer.toJson<String>(permission),
    };
  }

  RolePermRow copyWith({String? role, String? permission}) => RolePermRow(
    role: role ?? this.role,
    permission: permission ?? this.permission,
  );
  RolePermRow copyWithCompanion(RolePermsCompanion data) {
    return RolePermRow(
      role: data.role.present ? data.role.value : this.role,
      permission: data.permission.present
          ? data.permission.value
          : this.permission,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RolePermRow(')
          ..write('role: $role, ')
          ..write('permission: $permission')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(role, permission);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RolePermRow &&
          other.role == this.role &&
          other.permission == this.permission);
}

class RolePermsCompanion extends UpdateCompanion<RolePermRow> {
  final Value<String> role;
  final Value<String> permission;
  final Value<int> rowid;
  const RolePermsCompanion({
    this.role = const Value.absent(),
    this.permission = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RolePermsCompanion.insert({
    required String role,
    required String permission,
    this.rowid = const Value.absent(),
  }) : role = Value(role),
       permission = Value(permission);
  static Insertable<RolePermRow> custom({
    Expression<String>? role,
    Expression<String>? permission,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (role != null) 'role': role,
      if (permission != null) 'permission': permission,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RolePermsCompanion copyWith({
    Value<String>? role,
    Value<String>? permission,
    Value<int>? rowid,
  }) {
    return RolePermsCompanion(
      role: role ?? this.role,
      permission: permission ?? this.permission,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (permission.present) {
      map['permission'] = Variable<String>(permission.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RolePermsCompanion(')
          ..write('role: $role, ')
          ..write('permission: $permission, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RestaurantTablesTable extends RestaurantTables
    with TableInfo<$RestaurantTablesTable, RestaurantTableRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RestaurantTablesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _capacityMeta = const VerificationMeta(
    'capacity',
  );
  @override
  late final GeneratedColumn<int> capacity = GeneratedColumn<int>(
    'capacity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('available'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, number, capacity, status];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'restaurant_tables';
  @override
  VerificationContext validateIntegrity(
    Insertable<RestaurantTableRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('capacity')) {
      context.handle(
        _capacityMeta,
        capacity.isAcceptableOrUnknown(data['capacity']!, _capacityMeta),
      );
    } else if (isInserting) {
      context.missing(_capacityMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RestaurantTableRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RestaurantTableRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
      )!,
      capacity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}capacity'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $RestaurantTablesTable createAlias(String alias) {
    return $RestaurantTablesTable(attachedDatabase, alias);
  }
}

class RestaurantTableRow extends DataClass
    implements Insertable<RestaurantTableRow> {
  final String id;
  final int number;
  final int capacity;
  final String status;
  const RestaurantTableRow({
    required this.id,
    required this.number,
    required this.capacity,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['number'] = Variable<int>(number);
    map['capacity'] = Variable<int>(capacity);
    map['status'] = Variable<String>(status);
    return map;
  }

  RestaurantTablesCompanion toCompanion(bool nullToAbsent) {
    return RestaurantTablesCompanion(
      id: Value(id),
      number: Value(number),
      capacity: Value(capacity),
      status: Value(status),
    );
  }

  factory RestaurantTableRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RestaurantTableRow(
      id: serializer.fromJson<String>(json['id']),
      number: serializer.fromJson<int>(json['number']),
      capacity: serializer.fromJson<int>(json['capacity']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'number': serializer.toJson<int>(number),
      'capacity': serializer.toJson<int>(capacity),
      'status': serializer.toJson<String>(status),
    };
  }

  RestaurantTableRow copyWith({
    String? id,
    int? number,
    int? capacity,
    String? status,
  }) => RestaurantTableRow(
    id: id ?? this.id,
    number: number ?? this.number,
    capacity: capacity ?? this.capacity,
    status: status ?? this.status,
  );
  RestaurantTableRow copyWithCompanion(RestaurantTablesCompanion data) {
    return RestaurantTableRow(
      id: data.id.present ? data.id.value : this.id,
      number: data.number.present ? data.number.value : this.number,
      capacity: data.capacity.present ? data.capacity.value : this.capacity,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RestaurantTableRow(')
          ..write('id: $id, ')
          ..write('number: $number, ')
          ..write('capacity: $capacity, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, number, capacity, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RestaurantTableRow &&
          other.id == this.id &&
          other.number == this.number &&
          other.capacity == this.capacity &&
          other.status == this.status);
}

class RestaurantTablesCompanion extends UpdateCompanion<RestaurantTableRow> {
  final Value<String> id;
  final Value<int> number;
  final Value<int> capacity;
  final Value<String> status;
  final Value<int> rowid;
  const RestaurantTablesCompanion({
    this.id = const Value.absent(),
    this.number = const Value.absent(),
    this.capacity = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RestaurantTablesCompanion.insert({
    required String id,
    required int number,
    required int capacity,
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       number = Value(number),
       capacity = Value(capacity);
  static Insertable<RestaurantTableRow> custom({
    Expression<String>? id,
    Expression<int>? number,
    Expression<int>? capacity,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (number != null) 'number': number,
      if (capacity != null) 'capacity': capacity,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RestaurantTablesCompanion copyWith({
    Value<String>? id,
    Value<int>? number,
    Value<int>? capacity,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return RestaurantTablesCompanion(
      id: id ?? this.id,
      number: number ?? this.number,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (capacity.present) {
      map['capacity'] = Variable<int>(capacity.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RestaurantTablesCompanion(')
          ..write('id: $id, ')
          ..write('number: $number, ')
          ..write('capacity: $capacity, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrdersTable extends Orders with TableInfo<$OrdersTable, OrderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderNumberMeta = const VerificationMeta(
    'orderNumber',
  );
  @override
  late final GeneratedColumn<String> orderNumber = GeneratedColumn<String>(
    'order_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderTypeMeta = const VerificationMeta(
    'orderType',
  );
  @override
  late final GeneratedColumn<String> orderType = GeneratedColumn<String>(
    'order_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _staffNameMeta = const VerificationMeta(
    'staffName',
  );
  @override
  late final GeneratedColumn<String> staffName = GeneratedColumn<String>(
    'staff_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tableIdMeta = const VerificationMeta(
    'tableId',
  );
  @override
  late final GeneratedColumn<String> tableId = GeneratedColumn<String>(
    'table_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _tableNumberMeta = const VerificationMeta(
    'tableNumber',
  );
  @override
  late final GeneratedColumn<int> tableNumber = GeneratedColumn<int>(
    'table_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _subtotalMeta = const VerificationMeta(
    'subtotal',
  );
  @override
  late final GeneratedColumn<double> subtotal = GeneratedColumn<double>(
    'subtotal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountAmountMeta = const VerificationMeta(
    'discountAmount',
  );
  @override
  late final GeneratedColumn<double> discountAmount = GeneratedColumn<double>(
    'discount_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _taxMeta = const VerificationMeta('tax');
  @override
  late final GeneratedColumn<double> tax = GeneratedColumn<double>(
    'tax',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _tipMeta = const VerificationMeta('tip');
  @override
  late final GeneratedColumn<double> tip = GeneratedColumn<double>(
    'tip',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<double> total = GeneratedColumn<double>(
    'total',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cashPaidMeta = const VerificationMeta(
    'cashPaid',
  );
  @override
  late final GeneratedColumn<double> cashPaid = GeneratedColumn<double>(
    'cash_paid',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _cardPaidMeta = const VerificationMeta(
    'cardPaid',
  );
  @override
  late final GeneratedColumn<double> cardPaid = GeneratedColumn<double>(
    'card_paid',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _changeAmountMeta = const VerificationMeta(
    'changeAmount',
  );
  @override
  late final GeneratedColumn<double> changeAmount = GeneratedColumn<double>(
    'change_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    orderNumber,
    orderType,
    staffName,
    tableId,
    tableNumber,
    subtotal,
    discountAmount,
    tax,
    tip,
    total,
    method,
    cashPaid,
    cardPaid,
    changeAmount,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'orders';
  @override
  VerificationContext validateIntegrity(
    Insertable<OrderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('order_number')) {
      context.handle(
        _orderNumberMeta,
        orderNumber.isAcceptableOrUnknown(
          data['order_number']!,
          _orderNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_orderNumberMeta);
    }
    if (data.containsKey('order_type')) {
      context.handle(
        _orderTypeMeta,
        orderType.isAcceptableOrUnknown(data['order_type']!, _orderTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_orderTypeMeta);
    }
    if (data.containsKey('staff_name')) {
      context.handle(
        _staffNameMeta,
        staffName.isAcceptableOrUnknown(data['staff_name']!, _staffNameMeta),
      );
    } else if (isInserting) {
      context.missing(_staffNameMeta);
    }
    if (data.containsKey('table_id')) {
      context.handle(
        _tableIdMeta,
        tableId.isAcceptableOrUnknown(data['table_id']!, _tableIdMeta),
      );
    }
    if (data.containsKey('table_number')) {
      context.handle(
        _tableNumberMeta,
        tableNumber.isAcceptableOrUnknown(
          data['table_number']!,
          _tableNumberMeta,
        ),
      );
    }
    if (data.containsKey('subtotal')) {
      context.handle(
        _subtotalMeta,
        subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta),
      );
    } else if (isInserting) {
      context.missing(_subtotalMeta);
    }
    if (data.containsKey('discount_amount')) {
      context.handle(
        _discountAmountMeta,
        discountAmount.isAcceptableOrUnknown(
          data['discount_amount']!,
          _discountAmountMeta,
        ),
      );
    }
    if (data.containsKey('tax')) {
      context.handle(
        _taxMeta,
        tax.isAcceptableOrUnknown(data['tax']!, _taxMeta),
      );
    }
    if (data.containsKey('tip')) {
      context.handle(
        _tipMeta,
        tip.isAcceptableOrUnknown(data['tip']!, _tipMeta),
      );
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    } else if (isInserting) {
      context.missing(_totalMeta);
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('cash_paid')) {
      context.handle(
        _cashPaidMeta,
        cashPaid.isAcceptableOrUnknown(data['cash_paid']!, _cashPaidMeta),
      );
    }
    if (data.containsKey('card_paid')) {
      context.handle(
        _cardPaidMeta,
        cardPaid.isAcceptableOrUnknown(data['card_paid']!, _cardPaidMeta),
      );
    }
    if (data.containsKey('change_amount')) {
      context.handle(
        _changeAmountMeta,
        changeAmount.isAcceptableOrUnknown(
          data['change_amount']!,
          _changeAmountMeta,
        ),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OrderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrderRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      orderNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_number'],
      )!,
      orderType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_type'],
      )!,
      staffName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}staff_name'],
      )!,
      tableId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_id'],
      )!,
      tableNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}table_number'],
      )!,
      subtotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}subtotal'],
      )!,
      discountAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}discount_amount'],
      )!,
      tax: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tax'],
      )!,
      tip: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tip'],
      )!,
      total: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total'],
      )!,
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      )!,
      cashPaid: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cash_paid'],
      )!,
      cardPaid: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}card_paid'],
      )!,
      changeAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}change_amount'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $OrdersTable createAlias(String alias) {
    return $OrdersTable(attachedDatabase, alias);
  }
}

class OrderRow extends DataClass implements Insertable<OrderRow> {
  final String id;
  final String orderNumber;
  final String orderType;
  final String staffName;
  final String tableId;
  final int tableNumber;
  final double subtotal;
  final double discountAmount;
  final double tax;
  final double tip;
  final double total;
  final String method;
  final double cashPaid;
  final double cardPaid;
  final double changeAmount;
  final int timestamp;
  const OrderRow({
    required this.id,
    required this.orderNumber,
    required this.orderType,
    required this.staffName,
    required this.tableId,
    required this.tableNumber,
    required this.subtotal,
    required this.discountAmount,
    required this.tax,
    required this.tip,
    required this.total,
    required this.method,
    required this.cashPaid,
    required this.cardPaid,
    required this.changeAmount,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['order_number'] = Variable<String>(orderNumber);
    map['order_type'] = Variable<String>(orderType);
    map['staff_name'] = Variable<String>(staffName);
    map['table_id'] = Variable<String>(tableId);
    map['table_number'] = Variable<int>(tableNumber);
    map['subtotal'] = Variable<double>(subtotal);
    map['discount_amount'] = Variable<double>(discountAmount);
    map['tax'] = Variable<double>(tax);
    map['tip'] = Variable<double>(tip);
    map['total'] = Variable<double>(total);
    map['method'] = Variable<String>(method);
    map['cash_paid'] = Variable<double>(cashPaid);
    map['card_paid'] = Variable<double>(cardPaid);
    map['change_amount'] = Variable<double>(changeAmount);
    map['timestamp'] = Variable<int>(timestamp);
    return map;
  }

  OrdersCompanion toCompanion(bool nullToAbsent) {
    return OrdersCompanion(
      id: Value(id),
      orderNumber: Value(orderNumber),
      orderType: Value(orderType),
      staffName: Value(staffName),
      tableId: Value(tableId),
      tableNumber: Value(tableNumber),
      subtotal: Value(subtotal),
      discountAmount: Value(discountAmount),
      tax: Value(tax),
      tip: Value(tip),
      total: Value(total),
      method: Value(method),
      cashPaid: Value(cashPaid),
      cardPaid: Value(cardPaid),
      changeAmount: Value(changeAmount),
      timestamp: Value(timestamp),
    );
  }

  factory OrderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrderRow(
      id: serializer.fromJson<String>(json['id']),
      orderNumber: serializer.fromJson<String>(json['orderNumber']),
      orderType: serializer.fromJson<String>(json['orderType']),
      staffName: serializer.fromJson<String>(json['staffName']),
      tableId: serializer.fromJson<String>(json['tableId']),
      tableNumber: serializer.fromJson<int>(json['tableNumber']),
      subtotal: serializer.fromJson<double>(json['subtotal']),
      discountAmount: serializer.fromJson<double>(json['discountAmount']),
      tax: serializer.fromJson<double>(json['tax']),
      tip: serializer.fromJson<double>(json['tip']),
      total: serializer.fromJson<double>(json['total']),
      method: serializer.fromJson<String>(json['method']),
      cashPaid: serializer.fromJson<double>(json['cashPaid']),
      cardPaid: serializer.fromJson<double>(json['cardPaid']),
      changeAmount: serializer.fromJson<double>(json['changeAmount']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'orderNumber': serializer.toJson<String>(orderNumber),
      'orderType': serializer.toJson<String>(orderType),
      'staffName': serializer.toJson<String>(staffName),
      'tableId': serializer.toJson<String>(tableId),
      'tableNumber': serializer.toJson<int>(tableNumber),
      'subtotal': serializer.toJson<double>(subtotal),
      'discountAmount': serializer.toJson<double>(discountAmount),
      'tax': serializer.toJson<double>(tax),
      'tip': serializer.toJson<double>(tip),
      'total': serializer.toJson<double>(total),
      'method': serializer.toJson<String>(method),
      'cashPaid': serializer.toJson<double>(cashPaid),
      'cardPaid': serializer.toJson<double>(cardPaid),
      'changeAmount': serializer.toJson<double>(changeAmount),
      'timestamp': serializer.toJson<int>(timestamp),
    };
  }

  OrderRow copyWith({
    String? id,
    String? orderNumber,
    String? orderType,
    String? staffName,
    String? tableId,
    int? tableNumber,
    double? subtotal,
    double? discountAmount,
    double? tax,
    double? tip,
    double? total,
    String? method,
    double? cashPaid,
    double? cardPaid,
    double? changeAmount,
    int? timestamp,
  }) => OrderRow(
    id: id ?? this.id,
    orderNumber: orderNumber ?? this.orderNumber,
    orderType: orderType ?? this.orderType,
    staffName: staffName ?? this.staffName,
    tableId: tableId ?? this.tableId,
    tableNumber: tableNumber ?? this.tableNumber,
    subtotal: subtotal ?? this.subtotal,
    discountAmount: discountAmount ?? this.discountAmount,
    tax: tax ?? this.tax,
    tip: tip ?? this.tip,
    total: total ?? this.total,
    method: method ?? this.method,
    cashPaid: cashPaid ?? this.cashPaid,
    cardPaid: cardPaid ?? this.cardPaid,
    changeAmount: changeAmount ?? this.changeAmount,
    timestamp: timestamp ?? this.timestamp,
  );
  OrderRow copyWithCompanion(OrdersCompanion data) {
    return OrderRow(
      id: data.id.present ? data.id.value : this.id,
      orderNumber: data.orderNumber.present
          ? data.orderNumber.value
          : this.orderNumber,
      orderType: data.orderType.present ? data.orderType.value : this.orderType,
      staffName: data.staffName.present ? data.staffName.value : this.staffName,
      tableId: data.tableId.present ? data.tableId.value : this.tableId,
      tableNumber: data.tableNumber.present
          ? data.tableNumber.value
          : this.tableNumber,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      discountAmount: data.discountAmount.present
          ? data.discountAmount.value
          : this.discountAmount,
      tax: data.tax.present ? data.tax.value : this.tax,
      tip: data.tip.present ? data.tip.value : this.tip,
      total: data.total.present ? data.total.value : this.total,
      method: data.method.present ? data.method.value : this.method,
      cashPaid: data.cashPaid.present ? data.cashPaid.value : this.cashPaid,
      cardPaid: data.cardPaid.present ? data.cardPaid.value : this.cardPaid,
      changeAmount: data.changeAmount.present
          ? data.changeAmount.value
          : this.changeAmount,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrderRow(')
          ..write('id: $id, ')
          ..write('orderNumber: $orderNumber, ')
          ..write('orderType: $orderType, ')
          ..write('staffName: $staffName, ')
          ..write('tableId: $tableId, ')
          ..write('tableNumber: $tableNumber, ')
          ..write('subtotal: $subtotal, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('tax: $tax, ')
          ..write('tip: $tip, ')
          ..write('total: $total, ')
          ..write('method: $method, ')
          ..write('cashPaid: $cashPaid, ')
          ..write('cardPaid: $cardPaid, ')
          ..write('changeAmount: $changeAmount, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    orderNumber,
    orderType,
    staffName,
    tableId,
    tableNumber,
    subtotal,
    discountAmount,
    tax,
    tip,
    total,
    method,
    cashPaid,
    cardPaid,
    changeAmount,
    timestamp,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderRow &&
          other.id == this.id &&
          other.orderNumber == this.orderNumber &&
          other.orderType == this.orderType &&
          other.staffName == this.staffName &&
          other.tableId == this.tableId &&
          other.tableNumber == this.tableNumber &&
          other.subtotal == this.subtotal &&
          other.discountAmount == this.discountAmount &&
          other.tax == this.tax &&
          other.tip == this.tip &&
          other.total == this.total &&
          other.method == this.method &&
          other.cashPaid == this.cashPaid &&
          other.cardPaid == this.cardPaid &&
          other.changeAmount == this.changeAmount &&
          other.timestamp == this.timestamp);
}

class OrdersCompanion extends UpdateCompanion<OrderRow> {
  final Value<String> id;
  final Value<String> orderNumber;
  final Value<String> orderType;
  final Value<String> staffName;
  final Value<String> tableId;
  final Value<int> tableNumber;
  final Value<double> subtotal;
  final Value<double> discountAmount;
  final Value<double> tax;
  final Value<double> tip;
  final Value<double> total;
  final Value<String> method;
  final Value<double> cashPaid;
  final Value<double> cardPaid;
  final Value<double> changeAmount;
  final Value<int> timestamp;
  final Value<int> rowid;
  const OrdersCompanion({
    this.id = const Value.absent(),
    this.orderNumber = const Value.absent(),
    this.orderType = const Value.absent(),
    this.staffName = const Value.absent(),
    this.tableId = const Value.absent(),
    this.tableNumber = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.discountAmount = const Value.absent(),
    this.tax = const Value.absent(),
    this.tip = const Value.absent(),
    this.total = const Value.absent(),
    this.method = const Value.absent(),
    this.cashPaid = const Value.absent(),
    this.cardPaid = const Value.absent(),
    this.changeAmount = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrdersCompanion.insert({
    required String id,
    required String orderNumber,
    required String orderType,
    required String staffName,
    this.tableId = const Value.absent(),
    this.tableNumber = const Value.absent(),
    required double subtotal,
    this.discountAmount = const Value.absent(),
    this.tax = const Value.absent(),
    this.tip = const Value.absent(),
    required double total,
    required String method,
    this.cashPaid = const Value.absent(),
    this.cardPaid = const Value.absent(),
    this.changeAmount = const Value.absent(),
    required int timestamp,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       orderNumber = Value(orderNumber),
       orderType = Value(orderType),
       staffName = Value(staffName),
       subtotal = Value(subtotal),
       total = Value(total),
       method = Value(method),
       timestamp = Value(timestamp);
  static Insertable<OrderRow> custom({
    Expression<String>? id,
    Expression<String>? orderNumber,
    Expression<String>? orderType,
    Expression<String>? staffName,
    Expression<String>? tableId,
    Expression<int>? tableNumber,
    Expression<double>? subtotal,
    Expression<double>? discountAmount,
    Expression<double>? tax,
    Expression<double>? tip,
    Expression<double>? total,
    Expression<String>? method,
    Expression<double>? cashPaid,
    Expression<double>? cardPaid,
    Expression<double>? changeAmount,
    Expression<int>? timestamp,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderNumber != null) 'order_number': orderNumber,
      if (orderType != null) 'order_type': orderType,
      if (staffName != null) 'staff_name': staffName,
      if (tableId != null) 'table_id': tableId,
      if (tableNumber != null) 'table_number': tableNumber,
      if (subtotal != null) 'subtotal': subtotal,
      if (discountAmount != null) 'discount_amount': discountAmount,
      if (tax != null) 'tax': tax,
      if (tip != null) 'tip': tip,
      if (total != null) 'total': total,
      if (method != null) 'method': method,
      if (cashPaid != null) 'cash_paid': cashPaid,
      if (cardPaid != null) 'card_paid': cardPaid,
      if (changeAmount != null) 'change_amount': changeAmount,
      if (timestamp != null) 'timestamp': timestamp,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrdersCompanion copyWith({
    Value<String>? id,
    Value<String>? orderNumber,
    Value<String>? orderType,
    Value<String>? staffName,
    Value<String>? tableId,
    Value<int>? tableNumber,
    Value<double>? subtotal,
    Value<double>? discountAmount,
    Value<double>? tax,
    Value<double>? tip,
    Value<double>? total,
    Value<String>? method,
    Value<double>? cashPaid,
    Value<double>? cardPaid,
    Value<double>? changeAmount,
    Value<int>? timestamp,
    Value<int>? rowid,
  }) {
    return OrdersCompanion(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      orderType: orderType ?? this.orderType,
      staffName: staffName ?? this.staffName,
      tableId: tableId ?? this.tableId,
      tableNumber: tableNumber ?? this.tableNumber,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      tax: tax ?? this.tax,
      tip: tip ?? this.tip,
      total: total ?? this.total,
      method: method ?? this.method,
      cashPaid: cashPaid ?? this.cashPaid,
      cardPaid: cardPaid ?? this.cardPaid,
      changeAmount: changeAmount ?? this.changeAmount,
      timestamp: timestamp ?? this.timestamp,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (orderNumber.present) {
      map['order_number'] = Variable<String>(orderNumber.value);
    }
    if (orderType.present) {
      map['order_type'] = Variable<String>(orderType.value);
    }
    if (staffName.present) {
      map['staff_name'] = Variable<String>(staffName.value);
    }
    if (tableId.present) {
      map['table_id'] = Variable<String>(tableId.value);
    }
    if (tableNumber.present) {
      map['table_number'] = Variable<int>(tableNumber.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<double>(subtotal.value);
    }
    if (discountAmount.present) {
      map['discount_amount'] = Variable<double>(discountAmount.value);
    }
    if (tax.present) {
      map['tax'] = Variable<double>(tax.value);
    }
    if (tip.present) {
      map['tip'] = Variable<double>(tip.value);
    }
    if (total.present) {
      map['total'] = Variable<double>(total.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (cashPaid.present) {
      map['cash_paid'] = Variable<double>(cashPaid.value);
    }
    if (cardPaid.present) {
      map['card_paid'] = Variable<double>(cardPaid.value);
    }
    if (changeAmount.present) {
      map['change_amount'] = Variable<double>(changeAmount.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrdersCompanion(')
          ..write('id: $id, ')
          ..write('orderNumber: $orderNumber, ')
          ..write('orderType: $orderType, ')
          ..write('staffName: $staffName, ')
          ..write('tableId: $tableId, ')
          ..write('tableNumber: $tableNumber, ')
          ..write('subtotal: $subtotal, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('tax: $tax, ')
          ..write('tip: $tip, ')
          ..write('total: $total, ')
          ..write('method: $method, ')
          ..write('cashPaid: $cashPaid, ')
          ..write('cardPaid: $cardPaid, ')
          ..write('changeAmount: $changeAmount, ')
          ..write('timestamp: $timestamp, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrderItemsTable extends OrderItems
    with TableInfo<$OrderItemsTable, OrderItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrderItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderIdMeta = const VerificationMeta(
    'orderId',
  );
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
    'order_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
    'emoji',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('🍽️'),
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<double> unitPrice = GeneratedColumn<double>(
    'unit_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiersLabelMeta = const VerificationMeta(
    'modifiersLabel',
  );
  @override
  late final GeneratedColumn<String> modifiersLabel = GeneratedColumn<String>(
    'modifiers_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    orderId,
    name,
    emoji,
    quantity,
    unitPrice,
    modifiersLabel,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'order_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<OrderItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('order_id')) {
      context.handle(
        _orderIdMeta,
        orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('emoji')) {
      context.handle(
        _emojiMeta,
        emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_unitPriceMeta);
    }
    if (data.containsKey('modifiers_label')) {
      context.handle(
        _modifiersLabelMeta,
        modifiersLabel.isAcceptableOrUnknown(
          data['modifiers_label']!,
          _modifiersLabelMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OrderItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrderItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      orderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      emoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_price'],
      )!,
      modifiersLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modifiers_label'],
      )!,
    );
  }

  @override
  $OrderItemsTable createAlias(String alias) {
    return $OrderItemsTable(attachedDatabase, alias);
  }
}

class OrderItemRow extends DataClass implements Insertable<OrderItemRow> {
  final String id;
  final String orderId;
  final String name;
  final String emoji;
  final int quantity;
  final double unitPrice;
  final String modifiersLabel;
  const OrderItemRow({
    required this.id,
    required this.orderId,
    required this.name,
    required this.emoji,
    required this.quantity,
    required this.unitPrice,
    required this.modifiersLabel,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['order_id'] = Variable<String>(orderId);
    map['name'] = Variable<String>(name);
    map['emoji'] = Variable<String>(emoji);
    map['quantity'] = Variable<int>(quantity);
    map['unit_price'] = Variable<double>(unitPrice);
    map['modifiers_label'] = Variable<String>(modifiersLabel);
    return map;
  }

  OrderItemsCompanion toCompanion(bool nullToAbsent) {
    return OrderItemsCompanion(
      id: Value(id),
      orderId: Value(orderId),
      name: Value(name),
      emoji: Value(emoji),
      quantity: Value(quantity),
      unitPrice: Value(unitPrice),
      modifiersLabel: Value(modifiersLabel),
    );
  }

  factory OrderItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrderItemRow(
      id: serializer.fromJson<String>(json['id']),
      orderId: serializer.fromJson<String>(json['orderId']),
      name: serializer.fromJson<String>(json['name']),
      emoji: serializer.fromJson<String>(json['emoji']),
      quantity: serializer.fromJson<int>(json['quantity']),
      unitPrice: serializer.fromJson<double>(json['unitPrice']),
      modifiersLabel: serializer.fromJson<String>(json['modifiersLabel']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'orderId': serializer.toJson<String>(orderId),
      'name': serializer.toJson<String>(name),
      'emoji': serializer.toJson<String>(emoji),
      'quantity': serializer.toJson<int>(quantity),
      'unitPrice': serializer.toJson<double>(unitPrice),
      'modifiersLabel': serializer.toJson<String>(modifiersLabel),
    };
  }

  OrderItemRow copyWith({
    String? id,
    String? orderId,
    String? name,
    String? emoji,
    int? quantity,
    double? unitPrice,
    String? modifiersLabel,
  }) => OrderItemRow(
    id: id ?? this.id,
    orderId: orderId ?? this.orderId,
    name: name ?? this.name,
    emoji: emoji ?? this.emoji,
    quantity: quantity ?? this.quantity,
    unitPrice: unitPrice ?? this.unitPrice,
    modifiersLabel: modifiersLabel ?? this.modifiersLabel,
  );
  OrderItemRow copyWithCompanion(OrderItemsCompanion data) {
    return OrderItemRow(
      id: data.id.present ? data.id.value : this.id,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      name: data.name.present ? data.name.value : this.name,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      modifiersLabel: data.modifiersLabel.present
          ? data.modifiersLabel.value
          : this.modifiersLabel,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrderItemRow(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('name: $name, ')
          ..write('emoji: $emoji, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('modifiersLabel: $modifiersLabel')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    orderId,
    name,
    emoji,
    quantity,
    unitPrice,
    modifiersLabel,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderItemRow &&
          other.id == this.id &&
          other.orderId == this.orderId &&
          other.name == this.name &&
          other.emoji == this.emoji &&
          other.quantity == this.quantity &&
          other.unitPrice == this.unitPrice &&
          other.modifiersLabel == this.modifiersLabel);
}

class OrderItemsCompanion extends UpdateCompanion<OrderItemRow> {
  final Value<String> id;
  final Value<String> orderId;
  final Value<String> name;
  final Value<String> emoji;
  final Value<int> quantity;
  final Value<double> unitPrice;
  final Value<String> modifiersLabel;
  final Value<int> rowid;
  const OrderItemsCompanion({
    this.id = const Value.absent(),
    this.orderId = const Value.absent(),
    this.name = const Value.absent(),
    this.emoji = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.modifiersLabel = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrderItemsCompanion.insert({
    required String id,
    required String orderId,
    required String name,
    this.emoji = const Value.absent(),
    required int quantity,
    required double unitPrice,
    this.modifiersLabel = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       orderId = Value(orderId),
       name = Value(name),
       quantity = Value(quantity),
       unitPrice = Value(unitPrice);
  static Insertable<OrderItemRow> custom({
    Expression<String>? id,
    Expression<String>? orderId,
    Expression<String>? name,
    Expression<String>? emoji,
    Expression<int>? quantity,
    Expression<double>? unitPrice,
    Expression<String>? modifiersLabel,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderId != null) 'order_id': orderId,
      if (name != null) 'name': name,
      if (emoji != null) 'emoji': emoji,
      if (quantity != null) 'quantity': quantity,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (modifiersLabel != null) 'modifiers_label': modifiersLabel,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrderItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? orderId,
    Value<String>? name,
    Value<String>? emoji,
    Value<int>? quantity,
    Value<double>? unitPrice,
    Value<String>? modifiersLabel,
    Value<int>? rowid,
  }) {
    return OrderItemsCompanion(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      modifiersLabel: modifiersLabel ?? this.modifiersLabel,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<double>(unitPrice.value);
    }
    if (modifiersLabel.present) {
      map['modifiers_label'] = Variable<String>(modifiersLabel.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrderItemsCompanion(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('name: $name, ')
          ..write('emoji: $emoji, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('modifiersLabel: $modifiersLabel, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsKvTable extends SettingsKv
    with TableInfo<$SettingsKvTable, SettingsKvRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsKvTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings_kv';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsKvRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingsKvRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsKvRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsKvTable createAlias(String alias) {
    return $SettingsKvTable(attachedDatabase, alias);
  }
}

class SettingsKvRow extends DataClass implements Insertable<SettingsKvRow> {
  final String key;
  final String value;
  const SettingsKvRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsKvCompanion toCompanion(bool nullToAbsent) {
    return SettingsKvCompanion(key: Value(key), value: Value(value));
  }

  factory SettingsKvRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsKvRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingsKvRow copyWith({String? key, String? value}) =>
      SettingsKvRow(key: key ?? this.key, value: value ?? this.value);
  SettingsKvRow copyWithCompanion(SettingsKvCompanion data) {
    return SettingsKvRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsKvRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsKvRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsKvCompanion extends UpdateCompanion<SettingsKvRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsKvCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsKvCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingsKvRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsKvCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsKvCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsKvCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $MenuItemsTable menuItems = $MenuItemsTable(this);
  late final $StaffMembersTable staffMembers = $StaffMembersTable(this);
  late final $RolePermsTable rolePerms = $RolePermsTable(this);
  late final $RestaurantTablesTable restaurantTables = $RestaurantTablesTable(
    this,
  );
  late final $OrdersTable orders = $OrdersTable(this);
  late final $OrderItemsTable orderItems = $OrderItemsTable(this);
  late final $SettingsKvTable settingsKv = $SettingsKvTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    categories,
    menuItems,
    staffMembers,
    rolePerms,
    restaurantTables,
    orders,
    orderItems,
    settingsKv,
  ];
}

typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      required String id,
      required String name,
      Value<String> emoji,
      Value<int> rowid,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> emoji,
      Value<int> rowid,
    });

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          CategoryRow,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (
            CategoryRow,
            BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow>,
          ),
          CategoryRow,
          PrefetchHooks Function()
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> emoji = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                emoji: emoji,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> emoji = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                emoji: emoji,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      CategoryRow,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (
        CategoryRow,
        BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow>,
      ),
      CategoryRow,
      PrefetchHooks Function()
    >;
typedef $$MenuItemsTableCreateCompanionBuilder =
    MenuItemsCompanion Function({
      required String id,
      required String categoryId,
      required String name,
      required double price,
      Value<String> emoji,
      Value<String> modifierGroupsJson,
      Value<int> rowid,
    });
typedef $$MenuItemsTableUpdateCompanionBuilder =
    MenuItemsCompanion Function({
      Value<String> id,
      Value<String> categoryId,
      Value<String> name,
      Value<double> price,
      Value<String> emoji,
      Value<String> modifierGroupsJson,
      Value<int> rowid,
    });

class $$MenuItemsTableFilterComposer
    extends Composer<_$AppDatabase, $MenuItemsTable> {
  $$MenuItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modifierGroupsJson => $composableBuilder(
    column: $table.modifierGroupsJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MenuItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $MenuItemsTable> {
  $$MenuItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modifierGroupsJson => $composableBuilder(
    column: $table.modifierGroupsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MenuItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MenuItemsTable> {
  $$MenuItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<String> get modifierGroupsJson => $composableBuilder(
    column: $table.modifierGroupsJson,
    builder: (column) => column,
  );
}

class $$MenuItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MenuItemsTable,
          MenuItemRow,
          $$MenuItemsTableFilterComposer,
          $$MenuItemsTableOrderingComposer,
          $$MenuItemsTableAnnotationComposer,
          $$MenuItemsTableCreateCompanionBuilder,
          $$MenuItemsTableUpdateCompanionBuilder,
          (
            MenuItemRow,
            BaseReferences<_$AppDatabase, $MenuItemsTable, MenuItemRow>,
          ),
          MenuItemRow,
          PrefetchHooks Function()
        > {
  $$MenuItemsTableTableManager(_$AppDatabase db, $MenuItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MenuItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MenuItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MenuItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> price = const Value.absent(),
                Value<String> emoji = const Value.absent(),
                Value<String> modifierGroupsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MenuItemsCompanion(
                id: id,
                categoryId: categoryId,
                name: name,
                price: price,
                emoji: emoji,
                modifierGroupsJson: modifierGroupsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String categoryId,
                required String name,
                required double price,
                Value<String> emoji = const Value.absent(),
                Value<String> modifierGroupsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MenuItemsCompanion.insert(
                id: id,
                categoryId: categoryId,
                name: name,
                price: price,
                emoji: emoji,
                modifierGroupsJson: modifierGroupsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MenuItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MenuItemsTable,
      MenuItemRow,
      $$MenuItemsTableFilterComposer,
      $$MenuItemsTableOrderingComposer,
      $$MenuItemsTableAnnotationComposer,
      $$MenuItemsTableCreateCompanionBuilder,
      $$MenuItemsTableUpdateCompanionBuilder,
      (
        MenuItemRow,
        BaseReferences<_$AppDatabase, $MenuItemsTable, MenuItemRow>,
      ),
      MenuItemRow,
      PrefetchHooks Function()
    >;
typedef $$StaffMembersTableCreateCompanionBuilder =
    StaffMembersCompanion Function({
      required String id,
      required String name,
      required String role,
      required String pin,
      Value<String> avatar,
      Value<int> rowid,
    });
typedef $$StaffMembersTableUpdateCompanionBuilder =
    StaffMembersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> role,
      Value<String> pin,
      Value<String> avatar,
      Value<int> rowid,
    });

class $$StaffMembersTableFilterComposer
    extends Composer<_$AppDatabase, $StaffMembersTable> {
  $$StaffMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pin => $composableBuilder(
    column: $table.pin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatar => $composableBuilder(
    column: $table.avatar,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StaffMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $StaffMembersTable> {
  $$StaffMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pin => $composableBuilder(
    column: $table.pin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatar => $composableBuilder(
    column: $table.avatar,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StaffMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $StaffMembersTable> {
  $$StaffMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get pin =>
      $composableBuilder(column: $table.pin, builder: (column) => column);

  GeneratedColumn<String> get avatar =>
      $composableBuilder(column: $table.avatar, builder: (column) => column);
}

class $$StaffMembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StaffMembersTable,
          StaffRow,
          $$StaffMembersTableFilterComposer,
          $$StaffMembersTableOrderingComposer,
          $$StaffMembersTableAnnotationComposer,
          $$StaffMembersTableCreateCompanionBuilder,
          $$StaffMembersTableUpdateCompanionBuilder,
          (
            StaffRow,
            BaseReferences<_$AppDatabase, $StaffMembersTable, StaffRow>,
          ),
          StaffRow,
          PrefetchHooks Function()
        > {
  $$StaffMembersTableTableManager(_$AppDatabase db, $StaffMembersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StaffMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StaffMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StaffMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> pin = const Value.absent(),
                Value<String> avatar = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StaffMembersCompanion(
                id: id,
                name: name,
                role: role,
                pin: pin,
                avatar: avatar,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String role,
                required String pin,
                Value<String> avatar = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StaffMembersCompanion.insert(
                id: id,
                name: name,
                role: role,
                pin: pin,
                avatar: avatar,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StaffMembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StaffMembersTable,
      StaffRow,
      $$StaffMembersTableFilterComposer,
      $$StaffMembersTableOrderingComposer,
      $$StaffMembersTableAnnotationComposer,
      $$StaffMembersTableCreateCompanionBuilder,
      $$StaffMembersTableUpdateCompanionBuilder,
      (StaffRow, BaseReferences<_$AppDatabase, $StaffMembersTable, StaffRow>),
      StaffRow,
      PrefetchHooks Function()
    >;
typedef $$RolePermsTableCreateCompanionBuilder =
    RolePermsCompanion Function({
      required String role,
      required String permission,
      Value<int> rowid,
    });
typedef $$RolePermsTableUpdateCompanionBuilder =
    RolePermsCompanion Function({
      Value<String> role,
      Value<String> permission,
      Value<int> rowid,
    });

class $$RolePermsTableFilterComposer
    extends Composer<_$AppDatabase, $RolePermsTable> {
  $$RolePermsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get permission => $composableBuilder(
    column: $table.permission,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RolePermsTableOrderingComposer
    extends Composer<_$AppDatabase, $RolePermsTable> {
  $$RolePermsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get permission => $composableBuilder(
    column: $table.permission,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RolePermsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RolePermsTable> {
  $$RolePermsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get permission => $composableBuilder(
    column: $table.permission,
    builder: (column) => column,
  );
}

class $$RolePermsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RolePermsTable,
          RolePermRow,
          $$RolePermsTableFilterComposer,
          $$RolePermsTableOrderingComposer,
          $$RolePermsTableAnnotationComposer,
          $$RolePermsTableCreateCompanionBuilder,
          $$RolePermsTableUpdateCompanionBuilder,
          (
            RolePermRow,
            BaseReferences<_$AppDatabase, $RolePermsTable, RolePermRow>,
          ),
          RolePermRow,
          PrefetchHooks Function()
        > {
  $$RolePermsTableTableManager(_$AppDatabase db, $RolePermsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RolePermsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RolePermsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RolePermsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> role = const Value.absent(),
                Value<String> permission = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RolePermsCompanion(
                role: role,
                permission: permission,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String role,
                required String permission,
                Value<int> rowid = const Value.absent(),
              }) => RolePermsCompanion.insert(
                role: role,
                permission: permission,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RolePermsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RolePermsTable,
      RolePermRow,
      $$RolePermsTableFilterComposer,
      $$RolePermsTableOrderingComposer,
      $$RolePermsTableAnnotationComposer,
      $$RolePermsTableCreateCompanionBuilder,
      $$RolePermsTableUpdateCompanionBuilder,
      (
        RolePermRow,
        BaseReferences<_$AppDatabase, $RolePermsTable, RolePermRow>,
      ),
      RolePermRow,
      PrefetchHooks Function()
    >;
typedef $$RestaurantTablesTableCreateCompanionBuilder =
    RestaurantTablesCompanion Function({
      required String id,
      required int number,
      required int capacity,
      Value<String> status,
      Value<int> rowid,
    });
typedef $$RestaurantTablesTableUpdateCompanionBuilder =
    RestaurantTablesCompanion Function({
      Value<String> id,
      Value<int> number,
      Value<int> capacity,
      Value<String> status,
      Value<int> rowid,
    });

class $$RestaurantTablesTableFilterComposer
    extends Composer<_$AppDatabase, $RestaurantTablesTable> {
  $$RestaurantTablesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get capacity => $composableBuilder(
    column: $table.capacity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RestaurantTablesTableOrderingComposer
    extends Composer<_$AppDatabase, $RestaurantTablesTable> {
  $$RestaurantTablesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get capacity => $composableBuilder(
    column: $table.capacity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RestaurantTablesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RestaurantTablesTable> {
  $$RestaurantTablesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<int> get capacity =>
      $composableBuilder(column: $table.capacity, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$RestaurantTablesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RestaurantTablesTable,
          RestaurantTableRow,
          $$RestaurantTablesTableFilterComposer,
          $$RestaurantTablesTableOrderingComposer,
          $$RestaurantTablesTableAnnotationComposer,
          $$RestaurantTablesTableCreateCompanionBuilder,
          $$RestaurantTablesTableUpdateCompanionBuilder,
          (
            RestaurantTableRow,
            BaseReferences<
              _$AppDatabase,
              $RestaurantTablesTable,
              RestaurantTableRow
            >,
          ),
          RestaurantTableRow,
          PrefetchHooks Function()
        > {
  $$RestaurantTablesTableTableManager(
    _$AppDatabase db,
    $RestaurantTablesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RestaurantTablesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RestaurantTablesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RestaurantTablesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> number = const Value.absent(),
                Value<int> capacity = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RestaurantTablesCompanion(
                id: id,
                number: number,
                capacity: capacity,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int number,
                required int capacity,
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RestaurantTablesCompanion.insert(
                id: id,
                number: number,
                capacity: capacity,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RestaurantTablesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RestaurantTablesTable,
      RestaurantTableRow,
      $$RestaurantTablesTableFilterComposer,
      $$RestaurantTablesTableOrderingComposer,
      $$RestaurantTablesTableAnnotationComposer,
      $$RestaurantTablesTableCreateCompanionBuilder,
      $$RestaurantTablesTableUpdateCompanionBuilder,
      (
        RestaurantTableRow,
        BaseReferences<
          _$AppDatabase,
          $RestaurantTablesTable,
          RestaurantTableRow
        >,
      ),
      RestaurantTableRow,
      PrefetchHooks Function()
    >;
typedef $$OrdersTableCreateCompanionBuilder =
    OrdersCompanion Function({
      required String id,
      required String orderNumber,
      required String orderType,
      required String staffName,
      Value<String> tableId,
      Value<int> tableNumber,
      required double subtotal,
      Value<double> discountAmount,
      Value<double> tax,
      Value<double> tip,
      required double total,
      required String method,
      Value<double> cashPaid,
      Value<double> cardPaid,
      Value<double> changeAmount,
      required int timestamp,
      Value<int> rowid,
    });
typedef $$OrdersTableUpdateCompanionBuilder =
    OrdersCompanion Function({
      Value<String> id,
      Value<String> orderNumber,
      Value<String> orderType,
      Value<String> staffName,
      Value<String> tableId,
      Value<int> tableNumber,
      Value<double> subtotal,
      Value<double> discountAmount,
      Value<double> tax,
      Value<double> tip,
      Value<double> total,
      Value<String> method,
      Value<double> cashPaid,
      Value<double> cardPaid,
      Value<double> changeAmount,
      Value<int> timestamp,
      Value<int> rowid,
    });

class $$OrdersTableFilterComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderNumber => $composableBuilder(
    column: $table.orderNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderType => $composableBuilder(
    column: $table.orderType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get staffName => $composableBuilder(
    column: $table.staffName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tableId => $composableBuilder(
    column: $table.tableId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tableNumber => $composableBuilder(
    column: $table.tableNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get tax => $composableBuilder(
    column: $table.tax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get tip => $composableBuilder(
    column: $table.tip,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cashPaid => $composableBuilder(
    column: $table.cashPaid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cardPaid => $composableBuilder(
    column: $table.cardPaid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get changeAmount => $composableBuilder(
    column: $table.changeAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OrdersTableOrderingComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderNumber => $composableBuilder(
    column: $table.orderNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderType => $composableBuilder(
    column: $table.orderType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get staffName => $composableBuilder(
    column: $table.staffName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tableId => $composableBuilder(
    column: $table.tableId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tableNumber => $composableBuilder(
    column: $table.tableNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get tax => $composableBuilder(
    column: $table.tax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get tip => $composableBuilder(
    column: $table.tip,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cashPaid => $composableBuilder(
    column: $table.cashPaid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cardPaid => $composableBuilder(
    column: $table.cardPaid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get changeAmount => $composableBuilder(
    column: $table.changeAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OrdersTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get orderNumber => $composableBuilder(
    column: $table.orderNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get orderType =>
      $composableBuilder(column: $table.orderType, builder: (column) => column);

  GeneratedColumn<String> get staffName =>
      $composableBuilder(column: $table.staffName, builder: (column) => column);

  GeneratedColumn<String> get tableId =>
      $composableBuilder(column: $table.tableId, builder: (column) => column);

  GeneratedColumn<int> get tableNumber => $composableBuilder(
    column: $table.tableNumber,
    builder: (column) => column,
  );

  GeneratedColumn<double> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<double> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get tax =>
      $composableBuilder(column: $table.tax, builder: (column) => column);

  GeneratedColumn<double> get tip =>
      $composableBuilder(column: $table.tip, builder: (column) => column);

  GeneratedColumn<double> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<double> get cashPaid =>
      $composableBuilder(column: $table.cashPaid, builder: (column) => column);

  GeneratedColumn<double> get cardPaid =>
      $composableBuilder(column: $table.cardPaid, builder: (column) => column);

  GeneratedColumn<double> get changeAmount => $composableBuilder(
    column: $table.changeAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);
}

class $$OrdersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OrdersTable,
          OrderRow,
          $$OrdersTableFilterComposer,
          $$OrdersTableOrderingComposer,
          $$OrdersTableAnnotationComposer,
          $$OrdersTableCreateCompanionBuilder,
          $$OrdersTableUpdateCompanionBuilder,
          (OrderRow, BaseReferences<_$AppDatabase, $OrdersTable, OrderRow>),
          OrderRow,
          PrefetchHooks Function()
        > {
  $$OrdersTableTableManager(_$AppDatabase db, $OrdersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrdersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> orderNumber = const Value.absent(),
                Value<String> orderType = const Value.absent(),
                Value<String> staffName = const Value.absent(),
                Value<String> tableId = const Value.absent(),
                Value<int> tableNumber = const Value.absent(),
                Value<double> subtotal = const Value.absent(),
                Value<double> discountAmount = const Value.absent(),
                Value<double> tax = const Value.absent(),
                Value<double> tip = const Value.absent(),
                Value<double> total = const Value.absent(),
                Value<String> method = const Value.absent(),
                Value<double> cashPaid = const Value.absent(),
                Value<double> cardPaid = const Value.absent(),
                Value<double> changeAmount = const Value.absent(),
                Value<int> timestamp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrdersCompanion(
                id: id,
                orderNumber: orderNumber,
                orderType: orderType,
                staffName: staffName,
                tableId: tableId,
                tableNumber: tableNumber,
                subtotal: subtotal,
                discountAmount: discountAmount,
                tax: tax,
                tip: tip,
                total: total,
                method: method,
                cashPaid: cashPaid,
                cardPaid: cardPaid,
                changeAmount: changeAmount,
                timestamp: timestamp,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String orderNumber,
                required String orderType,
                required String staffName,
                Value<String> tableId = const Value.absent(),
                Value<int> tableNumber = const Value.absent(),
                required double subtotal,
                Value<double> discountAmount = const Value.absent(),
                Value<double> tax = const Value.absent(),
                Value<double> tip = const Value.absent(),
                required double total,
                required String method,
                Value<double> cashPaid = const Value.absent(),
                Value<double> cardPaid = const Value.absent(),
                Value<double> changeAmount = const Value.absent(),
                required int timestamp,
                Value<int> rowid = const Value.absent(),
              }) => OrdersCompanion.insert(
                id: id,
                orderNumber: orderNumber,
                orderType: orderType,
                staffName: staffName,
                tableId: tableId,
                tableNumber: tableNumber,
                subtotal: subtotal,
                discountAmount: discountAmount,
                tax: tax,
                tip: tip,
                total: total,
                method: method,
                cashPaid: cashPaid,
                cardPaid: cardPaid,
                changeAmount: changeAmount,
                timestamp: timestamp,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OrdersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OrdersTable,
      OrderRow,
      $$OrdersTableFilterComposer,
      $$OrdersTableOrderingComposer,
      $$OrdersTableAnnotationComposer,
      $$OrdersTableCreateCompanionBuilder,
      $$OrdersTableUpdateCompanionBuilder,
      (OrderRow, BaseReferences<_$AppDatabase, $OrdersTable, OrderRow>),
      OrderRow,
      PrefetchHooks Function()
    >;
typedef $$OrderItemsTableCreateCompanionBuilder =
    OrderItemsCompanion Function({
      required String id,
      required String orderId,
      required String name,
      Value<String> emoji,
      required int quantity,
      required double unitPrice,
      Value<String> modifiersLabel,
      Value<int> rowid,
    });
typedef $$OrderItemsTableUpdateCompanionBuilder =
    OrderItemsCompanion Function({
      Value<String> id,
      Value<String> orderId,
      Value<String> name,
      Value<String> emoji,
      Value<int> quantity,
      Value<double> unitPrice,
      Value<String> modifiersLabel,
      Value<int> rowid,
    });

class $$OrderItemsTableFilterComposer
    extends Composer<_$AppDatabase, $OrderItemsTable> {
  $$OrderItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modifiersLabel => $composableBuilder(
    column: $table.modifiersLabel,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OrderItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $OrderItemsTable> {
  $$OrderItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modifiersLabel => $composableBuilder(
    column: $table.modifiersLabel,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OrderItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrderItemsTable> {
  $$OrderItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get orderId =>
      $composableBuilder(column: $table.orderId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<String> get modifiersLabel => $composableBuilder(
    column: $table.modifiersLabel,
    builder: (column) => column,
  );
}

class $$OrderItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OrderItemsTable,
          OrderItemRow,
          $$OrderItemsTableFilterComposer,
          $$OrderItemsTableOrderingComposer,
          $$OrderItemsTableAnnotationComposer,
          $$OrderItemsTableCreateCompanionBuilder,
          $$OrderItemsTableUpdateCompanionBuilder,
          (
            OrderItemRow,
            BaseReferences<_$AppDatabase, $OrderItemsTable, OrderItemRow>,
          ),
          OrderItemRow,
          PrefetchHooks Function()
        > {
  $$OrderItemsTableTableManager(_$AppDatabase db, $OrderItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrderItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrderItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrderItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> orderId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> emoji = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<double> unitPrice = const Value.absent(),
                Value<String> modifiersLabel = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrderItemsCompanion(
                id: id,
                orderId: orderId,
                name: name,
                emoji: emoji,
                quantity: quantity,
                unitPrice: unitPrice,
                modifiersLabel: modifiersLabel,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String orderId,
                required String name,
                Value<String> emoji = const Value.absent(),
                required int quantity,
                required double unitPrice,
                Value<String> modifiersLabel = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrderItemsCompanion.insert(
                id: id,
                orderId: orderId,
                name: name,
                emoji: emoji,
                quantity: quantity,
                unitPrice: unitPrice,
                modifiersLabel: modifiersLabel,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OrderItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OrderItemsTable,
      OrderItemRow,
      $$OrderItemsTableFilterComposer,
      $$OrderItemsTableOrderingComposer,
      $$OrderItemsTableAnnotationComposer,
      $$OrderItemsTableCreateCompanionBuilder,
      $$OrderItemsTableUpdateCompanionBuilder,
      (
        OrderItemRow,
        BaseReferences<_$AppDatabase, $OrderItemsTable, OrderItemRow>,
      ),
      OrderItemRow,
      PrefetchHooks Function()
    >;
typedef $$SettingsKvTableCreateCompanionBuilder =
    SettingsKvCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingsKvTableUpdateCompanionBuilder =
    SettingsKvCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingsKvTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsKvTable> {
  $$SettingsKvTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsKvTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsKvTable> {
  $$SettingsKvTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsKvTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsKvTable> {
  $$SettingsKvTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsKvTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsKvTable,
          SettingsKvRow,
          $$SettingsKvTableFilterComposer,
          $$SettingsKvTableOrderingComposer,
          $$SettingsKvTableAnnotationComposer,
          $$SettingsKvTableCreateCompanionBuilder,
          $$SettingsKvTableUpdateCompanionBuilder,
          (
            SettingsKvRow,
            BaseReferences<_$AppDatabase, $SettingsKvTable, SettingsKvRow>,
          ),
          SettingsKvRow,
          PrefetchHooks Function()
        > {
  $$SettingsKvTableTableManager(_$AppDatabase db, $SettingsKvTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsKvTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsKvTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsKvTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsKvCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingsKvCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsKvTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsKvTable,
      SettingsKvRow,
      $$SettingsKvTableFilterComposer,
      $$SettingsKvTableOrderingComposer,
      $$SettingsKvTableAnnotationComposer,
      $$SettingsKvTableCreateCompanionBuilder,
      $$SettingsKvTableUpdateCompanionBuilder,
      (
        SettingsKvRow,
        BaseReferences<_$AppDatabase, $SettingsKvTable, SettingsKvRow>,
      ),
      SettingsKvRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$MenuItemsTableTableManager get menuItems =>
      $$MenuItemsTableTableManager(_db, _db.menuItems);
  $$StaffMembersTableTableManager get staffMembers =>
      $$StaffMembersTableTableManager(_db, _db.staffMembers);
  $$RolePermsTableTableManager get rolePerms =>
      $$RolePermsTableTableManager(_db, _db.rolePerms);
  $$RestaurantTablesTableTableManager get restaurantTables =>
      $$RestaurantTablesTableTableManager(_db, _db.restaurantTables);
  $$OrdersTableTableManager get orders =>
      $$OrdersTableTableManager(_db, _db.orders);
  $$OrderItemsTableTableManager get orderItems =>
      $$OrderItemsTableTableManager(_db, _db.orderItems);
  $$SettingsKvTableTableManager get settingsKv =>
      $$SettingsKvTableTableManager(_db, _db.settingsKv);
}
