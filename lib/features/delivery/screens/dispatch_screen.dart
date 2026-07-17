import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/constants/app_colors.dart';
import 'package:easycasher/features/auth/providers/auth_provider.dart';
import 'package:easycasher/features/cashier/providers/cashier_provider.dart';
import 'package:easycasher/features/delivery/models/pending_delivery.dart';
import 'package:easycasher/features/delivery/providers/pending_delivery_provider.dart';
import 'package:easycasher/features/payment/providers/payment_provider.dart';
import 'package:easycasher/features/shift/providers/shift_provider.dart';

String _iqd(double v) {
  final s = v.toStringAsFixed(0);
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return 'IQD ${buf.toString()}';
}

/// In-house delivery: orders that went out cash-on-delivery, grouped by the
/// driver who took them. When a driver gets back, the cashier collects the
/// cash here — each order settles as a normal cash sale into the shift.
///
/// Drivers and areas are managed in the web console; this screen only operates
/// on orders raised at the till.
class DispatchScreen extends ConsumerWidget {
  const DispatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final byDriver = ref.watch(deliveriesByDriverProvider);
    final all = ref.watch(pendingDeliveriesProvider);
    final totalOwed = all.fold(0.0, (s, d) => s + d.total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(count: all.length, totalOwed: totalOwed),
        Expanded(
          child: all.isEmpty
              ? const _EmptyState()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final entry in byDriver.entries)
                      _DriverCard(orders: entry.value),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Header extends ConsumerWidget {
  final int count;
  final double totalOwed;
  const _Header({required this.count, required this.totalOwed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Row(
        children: [
          const Text(
            'Delivery',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(width: 14),
          if (count > 0) ...[
            _Pill(
              label: '$count out',
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            _Pill(
              label: '${_iqd(totalOwed)} owed',
              color: AppColors.warning,
            ),
          ],
          const Spacer(),
          FilledButton.icon(
            onPressed: () {
              // Jump to the till with a delivery order started.
              ref.read(orderTypeProvider.notifier).state = OrderType.delivery;
              ref.read(appViewProvider.notifier).state = AppView.pos;
            },
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('New Delivery'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _DriverCard extends ConsumerWidget {
  final List<PendingDelivery> orders;
  const _DriverCard({required this.orders});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverName = orders.first.driverName;
    final owed = orders.fold(0.0, (s, d) => s + d.total);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Driver header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryFixed,
                  child: Icon(Icons.moped_rounded,
                      size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driverName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        '${orders.length} order${orders.length == 1 ? '' : 's'} · ${_iqd(owed)} to collect',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _collectAll(context, ref),
                  icon: const Icon(Icons.done_all_rounded, size: 16),
                  label: const Text('Collect All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9)),
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < orders.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, color: AppColors.outlineVariant),
            _OrderRow(order: orders[i]),
          ],
        ],
      ),
    );
  }

  void _collectAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _ConfirmCollectDialog(
        title: 'Collect from ${orders.first.driverName}',
        message:
            'Take ${_iqd(orders.fold(0.0, (s, d) => s + d.total))} for ${orders.length} order${orders.length == 1 ? '' : 's'}?',
        onConfirm: () {
          for (final o in List<PendingDelivery>.from(orders)) {
            _settle(ref, o);
          }
          _flash(context, 'Collected from ${orders.first.driverName}');
        },
      ),
    );
  }
}

class _OrderRow extends ConsumerWidget {
  final PendingDelivery order;
  const _OrderRow({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placed = order.placedAt;
    final time =
        '${placed.hour.toString().padLeft(2, '0')}:${placed.minute.toString().padLeft(2, '0')}';
    final who = order.customerName.trim().isNotEmpty
        ? order.customerName
        : (order.customerPhone.trim().isNotEmpty
            ? order.customerPhone
            : 'Customer');

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      order.orderNumber,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$who · ${order.totalItems} item${order.totalItems == 1 ? '' : 's'} · $time',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
                if (order.deliveryNotes.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    order.deliveryNotes,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.outline),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _iqd(order.total),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () => _collectOne(context, ref),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.success,
              side: const BorderSide(color: AppColors.success),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            child: const Text('Collect'),
          ),
        ],
      ),
    );
  }

  void _collectOne(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _ConfirmCollectDialog(
        title: 'Collect ${order.orderNumber}',
        message:
            'Take ${_iqd(order.total)} from ${order.driverName} for this order?',
        onConfirm: () {
          _settle(ref, order);
          _flash(context, 'Collected ${_iqd(order.total)}');
        },
      ),
    );
  }
}

/// Turn a returned delivery into a completed cash sale, then drop it from the
/// out-for-delivery list. Recording it through [paymentHistoryProvider] is what
/// puts the cash into the shift and queues the order for the cloud.
void _settle(WidgetRef ref, PendingDelivery order) {
  final collectedBy =
      ref.read(currentStaffProvider)?.name ?? order.staffName;
  ref
      .read(paymentHistoryProvider.notifier)
      .add(order.toCompletedPayment(collectedBy: collectedBy));
  ref.read(pendingDeliveriesProvider.notifier).remove(order.id);
  // The drawer just gained cash — recompute the shift figures.
  ref.invalidate(shiftSummaryProvider);
}

void _flash(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.success,
      duration: const Duration(seconds: 2),
    ),
  );
}

class _ConfirmCollectDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onConfirm;
  const _ConfirmCollectDialog({
    required this.title,
    required this.message,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(title,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface)),
      content: Text(message,
          style: const TextStyle(
              fontSize: 13, color: AppColors.onSurfaceVariant)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(color: AppColors.onSurfaceVariant)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Collect Cash'),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.delivery_dining_rounded,
            size: 64,
            color: AppColors.onSurface.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 16),
          Text(
            'No deliveries out',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Send a delivery order from the till and it will appear here.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}
