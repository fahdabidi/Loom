import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_demo/main.dart';

Future<void> openDiscoveryHome(WidgetTester tester) async {
  await tester.pumpWidget(await buildLoomDemoAppForTest());
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pumpAndSettle();

  expect(find.byKey(const ValueKey('p3_session_disclosure')), findsOneWidget);
}

Future<Finder> findDiscoveryKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  if (key.startsWith('p3_startup_tile_')) {
    final rail = find.byKey(const ValueKey('p3_intent_rail'));
    for (var attempt = 0; attempt < 8 && finder.evaluate().isEmpty; attempt++) {
      await tester.drag(rail, const Offset(-180, 0), warnIfMissed: false);
      await tester.pumpAndSettle();
    }
    if (finder.evaluate().isNotEmpty) {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      return finder;
    }
  }

  final scrollableCandidates = [
    find.byKey(const ValueKey('p3_discovery_scroll')),
    find.byKey(const ValueKey('p4_channel_home')),
    find.byKey(const ValueKey('p4_player_screen')),
  ];
  final scrollable = scrollableCandidates.firstWhere(
    (candidate) => candidate.evaluate().isNotEmpty,
    orElse: () => scrollableCandidates.first,
  );
  for (var attempt = 0; attempt < 12 && finder.evaluate().isEmpty; attempt++) {
    await tester.drag(scrollable, const Offset(0, -280), warnIfMissed: false);
    await tester.pumpAndSettle();
  }
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  return finder;
}

Future<void> tapDiscoveryKey(WidgetTester tester, String key) async {
  final finder = await findDiscoveryKey(tester, key);
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pumpAndSettle();
}
