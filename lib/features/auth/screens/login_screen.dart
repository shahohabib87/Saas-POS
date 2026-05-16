import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/constants/app_colors.dart';
import 'package:easycasher/features/auth/models/staff.dart';
import 'package:easycasher/features/auth/providers/auth_provider.dart';
import 'package:easycasher/features/auth/widgets/pin_pad.dart';
import 'package:easycasher/features/auth/widgets/staff_card.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  Staff? _selected;

  void _onStaffTap(Staff staff) {
    setState(() => _selected = staff);
    ref.read(authProvider.notifier).clearError();
  }

  void _onPinComplete(String pin) {
    if (_selected == null) return;
    ref.read(authProvider.notifier).login(_selected!, pin);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final hasError = authState.error == LoginError.wrongPin;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Left — branding
          Container(
            width: 340,
            color: AppColors.sidebar,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.point_of_sale_rounded,
                    color: Colors.white, size: 56),
                SizedBox(height: 16),
                Text(
                  'EasyCasher',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'POS System',
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                ),
              ],
            ),
          ),
          // Right — staff selection + PIN
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Who is working today?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Select your profile then enter your PIN',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Staff grid
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: kDemoStaff
                          .map((s) => SizedBox(
                                width: 120,
                                child: StaffCard(
                                  staff: s,
                                  isSelected: _selected?.id == s.id,
                                  onTap: () => _onStaffTap(s),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 36),
                    // PIN section
                    AnimatedOpacity(
                      opacity: _selected != null ? 1.0 : 0.3,
                      duration: const Duration(milliseconds: 200),
                      child: Column(
                        children: [
                          Text(
                            _selected != null
                                ? 'Enter PIN for ${_selected!.name}'
                                : 'Select a profile above',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 20),
                          PinPad(
                            onComplete: _onPinComplete,
                            hasError: hasError,
                            onErrorClear: () =>
                                ref.read(authProvider.notifier).clearError(),
                          ),
                          if (hasError) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'Incorrect PIN. Try again.',
                              style: TextStyle(
                                color: AppColors.danger,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
