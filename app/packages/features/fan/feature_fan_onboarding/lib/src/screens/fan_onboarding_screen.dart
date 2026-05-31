import 'package:flutter/material.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_design_system/loom_design_system.dart';

import '../mappers/interest_token_mapper.dart';
import '../state/fan_onboarding_controller.dart';

class FanOnboardingScreen extends StatefulWidget {
  const FanOnboardingScreen({super.key});

  @override
  State<FanOnboardingScreen> createState() => _FanOnboardingScreenState();
}

class _FanOnboardingScreenState extends State<FanOnboardingScreen> {
  late final FanOnboardingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FanOnboardingController(
      passportApi: resolveFanPassportApi(),
      vaultApi: resolveFanVaultApi(),
      creatorMetadataApi: resolveCreatorMetadataApi(),
    )..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final error = _controller.errorMessage;
        return OnboardingScaffold(
          eyebrow: 'Fan onboarding',
          title: _titleForStep(_controller.step),
          progress: _controller.progress,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (error != null) ...[
                Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: LoomSpacing.md),
              ],
              _BodyForStep(controller: _controller),
            ],
          ),
          primaryAction: _PrimaryAction(controller: _controller),
        );
      },
    );
  }
}

class _BodyForStep extends StatelessWidget {
  const _BodyForStep({required this.controller});

  final FanOnboardingController controller;

  @override
  Widget build(BuildContext context) {
    switch (controller.step) {
      case FanOnboardingStep.welcome:
        return const Text(
          'Create a demo fan passport, then choose interests and a first follow privacy default.',
        );
      case FanOnboardingStep.interests:
        if (controller.taxonomy.isEmpty && controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${controller.selectedInterestIds.length}/10 selected'),
            const SizedBox(height: LoomSpacing.md),
            InterestChipGrid(
              items: controller.taxonomy
                  .map(mapInterestToken)
                  .toList(growable: false),
              selectedIds: controller.selectedInterestIds,
              onToggle: controller.toggleInterest,
            ),
          ],
        );
      case FanOnboardingStep.privacy:
        final selectedIndex =
            controller.selectedVisibility == FollowVisibility.private ? 0 : 1;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose how the first follow appears to others.'),
            const SizedBox(height: LoomSpacing.md),
            PersonaSelector(
              options: const ['Private', 'Public'],
              selectedIndex: selectedIndex,
              onChanged: (index) => controller.setVisibility(
                index == 0 ? FollowVisibility.private : FollowVisibility.public,
              ),
            ),
          ],
        );
      case FanOnboardingStep.firstFollow:
        return Text(
          'Follow ${controller.recommendedCreatorName ?? 'the seeded creator'} using the selected ${controller.selectedVisibility.label.toLowerCase()} visibility.',
        );
      case FanOnboardingStep.complete:
        final follow = controller.follow;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fan onboarding complete'),
            const SizedBox(height: LoomSpacing.sm),
            Text(
              'Interests saved: ${controller.interestProfile?.interests.length ?? 0}',
            ),
            Text(
              'Interest batch writes: ${controller.interestBatchWriteCount}',
            ),
            Text('Taxonomy fetches: ${controller.taxonomyFetchCount}'),
            if (follow != null) ...[
              Text('Following ${follow.creatorDisplayName}'),
              Text('Visibility: ${follow.visibility.label}'),
            ],
          ],
        );
    }
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({required this.controller});

  final FanOnboardingController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (controller.step) {
      case FanOnboardingStep.welcome:
        return FilledButton(
          key: const ValueKey('fan_create_passport_button'),
          onPressed: controller.createPassport,
          child: const Text('Create fan passport'),
        );
      case FanOnboardingStep.interests:
        return FilledButton(
          key: const ValueKey('fan_save_interests_button'),
          onPressed: controller.canSaveInterests
              ? controller.saveInterests
              : null,
          child: const Text('Save interests'),
        );
      case FanOnboardingStep.privacy:
        return FilledButton(
          key: const ValueKey('fan_continue_privacy_button'),
          onPressed: controller.continueFromPrivacy,
          child: const Text('Continue'),
        );
      case FanOnboardingStep.firstFollow:
        return FilledButton(
          key: const ValueKey('fan_first_follow_button'),
          onPressed: controller.createFirstFollow,
          child: const Text('Follow creator'),
        );
      case FanOnboardingStep.complete:
        return OutlinedButton(
          key: const ValueKey('fan_toggle_visibility_button'),
          onPressed: controller.toggleFollowVisibility,
          child: const Text('Toggle follow visibility'),
        );
    }
  }
}

String _titleForStep(FanOnboardingStep step) {
  return switch (step) {
    FanOnboardingStep.welcome => 'Set up your fan passport',
    FanOnboardingStep.interests => 'Pick at least 10 interests',
    FanOnboardingStep.privacy => 'Set first-follow privacy',
    FanOnboardingStep.firstFollow => 'Follow a creator',
    FanOnboardingStep.complete => 'Fan passport ready',
  };
}
