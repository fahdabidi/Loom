import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p6_revenue_by_intent', (tester) async {
    await tester.pumpWidget(await buildLoomDemoAppForTest());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Creator Studio'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('p6_open_revenue_dashboard_button')),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('p6_revenue_dashboard')), findsOneWidget);
    expect(find.byKey(const ValueKey('p6_revenue_by_source')), findsOneWidget);
    expect(find.byKey(const ValueKey('p6_revenue_by_intent')), findsOneWidget);
    expect(find.text('Support'), findsWidgets);
  });
}
