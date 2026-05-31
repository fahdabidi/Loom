import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'p2_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p2_membership_setup', (tester) async {
    await openCreatorPublishingSetup(tester);

    await tapStudioKey(tester, 'p2_ai_draft_summary_button');
    await tapStudioKey(tester, 'p2_publish_post_button');
    await tapStudioKey(tester, 'p2_define_tiers_button');

    expect(
      await findStudioKey(tester, 'p2_membership_success'),
      findsOneWidget,
    );
    expect(
      find.text('Membership setup complete - 2 entitlements registered'),
      findsOneWidget,
    );
  });
}
