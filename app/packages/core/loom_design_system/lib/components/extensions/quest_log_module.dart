import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../channel/channel_theme.dart';
import 'badge_chip.dart';
import 'vote_button.dart';

class QuestLogModule extends StatelessWidget {
  const QuestLogModule({
    required this.questTitle,
    required this.questDescription,
    required this.badges,
    required this.completions,
    required this.theme,
    required this.onCompleteQuest,
    required this.statusLabel,
    super.key,
  });

  final String questTitle;
  final String questDescription;
  final List<String> badges;
  final int completions;
  final LoomChannelTheme theme;
  final VoidCallback onCompleteQuest;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          questTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: LoomColors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          questDescription,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: LoomColors.ink, height: 1.25),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final badge in badges)
              ExtensionBadgeChip(label: badge, accentColor: theme.accent),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                '$completions community completions',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: LoomColors.mutedInk),
              ),
            ),
            ExtensionVoteButton(
              label: 'Complete quest',
              icon: Icons.check_circle_rounded,
              onPressed: onCompleteQuest,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          statusLabel,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: LoomColors.mutedInk),
        ),
      ],
    );
  }
}
