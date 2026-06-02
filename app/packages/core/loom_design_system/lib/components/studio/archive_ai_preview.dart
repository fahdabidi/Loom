import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

class ArchiveCitationView {
  const ArchiveCitationView({
    required this.title,
    required this.segment,
    required this.startLabel,
    required this.royaltyBasis,
  });

  final String title;
  final String segment;
  final String startLabel;
  final String royaltyBasis;
}

class StudioArchiveAiPreview extends StatelessWidget {
  const StudioArchiveAiPreview({
    required this.question,
    required this.answer,
    required this.confidenceLabel,
    required this.citations,
    required this.busy,
    required this.onAsk,
    super.key,
  });

  final String question;
  final String? answer;
  final String? confidenceLabel;
  final List<ArchiveCitationView> citations;
  final bool busy;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('p13_archive_ai_preview'),
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
              const Icon(Icons.psychology_alt_outlined),
              const SizedBox(width: LoomSpacing.sm),
              Expanded(
                child: Text(
                  'Creator archive preview',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: LoomSpacing.sm),
          Text(
            question,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: LoomColors.mutedInk,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: LoomSpacing.md),
          FilledButton.icon(
            key: const ValueKey('p13_ask_creator_archive_button'),
            onPressed: busy ? null : onAsk,
            icon: busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_rounded),
            label: Text(busy ? 'Asking archive' : 'Ask archive'),
          ),
          if (answer != null) ...[
            const SizedBox(height: LoomSpacing.md),
            Container(
              key: const ValueKey('p13_creator_ai_answer'),
              padding: const EdgeInsets.all(LoomSpacing.md),
              decoration: BoxDecoration(
                color: LoomColors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: LoomColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    confidenceLabel ?? 'Cited answer',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: LoomSpacing.sm),
                  Text(answer!, style: const TextStyle(height: 1.32)),
                ],
              ),
            ),
            const SizedBox(height: LoomSpacing.md),
            Text(
              'Sources',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: LoomSpacing.sm),
            for (final citation in citations) ...[
              _CitationRow(citation: citation),
              const SizedBox(height: LoomSpacing.sm),
            ],
          ],
        ],
      ),
    );
  }
}

class _CitationRow extends StatelessWidget {
  const _CitationRow({required this.citation});

  final ArchiveCitationView citation;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('p13_creator_ai_citation_${citation.startLabel}'),
      padding: const EdgeInsets.all(LoomSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LoomColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote_rounded, color: LoomColors.mutedInk),
          const SizedBox(width: LoomSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  citation.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${citation.startLabel} · ${citation.royaltyBasis}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: LoomColors.mutedInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  citation.segment,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
