import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../channel/channel_theme.dart';
import 'submission_grid.dart';
import 'vote_button.dart';

class BuildShowcaseModule extends StatelessWidget {
  const BuildShowcaseModule({
    required this.prompt,
    required this.submissions,
    required this.theme,
    required this.onSubmitBuild,
    required this.onVoteFeatured,
    required this.statusLabel,
    super.key,
  });

  final String prompt;
  final List<ShowcaseSubmission> submissions;
  final LoomChannelTheme theme;
  final VoidCallback onSubmitBuild;
  final VoidCallback onVoteFeatured;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          prompt,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: LoomColors.ink, height: 1.25),
        ),
        const SizedBox(height: 12),
        SubmissionGrid(submissions: submissions, accentColor: theme.accent),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ExtensionVoteButton(
                label: 'Submit build',
                icon: Icons.add_photo_alternate_rounded,
                onPressed: onSubmitBuild,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ExtensionVoteButton(
                label: 'Vote featured',
                icon: Icons.how_to_vote_rounded,
                onPressed: onVoteFeatured,
                enabled: submissions.isNotEmpty,
              ),
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
