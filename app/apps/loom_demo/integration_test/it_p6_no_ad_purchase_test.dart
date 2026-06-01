import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'p3_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p6_no_ad_purchase', (tester) async {
    await openDiscoveryHome(tester);
    await tapDiscoveryKey(tester, 'p6_open_wallet_button');

    expect(find.byKey(const ValueKey('p6_wallet_screen')), findsOneWidget);
    await tapDiscoveryKey(tester, 'p6_buy_no_ad_button');
    await tester.tap(find.byKey(const ValueKey('p6_confirm_purchase_button')));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(find.textContaining('Ads are skipped'), findsOneWidget);
    await tapDiscoveryKey(tester, 'p6_wallet_back_button');
    await tapDiscoveryKey(tester, 'p3_feed_card_content_solar_001');

    expect(find.byKey(const ValueKey('p4_player_screen')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('p6_no_ad_playback_state')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('p4_ad_slot')), findsNothing);
  });
}
