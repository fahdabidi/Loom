import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p14_immersive_discovery', (tester) async {
    await tester.pumpWidget(await buildLoomDemoAppForTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('p14_toggle_immersive_button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('p14_immersive_discovery')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('p14_immersive_card_content_solar_001')),
      findsOneWidget,
    );
  });
}
