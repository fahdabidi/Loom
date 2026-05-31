import 'package:flutter/material.dart';

class RoleSwitcher extends StatelessWidget {
  const RoleSwitcher({
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    super.key,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: [
        for (var i = 0; i < labels.length; i += 1)
          ButtonSegment<int>(value: i, label: Text(labels[i])),
      ],
      selected: {selectedIndex},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onChanged(selection.single),
    );
  }
}
