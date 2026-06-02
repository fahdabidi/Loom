import 'package:flutter/material.dart';

import '../../tokens/colors.dart';

class SharedProgressBar extends StatelessWidget {
  const SharedProgressBar({
    required this.current,
    required this.target,
    required this.accentColor,
    required this.label,
    super.key,
  });

  final int current;
  final int target;
  final Color accentColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    final progress = target <= 0 ? 0.0 : (current / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: LoomColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '$current / $target',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: LoomColors.mutedInk),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: LoomColors.line,
            color: accentColor,
          ),
        ),
      ],
    );
  }
}
