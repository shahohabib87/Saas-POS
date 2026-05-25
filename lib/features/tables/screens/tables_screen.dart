import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/constants/app_colors.dart';
import 'package:easycasher/features/tables/models/restaurant_table.dart';
import 'package:easycasher/features/tables/providers/tables_provider.dart';
import 'package:easycasher/features/tables/widgets/table_card.dart';
import 'package:easycasher/features/kitchen/models/kitchen_order.dart';
import 'package:easycasher/features/cashier/providers/cashier_provider.dart';
import 'package:easycasher/features/kitchen/providers/kitchen_provider.dart';

class TablesScreen extends ConsumerStatefulWidget {
  const TablesScreen({super.key});

  @override
  ConsumerState<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends ConsumerState<TablesScreen> {
  @override
  Widget build(BuildContext context) {
    final tables      = ref.watch(tablesProvider);
    final savedOrders = ref.watch(savedTableOrdersProvider);
    final allKots     = ref.watch(kitchenProvider);

    final available = tables.where((t) => t.status == TableStatus.available).length;
    final occupied  = tables.where((t) => t.status == TableStatus.occupied).length;
    final reserved  = tables.where((t) => t.status == TableStatus.reserved).length;

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
                _StatChip(label: 'Available', count: available, color: AppColors.success),
                const SizedBox(width: 10),
                _StatChip(label: 'Occupied',  count: occupied,  color: AppColors.warning),
                const SizedBox(width: 10),
                _StatChip(label: 'Reserved',  count: reserved,  color: AppColors.outline),
                const Spacer(),
                Text(
                  '${tables.length} tables total',
                  style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
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
                final tableKots = allKots.where((o) => o.tableId == table.id).toList();
                final kotStatus = tableKots.isEmpty
                    ? TableKotStatus.none
                    : tableKots.every((o) => o.status == KotStatus.ready)
                        ? TableKotStatus.ready
                        : TableKotStatus.active;
                final hasSavedOrder = savedOrders[table.id]?.isNotEmpty ?? false;
                return TableCard(
                  table: table,
                  hasSavedOrder: hasSavedOrder,
                  kotStatus: kotStatus,
                  onTap: () => _openTable(table),
                  onLongPress: () => _showTableOptions(table),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openTable(RestaurantTable table) {
    final savedOrders = ref.read(savedTableOrdersProvider);
    final savedNotes  = ref.read(savedTableNotesProvider);

    final freshTable = ref.read(tablesProvider)
        .firstWhere((t) => t.id == table.id, orElse: () => table);

    ref.read(cartProvider.notifier).loadItems(savedOrders[table.id] ?? []);
    ref.read(orderNoteProvider.notifier).state   = savedNotes[table.id] ?? '';
    ref.read(tableNumberProvider.notifier).state = table.number.toString();
    ref.read(activeTableProvider.notifier).state = freshTable;

    if (freshTable.status == TableStatus.available) {
      ref.read(orderCounterProvider.notifier).bump();
      ref.read(tablesProvider.notifier).setStatus(table.id, TableStatus.occupied);
    }
  }

  void _showTableOptions(RestaurantTable table) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _TableOptionsSheet(table: table, ref: ref),
    );
  }
}

// ── Table options sheet (long press) ─────────────────────────────────────────

class _TableOptionsSheet extends StatelessWidget {
  final RestaurantTable table;
  final WidgetRef ref;
  const _TableOptionsSheet({required this.table, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isReserved  = table.status == TableStatus.reserved;
    final isAvailable = table.status == TableStatus.available;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Table ${table.number}',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              '${table.capacity} seats  •  ${table.status.name}',
              style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.outlineVariant),
            if (isAvailable)
              _OptionTile(
                icon: Icons.event_seat_rounded,
                label: 'Mark as Reserved',
                color: AppColors.outline,
                onTap: () {
                  ref.read(tablesProvider.notifier).setStatus(table.id, TableStatus.reserved);
                  Navigator.pop(context);
                },
              ),
            if (isReserved)
              _OptionTile(
                icon: Icons.check_circle_outline_rounded,
                label: 'Mark as Available',
                color: AppColors.success,
                onTap: () {
                  ref.read(tablesProvider.notifier).setStatus(table.id, TableStatus.available);
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _OptionTile(
      {required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label,
          style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w500)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      onTap: onTap,
    );
  }
}

// ── Stat chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatChip({required this.label, required this.count, required this.color});

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
          Text('$count',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}
