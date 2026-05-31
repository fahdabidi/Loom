import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

class StudioPublishComposer extends StatelessWidget {
  const StudioPublishComposer({
    required this.titleController,
    required this.summaryController,
    required this.onDraftSummary,
    required this.onPublishWithoutSummary,
    required this.onPublishVideo,
    required this.onPublishPost,
    required this.errorText,
    super.key,
  });

  final TextEditingController titleController;
  final TextEditingController summaryController;
  final VoidCallback onDraftSummary;
  final VoidCallback onPublishWithoutSummary;
  final VoidCallback onPublishVideo;
  final VoidCallback onPublishPost;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return _StudioPanel(
      title: 'Publish composer',
      subtitle: 'Media preview first, required summary second.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 170,
            width: double.infinity,
            padding: const EdgeInsets.all(LoomSpacing.md),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF14745E), Color(0xFF1C8EA8)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'Home battery walkthrough',
                style: TextStyle(
                  color: LoomColors.surface,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.04,
                ),
              ),
            ),
          ),
          const SizedBox(height: LoomSpacing.md),
          TextField(
            key: const ValueKey('p2_publish_title_field'),
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: LoomSpacing.sm),
          TextField(
            key: const ValueKey('p2_publish_summary_field'),
            controller: summaryController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Creator-approved summary',
              helperText: 'Required before search, AI, or publishing.',
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: LoomSpacing.sm),
            Text(
              errorText!,
              key: const ValueKey('p2_publish_error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: LoomSpacing.md),
          Wrap(
            spacing: LoomSpacing.sm,
            runSpacing: LoomSpacing.sm,
            children: [
              OutlinedButton.icon(
                key: const ValueKey('p2_ai_draft_summary_button'),
                onPressed: onDraftSummary,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('AI draft summary'),
              ),
              OutlinedButton(
                key: const ValueKey('p2_publish_without_summary_button'),
                onPressed: onPublishWithoutSummary,
                child: const Text('Test missing summary'),
              ),
              FilledButton.icon(
                key: const ValueKey('p2_publish_video_button'),
                onPressed: onPublishVideo,
                icon: const Icon(Icons.play_circle_rounded),
                label: const Text('Publish video'),
              ),
              FilledButton.tonalIcon(
                key: const ValueKey('p2_publish_post_button'),
                onPressed: onPublishPost,
                icon: const Icon(Icons.article_rounded),
                label: const Text('Publish post'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StudioStatusCard extends StatelessWidget {
  const StudioStatusCard({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 156,
      padding: const EdgeInsets.all(LoomSpacing.md),
      decoration: BoxDecoration(
        color: LoomColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LoomColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: LoomColors.aqua.withAlpha(36),
            child: Icon(icon, color: LoomColors.aqua),
          ),
          const SizedBox(height: LoomSpacing.md),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(label, style: const TextStyle(color: LoomColors.mutedInk)),
        ],
      ),
    );
  }
}

class _StudioPanel extends StatelessWidget {
  const _StudioPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LoomSpacing.md),
      decoration: BoxDecoration(
        color: LoomColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LoomColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: LoomSpacing.xs),
          Text(subtitle, style: const TextStyle(color: LoomColors.mutedInk)),
          const SizedBox(height: LoomSpacing.md),
          child,
        ],
      ),
    );
  }
}
