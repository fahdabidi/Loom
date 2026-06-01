import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'p3_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p8_publish_recommendation', (tester) async {
    await openDiscoveryHome(tester);

    await tester.tap(find.text('Creator Studio'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('p8_open_recommendations_button')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('p8_publish_recommendation_button')),
    );
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('p8_recommendation_published')),
      findsOneWidget,
    );

    await tester.tap(find.text('Fan App'));
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    expect(
      await findDiscoveryKey(
        tester,
        'p8_recommendation_disclosure_content_ferment_001',
      ),
      findsOneWidget,
    );
    await tapDiscoveryKey(tester, 'p8_record_discovery_content_ferment_001');
    expect(find.byKey(const ValueKey('p8_discovery_receipt')), findsOneWidget);
  });
}
