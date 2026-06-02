import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p14_feed_pagination', (tester) async {
    await tester.pumpWidget(await buildLoomDemoAppForTest());
    await tester.pumpAndSettle();

    final firstCard = find.byKey(
      const ValueKey('p3_feed_card_content_solar_001'),
    );
    expect(firstCard, findsOneWidget);

    final loadMore = find.byKey(const ValueKey('p3_load_more_button'));
    await tester.ensureVisible(loadMore);
    await tester.tap(loadMore);
    await tester.pumpAndSettle();

    expect(firstCard, findsOneWidget);
    expect(
      find.byKey(const ValueKey('p3_feed_card_content_ferment_001')),
      findsOneWidget,
    );
  });
}
