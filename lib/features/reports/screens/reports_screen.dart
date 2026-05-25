import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/constants/app_colors.dart';
import 'package:easycasher/features/payment/models/payment.dart';
import 'package:easycasher/features/payment/providers/payment_provider.dart';

// ── Period filter ─────────────────────────────────────────────────────────────

enum ReportPeriod { today, week, month, allTime }

extension ReportPeriodX on ReportPeriod {
  String get label => switch (this) {
        ReportPeriod.today   => 'Today',
        ReportPeriod.week    => 'This Week',
        ReportPeriod.month   => 'This Month',
        ReportPeriod.allTime => 'All Time',
      };
}

final _reportPeriodProvider =
    StateProvider<ReportPeriod>((ref) => ReportPeriod.today);

// ── Helpers ───────────────────────────────────────────────────────────────────

List<CompletedPayment> _filter(
    List<CompletedPayment> all, ReportPeriod period) {
  final now = DateTime.now();
  return all.where((p) {
    final t = p.timestamp;
    switch (period) {
      case ReportPeriod.today:
        return t.year == now.year && t.month == now.month && t.day == now.day;
      case ReportPeriod.week:
        final weekAgo = now.subtract(const Duration(days: 7));
        return t.isAfter(weekAgo);
      case ReportPeriod.month:
        return t.year == now.year && t.month == now.month;
      case ReportPeriod.allTime:
        return true;
    }
  }).toList();
}

String _fmt(double v) {
  final s = v.toStringAsFixed(0);
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period  = ref.watch(_reportPeriodProvider);
    final all     = ref.watch(paymentHistoryProvider);
    final orders  = _filter(all, period);

    final revenue     = orders.fold(0.0, (s, o) => s + o.total);
    final orderCount  = orders.length;
    final avgOrder    = orderCount == 0 ? 0.0 : revenue / orderCount;
    final cashTotal   = orders.where((o) => o.method == PaymentMethod.cash).fold(0.0, (s, o) => s + o.total);
    final cardTotal   = orders.where((o) => o.method == PaymentMethod.card).fold(0.0, (s, o) => s + o.total);
    final totalDiscount = orders.fold(0.0, (s, o) => s + o.discountAmount);
    final totalTax    = orders.fold(0.0, (s, o) => s + o.tax);

    // Order type breakdown
    final byType = <String, double>{};
    for (final o in orders) {
      byType[o.orderType] = (byType[o.orderType] ?? 0) + o.total;
    }

    // Top items
    final itemCount = <String, int>{};
    for (final o in orders) {
      for (final i in o.items) {
        itemCount[i.name] = (itemCount[i.name] ?? 0) + i.quantity;
      }
    }
    final topItems = itemCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: AppColors.surface,
          child: Row(
            children: [
              const Icon(Icons.bar_chart_rounded,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              const Text('Reports',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface)),
              const Spacer(),
              // Period filter chips
              ...ReportPeriod.values.map((p) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _PeriodChip(
                      label: p.label,
                      selected: period == p,
                      onTap: () => ref
                          .read(_reportPeriodProvider.notifier)
                          .state = p,
                    ),
                  )),
            ],
          ),
        ),
        Container(height: 1, color: AppColors.outlineVariant),
        // Body
        Expanded(
          child: orders.isEmpty
              ? _EmptyState(period: period)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Summary cards
                      Row(
                        children: [
                          _SummaryCard(
                            icon: Icons.attach_money_rounded,
                            label: 'Total Revenue',
                            value: 'IQD ${_fmt(revenue)}',
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 16),
                          _SummaryCard(
                            icon: Icons.receipt_long_rounded,
                            label: 'Orders',
                            value: '$orderCount',
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 16),
                          _SummaryCard(
                            icon: Icons.trending_up_rounded,
                            label: 'Avg Order',
                            value: 'IQD ${_fmt(avgOrder)}',
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 16),
                          _SummaryCard(
                            icon: Icons.discount_outlined,
                            label: 'Total Discount',
                            value: 'IQD ${_fmt(totalDiscount)}',
                            color: Colors.purple,
                          ),
                          if (totalTax > 0) ...[
                            const SizedBox(width: 16),
                            _SummaryCard(
                              icon: Icons.account_balance_outlined,
                              label: 'Total Tax',
                              value: 'IQD ${_fmt(totalTax)}',
                              color: Colors.teal,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Bottom two panels
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left column
                          Expanded(
                            child: Column(
                              children: [
                                // Payment method
                                _Panel(
                                  title: 'Payment Method',
                                  child: Column(
                                    children: [
                                      _BarRow(
                                        label: '💵 Cash',
                                        value: cashTotal,
                                        total: revenue,
                                        fmt: _fmt,
                                        color: AppColors.success,
                                      ),
                                      const SizedBox(height: 12),
                                      _BarRow(
                                        label: '💳 Card',
                                        value: cardTotal,
                                        total: revenue,
                                        fmt: _fmt,
                                        color: AppColors.primary,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Order type breakdown
                                _Panel(
                                  title: 'By Order Type',
                                  child: Column(
                                    children: [
                                      for (final entry in byType.entries) ...[
                                        _BarRow(
                                          label: _orderTypeEmoji(entry.key) +
                                              ' ' +
                                              entry.key,
                                          value: entry.value,
                                          total: revenue,
                                          fmt: _fmt,
                                          color: _orderTypeColor(entry.key),
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Right column — top items
                          Expanded(
                            child: _Panel(
                              title: 'Top Selling Items',
                              child: topItems.isEmpty
                                  ? const Center(
                                      child: Text('No items',
                                          style: TextStyle(
                                              color:
                                                  AppColors.onSurfaceVariant)))
                                  : Column(
                                      children: [
                                        for (int i = 0;
                                            i < topItems.length && i < 10;
                                            i++)
                                          _TopItemRow(
                                            rank: i + 1,
                                            name: topItems[i].key,
                                            qty: topItems[i].value,
                                          ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  String _orderTypeEmoji(String type) => switch (type) {
        'Dine-In'      => '🍽️',
        'Takeout'      => '🥡',
        'Delivery'     => '🛵',
        'Delivery App' => '📱',
        _              => '📋',
      };

  Color _orderTypeColor(String type) => switch (type) {
        'Dine-In'      => AppColors.primary,
        'Takeout'      => Colors.orange,
        'Delivery'     => Colors.teal,
        'Delivery App' => Colors.purple,
        _              => AppColors.onSurfaceVariant,
      };
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outlineVariant,
          ),
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

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;

  const _Panel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final double value;
  final double total;
  final String Function(double) fmt;
  final Color color;

  const _BarRow({
    required this.label,
    required this.value,
    required this.total,
    required this.fmt,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : (value / total).clamp(0.0, 1.0);
    final pctLabel = '${(pct * 100).toStringAsFixed(0)}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.onSurface)),
            const Spacer(),
            Text('IQD ${fmt(value)}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface)),
            const SizedBox(width: 8),
            SizedBox(
              width: 36,
              child: Text(pctLabel,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.onSurfaceVariant)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: AppColors.outlineVariant,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _TopItemRow extends StatelessWidget {
  final int rank;
  final String name;
  final int qty;

  const _TopItemRow({
    required this.rank,
    required this.name,
    required this.qty,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text('$rank.',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: rank <= 3
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(name,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.onSurface)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('×$qty',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ReportPeriod period;

  const _EmptyState({required this.period});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📊', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text('No orders ${period.label.toLowerCase()}',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface)),
          const SizedBox(height: 6),
          const Text('Complete some orders to see your report here.',
              style: TextStyle(
                  fontSize: 13, color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
