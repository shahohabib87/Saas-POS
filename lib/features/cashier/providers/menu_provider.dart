import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/features/cashier/models/category.dart';
import 'package:easycasher/features/cashier/models/menu_item.dart';
import 'package:easycasher/features/cashier/models/modifier.dart';

// ── Categories ───────────────────────────────────────────────────────────────

class CategoriesNotifier extends StateNotifier<List<Category>> {
  CategoriesNotifier() : super(_initial);

  static const _initial = <Category>[
    Category(id: 'all',      name: 'All Items', emoji: '🍽️'),
    Category(id: 'burgers',  name: 'Burgers',   emoji: '🍔'),
    Category(id: 'pizza',    name: 'Pizza',     emoji: '🍕'),
    Category(id: 'drinks',   name: 'Drinks',    emoji: '🥤'),
    Category(id: 'desserts', name: 'Desserts',  emoji: '🍰'),
    Category(id: 'sides',    name: 'Sides',     emoji: '🍟'),
  ];

  int _nextId = 100;
  String _newId() => 'cat_${_nextId++}';

  void add(Category cat) => state = [...state, cat.copyWith(id: _newId())];

  void update(Category cat) =>
      state = [for (final c in state) c.id == cat.id ? cat : c];

  void remove(String id) {
    state = state.where((c) => c.id != id).toList();
  }
}

final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, List<Category>>(
        (_) => CategoriesNotifier());

// ── Menu items ───────────────────────────────────────────────────────────────

class MenuItemsNotifier extends StateNotifier<List<MenuItem>> {
  MenuItemsNotifier() : super(_initial);

