import 'package:flutter_test/flutter_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_fake_backend/loom_fake_backend.dart';
import 'package:loom_local_store/loom_local_store.dart' show DemoLocalStore;

void main() {
  test(
    'authorization derives a contextual ad plan from creator policy',
    () async {
      final store = await DemoLocalStore.seeded();
      addTearDown(store.close);
      await store.setCreatorAdPolicy(
        channelId: 'creator_solar_sarah',
        allowedCategories: const ['gambling', 'home_energy'],
        blockedCategories: const ['gambling'],
        formats: const ['pre_roll'],
        surfaces: const ['watch'],
        idempotencyKey: 'p4-unit-policy',
      );
      final api = PlaybackAuthorizationFake(store, latency: Duration.zero);

      final authorization = await api.authorize(
        passportId: 'passport_demo_fan',
        contentId: 'content_solar_001',
        adContext: const AdContext(
          sessionIntentId: 'unit',
          intentLabel: 'Watch',
          allowedCategories: ['home_energy', 'gambling'],
        ),
        entitlementState: EntitlementState.adSupported,
        idempotencyKey: 'p4-unit-auth',
      );

      expect(authorization.adPlan.hasAd, isTrue);
      expect(authorization.adPlan.category, 'home_energy');
      expect(authorization.adPlan.noBehavioralTargeting, isTrue);
    },
  );

  test(
    'playback completion emits idempotent playback and ad receipts',
    () async {
      final store = await DemoLocalStore.seeded();
      addTearDown(store.close);
      final api = PlaybackAuthorizationFake(store, latency: Duration.zero);

      final authorization = await api.authorize(
        passportId: 'passport_demo_fan',
        contentId: 'content_solar_001',
        adContext: const AdContext(
          sessionIntentId: 'unit',
          intentLabel: 'Watch',
          allowedCategories: ['home_energy'],
        ),
        entitlementState: EntitlementState.adSupported,
        idempotencyKey: 'p4-unit-complete-auth',
      );
      final first = await api.complete(
        authorizationId: authorization.id,
        idempotencyKey: 'p4-unit-complete',
      );
      final second = await api.complete(
        authorizationId: authorization.id,
        idempotencyKey: 'p4-unit-complete',
      );

      expect(first.receipts.map((receipt) => receipt.type), {
        ReceiptType.playback,
        ReceiptType.adImpression,
      });
      expect(
        second.receipts.map((receipt) => receipt.id),
        first.receipts.map((receipt) => receipt.id),
      );
    },
  );

  test('blocked creator is suppressed from recommendation feed', () async {
    final store = await DemoLocalStore.seeded();
    addTearDown(store.close);
    final passport = FanPassportFake(store, latency: Duration.zero);
    final recommendations = RecommendationReferralFake(
      store,
      latency: Duration.zero,
    );

    final session = await recommendations.createSessionIntent(
      passportId: 'passport_demo_fan',
      platformIntentId: 'intent_for_you',
      idempotencyKey: 'p4-unit-session',
    );
    await passport.blockCreator(
      passportId: 'passport_demo_fan',
      creatorId: 'creator_solar_sarah',
      idempotencyKey: 'p4-unit-block',
    );
    final feed = await recommendations.getFeed(
      sessionIntentId: session.id,
      pageSize: 10,
    );

    expect(
      feed.items.map((item) => item.tile.creatorId),
      isNot(contains('creator_solar_sarah')),
    );
  });
}
