import 'package:flutter/foundation.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';

enum CreatorOnboardingStep { channel, hosting, complete }

class CreatorOnboardingController extends ChangeNotifier {
  CreatorOnboardingController({
    required CreatorChannelRegistryApi registryApi,
    required CreatorMetadataApi metadataApi,
  }) : _registryApi = registryApi,
       _metadataApi = metadataApi;

  final CreatorChannelRegistryApi _registryApi;
  final CreatorMetadataApi _metadataApi;

  CreatorOnboardingStep step = CreatorOnboardingStep.channel;
  bool isLoading = false;
  String? errorMessage;
  CreatorChannel? channel;
  CreatorChannelManifest? manifest;
  HostingContract? hostingContract;

  double get progress {
    return switch (step) {
      CreatorOnboardingStep.channel => 0.34,
      CreatorOnboardingStep.hosting => 0.67,
      CreatorOnboardingStep.complete => 1,
    };
  }

  Future<void> createChannel({
    required String displayName,
    required String handle,
    required String description,
    required String vertical,
  }) async {
    await _run(() async {
      final created = await _registryApi.createChannel(
        ownerPassportId: 'creator_demo_owner',
        displayName: displayName,
        vertical: vertical,
        idempotencyKey: 'p1-creator-channel-$handle',
      );
      channel = await _registryApi.bindHandle(
        channelId: created.id,
        handle: handle,
        idempotencyKey: 'p1-creator-handle-$handle',
      );
      manifest = await _metadataApi.createChannelProfile(
        channelId: created.id,
        displayName: displayName,
        handle: handle,
        description: description,
        category: vertical,
        idempotencyKey: 'p1-creator-profile-$handle',
      );
      step = CreatorOnboardingStep.hosting;
    });
  }

  Future<void> acceptManagedHosting() async {
    final currentChannel = channel;
    if (currentChannel == null) {
      return;
    }
    await _run(() async {
      hostingContract = await _metadataApi.attachHostingContract(
        channelId: currentChannel.id,
        provider: 'Loom Managed Hosting',
        termsVersion: 'managed-v1',
        idempotencyKey: 'p1-managed-hosting-${currentChannel.id}',
      );
      step = CreatorOnboardingStep.complete;
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
