part of loom_communities_app_shell;

class AudienceMultiSelectCandidate {
  const AudienceMultiSelectCandidate({
    required this.roleId,
    required this.label,
  });

  final String roleId;
  final String label;
}

class AudienceMultiSelectPicker extends StatelessWidget {
  const AudienceMultiSelectPicker({
    super.key,
    required this.candidates,
    required this.selectedRoleIds,
    required this.onChanged,
    this.label = 'Audience',
  });

  final List<AudienceMultiSelectCandidate> candidates;
  final Set<String> selectedRoleIds;
  final ValueChanged<Set<String>> onChanged;
  final String label;

  void _setSelected(String roleId, bool selected) {
    final next = Set<String>.from(selectedRoleIds);
    if (selected) {
      next.add(roleId);
    } else {
      next.remove(roleId);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final selected = candidates
        .where((candidate) => selectedRoleIds.contains(candidate.roleId))
        .toList(growable: false);
    return Column(
      key: const ValueKey('audience-multi-select-picker'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (selected.isEmpty)
          const Text(
            'No members selected',
            key: ValueKey('audience-picker-empty'),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final candidate in selected)
                InputChip(
                  key: ValueKey('audience-picker-chip-${candidate.roleId}'),
                  label: Text(candidate.label),
                  deleteIcon: Icon(
                    Icons.close,
                    key: ValueKey(
                      'audience-picker-chip-delete-${candidate.roleId}',
                    ),
                  ),
                  onDeleted: () => _setSelected(candidate.roleId, false),
                ),
            ],
          ),
        const SizedBox(height: 10),
        for (final candidate in candidates)
          CheckboxListTile(
            key: ValueKey('audience-picker-member-${candidate.roleId}'),
            value: selectedRoleIds.contains(candidate.roleId),
            onChanged: (selected) =>
                _setSelected(candidate.roleId, selected ?? false),
            title: Text(candidate.label),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
      ],
    );
  }
}
