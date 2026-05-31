import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_demo/main.dart';

import 'p1_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p1_FE-S1A', (tester) async {
    await tester.pumpWidget(await buildLoomDemoAppForTest());
    await tester.pumpAndSettle();

    await startFanOnboarding(tester);
    await completeFanOnboarding(tester);

    await tester.tap(
      find.byKey(const ValueKey('fan_toggle_visibility_button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Visibility: Public'), findsOneWidget);
    expect(find.text('Interest batch writes: 1'), findsOneWidget);
  });
}
