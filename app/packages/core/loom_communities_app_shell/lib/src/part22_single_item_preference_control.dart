part of loom_communities_app_shell;

class SingleItemPreferenceOption {
  const SingleItemPreferenceOption({
    required this.value,
    required this.label,
    this.icon,
  });

  final String value;
  final String label;
  final IconData? icon;
}

class SingleItemPreferenceControl extends StatelessWidget {
  const SingleItemPreferenceControl({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
    this.direction = Axis.horizontal,
  });

  final List<SingleItemPreferenceOption> options;
  final String selectedValue;
  final ValueChanged<String> onChanged;
  final Axis direction;

  @override
  Widget build(BuildContext context) => SegmentedButton<String>(
    key: const ValueKey('single-item-preference-control'),
    segments: [
      for (final option in options)
        ButtonSegment<String>(
          value: option.value,
          label: Text(option.label),
          icon: option.icon == null ? null : Icon(option.icon),
        ),
    ],
    selected: {selectedValue},
    emptySelectionAllowed: false,
    multiSelectionEnabled: false,
    showSelectedIcon: false,
    direction: direction,
    onSelectionChanged: (selected) {
      if (selected.isNotEmpty) onChanged(selected.first);
    },
  );
}
