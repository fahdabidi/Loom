import 'package:flutter_test/flutter_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_fake_backend/loom_fake_backend.dart';
import 'package:loom_local_store/loom_local_store.dart';

void main() {
  test('p18 quest completion awards badge and reward receipt', () async {
    final store = await DemoLocalStore.seeded();
    addTearDown(store.close);

    final runtime = ExtensionRuntimeFake(store, latency: Duration.zero);
    final receipts = ReceiptLedgerFake(store, latency: Duration.zero);

    final session = await runtime.createExtensionSession(
      channelId: 'creator_ember_hollow',
      extensionId: 'ext_quest_log',
      surface: 'feed_module',
      fanId: 'passport_demo_fan',
      idempotencyKey: 'p18-quest-session',
    );
    final first = await runtime.submitExtensionEvent(
      sessionId: session.sessionId,
      type: 'quest_completed',
      payload: const {
        'questId': 'valley_shrine',
        'title': 'Restore the valley shrine',
        'badge': 'Shrine keeper',
        'rewardCode': 'quest_badge_valley_shrine',
      },
      idempotencyKey: 'p18-quest-complete',
    );
    final replay = await runtime.submitExtensionEvent(
      sessionId: session.sessionId,
      type: 'quest_completed',
      payload: const {
        'questId': 'valley_shrine',
        'title': 'Restore the valley shrine',
        'badge': 'Shrine keeper',
        'rewardCode': 'quest_badge_valley_shrine',
      },
      idempotencyKey: 'p18-quest-complete',
    );
    expect(replay.eventId, first.eventId);

    final export = await runtime.createExtensionStateExport(
      channelId: 'creator_ember_hollow',
    );
    expect(
      export.entries.map((entry) => entry.key),
      containsAll([
        'quest:valley_shrine',
        'badge:passport_demo_fan:valley_shrine',
      ]),
    );

    final fanReceipts = await receipts.receiptsForPassport('passport_demo_fan');
    expect(
      fanReceipts.where((receipt) => receipt.type == ReceiptType.reward),
      isNotEmpty,
    );
  });

  test('p18 build showcase submission can become featured', () async {
    final store = await DemoLocalStore.seeded();
    addTearDown(store.close);

    final runtime = ExtensionRuntimeFake(store, latency: Duration.zero);

    final session = await runtime.createExtensionSession(
      channelId: 'creator_iron_vael',
      extensionId: 'ext_build_showcase',
      surface: 'feed_module',
      fanId: 'passport_demo_fan',
      idempotencyKey: 'p18-build-session',
    );
    await runtime.submitExtensionEvent(
      sessionId: session.sessionId,
      type: 'build_submitted',
      payload: const {
        'buildId': 'build_raid_ready',
        'title': 'Raid shield wall',
        'submitter': 'You',
      },
      idempotencyKey: 'p18-build-submit',
    );
    await runtime.submitExtensionEvent(
      sessionId: session.sessionId,
      type: 'build_vote',
      payload: const {
        'buildId': 'build_raid_ready',
        'featured': 'true',
        'rewardCode': 'build_showcase_featured_vote',
      },
      idempotencyKey: 'p18-build-vote',
    );

    final export = await runtime.createExtensionStateExport(
      channelId: 'creator_iron_vael',
    );
    final build = export.entries.singleWhere(
      (entry) =>
          entry.scopeKey ==
              'channel:creator_iron_vael:extension:ext_build_showcase' &&
          entry.key == 'build:build_raid_ready',
    );
    expect(build.value['votes'], '1');
    expect(build.value['featured'], 'true');
  });

  test('p18 guild quest contribution advances aggregate progress', () async {
    final store = await DemoLocalStore.seeded();
    addTearDown(store.close);

    final runtime = ExtensionRuntimeFake(store, latency: Duration.zero);

    final session = await runtime.createExtensionSession(
      channelId: 'creator_drift_and_chill',
      extensionId: 'ext_guild_quest',
      surface: 'feed_module',
      fanId: 'passport_demo_fan',
      idempotencyKey: 'p18-guild-session',
    );
    final first = await runtime.submitExtensionEvent(
      sessionId: session.sessionId,
      type: 'guild_contributed',
      payload: const {
        'amount': '5',
        'target': '30',
        'milestone': 'Queue opened',
        'rewardCode': 'guild_quest_progress',
      },
      idempotencyKey: 'p18-guild-contribute',
    );
    final replay = await runtime.submitExtensionEvent(
      sessionId: session.sessionId,
      type: 'guild_contributed',
      payload: const {
        'amount': '5',
        'target': '30',
        'milestone': 'Queue opened',
        'rewardCode': 'guild_quest_progress',
      },
      idempotencyKey: 'p18-guild-contribute',
    );
    expect(replay.eventId, first.eventId);

    final export = await runtime.createExtensionStateExport(
      channelId: 'creator_drift_and_chill',
    );
    final progress = export.entries.singleWhere(
      (entry) =>
          entry.scopeKey ==
              'channel:creator_drift_and_chill:extension:ext_guild_quest' &&
          entry.key == 'guild_progress',
    );
    expect(progress.value['current'], '5');
    expect(progress.value['target'], '30');
  });
}
