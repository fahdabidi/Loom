import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_demo/main.dart';

import 'p1_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p1_interest_coldstart', (tester) async {
    await tester.pumpWidget(await buildLoomDemoAppForTest());
    await tester.pumpAndSettle();

    await startFanOnboarding(tester);
    await completeFanOnboarding(tester);

    expect(find.text('Interests saved: 10'), findsOneWidget);
    expect(find.text('Interest batch writes: 1'), findsOneWidget);
    expect(find.text('Taxonomy fetches: 1'), findsOneWidget);
  });
}
