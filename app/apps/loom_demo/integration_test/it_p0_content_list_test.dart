import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p0_content_list', (tester) async {
    await tester.pumpWidget(await buildLoomDemoAppForTest());
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    final scroll = find.byKey(const ValueKey('p3_discovery_scroll'));
    for (
      var attempt = 0;
      attempt < 6 && find.text('Solar Sarah').evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(scroll, const Offset(0, -260), warnIfMissed: false);
      await tester.pumpAndSettle();
    }
    expect(find.text('Solar Sarah'), findsWidgets);
    expect(
      find.text('Rooftop storage that actually pencils out'),
      findsWidgets,
    );

    for (
      var attempt = 0;
      attempt < 20 && find.text('Load more').evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(scroll, const Offset(0, -520), warnIfMissed: false);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();

    for (
      var attempt = 0;
      attempt < 8 && find.text('Solar quote red flags').evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(scroll, const Offset(0, -360), warnIfMissed: false);
      await tester.pumpAndSettle();
    }
    expect(find.text('Solar quote red flags'), findsWidgets);
  });
}
