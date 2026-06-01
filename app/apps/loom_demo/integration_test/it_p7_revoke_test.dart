import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'p3_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p7_revoke', (tester) async {
    await openDiscoveryHome(tester);
    await tapDiscoveryKey(tester, 'p7_open_data_rights_button');
    await tester.tap(find.text('Approve'));
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();
    expect(find.textContaining('Approved full grant'), findsOneWidget);

    await tapDiscoveryKey(tester, 'p7_revoke_grant_button');

    expect(find.textContaining('Grant is revoked'), findsOneWidget);
    expect(find.text('Revoked'), findsWidgets);
  });
}
