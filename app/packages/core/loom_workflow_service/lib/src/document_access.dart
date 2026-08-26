import 'package:loom_workflow_engine/loom_workflow_engine.dart';

/// One member of a community's group, as App Access reports them.
class GroupMember {
  const GroupMember({
    required this.fanId,
    required this.roleIds,
    required this.state,
  });

  final String fanId;
  final Set<String> roleIds;
  final String state;

  bool get isActive => state == 'active';
}

/// Who may read and write a document, resolved against the live instance.
class DocumentAccess {
  const DocumentAccess({
    required this.documentId,
    required this.instanceState,
    required this.readFanIds,
    required this.writeFanIds,
    required this.derivation,
  });

  final String documentId;
  final String instanceState;
  final List<String> readFanIds;
  final List<String> writeFanIds;
  final Map<String, dynamic> derivation;

  Map<String, dynamic> toJson() => {
    'documentId': documentId,
    'instanceState': instanceState,
    'readFanIds': readFanIds,
    'writeFanIds': writeFanIds,
    'derivation': derivation,
  };
}

/// Resolves a document's reader and writer sets.
///
/// Every membership answer comes from the engine rather than from a second
/// implementation of the visibility rules here. Two implementations of a
/// 23-function expression language would have to agree on every input, and no
/// test can prove that they do -- the same reason the workflow service embeds
/// the engine instead of reimplementing it. This class decides only *whom* to
/// ask about and how to explain the answer.
class DocumentAccessResolver {
  const DocumentAccessResolver({
    required this.engine,
    required this.definition,
  });

  final LocalWorkflowEngineApi engine;

  /// The workflow's definition JSON, read from the store.
  ///
  /// Used only to report which rule applied. The rules themselves are never
  /// evaluated from it.
  final Map<String, dynamic> definition;

  /// The actions that make a fan a writer of this instance's documents.
  static const writeActions = {'upload', 'delete'};

  Future<DocumentAccess> resolve({
    required String documentId,
    required WorkflowInstance instance,
    required String ownerFanId,
    required List<GroupMember> members,
  }) async {
    final instanceId = instance.instanceId;
    final readFanIds = <String>[];
    final writeFanIds = <String>[];

    final activeMembers = members.where((member) => member.isActive).toList();

    // The owner may have left the group, and a document does not stop having an
    // owner when they do. Evaluated alongside the members so the engine's own
    // creator branch decides, rather than this class assuming.
    final candidates = <String>{
      ownerFanId,
      for (final member in activeMembers) member.fanId,
    };

    final rolesByFan = <String, Set<String>>{
      for (final member in activeMembers) member.fanId: member.roleIds,
    };

    for (final fanId in candidates) {
      engine.setRolesForFan(fanId, rolesByFan[fanId] ?? const <String>{});

      final visible = await engine.readVisibleInstance(
        instanceId: instanceId,
        fanId: fanId,
      );
      if (visible != null) readFanIds.add(fanId);

      // Writing is asked about even when reading was refused. A community may
      // let a role file documents it cannot read back, and merging the two
      // questions would quietly make every writer a reader.
      final transitions = await engine.availableTransitionsAsync(
        workflowType: instance.workflowType,
        instanceId: instanceId,
        currentState: instance.currentState,
        instanceData: instance.instanceData,
        fanId: fanId,
      );
      final writes = transitions.any(
        (transition) => writeActions.contains(transition.action),
      );
      if (writes) writeFanIds.add(fanId);
    }

    readFanIds.sort();
    writeFanIds.sort();

    return DocumentAccess(
      documentId: documentId,
      instanceState: instance.currentState,
      readFanIds: readFanIds,
      writeFanIds: writeFanIds,
      derivation: _derivation(
        ownerFanId: ownerFanId,
        readFanIds: readFanIds,
        instanceData: instance.instanceData,
        currentState: instance.currentState,
        activeMembers: activeMembers,
      ),
    );
  }

  Map<String, dynamic> _derivation({
    required String ownerFanId,
    required List<String> readFanIds,
    required Map<String, dynamic> instanceData,
    required String? currentState,
    required List<GroupMember> activeMembers,
  }) {
    final visibility = definition['visibility'];
    final visibilityMap = visibility is Map<String, dynamic>
        ? visibility
        : const <String, dynamic>{};
    final model = visibilityMap['default'] as String? ?? 'guarded';

    final sharedWithField =
        (visibilityMap['fields'] as Map<String, dynamic>?)?['sharedWith']
            as String?;
    final sharedFanIds = <String>[];
    if (sharedWithField != null) {
      final shared = instanceData[sharedWithField];
      if (shared is List) {
        for (final entry in shared) {
          if (entry is String && readFanIds.contains(entry)) {
            sharedFanIds.add(entry);
          }
        }
      }
    }

    final byDefault = <String, dynamic>{'model': model};
    switch (model) {
      case 'public':
        byDefault['everyone'] = true;
      case 'membersOnly':
        byDefault['byMembership'] = [
          for (final member in activeMembers)
            if (readFanIds.contains(member.fanId)) member.fanId,
        ]..sort();
      default:
        // `guarded`. Group by role so a community can see which role list is
        // doing the admitting; a fan with two admitting roles appears under
        // both, because both are true reasons.
        final byRole = <String, List<String>>{};
        for (final member in activeMembers) {
          if (!readFanIds.contains(member.fanId)) continue;
          for (final roleId in member.roleIds) {
            (byRole[roleId] ??= <String>[]).add(member.fanId);
          }
        }
        byDefault['byRole'] = [
          for (final entry in byRole.entries)
            {'roleId': entry.key, 'fanIds': entry.value..sort()},
        ];
        final states = definition['states'];
        final stateGuard = currentState == null || states is! Map
            ? null
            : (states[currentState] as Map<String, dynamic>?)?['readGuard'];
        byDefault['guardState'] = stateGuard != null ? 'state' : 'workflow';
    }

    return {
      'byOwner': [if (readFanIds.contains(ownerFanId)) ownerFanId],
      'byShare': {
        'fieldName': sharedWithField,
        'fanIds': sharedFanIds..sort(),
      },
      'byDefault': byDefault,
    };
  }
}
