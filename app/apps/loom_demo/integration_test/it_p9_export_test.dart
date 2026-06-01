import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'p3_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p9_export', (tester) async {
    await openDiscoveryHome(tester);

    await tester.tap(find.text('Creator Studio'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('p9_open_export_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('p9_export_screen')), findsOneWidget);
    await tapDiscoveryKey(tester, 'p9_create_export_button');

    expect(find.byKey(const ValueKey('p9_export_complete')), findsOneWidget);
    await findDiscoveryKey(tester, 'p9_export_bundle_summary');
    await tapDiscoveryKey(tester, 'p9_open_bundle_button');
    expect(find.byKey(const ValueKey('p9_export_bundle_json')), findsOneWidget);
  });
}
