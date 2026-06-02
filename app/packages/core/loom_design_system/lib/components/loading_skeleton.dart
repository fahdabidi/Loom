import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({this.rows = 3, this.title = 'Loading', super.key});

  final int rows;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('p14_loading_skeleton'),
      padding: const EdgeInsets.all(LoomSpacing.lg),
      decoration: BoxDecoration(
        color: LoomColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LoomColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: LoomSpacing.md),
          for (var index = 0; index < rows; index++) ...[
            _SkeletonBar(widthFactor: index == 0 ? 0.86 : 0.58),
            if (index != rows - 1) const SizedBox(height: LoomSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 14,
        decoration: BoxDecoration(
          color: LoomColors.line,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
