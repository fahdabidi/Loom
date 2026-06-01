import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'p3_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p3_feedback', (tester) async {
    await openDiscoveryHome(tester);

    await findDiscoveryKey(tester, 'p3_feed_card_content_solar_001');

    await tapDiscoveryKey(tester, 'p3_feedback_dislike_content_solar_001');

    expect(
      find.byKey(const ValueKey('p3_feed_card_content_solar_001')),
      findsNothing,
    );
  });
}
