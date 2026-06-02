import 'package:feature_fan_onboarding/feature_fan_onboarding.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';

void main() {
  test(
    'p12 capture controller resolves and bulk follows selected pack',
    () async {
      final captureApi = _CaptureApi();
      final starterPackApi = _StarterPackApi();
      final controller = FanCaptureOnboardingController(
        captureApi: captureApi,
        starterPackApi: starterPackApi,
        captureToken: 'cap_creator_solar_sarah_launch',
      );

      await controller.load();
      expect(controller.landing?.displayName, 'Solar Sarah');
      expect(controller.selectedChannelIds, {
        'creator_solar_sarah',
        'creator_ferment_fran',
        'creator_motion_maya',
      });

      controller.toggleMember('creator_motion_maya');
      expect(
        controller.selectedChannelIds,
        isNot(contains('creator_motion_maya')),
      );

      await controller.confirm();
      expect(captureApi.recordedTokens, ['cap_creator_solar_sarah_launch']);
      expect(starterPackApi.followedRequest, {
        'creator_ferment_fran',
        'creator_solar_sarah',
      });
      expect(controller.feedReady, isTrue);
    },
  );

  test(
    'p12 capture controller keeps already-following members locked',
    () async {
      final controller = FanCaptureOnboardingController(
        captureApi: _CaptureApi(alreadyFollowing: true),
        starterPackApi: _StarterPackApi(alreadyFollowingSource: true),
        captureToken: 'cap_creator_solar_sarah_launch',
      );

      await controller.load();
      controller.toggleMember('creator_solar_sarah');

      expect(controller.selectedChannelIds, contains('creator_solar_sarah'));
    },
  );
}

class _CaptureApi implements FanFollowCaptureApi {
  _CaptureApi({this.alreadyFollowing = false});

  final bool alreadyFollowing;
  final List<String> recordedTokens = [];

  @override
  Future<CaptureLink> createCaptureLink({
    required String channelId,
    required String channel,
    required bool starterPackEnabled,
    DateTime? expiresAt,
    required String idempotencyKey,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<CaptureLandingView> resolveCaptureLink({
    required String token,
    required String passportId,
  }) async {
    return CaptureLandingView(
      channelId: 'creator_solar_sarah',
      handle: 'solar-sarah',
      displayName: 'Solar Sarah',
      avatarRef: 'seed://solar',
      tagline: 'Follow Solar Sarah on Loom and start from a populated feed.',
      alreadyFollowing: alreadyFollowing,
      starterPackToken: 'starter_solar',
    );
  }

  @override
  Future<ReFollowResult> recordReFollow({
    required String token,
    required String passportId,
    required String followVisibility,
    required String idempotencyKey,
  }) async {
    recordedTokens.add(token);
    return ReFollowResult(
      channelId: 'creator_solar_sarah',
      followState: alreadyFollowing
          ? ReFollowState.alreadyFollowing
          : ReFollowState.followed,
      pairwiseCreatorFanId: 'pair_solar_demo',
      auditReceiptId: 'audit_solar_demo',
      createdAt: DateTime.utc(2026, 6, 2),
    );
  }
}

class _StarterPackApi implements StarterPackApi {
  _StarterPackApi({this.alreadyFollowingSource = false});

  final bool alreadyFollowingSource;
  Set<String> followedRequest = const {};

  @override
  Future<StarterPack> getStarterPack({
    required String channelId,
    required String passportId,
    int limit = 6,
  }) async {
    return StarterPack(
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
          alreadyFollowing: alreadyFollowingSource,
        ),
        const StarterPackMember(
          channelId: 'creator_ferment_fran',
          handle: 'ferment-fran',
          displayName: 'Ferment Fran',
          avatarRef: 'seed://ferment',
          role: StarterPackMemberRole.recommended,
          defaultSelected: true,
          alreadyFollowing: false,
          recommendationReason: 'Recommended for practical projects.',
        ),
        const StarterPackMember(
          channelId: 'creator_motion_maya',
          handle: 'motion-maya',
          displayName: 'Motion Maya',
          avatarRef: 'seed://motion',
          role: StarterPackMemberRole.recommended,
          defaultSelected: true,
          alreadyFollowing: false,
          recommendationReason: 'Recommended for active routines.',
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
    followedRequest = channelIds.toSet();
    return BulkFollowResult(
      followed: channelIds,
      alreadyFollowing: const [],
      feedReady: channelIds.length >= 2,
    );
  }
}
