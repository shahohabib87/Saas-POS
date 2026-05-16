import 'package:flutter_riverpod/flutter_riverpod.dart';
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
