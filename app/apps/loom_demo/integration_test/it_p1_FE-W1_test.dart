import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_demo/main.dart';

import 'p1_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p1_FE-W1', (tester) async {
    await tester.pumpWidget(await buildLoomDemoAppForTest());
    await tester.pumpAndSettle();

    await startFanOnboarding(tester);
    await completeFanOnboarding(tester);

    expect(find.text('Fan onboarding complete'), findsOneWidget);
    expect(find.textContaining('starter creators'), findsOneWidget);
    expect(find.text('Visibility: Private'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('fan_onboarding_nav_panel')),
      findsOneWidget,
    );
    await tester.drag(
      find.byKey(const ValueKey('fan_subsurface_with_rail')),
      const Offset(0, 600),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('fan_secondary_action_rail')),
      findsOneWidget,
    );

    final starterCreatorsTile = find.byKey(
      const ValueKey('fan_edit_starter_creators_tile'),
    );
    await tester.ensureVisible(starterCreatorsTile);
    await tester.pumpAndSettle();
    await tester.tap(starterCreatorsTile);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('fan_suggested_creator_pack')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('fan_onboarding_back_button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('fan_first_follow_button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('fan_complete_onboarding_button')),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('p0_recommendation_type_row')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('p6_open_wallet_button')));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('p6_wallet_screen')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('fan_secondary_action_rail')),
      findsOneWidget,
    );
  });
}
