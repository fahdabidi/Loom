import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'p3_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p9_reset_demo', (tester) async {
    await openDiscoveryHome(tester);

    await tester.tap(find.text('Creator Studio'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('p9_open_export_button')));
    await tester.pumpAndSettle();
    await tapDiscoveryKey(tester, 'p9_create_export_button');
    expect(find.byKey(const ValueKey('p9_export_complete')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('p9_demo_menu_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('p9_reset_demo_menu_item')));
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    expect(find.text('Demo reset to seed v1'), findsOneWidget);
    expect(find.byKey(const ValueKey('p3_session_disclosure')), findsOneWidget);
    expect(find.byKey(const ValueKey('p9_export_screen')), findsNothing);
  });
}
