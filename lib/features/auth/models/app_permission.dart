import 'package:easycasher/features/auth/models/staff.dart';

enum AppPermission {
  tables,
  takeout,
  delivery,
  deliveryApp,
  orders,
  kitchenDisplay,
  talabat,
  deliveryScreen,
  settings,
  menuManagement,
  tableManagement,
}

extension AppPermissionX on AppPermission {
  String get label => switch (this) {
        AppPermission.tables         => 'Tables',
        AppPermission.takeout        => 'Takeout',
        AppPermission.delivery       => 'Delivery (Order Type)',
        AppPermission.deliveryApp    => 'Delivery App',
        AppPermission.orders         => 'Orders',
        AppPermission.kitchenDisplay => 'Kitchen Display',
        AppPermission.talabat        => 'Talabat',
        AppPermission.deliveryScreen => 'Delivery Screen',
        AppPermission.settings        => 'Settings',
        AppPermission.menuManagement  => 'Menu Management',
        AppPermission.tableManagement => 'Table Management',
      };

  String get description => switch (this) {
        AppPermission.tables         => 'Access dine-in table management',
        AppPermission.takeout        => 'Create and manage takeout orders',
        AppPermission.delivery       => 'Manage in-house delivery orders',
        AppPermission.deliveryApp    => 'Handle third-party delivery app orders',
        AppPermission.orders         => 'View all orders list',
        AppPermission.kitchenDisplay => 'View the kitchen display screen',
        AppPermission.talabat        => 'Manage Talabat integration',
        AppPermission.deliveryScreen => 'View delivery management screen',
        AppPermission.settings       => 'Access app settings',
        AppPermission.menuManagement  => 'Add, edit, and delete menu items',
        AppPermission.tableManagement => 'Add, edit, and delete tables',
      };
}

const kDefaultRolePermissions = <StaffRole, Set<AppPermission>>{
  StaffRole.admin: {
    AppPermission.tables,
    AppPermission.takeout,
    AppPermission.delivery,
    AppPermission.deliveryApp,
    AppPermission.orders,
    AppPermission.kitchenDisplay,
    AppPermission.talabat,
    AppPermission.deliveryScreen,
    AppPermission.settings,
    AppPermission.menuManagement,
    AppPermission.tableManagement,
  },
  StaffRole.manager: {
    AppPermission.tables,
    AppPermission.takeout,
    AppPermission.delivery,
    AppPermission.deliveryApp,
    AppPermission.orders,
    AppPermission.kitchenDisplay,
    AppPermission.talabat,
    AppPermission.deliveryScreen,
    AppPermission.settings,
    AppPermission.menuManagement,
    AppPermission.tableManagement,
  },
  StaffRole.cashier: {
    AppPermission.tables,
    AppPermission.takeout,
    AppPermission.delivery,
    AppPermission.deliveryApp,
    AppPermission.orders,
    AppPermission.settings,
  },
  StaffRole.waiter: {
    AppPermission.tables,
    AppPermission.takeout,
    AppPermission.orders,
  },
  StaffRole.kitchen: {
    AppPermission.kitchenDisplay,
  },
};
