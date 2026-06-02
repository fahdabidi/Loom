import 'package:flutter/material.dart';

import '../../tokens/colors.dart';

class ShowcaseSubmission {
  const ShowcaseSubmission({
    required this.submissionId,
    required this.title,
    required this.submitter,
    required this.votes,
    required this.featured,
  });

  final String submissionId;
  final String title;
  final String submitter;
  final int votes;
  final bool featured;
}

class SubmissionGrid extends StatelessWidget {
  const SubmissionGrid({
    required this.submissions,
    required this.accentColor,
    super.key,
  });

  final List<ShowcaseSubmission> submissions;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final visible = submissions.take(4).toList(growable: false);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visible.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.08,
      ),
      itemBuilder: (context, index) {
        final item = visible[index];
        return DecoratedBox(
          decoration: BoxDecoration(
            color: item.featured ? accentColor.withAlpha(30) : LoomColors.paper,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: item.featured
                  ? accentColor.withAlpha(100)
                  : LoomColors.line,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  item.featured
                      ? Icons.auto_awesome_rounded
                      : Icons.image_outlined,
                  color: accentColor,
                ),
                const Spacer(),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: LoomColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.submitter} - ${item.votes} votes',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: LoomColors.mutedInk),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
