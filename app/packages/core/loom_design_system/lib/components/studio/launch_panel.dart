import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

class StudioLaunchPanel extends StatelessWidget {
  const StudioLaunchPanel({
    required this.creatorName,
    required this.creatorHandle,
    required this.templates,
    required this.selectedTemplateId,
    required this.externalAccounts,
    required this.captureUrl,
    required this.renderedBody,
    required this.crossPostTargets,
    required this.busy,
    required this.onSelectTemplate,
    required this.onGenerateAssets,
    required this.onCrossPost,
    required this.onShowImportExplanation,
    super.key,
  });

  final String creatorName;
  final String creatorHandle;
  final List<LaunchTemplateView> templates;
  final String? selectedTemplateId;
  final List<ExternalAccountView> externalAccounts;
  final String? captureUrl;
  final String? renderedBody;
  final List<CrossPostTargetView> crossPostTargets;
  final bool busy;
  final ValueChanged<String> onSelectTemplate;
  final VoidCallback onGenerateAssets;
  final VoidCallback? onCrossPost;
  final VoidCallback onShowImportExplanation;

  @override
  Widget build(BuildContext context) {
    final hasAssets = captureUrl != null && renderedBody != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: LoomColors.moss.withAlpha(42),
                    child: const Icon(Icons.rocket_launch_rounded),
                  ),
                  const SizedBox(width: LoomSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Launch and grow',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          '$creatorName · @$creatorHandle',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: LoomColors.mutedInk,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (busy)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: LoomSpacing.md),
              Text(
                'Create the assets that invite your existing audience to follow you on Loom. Follower graphs stay on the incumbent platforms; this flow drives manual re-follows.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: LoomColors.mutedInk,
                  height: 1.28,
                ),
              ),
              const SizedBox(height: LoomSpacing.md),
              Wrap(
                spacing: LoomSpacing.sm,
                runSpacing: LoomSpacing.sm,
                children: [
                  FilledButton.icon(
                    key: const ValueKey('p11_generate_launch_assets_button'),
                    onPressed: busy ? null : onGenerateAssets,
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Generate assets'),
                  ),
                  FilledButton.tonalIcon(
                    key: const ValueKey('p11_start_cross_post_button'),
                    onPressed: busy || !hasAssets ? null : onCrossPost,
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Simulate cross-post'),
                  ),
                  IconButton(
                    key: const ValueKey('p11_import_explanation_button'),
                    onPressed: onShowImportExplanation,
                    tooltip: 'Why followers are not imported',
                    icon: const Icon(Icons.info_outline_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: LoomSpacing.md),
        Text(
          'Announcement templates',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: LoomSpacing.sm),
        for (final template in templates) ...[
          LaunchTemplateCard(
            template: template,
            selected: selectedTemplateId == template.templateId,
            onTap: () => onSelectTemplate(template.templateId),
          ),
          const SizedBox(height: LoomSpacing.sm),
        ],
        if (externalAccounts.isNotEmpty) ...[
          const SizedBox(height: LoomSpacing.xs),
          Text(
            'Promotion channels',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: LoomSpacing.sm),
          for (final account in externalAccounts)
            CrossPostStatusRow(
              icon: Icons.verified_rounded,
              title: '${account.platform} ${account.handle}',
              subtitle: '${account.verificationState} public profile',
              status: 'Ready',
            ),
        ],
        if (crossPostTargets.isNotEmpty) ...[
          const SizedBox(height: LoomSpacing.md),
          Text(
            'Cross-post status',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: LoomSpacing.sm),
          for (final target in crossPostTargets)
            CrossPostStatusRow(
              key: ValueKey('p11_cross_post_${target.targetLinkId}'),
              icon: Icons.outbound_rounded,
              title: target.platform,
              subtitle: target.message ?? 'Simulated delivery only',
              status: target.deliveryStatus,
            ),
        ],
      ],
    );
  }
}

class LaunchTemplateView {
  const LaunchTemplateView({
    required this.templateId,
    required this.name,
    required this.channel,
    required this.body,
  });

  final String templateId;
  final String name;
  final String channel;
  final String body;
}

class ExternalAccountView {
  const ExternalAccountView({
    required this.linkId,
    required this.platform,
    required this.handle,
    required this.verificationState,
  });

  final String linkId;
  final String platform;
  final String handle;
  final String verificationState;
}

class CrossPostTargetView {
  const CrossPostTargetView({
    required this.targetLinkId,
    required this.platform,
    required this.deliveryStatus,
    this.message,
  });

  final String targetLinkId;
  final String platform;
  final String deliveryStatus;
  final String? message;
}

class LaunchTemplateCard extends StatelessWidget {
  const LaunchTemplateCard({
    required this.template,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final LaunchTemplateView template;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(LoomSpacing.md),
        decoration: BoxDecoration(
          color: selected ? LoomColors.ink : LoomColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? LoomColors.ink : LoomColors.line,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? LoomColors.surface : LoomColors.mutedInk,
            ),
            const SizedBox(width: LoomSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: selected ? LoomColors.surface : LoomColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: LoomSpacing.xs),
                  Text(
                    template.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: selected
                          ? LoomColors.surface.withAlpha(210)
                          : LoomColors.mutedInk,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: LoomSpacing.sm),
            Text(
              template.channel.replaceAll('_', ' '),
              style: TextStyle(
                color: selected ? LoomColors.surface : LoomColors.mutedInk,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CopyLinkRow extends StatelessWidget {
  const CopyLinkRow({
    required this.label,
    required this.url,
    required this.onCopy,
    super.key,
  });

  final String label;
  final String url;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(LoomSpacing.md),
      decoration: BoxDecoration(
        color: LoomColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.link_rounded),
          const SizedBox(width: LoomSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: LoomColors.mutedInk),
                ),
              ],
            ),
          ),
          IconButton(
            key: const ValueKey('p11_copy_capture_link_button'),
            onPressed: onCopy,
            tooltip: 'Copy link',
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
    );
  }
}

class CrossPostStatusRow extends StatelessWidget {
  const CrossPostStatusRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: LoomSpacing.sm),
      padding: const EdgeInsets.all(LoomSpacing.md),
      decoration: BoxDecoration(
        color: LoomColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LoomColors.line),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: LoomColors.aqua.withAlpha(36),
            child: Icon(icon, color: LoomColors.aqua),
          ),
          const SizedBox(width: LoomSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: LoomColors.mutedInk),
                ),
              ],
            ),
          ),
          const SizedBox(width: LoomSpacing.sm),
          Text(
            status.replaceAll('_', ' '),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
