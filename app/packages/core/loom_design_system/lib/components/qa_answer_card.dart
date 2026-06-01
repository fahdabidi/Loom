import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import 'citation_link.dart';

class QaCitationView {
  const QaCitationView({
    required this.contentId,
    required this.title,
    required this.startLabel,
    required this.segment,
    required this.royaltyBasis,
  });

  final String contentId;
  final String title;
  final String startLabel;
  final String segment;
  final String royaltyBasis;
}

class QaAnswerCard extends StatelessWidget {
  const QaAnswerCard({
    required this.question,
    required this.answer,
    required this.confidenceLabel,
    required this.citations,
    required this.onCitationTap,
    super.key,
  });

  final String question;
  final String answer;
  final String confidenceLabel;
  final List<QaCitationView> citations;
  final ValueChanged<QaCitationView> onCitationTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LoomColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(answer, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 12),
            _InfoPill(label: confidenceLabel),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final citation in citations)
                  CitationLink(
                    key: ValueKey('p5_citation_${citation.contentId}'),
                    title: citation.title,
                    startLabel: citation.startLabel,
                    onTap: () => onCitationTap(citation),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: LoomColors.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: LoomColors.moss,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
