import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

class MiniBarDatum {
  const MiniBarDatum({required this.label, required this.value});

  final String label;
  final int value;
}

class MiniBarChart extends StatelessWidget {
  const MiniBarChart({required this.items, super.key});

  final List<MiniBarDatum> items;

  @override
  Widget build(BuildContext context) {
    final maxValue = items.fold<int>(
      1,
      (max, item) => item.value > max ? item.value : max,
    );
    return Column(
      key: const ValueKey('p13_mini_bar_chart'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items) ...[
          Row(
            children: [
              SizedBox(
                width: 96,
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: LoomColors.mutedInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: LoomSpacing.sm),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: LoomColors.line,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: (item.value / maxValue).clamp(0.06, 1.0),
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: LoomColors.moss,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: LoomSpacing.sm),
              Text(
                '${item.value}',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          if (item != items.last) const SizedBox(height: LoomSpacing.sm),
        ],
      ],
    );
  }
}
