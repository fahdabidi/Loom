import 'package:flutter/material.dart';

import '../tokens/colors.dart';
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
    final clampedProgress = progress.clamp(0, 1).toDouble();
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                LoomSpacing.lg,
                LoomSpacing.sm,
                LoomSpacing.lg,
                180,
              ),
              children: [
                _ProgressHeader(
                  eyebrow: eyebrow,
                  title: title,
                  progress: clampedProgress,
                ),
                const SizedBox(height: LoomSpacing.lg),
                body,
              ],
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              color: LoomColors.surface,
              border: Border(top: BorderSide(color: LoomColors.line)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                LoomSpacing.lg,
                LoomSpacing.md,
                LoomSpacing.lg,
                LoomSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: double.infinity, child: primaryAction),
                  if (secondaryAction != null) ...[
                    const SizedBox(height: LoomSpacing.sm),
                    SizedBox(width: double.infinity, child: secondaryAction!),
                  ],
                  const SizedBox(height: LoomSpacing.xs),
                  Text(
                    'Progress ${(clampedProgress * 100).round()}%',
                    style: textTheme.labelSmall?.copyWith(
                      color: LoomColors.mutedInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.eyebrow,
    required this.title,
    required this.progress,
  });

  final String eyebrow;
  final String title;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LoomSpacing.md),
      decoration: BoxDecoration(
        color: LoomColors.charcoal,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: LoomSpacing.sm,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: LoomColors.surface.withAlpha(24),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  eyebrow,
                  style: const TextStyle(
                    color: LoomColors.surface,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.auto_awesome_rounded,
                color: LoomColors.sun,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: LoomSpacing.lg),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: LoomColors.surface,
              fontWeight: FontWeight.w900,
              height: 1.04,
            ),
          ),
          const SizedBox(height: LoomSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: progress,
              backgroundColor: LoomColors.surface.withAlpha(34),
              valueColor: const AlwaysStoppedAnimation<Color>(LoomColors.sun),
            ),
          ),
        ],
      ),
    );
  }
}
