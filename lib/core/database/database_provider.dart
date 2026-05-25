import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/database/app_database.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
      'appDatabaseProvider must be overridden in main.dart');
});
