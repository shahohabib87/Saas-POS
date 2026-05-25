import 'package:easycasher/features/cashier/models/modifier.dart';

class MenuItem {
  final String id;
  final String categoryId;
  final String name;
  final double price;
  final String emoji;
  final List<ModifierGroup> modifierGroups;

  const MenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.price,
    this.emoji = '🍽️',
    this.modifierGroups = const [],
  });

  bool get hasModifiers => modifierGroups.isNotEmpty;

  MenuItem copyWith({
    String? id,
    String? categoryId,
    String? name,
    double? price,
    String? emoji,
    List<ModifierGroup>? modifierGroups,
  }) =>
      MenuItem(
        id: id ?? this.id,
        categoryId: categoryId ?? this.categoryId,
        name: name ?? this.name,
        price: price ?? this.price,
        emoji: emoji ?? this.emoji,
        modifierGroups: modifierGroups ?? this.modifierGroups,
      );
}
