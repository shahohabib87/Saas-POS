import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/features/cashier/providers/cashier_provider.dart';
import 'package:easycasher/features/cashier/widgets/menu_item_card.dart';

class MenuGrid extends ConsumerWidget {
  const MenuGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(filteredMenuItemsProvider);

    if (items.isEmpty) {
      return const Center(
        child: Text('No items in this category.'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 170,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => MenuItemCard(item: items[i]),
    );
  }
}
