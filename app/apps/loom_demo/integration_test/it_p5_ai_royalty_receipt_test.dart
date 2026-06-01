import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'p3_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p5_ai_royalty_receipt', (tester) async {
    await openDiscoveryHome(tester);
    await tapDiscoveryKey(
      tester,
      'p4_open_channel_creator_solar_sarah_content_solar_001',
    );
    await tapDiscoveryKey(tester, 'p5_open_archive_qa_button');
    await tapDiscoveryKey(tester, 'p5_ask_button');
    await tapDiscoveryKey(tester, 'p5_citation_content_solar_001');

    expect(
      find.byKey(const ValueKey('p5_citation_royalty_basis')),
      findsOneWidget,
    );
    expect(find.text('source-attribution:content_solar_001'), findsOneWidget);
  });
}
