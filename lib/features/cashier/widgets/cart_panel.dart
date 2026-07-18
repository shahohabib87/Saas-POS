import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/constants/app_colors.dart';
import 'package:easycasher/features/cashier/providers/cashier_provider.dart';
import 'package:easycasher/features/cashier/widgets/cart_item_tile.dart';
import 'package:easycasher/features/settings/providers/settings_provider.dart';
import 'package:easycasher/features/kitchen/models/kitchen_order.dart';
import 'package:easycasher/features/kitchen/providers/kitchen_provider.dart';
import 'package:easycasher/features/tables/models/restaurant_table.dart';
import 'package:easycasher/features/tables/providers/tables_provider.dart';
import 'package:easycasher/features/tables/screens/tables_screen.dart';
import 'package:easycasher/features/payment/screens/payment_screen.dart';
import 'package:easycasher/features/payment/models/payment.dart';
import 'package:easycasher/features/auth/providers/auth_provider.dart';
import 'package:easycasher/features/delivery/providers/delivery_provider.dart';
import 'package:easycasher/features/delivery/providers/pending_delivery_provider.dart';
import 'package:easycasher/features/delivery/models/pending_delivery.dart';
import 'package:easycasher/features/delivery/widgets/delivery_details_card.dart';
import 'package:easycasher/core/entitlement/entitlement.dart';
import 'package:easycasher/core/entitlement/entitlement_provider.dart';

class CartPanel extends ConsumerWidget {
  const CartPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final activeTable = ref.watch(activeTableProvider);
    final orderType = ref.watch(orderTypeProvider);
    final tableKots = activeTable != null
        ? ref.watch(tableKotsProvider(activeTable.id))
        : <KitchenOrder>[];

    final hasKots = tableKots.isNotEmpty;
    final subtotal = ref.watch(subtotalProvider);
    final discountType = ref.watch(discountTypeProvider);
    final discountValue = ref.watch(discountValueProvider);

    final isDelivery = orderType == OrderType.delivery;
    // A dine-in order needs a table before anything can go on the check; until
    // one is picked the cart shows the floor-plan prompt instead of items.
    final needsTable = orderType == OrderType.dineIn && activeTable == null;
    // The fee rides on the area, so it only applies to an in-house delivery.
    final deliveryFee = isDelivery ? ref.watch(deliveryFeeProvider) : 0.0;

    // Bill total = all KOTs + current cart
    final kotSubtotal = tableKots.fold(0.0, (s, o) => s + o.total);
    final billSubtotal = kotSubtotal + subtotal;
    final discountAmount = discountType == DiscountType.percent
        ? billSubtotal * (discountValue / 100)
        : discountValue.clamp(0.0, billSubtotal);
    final discountedSubtotal = billSubtotal - discountAmount;
    final billTax = discountedSubtotal * ref.watch(taxMultiplierProvider);
    // Delivery is charged on top of tax: it is a service, not part of the food.
    final billTotal = discountedSubtotal + billTax + deliveryFee;

    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          const _CartHeader(),
          Container(height: 1, color: AppColors.outlineVariant),
          const _OrderTypeSelector(),
          if (needsTable) ...[
            const Expanded(child: _PickTablePrompt()),
          ] else ...[
          if (isDelivery) const DeliveryDetailsCard(),
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
            _DiscountRow(subtotal: billSubtotal),
            _TotalsSection(
              subtotal: billSubtotal,
              discountAmount: discountAmount,
              tax: billTax,
              deliveryFee: deliveryFee,
              total: billTotal,
            ),
            _ActionButtons(total: billTotal, kotTotal: kotSubtotal),
          ],
          ],
        ],
      ),
    );
  }
}

/// Order-type picker, moved off the old left sidebar into the cart to match
/// the web POS — a 2×2 grid at the top of the panel. Switching type carries
/// the same table bookkeeping the sidebar used to do: seating a dine-in keeps
/// its saved tab, and leaving dine-in releases the active table.
class _OrderTypeSelector extends ConsumerWidget {
  const _OrderTypeSelector();

  static const _types = <(OrderType, String)>[
    (OrderType.dineIn, 'Dine-in'),
    (OrderType.takeaway, 'Takeaway'),
    (OrderType.delivery, 'Delivery'),
    (OrderType.deliveryApp, 'Delivery App'),
  ];

