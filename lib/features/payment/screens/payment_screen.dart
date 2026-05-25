import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/constants/app_colors.dart';
import 'package:easycasher/core/constants/app_constants.dart';
import 'package:easycasher/features/cashier/models/cart_item.dart';
import 'package:easycasher/features/auth/providers/auth_provider.dart';
import 'package:easycasher/features/cashier/providers/cashier_provider.dart';
import 'package:easycasher/features/kitchen/models/kitchen_order.dart';
import 'package:easycasher/features/kitchen/providers/kitchen_provider.dart';
import 'package:easycasher/features/payment/models/payment.dart';
import 'package:easycasher/features/payment/providers/payment_provider.dart';
import 'package:easycasher/features/settings/providers/settings_provider.dart';
import 'package:easycasher/features/tables/models/restaurant_table.dart';
import 'package:easycasher/features/tables/providers/tables_provider.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final RestaurantTable table;
  final List<KitchenOrder> kots;
  final List<CartItem> cartItems;

  const PaymentScreen({
    super.key,
    required this.table,
    required this.kots,
    required this.cartItems,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  PaymentMethod _method = PaymentMethod.cash;
  final _cashController = TextEditingController();
  final _tipController = TextEditingController();
  bool _showReceipt = false;
  CompletedPayment? _completedPayment;
  double _tip = 0;
  int _splitCount = 1;

  double get _kotSubtotal =>
      widget.kots.fold(0.0, (s, o) => s + o.total);
  double get _cartSubtotal =>
      widget.cartItems.fold(0.0, (s, i) => s + i.subtotal);
  double get _subtotal => _kotSubtotal + _cartSubtotal;

  double get _discountAmount {
    final type = ref.read(discountTypeProvider);
    final value = ref.read(discountValueProvider);
    return type == DiscountType.percent
        ? _subtotal * (value / 100)
        : value.clamp(0.0, _subtotal);
  }

  double get _discountedSubtotal => _subtotal - _discountAmount;
  double get _tax => _discountedSubtotal * AppConstants.taxRate;
  double get _totalBeforeTip => _discountedSubtotal + _tax;
  double get _total => _totalBeforeTip + _tip;

  double get _cashReceived =>
      double.tryParse(_cashController.text) ?? 0;
  double get _change => max(0.0, _cashReceived - _total);

  bool get _canComplete =>
      _method == PaymentMethod.card || _cashReceived >= _total;

  List<double> _quickAmounts() {
    const denominations = [250.0, 500.0, 1000.0, 5000.0, 10000.0, 25000.0, 50000.0];
    final t = _total;
    final amounts = <double>{t}; // exact always first

    final larger = denominations.where((d) => d > t).toList();
    if (larger.isNotEmpty) {
      amounts.addAll(larger.take(3));
    } else {
      // total exceeds 50k — round up in 50k steps
      final next = ((t / 50000).ceil() * 50000).toDouble();
      amounts.add(next);
      amounts.add(next + 50000);
    }

    return (amounts.toList()..sort()).take(5).toList();
  }

  @override
  void initState() {
    super.initState();
    _cashController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _cashController.dispose();
    _tipController.dispose();
    super.dispose();
  }

  void _complete() {
    // Build a flat snapshot of all items (KOT items + unsent cart items)
    final completedItems = <CompletedItem>[
      for (final kot in widget.kots)
        for (final i in kot.items)
          CompletedItem(
            name: i.name,
            emoji: '🍽️',
            quantity: i.quantity,
            unitPrice: i.unitPrice,
            modifiersLabel: i.modifierSummary,
          ),
      for (final ci in widget.cartItems)
        CompletedItem(
          name: ci.item.name,
          emoji: ci.item.emoji,
          quantity: ci.quantity,
          unitPrice: ci.unitPrice,
          modifiersLabel: ci.modifierSummary,
        ),
    ];

    final staff       = ref.read(currentStaffProvider);
    final orderNumber = ref.read(orderNumberProvider);
    final orderType   = ref.read(orderTypeProvider);
    final orderTypeLabel = switch (orderType) {
      OrderType.dineIn      => 'Dine-In',
      OrderType.takeaway    => 'Takeout',
      OrderType.delivery    => 'Delivery',
      OrderType.deliveryApp => 'Delivery App',
    };

    final payment = CompletedPayment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      orderNumber: orderNumber,
      orderType: orderTypeLabel,
      staffName: staff?.name ?? '—',
      tableId: widget.table.id,
      tableNumber: widget.table.number,
      items: completedItems,
      subtotal: _subtotal,
      discountAmount: _discountAmount,
      tax: _tax,
      tip: _tip,
      total: _total,
      method: _method,
      cashPaid: _method == PaymentMethod.cash ? _cashReceived : 0,
      cardPaid: _method == PaymentMethod.card ? _total : 0,
      change: _change,
      timestamp: DateTime.now(),
    );

    ref.read(paymentHistoryProvider.notifier).add(payment);
    ref.read(kitchenProvider.notifier).clearTable(widget.table.id);
    ref.read(savedTableOrdersProvider.notifier).update(
      (s) => Map.fromEntries(s.entries.where((e) => e.key != widget.table.id)),
    );
    ref.read(savedTableNotesProvider.notifier).update(
      (s) => Map.fromEntries(s.entries.where((e) => e.key != widget.table.id)),
    );
    ref.read(tablesProvider.notifier).setStatus(widget.table.id, TableStatus.available);
    ref.read(cartProvider.notifier).clear();
    ref.read(orderNoteProvider.notifier).state = '';
    ref.read(tableNumberProvider.notifier).state = '';
    ref.read(discountValueProvider.notifier).state = 0;
    ref.read(activeTableProvider.notifier).state = null;

    setState(() {
      _completedPayment = payment;
      _showReceipt = true;
    });
  }

  void _done() => Navigator.pop(context);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 860,
        height: 560,
        child: _showReceipt
            ? _ReceiptView(
                payment: _completedPayment!,
                kots: widget.kots,
                cartItems: widget.cartItems,
                onDone: _done,
              )
            : Row(
          children: [
            SizedBox(
              width: 320,
              child: _OrderSummary(
                table: widget.table,
                kots: widget.kots,
                cartItems: widget.cartItems,
                subtotal: _subtotal,
                discountAmount: _discountAmount,
                tax: _tax,
                total: _total,
              ),
            ),
            Container(width: 1, color: AppColors.outlineVariant),
            Expanded(
              child: _PaymentPanel(
                total: _total,
                totalBeforeTip: _totalBeforeTip,
                tip: _tip,
                change: _change,
                method: _method,
                cashController: _cashController,
                tipController: _tipController,
                quickAmounts: _quickAmounts(),
                canComplete: _canComplete,
                onMethodChange: (m) => setState(() {
                  _method = m;
                  _cashController.clear();
                }),
                onQuickAmount: (v) => setState(() {
                  _cashController.text = v.toStringAsFixed(0);
                }),
                onTipChange: (v) => setState(() => _tip = v),
                splitCount: _splitCount,
                onSplitChange: (v) => setState(() => _splitCount = v),
                onComplete: _complete,
                onClose: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Receipt view ─────────────────────────────────────────────────────────────

class _ReceiptView extends ConsumerWidget {
  final CompletedPayment payment;
  final List<KitchenOrder> kots;
  final List<CartItem> cartItems;
  final VoidCallback onDone;

  const _ReceiptView({
    required this.payment,
    required this.kots,
    required this.cartItems,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // Success header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: AppColors.surface,
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 22),
                const SizedBox(width: 10),
                const Text('Payment Complete',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface)),
                const Spacer(),
                Text(
                  _invoiceNumber(),
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.outlineVariant),
          // Receipt paper
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  width: 360,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _ReceiptPaper(
                    payment: payment,
                    kots: kots,
                    cartItems: cartItems,
                    restaurantName: settings.restaurantName,
                    receiptFooter: settings.receiptFooter,
                  ),
                ),
              ),
            ),
          ),
          // Action buttons
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.outlineVariant)),
            ),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Printing receipt...')),
                  ),
                  icon: const Icon(Icons.print_outlined, size: 16),
                  label: const Text('Print'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.onSurfaceVariant,
                    side: const BorderSide(color: AppColors.outlineVariant),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onDone,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Done',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _invoiceNumber() {
    final d = payment.timestamp;
    final seq = payment.id.substring(payment.id.length - 4);
    return 'INV-${d.year}${d.month.toString().padLeft(2,'0')}${d.day.toString().padLeft(2,'0')}-$seq';
  }
}

