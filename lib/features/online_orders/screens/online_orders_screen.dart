import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/constants/app_colors.dart';
import 'package:easycasher/core/sync/cloud_sync.dart';

/// One inbox for every order that reaches us from outside the till — our own
/// web ordering and the aggregators alike. The terminal is the only writer of
/// an online order's state; the web console shows the same orders read-only.
///
/// Orders arrive over the sync channel, so this screen is the one place in the
/// app that genuinely cannot work offline. It says so rather than showing an
/// empty list, which would read as "quiet night" instead of "disconnected".

/// Where an online order came from.
enum OnlineOrderSource { own, talabat, careem }

extension OnlineOrderSourceX on OnlineOrderSource {
  String get label => switch (this) {
        OnlineOrderSource.own     => 'Web',
        OnlineOrderSource.talabat => 'Talabat',
        OnlineOrderSource.careem  => 'Careem',
      };

  Color get color => switch (this) {
        OnlineOrderSource.own     => AppColors.primary,
        OnlineOrderSource.talabat => const Color(0xFFFF6B00),
        OnlineOrderSource.careem  => const Color(0xFF4BB543),
      };
}

enum OnlineOrderStatus { all, incoming, preparing, ready, completed }

extension OnlineOrderStatusX on OnlineOrderStatus {
  String get label => switch (this) {
        OnlineOrderStatus.all       => 'All',
        OnlineOrderStatus.incoming  => 'New',
        OnlineOrderStatus.preparing => 'Preparing',
        OnlineOrderStatus.ready     => 'Ready',
        OnlineOrderStatus.completed => 'Completed',
      };

  Color get color => switch (this) {
        OnlineOrderStatus.all       => AppColors.primary,
        OnlineOrderStatus.incoming  => const Color(0xFFFF6B00),
        OnlineOrderStatus.preparing => Colors.blue,
        OnlineOrderStatus.ready     => Colors.green,
        OnlineOrderStatus.completed => Colors.grey,
      };
}

final _statusFilterProvider =
    StateProvider<OnlineOrderStatus>((_) => OnlineOrderStatus.all);

class OnlineOrdersScreen extends ConsumerWidget {
  const OnlineOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(_statusFilterProvider);
    final cloud = ref.watch(cloudSyncProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(status: status, connected: cloud.connected),
        Expanded(
          child: cloud.connected
              ? _EmptyInbox(status: status)
              : const _Disconnected(),
        ),
      ],
    );
  }
}

class _Header extends ConsumerWidget {
  final OnlineOrderStatus status;
  final bool connected;
  const _Header({required this.status, required this.connected});

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
            'Online Orders',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(width: 16),
          ...OnlineOrderStatus.values
              .map((s) => _StatusChip(status: s, selected: status)),
          const Spacer(),
          _ConnectionBadge(connected: connected),
        ],
      ),
    );
  }
}

/// Reflects the real sync state — when this is red, no order can reach us.
class _ConnectionBadge extends StatelessWidget {
  final bool connected;
  const _ConnectionBadge({required this.connected});

  @override
  Widget build(BuildContext context) {
    final color = connected ? Colors.green : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Text(
            connected ? 'Connected' : 'Offline',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends ConsumerWidget {
  final OnlineOrderStatus status;
  final OnlineOrderStatus selected;
  const _StatusChip({required this.status, required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = status == selected;
    return GestureDetector(
      onTap: () => ref.read(_statusFilterProvider.notifier).state = status,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? status.color.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? status.color : AppColors.outlineVariant,
          ),
        ),
        child: Text(
          status.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? status.color : AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}

class _Disconnected extends StatelessWidget {
  const _Disconnected();

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(
      icon: Icons.cloud_off_rounded,
      iconColor: AppColors.danger,
      title: 'Not connected',
      subtitle: 'Online orders cannot arrive while this terminal is offline.\n'
          'They will appear here once the connection is back.',
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  final OnlineOrderStatus status;
  const _EmptyInbox({required this.status});

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(
      icon: Icons.receipt_long_rounded,
      iconColor: AppColors.primary,
      title: status == OnlineOrderStatus.all
          ? 'No online orders yet'
          : 'No ${status.label.toLowerCase()} orders',
      subtitle: 'Incoming web and aggregator orders appear here automatically.',
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _CenteredMessage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: iconColor),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}
