import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/constants/app_colors.dart';
import 'package:easycasher/features/kitchen/models/kitchen_order.dart';
import 'package:easycasher/features/kitchen/providers/kitchen_provider.dart';
import 'package:easycasher/features/tables/models/restaurant_table.dart';
import 'package:easycasher/features/tables/providers/tables_provider.dart';
import 'package:easycasher/features/cashier/providers/cashier_provider.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allKots = ref.watch(kitchenProvider);
    final tables = ref.watch(tablesProvider);
    final savedOrders = ref.watch(savedTableOrdersProvider);

    // Build one entry per table that has KOTs or unsent cart items
    final activeTableIds = {
      ...allKots.map((o) => o.tableId),
      ...savedOrders.entries
          .where((e) => e.value.isNotEmpty)
          .map((e) => e.key),
    };

    final activeEntries = activeTableIds.map((tableId) {
      final table = tables.firstWhere(
        (t) => t.id == tableId,
        orElse: () => RestaurantTable(
          id: tableId,
          number: 0,
          capacity: 0,
          status: TableStatus.occupied,
        ),
      );
      final kots = allKots.where((o) => o.tableId == tableId).toList();
      final cartItems = savedOrders[tableId] ?? [];
      final cartTotal = cartItems.fold(0.0, (s, i) => s + i.unitPrice * i.quantity);
      final kotTotal = kots.fold(0.0, (s, o) => s + o.total);
      final total = kotTotal + cartTotal;
      final itemCount = kots.fold(0, (s, o) => s + o.items.length) + cartItems.length;

      // Overall status
      final overallStatus = kots.isEmpty
          ? _OrderStatus.unsent
          : kots.every((o) => o.status == KotStatus.ready)
              ? _OrderStatus.ready
              : kots.any((o) => o.status == KotStatus.inProgress)
                  ? _OrderStatus.preparing
                  : _OrderStatus.active;

      return _OrderEntry(
        table: table,
        kots: kots,
        itemCount: itemCount,
        total: total,
        status: overallStatus,
        hasUnsent: cartItems.isNotEmpty,
      );
    }).toList()
      ..sort((a, b) => a.table.number.compareTo(b.table.number));

    return Container(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OrdersHeader(count: activeEntries.length),
          Container(height: 1, color: AppColors.outlineVariant),
          Expanded(
            child: activeEntries.isEmpty
                ? const _EmptyOrders()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: activeEntries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _OrderCard(
                      entry: activeEntries[i],
                      onOpen: () => _openTable(ref, activeEntries[i].table),
                    ),
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
    ref.read(appViewProvider.notifier).state = AppView.pos;
  }
}

enum _OrderStatus { unsent, active, preparing, ready }

class _OrderEntry {
  final RestaurantTable table;
  final List<KitchenOrder> kots;
  final int itemCount;
  final double total;
  final _OrderStatus status;
  final bool hasUnsent;

  const _OrderEntry({
    required this.table,
    required this.kots,
    required this.itemCount,
    required this.total,
    required this.status,
    required this.hasUnsent,
  });
}

class _OrdersHeader extends StatelessWidget {
  final int count;
  const _OrdersHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: AppColors.surface,
      child: Row(
        children: [
          const Text(
            'Active Orders',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count orders',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final _OrderEntry entry;
  final VoidCallback onOpen;

  const _OrderCard({required this.entry, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final status = entry.status;

    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;

    switch (status) {
      case _OrderStatus.ready:
        statusColor = AppColors.success;
        statusLabel = 'Food Ready';
        statusIcon = Icons.check_circle_rounded;
      case _OrderStatus.preparing:
        statusColor = AppColors.primary;
        statusLabel = 'Preparing';
        statusIcon = Icons.restaurant_rounded;
      case _OrderStatus.active:
        statusColor = AppColors.warning;
        statusLabel = 'In Queue';
        statusIcon = Icons.hourglass_top_rounded;
      case _OrderStatus.unsent:
        statusColor = AppColors.onSurfaceVariant;
        statusLabel = 'Not Sent';
        statusIcon = Icons.edit_note_rounded;
    }

    return GestureDetector(
      onTap: onOpen,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: status == _OrderStatus.ready
                ? AppColors.success.withValues(alpha: 0.4)
                : AppColors.outlineVariant,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Table icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.table_restaurant_rounded,
                color: statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            // Table info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Table ${entry.table.number}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${entry.itemCount} items',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      if (entry.kots.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        const Text('·',
                            style: TextStyle(
                                color: AppColors.onSurfaceVariant)),
                        const SizedBox(width: 6),
                        Text(
                          '${entry.kots.length} KOT${entry.kots.length > 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (entry.hasUnsent) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'unsent',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Status + total
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'IQD ${entry.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined,
              color: AppColors.outlineVariant, size: 56),
          SizedBox(height: 16),
          Text(
            'No active orders',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Orders will appear here once tables are opened',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.outline,
            ),
          ),
        ],
      ),
    );
  }
}
