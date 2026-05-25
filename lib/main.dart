import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/app/app.dart';
import 'package:easycasher/core/database/app_database.dart';
import 'package:easycasher/core/database/database_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  await db.seedIfEmpty();
  runApp(ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
    child: const App(),
  ));
}
