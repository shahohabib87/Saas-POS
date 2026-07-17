import 'package:easycasher/features/auth/models/staff.dart';

/// What a staff member may do *on this terminal*.
///
/// The terminal only operates — it never manages. Catalog, staff, table and
/// driver records, reporting and business settings live in the web console,
/// so there are deliberately no `*Management` permissions here. Retired
/// values (menuManagement, tableManagement, reports) may still exist in old
/// `role_perms` rows; `getRolePermissions()` skips names it doesn't know.
enum AppPermission {
  tables,
  takeout,
  delivery,
  orders,
  onlineOrders,
  kitchenDisplay,
  dispatch,
  shift,
  settings,
}

extension AppPermissionX on AppPermission {
  String get label => switch (this) {
        AppPermission.tables         => 'Tables',
        AppPermission.takeout        => 'Takeout',
        AppPermission.delivery       => 'Delivery (Order Type)',
        AppPermission.orders         => 'Orders',
        AppPermission.onlineOrders   => 'Online Orders',
        AppPermission.kitchenDisplay => 'Kitchen Display',
        AppPermission.dispatch       => 'Dispatch',
        AppPermission.shift          => 'Shift',
        AppPermission.settings       => 'Device Settings',
      };

  String get description => switch (this) {
        AppPermission.tables         => 'Access dine-in table management',
        AppPermission.takeout        => 'Create and manage takeout orders',
        AppPermission.delivery       => 'Manage in-house delivery orders',
        AppPermission.orders         => 'View all orders list',
        AppPermission.onlineOrders   => 'Accept and reject incoming online orders',
        AppPermission.kitchenDisplay => 'View the kitchen display screen',
        AppPermission.dispatch       => 'Assign drivers and dispatch deliveries',
        AppPermission.shift          => 'Open and close shifts, count the drawer',
        AppPermission.settings       => 'Change this device\'s settings',
      };
}

const kDefaultRolePermissions = <StaffRole, Set<AppPermission>>{
  StaffRole.admin: {
    AppPermission.tables,
    AppPermission.takeout,
    AppPermission.delivery,
    AppPermission.orders,
    AppPermission.onlineOrders,
    AppPermission.kitchenDisplay,
    AppPermission.dispatch,
    AppPermission.shift,
    AppPermission.settings,
  },
  StaffRole.manager: {
    AppPermission.tables,
    AppPermission.takeout,
    AppPermission.delivery,
    AppPermission.orders,
    AppPermission.onlineOrders,
    AppPermission.kitchenDisplay,
    AppPermission.dispatch,
    AppPermission.shift,
    AppPermission.settings,
  },
  StaffRole.cashier: {
    AppPermission.tables,
    AppPermission.takeout,
    AppPermission.delivery,
    AppPermission.orders,
    AppPermission.onlineOrders,
    AppPermission.shift,
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
