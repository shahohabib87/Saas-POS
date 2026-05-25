import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/constants/app_colors.dart';
import 'package:easycasher/features/auth/models/app_permission.dart';
import 'package:easycasher/features/auth/models/staff.dart';
import 'package:easycasher/features/auth/providers/auth_provider.dart';
import 'package:easycasher/features/cashier/providers/cashier_provider.dart';
import 'package:easycasher/features/kitchen/providers/kitchen_provider.dart';
import 'package:easycasher/features/tables/providers/tables_provider.dart';

class CashierSidebar extends ConsumerWidget {
  const CashierSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderType    = ref.watch(orderTypeProvider);
    final appView      = ref.watch(appViewProvider);
    final pendingKots  = ref.watch(pendingKotCountProvider);
    final permissions  = ref.watch(currentPermissionsProvider);

    final showTables      = permissions.contains(AppPermission.tables);
    final showTakeout     = permissions.contains(AppPermission.takeout);
    final showDelivery    = permissions.contains(AppPermission.delivery);
    final showDeliveryApp = permissions.contains(AppPermission.deliveryApp);
    final showOrders      = permissions.contains(AppPermission.orders);
    final showKds         = permissions.contains(AppPermission.kitchenDisplay);
    final showTalabat     = permissions.contains(AppPermission.talabat);
    final showDeliveryScr = permissions.contains(AppPermission.deliveryScreen);
    final showSettings    = permissions.contains(AppPermission.settings);
    final showMenu        = permissions.contains(AppPermission.menuManagement);
    final showReports     = permissions.contains(AppPermission.reports);

    final hasOrderTypes = showTables || showTakeout || showDelivery || showDeliveryApp;
    final hasScreens    = showOrders || showKds || showTalabat || showDeliveryScr || showSettings || showMenu || showReports;

    return Container(
      width: 220,
      color: AppColors.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SidebarHeader(),
          const SizedBox(height: 16),
          // New Order button — only in POS view
          if (appView == AppView.pos)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(orderCounterProvider.notifier).bump();
                  ref.read(cartProvider.notifier).clear();
                  ref.read(orderNoteProvider.notifier).state = '';
                  ref.read(discountValueProvider.notifier).state = 0;
                },
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('New Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          // ORDER TYPE section
          if (hasOrderTypes) ...[
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                'ORDER TYPE',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 6),
            if (showTables)
              _NavItem(
                icon: Icons.table_restaurant_rounded,
                label: 'Tables',
                type: OrderType.dineIn,
                selected: orderType,
              ),
            if (showTakeout)
              _NavItem(
                icon: Icons.shopping_bag_outlined,
                label: 'Takeout',
                type: OrderType.takeaway,
                selected: orderType,
              ),
            if (showDelivery)
              _NavItem(
                icon: Icons.delivery_dining_rounded,
                label: 'Delivery',
                type: OrderType.delivery,
                selected: orderType,
              ),
            if (showDeliveryApp)
              _NavItem(
                icon: Icons.phone_android_rounded,
                label: 'Delivery App',
                type: OrderType.deliveryApp,
                selected: orderType,
              ),
          ],
          // SCREENS section
          if (hasScreens) ...[
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                'SCREENS',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 6),
            if (showOrders)
              _ViewNavItem(
                icon: Icons.receipt_long_rounded,
                label: 'Orders',
                badge: 0,
                view: AppView.orders,
                selected: appView,
              ),
            if (showKds)
              _ViewNavItem(
                icon: Icons.kitchen_rounded,
                label: 'Kitchen Display',
                badge: pendingKots,
                view: AppView.kds,
                selected: appView,
              ),
            if (showTalabat)
              _ViewNavItem(
                icon: Icons.delivery_dining_rounded,
                label: 'Talabat',
                badge: 0,
                view: AppView.talabat,
                selected: appView,
              ),
            if (showDeliveryScr)
              _ViewNavItem(
                icon: Icons.delivery_dining_rounded,
                label: 'Delivery',
                badge: 0,
                view: AppView.delivery,
                selected: appView,
              ),
            if (showMenu)
              _ViewNavItem(
                icon: Icons.restaurant_menu_rounded,
                label: 'Menu',
                badge: 0,
                view: AppView.menu,
                selected: appView,
              ),
            if (showReports)
              _ViewNavItem(
                icon: Icons.bar_chart_rounded,
                label: 'Reports',
                badge: 0,
                view: AppView.reports,
                selected: appView,
              ),
            if (showSettings)
              _ViewNavItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                badge: 0,
                view: AppView.settings,
                selected: appView,
              ),
          ],
          const Spacer(),
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 0, 14, 20),
            child: _SessionInfo(),
          ),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.point_of_sale_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EasyCasher',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'POS Terminal',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavItem extends ConsumerWidget {
  final IconData icon;
  final String label;
  final OrderType type;
  final OrderType selected;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.type,
    required this.selected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = type == selected;
    return GestureDetector(
      onTap: () {
        ref.read(orderTypeProvider.notifier).state = type;
        ref.read(appViewProvider.notifier).state = AppView.pos;
        if (type == OrderType.dineIn) {
          final activeTable = ref.read(activeTableProvider);
          if (activeTable != null) {
            final currentCart = ref.read(cartProvider);
            final currentNote = ref.read(orderNoteProvider);
            ref.read(savedTableOrdersProvider.notifier).update(
                  (s) => {...s, activeTable.id: currentCart},
                );
            ref.read(savedTableNotesProvider.notifier).update(
                  (s) => {...s, activeTable.id: currentNote},
                );
            ref.read(cartProvider.notifier).clear();
            ref.read(orderNoteProvider.notifier).state = '';
            ref.read(tableNumberProvider.notifier).state = '';
            ref.read(activeTableProvider.notifier).state = null;
          }
        } else {
          ref.read(activeTableProvider.notifier).state = null;
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18,
                color: isSelected ? Colors.white : Colors.white54),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.white60,
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SessionInfo extends ConsumerWidget {
  const _SessionInfo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(currentStaffProvider);
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final date = '${now.day}/${now.month}/${now.year}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                child: Text(
                  staff?.avatar ?? '👤',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff?.name ?? 'Staff',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      staff?.role.label ?? 'Active session',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => ref.read(authProvider.notifier).logout(),
                child: const Icon(Icons.logout_rounded,
                    color: Colors.white38, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$time  •  $date',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _ViewNavItem extends ConsumerWidget {
  final IconData icon;
  final String label;
  final int badge;
  final AppView view;
  final AppView selected;

  const _ViewNavItem({
    required this.icon,
    required this.label,
    required this.badge,
    required this.view,
    required this.selected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = view == selected;
    return GestureDetector(
      onTap: () => ref.read(appViewProvider.notifier).state = view,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18,
                color: isSelected ? Colors.white : Colors.white54),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.white60,
                ),
              ),
            ),
            if (badge > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
