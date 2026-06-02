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
      starterPackApi: resolveStarterPackApi(),
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
        return const _OnboardingHeroCard(
          icon: Icons.person_add_alt_1_rounded,
          title: 'Your fan passport powers every recommendation.',
          body:
              'Create a portable identity, pick the topics you want, and choose how your first follow appears.',
        );
      case FanOnboardingStep.interests:
        if (controller.taxonomy.isEmpty && controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SelectionMeter(
              selectedCount: controller.selectedInterestIds.length,
              requiredCount: 10,
            ),
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
            const _OnboardingHeroCard(
              icon: Icons.privacy_tip_outlined,
              title: 'Set the default before you follow.',
              body:
                  'Loom keeps relationship choices explicit. You can change this visibility later from your profile.',
            ),
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
        return _SuggestedCreatorPack(
          members: controller.recommendedCreators,
          selectedIds: controller.selectedRecommendedCreatorIds,
          visibility: controller.selectedVisibility.label,
          onToggle: controller.toggleRecommendedCreator,
        );
      case FanOnboardingStep.complete:
        final follow = controller.follow;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _OnboardingHeroCard(
              icon: Icons.check_circle_rounded,
              title: 'Fan onboarding complete',
              body:
                  'Your demo passport has interests, a privacy baseline, and a first creator relationship.',
            ),
            const SizedBox(height: LoomSpacing.md),
            _CompletionRow(
              icon: Icons.interests_rounded,
              text:
                  'Interests saved: ${controller.interestProfile?.interests.length ?? 0}',
            ),
            _CompletionRow(
              icon: Icons.sync_alt_rounded,
              text:
                  'Interest batch writes: ${controller.interestBatchWriteCount}',
            ),
            _CompletionRow(
              icon: Icons.category_rounded,
              text: 'Taxonomy fetches: ${controller.taxonomyFetchCount}',
            ),
            if (follow != null) ...[
              _CompletionRow(
                icon: Icons.person_add_alt_1_rounded,
                text:
                    'Following ${controller.firstFollows.length} starter creators',
              ),
              _CompletionRow(
                icon: Icons.visibility_rounded,
                text: 'Visibility: ${follow.visibility.label}',
              ),
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
          onPressed: controller.selectedRecommendedCreatorIds.isEmpty
              ? null
              : controller.createFirstFollow,
          child: const Text('Follow selected'),
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

class _OnboardingHeroCard extends StatelessWidget {
  const _OnboardingHeroCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LoomSpacing.lg),
      decoration: BoxDecoration(
        color: LoomColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: LoomColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: LoomColors.aqua.withAlpha(32),
            child: Icon(icon, color: LoomColors.aqua),
          ),
          const SizedBox(height: LoomSpacing.md),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.08,
            ),
          ),
          const SizedBox(height: LoomSpacing.sm),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: LoomColors.mutedInk,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionMeter extends StatelessWidget {
  const _SelectionMeter({
    required this.selectedCount,
    required this.requiredCount,
  });

  final int selectedCount;
  final int requiredCount;

  @override
  Widget build(BuildContext context) {
    final progress = (selectedCount / requiredCount).clamp(0, 1).toDouble();

    return Container(
      padding: const EdgeInsets.all(LoomSpacing.md),
      decoration: BoxDecoration(
        color: LoomColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LoomColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$selectedCount/$requiredCount selected',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              const Icon(Icons.touch_app_rounded, color: LoomColors.mutedInk),
            ],
          ),
          const SizedBox(height: LoomSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: progress,
              backgroundColor: LoomColors.line,
              valueColor: const AlwaysStoppedAnimation<Color>(LoomColors.ink),
            ),
          ),
          const SizedBox(height: LoomSpacing.sm),
          Text(
            'Pick across categories to seed the first discovery model.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: LoomColors.mutedInk),
          ),
        ],
      ),
    );
  }
}

class _SuggestedCreatorPack extends StatelessWidget {
  const _SuggestedCreatorPack({
    required this.members,
    required this.selectedIds,
    required this.visibility,
    required this.onToggle,
  });

  final List<StarterPackMember> members;
  final Set<String> selectedIds;
  final String visibility;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const _OnboardingHeroCard(
        icon: Icons.person_add_alt_1_rounded,
        title: 'Suggested creators are loading.',
        body: 'The first follow step uses the starter-pack graph.',
      );
    }
    return Column(
      key: const ValueKey('fan_suggested_creator_pack'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OnboardingHeroCard(
          icon: Icons.group_add_rounded,
          title: 'Start with a creator-led pack.',
          body:
              'Rows are default-selected like modern starter packs. Each follow uses $visibility visibility.',
        ),
        const SizedBox(height: LoomSpacing.md),
        for (final member in members) ...[
          StarterPackMemberRow(
            member: StarterPackMemberView(
              channelId: member.channelId,
              displayName: member.displayName,
              handle: member.handle,
              reason:
                  member.recommendationReason ??
                  'The source creator for your starter pack.',
              avatarRef: member.avatarRef,
              isSourceCreator: member.role == StarterPackMemberRole.source,
              alreadyFollowing: member.alreadyFollowing,
            ),
            selected: selectedIds.contains(member.channelId),
            onToggle: () => onToggle(member.channelId),
          ),
          const SizedBox(height: LoomSpacing.sm),
        ],
      ],
    );
  }
}

class _CompletionRow extends StatelessWidget {
  const _CompletionRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LoomSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(LoomSpacing.md),
        decoration: BoxDecoration(
          color: LoomColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: LoomColors.line),
        ),
        child: Row(
          children: [
            Icon(icon, color: LoomColors.ink),
            const SizedBox(width: LoomSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _titleForStep(FanOnboardingStep step) {
  return switch (step) {
    FanOnboardingStep.welcome => 'Set up your fan passport',
    FanOnboardingStep.interests => 'Pick at least 10 interests',
    FanOnboardingStep.privacy => 'Set first-follow privacy',
    FanOnboardingStep.firstFollow => 'Follow suggested creators',
    FanOnboardingStep.complete => 'Fan passport ready',
  };
}
