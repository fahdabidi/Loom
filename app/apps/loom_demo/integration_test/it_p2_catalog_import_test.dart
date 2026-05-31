import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'p2_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p2_catalog_import', (tester) async {
    await openCreatorPublishingSetup(tester);

    await tapStudioKey(tester, 'p2_start_import_button');

    expect(await findStudioKey(tester, 'p2_import_success'), findsOneWidget);
    expect(
      find.text('Import complete - external refs available'),
      findsOneWidget,
    );
  });
}
