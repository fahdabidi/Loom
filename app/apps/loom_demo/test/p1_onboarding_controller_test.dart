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
  Future<FanPassportClaim?> getPassport(String passportId) async => null;

  @override
  Future<List<FollowView>> listFollows(String passportId) async => const [];

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
}
