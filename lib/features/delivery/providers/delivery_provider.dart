import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/database/database_provider.dart';
import 'package:easycasher/features/delivery/models/driver.dart';

/// Drivers and delivery areas are pulled by the sync engine and cached as raw
/// JSON under these keys (they have no Drift tables of their own yet).
const _kDriversKey = 'cloud_drivers';
const _kAreasKey = 'cloud_delivery_areas';

List<T> _decode<T>(String? raw, T? Function(Map<String, dynamic>) parse) {
  if (raw == null || raw.isEmpty) return const [];
  try {
    final list = jsonDecode(raw);
    if (list is! List) return const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(parse)
        .whereType<T>()
        .toList();
  } on FormatException {
    // Cached JSON is only ever a mirror of the server; if it is unreadable the
    // next pull replaces it. Never take the till down over it.
    return const [];
  }
}

/// Drivers available to assign. Empty until the first cloud pull — a terminal
/// that has never synced has no drivers, which is correct rather than an error.
final driversProvider = FutureProvider<List<Driver>>((ref) async {
  final raw = await ref.watch(appDatabaseProvider).kvGet(_kDriversKey);
  return _decode(raw, Driver.tryFromJson).where((d) => d.active).toList();
});

final deliveryAreasProvider = FutureProvider<List<DeliveryArea>>((ref) async {
  final raw = await ref.watch(appDatabaseProvider).kvGet(_kAreasKey);
  return _decode(raw, DeliveryArea.tryFromJson);
});

/// What the cashier captures for a delivery order, alongside the cart.
class DeliveryDetails {
  final String phone;
  final String customerName;
  final String? driverId;
  final String? areaId;
  final double areaFee;
  final String notes;

  const DeliveryDetails({
    this.phone = '',
    this.customerName = '',
    this.driverId,
    this.areaId,
    this.areaFee = 0,
    this.notes = '',
  });

  /// A delivery needs somewhere to go and someone to take it. The phone is the
  /// only way to reach the customer when the driver cannot find the address.
  bool get isComplete =>
      phone.trim().isNotEmpty && driverId != null && areaId != null;

  DeliveryDetails copyWith({
    String? phone,
    String? customerName,
    String? driverId,
    String? areaId,
    double? areaFee,
    String? notes,
  }) =>
      DeliveryDetails(
        phone: phone ?? this.phone,
        customerName: customerName ?? this.customerName,
        driverId: driverId ?? this.driverId,
        areaId: areaId ?? this.areaId,
        areaFee: areaFee ?? this.areaFee,
        notes: notes ?? this.notes,
      );
}

class DeliveryDetailsNotifier extends StateNotifier<DeliveryDetails> {
  DeliveryDetailsNotifier() : super(const DeliveryDetails());

  void setPhone(String v) => state = state.copyWith(phone: v);
  void setCustomerName(String v) => state = state.copyWith(customerName: v);
  void setNotes(String v) => state = state.copyWith(notes: v);
  void setDriver(String? id) => state = DeliveryDetails(
        phone: state.phone,
        customerName: state.customerName,
        driverId: id,
        areaId: state.areaId,
        areaFee: state.areaFee,
        notes: state.notes,
      );

  void setArea(DeliveryArea? area) => state = DeliveryDetails(
        phone: state.phone,
        customerName: state.customerName,
        driverId: state.driverId,
        areaId: area?.id,
        areaFee: area?.fee ?? 0,
        notes: state.notes,
      );

  void clear() => state = const DeliveryDetails();
}

final deliveryDetailsProvider =
    StateNotifierProvider<DeliveryDetailsNotifier, DeliveryDetails>(
  (ref) => DeliveryDetailsNotifier(),
);

/// The delivery fee currently applying to the cart — zero unless the order is
/// a delivery to a chargeable area.
final deliveryFeeProvider = Provider<double>((ref) {
  return ref.watch(deliveryDetailsProvider).areaFee;
});
