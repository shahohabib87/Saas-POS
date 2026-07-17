import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/constants/app_colors.dart';
import 'package:easycasher/core/sync/cloud_sync.dart';
import 'package:easycasher/features/auth/providers/auth_provider.dart';
import 'package:easycasher/core/entitlement/widgets/entitlement_banner.dart';
import 'package:easycasher/features/cashier/providers/cashier_provider.dart';
import 'package:easycasher/features/cashier/widgets/category_tab_bar.dart';
import 'package:easycasher/features/cashier/widgets/menu_grid.dart';
import 'package:easycasher/features/cashier/widgets/cart_panel.dart';
import 'package:easycasher/features/cashier/widgets/cashier_sidebar.dart';
import 'package:easycasher/features/kitchen/screens/kds_screen.dart';
import 'package:easycasher/features/orders/screens/orders_screen.dart';
import 'package:easycasher/features/delivery/screens/dispatch_screen.dart';
import 'package:easycasher/features/online_orders/screens/online_orders_screen.dart';
import 'package:easycasher/features/settings/screens/settings_screen.dart';
import 'package:easycasher/features/shift/screens/shift_screen.dart';

/// The terminal shell. The register itself now mirrors the web POS — two
/// panels, menu on the left and cart (with the order-type picker) on the
/// right — while the operational screens live behind the [NavDrawer] opened
/// from the header, standing in for the web's "← Dashboard".
class CashierScreen extends ConsumerWidget {
  const CashierScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appView = ref.watch(appViewProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const EntitlementBanner(),
          Expanded(
            child: Row(
              children: [
                const NavSidebar(),
                Expanded(
                  child: switch (appView) {
                    AppView.pos => const _PosView(),
                    AppView.kds => const KdsScreen(),
                    AppView.orders => const OrdersScreen(),
                    AppView.onlineOrders => const OnlineOrdersScreen(),
                    AppView.dispatch => const DispatchScreen(),
                    AppView.shift => const ShiftScreen(),
                    AppView.settings => const SettingsScreen(),
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

/// The register: web-style two-panel layout, always showing menu + cart so
/// the order-type picker in the cart is always reachable. Seating a dine-in
/// table happens through an overlay (see the cart's "Pick a Table" button),
/// not by taking over the whole screen.
class _PosView extends StatelessWidget {
  const _PosView();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _PosHeader(),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _MenuSection()),
              _VerticalDivider(),
              SizedBox(width: 320, child: CartPanel()),
            ],
          ),
        ),
      ],
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

/// Register header: menu button (opens the [NavDrawer]) · search · online
/// status pill · signed-in staff — the web POS header, one-for-one.
class _PosHeader extends ConsumerWidget {
  const _PosHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(currentStaffProvider);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 4),
          const Expanded(child: _HeaderSearch()),
          const SizedBox(width: 12),
          const _OnlinePill(),
          const SizedBox(width: 14),
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

/// A bordered search box in the header (web-style), driving the same
/// [searchQueryProvider] the grid filters on.
class _HeaderSearch extends ConsumerStatefulWidget {
  const _HeaderSearch();

  @override
  ConsumerState<_HeaderSearch> createState() => _HeaderSearchState();
}

class _HeaderSearchState extends ConsumerState<_HeaderSearch> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(searchQueryProvider));
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: TextField(
        controller: _controller,
        onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
        decoration: InputDecoration(
          hintText: 'Search items…',
          hintStyle: const TextStyle(fontSize: 14, color: AppColors.outline),
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
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        style: const TextStyle(fontSize: 14, color: AppColors.onSurface),
      ),
    );
  }
}

/// Online / offline status with a pending-sync count — the web POS pill.
class _OnlinePill extends ConsumerWidget {
  const _OnlinePill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connected = ref.watch(cloudSyncProvider.select((s) => s.connected));
    final pending = ref.watch(cloudSyncProvider.select((s) => s.pendingSales));

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: connected
                ? AppColors.success.withValues(alpha: 0.12)
                : AppColors.surfaceLow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: connected ? AppColors.success : AppColors.outline,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                connected ? 'Online' : 'Offline',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: connected
                      ? AppColors.success
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (pending > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$pending pending',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

