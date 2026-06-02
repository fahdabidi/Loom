import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';
import '../viz/funnel_chart.dart';
import '../viz/mini_bar_chart.dart';

class ConversionFunnelCard extends StatelessWidget {
  const ConversionFunnelCard({
    required this.stages,
    required this.sourceBreakdown,
    required this.aggregateOnly,
    required this.dateRangeLabel,
    required this.onRefresh,
    super.key,
  });

  final List<FunnelStageView> stages;
  final List<MiniBarDatum> sourceBreakdown;
  final bool aggregateOnly;
  final String dateRangeLabel;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('p13_conversion_funnel_card'),
      padding: const EdgeInsets.all(LoomSpacing.lg),
      decoration: BoxDecoration(
        color: LoomColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LoomColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFEAF8F5),
                child: Icon(Icons.stacked_bar_chart_rounded),
              ),
              const SizedBox(width: LoomSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Launch conversion yield',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      dateRangeLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: LoomColors.mutedInk,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const ValueKey('p13_refresh_funnel_button'),
                tooltip: 'Refresh funnel',
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: LoomSpacing.md),
          _AggregateNotice(aggregateOnly: aggregateOnly),
          const SizedBox(height: LoomSpacing.md),
          FunnelChart(stages: stages),
          if (sourceBreakdown.isNotEmpty) ...[
            const SizedBox(height: LoomSpacing.lg),
            Text(
              'Source channels',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: LoomSpacing.sm),
            MiniBarChart(items: sourceBreakdown),
          ],
        ],
      ),
    );
  }
}

class _AggregateNotice extends StatelessWidget {
  const _AggregateNotice({required this.aggregateOnly});

  final bool aggregateOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('p13_aggregate_only_notice'),
      padding: const EdgeInsets.all(LoomSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCDEBE4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.privacy_tip_outlined, color: Color(0xFF167A55)),
          const SizedBox(width: LoomSpacing.sm),
          Expanded(
            child: Text(
              aggregateOnly
                  ? 'Aggregate-only metrics. No per-fan rows or universal IDs are exposed.'
                  : 'Review metric configuration before showing this funnel.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: LoomColors.mutedInk,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
