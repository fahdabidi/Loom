import 'package:flutter/material.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_design_system/loom_design_system.dart';

import '../state/creator_onboarding_controller.dart';

class CreatorOnboardingScreen extends StatefulWidget {
  const CreatorOnboardingScreen({super.key});

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
            Text('Channel: ${manifest?.displayName ?? ''}'),
            Text('@${manifest?.handle ?? ''}'),
            const SizedBox(height: LoomSpacing.md),
            const Text(
              'Managed hosting keeps the demo content available for fan playback in later phases.',
            ),
          ],
        );
      case CreatorOnboardingStep.complete:
        final channel = controller.channel;
        final contract = controller.hostingContract;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Creator onboarding complete'),
            if (channel != null) Text('Channel: ${channel.displayName}'),
            if (channel != null) Text('@${channel.handle}'),
            if (contract != null)
              Text('Hosting: ${contract.provider} ${contract.status}'),
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
  });

  final CreatorOnboardingController controller;
  final TextEditingController displayNameController;
  final TextEditingController handleController;
  final TextEditingController descriptionController;
  final TextEditingController verticalController;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (controller.step) {
      case CreatorOnboardingStep.channel:
        return FilledButton(
          key: const ValueKey('creator_create_channel_button'),
          onPressed: () => controller.createChannel(
            displayName: displayNameController.text,
            handle: handleController.text,
            description: descriptionController.text,
            vertical: verticalController.text,
          ),
          child: const Text('Create creator channel'),
        );
      case CreatorOnboardingStep.hosting:
        return FilledButton(
          key: const ValueKey('creator_accept_hosting_button'),
          onPressed: controller.acceptManagedHosting,
          child: const Text('Accept managed hosting'),
        );
      case CreatorOnboardingStep.complete:
        return const SizedBox.shrink();
    }
  }
}

String _titleForStep(CreatorOnboardingStep step) {
  return switch (step) {
    CreatorOnboardingStep.channel => 'Create your channel',
    CreatorOnboardingStep.hosting => 'Accept managed hosting',
    CreatorOnboardingStep.complete => 'Creator channel ready',
  };
}
