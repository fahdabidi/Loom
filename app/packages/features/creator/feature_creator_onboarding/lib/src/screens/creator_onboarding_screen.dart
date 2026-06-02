import 'package:flutter/material.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_design_system/loom_design_system.dart';

import '../state/creator_onboarding_controller.dart';

class CreatorOnboardingScreen extends StatefulWidget {
  const CreatorOnboardingScreen({this.onOpenPublishingSetup, super.key});

  final VoidCallback? onOpenPublishingSetup;

  @override
  State<CreatorOnboardingScreen> createState() =>
      _CreatorOnboardingScreenState();
}

class _CreatorOnboardingScreenState extends State<CreatorOnboardingScreen> {
  late final CreatorOnboardingController _controller;
  late final TextEditingController _displayNameController;
  late final TextEditingController _handleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _verticalController;

  @override
  void initState() {
    super.initState();
    _controller = CreatorOnboardingController(
      registryApi: resolveCreatorChannelRegistryApi(),
      metadataApi: resolveCreatorMetadataApi(),
    );
    _displayNameController = TextEditingController(text: 'Loom Home Lab');
    _handleController = TextEditingController(text: 'loom-home-lab');
    _descriptionController = TextEditingController(
      text:
          'Practical home-energy experiments, plain-English payback math, and durable upgrade checklists.',
    );
    _verticalController = TextEditingController(text: 'Home energy');
  }

  @override
  void dispose() {
    _controller.dispose();
    _displayNameController.dispose();
    _handleController.dispose();
    _descriptionController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final error = _controller.errorMessage;
        return OnboardingScaffold(
          eyebrow: 'Creator onboarding',
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
              _BodyForStep(
                controller: _controller,
                displayNameController: _displayNameController,
                handleController: _handleController,
                descriptionController: _descriptionController,
                verticalController: _verticalController,
              ),
            ],
          ),
          primaryAction: _PrimaryAction(
            controller: _controller,
            displayNameController: _displayNameController,
            handleController: _handleController,
            descriptionController: _descriptionController,
            verticalController: _verticalController,
            onOpenPublishingSetup: widget.onOpenPublishingSetup,
          ),
        );
      },
    );
  }
}

class _BodyForStep extends StatelessWidget {
  const _BodyForStep({
    required this.controller,
    required this.displayNameController,
    required this.handleController,
    required this.descriptionController,
    required this.verticalController,
  });

  final CreatorOnboardingController controller;
  final TextEditingController displayNameController;
  final TextEditingController handleController;
  final TextEditingController descriptionController;
  final TextEditingController verticalController;

  @override
  Widget build(BuildContext context) {
    switch (controller.step) {
      case CreatorOnboardingStep.channel:
        return ChannelSetupForm(
          displayNameController: displayNameController,
          handleController: handleController,
          descriptionController: descriptionController,
          verticalController: verticalController,
        );
      case CreatorOnboardingStep.hosting:
        final manifest = controller.manifest;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StudioPreviewCard(
              title: manifest?.displayName ?? '',
              subtitle: '@${manifest?.handle ?? ''}',
              body:
                  'Managed hosting prepares the channel for the demo: uploaded media is playable, thumbnails and metadata are available to the feed, and future receipts can point to the same hosted assets.',
              icon: Icons.cloud_done_outlined,
            ),
            const SizedBox(height: LoomSpacing.md),
            const _StudioChecklist(),
          ],
        );
      case CreatorOnboardingStep.complete:
        final channel = controller.channel;
        final contract = controller.hostingContract;
        final displayName =
            channel?.displayName ?? 'Creator onboarding complete';
        final handle = channel == null
            ? 'Studio workspace ready'
            : '@${channel.handle}';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StudioPreviewCard(
              title: displayName,
              subtitle: handle,
              body:
                  'Creator onboarding complete. Your channel profile, handle, and hosting contract are ready for publishing setup.',
              icon: Icons.check_circle_rounded,
            ),
            const SizedBox(height: LoomSpacing.md),
            const _StudioFactRow(
              icon: Icons.check_circle_outline_rounded,
              text: 'Creator onboarding complete',
            ),
            if (channel != null)
              _StudioFactRow(
                icon: Icons.badge_outlined,
                text: 'Channel: ${channel.displayName}',
              ),
            if (channel != null)
              _StudioFactRow(
                icon: Icons.alternate_email_rounded,
                text: 'Handle: @${channel.handle}',
              ),
            if (contract != null)
              _StudioFactRow(
                icon: Icons.cloud_done_outlined,
                text: 'Hosting: ${contract.provider} ${contract.status}',
              ),
          ],
        );
    }
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.controller,
    required this.displayNameController,
    required this.handleController,
    required this.descriptionController,
    required this.verticalController,
    required this.onOpenPublishingSetup,
  });

  final CreatorOnboardingController controller;
  final TextEditingController displayNameController;
  final TextEditingController handleController;
  final TextEditingController descriptionController;
  final TextEditingController verticalController;
  final VoidCallback? onOpenPublishingSetup;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (controller.step) {
      case CreatorOnboardingStep.channel:
        return FilledButton.icon(
          key: const ValueKey('creator_create_channel_button'),
          onPressed: () => controller.createChannel(
            displayName: displayNameController.text,
            handle: handleController.text,
            description: descriptionController.text,
            vertical: verticalController.text,
          ),
          icon: const Icon(Icons.add_circle_outline_rounded),
          label: const Text('Create creator channel'),
        );
      case CreatorOnboardingStep.hosting:
        return FilledButton.icon(
          key: const ValueKey('creator_accept_hosting_button'),
          onPressed: controller.acceptManagedHosting,
          icon: const Icon(Icons.cloud_done_outlined),
          label: const Text('Accept managed hosting'),
        );
      case CreatorOnboardingStep.complete:
        final callback = onOpenPublishingSetup;
        if (callback == null) {
          return const SizedBox.shrink();
        }
        return FilledButton.icon(
          key: const ValueKey('creator_open_publishing_setup_button'),
          onPressed: callback,
          icon: const Icon(Icons.dashboard_customize_outlined),
          label: const Text('Open publishing setup'),
        );
    }
  }
}

class _StudioPreviewCard extends StatelessWidget {
  const _StudioPreviewCard({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LoomSpacing.lg),
      decoration: BoxDecoration(
        color: LoomColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: LoomColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: LoomColors.moss.withAlpha(34),
            child: Icon(icon, color: LoomColors.moss),
          ),
          const SizedBox(width: LoomSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: LoomColors.mutedInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: LoomSpacing.sm),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: LoomColors.mutedInk,
                    height: 1.28,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudioChecklist extends StatelessWidget {
  const _StudioChecklist();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _StudioFactRow(
          icon: Icons.play_circle_outline_rounded,
          text: 'Demo media stays ready for feed playback',
        ),
        _StudioFactRow(
          icon: Icons.receipt_long_outlined,
          text: 'Receipts and monetization records point to hosted assets',
        ),
        _StudioFactRow(
          icon: Icons.lock_outline_rounded,
          text: 'Loom manages storage, thumbnails, metadata, and demo policy',
        ),
      ],
    );
  }
}

class _StudioFactRow extends StatelessWidget {
  const _StudioFactRow({required this.icon, required this.text});

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

String _titleForStep(CreatorOnboardingStep step) {
  return switch (step) {
    CreatorOnboardingStep.channel => 'Create your channel',
    CreatorOnboardingStep.hosting => 'Accept managed hosting',
    CreatorOnboardingStep.complete => 'Creator channel ready',
  };
}
