import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'p3_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p7_category_default', (tester) async {
    await openDiscoveryHome(tester);
    await tapDiscoveryKey(tester, 'p7_open_data_rights_button');

    await tapDiscoveryKey(tester, 'p7_category_default_button');

    expect(find.text('Denied'), findsWidgets);
  });
}
