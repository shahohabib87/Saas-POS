import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/constants/app_colors.dart';
import 'package:easycasher/features/tables/models/restaurant_table.dart';
import 'package:easycasher/features/tables/providers/tables_provider.dart';
import 'package:easycasher/features/tables/widgets/table_card.dart';
import 'package:easycasher/features/kitchen/models/kitchen_order.dart';
import 'package:easycasher/features/cashier/providers/cashier_provider.dart';
import 'package:easycasher/features/kitchen/providers/kitchen_provider.dart';

class TablesScreen extends ConsumerWidget {
  const TablesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tables = ref.watch(tablesProvider);
    final savedOrders = ref.watch(savedTableOrdersProvider);
    final allKots = ref.watch(kitchenProvider);

    final available =
        tables.where((t) => t.status == TableStatus.available).length;
    final occupied =
        tables.where((t) => t.status == TableStatus.occupied).length;
    final reserved =
        tables.where((t) => t.status == TableStatus.reserved).length;

    return Container(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            color: AppColors.surface,
            child: Row(
              children: [
                _StatChip(
                  label: 'Available',
                  count: available,
                  color: AppColors.success,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  label: 'Occupied',
                  count: occupied,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  label: 'Reserved',
                  count: reserved,
                  color: AppColors.outline,
                ),
                const Spacer(),
                Text(
                  '${tables.length} tables total',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.outlineVariant),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 155,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: tables.length,
              itemBuilder: (_, i) {
                final table = tables[i];
                final tableKots = allKots
                    .where((o) => o.tableId == table.id)
                    .toList();
                final kotStatus = tableKots.isEmpty
                    ? TableKotStatus.none
                    : tableKots.every((o) => o.status == KotStatus.ready)
                        ? TableKotStatus.ready
                        : TableKotStatus.active;
                final hasSavedOrder =
                    savedOrders[table.id]?.isNotEmpty ?? false;
                return TableCard(
                  table: table,
                  hasSavedOrder: hasSavedOrder,
                  kotStatus: kotStatus,
                  onTap: () => _openTable(ref, table),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openTable(WidgetRef ref, RestaurantTable table) {
    final savedOrders = ref.read(savedTableOrdersProvider);
    final savedNotes = ref.read(savedTableNotesProvider);

    ref.read(cartProvider.notifier).loadItems(savedOrders[table.id] ?? []);
    ref.read(orderNoteProvider.notifier).state = savedNotes[table.id] ?? '';
    ref.read(tableNumberProvider.notifier).state = table.number.toString();
    ref.read(activeTableProvider.notifier).state = table;

    if (table.status == TableStatus.available) {
      ref
          .read(tablesProvider.notifier)
          .setStatus(table.id, TableStatus.occupied);
    }
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }
}
