import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p13_ad_policy_console', (tester) async {
    await tester.pumpWidget(await buildLoomDemoAppForTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('p13_open_ad_policy_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('p2_save_ad_policy_button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('p13_ad_decision_verification')),
      findsOneWidget,
    );
  });
}
