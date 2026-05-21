enum ServiceMode { fullService, quickService, both }

extension ServiceModeX on ServiceMode {
  String get label => switch (this) {
    ServiceMode.fullService => 'Full Service',
    ServiceMode.quickService => 'Quick Service',
    ServiceMode.both => 'Both',
  };
  String get description => switch (this) {
    ServiceMode.fullService =>
      'Customers sit at a table, order food, and pay when done.',
    ServiceMode.quickService =>
      'Customers order at the counter, pay first, then receive food.',
    ServiceMode.both =>
      'Support both table service and counter orders simultaneously.',
  };
}

class AppSettings {
  final String restaurantName;
  final String restaurantAddress;
  final String restaurantPhone;
  final ServiceMode serviceMode;
  final bool taxEnabled;
  final double taxRate;
  final String receiptFooter;

  const AppSettings({
    this.restaurantName = 'My Restaurant',
    this.restaurantAddress = '',
    this.restaurantPhone = '',
    this.serviceMode = ServiceMode.fullService,
    this.taxEnabled = false,
    this.taxRate = 0.0,
    this.receiptFooter = 'Thank you for your visit! Come back again 😊',
  });

  AppSettings copyWith({
    String? restaurantName,
    String? restaurantAddress,
    String? restaurantPhone,
    ServiceMode? serviceMode,
    bool? taxEnabled,
    double? taxRate,
    String? receiptFooter,
  }) =>
      AppSettings(
        restaurantName: restaurantName ?? this.restaurantName,
        restaurantAddress: restaurantAddress ?? this.restaurantAddress,
        restaurantPhone: restaurantPhone ?? this.restaurantPhone,
        serviceMode: serviceMode ?? this.serviceMode,
        taxEnabled: taxEnabled ?? this.taxEnabled,
        taxRate: taxRate ?? this.taxRate,
        receiptFooter: receiptFooter ?? this.receiptFooter,
      );
}
