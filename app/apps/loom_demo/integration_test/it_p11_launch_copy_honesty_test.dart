import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'p3_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p11_launch_copy_honesty', (tester) async {
    await openDiscoveryHome(tester);
    await tester.tap(find.text('Creator Studio'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('p11_open_launch_button')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('invite your existing audience'),
      findsOneWidget,
    );
    expect(find.text('Import followers'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('p11_import_explanation_button')),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('does not import followers'), findsOneWidget);
    expect(find.textContaining('follow you on Loom'), findsWidgets);
  });
}
