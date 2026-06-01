import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'p3_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p4_ad_supported_playback', (tester) async {
    await openDiscoveryHome(tester);

    await tapDiscoveryKey(tester, 'p3_feed_card_content_solar_001');

    expect(find.byKey(const ValueKey('p4_player_screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('p4_ad_slot')), findsOneWidget);
    expect(find.textContaining('no behavioral targeting'), findsOneWidget);
    expect(find.textContaining('gambling'), findsNothing);
  });
}
