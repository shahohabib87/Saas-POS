import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/constants/app_colors.dart';
import 'package:easycasher/features/cashier/providers/cashier_provider.dart';

class CashierSearchBar extends ConsumerStatefulWidget {
  const CashierSearchBar({super.key});

  @override
  ConsumerState<CashierSearchBar> createState() => _CashierSearchBarState();
}

class _CashierSearchBarState extends ConsumerState<CashierSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: TextField(
          controller: _controller,
          onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
          decoration: InputDecoration(
            hintText: 'Search menu items...',
            hintStyle:
                const TextStyle(fontSize: 14, color: AppColors.outline),
            prefixIcon: const Icon(Icons.search_rounded,
                size: 18, color: AppColors.outline),
            suffixIcon: _controller.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _controller.clear();
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: AppColors.outline),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          style: const TextStyle(fontSize: 14, color: AppColors.onSurface),
        ),
      ),
    );
  }
}
