import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p13_catalog_import_console', (tester) async {
    await tester.pumpWidget(await buildLoomDemoAppForTest());
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('p13_open_catalog_import_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('p2_start_import_button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('p13_catalog_import_provenance')),
      findsOneWidget,
    );
    expect(find.text('Imported attic thermal scan'), findsOneWidget);
  });
}
