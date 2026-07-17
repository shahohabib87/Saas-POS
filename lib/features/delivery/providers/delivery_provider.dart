import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/database/app_database.dart';
import 'package:easycasher/core/database/database_provider.dart';
import 'package:easycasher/features/delivery/models/driver.dart';

/// Drivers, areas and the customer book are mirrors of cloud tables, kept in
/// SQLite so the till still takes a delivery order with no internet. Nothing
/// here writes back: the server creates customers from the delivery orders it
/// receives, and drivers/areas are managed in the web console.

/// Drivers available to assign. Empty until the first cloud pull — a terminal
/// that has never synced has no drivers, which is correct rather than an error.
final driversProvider = FutureProvider<List<Driver>>((ref) async {
  final rows = await ref.watch(appDatabaseProvider).getDrivers();
  return [
    for (final r in rows)
      Driver(id: r.id, name: r.name, phone: r.phone, active: r.active),
  ];
});

final deliveryAreasProvider = FutureProvider<List<DeliveryArea>>((ref) async {
  final rows = await ref.watch(appDatabaseProvider).getDeliveryAreas();
  return [
    for (final r in rows) DeliveryArea(id: r.id, name: r.name, fee: r.fee),
  ];
});

/// Look a customer up by phone. Local and indexed, so it answers instantly and
/// works offline — which is the entire reason the book is mirrored here.
final customerByPhoneProvider =
    FutureProvider.family<CustomerRow?, String>((ref, phone) async {
  return ref.watch(appDatabaseProvider).findCustomerByPhone(phone);
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
  final AppDatabase _db;

  DeliveryDetailsNotifier(this._db) : super(const DeliveryDetails());

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

  /// Fill in a returning caller from the local book. Returns the customer if
  /// one was found, so the UI can say so.
  ///
  /// Only ever fills blanks — a cashier who has already typed something is
  /// correcting the record, and a stale mirror must not overwrite them.
  Future<CustomerRow?> autofillFromPhone(
    String phone,
    List<DeliveryArea> areas,
  ) async {
    final customer = await _db.findCustomerByPhone(phone);
    if (customer == null) return null;

    final area = customer.areaId == null
        ? null
        : areas.where((a) => a.id == customer.areaId).firstOrNull;

    state = DeliveryDetails(
      phone: state.phone,
      customerName:
          state.customerName.isEmpty ? customer.name : state.customerName,
      driverId: state.driverId,
      areaId: state.areaId ?? area?.id,
      areaFee: state.areaId == null ? (area?.fee ?? 0) : state.areaFee,
      notes: state.notes.isEmpty ? customer.directions : state.notes,
    );
    return customer;
  }

  void clear() => state = const DeliveryDetails();
}

final deliveryDetailsProvider =
    StateNotifierProvider<DeliveryDetailsNotifier, DeliveryDetails>(
  (ref) => DeliveryDetailsNotifier(ref.watch(appDatabaseProvider)),
);

/// The delivery fee currently applying to the cart — zero unless the order is
/// a delivery to a chargeable area.
final deliveryFeeProvider = Provider<double>((ref) {
  return ref.watch(deliveryDetailsProvider).areaFee;
});
