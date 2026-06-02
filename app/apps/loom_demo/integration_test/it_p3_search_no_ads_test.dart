import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'p3_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p3_search_no_ads', (tester) async {
    await openDiscoveryHome(tester);

    await tester.tap(find.byKey(const ValueKey('shell_search_button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('p3_search_field')),
      'kimchi',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('p3_search_no_ads_label')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('p3_search_result_content_ferment_001')),
      findsOneWidget,
    );
  });
}
