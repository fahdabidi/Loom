import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_demo/main.dart';

void main() {
  testWidgets('Phase 0 app boots with fan content slice', (tester) async {
    await tester.pumpWidget(await buildLoomDemoAppForTest());
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(find.text('Fan App'), findsWidgets);
    expect(
      find.byKey(const ValueKey('p0_recommendation_type_row')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('shell_search_button')), findsOneWidget);
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
    for (
      var attempt = 0;
      attempt < 20 && find.text('Load more').evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(scroll, const Offset(0, -520), warnIfMissed: false);
      await tester.pumpAndSettle();
    }
    expect(find.text('Load more'), findsOneWidget);
  });
}
