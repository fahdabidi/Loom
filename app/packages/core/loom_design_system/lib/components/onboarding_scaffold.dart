import 'package:flutter/material.dart';

import '../tokens/spacing.dart';

class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.progress,
    required this.primaryAction,
    this.secondaryAction,
    super.key,
  });

  final String eyebrow;
  final String title;
  final Widget body;
  final double progress;
  final Widget primaryAction;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.all(LoomSpacing.lg),
        children: [
          LinearProgressIndicator(value: progress.clamp(0, 1)),
          const SizedBox(height: LoomSpacing.lg),
          Text(
            eyebrow.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: LoomSpacing.xs),
          Text(title, style: textTheme.headlineSmall),
          const SizedBox(height: LoomSpacing.lg),
          body,
          const SizedBox(height: LoomSpacing.xl),
          primaryAction,
          if (secondaryAction != null) ...[
            const SizedBox(height: LoomSpacing.sm),
            secondaryAction!,
          ],
        ],
      ),
    );
  }
}
