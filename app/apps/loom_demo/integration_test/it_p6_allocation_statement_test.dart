import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'p3_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p6_allocation_statement', (tester) async {
    await openDiscoveryHome(tester);
    await tapDiscoveryKey(tester, 'p6_open_wallet_button');

    await tapDiscoveryKey(tester, 'p6_buy_membership_button');
    await tester.tap(find.byKey(const ValueKey('p6_confirm_purchase_button')));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('p6_allocation_statement')),
      findsOneWidget,
    );
    expect(find.text('Solar Sarah'), findsWidgets);
    expect(find.text('\$7.99'), findsWidgets);
  });
}
