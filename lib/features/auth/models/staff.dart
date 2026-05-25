enum StaffRole { admin, waiter, cashier, kitchen, manager }

extension StaffRoleX on StaffRole {
  String get label => switch (this) {
        StaffRole.admin   => 'Admin',
        StaffRole.waiter  => 'Waiter',
        StaffRole.cashier => 'Cashier',
        StaffRole.kitchen => 'Kitchen',
        StaffRole.manager => 'Manager',
      };

  bool get canTakeOrders =>
      this == StaffRole.waiter ||
      this == StaffRole.manager ||
      this == StaffRole.admin;

  bool get canProcessPayment =>
      this == StaffRole.cashier ||
      this == StaffRole.manager ||
      this == StaffRole.admin;

  bool get canViewKitchen =>
      this == StaffRole.kitchen ||
      this == StaffRole.manager ||
      this == StaffRole.admin;

  bool get canVoid => this == StaffRole.manager || this == StaffRole.admin;

  bool get canViewReports => this == StaffRole.manager || this == StaffRole.admin;
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

  Staff copyWith({
    String? name,
    StaffRole? role,
    String? pin,
    String? avatar,
  }) =>
      Staff(
        id: id,
        name: name ?? this.name,
        role: role ?? this.role,
        pin: pin ?? this.pin,
        avatar: avatar ?? this.avatar,
      );
}

// Demo staff — replace with DB in production
const kDemoStaff = <Staff>[
  Staff(id: 's0', name: 'Admin',   role: StaffRole.admin,   pin: '9999', avatar: '👨‍💻'),
  Staff(id: 's1', name: 'Ahmed',   role: StaffRole.waiter,  pin: '1234', avatar: '👨‍🍳'),
  Staff(id: 's2', name: 'Sara',    role: StaffRole.cashier, pin: '5678', avatar: '👩‍💼'),
  Staff(id: 's3', name: 'Kitchen', role: StaffRole.kitchen, pin: '1111', avatar: '🧑‍🍳'),
  Staff(id: 's4', name: 'Manager', role: StaffRole.manager, pin: '0000', avatar: '👨‍💼'),
];
