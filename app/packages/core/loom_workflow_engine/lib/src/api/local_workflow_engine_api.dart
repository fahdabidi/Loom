import 'dart:async';
import 'dart:convert';
import 'dart:math';

import '../evaluator/effect_evaluator.dart';
import '../evaluator/formula_evaluator.dart';
import '../evaluator/transition_evaluator.dart' as trans_eval;
import '../models/workflow_models.dart';
import '../store/database.dart';
import 'workflow_engine_api.dart';

/// Validation error thrown when instance data fails schema checks.
class WorkflowValidationError implements Exception {
  final String fieldName;
  final String reason;

  const WorkflowValidationError(this.fieldName, this.reason);

  @override
  String toString() => 'Validation error on "$fieldName": $reason';
}

/// Authorization error for forbidden field edits.
class WorkflowAuthorizationError implements Exception {
  final String message;

  const WorkflowAuthorizationError(this.message);

  @override
  String toString() => 'Authorization error: $message';
}

/// SQLite-backed implementation of [WorkflowEngineApi].
///
/// Uses [WorkflowDatabase] (sqlite3, transitively available via drift) so
/// every read/write goes through a real transactional storage layer.
class LocalWorkflowEngineApi implements WorkflowEngineApi {
  final WorkflowDatabase _db;
  final String _communityId;

  /// Registry of loaded workflow definitions, keyed by definition ID
  /// (`"communityId_workflowType"`).
  final Map<String, LoomWorkflowStateMachine> _definitions = {};

  LocalWorkflowEngineApi({
    required WorkflowDatabase db,
    required String communityId,
  }) : _db = db,
       _communityId = communityId;

  // ── populate definitions (called before any API use) ──────────────────

  /// Registers a workflow definition from JSON.
  void registerDefinition(LoomWorkflowStateMachine machine) {
    final defId = '${_communityId}_${machine.workflowType}';
    _definitions[defId] = machine;
    unawaited(
      _db.upsertDefinition(
        definitionId: defId,
        workflowType: machine.workflowType,
        definitionJson: jsonEncode(_serializeMachine(machine)),
        version: 1,
      ),
    );
  }

  Future<LoomWorkflowStateMachine?> _getDefinition(String workflowType) async {
    final defId = '${_communityId}_$workflowType';
    // Try in-memory first.
    if (_definitions.containsKey(defId)) return _definitions[defId];

    // Fall back to DB.
    final jsonStr = await _db.loadDefinitionJson(defId);
    if (jsonStr == null) return null;
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    final machine = LoomWorkflowStateMachine.fromJson(map, workflowType);
    _definitions[defId] = machine;
    return machine;
  }

  // ── WorkflowEngineApi ─────────────────────────────────────────────────

  @override
  Future<InstancePage> queryInstances({
    required String tabId,
    required String personaId,
    SurfaceQuery query = const SurfaceQuery.empty(),
    int limit = 25,
    String? cursor,
  }) async {
    final sortKey = query.sort?.key ?? 'title';

    final rows = await _db.queryInstancesKeyset(
      communityId: _communityId,
      cursor: cursor,
      limit: limit,
      sortKey: sortKey,
    );

    final hasMore = rows.length > limit;
    final rawItems = rows
        .take(limit)
        .map((r) {
          final data = jsonDecode(r.instanceData) as Map<String, dynamic>;
          return WorkflowInstance(
            instanceId: r.instanceId,
            workflowType: r.workflowType,
            currentState: r.currentState,
            instanceData: data,
            createdByPersonaId: r.createdByPersonaId,
          );
        })
        .where((instance) {
          return _matchesAudienceQuery(instance.instanceData, personaId, query);
        })
        .toList();
    final items = await Future.wait(
      rawItems.map((instance) async {
        final machine = await _getDefinition(instance.workflowType);
        return WorkflowInstance(
          instanceId: instance.instanceId,
          workflowType: instance.workflowType,
          currentState: instance.currentState,
          instanceData: _withComputedFields(
            instance.instanceData,
            machine,
            viewerId: personaId,
          ),
          createdByPersonaId: instance.createdByPersonaId,
        );
      }),
    );

    String? nextCursor;
    if (hasMore && items.isNotEmpty) {
      final lastRow = rows[limit - 1];
      final lastData = jsonDecode(lastRow.instanceData) as Map<String, dynamic>;
      final cursorValue = '${lastData[sortKey] ?? ''}';
      // Encode sortKey into cursor so the DB layer can detect mismatches.
      nextCursor = '$sortKey\x1f$cursorValue\x1f${lastRow.instanceId}';
    }

    return InstancePage(items: items, nextCursor: nextCursor, hasMore: hasMore);
  }