  void _select(WidgetRef ref, OrderType type) {
    ref.read(orderTypeProvider.notifier).state = type;
    ref.read(appViewProvider.notifier).state = AppView.pos;
    if (type == OrderType.dineIn) {
      final activeTable = ref.read(activeTableProvider);
      if (activeTable != null) {
        final currentCart = ref.read(cartProvider);
        final currentNote = ref.read(orderNoteProvider);
        ref.read(savedTableOrdersProvider.notifier).update(
              (s) => {...s, activeTable.id: currentCart},
            );
        ref.read(savedTableNotesProvider.notifier).update(
              (s) => {...s, activeTable.id: currentNote},
            );
        ref.read(cartProvider.notifier).clear();
        ref.read(orderNoteProvider.notifier).state = '';
        ref.read(tableNumberProvider.notifier).state = '';
        ref.read(activeTableProvider.notifier).state = null;
      }
    } else {
      ref.read(activeTableProvider.notifier).state = null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(orderTypeProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Column(
        children: [
          for (var row = 0; row < 2; row++)
            Padding(
              padding: EdgeInsets.only(top: row == 0 ? 0 : 6),
              child: Row(
                children: [
                  for (var col = 0; col < 2; col++) ...[
                    if (col == 1) const SizedBox(width: 6),
                    Expanded(
                      child: _OrderTypeButton(
                        label: _types[row * 2 + col].$2,
                        selected: _types[row * 2 + col].$1 == selected,
                        onTap: () => _select(ref, _types[row * 2 + col].$1),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderTypeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OrderTypeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.onSurfaceVariant,
          ),
        ),
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
        typeLabel = tableNumber.isEmpty ? 'Dine In' : 'Table $tableNumber';
      case OrderType.takeaway:
        typeLabel = 'Takeout';
      case OrderType.delivery:
        typeLabel = 'Delivery';
      case OrderType.deliveryApp:
        typeLabel = 'Delivery App';
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
          if (orderType == OrderType.dineIn && activeTable != null) ...[
            IconButton(
              onPressed: () => _backToTables(ref),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
              color: AppColors.onSurfaceVariant,
              tooltip: 'Back to tables',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            IconButton(
              onPressed: () => _showTransferDialog(context, ref),
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              color: AppColors.onSurfaceVariant,
              tooltip: 'Transfer table',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ref.watch(orderNumberProvider),
                  style: const TextStyle(
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
        ],
      ),
    );
  }

  void _showTransferDialog(BuildContext context, WidgetRef ref) {
    final activeTable = ref.read(activeTableProvider);
    if (activeTable == null) return;
    showDialog(
      context: context,
      builder: (_) => _TableTransferDialog(fromTable: activeTable, ref: ref),
    );
  }

  void _backToTables(WidgetRef ref) {
    final activeTable = ref.read(activeTableProvider);
    if (activeTable == null) return;

    // Save current cart + note + covers for this table
    final currentCart = ref.read(cartProvider);
    final currentNote = ref.read(orderNoteProvider);
    ref.read(savedTableOrdersProvider.notifier).update(
          (s) => {...s, activeTable.id: currentCart},
        );
    ref.read(savedTableNotesProvider.notifier).update(
          (s) => {...s, activeTable.id: currentNote},
        );

    ref.read(cartProvider.notifier).clear();
    ref.read(orderNoteProvider.notifier).state = '';
    ref.read(tableNumberProvider.notifier).state = '';
    ref.read(discountValueProvider.notifier).state = 0;
    ref.read(activeTableProvider.notifier).state = null;
  }
}

/// Shown in the cart when a dine-in order has no table yet. Opens the floor
/// plan as an overlay; picking a table seats it and closes the overlay, so the
/// register never has to leave the two-panel layout.
class _PickTablePrompt extends StatelessWidget {
  const _PickTablePrompt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.table_restaurant_rounded,
              size: 52, color: AppColors.outlineVariant),
          const SizedBox(height: 12),
          const Text(
            'No table selected',
            style: TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pick a table to start a dine-in order',
            style: TextStyle(color: AppColors.outline, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const _TablePickerDialog(),
            ),
            icon: const Icon(Icons.table_restaurant_rounded, size: 18),
            label: const Text('Pick a Table'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// The floor plan, shown as an overlay. It closes itself the moment a table
/// becomes active — [TablesScreen._openTable] sets [activeTableProvider], which
/// this dialog listens for.
class _TablePickerDialog extends ConsumerWidget {
  const _TablePickerDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(activeTableProvider, (_, next) {
      if (next != null) Navigator.of(context).pop();
    });

    return Dialog(
      insetPadding: const EdgeInsets.all(32),
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980, maxHeight: 680),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
              color: AppColors.surface,
              child: Row(
                children: [
                  const Text(
                    'Select a Table',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: AppColors.onSurfaceVariant,
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            Container(height: 1, color: AppColors.outlineVariant),
            const Expanded(child: TablesScreen()),
          ],
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

class _DiscountRow extends ConsumerStatefulWidget {
  final double subtotal;
  const _DiscountRow({required this.subtotal});

  @override
  ConsumerState<_DiscountRow> createState() => _DiscountRowState();
}

class _DiscountRowState extends ConsumerState<_DiscountRow> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    final v = ref.read(discountValueProvider);
    _ctrl = TextEditingController(text: v > 0 ? v.toStringAsFixed(0) : '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final discountType = ref.watch(discountTypeProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          // Toggle %  / IQD
          GestureDetector(
            onTap: () {
              ref.read(discountTypeProvider.notifier).state =
                  discountType == DiscountType.percent
                      ? DiscountType.fixed
                      : DiscountType.percent;
              ref.read(discountValueProvider.notifier).state = 0;
              _ctrl.clear();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Text(
                discountType == DiscountType.percent ? '%' : 'IQD',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: _ctrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 13, color: AppColors.onSurface),
                onChanged: (v) {
                  final parsed = double.tryParse(v) ?? 0.0;
                  final capped = discountType == DiscountType.percent
                      ? parsed.clamp(0.0, 100.0)
                      : parsed.clamp(0.0, widget.subtotal);
                  ref.read(discountValueProvider.notifier).state = capped;
                },
                decoration: InputDecoration(
                  hintText: discountType == DiscountType.percent ? 'Discount %' : 'Discount amount',
                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.outline),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  isDense: true,
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
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  suffixIcon: ref.watch(discountValueProvider) > 0
                      ? GestureDetector(
                          onTap: () {
                            ref.read(discountValueProvider.notifier).state = 0;
                            _ctrl.clear();
                          },
                          child: const Icon(Icons.clear_rounded, size: 16, color: AppColors.outline),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalsSection extends StatelessWidget {
  final double subtotal;
  final double discountAmount;
  final double tax;
  final double deliveryFee;
  final double total;

  const _TotalsSection({
    required this.subtotal,
    required this.discountAmount,
    required this.tax,
    required this.total,
    this.deliveryFee = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          if (discountAmount > 0) ...[
            _TotalRow(label: 'Subtotal', value: subtotal),
            const SizedBox(height: 4),
            _TotalRow(label: 'Discount', value: -discountAmount, isDiscount: true),
            const SizedBox(height: 4),
          ],
          // Itemised so the customer can see what they are being charged to
          // deliver, rather than finding it buried in the total.
          if (deliveryFee > 0) ...[
            _TotalRow(label: 'Delivery', value: deliveryFee),
            const SizedBox(height: 4),
          ],
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
  final bool isDiscount;

  const _TotalRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDiscount
        ? AppColors.success
        : isTotal
            ? AppColors.onSurface
            : AppColors.onSurfaceVariant;
    final displayValue = isDiscount
        ? '- IQD ${value.abs().toStringAsFixed(0)}'
        : 'IQD ${value.toStringAsFixed(0)}';

    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 14 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
        const Spacer(),
        Text(
          displayValue,
          style: TextStyle(
            fontSize: isTotal ? 16 : 13,
            fontWeight: FontWeight.bold,
            color: isTotal ? AppColors.primary : color,
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
    // Own-delivery is cash on delivery: the order leaves unpaid with a driver
    // and is settled on the Delivery screen when they return, so the till's
    // primary action becomes "Out for Delivery" rather than "Pay Now".
    final isDelivery = orderType == OrderType.delivery;

    final locked = ref.watch(entitlementProvider).level == EntitlementLevel.locked;
    // Settling a check that's already gone to the kitchen is always allowed —
    // a lapse must never strand a seated table. Only brand-new sales stop.
    final isSettlingOpenCheck = kotTotal > 0;

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
                onPressed: locked
                    ? () => _blockedBySubscription(context)
                    : () => _sendToKitchen(context, ref),
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
          Row(
            children: [
              Expanded(
                child: SizedBox(
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
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 40,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmVoid(context, ref),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Void'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: isDelivery
                ? ElevatedButton.icon(
                    onPressed: locked
                        ? () => _blockedBySubscription(context)
                        : () => _sendOutForDelivery(context, ref, total),
                    icon: const Icon(Icons.moped_rounded, size: 18),
                    label: Text(
                      'Out for Delivery  •  IQD ${total.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  )
                : ElevatedButton(
                    onPressed: (locked && !isSettlingOpenCheck)
                        ? () => _blockedBySubscription(context)
                        : () => _confirmPay(context, ref),
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

  void _blockedBySubscription(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Subscription expired — renew to start new orders. '
          'You can still settle open checks and close the shift.',
        ),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  /// Send the delivery order out with its driver, unpaid. It moves to the
  /// Delivery screen under that driver; the cash is taken when they return.
  void _sendOutForDelivery(BuildContext context, WidgetRef ref, double total) {
    final cartItems = ref.read(cartProvider);
    if (cartItems.isEmpty) {
      _toast(context, 'Add items before sending a delivery.');
      return;
    }

    final delivery = ref.read(deliveryDetailsProvider);
    if (!delivery.isComplete) {
      _toast(context,
          'Phone, driver and area are required before sending a delivery.');
      return;
    }

    // Recompute the bill from the cart so the stored total is self-contained.
    final subtotal = cartItems.fold(0.0, (s, i) => s + i.subtotal);
    final discountType = ref.read(discountTypeProvider);
    final discountValue = ref.read(discountValueProvider);
    final discountAmount = discountType == DiscountType.percent
        ? subtotal * (discountValue / 100)
        : discountValue.clamp(0.0, subtotal);
    final tax = (subtotal - discountAmount) * ref.read(taxMultiplierProvider);

    final driverName = (ref.read(driversProvider).valueOrNull ?? [])
            .where((d) => d.id == delivery.driverId)
            .map((d) => d.name)
            .firstOrNull ??
        'Driver';
    final staff = ref.read(currentStaffProvider);

    final pending = PendingDelivery(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      orderNumber: ref.read(orderNumberProvider),
      staffName: staff?.name ?? '—',
      driverId: delivery.driverId!,
      driverName: driverName,
      customerName: delivery.customerName,
      customerPhone: delivery.phone,
      deliveryNotes: delivery.notes,
      areaId: delivery.areaId,
      deliveryFee: delivery.areaFee,
      items: [
        for (final ci in cartItems)
          CompletedItem(
            name: ci.item.name,
            emoji: ci.item.emoji,
            quantity: ci.quantity,
            unitPrice: ci.unitPrice,
            modifiersLabel: ci.modifierSummary,
          ),
      ],
      subtotal: subtotal,
      discountAmount: discountAmount,
      tax: tax,
      total: total,
      placedAt: DateTime.now(),
    );

    ref.read(pendingDeliveriesProvider.notifier).add(pending);

    // Reset the till for the next order and start a fresh order number.
    ref.read(cartProvider.notifier).clear();
    ref.read(orderNoteProvider.notifier).state = '';
    ref.read(discountValueProvider.notifier).state = 0;
    ref.read(deliveryDetailsProvider.notifier).clear();
    ref.read(orderCounterProvider.notifier).bump();

    _toast(context, 'Sent out with $driverName — collect on return.',
        success: true);
  }

  void _toast(BuildContext context, String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.success : AppColors.danger,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  KotOrderType _toKotOrderType(OrderType t) => switch (t) {
    OrderType.dineIn       => KotOrderType.dineIn,
    OrderType.takeaway     => KotOrderType.takeout,
    OrderType.delivery     => KotOrderType.delivery,
    OrderType.deliveryApp  => KotOrderType.deliveryApp,
  };

  void _sendToKitchen(BuildContext context, WidgetRef ref) {
    final activeTable = ref.read(activeTableProvider);
    final cartItems = ref.read(cartProvider);
    if (activeTable == null || cartItems.isEmpty) return;

    ref.read(kitchenProvider.notifier).send(
          tableId: activeTable.id,
          tableLabel: 'Table ${activeTable.number}',
          cartItems: cartItems,
          orderType: _toKotOrderType(ref.read(orderTypeProvider)),
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
    final activeTable = ref.read(activeTableProvider);
    final kots = activeTable != null
        ? ref.read(tableKotsProvider(activeTable.id))
        : <KitchenOrder>[];
    final cartItems = ref.read(cartProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PaymentScreen(
        table: activeTable ??
            RestaurantTable(
              id: 'takeout',
              number: 0,
              capacity: 0,
              status: TableStatus.occupied,
            ),
        kots: kots,
        cartItems: cartItems,
      ),
    );
  }

  void _confirmVoid(BuildContext context, WidgetRef ref) {
    final activeTable = ref.read(activeTableProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Void Order',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface),
        ),
        content: Text(
          activeTable != null
              ? 'This will void all items for Table ${activeTable.number} and free the table.'
              : 'This will void all items in the current order.',
          style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _voidOrder(ref);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Void Order'),
          ),
        ],
      ),
    );
  }

  void _voidOrder(WidgetRef ref) {
    final activeTable = ref.read(activeTableProvider);

    if (activeTable != null) {
      ref.read(kitchenProvider.notifier).clearTable(activeTable.id);
      ref.read(savedTableOrdersProvider.notifier).update(
        (s) => Map.fromEntries(s.entries.where((e) => e.key != activeTable.id)),
      );
      ref.read(savedTableNotesProvider.notifier).update(
        (s) => Map.fromEntries(s.entries.where((e) => e.key != activeTable.id)),
      );
      ref.read(tablesProvider.notifier).setStatus(activeTable.id, TableStatus.available);
      ref.read(activeTableProvider.notifier).state = null;
      ref.read(tableNumberProvider.notifier).state = '';
    }

    ref.read(cartProvider.notifier).clear();
    ref.read(orderNoteProvider.notifier).state = '';
    ref.read(discountValueProvider.notifier).state = 0;
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

// ── Table Transfer Dialog ─────────────────────────────────────────────────────

class _TableTransferDialog extends ConsumerWidget {
  final RestaurantTable fromTable;
  final WidgetRef ref;
  const _TableTransferDialog({required this.fromTable, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final tables = widgetRef.watch(tablesProvider);
    final available = tables
        .where((t) => t.id != fromTable.id && t.status == TableStatus.available)
        .toList();

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(
        'Transfer Table ${fromTable.number}',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface),
      ),
      content: SizedBox(
        width: 320,
        child: available.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No available tables to transfer to.',
                  style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              )
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: available.map((t) => _TransferTableChip(
                  table: t,
                  onTap: () {
                    Navigator.pop(context);
                    _doTransfer(widgetRef, t);
                  },
                )).toList(),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.onSurfaceVariant)),
        ),
      ],
    );
  }

  void _doTransfer(WidgetRef r, RestaurantTable toTable) {
    final cart = r.read(cartProvider);
    final note = r.read(orderNoteProvider);

    r.read(savedTableOrdersProvider.notifier).update(
      (s) => {...Map.from(s)..remove(fromTable.id), toTable.id: cart},
    );
    r.read(savedTableNotesProvider.notifier).update(
      (s) => {...Map.from(s)..remove(fromTable.id), toTable.id: note},
    );

    r.read(kitchenProvider.notifier).transferTable(fromTable.id, toTable.id);
    r.read(tablesProvider.notifier).setStatus(fromTable.id, TableStatus.available);
    r.read(tablesProvider.notifier).setStatus(toTable.id, TableStatus.occupied);
    r.read(activeTableProvider.notifier).state = toTable;
    r.read(tableNumberProvider.notifier).state = toTable.number.toString();
  }
}

class _TransferTableChip extends StatelessWidget {
  final RestaurantTable table;
  final VoidCallback onTap;
  const _TransferTableChip({required this.table, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.table_restaurant_rounded, size: 20, color: AppColors.success),
            const SizedBox(height: 4),
            Text(
              'Table ${table.number}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurface),
            ),
            Text(
              '${table.capacity} seats',
              style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
