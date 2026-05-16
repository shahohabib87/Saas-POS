import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/constants/app_colors.dart';
import 'package:easycasher/features/cashier/providers/cashier_provider.dart';

class CategoryTabBar extends ConsumerWidget {
  const CategoryTabBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final selected = ref.watch(selectedCategoryProvider);

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final isSelected = cat.id == selected;
          return GestureDetector(
            onTap: () =>
                ref.read(selectedCategoryProvider.notifier).state = cat.id,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.outlineVariant,
                ),
              ),
              child: Text(
                cat.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
