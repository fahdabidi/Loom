import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'p2_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p2_publish_requires_summary', (tester) async {
    await openCreatorPublishingSetup(tester);

    await tapStudioKey(tester, 'p2_publish_without_summary_button');
    expect(find.byKey(const ValueKey('p2_publish_error')), findsOneWidget);
    expect(find.textContaining('summary_required'), findsOneWidget);

    await tapStudioKey(tester, 'p2_ai_draft_summary_button');
    await tapStudioKey(tester, 'p2_publish_video_button');

    expect(await findStudioKey(tester, 'p2_publish_success'), findsOneWidget);
    expect(find.textContaining('manifest v1'), findsOneWidget);
  });
}
