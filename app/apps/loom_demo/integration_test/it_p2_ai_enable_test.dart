import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'p2_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p2_ai_enable', (tester) async {
    await openCreatorPublishingSetup(tester);

    await tapStudioKey(tester, 'p2_enable_ai_button');

    expect(await findStudioKey(tester, 'p2_ai_success'), findsOneWidget);
    expect(
      find.text('AIContentPolicy stored - Q&A and summaries enabled'),
      findsOneWidget,
    );
  });
}
