import 'package:flutter_test/flutter_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_fake_backend/loom_fake_backend.dart';
import 'package:loom_local_store/loom_local_store.dart' show DemoLocalStore;

void main() {
  test(
    'publishContent rejects missing summary and versions valid manifests',
    () async {
      final store = await DemoLocalStore.seeded();
      addTearDown(store.close);
      final api = CreatorMetadataFake(store, latency: Duration.zero);

      await expectLater(
        api.publishContent(
          channelId: 'channel_test',
          contentType: ContentType.video,
          title: 'Test video',
          summary: '',
          thumbnailRef: 'seed://test',
          accessMode: ContentAccessMode.public,
          monetizationMode: MonetizationMode.free,
          idempotencyKey: 'p2-test-missing-summary',
        ),
        throwsA(
          isA<ApiError>().having(
            (error) => error.code,
            'code',
            'summary_required',
          ),
        ),
      );

      final manifest = await api.publishContent(
        channelId: 'channel_test',
        contentType: ContentType.video,
        title: 'Test video',
        summary: 'Creator-approved summary.',
        thumbnailRef: 'seed://test',
        accessMode: ContentAccessMode.public,
        monetizationMode: MonetizationMode.free,
        idempotencyKey: 'p2-test-publish',
      );

      expect(manifest.schemaVersion, 1);
      expect(manifest.summary, 'Creator-approved summary.');
    },
  );

  test('catalog import completes with external references', () async {
    final store = await DemoLocalStore.seeded();
    addTearDown(store.close);
    final api = MigrationExportFake(store, latency: Duration.zero);

    final started = await api.startImportJob(
      channelId: 'channel_test',
      sourcePlatform: 'YouTube export',
      idempotencyKey: 'p2-test-import',
    );
    final completed = await api.getImportJob(started.id);

    expect(started.state, ImportJobState.processing);
    expect(completed.state, ImportJobState.complete);
    expect(completed.references, hasLength(2));
  });

  test('memberships, entitlements, and ad policy persist', () async {
    final store = await DemoLocalStore.seeded();
    addTearDown(store.close);
    final metadata = CreatorMetadataFake(store, latency: Duration.zero);
    final ledger = EntitlementLedgerFake(store, latency: Duration.zero);

    final tiers = await metadata.defineMembershipTiers(
      channelId: 'channel_test',
      tiers: const [
        MembershipTierDraft(
          name: 'Supporter',
          monthlyPriceCents: 500,
          benefits: ['Member posts'],
          entitlementCode: 'member.supporter',
        ),
      ],
      idempotencyKey: 'p2-test-tiers',
    );
    final entitlements = await ledger.registerMembershipTierDefinitions(
      channelId: 'channel_test',
      tiers: tiers,
      idempotencyKey: 'p2-test-entitlements',
    );
    final policy = await metadata.setCreatorAdPolicy(
      channelId: 'channel_test',
      allowedCategories: const ['home_energy'],
      blockedCategories: const ['gambling'],
      formats: const ['pre_roll'],
      surfaces: const ['watch'],
      idempotencyKey: 'p2-test-ad-policy',
    );

    expect(tiers, hasLength(1));
    expect(entitlements.single.code, 'member.supporter');
    expect(policy.blockedCategories, contains('gambling'));
  });
}
