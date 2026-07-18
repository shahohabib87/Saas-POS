import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/app/app.dart';
import 'package:easycasher/core/database/app_database.dart';
import 'package:easycasher/core/database/database_provider.dart';
import 'package:easycasher/core/sync/cloud_sync.dart';
import 'package:easycasher/features/kitchen/providers/kitchen_link_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final db = AppDatabase.forTesting();
    await db.seedIfEmpty();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        // The app boots the LAN kitchen link, whose till side binds a real
        // network port — which pops the Windows Firewall dialog naming
        // flutter_tester. A KDS-mode notifier with no address does nothing.
        kitchenLinkProvider.overrideWith(
            (ref) => KitchenLinkNotifier(ref, DeviceMode.kds)),
      ],
      child: const App(),
    ));
    expect(find.text('EasyCasher'), findsOneWidget);
  });
}
