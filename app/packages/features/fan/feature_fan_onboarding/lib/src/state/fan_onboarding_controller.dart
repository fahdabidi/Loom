import 'package:flutter/foundation.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';

enum FanOnboardingStep { welcome, interests, privacy, firstFollow, complete }

class FanOnboardingController extends ChangeNotifier {
  FanOnboardingController({
    required FanPassportApi passportApi,
    required FanVaultApi vaultApi,
    required CreatorMetadataApi creatorMetadataApi,
  }) : _passportApi = passportApi,
       _vaultApi = vaultApi,
       _creatorMetadataApi = creatorMetadataApi;

  final FanPassportApi _passportApi;
  final FanVaultApi _vaultApi;
  final CreatorMetadataApi _creatorMetadataApi;

  FanOnboardingStep step = FanOnboardingStep.welcome;
  bool isLoading = false;
  String? errorMessage;
  List<InterestToken> taxonomy = const [];
  Set<String> selectedInterestIds = <String>{};
  FollowVisibility selectedVisibility = FollowVisibility.private;
  FanPassportClaim? passport;
  InterestProfile? interestProfile;
  FollowView? follow;
  String? recommendedCreatorId;
  String? recommendedCreatorName;
  int taxonomyFetchCount = 0;
  int interestBatchWriteCount = 0;

  double get progress {
    return switch (step) {
      FanOnboardingStep.welcome => 0.2,
      FanOnboardingStep.interests => 0.4,
      FanOnboardingStep.privacy => 0.6,
      FanOnboardingStep.firstFollow => 0.8,
      FanOnboardingStep.complete => 1,
    };
  }

  bool get canSaveInterests => selectedInterestIds.length >= 10 && !isLoading;

  Future<void> load() async {
    if (taxonomy.isNotEmpty) {
      return;
    }
    await _run(() async {
      taxonomy = await _vaultApi.getInterestTaxonomy();
      taxonomyFetchCount++;
      final page = await _creatorMetadataApi.getPublicCatalog(
        'creator_solar_sarah',
        limit: 1,
      );
      if (page.items.isNotEmpty) {
        recommendedCreatorId = page.items.first.creatorId;
        recommendedCreatorName = page.items.first.creatorDisplayName;
      }
    });
  }

  Future<void> createPassport() async {
    await _run(() async {
      final created = await _passportApi.createPassport(
        displayName: 'Demo Fan',
        idempotencyKey: 'p1-fan-passport-demo-fan',
      );
      passport = created;
      await _passportApi.setPersona(
        passportId: created.id,
        label: 'Everyday fan',
        idempotencyKey: 'p1-fan-persona-everyday',
      );
      await _passportApi.createConsentGrant(
        passportId: created.id,
        grantType: 'baseline_privacy_controls',
        idempotencyKey: 'p1-fan-baseline-consent',
      );
      step = FanOnboardingStep.interests;
    });
  }

  void toggleInterest(String id) {
    final next = Set<String>.from(selectedInterestIds);
    if (!next.add(id)) {
      next.remove(id);
    }
    selectedInterestIds = next;
    notifyListeners();
  }

  Future<void> saveInterests() async {
    final currentPassport = passport;
    if (currentPassport == null || !canSaveInterests) {
      return;
    }
    await _run(() async {
      interestProfile = await _vaultApi.putInterests(
        passportId: currentPassport.id,
        interestIds: selectedInterestIds.toList(growable: false),
        idempotencyKey: 'p1-fan-interests-batch',
      );
      interestBatchWriteCount++;
      step = FanOnboardingStep.privacy;
    });
  }

  void setVisibility(FollowVisibility visibility) {
    selectedVisibility = visibility;
    notifyListeners();
  }

  void continueFromPrivacy() {
    step = FanOnboardingStep.firstFollow;
    notifyListeners();
  }

  Future<void> createFirstFollow() async {
    final currentPassport = passport;
    final creatorId = recommendedCreatorId;
    if (currentPassport == null || creatorId == null) {
      return;
    }
    await _run(() async {
      follow = await _passportApi.createFollow(
        passportId: currentPassport.id,
        creatorId: creatorId,
        visibility: selectedVisibility,
        idempotencyKey: 'p1-fan-first-follow-$creatorId',
      );
      step = FanOnboardingStep.complete;
    });
  }

  Future<void> toggleFollowVisibility() async {
    final currentFollow = follow;
    if (currentFollow == null) {
      return;
    }
    final nextVisibility = currentFollow.visibility == FollowVisibility.private
        ? FollowVisibility.public
        : FollowVisibility.private;
    await _run(() async {
      follow = await _passportApi.setFollowVisibility(
        followId: currentFollow.id,
        visibility: nextVisibility,
        idempotencyKey: 'p1-fan-follow-visibility-${nextVisibility.name}',
      );
      selectedVisibility = nextVisibility;
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
    } on ApiError catch (error) {
      errorMessage = error.message;
    } on Object catch (error) {
      errorMessage = error.toString();
    }
    isLoading = false;
    notifyListeners();
  }
}
