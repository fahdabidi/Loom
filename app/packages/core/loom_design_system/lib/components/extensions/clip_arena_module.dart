import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../channel/channel_theme.dart';
import 'leaderboard_row.dart';
import 'vote_button.dart';

class ClipArenaEntry {
  const ClipArenaEntry({
    required this.clipId,
    required this.title,
    required this.submitter,
    required this.votes,
  });

  final String clipId;
  final String title;
  final String submitter;
  final int votes;
}

class ClipArenaModule extends StatelessWidget {
  const ClipArenaModule({
    required this.seasonLabel,
    required this.prompt,
    required this.entries,
    required this.theme,
    required this.onSubmitClip,
    required this.onVoteLeader,
    required this.statusLabel,
    super.key,
  });

  final String seasonLabel;
  final String prompt;
  final List<ClipArenaEntry> entries;
  final LoomChannelTheme theme;
  final VoidCallback onSubmitClip;
  final VoidCallback onVoteLeader;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    final ranked = [...entries]..sort((a, b) => b.votes.compareTo(a.votes));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ModuleHeaderLine(
          icon: Icons.emoji_events_rounded,
          label: seasonLabel,
          accentColor: theme.accent,
        ),
        const SizedBox(height: 8),
        Text(
          prompt,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: LoomColors.ink, height: 1.25),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ExtensionVoteButton(
                label: 'Submit clip',
                icon: Icons.video_call_rounded,
                onPressed: onSubmitClip,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ExtensionVoteButton(
                label: 'Vote leader',
                icon: Icons.how_to_vote_rounded,
                onPressed: onVoteLeader,
                enabled: ranked.isNotEmpty,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final (index, entry) in ranked.take(3).indexed) ...[
          ExtensionLeaderboardRow(
            rank: index + 1,
            title: entry.title,
            subtitle: entry.submitter,
            scoreLabel: '${entry.votes} votes',
            accentColor: theme.primary,
            highlight: index == 0,
          ),
          if (index < ranked.take(3).length - 1) const SizedBox(height: 8),
        ],
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

class _ModuleHeaderLine extends StatelessWidget {
  const _ModuleHeaderLine({
    required this.icon,
    required this.label,
    required this.accentColor,
  });

  final IconData icon;
  final String label;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: accentColor, size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: LoomColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
