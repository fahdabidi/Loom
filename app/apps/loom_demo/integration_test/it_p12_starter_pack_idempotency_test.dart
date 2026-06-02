import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p12_starter_pack_idempotency', (tester) async {
    await tester.pumpWidget(await buildLoomDemoAppForTest());
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('p12_open_capture_link_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('p12_follow_selected_button')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('p12_open_capture_link_button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('You already follow this creator'), findsOneWidget);
    expect(find.text('Already following'), findsWidgets);
  });
}
