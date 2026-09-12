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

bool _isFanIdScalarType(String type) => type == 'fanId' || type == 'fanId?';

bool _isFanIdListType(String type) => type == 'fanId[]' || type == 'fanId[]?';

bool _isFanIdFieldType(String type) =>
    _isFanIdScalarType(type) || _isFanIdListType(type);

/// A member-directory-backed editor for `fanId` and `fanId[]` fields.
///
/// Existing ids that are absent from the active directory remain selected and
/// are called out explicitly. This prevents an edit from silently repairing,
/// dropping, or substituting contaminated and departed-member values.
class FanIdFormPicker extends StatelessWidget {
  const FanIdFormPicker({
    super.key,
    required this.label,
    required this.members,
    required this.selectedFanIds,
    required this.multiple,
    required this.nullable,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final Future<List<LoomCommunityMember>>? members;
  final Set<String> selectedFanIds;
  final bool multiple;
  final bool nullable;
  final bool enabled;
  final ValueChanged<Set<String>> onChanged;

  void _setSelected(String fanId, bool selected) {
    final next = Set<String>.from(selectedFanIds);
    if (multiple) {
      if (selected) {
        next.add(fanId);
      } else {
        next.remove(fanId);
      }
    } else if (selected) {
      next
        ..clear()
        ..add(fanId);
    } else if (nullable) {
      next.clear();
    }
    onChanged(next);
  }

  Widget _preservedValues({required String reason}) {
    if (selectedFanIds.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final fanId in selectedFanIds)
          ListTile(
            key: ValueKey('fan-id-picker-preserved-$fanId'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.warning_amber_rounded),
            title: Text(fanId),
            subtitle: Text(reason),
          ),
      ],
    );
  }

  String _statusLabel(MembershipStatus status) => switch (status) {
    MembershipStatus.active => 'Active',
    MembershipStatus.pendingApproval => 'Pending approval',
    MembershipStatus.invited => 'Invited',
  };

  @override
  Widget build(BuildContext context) {
    final directoryFuture = members;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        key: key,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          if (directoryFuture == null) ...[
            _preservedValues(reason: 'Member directory unavailable'),
            const Text(
              'Could not load the community member directory.',
              key: ValueKey('fan-id-picker-failed'),
            ),
          ] else
            FutureBuilder<List<LoomCommunityMember>>(
              future: directoryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _preservedValues(
                        reason: 'Waiting for the member directory',
                      ),
                      const Row(
                        key: ValueKey('fan-id-picker-loading'),
                        children: [
                          SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Loading community members…'),
                        ],
                      ),
                    ],
                  );
                }
                if (snapshot.hasError) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _preservedValues(reason: 'Member directory failed'),
                      const Text(
                        'Could not load the community member directory.',
                        key: ValueKey('fan-id-picker-failed'),
                      ),
                    ],
                  );
                }

                final directory = snapshot.data!;
                if (directory.isEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _preservedValues(
                        reason: 'Unknown or departed community member',
                      ),
                      const Text(
                        'This community has no members to select.',
                        key: ValueKey('fan-id-picker-empty'),
                      ),
                    ],
                  );
                }

                final byFanId = {
                  for (final member in directory) member.fanId: member,
                };
                final unknown = selectedFanIds
                    .where(
                      (fanId) =>
                          byFanId[fanId]?.status != MembershipStatus.active,
                    )
                    .toList(growable: false);
                final hasActiveMembers = directory.any(
                  (member) => member.status == MembershipStatus.active,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final fanId in unknown)
                      Builder(
                        builder: (context) {
                          final member = byFanId[fanId];
                          final reason = member == null
                              ? 'Unknown or departed community member'
                              : 'Not selectable: ${_statusLabel(member.status)}';
                          return ListTile(
                            key: ValueKey('fan-id-picker-unknown-$fanId'),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.warning_amber_rounded),
                            title: Text(member?.displayLabel ?? fanId),
                            subtitle: Text('$fanId · $reason'),
                            trailing: enabled && (multiple || nullable)
                                ? IconButton(
                                    key: ValueKey(
                                      'fan-id-picker-remove-unknown-$fanId',
                                    ),
                                    tooltip: 'Remove preserved value',
                                    onPressed: () => _setSelected(fanId, false),
                                    icon: const Icon(Icons.close),
                                  )
                                : null,
                          );
                        },
                      ),
                    if (!hasActiveMembers)
                      const Text(
                        'There are no active community members to select.',
                        key: ValueKey('fan-id-picker-no-active-members'),
                      ),
                    // Only active memberships are selectable: pending or
                    // invited people cannot yet act as community members.
                    // Role ids are shown as metadata and never used to filter
                    // the directory because field schemas declare no role
                    // eligibility contract.
                    for (final member in directory)
                      CheckboxListTile(
                        key: ValueKey('fan-id-picker-member-${member.fanId}'),
                        value: selectedFanIds.contains(member.fanId),
                        onChanged:
                            enabled && member.status == MembershipStatus.active
                            ? (selected) =>
                                  _setSelected(member.fanId, selected ?? false)
                            : null,
                        title: Text(member.displayLabel),
                        subtitle: Text(
                          '${member.fanId} · ${_statusLabel(member.status)}'
                          '${member.roleIds.isEmpty ? '' : ' · ${member.roleIds.join(', ')}'}',
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
