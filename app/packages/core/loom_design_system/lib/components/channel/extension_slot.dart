import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import 'channel_theme.dart';

class ExtensionSlot extends StatelessWidget {
  const ExtensionSlot({
    required this.name,
    required this.surface,
    required this.version,
    required this.theme,
    required this.summary,
    super.key,
  });

  final String name;
  final String surface;
  final String version;
  final LoomChannelTheme theme;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.accent.withAlpha(72)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.extension_rounded, color: theme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: theme.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$surface · v$version',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: LoomColors.mutedInk),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    summary,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: theme.text,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
