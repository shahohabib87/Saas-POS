import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/database/app_database.dart';
import 'package:easycasher/core/database/database_provider.dart';
import 'package:easycasher/features/cashier/models/category.dart';
import 'package:easycasher/features/cashier/models/menu_item.dart';

// ── Categories ────────────────────────────────────────────────────────────────

class CategoriesNotifier extends StateNotifier<List<Category>> {
  final AppDatabase _db;

  CategoriesNotifier(this._db) : super([]) {
    _load();
  }

  Future<void> _load() async {
    state = await _db.getCategories();
  }

  String _newId() => 'cat_${DateTime.now().millisecondsSinceEpoch}';

  void add(Category cat) {
    final newCat = cat.copyWith(id: _newId());
    state = [...state, newCat];
    _db.upsertCategory(newCat);
  }

  void update(Category cat) {
    state = [for (final c in state) c.id == cat.id ? cat : c];
    _db.upsertCategory(cat);
  }

  void remove(String id) {
    state = state.where((c) => c.id != id).toList();
    _db.deleteCategory(id);
  }
}

final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, List<Category>>((ref) {
  return CategoriesNotifier(ref.watch(appDatabaseProvider));
});

// ── Menu Items ────────────────────────────────────────────────────────────────

class MenuItemsNotifier extends StateNotifier<List<MenuItem>> {
  final AppDatabase _db;

  MenuItemsNotifier(this._db) : super([]) {
    _load();
  }

  Future<void> _load() async {
    state = await _db.getMenuItems();
  }

  String _newId() => 'item_${DateTime.now().millisecondsSinceEpoch}';

  void add(MenuItem item) {
    final newItem = item.copyWith(id: _newId());
    state = [...state, newItem];
    _db.upsertMenuItem(newItem);
  }

  void update(MenuItem item) {
    state = [for (final m in state) m.id == item.id ? item : m];
    _db.upsertMenuItem(item);
  }

  void remove(String id) {
    state = state.where((m) => m.id != id).toList();
    _db.deleteMenuItem(id);
  }
}

final menuItemsProvider =
    StateNotifierProvider<MenuItemsNotifier, List<MenuItem>>((ref) {
  return MenuItemsNotifier(ref.watch(appDatabaseProvider));
});

// ── Filters ───────────────────────────────────────────────────────────────────

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