  bool _matchesAudienceQuery(
    Map<String, dynamic> instanceData,
    String personaId,
    SurfaceQuery query,
  ) {
    final audienceMemberField = query.audienceMemberField;
    if (audienceMemberField == null || audienceMemberField.isEmpty) {
      return true;
    }
    final scope = instanceData[query.audienceScopeField] as String? ?? 'all';
    if (scope == 'all') return true;
    if (scope != 'selected' && scope != 'individual') return false;
    final invited = instanceData[audienceMemberField];
    if (invited is Iterable) return invited.contains(personaId);
    return false;
  }

  @override
  List<LoomWorkflowTransition> availableTransitions({
    required String workflowType,
    required String instanceId,
    required String currentState,
    required Map<String, dynamic> instanceData,
    required String personaId,
  }) {
    final defId = '${_communityId}_$workflowType';
    final machine = _definitions[defId];
    if (machine == null) return const [];

    return trans_eval.availableTransitions(
      machine,
      currentState,
      personaId,
      _withComputedFields(instanceData, machine, viewerId: personaId),
    );
  }

  Future<Set<String>> completedWorkflowIdsForPersona(String personaId) async {
    final rows = await _db.queryInstancesForPersona(
      communityId: _communityId,
      personaId: personaId,
    );
    final completed = <String>{};
    for (final row in rows) {
      final machine = await _getDefinition(row.workflowType);
      final state = machine?.states[row.currentState];
      if (row.currentState == 'paid' || (state?.isTerminal ?? false)) {
        completed.add(row.workflowType);
        final data = jsonDecode(row.instanceData) as Map<String, dynamic>;
        final workflowId = data['workflowId'];
        if (workflowId is String && workflowId.isNotEmpty) {
          completed.add(workflowId);
        }
        final completionId = data['completionWorkflowId'];
        if (completionId is String && completionId.isNotEmpty) {
          completed.add(completionId);
        }
      }
    }
    return completed;
  }

  @override
  Future<WorkflowTransitionResult> applyTransition({
    required String workflowType,
    required String instanceId,
    required String transitionId,
    required String personaId,
  }) async {
    final machine = await _getDefinition(workflowType);
    if (machine == null) {
      throw StateError('Unknown workflow type: $workflowType');
    }

    late final WorkflowTransitionResult result;
    await _db.transaction(() async {
      final row = await _db.readInstance(instanceId);
      if (row == null) throw StateError('Instance $instanceId not found');

      final data = jsonDecode(row.instanceData) as Map<String, dynamic>;
      final completedWorkflowIds = await completedWorkflowIdsForPersona(
        personaId,
      );
      final computedData = _withComputedFields(
        data,
        machine,
        viewerId: personaId,
        actorId: personaId,
      );
      final transitions = trans_eval.availableTransitions(
        machine,
        row.currentState,
        personaId,
        computedData,
        completedWorkflowIds: completedWorkflowIds,
      );

      final transition = transitions.firstWhere(
        (t) => t.id == transitionId,
        orElse: () => throw StateError(
          'Transition $transitionId not available from state ${row.currentState}',
        ),
      );

      for (final effect in transition.effects) {
        if (effect.key != null &&
            machine.instanceDataSchema[effect.key]?.formula != null) {
          throw WorkflowAuthorizationError(
            'Computed field "${effect.key}" cannot be written by an effect',
          );
        }
      }
      // Apply effects to stored (non-computed) data.
      final newData = applyEffects(transition.effects, personaId, data);
      final newState = transition.to ?? row.currentState;

      await _db.updateInstanceState(
        instanceId: instanceId,
        newState: newState,
        newInstanceData: _withComputedFields(
          newData,
          machine,
          viewerId: personaId,
          actorId: personaId,
        ),
      );

      result = WorkflowTransitionResult(
        newState: newState,
        newInstanceData: newData,
      );
    });

    return result;
  }

