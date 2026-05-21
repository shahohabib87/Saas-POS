import 'package:flutter/material.dart';
import 'package:easycasher/core/constants/app_colors.dart';
import 'package:easycasher/features/kitchen/models/kitchen_order.dart';

extension _OrderTypeVisuals on KotOrderType {
  Color get badgeColor => switch (this) {
    KotOrderType.dineIn      => const Color(0xFFEF4444),
    KotOrderType.deliveryApp => const Color(0xFFF97316),
    KotOrderType.delivery    => const Color(0xFFEAB308),
    KotOrderType.takeout     => const Color(0xFF10B981),
  };
  IconData get icon => switch (this) {
    KotOrderType.dineIn      => Icons.table_restaurant_rounded,
    KotOrderType.deliveryApp => Icons.phone_android_rounded,
    KotOrderType.delivery    => Icons.delivery_dining_rounded,
    KotOrderType.takeout     => Icons.shopping_bag_outlined,
  };
}

class KotCard extends StatefulWidget {
  final KitchenOrder order;
  final VoidCallback onBump;

  const KotCard({super.key, required this.order, required this.onBump});

  @override
  State<KotCard> createState() => _KotCardState();
}

class _KotCardState extends State<KotCard> {
  late final Stream<int> _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Stream.periodic(const Duration(seconds: 30), (i) => i);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _ticker,
      builder: (context, _) {
        final elapsed = widget.order.elapsed;
        final borderColor = _borderColor(widget.order.status, elapsed);
        final isReady = widget.order.status == KotStatus.ready;

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isReady ? 0.5 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(order: widget.order, elapsed: elapsed, borderColor: borderColor),
                const Divider(color: Colors.white12, height: 1),
                _ItemsList(items: widget.order.items),
                const Divider(color: Colors.white12, height: 1),
                _BumpButton(order: widget.order, onBump: widget.onBump),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _borderColor(KotStatus status, Duration elapsed) {
    if (status == KotStatus.ready) return Colors.white12;
    if (status == KotStatus.inProgress) return AppColors.primary;
    final mins = elapsed.inMinutes;
    if (mins < 5) return AppColors.success;
    if (mins < 10) return AppColors.warning;
    return AppColors.danger;
  }
}

class _Header extends StatelessWidget {
  final KitchenOrder order;
  final Duration elapsed;
  final Color borderColor;

  const _Header({
    required this.order,
    required this.elapsed,
    required this.borderColor,
  });

  String _formatElapsed(Duration d) {
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    return '${d.inHours}h ${d.inMinutes.remainder(60)}m ago';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.tableLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'KOT #${order.kotNumber}',
                      style: TextStyle(
                        color: borderColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _OrderTypeBadge(type: order.orderType),
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
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: borderColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _statusLabel(order.status),
                  style: TextStyle(
                    color: borderColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatElapsed(elapsed),
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(KotStatus status) => switch (status) {
        KotStatus.pending    => 'NEW',
        KotStatus.inProgress => 'IN PROGRESS',
        KotStatus.ready      => 'READY',
      };
}

class _OrderTypeBadge extends StatelessWidget {
  final KotOrderType type;
  const _OrderTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final color = type.badgeColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            type.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemsList extends StatelessWidget {
  final List<KotItem> items;

  const _ItemsList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '${item.quantity}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item.modifierSummary.isNotEmpty)
                      Text(
                        item.modifierSummary,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }
}

class _BumpButton extends StatelessWidget {
  final KitchenOrder order;
  final VoidCallback onBump;

  const _BumpButton({required this.order, required this.onBump});

  @override
  Widget build(BuildContext context) {
    if (order.status == KotStatus.ready) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 18),
            SizedBox(width: 6),
            Text(
              'Ready to serve',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final label = order.status == KotStatus.pending
        ? 'Start Preparing'
        : 'Mark as Ready';
    final color = order.status == KotStatus.pending
        ? AppColors.primary
        : AppColors.success;

    return Padding(
      padding: const EdgeInsets.all(10),
      child: SizedBox(
        height: 40,
        child: ElevatedButton(
          onPressed: onBump,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
