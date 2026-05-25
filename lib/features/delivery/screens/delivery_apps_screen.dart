import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/constants/app_colors.dart';

enum _TalabatStatus { all, newOrder, preparing, ready, completed }

extension _TalabatStatusX on _TalabatStatus {
  String get label => switch (this) {
        _TalabatStatus.all       => 'All',
        _TalabatStatus.newOrder  => 'New',
        _TalabatStatus.preparing => 'Preparing',
        _TalabatStatus.ready     => 'Ready',
        _TalabatStatus.completed => 'Completed',
      };

  Color get color => switch (this) {
        _TalabatStatus.all       => AppColors.primary,
        _TalabatStatus.newOrder  => const Color(0xFFFF6B00),
        _TalabatStatus.preparing => Colors.blue,
        _TalabatStatus.ready     => Colors.green,
        _TalabatStatus.completed => Colors.grey,
      };
}

final _talabatStatusProvider =
    StateProvider<_TalabatStatus>((_) => _TalabatStatus.all);

class DeliveryAppsScreen extends ConsumerWidget {
  const DeliveryAppsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(_talabatStatusProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TalabatHeader(status: status),
        Expanded(child: _TalabatBody(status: status)),
      ],
    );
  }
}

class _TalabatHeader extends ConsumerWidget {
  final _TalabatStatus status;
  const _TalabatHeader({required this.status});

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
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B00).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.delivery_dining_rounded,
                size: 16, color: Color(0xFFFF6B00)),
          ),
          const SizedBox(width: 10),
          const Text(
            'Talabat Orders',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(width: 16),
          ..._TalabatStatus.values.map(
            (s) => _StatusChip(status: s, selected: status),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, size: 8, color: Colors.green),
                SizedBox(width: 6),
                Text(
                  'Connected',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends ConsumerWidget {
  final _TalabatStatus status;
  final _TalabatStatus selected;
  const _StatusChip({required this.status, required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = status == selected;
    return GestureDetector(
      onTap: () => ref.read(_talabatStatusProvider.notifier).state = status,
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

class _TalabatBody extends StatelessWidget {
  final _TalabatStatus status;
  const _TalabatBody({required this.status});

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
              color: const Color(0xFFFF6B00).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delivery_dining_rounded,
              size: 40,
              color: Color(0xFFFF6B00),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            status == _TalabatStatus.all
                ? 'No Talabat orders yet'
                : 'No ${status.label.toLowerCase()} orders',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Incoming Talabat orders will appear here automatically',
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
