import 'package:feature_fan_onboarding/feature_fan_onboarding.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';

void main() {
  test('interest token mapper keeps only displayed fields', () {
    const token = InterestToken(
      id: 'mobility',
      label: 'Mobility',
      category: 'Movement',
    );

    final item = mapInterestToken(token);

    expect(item.id, 'mobility');
    expect(item.label, 'Mobility');
    expect(item.category, 'Movement');
  });

  test('fan onboarding writes interests in one batch', () async {
    final controller = FanOnboardingController(
      passportApi: _FakePassportApi(),
      vaultApi: _FakeVaultApi(),
      creatorMetadataApi: _FakeCreatorMetadataApi(),
      starterPackApi: _FakeStarterPackApi(),
    );

    await controller.load();
    await controller.createPassport();
    for (final token in controller.taxonomy.take(10)) {
      controller.toggleInterest(token.id);
    }
    await controller.saveInterests();

    expect(controller.step, FanOnboardingStep.privacy);
    expect(controller.interestProfile?.interests.length, 10);
    expect(controller.interestBatchWriteCount, 1);
    expect(controller.taxonomyFetchCount, 1);
  });

  test('fan onboarding exposes multiple suggested creators', () async {
    final controller = FanOnboardingController(
      passportApi: _FakePassportApi(),
      vaultApi: _FakeVaultApi(),
      creatorMetadataApi: _FakeCreatorMetadataApi(),
      starterPackApi: _FakeStarterPackApi(),
    );

    await controller.load();

    expect(controller.recommendedCreators, hasLength(4));
    expect(controller.selectedRecommendedCreatorIds, {
      'creator_solar_sarah',
      'creator_ferment_fran',
      'creator_motion_maya',
      'creator_lena_code',
    });

    controller.toggleRecommendedCreator('creator_lena_code');
    expect(
      controller.selectedRecommendedCreatorIds,
      isNot(contains('creator_lena_code')),
    );
  });
}

class _FakePassportApi implements FanPassportApi {
  @override
  Future<FanPassportClaim> createPassport({
    required String displayName,
    required String idempotencyKey,
  }) async {
    return FanPassportClaim(
      id: 'passport_test',
      displayName: displayName,
      activePersonaId: 'persona_test',
      createdAt: DateTime.utc(2026),
    );
  }

  @override
  Future<ConsentGrant> createConsentGrant({
    required String passportId,
    required String grantType,
    required String idempotencyKey,
  }) async {
    return ConsentGrant(
      id: 'grant_test',
      passportId: passportId,
      grantType: grantType,
      createdAt: DateTime.utc(2026),
    );
  }

