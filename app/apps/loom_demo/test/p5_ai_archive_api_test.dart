import 'package:flutter_test/flutter_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_fake_backend/loom_fake_backend.dart';
import 'package:loom_local_store/loom_local_store.dart';

void main() {
  test('archive Q&A returns citations and AI/source receipts', () async {
    final store = await DemoLocalStore.seeded();
    addTearDown(store.close);
    final api = AiGatewayFake(store, latency: Duration.zero);

    final answer = await api.askArchive(
      passportId: 'passport_demo_fan',
      creatorId: 'creator_solar_sarah',
      question: 'What should I check before sizing a home battery?',
      policyRef: 'ai-policy:creator_solar_sarah',
      idempotencyKey: 'p5-qa-test',
    );

    expect(answer.citations, isNotEmpty);
    expect(answer.citations.length, lessThanOrEqualTo(2));
    expect(answer.citations.first.segment.length, lessThan(260));
    expect(
      answer.receipts.map((receipt) => receipt.type),
      containsAll([ReceiptType.aiUsage, ReceiptType.sourceAttribution]),
    );
  });

  test('source-attribution receipts match cited content', () async {
    final store = await DemoLocalStore.seeded();
    addTearDown(store.close);
    final api = AiGatewayFake(store, latency: Duration.zero);

    final answer = await api.askArchive(
      passportId: 'passport_demo_fan',
      creatorId: 'creator_solar_sarah',
      question: 'Which utility bill fields matter for solar ROI?',
      policyRef: 'ai-policy:creator_solar_sarah',
      idempotencyKey: 'p5-royalty-test',
    );

    final citedIds = answer.citations.map((citation) => citation.contentId);
    final sourceReceiptIds = answer.receipts
        .where((receipt) => receipt.type == ReceiptType.sourceAttribution)
        .map((receipt) => receipt.contentId);
    expect(sourceReceiptIds.toSet(), citedIds.toSet());
    expect(
      answer.receipts
          .where((receipt) => receipt.type == ReceiptType.sourceAttribution)
          .first
          .summary,
      contains('royalty basis'),
    );
  });

  test('summary ranking preserves candidate set and annotates why', () async {
    final store = await DemoLocalStore.seeded();
    addTearDown(store.close);
    final recommendation = RecommendationReferralFake(
      store,
      latency: Duration.zero,
    );
    final ai = AiGatewayFake(store, latency: Duration.zero);

    final session = await recommendation.createSessionIntent(
      passportId: 'passport_demo_fan',
      platformIntentId: 'intent_for_you',
      idempotencyKey: 'p5-session',
    );
    final page = await recommendation.getFeed(
      sessionIntentId: session.id,
      pageSize: 5,
    );
    final result = await ai.rankBySummary(
      preference: RankPreference(
        passportId: 'passport_demo_fan',
        summaryFirst: true,
        updatedAt: DateTime.utc(2026),
      ),
      candidates: page.items,
    );

    expect(result.candidateCount, page.items.length);
    expect(
      result.items.map((item) => item.tile.contentId).toSet(),
      page.items.map((item) => item.tile.contentId).toSet(),
    );
    expect(
      result.items.map((item) => item.tile.contentId),
      isNot(page.items.map((item) => item.tile.contentId)),
    );
    expect(
      result.items.first.explanation.matchedSignals,
      contains('Summary used for relevance'),
    );
    expect(
      result.items.first.explanation.suppressedSignals,
      contains('Clickbait title weighting'),
    );
  });
}
