import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'p3_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p4_follow_unfollow_block', (tester) async {
    await openDiscoveryHome(tester);

    await tapDiscoveryKey(
      tester,
      'p4_open_channel_creator_solar_sarah_content_solar_001',
    );

    expect(find.byKey(const ValueKey('p4_channel_home')), findsOneWidget);
    await tapDiscoveryKey(tester, 'p4_follow_button');
    expect(find.byKey(const ValueKey('p4_unfollow_button')), findsOneWidget);
    await tapDiscoveryKey(tester, 'p4_unfollow_button');
    expect(find.byKey(const ValueKey('p4_follow_button')), findsOneWidget);
    await tapDiscoveryKey(tester, 'p4_block_button');
    expect(find.byKey(const ValueKey('p4_blocked_state')), findsOneWidget);
  });
}
