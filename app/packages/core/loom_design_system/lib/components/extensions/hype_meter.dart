import 'package:flutter/material.dart';

import '../../tokens/colors.dart';

class HypeMeter extends StatelessWidget {
  const HypeMeter({
    required this.totalCents,
    required this.goalCents,
    required this.accentColor,
    super.key,
  });

  final int totalCents;
  final int goalCents;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final progress = goalCents <= 0
        ? 0.0
        : (totalCents / goalCents).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: LoomColors.line,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              _money(totalCents),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: LoomColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Text(
              'Goal ${_money(goalCents)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: LoomColors.mutedInk),
            ),
          ],
        ),
      ],
    );
  }
}

String _money(int cents) {
  return '\$${(cents / 100).toStringAsFixed(2)}';
}
