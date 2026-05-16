import 'package:flutter/material.dart';
import 'package:easycasher/core/constants/app_colors.dart';
import 'package:easycasher/features/cashier/models/cart_item.dart';
import 'package:easycasher/features/cashier/models/menu_item.dart';
import 'package:easycasher/features/cashier/models/modifier.dart';

class ModifierDialog extends StatefulWidget {
  final MenuItem item;
  final void Function(CartItem) onAdd;

  const ModifierDialog({
    super.key,
    required this.item,
    required this.onAdd,
  });

  @override
  State<ModifierDialog> createState() => _ModifierDialogState();
}

class _ModifierDialogState extends State<ModifierDialog> {
  ModifierOption? _selectedVariation;
  final Set<String> _selectedToppingIds = {};

  @override
  void initState() {
    super.initState();
    final varGroup = widget.item.modifierGroups
        .where((g) => !g.multiSelect)
        .firstOrNull;
    if (varGroup != null && varGroup.options.isNotEmpty) {
      _selectedVariation = varGroup.options.first;
    }
  }

  double get _totalPrice {
    final base = _selectedVariation?.price ?? widget.item.price;
    final toppings = widget.item.modifierGroups
        .where((g) => g.multiSelect)
        .expand((g) => g.options)
        .where((o) => _selectedToppingIds.contains(o.id))
        .fold(0.0, (s, o) => s + o.price);
    return base + toppings;
  }

  List<ModifierOption> get _selectedToppings => widget.item.modifierGroups
      .where((g) => g.multiSelect)
      .expand((g) => g.options)
      .where((o) => _selectedToppingIds.contains(o.id))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(name: widget.item.name),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final group in widget.item.modifierGroups) ...[
                      Text(
                        group.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: group.options.map((option) {
                          final isSelected = group.multiSelect
                              ? _selectedToppingIds.contains(option.id)
                              : _selectedVariation?.id == option.id;
                          final selectedColor = group.multiSelect
                              ? AppColors.blueAccent
                              : AppColors.success;
                          return _OptionChip(
                            option: option,
                            isSelected: isSelected,
                            selectedColor: selectedColor,
                            onTap: () => setState(() {
                              if (group.multiSelect) {
                                _selectedToppingIds.contains(option.id)
                                    ? _selectedToppingIds.remove(option.id)
                                    : _selectedToppingIds.add(option.id);
                              } else {
                                _selectedVariation = option;
                              }
                            }),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            _Footer(
              totalPrice: _totalPrice,
              onCancel: () => Navigator.pop(context),
              onAdd: () {
                widget.onAdd(CartItem(
                  item: widget.item,
                  quantity: 1,
                  selectedVariation: _selectedVariation,
                  selectedToppings: _selectedToppings,
                ));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  const _Header({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final ModifierOption option;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _OptionChip({
    required this.option,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? selectedColor : AppColors.divider,
          ),
        ),
        child: Column(
          children: [
            Text(
              option.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'IQD ${option.price.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white70 : AppColors.textMid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final double totalPrice;
  final VoidCallback onCancel;
  final VoidCallback onAdd;

  const _Footer({
    required this.totalPrice,
    required this.onCancel,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            'IQD ${totalPrice.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onCancel,
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMid)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Add to Order',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
