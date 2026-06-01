import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'p3_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p7_interest_grant', (tester) async {
    await openDiscoveryHome(tester);
    await tapDiscoveryKey(tester, 'p7_open_data_rights_button');

    expect(find.byKey(const ValueKey('p7_data_rights_screen')), findsOneWidget);
    await tester.tap(find.text('Narrow'));
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();
    expect(find.textContaining('Narrowed grant'), findsOneWidget);

    await tester.tap(find.text('Creator Studio'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('p7_open_audience_button')));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Query approved data'));
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('p7_permissioned_fields')),
      findsOneWidget,
    );
    expect(find.textContaining('Interest categories'), findsWidgets);
    expect(find.textContaining('Approved audience fields'), findsOneWidget);
  });
}
