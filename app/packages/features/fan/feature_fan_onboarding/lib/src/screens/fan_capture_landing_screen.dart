import 'package:flutter/material.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_design_system/loom_design_system.dart';

import '../state/fan_capture_onboarding_controller.dart';

class FanCaptureLandingScreen extends StatefulWidget {
  const FanCaptureLandingScreen({
    required this.captureToken,
    required this.onDone,
    this.onBack,
    super.key,
  });

  final String captureToken;
  final VoidCallback onDone;
  final VoidCallback? onBack;

  @override
  State<FanCaptureLandingScreen> createState() =>
      _FanCaptureLandingScreenState();
}

class _FanCaptureLandingScreenState extends State<FanCaptureLandingScreen> {
  late final FanCaptureOnboardingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FanCaptureOnboardingController(
      captureToken: widget.captureToken,
      captureApi: resolveFanFollowCaptureApi(),
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
        if (_controller.loading && !_controller.hasResolved) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: LoadingSkeleton(title: 'Opening creator invite', rows: 4),
          );
        }
        final error = _controller.errorMessage;
        final landing = _controller.landing;
        final pack = _controller.starterPack;
        if (error != null && landing == null) {
          return _ErrorState(message: error, onBack: widget.onBack);
        }
        if (landing == null || pack == null) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: LoadingSkeleton(title: 'Preparing starter pack', rows: 3),
          );
        }
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Creator invite'),
            actions: [
              if (widget.onBack != null)
                TextButton.icon(
                  key: const ValueKey('p12_capture_back_button'),
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Return to Feed'),
                ),
            ],
          ),
          body: ListView(
            key: const ValueKey('p12_capture_landing_scroll'),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            children: [
              CreatorCaptureLandingPanel(
                displayName: landing.displayName,
                handle: landing.handle,
                tagline: landing.tagline,
                avatarRef: landing.avatarRef,
                alreadyFollowing: landing.alreadyFollowing,
              ),
              const SizedBox(height: LoomSpacing.md),
              StarterPackSheet(
                members: pack.members.map(_mapMember).toList(growable: false),
                selectedIds: _controller.selectedChannelIds,
                busy: _controller.confirming,
                onToggle: _controller.toggleMember,
                onConfirm: _confirmAndEnterFeed,
              ),
              if (error != null) ...[
                const SizedBox(height: LoomSpacing.md),
                Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmAndEnterFeed() async {
    await _controller.confirm();
    if (!mounted) {
      return;
    }
    if (_controller.feedReady && _controller.errorMessage == null) {
      widget.onDone();
    }
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onBack});

  final String message;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Creator invite'),
        actions: [
          if (onBack != null)
            TextButton.icon(
              key: const ValueKey('p12_capture_back_button'),
              onPressed: onBack,
              icon: const Icon(Icons.home_rounded),
              label: const Text('Return to Feed'),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LoomErrorState(
          title: 'Creator invite unavailable',
          body: message,
        ),
      ),
    );
  }
}

StarterPackMemberView _mapMember(StarterPackMember member) {
  return StarterPackMemberView(
    channelId: member.channelId,
    displayName: member.displayName,
    handle: member.handle,
    reason:
        member.recommendationReason ?? 'The creator who invited you to Loom.',
    avatarRef: member.avatarRef,
    isSourceCreator: member.role == StarterPackMemberRole.source,
    alreadyFollowing: member.alreadyFollowing,
  );
}
