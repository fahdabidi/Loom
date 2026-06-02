import 'package:flutter_test/flutter_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_fake_backend/loom_fake_backend.dart';
import 'package:loom_local_store/loom_local_store.dart';

void main() {
  test('p17 clip arena submit vote leaderboard and reward receipt', () async {
    final store = await DemoLocalStore.seeded();
    addTearDown(store.close);

    final runtime = ExtensionRuntimeFake(store, latency: Duration.zero);
    final receipts = ReceiptLedgerFake(store, latency: Duration.zero);

    final session = await runtime.createExtensionSession(
      channelId: 'creator_nova_clutch',
      extensionId: 'ext_clip_arena',
      surface: 'feed_module',
      fanId: 'passport_demo_fan',
      idempotencyKey: 'p17-clip-session',
    );
    await runtime.submitExtensionEvent(
      sessionId: session.sessionId,
      type: 'clip_submitted',
      payload: const {
        'clipId': 'clip_demo_ace',
        'title': 'Triple retake',
        'submitter': 'You',
        'season': 'Week 1',
      },
      idempotencyKey: 'p17-clip-submit',
    );
    final vote = await runtime.submitExtensionEvent(
      sessionId: session.sessionId,
      type: 'clip_vote',
      payload: const {
        'clipId': 'clip_demo_ace',
        'rewardCode': 'clip_arena_vote_badge',
      },
      idempotencyKey: 'p17-clip-vote',
    );
    final replay = await runtime.submitExtensionEvent(
      sessionId: session.sessionId,
      type: 'clip_vote',
      payload: const {
        'clipId': 'clip_demo_ace',
        'rewardCode': 'clip_arena_vote_badge',
      },
      idempotencyKey: 'p17-clip-vote',
    );
    expect(replay.eventId, vote.eventId);

    final export = await runtime.createExtensionStateExport(
      channelId: 'creator_nova_clutch',
    );
    final clip = export.entries.singleWhere(
      (entry) =>
          entry.scopeKey ==
              'channel:creator_nova_clutch:extension:ext_clip_arena' &&
          entry.key == 'clip:clip_demo_ace',
    );
    expect(clip.value['votes'], '1');
    expect(clip.value['title'], 'Triple retake');

    final fanReceipts = await receipts.receiptsForPassport('passport_demo_fan');
    expect(
      fanReceipts.where((receipt) => receipt.type == ReceiptType.reward),
      isNotEmpty,
    );
  });

  test(
    'p17 pickem stores one idempotent fan pick and ladder standing',
    () async {
      final store = await DemoLocalStore.seeded();
      addTearDown(store.close);

      final runtime = ExtensionRuntimeFake(store, latency: Duration.zero);

      final session = await runtime.createExtensionSession(
        channelId: 'creator_frame_by_frame',
        extensionId: 'ext_pickem',
        surface: 'feed_module',
        fanId: 'passport_demo_fan',
        idempotencyKey: 'p17-pick-session',
      );
      final first = await runtime.submitExtensionEvent(
        sessionId: session.sessionId,
        type: 'pick_made',
        payload: const {
          'name': 'You',
          'pick': 'PB pace',
          'points': '10',
          'question': 'PB this weekend?',
        },
        idempotencyKey: 'p17-pick-made',
      );
      final second = await runtime.submitExtensionEvent(
        sessionId: session.sessionId,
        type: 'pick_made',
        payload: const {
          'name': 'You',
          'pick': 'PB pace',
          'points': '10',
          'question': 'PB this weekend?',
        },
        idempotencyKey: 'p17-pick-made',
      );
      expect(second.eventId, first.eventId);

      final export = await runtime.createExtensionStateExport(
        channelId: 'creator_frame_by_frame',
      );
      final pick = export.entries.singleWhere(
        (entry) =>
            entry.scopeKey ==
                'channel:creator_frame_by_frame:extension:ext_pickem' &&
            entry.key == 'pick:passport_demo_fan',
      );
      expect(pick.value['pick'], 'PB pace');
      expect(pick.value['points'], '10');
    },
  );

  test('p17 hypewars uses wallet intent and advances hype meter', () async {
    final store = await DemoLocalStore.seeded();
    addTearDown(store.close);

    final runtime = ExtensionRuntimeFake(store, latency: Duration.zero);
    final wallet = FanWalletFake(store, latency: Duration.zero);
    final receipts = ReceiptLedgerFake(store, latency: Duration.zero);

    final before = await wallet.getWallet('passport_demo_fan');
    final intent = await wallet.createPaymentIntent(
      passportId: 'passport_demo_fan',
      kind: PurchaseKind.extensionHype,
      creatorId: 'creator_drift_and_chill',
      idempotencyKey: 'p17-hype-intent',
    );
    final confirmed = await wallet.confirmPaymentIntent(
      paymentIntentId: intent.id,
      idempotencyKey: 'p17-hype-confirm',
    );
    expect(confirmed.status, PaymentIntentStatus.succeeded);

    final session = await runtime.createExtensionSession(
      channelId: 'creator_drift_and_chill',
      extensionId: 'ext_hypewars',
      surface: 'feed_module',
      fanId: 'passport_demo_fan',
      idempotencyKey: 'p17-hype-session',
    );
    await runtime.submitExtensionEvent(
      sessionId: session.sessionId,
      type: 'hype_sent',
      payload: {
        'amountCents': '${confirmed.amountCents}',
        'paymentIntentId': confirmed.id,
        'goal': 'Unlock community queue',
        'rewardCode': 'hypewars_boost',
      },
      idempotencyKey: 'p17-hype-event',
    );

    final after = await wallet.getWallet('passport_demo_fan');
    expect(
      before.simulatedBalanceCents - after.simulatedBalanceCents,
      confirmed.amountCents,
    );

    final export = await runtime.createExtensionStateExport(
      channelId: 'creator_drift_and_chill',
    );
    final meter = export.entries.singleWhere(
      (entry) =>
          entry.scopeKey ==
              'channel:creator_drift_and_chill:extension:ext_hypewars' &&
          entry.key == 'hype_meter',
    );
    expect(meter.value['totalCents'], '${confirmed.amountCents}');

    final fanReceipts = await receipts.receiptsForPassport('passport_demo_fan');
    expect(
      fanReceipts.map((receipt) => receipt.type),
      containsAll([ReceiptType.payment, ReceiptType.reward]),
    );
  });
}
