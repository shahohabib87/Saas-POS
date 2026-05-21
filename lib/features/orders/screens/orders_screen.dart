import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/constants/app_colors.dart';
import 'package:easycasher/features/kitchen/models/kitchen_order.dart';
import 'package:easycasher/features/kitchen/providers/kitchen_provider.dart';
import 'package:easycasher/features/tables/models/restaurant_table.dart';
import 'package:easycasher/features/tables/providers/tables_provider.dart';
import 'package:easycasher/features/cashier/providers/cashier_provider.dart';

enum _OrderStatus { ready, preparing, active, unsent }

enum _OrderType { all, dineIn, takeout, delivery, deliveryApp }

extension _OrderTypeX on _OrderType {
  String get label => switch (this) {
    _OrderType.all         => 'All',
    _OrderType.dineIn      => 'Dine-In',
    _OrderType.takeout     => 'Takeout',
    _OrderType.delivery    => 'Delivery',
    _OrderType.deliveryApp => 'Delivery App',
  };
  IconData get icon => switch (this) {
    _OrderType.all         => Icons.list_alt_rounded,
    _OrderType.dineIn      => Icons.table_restaurant_rounded,
    _OrderType.takeout     => Icons.shopping_bag_outlined,
    _OrderType.delivery    => Icons.delivery_dining_rounded,
    _OrderType.deliveryApp => Icons.phone_android_rounded,
  };
}

class _OrderEntry {
  final RestaurantTable table;
  final List<KitchenOrder> kots;
  final int itemCount;
  final double total;
  final _OrderStatus status;
  final _OrderType type;
  final bool hasUnsent;

  const _OrderEntry({
    required this.table,
    required this.kots,
    required this.itemCount,
    required this.total,
    required this.status,
    required this.type,
    required this.hasUnsent,
  });
}

// Selected tab provider
final _selectedOrderTypeProvider = StateProvider<_OrderType>((_) => _OrderType.all);

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allKots     = ref.watch(kitchenProvider);
    final tables      = ref.watch(tablesProvider);
    final savedOrders = ref.watch(savedTableOrdersProvider);
    final selectedType = ref.watch(_selectedOrderTypeProvider);

    final activeTableIds = {
      ...allKots.map((o) => o.tableId),
      ...savedOrders.entries.where((e) => e.value.isNotEmpty).map((e) => e.key),
    };

    // For now all table orders are Dine-In
    // Takeout/Delivery will be added in Phase 4-5
    final allEntries = activeTableIds.map((tableId) {
      final table = tables.firstWhere(
        (t) => t.id == tableId,
        orElse: () => RestaurantTable(
          id: tableId, number: 0, capacity: 0, status: TableStatus.occupied,
        ),
      );
      final kots      = allKots.where((o) => o.tableId == tableId).toList();
      final cartItems = savedOrders[tableId] ?? [];
      final total     = kots.fold(0.0, (s, o) => s + o.total) +
                        cartItems.fold(0.0, (s, i) => s + i.unitPrice * i.quantity);
      final itemCount = kots.fold(0, (s, o) => s + o.items.length) + cartItems.length;
      final status = kots.isEmpty
          ? _OrderStatus.unsent
          : kots.every((o) => o.status == KotStatus.ready)
              ? _OrderStatus.ready
              : kots.any((o) => o.status == KotStatus.inProgress)
                  ? _OrderStatus.preparing
                  : _OrderStatus.active;

      return _OrderEntry(
        table: table, kots: kots, itemCount: itemCount, total: total,
        status: status, type: _OrderType.dineIn, hasUnsent: cartItems.isNotEmpty,
      );
    }).toList()..sort((a, b) => a.table.number.compareTo(b.table.number));

    // Filter by selected type
    final filtered = selectedType == _OrderType.all
        ? allEntries
        : allEntries.where((e) => e.type == selectedType).toList();

    // Count per type for tab badges
    final dineInCount      = allEntries.where((e) => e.type == _OrderType.dineIn).length;
    final takeoutCount     = 0; // future phase
    final deliveryCount    = 0; // future phase
    final deliveryAppCount = 0; // future phase — Talabat etc.

    // Status groups
    final ready     = filtered.where((e) => e.status == _OrderStatus.ready).toList();
    final preparing = filtered.where((e) => e.status == _OrderStatus.preparing).toList();
    final active    = filtered.where((e) => e.status == _OrderStatus.active).toList();
    final unsent    = filtered.where((e) => e.status == _OrderStatus.unsent).toList();

    final List<Widget> listItems = [];

    void addSection(String label, Color color, IconData icon, List<_OrderEntry> group) {
      if (group.isEmpty) return;
      listItems.add(_SectionHeader(label: label, color: color, icon: icon, count: group.length));
      for (final e in group) {
        listItems.add(_OrderCard(entry: e, onOpen: () => _openTable(ref, e.table)));
      }
      listItems.add(const SizedBox(height: 8));
    }

    addSection('Food Ready', AppColors.success,           Icons.check_circle_rounded,  ready);
    addSection('Preparing',  AppColors.primary,            Icons.restaurant_rounded,    preparing);
    addSection('In Queue',   AppColors.warning,            Icons.hourglass_top_rounded, active);
    addSection('Unsent',     AppColors.onSurfaceVariant,   Icons.edit_note_rounded,     unsent);

    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          _OrdersHeader(
            total: allEntries.length,
            ready: ready.length,
            preparing: preparing.length,
            active: active.length,
          ),
          // Type tab bar
          _TypeTabBar(
            selected: selectedType,
            dineInCount: dineInCount,
            takeoutCount: takeoutCount,
            deliveryCount: deliveryCount,
            deliveryAppCount: deliveryAppCount,
            onSelect: (t) => ref.read(_selectedOrderTypeProvider.notifier).state = t,
          ),
          Container(height: 1, color: AppColors.outlineVariant),
          Expanded(
            child: filtered.isEmpty
                ? _EmptyOrders(type: selectedType)
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: listItems,
                  ),
          ),
        ],
      ),
    );
  }

  void _openTable(WidgetRef ref, RestaurantTable table) {
    final savedOrders = ref.read(savedTableOrdersProvider);
    final savedNotes  = ref.read(savedTableNotesProvider);
    ref.read(cartProvider.notifier).loadItems(savedOrders[table.id] ?? []);
    ref.read(orderNoteProvider.notifier).state   = savedNotes[table.id] ?? '';
    ref.read(tableNumberProvider.notifier).state = table.number.toString();
    ref.read(activeTableProvider.notifier).state = table;
    ref.read(appViewProvider.notifier).state     = AppView.pos;
  }
}

