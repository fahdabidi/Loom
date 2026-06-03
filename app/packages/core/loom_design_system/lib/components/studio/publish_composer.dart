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
      subtitle: 'Upload the video first, then approve the summary and post.',
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
          FilledButton.icon(
            key: const ValueKey('p2_publish_video_button'),
            onPressed: onPublishVideo,
            icon: const Icon(Icons.play_circle_rounded),
            label: const Text('Publish video'),
          ),
          const SizedBox(height: LoomSpacing.md),
          _SummaryField(controller: summaryController, errorText: errorText),
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

class _SummaryField extends StatelessWidget {
  const _SummaryField({required this.controller, required this.errorText});

  final TextEditingController controller;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    return Container(
      key: hasError ? const ValueKey('p2_publish_error') : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LoomColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError ? LoomColors.coral : LoomColors.line,
          width: hasError ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Creator-approved summary',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Required before search, AI, or member posts.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: LoomColors.mutedInk,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasError) ...[
                const SizedBox(width: LoomSpacing.sm),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEEEE),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFFFC7C7)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: LoomColors.coral,
                          size: 16,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            errorText!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: LoomColors.coral,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: LoomSpacing.sm),
          TextField(
            key: const ValueKey('p2_publish_summary_field'),
            controller: controller,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Add the creator-approved summary here.',
              border: InputBorder.none,
              isDense: true,
            ),
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
