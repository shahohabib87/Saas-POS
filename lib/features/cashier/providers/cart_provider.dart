import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/features/settings/providers/settings_provider.dart';
import 'package:easycasher/features/cashier/models/cart_item.dart';
import 'package:easycasher/features/cashier/models/modifier.dart';

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(CartItem newItem) {
    final idx = state.indexWhere((ci) =>
        ci.item.id == newItem.item.id &&
        ci.selectedVariation?.id == newItem.selectedVariation?.id &&
        _toppingsMatch(ci.selectedToppings, newItem.selectedToppings));
    if (idx >= 0) {
      final copy = [...state];
      copy[idx] = copy[idx].copyWith(quantity: copy[idx].quantity + 1);
      state = copy;
    } else {
      state = [...state, newItem];
    }
  }

  void increment(int index) {
    final copy = [...state];
    copy[index] = copy[index].copyWith(quantity: copy[index].quantity + 1);
    state = copy;
  }

  void decrement(int index) {
    if (state[index].quantity <= 1) {
      removeAt(index);
    } else {
      final copy = [...state];
      copy[index] = copy[index].copyWith(quantity: copy[index].quantity - 1);
      state = copy;
    }
  }

  void removeAt(int index) {
    final copy = [...state];
    copy.removeAt(index);
    state = copy;
  }

  void clear() => state = [];

  void loadItems(List<CartItem> items) => state = List.from(items);

  bool _toppingsMatch(List<ModifierOption> a, List<ModifierOption> b) {
    if (a.length != b.length) return false;
    final aIds = a.map((t) => t.id).toSet();
    final bIds = b.map((t) => t.id).toSet();
    return aIds.containsAll(bIds) && bIds.containsAll(aIds);
  }
}

final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartItem>>((ref) => CartNotifier());

final savedTableOrdersProvider =
    StateProvider<Map<String, List<CartItem>>>((ref) => const {});

final savedTableNotesProvider =
    StateProvider<Map<String, String>>((ref) => const {});

final subtotalProvider = Provider<double>(
    (ref) => ref.watch(cartProvider).fold(0.0, (s, ci) => s + ci.subtotal));

final taxProvider = Provider<double>(
    (ref) => ref.watch(subtotalProvider) * ref.watch(taxMultiplierProvider));

final totalProvider = Provider<double>(
    (ref) => ref.watch(subtotalProvider) + ref.watch(taxProvider));

final cartCountProvider = Provider<int>(
    (ref) => ref.watch(cartProvider).fold(0, (s, ci) => s + ci.quantity));