  @override
  Future<String> createInstance({
    required String workflowType,
    required Map<String, dynamic> initialInstanceData,
    required String personaId,
  }) async {
    final machine = await _getDefinition(workflowType);
    if (machine == null) {
      throw StateError('Unknown workflow type: $workflowType');
    }

    // Validate required fields against instanceDataSchema.
    for (final entry in machine.instanceDataSchema.entries) {
      final field = entry.value;
      final key = entry.key;
      if (field.required) {
        if (!initialInstanceData.containsKey(key) ||
            initialInstanceData[key] == null) {
          throw WorkflowValidationError(
            key,
            'Required field is missing or null',
          );
        }
      }
    }
    for (final key in initialInstanceData.keys) {
      if (machine.instanceDataSchema[key]?.formula != null) {
        throw WorkflowValidationError(key, 'Computed fields cannot be seeded');
      }
    }

    final instanceId = '${_communityId}_${workflowType}_${_generateId()}';
    await _db.insertInstance(
      instanceId: instanceId,
      communityId: _communityId,
      workflowType: workflowType,
      currentState: machine.initialState,
      instanceData: initialInstanceData,
      createdByPersonaId: personaId,
    );

    return instanceId;
  }

  @override
  Future<void> updateInstanceFields({
    required String workflowType,
    required String instanceId,
    required Map<String, dynamic> fieldUpdates,
    required String personaId,
  }) async {
    final machine = await _getDefinition(workflowType);
    if (machine == null) {
      throw StateError('Unknown workflow type: $workflowType');
    }

    await _db.transaction(() async {
      final row = await _db.readInstance(instanceId);
      if (row == null) throw StateError('Instance $instanceId not found');

      final stateDef = machine.states[row.currentState];
      if (stateDef == null) {
        throw StateError('Unknown state ${row.currentState} for $workflowType');
      }

      final editable = stateDef.editableFields ?? const [];
      for (final key in fieldUpdates.keys) {
        if (!editable.contains(key)) {
          throw WorkflowAuthorizationError(
            'Field "$key" is not editable in state "${row.currentState}"',
          );
        }
        final schema = machine.instanceDataSchema[key];
        if (schema?.formula != null) {
          throw WorkflowAuthorizationError(
            'Computed field "$key" cannot be user-edited',
          );
        }
        if (schema != null && schema.writableBy == 'effect') {
          throw WorkflowAuthorizationError(
            'Field "$key" is effect-only and cannot be user-edited',
          );
        }
      }

      final data = jsonDecode(row.instanceData) as Map<String, dynamic>;
      data.addAll(fieldUpdates);
      await _db.updateInstanceState(
        instanceId: instanceId,
        newState: row.currentState,
        newInstanceData: data,
      );
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  Map<String, dynamic> _withComputedFields(
    Map<String, dynamic> data,
    LoomWorkflowStateMachine? machine, {
    String? viewerId,
    String? actorId,
  }) {
    if (machine == null) return Map<String, dynamic>.from(data);
    final formulas = <String, String?>{
      for (final entry in machine.instanceDataSchema.entries)
        if (entry.value.formula != null) entry.key: entry.value.formula,
    };
    if (formulas.isEmpty) return Map<String, dynamic>.from(data);
    return evaluateComputedFields(
      instanceData: data,
      formulas: formulas,
      viewerId: viewerId,
      actorId: actorId,
    );
  }

  static final _random = Random();

  String _generateId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(
      12,
      (_) => chars[_random.nextInt(chars.length)],
    ).join();
  }

  Map<String, dynamic> _serializeMachine(LoomWorkflowStateMachine machine) {
    // Re-serialize to JSON via jsonDecode/jsonEncode round-trip.
    final map = <String, dynamic>{
      'initialState': machine.initialState,
      'states': machine.states.map(
        (k, v) => MapEntry(k, {
          'label': v.label,
          if (v.tone != null) 'tone': v.tone,
          if (v.editableFields != null) 'editableFields': v.editableFields,
        }),
      ),
      'transitions': machine.transitions
          .map(
            (t) => {
              'id': t.id,
              'label': t.label,
              if (t.icon != null) 'icon': t.icon,
              if (t.tone != null) 'tone': t.tone,
              'from': t.from,
              if (t.to != null) 'to': t.to,
              if (!t.guard.isEmpty) 'guard': _serializeGuard(t.guard),
              if (t.effects.isNotEmpty)
                'effects': t.effects
                    .map((e) => {'op': e.op, 'key': e.key, 'value': e.value})
                    .toList(),
              if (t.linkedWorkflowId != null)
                'linkedWorkflowId': t.linkedWorkflowId,
            },
          )
          .toList(),
      if (machine.renderBindings.isNotEmpty)
        'renderBindings': machine.renderBindings
            .map(
              (b) => {
                'states': b.states,
                'role': b.role,
                'tabId': b.tabId,
                'cardSurfaceFamily': b.cardSurfaceFamily,
                'bindingKind': b.bindingKind,
                if (b.audienceMemberField != null)
                  'audienceMemberField': b.audienceMemberField,
              },
            )
            .toList(),
      if (machine.instanceDataSchema.isNotEmpty)
        'instanceDataSchema': machine.instanceDataSchema.map(
          (k, v) => MapEntry(k, {
            'type': v.type,
            if (v.required) 'required': v.required,
            if (v.writableBy != null) 'writableBy': v.writableBy,
            if (v.storage != null) 'storage': v.storage,
            if (v.storageTarget != null) 'storageTarget': v.storageTarget,
            if (v.searchable) 'searchable': v.searchable,
            if (v.sortable) 'sortable': v.sortable,
            if (v.displayIcon != null) 'displayIcon': v.displayIcon,
            if (v.labelTemplate != null) 'labelTemplate': v.labelTemplate,
            if (v.displayContexts != null) 'displayContexts': v.displayContexts,
            if (v.hideWhenEmpty) 'hideWhenEmpty': v.hideWhenEmpty,
            if (v.maxLength != null) 'maxLength': v.maxLength,
            if (v.formula != null) 'formula': v.formula,
          }),
        ),
    };
    return map;
  }

  Map<String, dynamic>? _serializeGuard(WorkflowGuard guard) {
    if (guard.isEmpty) return null;
    final m = <String, dynamic>{};
    if (guard.allowedPersonaIds != null &&
        guard.allowedPersonaIds!.isNotEmpty) {
      m['allowedPersonaIds'] = guard.allowedPersonaIds;
    }
    if (guard.actorInList != null) {
      m['actorInList'] = {
        'key': guard.actorInList!.key,
        'present': guard.actorInList!.present,
      };
    }
    if (guard.instanceDataEquals != null) {
      m['instanceDataEquals'] = {
        'key': guard.instanceDataEquals!.key,
        'value': guard.instanceDataEquals!.value,
      };
    }
    if (guard.requiresWorkflowsComplete != null &&
        guard.requiresWorkflowsComplete!.isNotEmpty) {
      m['requiresWorkflowsComplete'] = guard.requiresWorkflowsComplete;
    }
    return m.isEmpty ? null : m;
  }
}
