import 'package:flutter/foundation.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';

class CreatorPublishingController extends ChangeNotifier {
  CreatorPublishingController({
    required this.channelId,
    required CreatorMetadataApi metadataApi,
    required ContentHostApi contentHostApi,
    required MigrationExportApi migrationExportApi,
    required EntitlementLedgerApi entitlementLedgerApi,
    required AiGatewayApi aiGatewayApi,
  }) : _metadataApi = metadataApi,
       _contentHostApi = contentHostApi,
       _migrationExportApi = migrationExportApi,
       _entitlementLedgerApi = entitlementLedgerApi,
       _aiGatewayApi = aiGatewayApi;

  final String channelId;
  final CreatorMetadataApi _metadataApi;
  final ContentHostApi _contentHostApi;
  final MigrationExportApi _migrationExportApi;
  final EntitlementLedgerApi _entitlementLedgerApi;
  final AiGatewayApi _aiGatewayApi;

  bool isLoading = false;
  String? errorMessage;
  String? summaryDraft;
  ContentManifest? lastPublished;
  ImportJob? importJob;
  List<ContentManifest> manifests = const [];
  List<MembershipTier> tiers = const [];
  List<EntitlementDefinition> entitlements = const [];
  CreatorAdPolicy? adPolicy;
  AIContentPolicy? aiPolicy;

  int get publishedCount => manifests.length;
  int get importedCount => importJob?.references.length ?? 0;

  Future<void> load() async {
    await _run(() async {
      await _refresh();
    });
  }

  Future<void> draftSummary({
    required String title,
    required String sourceNote,
  }) async {
    await _run(() async {
      final draft = await _aiGatewayApi.generateSummaryDraft(
        title: title,
        sourceNote: sourceNote,
      );
      summaryDraft = draft.summary;
    });
  }

  Future<void> publishWithoutSummary(String title) async {
    await _run(() async {
      lastPublished = await _metadataApi.publishContent(
        channelId: channelId,
        contentType: ContentType.video,
        title: title,
        summary: '',
        thumbnailRef: 'seed://studio/missing-summary',
        accessMode: ContentAccessMode.public,
        monetizationMode: MonetizationMode.free,
        idempotencyKey: 'p2-missing-summary-$channelId',
      );
    });
  }

  Future<void> publishVideo({
    required String title,
    required String summary,
  }) async {
    await _publish(
      title: title,
      summary: summary,
      contentType: ContentType.video,
      idempotencyKey: 'p2-publish-video-$channelId',
      accessMode: ContentAccessMode.public,
      monetizationMode: MonetizationMode.free,
    );
  }

  Future<void> publishPost({
    required String title,
    required String summary,
  }) async {
    await _publish(
      title: '$title field notes',
      summary: summary,
      contentType: ContentType.post,
      idempotencyKey: 'p2-publish-post-$channelId',
      accessMode: ContentAccessMode.membersOnly,
      monetizationMode: MonetizationMode.membership,
    );
  }

  Future<void> startImport() async {
    await _run(() async {
      importJob = await _migrationExportApi.startImportJob(
        channelId: channelId,
        sourcePlatform: 'YouTube export',
        idempotencyKey: 'p2-import-$channelId',
      );
      await Future<void>.delayed(const Duration(milliseconds: 220));
      importJob = await _migrationExportApi.getImportJob(importJob!.id);
      await _refresh();
    });
  }

  Future<void> defineTiers() async {
    await _run(() async {
      tiers = await _metadataApi.defineMembershipTiers(
        channelId: channelId,
        tiers: const [
          MembershipTierDraft(
            name: 'Supporter',
            monthlyPriceCents: 500,
            benefits: ['Member posts', 'Monthly notes'],
            entitlementCode: 'member.supporter',
          ),
          MembershipTierDraft(
            name: 'Lab Insider',
            monthlyPriceCents: 1200,
            benefits: ['Member videos', 'Early checklists'],
            entitlementCode: 'member.lab_insider',
          ),
        ],
        idempotencyKey: 'p2-membership-$channelId',
      );
      entitlements = await _entitlementLedgerApi
          .registerMembershipTierDefinitions(
            channelId: channelId,
            tiers: tiers,
            idempotencyKey: 'p2-entitlements-$channelId',
          );
      await _metadataApi.updateMonetizationManifest(
        channelId: channelId,
        membershipsEnabled: true,
        memberOnlyContentIds: manifests
            .where(
              (manifest) =>
                  manifest.accessMode == ContentAccessMode.membersOnly,
            )
            .map((manifest) => manifest.id)
            .toList(growable: false),
        idempotencyKey: 'p2-monetization-$channelId',
      );
    });
  }

  Future<void> saveAdPolicy() async {
    await _run(() async {
      adPolicy = await _metadataApi.setCreatorAdPolicy(
        channelId: channelId,
        allowedCategories: const ['home_energy', 'sustainable_living'],
        blockedCategories: const ['gambling', 'alcohol'],
        formats: const ['pre_roll', 'sponsor_card'],
        surfaces: const ['watch', 'channel'],
        idempotencyKey: 'p2-ad-policy-$channelId',
      );
    });
  }

  Future<void> enableAi() async {
    await _run(() async {
      aiPolicy = await _metadataApi.setAIContentPolicy(
        channelId: channelId,
        archiveQaEnabled: true,
        summariesEnabled: true,
        citationRequired: true,
        idempotencyKey: 'p2-ai-policy-$channelId',
      );
    });
  }

  Future<void> _publish({
    required String title,
    required String summary,
    required ContentType contentType,
    required String idempotencyKey,
    required ContentAccessMode accessMode,
    required MonetizationMode monetizationMode,
  }) async {
    await _run(() async {
      final asset = await _contentHostApi.ingestMedia(
        channelId: channelId,
        contentType: contentType,
        fileName: contentType == ContentType.video
            ? 'home-battery-walkthrough.mp4'
            : 'home-battery-field-notes.md',
        idempotencyKey: '$idempotencyKey-asset',
      );
      lastPublished = await _metadataApi.publishContent(
        channelId: channelId,
        contentType: contentType,
        title: title,
        summary: summary,
        thumbnailRef: asset.thumbnailRef,
        accessMode: accessMode,
        monetizationMode: monetizationMode,
        idempotencyKey: idempotencyKey,
      );
      await _refresh();
    });
  }

  Future<void> _refresh() async {
    manifests = await _metadataApi.contentManifests(channelId);
    tiers = await _metadataApi.membershipTiers(channelId);
    entitlements = await _entitlementLedgerApi.entitlementDefinitions(
      channelId,
    );
    adPolicy = await _metadataApi.creatorAdPolicy(channelId);
    aiPolicy = await _metadataApi.aiContentPolicy(channelId);
  }

  Future<void> _run(Future<void> Function() action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
    } on ApiError catch (error) {
      errorMessage = '${error.code}: ${error.message}';
    } on Object catch (error) {
      errorMessage = error.toString();
    }
    isLoading = false;
    notifyListeners();
  }
}
