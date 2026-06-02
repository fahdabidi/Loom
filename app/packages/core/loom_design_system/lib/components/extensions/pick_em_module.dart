import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../channel/channel_theme.dart';
import 'leaderboard_row.dart';

class PickEmStanding {
  const PickEmStanding({
    required this.name,
    required this.pick,
    required this.points,
  });

  final String name;
  final String pick;
  final int points;
}

class PickEmModule extends StatelessWidget {
  const PickEmModule({
    required this.question,
    required this.options,
    required this.selectedPick,
    required this.standings,
    required this.theme,
    required this.onPick,
    required this.statusLabel,
    super.key,
  });

  final String question;
  final List<String> options;
  final String? selectedPick;
  final List<PickEmStanding> standings;
  final LoomChannelTheme theme;
  final ValueChanged<String> onPick;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    final ranked = [...standings]..sort((a, b) => b.points.compareTo(a.points));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: LoomColors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options.take(3))
              ChoiceChip(
                label: Text(option),
                selected: selectedPick == option,
                onSelected: (_) => onPick(option),
                selectedColor: theme.accent.withAlpha(56),
                checkmarkColor: theme.primary,
              ),
          ],
        ),
        const SizedBox(height: 12),
        for (final (index, standing) in ranked.take(3).indexed) ...[
          ExtensionLeaderboardRow(
            rank: index + 1,
            title: standing.name,
            subtitle: 'Picked ${standing.pick}',
            scoreLabel: '${standing.points} pts',
            accentColor: theme.primary,
            highlight: selectedPick == standing.pick,
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
