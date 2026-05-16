import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/constants/app_colors.dart';
import 'package:easycasher/features/cashier/models/cart_item.dart';
import 'package:easycasher/features/cashier/providers/cashier_provider.dart';

const _kCategoryColors = <String, Color>{
  'burgers': Color(0xFFFFF3E0),
  'pizza': Color(0xFFFFEBEE),
  'drinks': Color(0xFFE3F2FD),
  'desserts': Color(0xFFFCE4EC),
  'sides': Color(0xFFE8F5E9),
};

class CartItemTile extends ConsumerWidget {
  final int index;
  final CartItem cartItem;

  const CartItemTile({super.key, required this.index, required this.cartItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.read(cartProvider.notifier);
    final bgColor =
        _kCategoryColors[cartItem.item.categoryId] ?? const Color(0xFFF3F0FF);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(cartItem.item.emoji,
                  style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 10),
          // Info + qty controls
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cartItem.item.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                if (cartItem.modifierSummary.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      cartItem.modifierSummary,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.outline),
                    ),
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _QtyButton(
                      icon: Icons.remove_rounded,
                      onTap: () => cart.decrement(index),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${cartItem.quantity}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _QtyButton(
                      icon: Icons.add_rounded,
                      onTap: () => cart.increment(index),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Price + remove
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => cart.removeAt(index),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 12, color: AppColors.outline),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'IQD ${cartItem.subtotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.primaryFixed,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: AppColors.primary),
      ),
    );
  }
}
