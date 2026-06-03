import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_design_system/loom_design_system.dart';

import 'creator_launch_controller.dart';

class CreatorLaunchScreen extends StatefulWidget {
  const CreatorLaunchScreen({
    required this.creatorId,
    required this.onBack,
    super.key,
  });

  final String creatorId;
  final VoidCallback onBack;

  @override
  State<CreatorLaunchScreen> createState() => _CreatorLaunchScreenState();
}

class _CreatorLaunchScreenState extends State<CreatorLaunchScreen> {
  late final CreatorLaunchController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CreatorLaunchController(
      creatorId: widget.creatorId,
      metadataApi: resolveCreatorMetadataApi(),
      announcementApi: resolveCreatorAnnouncementApi(),
      captureApi: resolveFanFollowCaptureApi(),
      externalAccountApi: resolveExternalAccountLinkApi(),
      crossPostingApi: resolveCrossPostingApi(),
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
        final home = _controller.channelHome;
        final linkInBio = _controller.linkInBio;
        final captureLink = _controller.captureLink;
        final rendered = _controller.renderedAnnouncement;
        return ListView(
          key: const ValueKey('p11_creator_launch_screen'),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Launch',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_controller.loading)
              const _LaunchLoading()
            else if (_controller.errorMessage != null)
              _LaunchError(
                message: _controller.errorMessage!,
                onRetry: _controller.load,
              )
            else if (home != null)
              StudioLaunchPanel(
                creatorName: home.displayName,
                creatorHandle: home.handle,
                templates: _controller.templates
                    .map(
                      (template) => LaunchTemplateView(
                        templateId: template.templateId,
                        name: template.name,
                        channel: template.channel,
                        body: template.body,
                      ),
                    )
                    .toList(growable: false),
                selectedTemplateId: _controller.selectedTemplateId,
                externalAccounts: _controller.externalAccounts
                    .map(
                      (account) => ExternalAccountView(
                        linkId: account.linkId,
                        platform: account.platform,
                        handle: account.handle,
                        verificationState: account.verificationState,
                      ),
                    )
                    .toList(growable: false),
                captureUrl: captureLink?.url,
                renderedBody: rendered?.renderedBody,
                crossPostTargets:
                    _controller.crossPost?.targets
                        .map(
                          (target) => CrossPostTargetView(
                            targetLinkId: target.targetLinkId,
                            platform: target.platform,
                            deliveryStatus: target.deliveryStatus,
                            message: target.message,
                          ),
                        )
                        .toList(growable: false) ??
                    const [],
                busy: _controller.busy,
                onSelectTemplate: _controller.selectTemplate,
                onGenerateAssets: _controller.generateAssets,
                onCrossPost: _controller.simulateCrossPost,
                onShowImportExplanation: _showImportExplanation,
              ),
            if (captureLink != null && linkInBio != null) ...[
              const SizedBox(height: LoomSpacing.md),
              CopyLinkRow(
                key: const ValueKey('p11_capture_link_row'),
                label: 'Capture link',
                url: captureLink.url,
                onCopy: () => _copy(captureLink.url),
              ),
              const SizedBox(height: LoomSpacing.md),
              QrCard(
                key: const ValueKey('p11_qr_card'),
                payload: captureLink.qrPayload,
                title: 'QR follow card',
                subtitle:
                    'Offline QR payload points fans to the same manual re-follow landing.',
              ),
              const SizedBox(height: LoomSpacing.md),
              _LinkInBioPreview(page: linkInBio),
            ],
            if (rendered != null) ...[
              const SizedBox(height: LoomSpacing.md),
              _RenderedAnnouncement(body: rendered.renderedBody),
            ],
          ],
        );
      },
    );
  }

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Capture link copied')));
  }

  void _showImportExplanation() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manual re-follows',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: LoomSpacing.sm),
            const Text(
              'Loom does not import followers from external platforms. Use these assets to invite your audience to follow you on Loom, then measure aggregate conversion from the capture link.',
            ),
          ],
        ),
      ),
    );
  }
}

class _LaunchLoading extends StatelessWidget {
  const _LaunchLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('p11_launch_loading'),
      padding: const EdgeInsets.all(LoomSpacing.lg),
      decoration: BoxDecoration(
        color: LoomColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LoomColors.line),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: LoomSpacing.md),
          Expanded(child: Text('Loading launch assets')),
        ],
      ),
    );
  }
}

class _LaunchError extends StatelessWidget {
  const _LaunchError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DataDashboardRow(
      key: const ValueKey('p11_launch_error'),
      icon: Icons.error_outline_rounded,
      title: 'Launch assets unavailable',
      subtitle: message,
      trailing: IconButton(
        onPressed: onRetry,
        tooltip: 'Retry',
        icon: const Icon(Icons.refresh_rounded),
      ),
    );
  }
}

class _LinkInBioPreview extends StatelessWidget {
  const _LinkInBioPreview({required this.page});

  final LinkInBioPage page;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('p11_link_in_bio_preview'),
      padding: const EdgeInsets.all(LoomSpacing.lg),
      decoration: BoxDecoration(
        color: LoomColors.ink,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(child: Text(page.displayName.characters.first)),
              const SizedBox(width: LoomSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      page.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: LoomColors.surface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '@${page.handle}',
                      style: const TextStyle(
                        color: LoomColors.surface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: LoomSpacing.md),
          for (final link in page.externalLinks)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: LoomSpacing.sm),
              padding: const EdgeInsets.all(LoomSpacing.md),
              decoration: BoxDecoration(
                color: LoomColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                link.label,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
        ],
      ),
    );
  }
}

class _RenderedAnnouncement extends StatelessWidget {
  const _RenderedAnnouncement({required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('p11_rendered_announcement'),
      width: double.infinity,
      padding: const EdgeInsets.all(LoomSpacing.lg),
      decoration: BoxDecoration(
        color: LoomColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LoomColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rendered announcement',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: LoomSpacing.sm),
          SelectableText(body),
        ],
      ),
    );
  }
}
