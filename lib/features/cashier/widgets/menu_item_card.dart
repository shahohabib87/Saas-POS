import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/constants/app_colors.dart';
import 'package:easycasher/features/cashier/models/cart_item.dart';
import 'package:easycasher/features/cashier/models/menu_item.dart';
import 'package:easycasher/features/cashier/providers/cashier_provider.dart';
import 'package:easycasher/features/cashier/widgets/modifier_dialog.dart';

const _kCategoryColors = <String, Color>{
  'burgers': Color(0xFFFFF3E0),
  'pizza': Color(0xFFFFEBEE),
  'drinks': Color(0xFFE3F2FD),
  'desserts': Color(0xFFFCE4EC),
  'sides': Color(0xFFE8F5E9),
};

class MenuItemCard extends ConsumerWidget {
  final MenuItem item;

  const MenuItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bgColor =
        _kCategoryColors[item.categoryId] ?? const Color(0xFFF3F0FF);

    return GestureDetector(
      onTap: () => _handleTap(context, ref),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                      ),
                    ),
                    child: Center(
                      child: Text(item.emoji,
                          style: const TextStyle(fontSize: 40)),
                    ),
                  ),
                  // In Stock badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'In Stock',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  // Options badge
                  if (item.hasModifiers)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryFixed,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'options',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info area
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                        height: 1.3,
                      ),
                    ),
                    Text(
                      'IQD ${item.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref) {
    if (item.hasModifiers) {
      showDialog(
        context: context,
        builder: (_) => ModifierDialog(
          item: item,
          onAdd: (cartItem) =>
              ref.read(cartProvider.notifier).addItem(cartItem),
        ),
      );
    } else {
      ref.read(cartProvider.notifier).addItem(
            CartItem(item: item, quantity: 1),
          );
    }
  }
}
