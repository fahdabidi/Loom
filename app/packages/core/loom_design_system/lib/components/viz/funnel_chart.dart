import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

class FunnelStageView {
  const FunnelStageView({
    required this.label,
    required this.countLabel,
    required this.ratio,
    this.detail,
  });

  final String label;
  final String countLabel;
  final double ratio;
  final String? detail;
}

class FunnelChart extends StatelessWidget {
  const FunnelChart({required this.stages, super.key});

  final List<FunnelStageView> stages;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('p13_funnel_chart'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final stage in stages) ...[
          _StageRow(stage: stage),
          if (stage != stages.last) const SizedBox(height: LoomSpacing.sm),
        ],
      ],
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({required this.stage});

  final FunnelStageView stage;

  @override
  Widget build(BuildContext context) {
    final width = stage.ratio.clamp(0.08, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                stage.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            Text(
              stage.countLabel,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: LoomColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: LoomColors.line,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 16,
                  width: constraints.maxWidth * width,
                  decoration: BoxDecoration(
                    color: LoomColors.ink,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            );
          },
        ),
        if (stage.detail != null) ...[
          const SizedBox(height: 4),
          Text(
            stage.detail!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: LoomColors.mutedInk,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
