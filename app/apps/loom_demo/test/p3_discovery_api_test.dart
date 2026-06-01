import 'package:flutter_test/flutter_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_fake_backend/loom_fake_backend.dart';
import 'package:loom_local_store/loom_local_store.dart' show DemoLocalStore;

void main() {
  test('startup tiles create an explainable ranked feed session', () async {
    final store = await DemoLocalStore.seeded();
    addTearDown(store.close);
    final api = RecommendationReferralFake(store, latency: Duration.zero);

    final tiles = await api.getStartupTiles(passportId: 'passport_demo_fan');
    final session = await api.createSessionIntent(
      passportId: 'passport_demo_fan',
      platformIntentId: tiles.first.id,
      idempotencyKey: 'p3-api-session',
    );
    final page = await api.getFeed(sessionIntentId: session.id, pageSize: 3);

    expect(tiles.map((tile) => tile.id), contains('intent_for_you'));
    expect(session.disclosure.excludedSignals, contains('Paid placement'));
    expect(page.items, hasLength(3));
    expect(page.items.first.explanation.summary, contains('summary fit'));
    expect(api.feedRequestCount, 1);
  });

  test(
    'feedback suppresses disliked content from the next feed page',
    () async {
      final store = await DemoLocalStore.seeded();
      addTearDown(store.close);
      final api = RecommendationReferralFake(store, latency: Duration.zero);

      final session = await api.createSessionIntent(
        passportId: 'passport_demo_fan',
        platformIntentId: 'intent_for_you',
        idempotencyKey: 'p3-api-feedback-session',
      );
      final firstPage = await api.getFeed(sessionIntentId: session.id);
      final dislikedId = firstPage.items.first.tile.contentId;

      await api.submitFeedback(
        sessionIntentId: session.id,
        contentId: dislikedId,
        action: FeedbackAction.dislike,
        idempotencyKey: 'p3-api-dislike',
      );
      final nextPage = await api.getFeed(
        sessionIntentId: session.id,
        pageSize: 10,
      );

      expect(
        nextPage.items.map((item) => item.tile.contentId),
        isNot(contains(dislikedId)),
      );
    },
  );

  test('search returns neutral non-ad results', () async {
    final store = await DemoLocalStore.seeded();
    addTearDown(store.close);
    final api = SearchFake(store, latency: Duration.zero);

    final page = await api.search(
      passportId: 'passport_demo_fan',
      query: 'solar',
    );

    expect(page.items, isNotEmpty);
    expect(page.items.first.neutralityLabel, contains('no ads'));
    expect(page.items.first.tile.creatorName, 'Solar Sarah');
  });
}
