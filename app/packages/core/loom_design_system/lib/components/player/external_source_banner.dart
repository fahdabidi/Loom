import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

class ExternalSourceBanner extends StatelessWidget {
  const ExternalSourceBanner({
    required this.title,
    required this.originalTitle,
    required this.sourceLabel,
    required this.summary,
    this.accurateMatchLabel,
    super.key,
  });

  final String title;
  final String originalTitle;
  final String sourceLabel;
  final String summary;
  final String? accurateMatchLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('p24_external_source_banner'),
      padding: const EdgeInsets.all(LoomSpacing.md),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: LoomColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: LoomColors.line),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.public_rounded, size: 15),
                    const SizedBox(width: 5),
                    Text(
                      sourceLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              if (accurateMatchLabel != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    accurateMatchLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: LoomColors.moss,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: LoomSpacing.sm),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: LoomSpacing.xs),
          Text(
            originalTitle,
            key: const ValueKey('p24_external_original_title'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: LoomColors.mutedInk,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: LoomSpacing.sm),
          Text(
            summary,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.28),
          ),
        ],
      ),
    );
  }
}
