/// Local, offline-capable evaluation of a tenant's subscription.
///
/// The server is the authority (`Tenant::hasActiveAccess()` + the 402 gate on
/// /api/sync), but an offline-first till cannot phone home on every sale, so it
/// carries the last-known subscription state and judges it locally. This mirror
/// is deliberately never MORE permissive than the server: it only ever decides
/// to restrict, never to grant beyond what the server last said.
///
/// The whole reason this exists: without it, a tenant who stops paying just
/// unplugs the internet and uses the POS forever.
library;

/// What the terminal should do, given the subscription and the time.
enum EntitlementLevel {
  /// Paid/trialing and not near expiry — no UI, no restriction.
  active,

  /// Still valid but within the warning window — show a countdown banner.
  warning,

  /// Past the expiry date but inside the grace window — still fully usable,
  /// stronger banner. Cushions a late payment or a few days offline.
  grace,

  /// Grace exhausted, or suspended/cancelled — new orders are blocked.
  locked,
}

class Entitlement {
  /// 'trial' | 'active' | 'suspended' | 'cancelled' | 'unknown'.
  final String status;
  final DateTime? trialEndsAt;
  final DateTime? subscriptionEndsAt;
  final String? plan;

  const Entitlement({
    this.status = 'unknown',
    this.trialEndsAt,
    this.subscriptionEndsAt,
    this.plan,
  });

  /// Days before expiry to start warning.
  static const int warnDays = 7;

  /// Days of full operation allowed after expiry before new orders are blocked.
  static const int graceDays = 3;

  /// A tenant we know nothing about yet (never synced). Treated as active so a
  /// fresh install is usable before its first login — the server's 402 gate is
  /// the real backstop the moment it connects.
  bool get isUnknown => status == 'unknown';

  /// The date this tenant's access runs out, by status. Null when the status
  /// itself denies access (suspended/cancelled) or no date was provided.
  DateTime? get effectiveEnd => switch (status) {
        'trial' => trialEndsAt,
        'active' => subscriptionEndsAt,
        _ => null,
      };

  /// Evaluate against a trusted [now] (see clock-tamper handling in the
  /// provider — this method assumes [now] has already been guarded).
  EntitlementLevel levelAt(DateTime now) {
    if (isUnknown) return EntitlementLevel.active;

    // suspended / cancelled — locked regardless of any date.
    if (status != 'trial' && status != 'active') return EntitlementLevel.locked;

    final end = effectiveEnd;
    if (end == null) return EntitlementLevel.locked;

    if (now.isBefore(end)) {
      final daysLeft = end.difference(now).inDays;
      return daysLeft <= warnDays
          ? EntitlementLevel.warning
          : EntitlementLevel.active;
    }

    // Expired — grace, then locked.
    final graceEnd = end.add(const Duration(days: graceDays));
    return now.isBefore(graceEnd)
        ? EntitlementLevel.grace
        : EntitlementLevel.locked;
  }

  /// Whole days until expiry (>= 0), or null if not applicable. For the
  /// "ends in N days" banner.
  int? daysUntilExpiry(DateTime now) {
    final end = effectiveEnd;
    if (end == null || !now.isBefore(end)) return null;
    return end.difference(now).inDays;
  }

  /// Whole days of grace remaining once expired (>= 0), or null. For the
  /// "N days left to renew" banner.
  int? graceDaysLeft(DateTime now) {
    final end = effectiveEnd;
    if (end == null || now.isBefore(end)) return null;
    final graceEnd = end.add(const Duration(days: graceDays));
    if (!now.isBefore(graceEnd)) return 0;
    return graceEnd.difference(now).inDays;
  }

  /// Whether the till may start a NEW order. Everything else — settling open
  /// checks, the Z report, shifts, sync — stays allowed even when locked, so a
  /// lapse never strands a table mid-service.
  bool canStartNewOrder(DateTime now) => levelAt(now) != EntitlementLevel.locked;

  static DateTime? _parseDate(dynamic v) {
    if (v is! String || v.isEmpty) return null;
    return DateTime.tryParse(v)?.toUtc();
  }

  /// Build from a server tenant object (login / 402 body / /me), tolerating
  /// missing fields.
  factory Entitlement.fromTenantJson(Map<String, dynamic> j) => Entitlement(
        status: (j['status'] as String?)?.trim().isNotEmpty == true
            ? j['status'] as String
            : 'unknown',
        trialEndsAt: _parseDate(j['trial_ends_at']),
        subscriptionEndsAt: _parseDate(j['subscription_ends_at']),
        plan: j['plan'] as String?,
      );

  Map<String, String> toKv() => {
        'entitlement_status': status,
        'entitlement_trial_ends': ?trialEndsAt?.toIso8601String(),
        'entitlement_sub_ends': ?subscriptionEndsAt?.toIso8601String(),
        'entitlement_plan': ?plan,
      };

  factory Entitlement.fromKv(Map<String, String?> kv) => Entitlement(
        status: kv['entitlement_status'] ?? 'unknown',
        trialEndsAt: _parseDate(kv['entitlement_trial_ends']),
        subscriptionEndsAt: _parseDate(kv['entitlement_sub_ends']),
        plan: kv['entitlement_plan'],
      );
}
