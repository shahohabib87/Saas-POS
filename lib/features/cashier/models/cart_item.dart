import 'package:easycasher/features/cashier/models/menu_item.dart';
import 'package:easycasher/features/cashier/models/modifier.dart';

class CartItem {
  final MenuItem item;
  final int quantity;
  final ModifierOption? selectedVariation;
  final List<ModifierOption> selectedToppings;
  final String? note;

  const CartItem({
    required this.item,
    required this.quantity,
    this.selectedVariation,
    this.selectedToppings = const [],
    this.note,
  });

  double get unitPrice {
    final base = selectedVariation?.price ?? item.price;
    final toppingsTotal =
        selectedToppings.fold(0.0, (s, t) => s + t.price);
    return base + toppingsTotal;
  }

  double get subtotal => unitPrice * quantity;

  String get modifierSummary {
    final parts = <String>[];
    if (selectedVariation != null) parts.add(selectedVariation!.name);
    for (final t in selectedToppings) {
      parts.add(t.name);
    }
    return parts.join(' · ');
  }

  CartItem copyWith({
    int? quantity,
    ModifierOption? selectedVariation,
    List<ModifierOption>? selectedToppings,
    String? note,
  }) =>
      CartItem(
        item: item,
        quantity: quantity ?? this.quantity,
        selectedVariation: selectedVariation ?? this.selectedVariation,
        selectedToppings: selectedToppings ?? this.selectedToppings,
        note: note ?? this.note,
      );
}
