import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'p3_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p6_membership_purchase', (tester) async {
    await openDiscoveryHome(tester);
    await tapDiscoveryKey(tester, 'p6_open_wallet_button');

    await tapDiscoveryKey(tester, 'p6_buy_membership_button');
    await tester.tap(find.byKey(const ValueKey('p6_confirm_purchase_button')));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(find.text('Solar Supporter'), findsOneWidget);
    expect(
      find.textContaining('Solar Sarah membership at \$7.99'),
      findsOneWidget,
    );
    await findDiscoveryKey(tester, 'p6_latest_purchase_receipt');
  });
}
