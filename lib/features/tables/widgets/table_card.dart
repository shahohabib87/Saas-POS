import 'package:flutter/material.dart';
import 'package:easycasher/core/constants/app_colors.dart';
import 'package:easycasher/features/tables/models/restaurant_table.dart';

enum TableKotStatus { none, active, ready }

class TableCard extends StatelessWidget {
  final RestaurantTable table;
  final bool hasSavedOrder;
  final TableKotStatus kotStatus;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const TableCard({
    super.key,
    required this.table,
    required this.hasSavedOrder,
    this.kotStatus = TableKotStatus.none,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isReserved = table.status == TableStatus.reserved;
    final color = switch (table.status) {
      TableStatus.available => AppColors.success,
      TableStatus.occupied => AppColors.warning,
      TableStatus.reserved => AppColors.outline,
    };

    return GestureDetector(
      onTap: isReserved ? null : onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.table_restaurant_rounded,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Table ${table.number}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isReserved
                          ? AppColors.outline
                          : AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    switch (table.status) {
                      TableStatus.available =>
                        '${table.capacity} seats',
                      TableStatus.occupied => 'Occupied',
                      TableStatus.reserved => 'Reserved',
                    },
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            if (kotStatus == TableKotStatus.ready)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'READY',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            else if (kotStatus == TableKotStatus.active || hasSavedOrder)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
