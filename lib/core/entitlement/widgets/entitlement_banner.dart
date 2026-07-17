import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/constants/app_colors.dart';
import 'package:easycasher/core/entitlement/entitlement.dart';
import 'package:easycasher/core/entitlement/entitlement_provider.dart';

/// A thin strip across the top of the terminal that surfaces subscription
/// state. Silent while everything is fine (active/unknown); speaks up as
/// expiry approaches, through grace, and once locked.
class EntitlementBanner extends ConsumerWidget {
  const EntitlementBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(entitlementProvider);

    final (String? message, Color color, IconData icon) = switch (e.level) {
      EntitlementLevel.active => (null, Colors.transparent, Icons.check),
      EntitlementLevel.warning => (
          'Subscription ends in ${e.daysUntilExpiry ?? 0} day(s). Renew to avoid interruption.',
          const Color(0xFFB45309),
          Icons.schedule_rounded,
        ),
      EntitlementLevel.grace => (
          'Subscription expired — ${e.graceDaysLeft ?? 0} day(s) of grace left. Renew now to keep taking orders.',
          const Color(0xFFB45309),
          Icons.warning_amber_rounded,
        ),
      EntitlementLevel.locked => (
          'Subscription expired. New orders are blocked — settle open checks and close the shift, then renew to resume.',
          AppColors.danger,
          Icons.lock_rounded,
        ),
    };

    if (message == null) return const SizedBox.shrink();

    return Material(
      color: color,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (e.clockSuspect) ...[
              const SizedBox(width: 10),
              const Tooltip(
                message:
                    'This device\'s clock is behind the server. Subscription '
                    'time is measured from the server, not this clock.',
                child: Icon(Icons.access_time_rounded,
                    size: 15, color: Colors.white70),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