// ── Type tab bar ──────────────────────────────────────────────────────────────

class _TypeTabBar extends StatelessWidget {
  final _OrderType selected;
  final int dineInCount;
  final int takeoutCount;
  final int deliveryCount;
  final int deliveryAppCount;
  final void Function(_OrderType) onSelect;

  const _TypeTabBar({
    required this.selected,
    required this.dineInCount,
    required this.takeoutCount,
    required this.deliveryCount,
    required this.deliveryAppCount,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final counts = {
      _OrderType.all:         dineInCount + takeoutCount + deliveryCount + deliveryAppCount,
      _OrderType.dineIn:      dineInCount,
      _OrderType.takeout:     takeoutCount,
      _OrderType.delivery:    deliveryCount,
      _OrderType.deliveryApp: deliveryAppCount,
    };

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: _OrderType.values.map((type) {
          final isSelected = type == selected;
          final count = counts[type] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.outlineVariant,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      type.icon,
                      size: 14,
                      color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      type.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.25)
                              : AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final int count;

  const _SectionHeader({
    required this.label, required this.color,
    required this.icon,  required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold,
              color: color, letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$count',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: color.withValues(alpha: 0.2))),
        ],
      ),
    );
  }
}

// ── Page header ───────────────────────────────────────────────────────────────

class _OrdersHeader extends StatelessWidget {
  final int total, ready, preparing, active;
  const _OrdersHeader({
    required this.total, required this.ready,
    required this.preparing, required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: AppColors.surface,
      child: Row(
        children: [
          const Text('Active Orders',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryFixed, borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$total tables',
                style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
          const Spacer(),
          if (ready > 0)     _MiniChip(label: '$ready ready',      color: AppColors.success),
          if (preparing > 0) ...[const SizedBox(width: 6), _MiniChip(label: '$preparing preparing', color: AppColors.primary)],
          if (active > 0)    ...[const SizedBox(width: 6), _MiniChip(label: '$active in queue',     color: AppColors.warning)],
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ── Order card ────────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final _OrderEntry entry;
  final VoidCallback onOpen;
  const _OrderCard({required this.entry, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;

    switch (entry.status) {
      case _OrderStatus.ready:
        statusColor = AppColors.success; statusLabel = 'Food Ready'; statusIcon = Icons.check_circle_rounded;
      case _OrderStatus.preparing:
        statusColor = AppColors.primary; statusLabel = 'Preparing'; statusIcon = Icons.restaurant_rounded;
      case _OrderStatus.active:
        statusColor = AppColors.warning; statusLabel = 'In Queue'; statusIcon = Icons.hourglass_top_rounded;
      case _OrderStatus.unsent:
        statusColor = AppColors.onSurfaceVariant; statusLabel = 'Not Sent'; statusIcon = Icons.edit_note_rounded;
    }

    return GestureDetector(
      onTap: onOpen,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: entry.status == _OrderStatus.ready
                ? AppColors.success.withValues(alpha: 0.4)
                : AppColors.outlineVariant,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.table_restaurant_rounded, color: statusColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Table ${entry.table.number}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryFixed,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(entry.type.icon, size: 10, color: AppColors.primary),
                            const SizedBox(width: 3),
                            Text(entry.type.label,
                                style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text('${entry.itemCount} items',
                          style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                      if (entry.kots.isNotEmpty) ...[
                        const Text('  ·  ', style: TextStyle(color: AppColors.onSurfaceVariant)),
                        Text('${entry.kots.length} KOT${entry.kots.length > 1 ? 's' : ''}',
                            style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                      ],
                      if (entry.hasUnsent) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('unsent',
                              style: TextStyle(fontSize: 10, color: AppColors.warning, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusLabel,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text('IQD ${entry.total.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: AppColors.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyOrders extends StatelessWidget {
  final _OrderType type;
  const _EmptyOrders({required this.type});

  @override
  Widget build(BuildContext context) {
    final isFiltered = type != _OrderType.all;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, color: AppColors.outlineVariant, size: 56),
          const SizedBox(height: 16),
          Text(
            isFiltered ? 'No ${type.label} orders' : 'No active orders',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text(
            isFiltered
                ? '${type.label} orders will appear here'
                : 'Orders will appear here once tables are opened',
            style: const TextStyle(fontSize: 13, color: AppColors.outline),
          ),
        ],
      ),
    );
  }
}
