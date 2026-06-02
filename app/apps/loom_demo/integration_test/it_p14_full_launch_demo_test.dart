import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p14_full_launch_demo', (tester) async {
    await tester.pumpWidget(await buildLoomDemoAppForTest());
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('p12_open_capture_link_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('p12_follow_selected_button')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('p3_feed_card_content_solar_001')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('p4_player_screen')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('p4_playback_back_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Creator Studio'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('p13_open_conversion_button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('p13_conversion_funnel_card')),
      findsOneWidget,
    );
  });
}
