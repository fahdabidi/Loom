import 'package:flutter/material.dart';

class PersonaSelector extends StatelessWidget {
  const PersonaSelector({
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
    super.key,
  });

  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: [
        for (var index = 0; index < options.length; index++)
          ButtonSegment<int>(value: index, label: Text(options[index])),
      ],
      selected: {selectedIndex},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
