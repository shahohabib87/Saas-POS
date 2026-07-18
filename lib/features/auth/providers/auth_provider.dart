import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/database/app_database.dart';
import 'package:easycasher/core/database/database_provider.dart';
import 'package:easycasher/features/auth/models/app_permission.dart';
import 'package:easycasher/features/auth/models/staff.dart';

enum LoginError { wrongPin, notFound }

class AuthState {
  final Staff? staff;
  final LoginError? error;

  const AuthState({this.staff, this.error});

  bool get isLoggedIn => staff != null;

  AuthState copyWith({Staff? staff, LoginError? error}) => AuthState(
        staff: staff ?? this.staff,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  bool login(Staff selectedStaff, String enteredPin) {
    if (enteredPin == selectedStaff.pin) {
      state = AuthState(staff: selectedStaff);
      return true;
    }
    state = AuthState(error: LoginError.wrongPin);
    return false;
  }

  void clearError() {
    state = AuthState(staff: state.staff);
  }

  void logout() {
    state = const AuthState();
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

final currentStaffProvider = Provider<Staff?>(
  (ref) => ref.watch(authProvider).staff,
);

// ── Role permissions ──────────────────────────────────────────────────────────

class RolePermissionsNotifier
    extends StateNotifier<Map<StaffRole, Set<AppPermission>>> {
  final AppDatabase _db;

  RolePermissionsNotifier(this._db)
      : super({for (final r in StaffRole.values) r: {}}) {
    _load();
  }

  Future<void> _load() async {
    final perms = await _db.getRolePermissions();
    if (!mounted) return; // sync may invalidate/dispose us mid-load
    state = perms;
  }

  void setPermission(StaffRole role, AppPermission perm, bool enabled) {
    if (role == StaffRole.admin) return;
    final updated = Map<StaffRole, Set<AppPermission>>.from(state);
    final perms = Set<AppPermission>.from(updated[role] ?? {});
    enabled ? perms.add(perm) : perms.remove(perm);
    updated[role] = perms;
    state = updated;
    _db.setRolePermission(role, perm, enabled);
  }
}

final rolePermissionsProvider = StateNotifierProvider<RolePermissionsNotifier,
    Map<StaffRole, Set<AppPermission>>>(
  (ref) => RolePermissionsNotifier(ref.watch(appDatabaseProvider)),
);

final currentPermissionsProvider = Provider<Set<AppPermission>>((ref) {
  final staff = ref.watch(currentStaffProvider);
  if (staff == null) return {};
  final rolePerms = ref.watch(rolePermissionsProvider);
  return rolePerms[staff.role] ?? {};
});
