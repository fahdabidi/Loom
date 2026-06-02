import 'package:flutter/foundation.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';

class FanCaptureOnboardingController extends ChangeNotifier {
  FanCaptureOnboardingController({
    required FanFollowCaptureApi captureApi,
    required StarterPackApi starterPackApi,
    required this.captureToken,
    this.passportId = 'passport_demo_fan',
  }) : _captureApi = captureApi,
       _starterPackApi = starterPackApi;

  final FanFollowCaptureApi _captureApi;
  final StarterPackApi _starterPackApi;
  final String captureToken;
  final String passportId;

  bool loading = false;
  bool confirming = false;
  String? errorMessage;
  CaptureLandingView? landing;
  StarterPack? starterPack;
  ReFollowResult? reFollowResult;
  BulkFollowResult? bulkFollowResult;
  Set<String> selectedChannelIds = <String>{};

  bool get hasResolved => landing != null && starterPack != null;
  bool get feedReady => bulkFollowResult?.feedReady ?? false;

  Future<void> load() async {
    if (hasResolved || loading) {
      return;
    }
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final resolved = await _captureApi.resolveCaptureLink(
        token: captureToken,
        passportId: passportId,
      );
      landing = resolved;
      final pack = await _starterPackApi.getStarterPack(
        channelId: resolved.channelId,
        passportId: passportId,
        limit: 6,
      );
      starterPack = pack;
      selectedChannelIds = pack.members
          .where((member) => member.defaultSelected || member.alreadyFollowing)
          .map((member) => member.channelId)
          .toSet();
    } on ApiError catch (error) {
      errorMessage = error.message;
    } on Object catch (error) {
      errorMessage = '$error';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void toggleMember(String channelId) {
    final member = _memberById(channelId);
    if (member == null || member.alreadyFollowing) {
      return;
    }
    final next = Set<String>.from(selectedChannelIds);
    if (!next.add(channelId)) {
      next.remove(channelId);
    }
    selectedChannelIds = next;
    notifyListeners();
  }

  StarterPackMember? _memberById(String channelId) {
    final members = starterPack?.members ?? const <StarterPackMember>[];
    for (final member in members) {
      if (member.channelId == channelId) {
        return member;
      }
    }
    return null;
  }

  Future<void> confirm() async {
    final resolved = landing;
    final selected = selectedChannelIds.toList(growable: false)..sort();
    if (resolved == null || selected.isEmpty || confirming) {
      return;
    }
    confirming = true;
    errorMessage = null;
    notifyListeners();
    try {
      reFollowResult = await _captureApi.recordReFollow(
        token: captureToken,
        passportId: passportId,
        followVisibility: FollowVisibility.private.name,
        idempotencyKey: 'p12-refollow-$passportId-$captureToken',
      );
      bulkFollowResult = await _starterPackApi.bulkFollow(
        channelId: resolved.channelId,
        passportId: passportId,
        channelIds: selected,
        followVisibility: FollowVisibility.private.name,
        idempotencyKey:
            'p12-starter-pack-$passportId-${resolved.channelId}-${selected.join('-')}',
      );
    } on ApiError catch (error) {
      errorMessage = error.message;
    } on Object catch (error) {
      errorMessage = '$error';
    } finally {
      confirming = false;
      notifyListeners();
    }
  }
}
