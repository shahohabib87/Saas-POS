class AppConstants {
  AppConstants._();

  // Tax is no longer a constant — it comes from the tenant's Settings via
  // `taxMultiplierProvider` (a hardcoded 0 here silently disabled tax app-wide).
  static const String currencySymbol = 'IQD';
}
