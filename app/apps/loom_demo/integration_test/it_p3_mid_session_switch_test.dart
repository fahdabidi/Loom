import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'p3_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p3_mid_session_switch', (tester) async {
    await openDiscoveryHome(tester);

    await tapDiscoveryKey(tester, 'p3_startup_tile_intent_learn');

    expect(find.text('Learn feed'), findsOneWidget);
    expect(find.textContaining('Solar storage'), findsWidgets);
  });
}
