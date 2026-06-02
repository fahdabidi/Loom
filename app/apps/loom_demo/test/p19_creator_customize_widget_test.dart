import 'package:feature_creator_customize/feature_creator_customize.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo/main.dart';
import 'package:loom_local_store/loom_local_store.dart';

void main() {
  late DemoLocalStore store;

  setUp(() async {
    resetAppShellDependencies();
    store = await configureDemoDependencies(persistent: false);
  });

  tearDown(() async {
    await store.close();
    resetAppShellDependencies();
  });

  testWidgets('p19 customize screen previews creator and switches profiles', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLoomTheme(),
        home: Scaffold(
          body: CreatorCustomizeConsoleScreen(
            creatorId: 'creator_ember_hollow',
            onBack: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(
      find.byKey(const ValueKey('p19_live_preview_panel')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('p19_creator_selector')), findsOneWidget);
    expect(find.text('EmberHollow'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey('p19_creator_creator_nova_clutch')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.textContaining('Nova'), findsWidgets);
    expect(
      find.byKey(const ValueKey('p19_save_experience_button')),
      findsOneWidget,
    );
  });
}
