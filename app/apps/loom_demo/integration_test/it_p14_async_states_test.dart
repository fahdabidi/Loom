import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p14_async_states', (tester) async {
    await tester.pumpWidget(await buildLoomDemoAppForTest());

    expect(find.byKey(const ValueKey('p14_loading_skeleton')), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('p3_discovery_scroll')), findsOneWidget);
  });
}
