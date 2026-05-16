import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/constants/app_colors.dart';
import 'package:easycasher/features/cashier/providers/cashier_provider.dart';
import 'package:easycasher/features/cashier/widgets/cart_item_tile.dart';
import 'package:easycasher/core/constants/app_constants.dart';
import 'package:easycasher/features/kitchen/models/kitchen_order.dart';
import 'package:easycasher/features/kitchen/providers/kitchen_provider.dart';
import 'package:easycasher/features/tables/models/restaurant_table.dart';
import 'package:easycasher/features/tables/providers/tables_provider.dart';

class CartPanel extends ConsumerWidget {
  const CartPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final activeTable = ref.watch(activeTableProvider);
    final tableKots = activeTable != null
        ? ref.watch(tableKotsProvider(activeTable.id))
        : <KitchenOrder>[];

    final hasKots = tableKots.isNotEmpty;
    final subtotal = ref.watch(subtotalProvider);

    // Bill total = all KOTs + current cart
    final kotSubtotal =
        tableKots.fold(0.0, (s, o) => s + o.total);
    final billSubtotal = kotSubtotal + subtotal;
    final billTax = billSubtotal * AppConstants.taxRate;
    final billTotal = billSubtotal + billTax;

    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          const _CartHeader(),
          Container(height: 1, color: AppColors.outlineVariant),
          Expanded(
            child: cartItems.isEmpty && !hasKots
                ? const _EmptyCart()
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      // Sent KOTs summary
                      if (hasKots) ...[
                        _KotSummarySection(kots: tableKots),
                        const SizedBox(height: 8),
                      ],
                      // Current cart items
                      if (cartItems.isNotEmpty) ...[
                        if (hasKots)
                          const _SectionLabel('New Items'),
                        ...cartItems.asMap().entries.map(
                              (e) => CartItemTile(
                                  index: e.key, cartItem: e.value),
                            ),
                        const SizedBox(height: 8),
                        const _KotBlock(),
                        const SizedBox(height: 4),
                        const _CookingNoteField(),
                      ],
                    ],
                  ),
          ),
          if (cartItems.isNotEmpty || hasKots) ...[
            Container(height: 1, color: AppColors.outlineVariant),
            _TotalsSection(
              subtotal: billSubtotal,
              tax: billTax,
              total: billTotal,
            ),
            _ActionButtons(total: billTotal, kotTotal: kotSubtotal),
          ],
        ],
      ),
    );
  }
}

class _CartHeader extends ConsumerWidget {
  const _CartHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderType = ref.watch(orderTypeProvider);
    final tableNumber = ref.watch(tableNumberProvider);
    final activeTable = ref.watch(activeTableProvider);
    final tableKots = activeTable != null
        ? ref.watch(tableKotsProvider(activeTable.id))
        : <KitchenOrder>[];

    String typeLabel;
    switch (orderType) {
      case OrderType.dineIn:
        typeLabel =
            tableNumber.isEmpty ? 'Dine In' : 'Table $tableNumber  •  Dine In';
      case OrderType.takeaway:
        typeLabel = 'Takeout';
      case OrderType.delivery:
        typeLabel = 'Delivery';
    }

    // Derive kitchen status from KOTs
    final allReady = tableKots.isNotEmpty &&
        tableKots.every((o) => o.status == KotStatus.ready);
    final anyInProgress = tableKots.any((o) => o.status == KotStatus.inProgress);
    final anyPending = tableKots.any((o) => o.status == KotStatus.pending);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 16, 12),
      child: Row(
        children: [
          if (orderType == OrderType.dineIn && activeTable != null)
            IconButton(
              onPressed: () => _backToTables(ref),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
              color: AppColors.onSurfaceVariant,
              tooltip: 'Back to tables',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order #001',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      typeLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Kitchen status chip — visible to waiter
          if (tableKots.isNotEmpty) ...[
            const SizedBox(width: 8),
            _KitchenStatusChip(
              allReady: allReady,
              anyInProgress: anyInProgress,
              anyPending: anyPending,
            ),
          ],
          if (orderType == OrderType.dineIn && activeTable == null)
            const _TableInput(),
        ],
      ),
    );
  }

  void _backToTables(WidgetRef ref) {
    final activeTable = ref.read(activeTableProvider);
    if (activeTable == null) return;

    // Save current cart + note for this table
    final currentCart = ref.read(cartProvider);
    final currentNote = ref.read(orderNoteProvider);
    ref.read(savedTableOrdersProvider.notifier).update(
          (s) => {...s, activeTable.id: currentCart},
        );
    ref.read(savedTableNotesProvider.notifier).update(
          (s) => {...s, activeTable.id: currentNote},
        );

    // Only free the table if cart is empty AND no KOTs have been sent
    final hasKots = ref
        .read(kitchenProvider)
        .any((o) => o.tableId == activeTable.id);
    if (currentCart.isEmpty && !hasKots) {
      ref
          .read(tablesProvider.notifier)
          .setStatus(activeTable.id, TableStatus.available);
    }

    ref.read(cartProvider.notifier).clear();
    ref.read(orderNoteProvider.notifier).state = '';
    ref.read(tableNumberProvider.notifier).state = '';
    ref.read(activeTableProvider.notifier).state = null;
  }
}

