enum StaffRole { waiter, cashier, kitchen, manager }

extension StaffRoleX on StaffRole {
  String get label => switch (this) {
        StaffRole.waiter => 'Waiter',
        StaffRole.cashier => 'Cashier',
        StaffRole.kitchen => 'Kitchen',
        StaffRole.manager => 'Manager',
      };

  bool get canTakeOrders =>
      this == StaffRole.waiter || this == StaffRole.manager;

  bool get canProcessPayment =>
      this == StaffRole.cashier || this == StaffRole.manager;

  bool get canViewKitchen =>
      this == StaffRole.kitchen || this == StaffRole.manager;

  bool get canVoid => this == StaffRole.manager;

  bool get canViewReports => this == StaffRole.manager;
}

class Staff {
  final String id;
  final String name;
  final StaffRole role;
  final String pin;
  final String avatar;

  const Staff({
    required this.id,
    required this.name,
    required this.role,
    required this.pin,
    required this.avatar,
  });
}

// Demo staff — replace with DB in production
const kDemoStaff = <Staff>[
  Staff(id: 's1', name: 'Ahmed',   role: StaffRole.waiter,  pin: '1234', avatar: '👨‍🍳'),
  Staff(id: 's2', name: 'Sara',    role: StaffRole.cashier, pin: '5678', avatar: '👩‍💼'),
  Staff(id: 's3', name: 'Kitchen', role: StaffRole.kitchen, pin: '1111', avatar: '🧑‍🍳'),
  Staff(id: 's4', name: 'Manager', role: StaffRole.manager, pin: '0000', avatar: '👨‍💼'),
];
