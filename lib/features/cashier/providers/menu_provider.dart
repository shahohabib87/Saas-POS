import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/features/cashier/models/category.dart';
import 'package:easycasher/features/cashier/models/menu_item.dart';
import 'package:easycasher/features/cashier/models/modifier.dart';

final categoriesProvider = Provider<List<Category>>(
  (ref) => const [
    Category(id: 'all', name: 'All Items', icon: Icons.grid_view_rounded),
    Category(id: 'burgers', name: 'Burgers', icon: Icons.lunch_dining),
    Category(id: 'pizza', name: 'Pizza', icon: Icons.local_pizza),
    Category(id: 'drinks', name: 'Drinks', icon: Icons.local_drink),
    Category(id: 'desserts', name: 'Desserts', icon: Icons.cake),
    Category(id: 'sides', name: 'Sides', icon: Icons.fastfood),
  ],
);

final menuItemsProvider = Provider<List<MenuItem>>(
  (ref) => const [
    // Burgers
    MenuItem(
      id: '1',
      categoryId: 'burgers',
      name: 'Classic Burger',
      price: 5.500,
      emoji: '🍔',
      modifierGroups: [
        ModifierGroup(name: 'Size', multiSelect: false, options: [
          ModifierOption(id: 'b_reg', name: 'Regular', price: 5.500),
          ModifierOption(id: 'b_lg', name: 'Large', price: 7.500),
        ]),
        ModifierGroup(name: 'Extras', multiSelect: true, options: [
          ModifierOption(id: 'cheese', name: 'Extra Cheese', price: 0.500),
          ModifierOption(id: 'bacon', name: 'Bacon', price: 1.000),
          ModifierOption(id: 'jalapeno', name: 'Jalapeños', price: 0.250),
          ModifierOption(id: 'sauce', name: 'Extra Sauce', price: 0.250),
        ]),
      ],
    ),
    MenuItem(
      id: '2',
      categoryId: 'burgers',
      name: 'Cheese Burger',
      price: 6.500,
      emoji: '🍔',
      modifierGroups: [
        ModifierGroup(name: 'Size', multiSelect: false, options: [
          ModifierOption(id: 'b_reg', name: 'Regular', price: 6.500),
          ModifierOption(id: 'b_lg', name: 'Large', price: 8.500),
        ]),
        ModifierGroup(name: 'Extras', multiSelect: true, options: [
          ModifierOption(id: 'cheese', name: 'Extra Cheese', price: 0.500),
          ModifierOption(id: 'bacon', name: 'Bacon', price: 1.000),
          ModifierOption(id: 'jalapeno', name: 'Jalapeños', price: 0.250),
          ModifierOption(id: 'sauce', name: 'Extra Sauce', price: 0.250),
        ]),
      ],
    ),
    MenuItem(id: '3', categoryId: 'burgers', name: 'Double Smash', price: 8.000, emoji: '🍔'),
    MenuItem(id: '4', categoryId: 'burgers', name: 'BBQ Bacon Burger', price: 9.500, emoji: '🍔'),
    // Pizza
    MenuItem(
      id: '5',
      categoryId: 'pizza',
      name: 'Margherita',
      price: 10.000,
      emoji: '🍕',
      modifierGroups: [
        ModifierGroup(name: 'Size', multiSelect: false, options: [
          ModifierOption(id: 'p_sm', name: 'Small', price: 8.000),
          ModifierOption(id: 'p_md', name: 'Medium', price: 10.000),
          ModifierOption(id: 'p_lg', name: 'Large', price: 13.000),
        ]),
        ModifierGroup(name: 'Toppings', multiSelect: true, options: [
          ModifierOption(id: 'xtra_cheese', name: 'Extra Cheese', price: 0.500),
          ModifierOption(id: 'mushrooms', name: 'Mushrooms', price: 0.500),
          ModifierOption(id: 'olives', name: 'Olives', price: 0.500),
          ModifierOption(id: 'peppers', name: 'Peppers', price: 0.500),
        ]),
      ],
    ),
    MenuItem(
      id: '6',
      categoryId: 'pizza',
      name: 'Pepperoni',
      price: 12.000,
      emoji: '🍕',
      modifierGroups: [
        ModifierGroup(name: 'Size', multiSelect: false, options: [
          ModifierOption(id: 'p_sm', name: 'Small', price: 10.000),
          ModifierOption(id: 'p_md', name: 'Medium', price: 12.000),
          ModifierOption(id: 'p_lg', name: 'Large', price: 15.000),
        ]),
        ModifierGroup(name: 'Toppings', multiSelect: true, options: [
          ModifierOption(id: 'xtra_cheese', name: 'Extra Cheese', price: 0.500),
          ModifierOption(id: 'mushrooms', name: 'Mushrooms', price: 0.500),
          ModifierOption(id: 'olives', name: 'Olives', price: 0.500),
          ModifierOption(id: 'peppers', name: 'Peppers', price: 0.500),
        ]),
      ],
    ),
    MenuItem(id: '7', categoryId: 'pizza', name: 'BBQ Chicken', price: 13.500, emoji: '🍕'),
    MenuItem(id: '8', categoryId: 'pizza', name: 'Four Cheese', price: 11.500, emoji: '🍕'),
    // Drinks
    MenuItem(id: '9', categoryId: 'drinks', name: 'Pepsi', price: 1.500, emoji: '🥤'),
    MenuItem(id: '10', categoryId: 'drinks', name: 'Fresh Orange Juice', price: 3.000, emoji: '🧃'),
    MenuItem(id: '11', categoryId: 'drinks', name: 'Mineral Water', price: 0.750, emoji: '💧'),
    MenuItem(id: '12', categoryId: 'drinks', name: 'Lemonade', price: 2.500, emoji: '🍋'),
    // Desserts
    MenuItem(id: '13', categoryId: 'desserts', name: 'Chocolate Cake', price: 4.000, emoji: '🎂'),
    MenuItem(id: '14', categoryId: 'desserts', name: 'Ice Cream', price: 2.500, emoji: '🍦'),
    MenuItem(id: '15', categoryId: 'desserts', name: 'Cheesecake', price: 4.500, emoji: '🍰'),
    // Sides
    MenuItem(id: '16', categoryId: 'sides', name: 'French Fries', price: 2.500, emoji: '🍟'),
    MenuItem(id: '17', categoryId: 'sides', name: 'Onion Rings', price: 3.000, emoji: '🧅'),
    MenuItem(id: '18', categoryId: 'sides', name: 'Coleslaw', price: 1.500, emoji: '🥗'),
  ],
);

final selectedCategoryProvider = StateProvider<String>((ref) => 'all');
final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredMenuItemsProvider = Provider<List<MenuItem>>((ref) {
  final items = ref.watch(menuItemsProvider);
  final selected = ref.watch(selectedCategoryProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();

  var filtered = selected == 'all'
      ? items
      : items.where((i) => i.categoryId == selected).toList();

  if (query.isNotEmpty) {
    filtered =
        filtered.where((i) => i.name.toLowerCase().contains(query)).toList();
  }

  return filtered;
});
