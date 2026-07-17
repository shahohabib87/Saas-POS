import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/database/app_database.dart';
import 'package:easycasher/core/database/database_provider.dart';
import 'package:easycasher/features/auth/models/staff.dart';

/// The shift open on this terminal, or null when the drawer is closed.
class ShiftNotifier extends StateNotifier<ShiftRow?> {
  final AppDatabase _db;
  final Ref _ref;

  ShiftNotifier(this._db, this._ref) : super(null) {
    _load();
  }

  Future<void> _load() async {
    state = await _db.getOpenShift();
  }

  /// Reload from disk. A shift outlives a login — the cashier who opened it
  /// may have signed out and handed the terminal over.
  Future<void> refresh() => _load();

  Future<void> open({required Staff staff, required double openingFloat}) async {
    state = await _db.openShift(
      staffId: staff.id,
      staffName: staff.name,
      openingFloat: openingFloat,
    );
  }

  Future<void> addCash({
    required bool isIn,
    required double amount,
    required String reason,
    required String staffName,
  }) async {
    final shift = state;
    if (shift == null) return;
    await _db.addCashMovement(
      shiftId: shift.id,
      isIn: isIn,
      amount: amount,
      reason: reason,
      staffName: staffName,
    );
    // The shift row itself is unchanged, so there is no new state to publish —
    // the derived summary is what moved.
    _ref.invalidate(shiftSummaryProvider);
  }

  Future<void> close({
    required double countedCash,
    required double expectedCash,
    String note = '',
  }) async {
    final shift = state;
    if (shift == null) return;
    await _db.closeShift(
      shiftId: shift.id,
      countedCash: countedCash,
      expectedCash: expectedCash,
      note: note,
    );
    state = null;
  }
}

final shiftProvider = StateNotifierProvider<ShiftNotifier, ShiftRow?>((ref) {
  return ShiftNotifier(ref.watch(appDatabaseProvider), ref);
});

/// Everything the shift screen needs, recomputed together so the figures on
/// screen can never disagree with each other.
class ShiftSummary {
  final ShiftTakings takings;
  final List<CashMovementRow> movements;
  final double cashIn;
  final double cashOut;
  final double openingFloat;

  const ShiftSummary({
    required this.takings,
    required this.movements,
    required this.cashIn,
    required this.cashOut,
    required this.openingFloat,
  });

  /// What the drawer should physically contain right now.
  double get expectedCash =>
      openingFloat + takings.cashSales + cashIn - cashOut;
}

final shiftSummaryProvider = FutureProvider<ShiftSummary?>((ref) async {
  final shift = ref.watch(shiftProvider);
  if (shift == null) return null;

  final db = ref.watch(appDatabaseProvider);
  final takings = await db.getShiftTakings(openedAt: shift.openedAt);
  final movements = await db.getCashMovements(shift.id);

  var cashIn = 0.0, cashOut = 0.0;
  for (final m in movements) {
    if (m.kind == 'in') {
      cashIn += m.amount;
    } else {
      cashOut += m.amount;
    }
  }

  return ShiftSummary(
    takings: takings,
    movements: movements,
    cashIn: cashIn,
    cashOut: cashOut,
    openingFloat: shift.openingFloat,
  );
});
