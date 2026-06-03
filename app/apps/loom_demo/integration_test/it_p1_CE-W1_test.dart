import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p1_CE-W1', (tester) async {
    await tester.pumpWidget(await buildLoomDemoAppForTest());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Creator Studio'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('creator_studio_landing')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('creator_complete_onboarding_tile')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('creator_open_channel_setup_button')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('creator_create_channel_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('creator_accept_hosting_button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Creator onboarding complete'), findsOneWidget);
    expect(find.text('Channel: Loom Home Lab'), findsOneWidget);
    expect(find.text('@loom-home-lab'), findsOneWidget);
    expect(find.text('Hosting: Loom Managed Hosting accepted'), findsOneWidget);
  });
}
