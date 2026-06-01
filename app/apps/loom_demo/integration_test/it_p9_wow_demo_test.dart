import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'p3_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p9_wow_demo', (tester) async {
    await openDiscoveryHome(tester);

    await tapDiscoveryKey(tester, 'p3_feed_card_content_solar_001');
    expect(find.byKey(const ValueKey('p4_player_screen')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('p4_playback_back_button')));
    await tester.pumpAndSettle();

    await tapDiscoveryKey(
      tester,
      'p4_open_channel_creator_solar_sarah_content_solar_001',
    );
    await tapDiscoveryKey(tester, 'p5_open_archive_qa_button');
    await tapDiscoveryKey(tester, 'p5_ask_button');
    expect(find.byKey(const ValueKey('p5_answer_card')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('p5_archive_qa_back_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('p4_channel_back_button')));
    await tester.pumpAndSettle();

    await tapDiscoveryKey(tester, 'p8_open_campaigns_button');
    await tapDiscoveryKey(tester, 'p8_enter_campaign_button');
    expect(
      find.byKey(const ValueKey('p8_campaign_entry_receipt')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('p8_campaigns_back_button')));
    await tester.pumpAndSettle();

    await tapDiscoveryKey(tester, 'p6_open_wallet_button');
    expect(
      find.byKey(const ValueKey('p9_supported_creators_view')),
      findsOneWidget,
    );

    await tester.tap(find.text('Creator Studio'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('p9_open_export_button')));
    await tester.pumpAndSettle();
    await tapDiscoveryKey(tester, 'p9_create_export_button');
    expect(find.byKey(const ValueKey('p9_export_complete')), findsOneWidget);
  });
}
