import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'p3_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p4_completion_receipts', (tester) async {
    await openDiscoveryHome(tester);

    await tapDiscoveryKey(tester, 'p3_feed_card_content_solar_001');
    await tester.tap(find.byKey(const ValueKey('p4_complete_button')));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('p4_playback_receipt')), findsOneWidget);
    expect(find.byKey(const ValueKey('p4_ad_receipt')), findsOneWidget);
  });
}