class _ReceiptPaper extends StatelessWidget {
  final CompletedPayment payment;
  final List<KitchenOrder> kots;
  final List<CartItem> cartItems;
  final String restaurantName;
  final String receiptFooter;

  const _ReceiptPaper({
    required this.payment,
    required this.kots,
    required this.cartItems,
    required this.restaurantName,
    required this.receiptFooter,
  });

  String _fmt(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final d = payment.timestamp;
    final date =
        '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
    final time =
        '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
    final invoiceNum =
        'INV-${d.year}${d.month.toString().padLeft(2,'0')}${d.day.toString().padLeft(2,'0')}-${payment.id.substring(payment.id.length - 4)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          const Center(
            child: Text('🏪',
                style: TextStyle(fontSize: 36)),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(restaurantName,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
          ),
          const Center(
            child: Text('POS Receipt',
                style: TextStyle(fontSize: 11, color: Colors.black45)),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text('Table ${payment.tableNumber}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87)),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(invoiceNum,
                style: const TextStyle(
                    fontSize: 11, color: Colors.black45)),
          ),
          Center(
            child: Text('$date   $time',
                style: const TextStyle(
                    fontSize: 11, color: Colors.black45)),
          ),
          const SizedBox(height: 14),
          _Dashes(),
          const SizedBox(height: 8),
          // Items from KOTs
          for (final kot in kots)
            for (final item in kot.items)
              _ReceiptItemRow(
                  name: item.name,
                  qty: item.quantity,
                  price: item.subtotal,
                  fmt: _fmt),
          // Unsent cart items
          for (final ci in cartItems)
            _ReceiptItemRow(
                name: ci.item.name,
                qty: ci.quantity,
                price: ci.subtotal,
                fmt: _fmt),
          const SizedBox(height: 8),
          _Dashes(),
          const SizedBox(height: 8),
          // Total
          Row(
            children: [
              const Text('TOTAL',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              const Spacer(),
              Text('IQD ${_fmt(payment.total)}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 8),
          _Dashes(),
          const SizedBox(height: 8),
          // Payment details
          _ReceiptRow('Payment',
              payment.method == PaymentMethod.cash ? 'Cash' : 'Card'),
          if (payment.tip > 0) ...[
            const SizedBox(height: 3),
            _ReceiptRow('Tip', 'IQD ${_fmt(payment.tip)}'),
          ],
          if (payment.method == PaymentMethod.cash) ...[
            const SizedBox(height: 3),
            _ReceiptRow('Received', 'IQD ${_fmt(payment.cashPaid)}'),
            const SizedBox(height: 3),
            _ReceiptRow('Change', 'IQD ${_fmt(payment.change)}',
                highlight: payment.change > 0),
          ],
          const SizedBox(height: 14),
          _Dashes(),
          const SizedBox(height: 14),
          // Footer
          Center(
            child: Text(receiptFooter,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black45)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Dashes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        38,
        (_) => const Expanded(
          child: Text('–',
              style: TextStyle(fontSize: 10, color: Colors.black12),
              textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

class _ReceiptItemRow extends StatelessWidget {
  final String name;
  final int qty;
  final double price;
  final String Function(double) fmt;

  const _ReceiptItemRow({
    required this.name,
    required this.qty,
    required this.price,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$qty× ',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54)),
          Expanded(
            child: Text(name,
                style: const TextStyle(
                    fontSize: 12, color: Colors.black87)),
          ),
          Text('IQD ${fmt(price)}',
              style: const TextStyle(
                  fontSize: 12, color: Colors.black87)),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _ReceiptRow(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final color = highlight ? Colors.green.shade700 : Colors.black54;
    return Row(
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: color)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                color: color)),
      ],
    );
  }
}

// ── Left panel: order summary ─────────────────────────────────────────────────

class _OrderSummary extends StatelessWidget {
  final RestaurantTable table;
  final List<KitchenOrder> kots;
  final List<CartItem> cartItems;
  final double subtotal;
  final double discountAmount;
  final double tax;
  final double total;

  const _OrderSummary({
    required this.table,
    required this.kots,
    required this.cartItems,
    required this.subtotal,
    required this.discountAmount,
    required this.tax,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            color: AppColors.surface,
            child: Row(
              children: [
                const Icon(Icons.receipt_long_rounded,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Table ${table.number}  ·  Order Summary',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.outlineVariant),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final kot in kots) ...[
                  _KotDivider(number: kot.kotNumber),
                  for (final item in kot.items)
                    _ItemRow(
                        name: item.name,
                        qty: item.quantity,
                        price: item.subtotal),
                  const SizedBox(height: 6),
                ],
                if (cartItems.isNotEmpty) ...[
                  _UnsentDivider(),
                  for (final ci in cartItems)
                    _ItemRow(
                        name: ci.item.name,
                        qty: ci.quantity,
                        price: ci.subtotal),
                ],
              ],
            ),
          ),
          Container(height: 1, color: AppColors.outlineVariant),
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                if (discountAmount > 0) ...[
                  _TotRow('Subtotal', subtotal),
                  const SizedBox(height: 4),
                  _TotRow('Discount', discountAmount, isDiscount: true),
                  const SizedBox(height: 4),
                ],
                _TotRow('TOTAL', total, isTotal: true),
                // tip is included in total — shown separately for clarity

              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KotDivider extends StatelessWidget {
  final int number;
  const _KotDivider({required this.number});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('KOT #$number',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurfaceVariant)),
          const SizedBox(width: 6),
          const Expanded(child: Divider(color: AppColors.outlineVariant)),
        ],
      ),
    );
  }
}

class _UnsentDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Text('Unsent',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning)),
          const SizedBox(width: 6),
          const Expanded(child: Divider(color: AppColors.outlineVariant)),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final String name;
  final int qty;
  final double price;
  const _ItemRow({required this.name, required this.qty, required this.price});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text('$qty×',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary)),
          const SizedBox(width: 6),
          Expanded(
              child: Text(name,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.onSurface))),
          Text('IQD ${price.toStringAsFixed(0)}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.onSurface)),
        ],
      ),
    );
  }
}

