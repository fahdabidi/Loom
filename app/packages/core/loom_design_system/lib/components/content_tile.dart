import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';

class ContentTile extends StatelessWidget {
  const ContentTile({
    required this.title,
    required this.summary,
    required this.creatorName,
    required this.contentTypeLabel,
    super.key,
  });

  final String title;
  final String summary;
  final String creatorName;
  final String contentTypeLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(LoomSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: LoomColors.sun.withAlpha(90),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: LoomColors.line),
            ),
            child: Text(
              contentTypeLabel,
              style: textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: LoomSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  creatorName,
                  style: textTheme.labelMedium?.copyWith(
                    color: LoomColors.mutedInk,
                  ),
                ),
                const SizedBox(height: LoomSpacing.xxs),
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: LoomSpacing.xs),
                Text(
                  summary,
                  style: textTheme.bodyMedium?.copyWith(
                    color: LoomColors.mutedInk,
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
