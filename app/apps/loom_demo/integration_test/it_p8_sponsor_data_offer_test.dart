import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'p3_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p8_sponsor_data_offer', (tester) async {
    await openDiscoveryHome(tester);
    await tapDiscoveryKey(tester, 'p8_open_campaigns_button');

    expect(
      find.byKey(const ValueKey('p8_campaign_entry_screen')),
      findsOneWidget,
    );
    await tapDiscoveryKey(tester, 'p8_accept_data_offer_button');
    expect(
      find.byKey(const ValueKey('p8_sponsor_data_receipt')),
      findsOneWidget,
    );
    expect(find.textContaining('interest_categories'), findsOneWidget);
  });
}
