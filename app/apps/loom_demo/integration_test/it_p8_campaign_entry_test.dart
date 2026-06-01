import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'p3_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p8_campaign_entry', (tester) async {
    await openDiscoveryHome(tester);
    await tapDiscoveryKey(tester, 'p8_open_campaigns_button');

    expect(
      find.byKey(const ValueKey('p8_campaign_entry_screen')),
      findsOneWidget,
    );
    await tapDiscoveryKey(tester, 'p8_enter_campaign_button');
    expect(
      find.byKey(const ValueKey('p8_campaign_entry_receipt')),
      findsOneWidget,
    );
    await tapDiscoveryKey(tester, 'p8_issue_reward_button');
    expect(find.byKey(const ValueKey('p8_reward_receipt')), findsOneWidget);
  });
}
