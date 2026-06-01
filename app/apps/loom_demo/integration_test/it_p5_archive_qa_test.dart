import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'p3_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p5_archive_qa', (tester) async {
    await openDiscoveryHome(tester);
    await tapDiscoveryKey(
      tester,
      'p4_open_channel_creator_solar_sarah_content_solar_001',
    );
    await tapDiscoveryKey(tester, 'p5_open_archive_qa_button');

    expect(find.byKey(const ValueKey('p5_archive_qa_screen')), findsOneWidget);
    await tapDiscoveryKey(tester, 'p5_ask_button');

    expect(find.byKey(const ValueKey('p5_answer_card')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('p5_citation_content_solar_001')),
      findsWidgets,
    );
    await findDiscoveryKey(tester, 'p5_receipt_aiUsage');
    await findDiscoveryKey(
      tester,
      'p5_receipt_sourceAttribution_content_solar_001',
    );
  });
}
