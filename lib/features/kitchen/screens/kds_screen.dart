import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/sync/cloud_sync.dart';
import 'package:easycasher/features/auth/models/staff.dart';
import 'package:easycasher/features/auth/providers/auth_provider.dart';
import 'package:easycasher/features/kitchen/models/kitchen_order.dart';
import 'package:easycasher/features/kitchen/providers/kitchen_link_provider.dart';
import 'package:easycasher/features/kitchen/providers/kitchen_provider.dart';
import 'package:easycasher/features/kitchen/widgets/kot_card.dart';

class KdsScreen extends ConsumerWidget {
  const KdsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(kitchenProvider);
    // Bumps route through the link: applied locally on the till, sent to the
    // till from a LAN kitchen display.
    void bump(String id) => ref.read(kitchenLinkProvider.notifier).bump(id);
    final isKdsDevice =
        ref.watch(cloudSyncProvider.select((s) => s.deviceMode)) ==
            DeviceMode.kds;

    int byPriority(KitchenOrder a, KitchenOrder b) =>
        a.orderType.priority.compareTo(b.orderType.priority);

    final pending    = orders.where((o) => o.status == KotStatus.pending).toList()..sort(byPriority);
    final inProgress = orders.where((o) => o.status == KotStatus.inProgress).toList()..sort(byPriority);
    final ready      = orders.where((o) => o.status == KotStatus.ready).toList()..sort(byPriority);

    return Container(
      color: const Color(0xFF0D1117),
      child: Column(
        children: [
          _KdsHeader(
            pending: pending.length,
            inProgress: inProgress.length,
            ready: ready.length,
          ),
          if (isKdsDevice) const _LinkStatusStrip(),
          Expanded(
            child: orders.isEmpty
                ? const _EmptyKds()
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _KdsColumn(
                        label: 'ACTIVE',
                        count: pending.length,
                        accentColor: const Color(0xFF10B981),
                        orders: pending,
                        onBump: bump,
                      ),
                      _ColumnDivider(),
                      _KdsColumn(
                        label: 'PREPARING',
                        count: inProgress.length,
                        accentColor: const Color(0xFF4529E7),
                        orders: inProgress,
                        onBump: bump,
                      ),
                      _ColumnDivider(),
                      _KdsColumn(
                        label: 'READY',
                        count: ready.length,
                        accentColor: Colors.white54,
                        orders: ready,
                        onBump: bump,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _KdsColumn extends StatelessWidget {
  final String label;
  final int count;
  final Color accentColor;
  final List<KitchenOrder> orders;
  final void Function(String id) onBump;

  const _KdsColumn({
    required this.label,
    required this.count,
    required this.accentColor,
    required this.orders,
    required this.onBump,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          // Column header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              border: Border(
                bottom: BorderSide(color: accentColor.withValues(alpha: 0.3)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Orders list
          Expanded(
            child: orders.isEmpty
                ? Center(
                    child: Text(
                      'No orders',
                      style: TextStyle(
                        color: Colors.white12,
                        fontSize: 13,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: orders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => KotCard(
                      order: orders[i],
                      onBump: () => onBump(orders[i].id),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ColumnDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, color: Colors.white.withValues(alpha: 0.06));
}

class _KdsHeader extends ConsumerWidget {
  final int pending;
  final int inProgress;
  final int ready;

  const _KdsHeader({
    required this.pending,
    required this.inProgress,
    required this.ready,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A device locked to KDS mode would otherwise be locked forever — only a
    // manager can flip it back to a full POS from here.
    final staff = ref.watch(currentStaffProvider);
    final canExitKdsMode = ref.watch(
            cloudSyncProvider.select((s) => s.deviceMode)) ==
            DeviceMode.kds &&
        (staff?.role == StaffRole.admin || staff?.role == StaffRole.manager);

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF161B22),
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.kitchen_rounded, color: Colors.white54, size: 20),
          const SizedBox(width: 10),
          const Text(
            'Kitchen Display',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          _HeaderChip(label: 'Active',    count: pending,    color: const Color(0xFF10B981)),
          const SizedBox(width: 8),
          _HeaderChip(label: 'Preparing', count: inProgress, color: const Color(0xFF4529E7)),
          const SizedBox(width: 8),
          _HeaderChip(label: 'Ready',     count: ready,      color: Colors.white38),
          const SizedBox(width: 16),
          const _VerticalDivider(),
          const SizedBox(width: 16),
          if (canExitKdsMode) ...[
            TextButton.icon(
              onPressed: () => ref
                  .read(cloudSyncProvider.notifier)
                  .setDeviceMode(DeviceMode.full),
              icon: const Icon(Icons.point_of_sale_rounded, size: 16),
              label: const Text('Exit KDS mode'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white60,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          TextButton.icon(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: const Icon(Icons.logout_rounded, size: 16),
            label: const Text('Logout'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white60,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 28, color: Colors.white12);
}

class _HeaderChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _HeaderChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

/// On a dedicated kitchen device the board is a mirror of the till — this
/// strip says whether the mirror is live, so an empty board is never ambiguous
/// (no orders vs. not connected).
class _LinkStatusStrip extends ConsumerWidget {
  const _LinkStatusStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = ref.watch(kitchenLinkProvider);

    final (color, text) = switch (link.status) {
      KdsLinkStatus.connected => (
          const Color(0xFF10B981),
          'Connected to till (${link.tillAddress})',
        ),
      KdsLinkStatus.connecting => (
          const Color(0xFFF59E0B),
          'Connecting to till at ${link.tillAddress}… retrying',
        ),
      KdsLinkStatus.unconfigured => (
          const Color(0xFFF59E0B),
          'No till address set — enter it in Settings → Cloud Sync on this device',
        ),
      // A KDS device never reports `serving`; covered for completeness.
      KdsLinkStatus.serving => (const Color(0xFF10B981), 'Serving'),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      color: color.withValues(alpha: 0.12),
      child: Row(
        children: [
          Icon(
            link.status == KdsLinkStatus.connected
                ? Icons.wifi_rounded
                : Icons.wifi_off_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

class _EmptyKds extends StatelessWidget {
  const _EmptyKds();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline_rounded,
              color: Colors.white12, size: 64),
          SizedBox(height: 16),
          Text(
            'No active orders',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Orders will appear here when sent from the POS',
            style: TextStyle(color: Colors.white24, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
