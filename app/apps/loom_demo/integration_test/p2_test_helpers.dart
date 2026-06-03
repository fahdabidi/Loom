import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_demo/main.dart';

Future<void> openCreatorPublishingSetup(WidgetTester tester) async {
  await tester.pumpWidget(await buildLoomDemoAppForTest());
  await tester.pumpAndSettle();

  await tester.tap(find.text('Creator Studio'));
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(const ValueKey('creator_open_channel_setup_button')),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('creator_create_channel_button')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('creator_accept_hosting_button')));
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(const ValueKey('creator_open_publishing_setup_button')),
  );
  await tester.pumpAndSettle();

  expect(find.text('Publish composer'), findsOneWidget);
}

Future<void> tapStudioKey(WidgetTester tester, String key) async {
  final finder = await findStudioKey(tester, key);
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 1500));
  await tester.pumpAndSettle();
}

Future<Finder> findStudioKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  final scrollable = find.byKey(const ValueKey('p2_studio_scroll'));
  for (var attempt = 0; attempt < 12 && finder.evaluate().isEmpty; attempt++) {
    await tester.drag(scrollable, const Offset(0, -320), warnIfMissed: false);
    await tester.pumpAndSettle();
  }
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  return finder;
}
