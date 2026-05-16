import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/theme/app_theme.dart';
import 'package:easycasher/features/auth/models/staff.dart';
import 'package:easycasher/features/auth/providers/auth_provider.dart';
import 'package:easycasher/features/auth/screens/login_screen.dart';
import 'package:easycasher/features/cashier/screens/cashier_screen.dart';
import 'package:easycasher/features/kitchen/screens/kds_screen.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(currentStaffProvider);

    return MaterialApp(
      title: 'EasyCasher',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: staff == null ? const LoginScreen() : _homeForRole(staff.role),
    );
  }

  Widget _homeForRole(StaffRole role) => switch (role) {
        StaffRole.kitchen => const Scaffold(
            backgroundColor: Color(0xFF0D1117),
            body: KdsScreen(),
          ),
        _ => const CashierScreen(),
      };
}
