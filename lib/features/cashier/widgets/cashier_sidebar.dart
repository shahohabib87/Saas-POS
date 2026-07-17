import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/constants/app_colors.dart';
import 'package:easycasher/features/auth/models/app_permission.dart';
import 'package:easycasher/features/auth/models/staff.dart';
import 'package:easycasher/features/auth/providers/auth_provider.dart';
import 'package:easycasher/features/cashier/providers/cashier_provider.dart';
import 'package:easycasher/features/kitchen/providers/kitchen_provider.dart';

/// The screen navigation as a persistent left column — always visible, the way
/// the web console keeps its nav in view. The order-type picker no longer lives
/// here (it moved into the cart to match the web POS); this rail just reaches
/// the operational screens (KDS, Orders, Shift, Settings…) the all-in-one
/// terminal still has to run.
class NavSidebar extends ConsumerWidget {
  const NavSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appView      = ref.watch(appViewProvider);
    final pendingKots  = ref.watch(pendingKotCountProvider);
    final permissions  = ref.watch(currentPermissionsProvider);

    final showOrders       = permissions.contains(AppPermission.orders);
    final showOnlineOrders = permissions.contains(AppPermission.onlineOrders);
    final showKds          = permissions.contains(AppPermission.kitchenDisplay);
    final showDispatch     = permissions.contains(AppPermission.dispatch);
    final showShift        = permissions.contains(AppPermission.shift);
    final showSettings     = permissions.contains(AppPermission.settings);

    return Container(
      width: 210,
      color: AppColors.sidebar,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SidebarHeader(),
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
            // Register — the way back to the till from any operational screen.
            _ViewNavItem(
              icon: Icons.point_of_sale_rounded,
              label: 'Register',
              badge: 0,
              view: AppView.pos,
              selected: appView,
            ),
            if (showOrders)
              _ViewNavItem(
                icon: Icons.receipt_long_rounded,
                label: 'Orders',
                badge: 0,
                view: AppView.orders,
                selected: appView,
              ),
            if (showOnlineOrders)
              _ViewNavItem(
                icon: Icons.language_rounded,
                label: 'Online Orders',
                badge: 0,
                view: AppView.onlineOrders,
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
            if (showDispatch)
              _ViewNavItem(
                icon: Icons.moped_rounded,
                label: 'Delivery',
                badge: 0,
                view: AppView.dispatch,
                selected: appView,
              ),
            if (showShift)
              _ViewNavItem(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Shift',
                badge: 0,
                view: AppView.shift,
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
            const Spacer(),
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 0, 14, 20),
              child: _SessionInfo(),
            ),
          ],
        ),
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
