import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'p3_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p11_creator_launch_assets', (tester) async {
    await openDiscoveryHome(tester);
    await tester.tap(find.text('Creator Studio'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('p11_open_launch_button')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('p11_generate_launch_assets_button')),
    );
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('p11_capture_link_row')), findsOneWidget);
    expect(find.byKey(const ValueKey('p11_qr_card')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('p11_link_in_bio_preview')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('p11_rendered_announcement')),
      findsOneWidget,
    );
  });
}
