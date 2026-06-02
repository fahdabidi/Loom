import 'package:flutter_test/flutter_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_fake_backend/loom_fake_backend.dart';
import 'package:loom_local_store/loom_local_store.dart';

void main() {
  test(
    'p15 extension foundation uses typed APIs over local store fakes',
    () async {
      final store = await DemoLocalStore.seeded();
      addTearDown(store.close);

      final registry = ExtensionRegistryFake(store, latency: Duration.zero);
      final runtime = ExtensionRuntimeFake(store, latency: Duration.zero);
      final experience = CreatorExperienceFake(store, latency: Duration.zero);
      final receipts = ReceiptLedgerFake(store, latency: Duration.zero);

      final manifests = await registry.listExtensions();
      expect(manifests, hasLength(6));
      expect(
        manifests.map((manifest) => manifest.name),
        containsAll([
          'Clip Arena',
          'Pick\'Em',
          'HypeWars',
          'Quest Log',
          'Build Showcase',
          'Guild Quest',
        ]),
      );
      expect(
        manifests.every(
          (manifest) => manifest.certificationState == 'certified',
        ),
        isTrue,
      );

      final creatorIds = (await store.creators())
          .map((creator) => creator.id)
          .where(
            (id) => id.startsWith('creator_') && _gamingCreatorIds.contains(id),
          )
          .toList(growable: false);
      expect(creatorIds, hasLength(5));

      final configs = <CreatorExperienceConfig>[];
      for (final creatorId in _gamingCreatorIds) {
        configs.add(await experience.getExperienceConfig(channelId: creatorId));
      }
      expect(
        configs.map((config) => config.theme.themeId).toSet(),
        hasLength(5),
      );
      expect(
        configs
            .expand((config) => config.installedExtensions)
            .map((install) => install.extensionId),
        containsAll(manifests.map((manifest) => manifest.extensionId)),
      );

      final nova = await experience.getExperienceConfig(
        channelId: 'creator_nova_clutch',
      );
      expect(nova.bannerRef, 'seed://banners/nova-clutch');
      expect(
        nova.surfaceModules.map((module) => module.extensionId),
        containsAll(['ext_clip_arena', 'ext_pickem']),
      );

      final clipSession = await runtime.createExtensionSession(
        channelId: 'creator_nova_clutch',
        extensionId: 'ext_clip_arena',
        surface: 'feed_module',
        fanId: 'passport_demo_fan',
        idempotencyKey: 'p15-clip-session',
      );
      final clipSessionReplay = await runtime.createExtensionSession(
        channelId: 'creator_nova_clutch',
        extensionId: 'ext_clip_arena',
        surface: 'feed_module',
        fanId: 'passport_demo_fan',
        idempotencyKey: 'p15-clip-session',
      );
      expect(clipSessionReplay.sessionId, clipSession.sessionId);
      expect(clipSession.allowedPermissions, contains('write_fan_vote'));

      await expectLater(
        runtime.createExtensionSession(
          channelId: 'creator_nova_clutch',
          extensionId: 'ext_pickem',
          surface: 'video_overlay',
          fanId: 'passport_demo_fan',
          idempotencyKey: 'p15-denied-surface',
        ),
        throwsStateError,
      );

      final event = await runtime.submitExtensionEvent(
        sessionId: clipSession.sessionId,
        type: 'reward_earned',
        payload: const {
          'vote': 'clip_retakes',
          'rewardCode': 'clip-arena-voter',
        },
        idempotencyKey: 'p15-clip-vote',
      );
      final eventReplay = await runtime.submitExtensionEvent(
        sessionId: clipSession.sessionId,
        type: 'reward_earned',
        payload: const {
          'vote': 'clip_retakes',
          'rewardCode': 'clip-arena-voter',
        },
        idempotencyKey: 'p15-clip-vote',
      );
      expect(eventReplay.eventId, event.eventId);

      final fanReceipts = await receipts.receiptsForPassport(
        'passport_demo_fan',
      );
      expect(
        fanReceipts.where((receipt) => receipt.type == ReceiptType.reward),
        isNotEmpty,
      );

      final stateExport = await runtime.createExtensionStateExport(
        channelId: 'creator_nova_clutch',
        fanId: 'passport_demo_fan',
      );
      expect(
        stateExport.entries.map((entry) => entry.key),
        contains('last_event_reward-earned'),
      );

      final installed = await registry.installExtension(
        channelId: 'creator_ember_hollow',
        extensionId: 'ext_hypewars',
        version: '1.0.0',
        approvedPermissions: const ['read_wallet_status', 'issue_reward'],
        approvedSurfaces: const ['feed_module'],
        config: const {'goal': 'Community campfire boost'},
        idempotencyKey: 'p15-install-hypewars',
      );
      final installedReplay = await registry.installExtension(
        channelId: 'creator_ember_hollow',
        extensionId: 'ext_hypewars',
        version: '1.0.0',
        approvedPermissions: const ['read_wallet_status', 'issue_reward'],
        approvedSurfaces: const ['feed_module'],
        config: const {'goal': 'Community campfire boost'},
        idempotencyKey: 'p15-install-hypewars',
      );
      expect(installedReplay.installId, installed.installId);

      await store.resetDemo();
      final resetManifests = await registry.listExtensions();
      final resetNova = await experience.getExperienceConfig(
        channelId: 'creator_nova_clutch',
      );
      final resetExport = await runtime.createExtensionStateExport(
        channelId: 'creator_nova_clutch',
        fanId: 'passport_demo_fan',
      );
      expect(resetManifests, hasLength(6));
      expect(resetNova.installedExtensions, hasLength(3));
      expect(
        resetExport.entries.map((entry) => entry.key),
        isNot(contains('last_event_reward-earned')),
      );
    },
  );
}

const _gamingCreatorIds = {
  'creator_nova_clutch',
  'creator_ember_hollow',
  'creator_frame_by_frame',
  'creator_drift_and_chill',
  'creator_iron_vael',
};
