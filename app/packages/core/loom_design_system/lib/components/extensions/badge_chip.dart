import 'package:flutter/material.dart';

import '../../tokens/colors.dart';

class ExtensionBadgeChip extends StatelessWidget {
  const ExtensionBadgeChip({
    required this.label,
    required this.accentColor,
    this.icon = Icons.workspace_premium_rounded,
    super.key,
  });

  final String label;
  final Color accentColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accentColor.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accentColor.withAlpha(92)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: accentColor, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: LoomColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
