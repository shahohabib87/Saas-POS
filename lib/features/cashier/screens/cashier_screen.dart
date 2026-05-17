import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/constants/app_colors.dart';
import 'package:easycasher/features/cashier/providers/cashier_provider.dart';
import 'package:easycasher/features/cashier/widgets/category_tab_bar.dart';
import 'package:easycasher/features/cashier/widgets/menu_grid.dart';
import 'package:easycasher/features/cashier/widgets/cart_panel.dart';
import 'package:easycasher/features/cashier/widgets/cashier_sidebar.dart';
import 'package:easycasher/features/cashier/widgets/cashier_search_bar.dart';
import 'package:easycasher/features/kitchen/screens/kds_screen.dart';
import 'package:easycasher/features/orders/screens/orders_screen.dart';
import 'package:easycasher/features/tables/providers/tables_provider.dart';
import 'package:easycasher/features/tables/screens/tables_screen.dart';

class CashierScreen extends ConsumerWidget {
  const CashierScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderType = ref.watch(orderTypeProvider);
    final activeTable = ref.watch(activeTableProvider);
    final appView = ref.watch(appViewProvider);

    final showKds     = appView == AppView.kds;
    final showOrders  = appView == AppView.orders;
    final showTablesMap =
        !showKds && !showOrders && orderType == OrderType.dineIn && activeTable == null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const CashierSidebar(),
          Expanded(
            child: showKds
                ? const KdsScreen()
                : showOrders
                    ? const OrdersScreen()
                    : Column(
                        children: [
                          const _TopHeader(),
                          Expanded(
                            child: showTablesMap
                                ? const TablesScreen()
                                : const Row(
                                    children: [
                                      Expanded(child: _MenuSection()),
                                      _VerticalDivider(),
                                      SizedBox(width: 380, child: CartPanel()),
                                    ],
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

class _MenuSection extends StatelessWidget {
  const _MenuSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),
        CashierSearchBar(),
        SizedBox(height: 12),
        CategoryTabBar(),
        SizedBox(height: 4),
        Expanded(child: MenuGrid()),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, color: AppColors.outlineVariant);
  }
}

class _TopHeader extends ConsumerWidget {
  const _TopHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartCountProvider);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Menu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(width: 10),
          if (cartCount > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryFixed,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$cartCount in cart',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primaryFixed,
                  child: Icon(Icons.person_rounded,
                      size: 14, color: AppColors.primary),
                ),
                SizedBox(width: 6),
                Text(
                  'Cashier',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w500,
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
