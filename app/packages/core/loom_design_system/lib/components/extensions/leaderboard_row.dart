import 'package:flutter/material.dart';

import '../../tokens/colors.dart';

class ExtensionLeaderboardRow extends StatelessWidget {
  const ExtensionLeaderboardRow({
    required this.rank,
    required this.title,
    required this.subtitle,
    required this.scoreLabel,
    required this.accentColor,
    this.highlight = false,
    super.key,
  });

  final int rank;
  final String title;
  final String subtitle;
  final String scoreLabel;
  final Color accentColor;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final background = highlight
        ? accentColor.withAlpha(24)
        : LoomColors.surface;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight ? accentColor.withAlpha(96) : LoomColors.line,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#$rank',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: LoomColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: LoomColors.mutedInk),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            scoreLabel,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: LoomColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