class _TableInput extends ConsumerStatefulWidget {
  const _TableInput();

  @override
  ConsumerState<_TableInput> createState() => _TableInputState();
}

class _TableInputState extends ConsumerState<_TableInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: ref.read(tableNumberProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 34,
      child: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        onChanged: (v) =>
            ref.read(tableNumberProvider.notifier).state = v,
        style: const TextStyle(fontSize: 13, color: AppColors.onSurface),
        decoration: InputDecoration(
          hintText: 'Table #',
          hintStyle:
              const TextStyle(fontSize: 12, color: AppColors.outline),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          isDense: true,
          filled: true,
          fillColor: AppColors.surfaceLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppColors.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppColors.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 52, color: AppColors.outlineVariant),
          SizedBox(height: 12),
          Text(
            'No items added yet',
            style: TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tap a menu item to add',
            style: TextStyle(color: AppColors.outline, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _KotBlock extends StatelessWidget {
  const _KotBlock();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final date = '${now.day}/${now.month}/${now.year}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'KOT1  •  $time  •  $date',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.onSurfaceVariant),
            ),
          ),
          const Icon(Icons.expand_more_rounded,
              size: 16, color: AppColors.outline),
          const SizedBox(width: 8),
          const Icon(Icons.print_outlined,
              size: 16, color: AppColors.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _CookingNoteField extends ConsumerStatefulWidget {
  const _CookingNoteField();

  @override
  ConsumerState<_CookingNoteField> createState() =>
      _CookingNoteFieldState();
}

class _CookingNoteFieldState extends ConsumerState<_CookingNoteField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: ref.read(orderNoteProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: (v) => ref.read(orderNoteProvider.notifier).state = v,
      maxLines: 2,
      style:
          const TextStyle(fontSize: 12, color: AppColors.onSurface),
      decoration: InputDecoration(
        hintText: 'Add cooking instructions...',
        hintStyle:
            const TextStyle(fontSize: 12, color: AppColors.outline),
        contentPadding: const EdgeInsets.all(10),
        filled: true,
        fillColor: AppColors.surfaceLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _TotalsSection extends StatelessWidget {
  final double subtotal;
  final double tax;
  final double total;

  const _TotalsSection(
      {required this.subtotal, required this.tax, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          _TotalRow(label: 'Subtotal', value: subtotal),
          const SizedBox(height: 4),
          _TotalRow(label: 'Tax (5%)', value: tax),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: AppColors.outlineVariant),
          ),
          _TotalRow(label: 'Total', value: total, isTotal: true),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isTotal;

  const _TotalRow(
      {required this.label, required this.value, this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 14 : 13,
            fontWeight:
                isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal
                ? AppColors.onSurface
                : AppColors.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          'IQD ${value.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: isTotal ? 16 : 13,
            fontWeight: FontWeight.bold,
            color:
                isTotal ? AppColors.primary : AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends ConsumerWidget {
  final double total;
  final double kotTotal;
  const _ActionButtons({required this.total, required this.kotTotal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderType = ref.watch(orderTypeProvider);
    final activeTable = ref.watch(activeTableProvider);
    final isDineIn = orderType == OrderType.dineIn && activeTable != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: [
          // Send to Kitchen — dine-in primary action
          if (isDineIn) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _sendToKitchen(context, ref),
                icon: const Icon(Icons.kitchen_rounded, size: 18),
                label: const Text(
                  'Send to Kitchen',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Printing bill...')),
              ),
              icon: const Icon(Icons.print_outlined, size: 16),
              label: const Text('Print Bill'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.onSurfaceVariant,
                side: const BorderSide(color: AppColors.outlineVariant),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => _confirmPay(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text(
                'Pay Now  •  IQD ${total.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendToKitchen(BuildContext context, WidgetRef ref) {
    final activeTable = ref.read(activeTableProvider);
    final cartItems = ref.read(cartProvider);
    if (activeTable == null || cartItems.isEmpty) return;

    ref.read(kitchenProvider.notifier).send(
          tableId: activeTable.id,
          tableLabel: 'Table ${activeTable.number}',
          cartItems: cartItems,
        );

    final kotCount = ref
        .read(kitchenProvider)
        .where((o) => o.tableId == activeTable.id)
        .length;

    // Clear cart, keep table open
    ref.read(cartProvider.notifier).clear();
    ref.read(orderNoteProvider.notifier).state = '';
    ref.read(savedTableOrdersProvider.notifier).update(
          (s) => {...s, activeTable.id: []},
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('KOT #$kotCount sent to kitchen!'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmPay(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Text('Collect IQD ${total.toStringAsFixed(0)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final activeTable = ref.read(activeTableProvider);

              ref.read(cartProvider.notifier).clear();
              ref.read(orderNoteProvider.notifier).state = '';
              ref.read(tableNumberProvider.notifier).state = '';

              if (activeTable != null) {
                ref.read(savedTableOrdersProvider.notifier).update(
                      (s) => {
                        for (final e in s.entries)
                          if (e.key != activeTable.id) e.key: e.value,
                      },
                    );
                ref.read(kitchenProvider.notifier).clearTable(activeTable.id);
                ref
                    .read(tablesProvider.notifier)
                    .setStatus(activeTable.id, TableStatus.available);
                ref.read(activeTableProvider.notifier).state = null;
              }

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment confirmed!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            child: const Text('Confirm',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(child: Divider(color: AppColors.outlineVariant)),
        ],
      ),
    );
  }
}

class _KotSummarySection extends StatelessWidget {
  final List<KitchenOrder> kots;
  const _KotSummarySection({required this.kots});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Sent to Kitchen'),
        ...kots.map((kot) => _KotSummaryCard(kot: kot)),
      ],
    );
  }
}

class _KotSummaryCard extends ConsumerWidget {
  final KitchenOrder kot;
  const _KotSummaryCard({required this.kot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = switch (kot.status) {
      KotStatus.pending    => AppColors.warning,
      KotStatus.inProgress => AppColors.primary,
      KotStatus.ready      => AppColors.success,
    };
    final statusLabel = switch (kot.status) {
      KotStatus.pending    => 'Pending',
      KotStatus.inProgress => 'In Progress',
      KotStatus.ready      => 'Ready',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            child: Row(
              children: [
                Text(
                  'KOT #${kot.kotNumber}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.outlineVariant),
          ...kot.items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.fromLTRB(10, 5, 4, 5),
                child: Row(
                  children: [
                    Text(
                      '${item.quantity}×',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurface,
                            ),
                          ),
                          if (item.modifierSummary.isNotEmpty)
                            Text(
                              item.modifierSummary,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      'IQD ${item.subtotal.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _confirmVoid(context, ref, idx),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
              );
            }),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
            child: Row(
              children: [
                const Spacer(),
                Text(
                  'IQD ${kot.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmVoid(BuildContext context, WidgetRef ref, int itemIndex) {
    final item = kot.items[itemIndex];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Void Item'),
        content: Text('Remove "${item.name}" from KOT #${kot.kotNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(kitchenProvider.notifier).voidItem(kot.id, itemIndex);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${item.name}" removed from KOT #${kot.kotNumber}'),
                  backgroundColor: AppColors.danger,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Void', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _KitchenStatusChip extends StatelessWidget {
  final bool allReady;
  final bool anyInProgress;
  final bool anyPending;

  const _KitchenStatusChip({
    required this.allReady,
    required this.anyInProgress,
    required this.anyPending,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    final IconData icon;

    if (allReady) {
      color = AppColors.success;
      label = 'Food Ready';
      icon = Icons.check_circle_outline_rounded;
    } else if (anyInProgress) {
      color = AppColors.primary;
      label = 'Preparing';
      icon = Icons.restaurant_rounded;
    } else {
      color = AppColors.warning;
      label = 'In Queue';
      icon = Icons.hourglass_top_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
