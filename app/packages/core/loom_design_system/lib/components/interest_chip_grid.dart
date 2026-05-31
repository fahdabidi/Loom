import 'package:flutter/material.dart';

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
    return Wrap(
      spacing: LoomSpacing.sm,
      runSpacing: LoomSpacing.sm,
      children: [
        for (final item in items)
          FilterChip(
            key: ValueKey('interest_chip_${item.id}'),
            label: Text(item.label),
            selected: selectedIds.contains(item.id),
            tooltip: item.category,
            onSelected: (_) => onToggle(item.id),
          ),
      ],
    );
  }
}
