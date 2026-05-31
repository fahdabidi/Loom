import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'p2_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p2_ad_policy', (tester) async {
    await openCreatorPublishingSetup(tester);

    await tapStudioKey(tester, 'p2_save_ad_policy_button');

    expect(await findStudioKey(tester, 'p2_ad_policy_success'), findsOneWidget);
    expect(find.text('CreatorAdPolicy persisted'), findsOneWidget);
  });
}
