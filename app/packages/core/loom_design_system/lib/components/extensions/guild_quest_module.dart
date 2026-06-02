import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../channel/channel_theme.dart';
import 'badge_chip.dart';
import 'shared_progress_bar.dart';
import 'vote_button.dart';

class GuildQuestModule extends StatelessWidget {
  const GuildQuestModule({
    required this.goalLabel,
    required this.current,
    required this.target,
    required this.milestones,
    required this.theme,
    required this.onContribute,
    required this.statusLabel,
    super.key,
  });

  final String goalLabel;
  final int current;
  final int target;
  final List<String> milestones;
  final LoomChannelTheme theme;
  final VoidCallback onContribute;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SharedProgressBar(
          current: current,
          target: target,
          accentColor: theme.accent,
          label: goalLabel,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final milestone in milestones)
              ExtensionBadgeChip(
                label: milestone,
                accentColor: theme.primary,
                icon: Icons.flag_rounded,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                'Aggregate community progress only',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: LoomColors.mutedInk),
              ),
            ),
            ExtensionVoteButton(
              label: 'Contribute',
              icon: Icons.groups_2_rounded,
              onPressed: onContribute,
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
