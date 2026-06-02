import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_demo/main.dart';

import 'p1_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p1_FE-W1', (tester) async {
    await tester.pumpWidget(await buildLoomDemoAppForTest());
    await tester.pumpAndSettle();

    await startFanOnboarding(tester);
    await completeFanOnboarding(tester);

    expect(find.text('Fan onboarding complete'), findsOneWidget);
    expect(find.text('Following 4 starter creators'), findsOneWidget);
    expect(find.text('Visibility: Private'), findsOneWidget);
  });
}
