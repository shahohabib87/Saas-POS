import 'package:flutter/material.dart';
import 'package:easycasher/core/constants/app_colors.dart';
import 'package:easycasher/features/auth/models/staff.dart';

class StaffCard extends StatelessWidget {
  final Staff staff;
  final bool isSelected;
  final VoidCallback onTap;

  const StaffCard({
    super.key,
    required this.staff,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final roleColor = switch (staff.role) {
      StaffRole.admin   => const Color(0xFFDC2626),
      StaffRole.manager => AppColors.primary,
      StaffRole.cashier => AppColors.success,
      StaffRole.waiter  => AppColors.warning,
      StaffRole.kitchen => AppColors.danger,
    };

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? roleColor.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? roleColor : AppColors.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(staff.avatar, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(
              staff.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? roleColor : AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                staff.role.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: roleColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