class _TotRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isTotal;
  final bool isDiscount;
  const _TotRow(this.label, this.value, {this.isTotal = false, this.isDiscount = false});

  @override
  Widget build(BuildContext context) {
    final labelColor = isDiscount
        ? AppColors.success
        : isTotal ? AppColors.onSurface : AppColors.onSurfaceVariant;
    final displayValue = isDiscount
        ? '- IQD ${value.toStringAsFixed(0)}'
        : 'IQD ${value.toStringAsFixed(0)}';

    return Row(
      children: [
        Text(label,
            style: TextStyle(
              fontSize: isTotal ? 14 : 12,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: labelColor,
            )),
        const Spacer(),
        Text(displayValue,
            style: TextStyle(
              fontSize: isTotal ? 16 : 12,
              fontWeight: FontWeight.bold,
              color: isDiscount ? AppColors.success : isTotal ? AppColors.primary : AppColors.onSurface,
            )),
      ],
    );
  }
}

// ── Right panel: payment input ────────────────────────────────────────────────

class _PaymentPanel extends StatelessWidget {
  final double total;
  final double totalBeforeTip;
  final double tip;
  final double change;
  final PaymentMethod method;
  final TextEditingController cashController;
  final TextEditingController tipController;
  final List<double> quickAmounts;
  final bool canComplete;
  final void Function(PaymentMethod) onMethodChange;
  final void Function(double) onQuickAmount;
  final void Function(double) onTipChange;
  final int splitCount;
  final void Function(int) onSplitChange;
  final VoidCallback onComplete;
  final VoidCallback onClose;

