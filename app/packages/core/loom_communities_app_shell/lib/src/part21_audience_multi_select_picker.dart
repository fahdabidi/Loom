part of loom_communities_app_shell;

class AudienceMultiSelectCandidate {
  const AudienceMultiSelectCandidate({
    required this.personaId,
    required this.label,
  });

  final String personaId;
  final String label;
}

class AudienceMultiSelectPicker extends StatelessWidget {
  const AudienceMultiSelectPicker({
    super.key,
    required this.candidates,
    required this.selectedPersonaIds,
    required this.onChanged,
    this.label = 'Audience',
  });

  final List<AudienceMultiSelectCandidate> candidates;
  final Set<String> selectedPersonaIds;
  final ValueChanged<Set<String>> onChanged;
  final String label;

  void _setSelected(String personaId, bool selected) {
    final next = Set<String>.from(selectedPersonaIds);
    if (selected) {
      next.add(personaId);
    } else {
      next.remove(personaId);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final selected = candidates
        .where((candidate) => selectedPersonaIds.contains(candidate.personaId))
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
                  key: ValueKey('audience-picker-chip-${candidate.personaId}'),
                  label: Text(candidate.label),
                  deleteIcon: Icon(
                    Icons.close,
                    key: ValueKey(
                      'audience-picker-chip-delete-${candidate.personaId}',
                    ),
                  ),
                  onDeleted: () => _setSelected(candidate.personaId, false),
                ),
            ],
          ),
        const SizedBox(height: 10),
        for (final candidate in candidates)
          CheckboxListTile(
            key: ValueKey('audience-picker-member-${candidate.personaId}'),
            value: selectedPersonaIds.contains(candidate.personaId),
            onChanged: (selected) =>
                _setSelected(candidate.personaId, selected ?? false),
            title: Text(candidate.label),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
      ],
    );
  }
}
