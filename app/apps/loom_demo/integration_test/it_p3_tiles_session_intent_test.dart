import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'p3_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p3_tiles_session_intent', (tester) async {
    await openDiscoveryHome(tester);

    expect(find.textContaining('Recommendation Type: For you'), findsOneWidget);
    await findDiscoveryKey(tester, 'p3_session_disclosure');
    expect(find.text('Paid placement'), findsWidgets);

    await tapDiscoveryKey(tester, 'p3_startup_tile_intent_learn');
    expect(find.text('Learn feed'), findsOneWidget);

    await tapDiscoveryKey(tester, 'p3_startup_tile_intent_for_you');
    expect(find.text('For you feed'), findsOneWidget);

    await tapDiscoveryKey(tester, 'p3_startup_tile_intent_learn');
    expect(find.text('Learn feed'), findsOneWidget);

    await tapDiscoveryKey(tester, 'p3_startup_tile_intent_reset');
    expect(find.text('Reset feed'), findsOneWidget);

    await tapDiscoveryKey(tester, 'p3_startup_tile_intent_for_you');
    expect(find.text('For you feed'), findsOneWidget);
  });
}