  const _PaymentPanel({
    required this.total,
    required this.totalBeforeTip,
    required this.tip,
    required this.change,
    required this.method,
    required this.cashController,
    required this.tipController,
    required this.quickAmounts,
    required this.canComplete,
    required this.onMethodChange,
    required this.onQuickAmount,
    required this.onTipChange,
    required this.splitCount,
    required this.onSplitChange,
    required this.onComplete,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header — fixed
          Row(
            children: [
              const Text('Payment',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface)),
              const Spacer(),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
                color: AppColors.onSurfaceVariant,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Scrollable middle section
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Method tabs
                  Row(
                    children: [
                      _MethodTab(
                        icon: Icons.payments_outlined,
                        label: 'Cash',
                        selected: method == PaymentMethod.cash,
                        onTap: () => onMethodChange(PaymentMethod.cash),
                      ),
                      const SizedBox(width: 8),
                      _MethodTab(
                        icon: Icons.credit_card_rounded,
                        label: 'Card',
                        selected: method == PaymentMethod.card,
                        onTap: () => onMethodChange(PaymentMethod.card),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Total display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Text('Total',
                            style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
                        const Spacer(),
                        Text('IQD ${total.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Split bill
                  _SplitBillRow(total: total, splitCount: splitCount, onSplitChange: onSplitChange),
                  const SizedBox(height: 12),
                  // Tip
                  _TipRow(
                    totalBeforeTip: totalBeforeTip,
                    tip: tip,
                    controller: tipController,
                    onTipChange: onTipChange,
                  ),
                  const SizedBox(height: 12),
                  // Cash / Card section
                  method == PaymentMethod.cash
                      ? _CashSection(
                          controller: cashController,
                          total: total,
                          change: change,
                          quickAmounts: quickAmounts,
                          onQuickAmount: onQuickAmount,
                        )
                      : const _CardSection(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Complete button — always visible at bottom
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: canComplete ? onComplete : null,
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: const Text('Complete Payment',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.outlineVariant,
                disabledForegroundColor: AppColors.onSurfaceVariant,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplitBillRow extends StatelessWidget {
  final double total;
  final int splitCount;
  final void Function(int) onSplitChange;

  const _SplitBillRow({
    required this.total,
    required this.splitCount,
    required this.onSplitChange,
  });

  @override
  Widget build(BuildContext context) {
    final perPerson = splitCount > 1 ? total / splitCount : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Split Bill',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            // Decrease
            GestureDetector(
              onTap: () { if (splitCount > 1) onSplitChange(splitCount - 1); },
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: const Icon(Icons.remove_rounded, size: 16, color: AppColors.onSurface),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              splitCount == 1 ? 'No split' : '$splitCount guests',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface),
            ),
            const SizedBox(width: 8),
            // Increase
            GestureDetector(
              onTap: () { if (splitCount < 20) onSplitChange(splitCount + 1); },
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: const Icon(Icons.add_rounded, size: 16, color: AppColors.onSurface),
              ),
            ),
            if (splitCount > 1) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'IQD ${perPerson.toStringAsFixed(0)} / person',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _TipRow extends StatelessWidget {
  final double totalBeforeTip;
  final double tip;
  final TextEditingController controller;
  final void Function(double) onTipChange;

  const _TipRow({
    required this.totalBeforeTip,
    required this.tip,
    required this.controller,
    required this.onTipChange,
  });

  static const _presets = [5, 10, 15, 20];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tip (optional)',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            // Quick % presets
            ..._presets.map((pct) {
              final amount = totalBeforeTip * pct / 100;
              final isSelected = (tip - amount).abs() < 0.01;
              return GestureDetector(
                onTap: () {
                  onTipChange(isSelected ? 0 : amount);
                  controller.text = isSelected ? '' : amount.toStringAsFixed(0);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryFixed : AppColors.surfaceLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.outlineVariant,
                    ),
                  ),
                  child: Text(
                    '$pct%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.onSurface,
                    ),
                  ),
                ),
              );
            }),
            // Custom amount field
            Expanded(
              child: SizedBox(
                height: 34,
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 13, color: AppColors.onSurface),
                  onChanged: (v) => onTipChange(double.tryParse(v) ?? 0),
                  decoration: InputDecoration(
                    hintText: 'Custom',
                    hintStyle: const TextStyle(fontSize: 12, color: AppColors.outline),
                    prefixText: 'IQD  ',
                    prefixStyle: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CashSection extends StatelessWidget {
  final TextEditingController controller;
  final double total;
  final double change;
  final List<double> quickAmounts;
  final void Function(double) onQuickAmount;

  const _CashSection({
    required this.controller,
    required this.total,
    required this.change,
    required this.quickAmounts,
    required this.onQuickAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cash Received',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofocus: true,
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface),
          decoration: InputDecoration(
            prefixText: 'IQD  ',
            prefixStyle: const TextStyle(
                fontSize: 14, color: AppColors.onSurfaceVariant),
            filled: true,
            fillColor: AppColors.surfaceLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quickAmounts
              .map((a) => _QuickAmountBtn(
                    amount: a,
                    isExact: a == total,
                    onTap: () => onQuickAmount(a),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
        // Change display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: change > 0
                ? AppColors.success.withValues(alpha: 0.08)
                : AppColors.surfaceLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: change > 0
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Text('Change',
                  style: TextStyle(
                      fontSize: 13,
                      color: change > 0
                          ? AppColors.success
                          : AppColors.onSurfaceVariant)),
              const Spacer(),
              Text('IQD ${change.toStringAsFixed(0)}',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: change > 0
                          ? AppColors.success
                          : AppColors.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardSection extends StatelessWidget {
  const _CardSection();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.primaryFixed,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.credit_card_rounded,
                size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text('Process card payment',
              style: TextStyle(
                  fontSize: 14, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 4),
          const Text('Tap Complete Payment when done',
              style: TextStyle(
                  fontSize: 12, color: AppColors.outline)),
        ],
      ),
    );
  }
}

class _MethodTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MethodTab({
    required this.icon,
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
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.primary : AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: selected
                    ? Colors.white
                    : AppColors.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : AppColors.onSurfaceVariant,
                )),
          ],
        ),
      ),
    );
  }
}

class _QuickAmountBtn extends StatelessWidget {
  final double amount;
  final bool isExact;
  final VoidCallback onTap;

  const _QuickAmountBtn({
    required this.amount,
    required this.isExact,
    required this.onTap,
  });

  String _fmt(double v) {
    final parts = v.toStringAsFixed(0).split('');
    final buf = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buf.write(',');
      buf.write(parts[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isExact
              ? AppColors.primaryFixed
              : AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isExact
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.outlineVariant,
          ),
        ),
        child: Text(
          _fmt(amount),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color:
                isExact ? AppColors.primary : AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}
