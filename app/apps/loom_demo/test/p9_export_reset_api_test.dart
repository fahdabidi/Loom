import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_fake_backend/loom_fake_backend.dart';
import 'package:loom_local_store/loom_local_store.dart';

void main() {
  test('p9 export job assembles a complete portable bundle', () async {
    final store = await DemoLocalStore.seeded();
    addTearDown(store.close);
    final playback = PlaybackAuthorizationFake(store, latency: Duration.zero);
    final export = MigrationExportFake(store, latency: Duration.zero);

    final authorization = await playback.authorize(
      passportId: 'passport_demo_fan',
      contentId: 'content_solar_001',
      adContext: const AdContext(
        sessionIntentId: 'session_demo',
        intentLabel: 'Support',
        allowedCategories: ['home_energy'],
      ),
      entitlementState: EntitlementState.adSupported,
      idempotencyKey: 'p9-export-playback',
    );
    await playback.complete(
      authorizationId: authorization.id,
      idempotencyKey: 'p9-export-playback-complete',
    );

    final queued = await export.createExportJob(
      creatorId: 'creator_solar_sarah',
      idempotencyKey: 'p9-export-api',
    );
    final processing = await export.getExportJob(queued.id);
    final complete = await export.getExportJob(queued.id);
    final bundle = complete.bundle!;
    final portable = jsonDecode(bundle.portableJson) as Map<String, dynamic>;

    expect(queued.state, ExportJobState.queued);
    expect(processing.state, ExportJobState.processing);
    expect(complete.state, ExportJobState.complete);
    expect(portable['channel'], isA<Map<String, dynamic>>());
    expect(portable['content'], isA<List<dynamic>>());
    expect(portable['receipts'], isA<List<dynamic>>());
    expect(portable['settlementHistory'], isA<List<dynamic>>());
    expect(bundle.contentCount, greaterThan(0));
    expect(bundle.receiptCount, greaterThan(0));
    expect(bundle.settlementCount, 1);
  });

  test('p9 reset demo clears authored payment state', () async {
    final store = await DemoLocalStore.seeded();
    addTearDown(store.close);
    final wallet = FanWalletFake(store, latency: Duration.zero);
    final export = MigrationExportFake(store, latency: Duration.zero);

    final intent = await wallet.createPaymentIntent(
      passportId: 'passport_demo_fan',
      kind: PurchaseKind.creatorMembership,
      creatorId: 'creator_solar_sarah',
      idempotencyKey: 'p9-reset-membership',
    );
    await wallet.confirmPaymentIntent(
      paymentIntentId: intent.id,
      idempotencyKey: 'p9-reset-membership-confirm',
    );
    expect(
      (await wallet.getWallet('passport_demo_fan')).subscriptions,
      isNotEmpty,
    );

    await export.resetDemo(idempotencyKey: 'p9-reset-api');

    expect(
      (await wallet.getWallet('passport_demo_fan')).subscriptions,
      isEmpty,
    );
  });
}
