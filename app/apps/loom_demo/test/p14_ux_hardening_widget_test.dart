import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_design_system/loom_design_system.dart';

void main() {
  testWidgets('p14 async states render polished reusable components', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLoomTheme(),
        home: const Scaffold(
          body: Column(
            children: [
              LoadingSkeleton(title: 'Loading test'),
              LoomEmptyState(
                icon: Icons.inbox_outlined,
                title: 'Empty test',
                body: 'Nothing to show yet.',
              ),
              LoomErrorState(title: 'Error test', body: 'Retry when ready.'),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('p14_loading_skeleton')), findsOneWidget);
    expect(find.byKey(const ValueKey('p14_empty_state')), findsOneWidget);
    expect(find.byKey(const ValueKey('p14_error_state')), findsOneWidget);
  });

  testWidgets(
    'p14 immersive feed renders media card and load more affordance',
    (tester) async {
      var opened = false;
      var loaded = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLoomTheme(),
          home: Scaffold(
            body: ImmersiveDiscoveryFeed(
              items: const [
                ImmersiveFeedItemView(
                  id: 'content_solar_001',
                  creatorId: 'creator_solar_sarah',
                  title: 'Solar starter',
                  creatorName: 'Solar Sarah',
                  summary: 'A practical setup walkthrough.',
                  posterRef: 'seed://thumbs/solar',
                  providerLabel: 'Loom',
                  reason: 'Matched home energy',
                ),
              ],
              hasMore: true,
              loadingMore: false,
              onLoadMore: () => loaded = true,
              onOpenItem: (_) => opened = true,
              onOpenCreator: (_) {},
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('p14_immersive_discovery')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('p14_immersive_card_content_solar_001')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('p14_immersive_open_content_solar_001')),
      );
      expect(opened, isTrue);

      await tester.drag(
        find.byKey(const ValueKey('p14_immersive_discovery')),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('p14_immersive_load_more_button')),
      );
      expect(loaded, isTrue);
    },
  );
}
