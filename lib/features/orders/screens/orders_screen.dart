import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/constants/app_colors.dart';
import 'package:easycasher/features/kitchen/models/kitchen_order.dart';
import 'package:easycasher/features/kitchen/providers/kitchen_provider.dart';
import 'package:easycasher/features/payment/models/payment.dart';
import 'package:easycasher/features/payment/providers/payment_provider.dart';
import 'package:easycasher/features/tables/models/restaurant_table.dart';
import 'package:easycasher/features/tables/providers/tables_provider.dart';
import 'package:easycasher/features/cashier/providers/cashier_provider.dart';
import 'package:easycasher/features/delivery/models/pending_delivery.dart';
import 'package:easycasher/features/delivery/providers/pending_delivery_provider.dart';

// ── Shared providers ──────────────────────────────────────────────────────────

final _ordersTabProvider = StateProvider<_Tab>((_) => _Tab.active);

enum _Tab { active, completed }

// ── Active order helpers ──────────────────────────────────────────────────────

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

final _selectedOrderTypeProvider = StateProvider<_OrderType>((_) => _OrderType.all);

// Completed-tab filters: order type (null = all) and an inclusive date range.
final _completedTypeProvider = StateProvider<String?>((_) => null);
final _completedFromProvider = StateProvider<DateTime?>((_) => null);
final _completedToProvider = StateProvider<DateTime?>((_) => null);

// ── Root screen ───────────────────────────────────────────────────────────────

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(_ordersTabProvider);

    return Column(
      children: [
        _TopBar(tab: tab),
        Expanded(
          child: tab == _Tab.active
              ? const _ActiveOrdersBody()
              : const _CompletedOrdersBody(),
        ),
      ],
    );
  }
}

// ── Top bar with Active / Completed toggle ────────────────────────────────────

class _TopBar extends ConsumerWidget {
  final _Tab tab;
  const _TopBar({required this.tab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedCount = ref.watch(paymentHistoryProvider).length;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Row(
        children: [
          _TabToggle(
            label: 'Active Orders',
            icon: Icons.receipt_long_rounded,
            selected: tab == _Tab.active,
            onTap: () => ref.read(_ordersTabProvider.notifier).state = _Tab.active,
          ),
          const SizedBox(width: 8),
          _TabToggle(
            label: 'Completed',
            icon: Icons.check_circle_outline_rounded,
            selected: tab == _Tab.completed,
            badge: completedCount,
            onTap: () => ref.read(_ordersTabProvider.notifier).state = _Tab.completed,
          ),
        ],
      ),
    );
  }
}

