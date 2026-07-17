import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/constants/app_colors.dart';

enum _DeliveryTab { active, scheduled, completed }

extension _DeliveryTabX on _DeliveryTab {
  String get label => switch (this) {
        _DeliveryTab.active    => 'Active',
        _DeliveryTab.scheduled => 'Scheduled',
        _DeliveryTab.completed => 'Completed',
      };
}

final _deliveryTabProvider =
    StateProvider<_DeliveryTab>((_) => _DeliveryTab.active);

/// In-house delivery dispatch: assign a driver, send them out, mark delivered.
///
/// Driver records, delivery areas and settlement live in the web console —
/// this screen only operates on what the cloud sends down.
class DispatchScreen extends ConsumerWidget {
  const DispatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(_deliveryTabProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DeliveryHeader(tab: tab),
        Expanded(
          child: _DeliveryBody(tab: tab),
        ),
      ],
    );
  }
}

class _DeliveryHeader extends ConsumerWidget {
  final _DeliveryTab tab;
  const _DeliveryHeader({required this.tab});

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
            'Dispatch',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(width: 16),
          ..._DeliveryTab.values.map((t) => _TabChip(tab: t, selected: tab)),
          const Spacer(),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('New Delivery'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              textStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends ConsumerWidget {
  final _DeliveryTab tab;
  final _DeliveryTab selected;
  const _TabChip({required this.tab, required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = tab == selected;
    return GestureDetector(
      onTap: () => ref.read(_deliveryTabProvider.notifier).state = tab,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryFixed : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.outlineVariant,
          ),
        ),
        child: Text(
          tab.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppColors.primary : AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}

class _DeliveryBody extends StatelessWidget {
  final _DeliveryTab tab;
  const _DeliveryBody({required this.tab});

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
            'No ${tab.label.toLowerCase()} deliveries',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Delivery orders will appear here',
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
