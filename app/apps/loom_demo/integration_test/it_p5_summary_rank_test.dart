import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'p3_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p5_summary_rank', (tester) async {
    await openDiscoveryHome(tester);
    await tapDiscoveryKey(tester, 'p5_summary_rank_toggle');

    expect(find.byKey(const ValueKey('p5_summary_rank_note')), findsOneWidget);
    expect(find.textContaining('candidate set unchanged'), findsOneWidget);

    await tapDiscoveryKey(tester, 'p3_why_button_content_solar_002');
    expect(find.byKey(const ValueKey('p3_why_sheet')), findsOneWidget);
    expect(find.textContaining('Summary used for relevance'), findsOneWidget);
    expect(find.textContaining('Title deemphasized'), findsOneWidget);
  });
}
