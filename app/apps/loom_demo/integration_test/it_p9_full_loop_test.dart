import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'p3_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p9_full_loop', (tester) async {
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
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();
    await tapDiscoveryKey(tester, 'p8_record_discovery_content_ferment_001');
    expect(find.byKey(const ValueKey('p8_discovery_receipt')), findsOneWidget);

    await tapDiscoveryKey(tester, 'p3_feed_card_content_ferment_001');
    expect(find.byKey(const ValueKey('p4_player_screen')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('p4_playback_back_button')));
    await tester.pumpAndSettle();
    await tapDiscoveryKey(tester, 'p6_open_wallet_button');
    await tapDiscoveryKey(tester, 'p6_buy_membership_button');
    await tester.tap(find.byKey(const ValueKey('p6_confirm_purchase_button')));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('p9_supported_creators_view')),
      findsOneWidget,
    );
    expect(find.text('Solar Supporter'), findsOneWidget);
  });
}