  @override
  Future<FollowView> createFollow({
    required String passportId,
    required String creatorId,
    required FollowVisibility visibility,
    required String idempotencyKey,
  }) async {
    return FollowView(
      id: 'follow_test',
      passportId: passportId,
      creatorId: creatorId,
      creatorDisplayName: 'Solar Sarah',
      visibility: visibility,
      blocked: false,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
  }

  @override
  Future<FollowView> blockCreator({
    required String passportId,
    required String creatorId,
    required String idempotencyKey,
  }) async {
    return FollowView(
      id: 'follow_blocked',
      passportId: passportId,
      creatorId: creatorId,
      creatorDisplayName: 'Solar Sarah',
      visibility: FollowVisibility.private,
      blocked: true,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
  }

  @override
  Future<FanPassportClaim?> getPassport(String passportId) async => null;

  @override
  Future<List<FollowView>> listFollows(String passportId) async => const [];

  @override
  Future<FollowView?> unfollow({
    required String passportId,
    required String creatorId,
    required String idempotencyKey,
  }) async {
    return null;
  }

  @override
  Future<Persona> setPersona({
    required String passportId,
    required String label,
    required String idempotencyKey,
  }) async {
    return Persona(
      id: 'persona_test',
      passportId: passportId,
      label: label,
      isActive: true,
    );
  }

  @override
  Future<FollowView> setFollowVisibility({
    required String followId,
    required FollowVisibility visibility,
    required String idempotencyKey,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<DataConsentGrant> reviewDataGrantRequest({
    required String requestId,
    required String passportId,
    required ConsentGrantState state,
    required List<String> approvedFields,
    required String idempotencyKey,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<DataConsentGrant> narrowGrant({
    required String grantId,
    required List<String> approvedFields,
    required String idempotencyKey,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<DataConsentGrant> revokeGrant({
    required String grantId,
    required String idempotencyKey,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<CategoryDefault> setCategoryDefault({
    required String passportId,
    required String category,
    required ConsentGrantState state,
    required String idempotencyKey,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<FollowView> revokeDirectContact({
    required String passportId,
    required String creatorId,
    required String idempotencyKey,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TombstoneRequest> requestTombstone({
    required String passportId,
    required String creatorId,
    required String idempotencyKey,
  }) async {
    throw UnimplementedError();
  }
}

class _FakeVaultApi implements FanVaultApi {
  final _tokens = List.generate(
    12,
    (index) => InterestToken(
      id: 'interest_$index',
      label: 'Interest $index',
      category: 'Category',
    ),
  );

  @override
  Future<List<InterestToken>> getInterestTaxonomy() async => _tokens;

  @override
  Future<InterestProfile> getInterestProfile(String passportId) async {
    return InterestProfile(
      passportId: passportId,
      interests: const [],
      dislikedInterestIds: const [],
      dislikedCreatorIds: const [],
      mutedProviderIds: const [],
      updatedAt: DateTime.utc(2026),
    );
  }

  @override
  Future<AdPreferences> getAdPreferences(String passportId) async {
    return AdPreferences(
      passportId: passportId,
      personalizedAds: false,
      updatedAt: DateTime.utc(2026),
    );
  }

  @override
  Future<AdPreferences> putAdPreferences({
    required String passportId,
    required bool personalizedAds,
    required String idempotencyKey,
  }) async {
    return AdPreferences(
      passportId: passportId,
      personalizedAds: personalizedAds,
      updatedAt: DateTime.utc(2026),
    );
  }

  @override
  Future<RankPreference> getRankPreference(String passportId) async {
    return RankPreference(
      passportId: passportId,
      summaryFirst: false,
      updatedAt: DateTime.utc(2026),
    );
  }

  @override
  Future<RankPreference> putRankPreference({
    required String passportId,
    required bool summaryFirst,
    required String idempotencyKey,
  }) async {
    return RankPreference(
      passportId: passportId,
      summaryFirst: summaryFirst,
      updatedAt: DateTime.utc(2026),
    );
  }

  @override
  Future<InterestProfile> putDislikes({
    required String passportId,
    required List<String> dislikedInterestIds,
    required String idempotencyKey,
  }) async {
    return getInterestProfile(passportId);
  }

  @override
  Future<InterestProfile> putInterests({
    required String passportId,
    required List<String> interestIds,
    required String idempotencyKey,
  }) async {
    return InterestProfile(
      passportId: passportId,
      interests: _tokens
          .where((token) => interestIds.contains(token.id))
          .toList(growable: false),
      dislikedInterestIds: const [],
      dislikedCreatorIds: const [],
      mutedProviderIds: const [],
      updatedAt: DateTime.utc(2026),
    );
  }
}

class _FakeCreatorMetadataApi implements CreatorMetadataApi {
  @override
  Future<Page<ContentSummaryView>> getPublicCatalog(
    String channelId, {
    String? cursor,
    int limit = 10,
  }) async {
    return const Page(
      items: [
        ContentSummaryView(
          id: 'content_test',
          creatorId: 'creator_solar_sarah',
          creatorDisplayName: 'Solar Sarah',
          title: 'Solar test',
          summary: 'Summary',
          thumbnailRef: 'seed://thumb',
          contentType: ContentType.video,
        ),
      ],
      nextCursor: null,
    );
  }

  @override
  Future<ChannelHome> getChannelHome({
    required String channelId,
    required String passportId,
  }) async {
    return const ChannelHome(
      creatorId: 'creator_solar_sarah',
      displayName: 'Solar Sarah',
      handle: 'solar-sarah',
      vertical: 'home-energy',
      avatarRef: 'seed://avatar',
      isFollowed: false,
      isBlocked: false,
      visibilityLabel: 'private',
      content: [],
      adPolicy: null,
    );
  }

  @override
  Future<ContentDetail> getContentDetail(String contentId) async {
    return ContentDetail(
      id: contentId,
      creatorId: 'creator_solar_sarah',
      creatorDisplayName: 'Solar Sarah',
      title: 'Solar test',
      summary: 'Summary',
      body: 'Body',
      thumbnailRef: 'seed://thumb',
      contentType: ContentType.video,
      createdAt: DateTime.utc(2026),
    );
  }

  @override
  Future<HostingContract> attachHostingContract({
    required String channelId,
    required String provider,
    required String termsVersion,
    required String idempotencyKey,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<CreatorChannelManifest> createChannelProfile({
    required String channelId,
    required String displayName,
    required String handle,
    required String description,
    required String category,
    required String idempotencyKey,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<ContentManifest>> contentManifests(String channelId) async {
    return const [];
  }

  @override
  Future<CreatorAdPolicy?> creatorAdPolicy(String channelId) async => null;

  @override
  Future<List<MembershipTier>> defineMembershipTiers({
    required String channelId,
    required List<MembershipTierDraft> tiers,
    required String idempotencyKey,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AIContentPolicy?> aiContentPolicy(String channelId) async => null;

  @override
  Future<List<MembershipTier>> membershipTiers(String channelId) async {
    return const [];
  }

  @override
  Future<ContentManifest> publishContent({
    required String channelId,
    required ContentType contentType,
    required String title,
    required String summary,
    required String thumbnailRef,
    required ContentAccessMode accessMode,
    required MonetizationMode monetizationMode,
    required String idempotencyKey,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AIContentPolicy> setAIContentPolicy({
    required String channelId,
    required bool archiveQaEnabled,
    required bool summariesEnabled,
    required bool citationRequired,
    required String idempotencyKey,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<CreatorAdPolicy> setCreatorAdPolicy({
    required String channelId,
    required List<String> allowedCategories,
    required List<String> blockedCategories,
    required List<String> formats,
    required List<String> surfaces,
    required String idempotencyKey,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<MonetizationManifest> updateMonetizationManifest({
    required String channelId,
    required bool membershipsEnabled,
    required List<String> memberOnlyContentIds,
    required String idempotencyKey,
  }) async {
    throw UnimplementedError();
  }
}

class _FakeStarterPackApi implements StarterPackApi {
  @override
  Future<StarterPack> getStarterPack({
    required String channelId,
    required String passportId,
    int limit = 6,
  }) async {
    return const StarterPack(
      sourceChannelId: 'creator_solar_sarah',
      starterPackToken: 'starter_solar',
      members: [
        StarterPackMember(
          channelId: 'creator_solar_sarah',
          handle: 'solar-sarah',
          displayName: 'Solar Sarah',
          avatarRef: 'seed://solar',
          role: StarterPackMemberRole.source,
          defaultSelected: true,
          alreadyFollowing: false,
        ),
        StarterPackMember(
          channelId: 'creator_ferment_fran',
          handle: 'ferment-fran',
          displayName: 'Ferment Fran',
          avatarRef: 'seed://ferment',
          role: StarterPackMemberRole.recommended,
          defaultSelected: true,
          alreadyFollowing: false,
          recommendationReason: 'Recommended for food projects.',
        ),
        StarterPackMember(
          channelId: 'creator_motion_maya',
          handle: 'motion-maya',
          displayName: 'Motion Maya',
          avatarRef: 'seed://motion',
          role: StarterPackMemberRole.recommended,
          defaultSelected: true,
          alreadyFollowing: false,
          recommendationReason: 'Recommended for movement.',
        ),
        StarterPackMember(
          channelId: 'creator_lena_code',
          handle: 'lena-code',
          displayName: 'Lena Code',
          avatarRef: 'seed://code',
          role: StarterPackMemberRole.recommended,
          defaultSelected: true,
          alreadyFollowing: false,
          recommendationReason: 'Recommended for tool builders.',
        ),
      ],
    );
  }

  @override
  Future<StarterPack> putStarterPack({
    required String channelId,
    required String passportId,
    required List<String> memberChannelIds,
    required List<String> defaultSelectedChannelIds,
    required String idempotencyKey,
  }) {
    return getStarterPack(channelId: channelId, passportId: passportId);
  }

  @override
  Future<BulkFollowResult> bulkFollow({
    required String channelId,
    required String passportId,
    required List<String> channelIds,
    required String followVisibility,
    required String idempotencyKey,
  }) async {
    throw UnimplementedError();
  }
}
