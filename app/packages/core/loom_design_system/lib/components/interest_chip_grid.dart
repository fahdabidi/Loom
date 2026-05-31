import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';

class InterestChipItem {
  const InterestChipItem({
    required this.id,
    required this.label,
    required this.category,
  });

  final String id;
  final String label;
  final String category;
}

class InterestChipGrid extends StatelessWidget {
  const InterestChipGrid({
    required this.items,
    required this.selectedIds,
    required this.onToggle,
    super.key,
  });

  final List<InterestChipItem> items;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<InterestChipItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in grouped.entries) ...[
          Text(
            entry.key,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: LoomColors.mutedInk,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: LoomSpacing.xs),
          Wrap(
            spacing: LoomSpacing.sm,
            runSpacing: LoomSpacing.sm,
            children: [
              for (final item in entry.value)
                FilterChip(
                  key: ValueKey('interest_chip_${item.id}'),
                  avatar: Icon(
                    _iconFor(item.category),
                    size: 16,
                    color: selectedIds.contains(item.id)
                        ? LoomColors.surface
                        : LoomColors.mutedInk,
                  ),
                  label: Text(item.label),
                  selected: selectedIds.contains(item.id),
                  showCheckmark: false,
                  tooltip: item.category,
                  onSelected: (_) => onToggle(item.id),
                ),
            ],
          ),
          const SizedBox(height: LoomSpacing.lg),
        ],
      ],
    );
  }
}

IconData _iconFor(String category) {
  return switch (category) {
    'Sustainable living' => Icons.bolt_rounded,
    'Food craft' => Icons.restaurant_rounded,
    'Movement' => Icons.directions_run_rounded,
    'Life systems' => Icons.auto_awesome_rounded,
    _ => Icons.interests_rounded,
  };
}
