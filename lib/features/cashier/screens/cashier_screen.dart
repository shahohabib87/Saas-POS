import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/constants/app_colors.dart';
import 'package:easycasher/features/auth/providers/auth_provider.dart';
import 'package:easycasher/core/entitlement/widgets/entitlement_banner.dart';
import 'package:easycasher/features/cashier/providers/cashier_provider.dart';
import 'package:easycasher/features/cashier/widgets/category_tab_bar.dart';
import 'package:easycasher/features/cashier/widgets/menu_grid.dart';
import 'package:easycasher/features/cashier/widgets/cart_panel.dart';
import 'package:easycasher/features/cashier/widgets/cashier_sidebar.dart';
import 'package:easycasher/features/cashier/widgets/cashier_search_bar.dart';
import 'package:easycasher/features/kitchen/screens/kds_screen.dart';
import 'package:easycasher/features/orders/screens/orders_screen.dart';
import 'package:easycasher/features/delivery/screens/dispatch_screen.dart';
import 'package:easycasher/features/online_orders/screens/online_orders_screen.dart';
import 'package:easycasher/features/settings/screens/settings_screen.dart';
import 'package:easycasher/features/shift/screens/shift_screen.dart';
import 'package:easycasher/features/tables/providers/tables_provider.dart';
import 'package:easycasher/features/tables/screens/tables_screen.dart';

class CashierScreen extends ConsumerWidget {
  const CashierScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderType = ref.watch(orderTypeProvider);
    final activeTable = ref.watch(activeTableProvider);
    final appView = ref.watch(appViewProvider);

    // Dine-in with no table picked yet shows the floor plan instead of the till.
    final showTablesMap =
        orderType == OrderType.dineIn && activeTable == null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const EntitlementBanner(),
          Expanded(
            child: Row(
        children: [
          const CashierSidebar(),
          Expanded(
            child: switch (appView) {
              AppView.kds          => const KdsScreen(),
              AppView.orders       => const OrdersScreen(),
              AppView.onlineOrders => const OnlineOrdersScreen(),
              AppView.dispatch     => const DispatchScreen(),
              AppView.shift        => const ShiftScreen(),
              AppView.settings     => const SettingsScreen(),
              AppView.pos => Column(
                  children: [
                    _TopHeader(
                      title: showTablesMap ? 'Tables' : 'Menu',
                    ),
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
            },
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
  final String title;
  const _TopHeader({required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartCountProvider);
    final staff = ref.watch(currentStaffProvider);

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
          Text(
            title,
            style: const TextStyle(
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
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primaryFixed,
                  child: Icon(Icons.person_rounded,
                      size: 14, color: AppColors.primary),
                ),
                const SizedBox(width: 6),
                Text(
                  staff?.name ?? 'Signed out',
                  style: const TextStyle(
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