  static final _initial = <MenuItem>[
    // Burgers
    MenuItem(
      id: '1',
      categoryId: 'burgers',
      name: 'Classic Burger',
      price: 5500,
      emoji: '🍔',
      modifierGroups: [
        ModifierGroup(name: 'Size', multiSelect: false, options: [
          const ModifierOption(id: 'b_reg', name: 'Regular', price: 5500),
          const ModifierOption(id: 'b_lg',  name: 'Large',   price: 7500),
        ]),
        ModifierGroup(name: 'Extras', multiSelect: true, options: [
          const ModifierOption(id: 'cheese',   name: 'Extra Cheese', price: 500),
          const ModifierOption(id: 'bacon',    name: 'Bacon',        price: 1000),
          const ModifierOption(id: 'jalapeno', name: 'Jalapeños',    price: 250),
          const ModifierOption(id: 'sauce',    name: 'Extra Sauce',  price: 250),
        ]),
      ],
    ),
    MenuItem(
      id: '2',
      categoryId: 'burgers',
      name: 'Cheese Burger',
      price: 6500,
      emoji: '🍔',
      modifierGroups: [
        ModifierGroup(name: 'Size', multiSelect: false, options: [
          const ModifierOption(id: 'b_reg', name: 'Regular', price: 6500),
          const ModifierOption(id: 'b_lg',  name: 'Large',   price: 8500),
        ]),
        ModifierGroup(name: 'Extras', multiSelect: true, options: [
          const ModifierOption(id: 'cheese',   name: 'Extra Cheese', price: 500),
          const ModifierOption(id: 'bacon',    name: 'Bacon',        price: 1000),
          const ModifierOption(id: 'jalapeno', name: 'Jalapeños',    price: 250),
          const ModifierOption(id: 'sauce',    name: 'Extra Sauce',  price: 250),
        ]),
      ],
    ),
    MenuItem(id: '3',  categoryId: 'burgers',  name: 'Double Smash',      price: 8000,  emoji: '🍔'),
    MenuItem(id: '4',  categoryId: 'burgers',  name: 'BBQ Bacon Burger',   price: 9500,  emoji: '🍔'),
    // Pizza
    MenuItem(
      id: '5',
      categoryId: 'pizza',
      name: 'Margherita',
      price: 10000,
      emoji: '🍕',
      modifierGroups: [
        ModifierGroup(name: 'Size', multiSelect: false, options: [
          const ModifierOption(id: 'p_sm', name: 'Small',  price: 8000),
          const ModifierOption(id: 'p_md', name: 'Medium', price: 10000),
          const ModifierOption(id: 'p_lg', name: 'Large',  price: 13000),
        ]),
        ModifierGroup(name: 'Toppings', multiSelect: true, options: [
          const ModifierOption(id: 'xtra_cheese', name: 'Extra Cheese', price: 500),
          const ModifierOption(id: 'mushrooms',   name: 'Mushrooms',    price: 500),
          const ModifierOption(id: 'olives',      name: 'Olives',       price: 500),
          const ModifierOption(id: 'peppers',     name: 'Peppers',      price: 500),
        ]),
      ],
    ),
    MenuItem(
      id: '6',
      categoryId: 'pizza',
      name: 'Pepperoni',
      price: 12000,
      emoji: '🍕',
      modifierGroups: [
        ModifierGroup(name: 'Size', multiSelect: false, options: [
          const ModifierOption(id: 'p_sm', name: 'Small',  price: 10000),
          const ModifierOption(id: 'p_md', name: 'Medium', price: 12000),
          const ModifierOption(id: 'p_lg', name: 'Large',  price: 15000),
        ]),
        ModifierGroup(name: 'Toppings', multiSelect: true, options: [
          const ModifierOption(id: 'xtra_cheese', name: 'Extra Cheese', price: 500),
          const ModifierOption(id: 'mushrooms',   name: 'Mushrooms',    price: 500),
          const ModifierOption(id: 'olives',      name: 'Olives',       price: 500),
          const ModifierOption(id: 'peppers',     name: 'Peppers',      price: 500),
        ]),
      ],
    ),
    MenuItem(id: '7',  categoryId: 'pizza',    name: 'BBQ Chicken',        price: 13500, emoji: '🍕'),
    MenuItem(id: '8',  categoryId: 'pizza',    name: 'Four Cheese',        price: 11500, emoji: '🍕'),
    // Drinks
    MenuItem(id: '9',  categoryId: 'drinks',   name: 'Pepsi',              price: 1500,  emoji: '🥤'),
    MenuItem(id: '10', categoryId: 'drinks',   name: 'Fresh Orange Juice', price: 3000,  emoji: '🧃'),
    MenuItem(id: '11', categoryId: 'drinks',   name: 'Mineral Water',      price: 1000,  emoji: '💧'),
    MenuItem(id: '12', categoryId: 'drinks',   name: 'Lemonade',           price: 2500,  emoji: '🍋'),
    // Desserts
    MenuItem(id: '13', categoryId: 'desserts', name: 'Chocolate Cake',     price: 4000,  emoji: '🎂'),
    MenuItem(id: '14', categoryId: 'desserts', name: 'Ice Cream',          price: 2500,  emoji: '🍦'),
    MenuItem(id: '15', categoryId: 'desserts', name: 'Cheesecake',         price: 4500,  emoji: '🍰'),
    // Sides
    MenuItem(id: '16', categoryId: 'sides',    name: 'French Fries',       price: 2500,  emoji: '🍟'),
    MenuItem(id: '17', categoryId: 'sides',    name: 'Onion Rings',        price: 3000,  emoji: '🧅'),
    MenuItem(id: '18', categoryId: 'sides',    name: 'Coleslaw',           price: 1500,  emoji: '🥗'),
  ];

  int _nextId = 100;
  String _newId() => 'item_${_nextId++}';

  void add(MenuItem item) => state = [...state, item.copyWith(id: _newId())];

  void update(MenuItem item) =>
      state = [for (final m in state) m.id == item.id ? item : m];

  void remove(String id) {
    state = state.where((m) => m.id != id).toList();
  }
}

final menuItemsProvider =
    StateNotifierProvider<MenuItemsNotifier, List<MenuItem>>(
        (_) => MenuItemsNotifier());

// ── Filters ──────────────────────────────────────────────────────────────────

final selectedCategoryProvider = StateProvider<String>((ref) => 'all');
final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredMenuItemsProvider = Provider<List<MenuItem>>((ref) {
  final items    = ref.watch(menuItemsProvider);
  final selected = ref.watch(selectedCategoryProvider);
  final query    = ref.watch(searchQueryProvider).toLowerCase().trim();

  var filtered = selected == 'all'
      ? items
      : items.where((i) => i.categoryId == selected).toList();

  if (query.isNotEmpty) {
    filtered = filtered.where((i) => i.name.toLowerCase().contains(query)).toList();
  }

  return filtered;
});