class _TabToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  const _TabToggle({
    required this.label,
    required this.icon,
    required this.selected,
    this.badge = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14,
                color: selected ? Colors.white : AppColors.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.onSurfaceVariant,
                )),
            if (badge > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$badge',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.white : AppColors.primary,
                    )),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVE ORDERS BODY
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveOrdersBody extends ConsumerWidget {
  const _ActiveOrdersBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allKots      = ref.watch(kitchenProvider);
    // Only dine-in tickets belong to a table row; takeout/delivery tickets live
    // on the KDS (and delivery also appears in the pending list below).
    final dineInKots   = allKots.where((o) => o.orderType == KotOrderType.dineIn).toList();
    final tables       = ref.watch(tablesProvider);
    final savedOrders  = ref.watch(savedTableOrdersProvider);
    final pending      = ref.watch(pendingDeliveriesProvider);
    final selectedType = ref.watch(_selectedOrderTypeProvider);

    final activeTableIds = {
      ...dineInKots.map((o) => o.tableId),
      ...savedOrders.entries.where((e) => e.value.isNotEmpty).map((e) => e.key),
    };

    final allEntries = activeTableIds.map((tableId) {
      final table = tables.firstWhere(
        (t) => t.id == tableId,
        orElse: () => RestaurantTable(
            id: tableId, number: 0, capacity: 0, status: TableStatus.occupied),
      );
      final kots      = dineInKots.where((o) => o.tableId == tableId).toList();
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

    // Active work is dine-in tables PLUS deliveries currently out with a driver.
    final showDineIn   = selectedType == _OrderType.all || selectedType == _OrderType.dineIn;
    final showDelivery = selectedType == _OrderType.all || selectedType == _OrderType.delivery;

    final dineIn = showDineIn ? allEntries : const <_OrderEntry>[];
    final dineInCount   = allEntries.length; // every table entry is dine-in
    final deliveryCount = pending.length;

    final ready     = dineIn.where((e) => e.status == _OrderStatus.ready).toList();
    final preparing = dineIn.where((e) => e.status == _OrderStatus.preparing).toList();
    final active    = dineIn.where((e) => e.status == _OrderStatus.active).toList();
    final unsent    = dineIn.where((e) => e.status == _OrderStatus.unsent).toList();

    final List<Widget> listItems = [];

    void addSection(String label, Color color, IconData icon, List<_OrderEntry> group) {
      if (group.isEmpty) return;
      listItems.add(_SectionHeader(label: label, color: color, icon: icon, count: group.length));
      for (final e in group) {
        listItems.add(_OrderCard(entry: e, onOpen: () => _openTable(ref, e.table)));
      }
      listItems.add(const SizedBox(height: 8));
    }

    addSection('Food Ready', AppColors.success,         Icons.check_circle_rounded,  ready);
    addSection('Preparing',  AppColors.primary,          Icons.restaurant_rounded,    preparing);
    addSection('In Queue',   AppColors.warning,          Icons.hourglass_top_rounded, active);
    addSection('Unsent',     AppColors.onSurfaceVariant, Icons.edit_note_rounded,     unsent);

    // Out-for-delivery orders never opened a table, so they live in their own
    // store — surface them here (under the Delivery filter). Cash is still
    // collected on the Delivery screen, which a tap jumps to.
    if (showDelivery && pending.isNotEmpty) {
      listItems.add(_SectionHeader(
          label: 'Out for Delivery',
          color: AppColors.primary,
          icon: Icons.moped_rounded,
          count: pending.length));
      for (final d in pending) {
        listItems.add(_DeliveryOrderCard(
          delivery: d,
          onOpen: () =>
              ref.read(appViewProvider.notifier).state = AppView.dispatch,
        ));
      }
      listItems.add(const SizedBox(height: 8));
    }

    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          _ActiveSubHeader(
            total: allEntries.length + pending.length,
            ready: ready.length,
            preparing: preparing.length,
            active: active.length,
          ),
          _TypeTabBar(
            selected: selectedType,
            dineInCount: dineInCount,
            deliveryCount: deliveryCount,
            onSelect: (t) => ref.read(_selectedOrderTypeProvider.notifier).state = t,
          ),
          Container(height: 1, color: AppColors.outlineVariant),
          Expanded(
            child: listItems.isEmpty
                ? _EmptyState(
                    icon: selectedType.icon,
                    message: selectedType == _OrderType.all
                        ? 'No active orders'
                        : 'No ${selectedType.label} orders',
                    sub: selectedType == _OrderType.all
                        ? 'Orders appear here once tables are opened'
                        : '${selectedType.label} orders will appear here',
                  )
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

// ─────────────────────────────────────────────────────────────────────────────
// COMPLETED ORDERS BODY
// ─────────────────────────────────────────────────────────────────────────────

// A delivery that's out with a driver, shown in the Active list. Tapping jumps
// to the Delivery screen where the cash is collected on the driver's return.
class _DeliveryOrderCard extends StatelessWidget {
  final PendingDelivery delivery;
  final VoidCallback onOpen;
  const _DeliveryOrderCard({required this.delivery, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final sub = [
      '🛵 ${delivery.driverName}',
      if (delivery.customerName.isNotEmpty) delivery.customerName,
      if (delivery.customerPhone.isNotEmpty) delivery.customerPhone,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.moped_rounded,
                      size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(delivery.orderNumber,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.onSurface)),
                      const SizedBox(height: 2),
                      Text(sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('IQD ${delivery.total.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.onSurface)),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Collect on return',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletedOrdersBody extends ConsumerWidget {
  const _CompletedOrdersBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(paymentHistoryProvider).reversed.toList(); // newest first
    final typeFilter = ref.watch(_completedTypeProvider);
    final from = ref.watch(_completedFromProvider);
    final to = ref.watch(_completedToProvider);

    // The order types actually present, so the filter only offers real options.
    final types = <String>{for (final p in all) p.orderType}.toList()..sort();

    final history = all.where((p) {
      if (typeFilter != null && p.orderType != typeFilter) return false;
      if (from != null && p.timestamp.isBefore(from)) return false;
      if (to != null && p.timestamp.isAfter(to)) return false;
      return true;
    }).toList();

    final filtersActive = typeFilter != null || from != null || to != null;

    final totalRevenue = history.fold(0.0, (s, p) => s + p.total);
    final cashCount    = history.where((p) => p.method == PaymentMethod.cash).length;
    final cardCount    = history.where((p) => p.method == PaymentMethod.card).length;

    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          _CompletedFilterBar(
            types: types,
            typeFilter: typeFilter,
            from: from,
            to: to,
          ),
          // Summary bar (reflects the current filters)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            color: AppColors.surface,
            child: Row(
              children: [
                _SummaryChip(
                  label: '${history.length} order${history.length == 1 ? '' : 's'}',
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                _SummaryChip(
                  label: 'IQD ${totalRevenue.toStringAsFixed(0)}',
                  icon: Icons.payments_rounded,
                  color: AppColors.success,
                ),
                const SizedBox(width: 10),
                if (cashCount > 0)
                  _SummaryChip(
                    label: '$cashCount cash',
                    icon: Icons.money_rounded,
                    color: AppColors.warning,
                  ),
                const SizedBox(width: 10),
                if (cardCount > 0)
                  _SummaryChip(
                    label: '$cardCount card',
                    icon: Icons.credit_card_rounded,
                    color: AppColors.primary,
                  ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.outlineVariant),
          Expanded(
            child: history.isEmpty
                ? _EmptyState(
                    icon: filtersActive
                        ? Icons.filter_alt_off_rounded
                        : Icons.check_circle_outline_rounded,
                    message: filtersActive
                        ? 'No orders match these filters'
                        : 'No completed orders yet',
                    sub: filtersActive
                        ? 'Try a different type or date range'
                        : 'Paid orders will appear here',
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    // Responsive: as many ~480px columns as fit, uniform height.
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 480,
                      mainAxisExtent: 88,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: history.length,
                    itemBuilder: (_, i) => _CompletedCard(
                      payment: history[i],
                      onTap: () => _showDetail(context, history[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, CompletedPayment payment) {
    showDialog(
      context: context,
      builder: (_) => _CompletedDetailDialog(payment: payment),
    );
  }
}

// ── Completed filters: order type + from/to date range ────────────────────────

class _CompletedFilterBar extends ConsumerWidget {
  final List<String> types;
  final String? typeFilter;
  final DateTime? from;
  final DateTime? to;
  const _CompletedFilterBar({
    required this.types,
    required this.typeFilter,
    required this.from,
    required this.to,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = typeFilter != null || from != null || to != null;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All types',
                    icon: Icons.list_alt_rounded,
                    selected: typeFilter == null,
                    onTap: () =>
                        ref.read(_completedTypeProvider.notifier).state = null,
                  ),
                  for (final t in types) ...[
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: t,
                      icon: Icons.local_offer_outlined,
                      selected: typeFilter == t,
                      onTap: () =>
                          ref.read(_completedTypeProvider.notifier).state = t,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          _DateButton(
            hint: 'From',
            value: from,
            onPick: (d) => ref.read(_completedFromProvider.notifier).state =
                d == null ? null : DateTime(d.year, d.month, d.day),
          ),
          const SizedBox(width: 8),
          _DateButton(
            hint: 'To',
            value: to,
            // Inclusive: end of the chosen day.
            onPick: (d) => ref.read(_completedToProvider.notifier).state =
                d == null ? null : DateTime(d.year, d.month, d.day, 23, 59, 59),
          ),
          if (active) ...[
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Clear filters',
              icon: const Icon(Icons.clear_rounded, size: 18),
              color: AppColors.onSurfaceVariant,
              onPressed: () {
                ref.read(_completedTypeProvider.notifier).state = null;
                ref.read(_completedFromProvider.notifier).state = null;
                ref.read(_completedToProvider.notifier).state = null;
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: selected ? Colors.white : AppColors.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.onSurfaceVariant,
                )),
          ],
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String hint;
  final DateTime? value;
  final void Function(DateTime?) onPick;
  const _DateButton({required this.hint, required this.value, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final set = value != null;
    final text = set
        ? '$hint: ${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.year}'
        : hint;

    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: DateTime(2020),
          lastDate: DateTime(now.year + 1, 12, 31),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: set
              ? AppColors.primary.withValues(alpha: 0.10)
              : AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: set ? AppColors.primary : AppColors.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 13,
                color: set ? AppColors.primary : AppColors.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(text,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: set ? AppColors.primary : AppColors.onSurfaceVariant,
                )),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _SummaryChip({required this.label, required this.icon, required this.color});

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
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _CompletedCard extends StatelessWidget {
  final CompletedPayment payment;
  final VoidCallback onTap;
  const _CompletedCard({required this.payment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCash = payment.method == PaymentMethod.cash;
    final methodColor = isCash ? AppColors.warning : AppColors.primary;
    final methodLabel = isCash ? 'Cash' : 'Card';
    final methodIcon  = isCash ? Icons.money_rounded : Icons.credit_card_rounded;

    final time = _formatTime(payment.timestamp);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(payment.orderNumber,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface)),
                      const SizedBox(width: 8),
                      _MiniTag(label: payment.orderType, color: AppColors.primary),
                      if (payment.tableNumber > 0) ...[
                        const SizedBox(width: 4),
                        _MiniTag(
                            label: 'Table ${payment.tableNumber}',
                            color: AppColors.onSurfaceVariant),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text('${payment.totalItems} items',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.onSurfaceVariant)),
                      const Text('  ·  ',
                          style: TextStyle(color: AppColors.onSurfaceVariant)),
                      Text(payment.staffName,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.onSurfaceVariant)),
                      const Text('  ·  ',
                          style: TextStyle(color: AppColors.onSurfaceVariant)),
                      Text(time,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: methodColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(methodIcon, size: 11, color: methodColor),
                      const SizedBox(width: 3),
                      Text(methodLabel,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: methodColor)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text('IQD ${payment.total.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface)),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ── Completed detail dialog ───────────────────────────────────────────────────

class _CompletedDetailDialog extends StatelessWidget {
  final CompletedPayment payment;
  const _CompletedDetailDialog({required this.payment});

  @override
  Widget build(BuildContext context) {
    final isCash = payment.method == PaymentMethod.cash;
    final dt     = payment.timestamp;
    final dateStr =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Text(payment.orderNumber,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: AppColors.onSurfaceVariant,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.outlineVariant),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Meta row
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _MiniTag(label: payment.orderType, color: AppColors.primary),
                        if (payment.tableNumber > 0)
                          _MiniTag(
                              label: 'Table ${payment.tableNumber}',
                              color: AppColors.onSurfaceVariant),
                        _MiniTag(
                            label: isCash ? 'Cash' : 'Card',
                            color: isCash ? AppColors.warning : AppColors.primary),
                        _MiniTag(
                            label: payment.staffName,
                            color: AppColors.onSurfaceVariant),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(dateStr,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 16),
                    // Items
                    const Text('ITEMS',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: Column(
                        children: [
                          for (int i = 0; i < payment.items.length; i++) ...[
                            if (i > 0)
                              const Divider(
                                  height: 1, color: AppColors.outlineVariant),
                            _ItemRow(item: payment.items[i]),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Totals
                    const Text('SUMMARY',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: Column(
                        children: [
                          _TotalRow(label: 'Subtotal',
                              value: 'IQD ${payment.subtotal.toStringAsFixed(0)}'),
                          if (payment.discountAmount > 0)
                            _TotalRow(
                                label: 'Discount',
                                value: '− IQD ${payment.discountAmount.toStringAsFixed(0)}',
                                color: AppColors.success),
                          if (payment.tax > 0)
                            _TotalRow(label: 'Tax',
                                value: 'IQD ${payment.tax.toStringAsFixed(0)}'),
                          if (payment.tip > 0)
                            _TotalRow(label: 'Tip',
                                value: 'IQD ${payment.tip.toStringAsFixed(0)}'),
                          const Divider(color: AppColors.outlineVariant, height: 16),
                          _TotalRow(
                              label: 'Total',
                              value: 'IQD ${payment.total.toStringAsFixed(0)}',
                              bold: true),
                          if (isCash && payment.cashPaid > 0) ...[
                            _TotalRow(label: 'Cash Received',
                                value: 'IQD ${payment.cashPaid.toStringAsFixed(0)}'),
                            _TotalRow(label: 'Change',
                                value: 'IQD ${payment.change.toStringAsFixed(0)}',
                                color: AppColors.success),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            const Divider(color: AppColors.outlineVariant),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final CompletedItem item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurface)),
                if (item.modifiersLabel.isNotEmpty)
                  Text(item.modifiersLabel,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          Text('×${item.quantity}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.onSurfaceVariant)),
          const SizedBox(width: 12),
          Text('IQD ${item.subtotal.toStringAsFixed(0)}',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface)),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;
  const _TotalRow(
      {required this.label, required this.value, this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? (bold ? AppColors.onSurface : AppColors.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: bold ? 14 : 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: c)),
          Text(value,
              style: TextStyle(
                  fontSize: bold ? 14 : 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: c)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVE ORDERS — sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveSubHeader extends StatelessWidget {
  final int total, ready, preparing, active;
  const _ActiveSubHeader(
      {required this.total,
      required this.ready,
      required this.preparing,
      required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: AppColors.surface,
      child: Row(
        children: [
          Text('$total tables open',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface)),
          const Spacer(),
          if (ready > 0)
            _MiniChip(label: '$ready ready', color: AppColors.success),
          if (preparing > 0) ...[
            const SizedBox(width: 6),
            _MiniChip(label: '$preparing preparing', color: AppColors.primary),
          ],
          if (active > 0) ...[
            const SizedBox(width: 6),
            _MiniChip(label: '$active in queue', color: AppColors.warning),
          ],
        ],
      ),
    );
  }
}

class _TypeTabBar extends StatelessWidget {
  final _OrderType selected;
  final int dineInCount;
  final int deliveryCount;
  final void Function(_OrderType) onSelect;

  const _TypeTabBar({
    required this.selected,
    required this.dineInCount,
    required this.deliveryCount,
    required this.onSelect,
  });

  // Only the types that can actually be active are offered — takeout is paid
  // instantly (it goes to Completed) and Delivery App has no data source.
  static const _visible = [_OrderType.all, _OrderType.dineIn, _OrderType.delivery];

  @override
  Widget build(BuildContext context) {
    final counts = {
      _OrderType.all:      dineInCount + deliveryCount,
      _OrderType.dineIn:   dineInCount,
      _OrderType.delivery: deliveryCount,
    };

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: _visible.map((type) {
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
                    color: isSelected ? AppColors.primary : AppColors.outlineVariant,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(type.icon, size: 14,
                        color: isSelected ? Colors.white : AppColors.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(type.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                        )),
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
                        child: Text('$count',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppColors.primary,
                            )),
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

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final int count;
  const _SectionHeader(
      {required this.label,
      required this.color,
      required this.icon,
      required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 1)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$count',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: color.withValues(alpha: 0.2))),
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
    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;

    switch (entry.status) {
      case _OrderStatus.ready:
        statusColor = AppColors.success;
        statusLabel = 'Food Ready';
        statusIcon  = Icons.check_circle_rounded;
      case _OrderStatus.preparing:
        statusColor = AppColors.primary;
        statusLabel = 'Preparing';
        statusIcon  = Icons.restaurant_rounded;
      case _OrderStatus.active:
        statusColor = AppColors.warning;
        statusLabel = 'In Queue';
        statusIcon  = Icons.hourglass_top_rounded;
      case _OrderStatus.unsent:
        statusColor = AppColors.onSurfaceVariant;
        statusLabel = 'Not Sent';
        statusIcon  = Icons.edit_note_rounded;
    }

    return GestureDetector(
      onTap: onOpen,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: entry.status == _OrderStatus.ready
                ? AppColors.success.withValues(alpha: 0.4)
                : AppColors.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.table_restaurant_rounded,
                  color: statusColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Table ${entry.table.number}',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface)),
                      const SizedBox(width: 8),
                      _MiniTag(label: entry.type.label, color: AppColors.primary),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text('${entry.itemCount} items',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.onSurfaceVariant)),
                      if (entry.kots.isNotEmpty) ...[
                        const Text('  ·  ',
                            style:
                                TextStyle(color: AppColors.onSurfaceVariant)),
                        Text(
                            '${entry.kots.length} KOT${entry.kots.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant)),
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
                          child: const Text('unsent',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600)),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text('IQD ${entry.total.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface)),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.onSurfaceVariant, size: 20),
          ],
        ),
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
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;
  const _EmptyState(
      {required this.icon, required this.message, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.outlineVariant, size: 56),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 6),
          Text(sub,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.outline)),
        ],
      ),
    );
  }
}
