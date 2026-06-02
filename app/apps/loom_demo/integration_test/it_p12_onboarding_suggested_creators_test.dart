import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_demo/main.dart';

import 'p1_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p12_onboarding_suggested_creators', (tester) async {
    await tester.pumpWidget(await buildLoomDemoAppForTest());
    await tester.pumpAndSettle();

    await startFanOnboarding(tester);
    await createPassportAndPickInterests(tester);
    await tester.tap(find.byKey(const ValueKey('fan_continue_privacy_button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('fan_suggested_creator_pack')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('starter_pack_member_creator_solar_sarah')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('starter_pack_member_creator_city_ferments')),
      findsOneWidget,
    );
  });
}
