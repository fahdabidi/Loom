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
  /// Maps individual persona ids to their declared persona type (role).
  /// Set before any guard-evaluating calls so
  /// [allowedPersonaIds]-style checks compare the type, not the individual id.
  final Map<String, String> _personaTypeById = {};
  /// Registers the persona type for an individual account id.
  void setPersonaType(String personaId, String personaTypeId) {
    _personaTypeById[personaId] = personaTypeId;
  }

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
  Future<dynamic> aggregate({
    required String workflowType,
    required String column,
    required String op,
    Map<String, dynamic>? filter,
    String? groupBy,
  }) async {
    const supported = {'count', 'sum', 'avg', 'min', 'max', 'countDistinct'};
    if (!supported.contains(op)) {
      throw ArgumentError.value(op, 'op', 'Unsupported aggregate operation');
    }
    final rows = await _db.queryInstancesKeyset(
      communityId: _communityId,
      limit: 1 << 30,
      sortKey: 'instanceId',
    );
    final data = rows
        .where((row) => row.workflowType == workflowType)
        .map((row) => jsonDecode(row.instanceData) as Map<String, dynamic>)
        .where(
          (row) =>
              filter == null ||
              filter.entries.every((entry) => row[entry.key] == entry.value),
        )
        .toList();
    if (groupBy == null) {
      return aggregateValues(data.map((row) => row[column]), op);
    }
    final groups = <dynamic, List<dynamic>>{};
    for (final row in data) {
      groups.putIfAbsent(row[groupBy], () => <dynamic>[]).add(row[column]);
    }
    return groups.entries
        .map(
          (entry) => <String, dynamic>{
            groupBy: entry.key,
            op: aggregateValues(entry.value, op),
          },
        )
        .toList();
  }

  @override
  Future<List<WorkflowInstance>> dueNotifications({
    required DateTime asOf,
  }) async {
    final rows = await _db.queryInstancesKeyset(
      communityId: _communityId,
      limit: 1 << 30,
      sortKey: 'dueAt',
    );
    final due = <WorkflowInstance>[];
    for (final row in rows) {
      final data = jsonDecode(row.instanceData) as Map<String, dynamic>;
      final rawDueAt = data['dueAt'];
      if (rawDueAt is! String) continue;
      final dueAt = DateTime.tryParse(rawDueAt);
      if (dueAt == null || dueAt.isAfter(asOf)) continue;
      final machine = await _getDefinition(row.workflowType);
      due.add(
        WorkflowInstance(
          instanceId: row.instanceId,
          workflowType: row.workflowType,
          currentState: row.currentState,
          instanceData: _withComputedFields(data, machine),
          createdByPersonaId: row.createdByPersonaId,
        ),
      );
    }
    return due;
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
      personaTypeId: _personaTypeById[personaId],
    );
  }

  @override
  Future<List<LoomWorkflowTransition>> availableTransitionsAsync({
    required String workflowType,
    required String instanceId,
    required String currentState,
    required Map<String, dynamic> instanceData,
    required String personaId,
  }) async {
    final candidates = availableTransitions(
      workflowType: workflowType,
      instanceId: instanceId,
      currentState: currentState,
      instanceData: instanceData,
      personaId: personaId,
    );
    return [
      for (final transition in candidates)
        if (await _passesRelatedListGuard(
          transition.guard,
          instanceData,
          personaId,
        ))
          transition,
    ];
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
        personaTypeId: _personaTypeById[personaId],
        completedWorkflowIds: completedWorkflowIds,
      );

      final transition = transitions.firstWhere(
        (t) => t.id == transitionId,
        orElse: () => throw StateError(
          'Transition $transitionId not available from state ${row.currentState}',
        ),
      );
      if (!await _passesRelatedListGuard(transition.guard, data, personaId)) {
        throw StateError(
          'Transition $transitionId is not available for $personaId',
        );
      }

      final newData = await _applyExtendedEffects(
        transition.effects,
        machine: machine,
        sourceData: data,
        personaId: personaId,
      );
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

    _validateSeedData(machine, initialInstanceData);

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

  /// Atomically imports installation seed rows while preserving their IDs and
  /// declared states. Exact repeats are no-ops; conflicting existing rows fail.
  Future<void> seedInstances(Iterable<WorkflowInstance> instances) async {
    final batch = instances.toList(growable: false);
    final ids = <String>{};
    for (final instance in batch) {
      if (instance.instanceId.isEmpty || !ids.add(instance.instanceId)) {
        throw StateError('Seed instance IDs must be non-empty and unique');
      }
      final machine = await _getDefinition(instance.workflowType);
      if (machine == null)
        throw StateError('Unknown workflow type: ${instance.workflowType}');
      if (!machine.states.containsKey(instance.currentState)) {
        throw StateError(
          'Unknown state "${instance.currentState}" for ${instance.workflowType}',
        );
      }
      _validateSeedData(machine, instance.instanceData);
    }
    await _db.transaction(() async {
      for (final instance in batch) {
        final existing = await _db.readInstance(instance.instanceId);
        if (existing == null) continue;
        final existingData = jsonDecode(existing.instanceData);
        if (existing.communityId != _communityId ||
            existing.workflowType != instance.workflowType ||
            existing.currentState != instance.currentState ||
            existing.createdByPersonaId != instance.createdByPersonaId ||
            !_deepEquals(existingData, instance.instanceData)) {
          throw StateError(
            'Seed instance ${instance.instanceId} conflicts with existing row',
          );
        }
      }
      for (final instance in batch) {
        if (await _db.readInstance(instance.instanceId) != null) continue;
        await _db.insertInstance(
          instanceId: instance.instanceId,
          communityId: _communityId,
          workflowType: instance.workflowType,
          currentState: instance.currentState,
          instanceData: instance.instanceData,
          createdByPersonaId: instance.createdByPersonaId,
        );
      }
    });
  }

  void _validateSeedData(
    LoomWorkflowStateMachine machine,
    Map<String, dynamic> data,
  ) {
    for (final entry in machine.instanceDataSchema.entries) {
      if (entry.value.required &&
          (!data.containsKey(entry.key) || data[entry.key] == null)) {
        throw WorkflowValidationError(
          entry.key,
          'Required field is missing or null',
        );
      }
    }
    for (final key in data.keys) {
      if (machine.instanceDataSchema[key]?.formula != null) {
        throw WorkflowValidationError(key, 'Computed fields cannot be seeded');
      }
    }
  }

  bool _deepEquals(Object? left, Object? right) {
    if (left is Map && right is Map) {
      if (left.length != right.length) return false;
      return left.entries.every(
        (entry) =>
            right.containsKey(entry.key) &&
            _deepEquals(entry.value, right[entry.key]),
      );
    }
    if (left is List<Object?> && right is List<Object?>) {
      return left.length == right.length &&
          Iterable<int>.generate(
            left.length,
          ).every((i) => _deepEquals(left[i], right[i]));
    }
    return left == right;
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

  Future<bool> _passesRelatedListGuard(
    WorkflowGuard guard,
    Map<String, dynamic> sourceData,
    String personaId,
  ) async {
    final related = guard.relatedListMembership;
    if (related == null) return true;
    final id = sourceData[related.relatedInstanceField];
    if (id is! String || id.isEmpty) return false;
    final row = await _db.readInstance(id);
    if (row == null) return false;
    final data = jsonDecode(row.instanceData) as Map<String, dynamic>;
    final members = data[related.relatedListField];
    return members is Iterable && members.contains(personaId);
  }

  Future<Map<String, dynamic>> _applyExtendedEffects(
    List<WorkflowEffect> effects, {
    required LoomWorkflowStateMachine machine,
    required Map<String, dynamic> sourceData,
    required String personaId,
  }) async {
    var data = Map<String, dynamic>.from(sourceData);
    Future<void> applyList(List<WorkflowEffect> list) async {
      for (final effect in list) {
        final computed = _withComputedFields(
          data,
          machine,
          viewerId: personaId,
          actorId: personaId,
        );
        if (effect.op == 'branch') {
          if (effect.condition == null) {
            throw StateError('branch effect requires an "if" formula');
          }
          final condition = evaluateFormula(
            effect.condition!,
            instanceData: computed,
            viewerId: personaId,
            actorId: personaId,
          );
          if (condition is! bool) {
            throw StateError('branch "if" formula must evaluate to bool');
          }
          await applyList(condition ? effect.thenEffects : effect.elseEffects);
          continue;
        }
        if (effect.op == 'createInstance') {
          if (effect.workflowType == null || effect.fields == null) {
            throw StateError('createInstance requires workflowType and fields');
          }
          final fields = resolveEffectValue(effect.fields, personaId, computed);
          await createInstance(
            workflowType: effect.workflowType!,
            initialInstanceData: Map<String, dynamic>.from(fields as Map),
            personaId: personaId,
          );
          continue;
        }
        if (effect.op == 'set' && effect.relatedInstance != null) {
          final targetId = computed[effect.relatedInstance];
          if (targetId is! String || targetId.isEmpty) {
            throw StateError(
              'relatedInstance "${effect.relatedInstance}" is not an instance id',
            );
          }
          final target = await _db.readInstance(targetId);
          if (target == null)
            throw StateError('Related instance $targetId not found');
          final targetMachine = await _getDefinition(target.workflowType);
          if (targetMachine == null) {
            throw StateError('Unknown workflow type: ${target.workflowType}');
          }
          if (effect.key == null ||
              targetMachine.instanceDataSchema[effect.key]?.formula != null) {
            throw const WorkflowAuthorizationError(
              'Computed or missing target field cannot be written',
            );
          }
          final targetData =
              jsonDecode(target.instanceData) as Map<String, dynamic>;
          final value = resolveEffectValue(effect.value, personaId, computed);
          final updated = applyEffects(
            [WorkflowEffect(op: 'set', key: effect.key, value: value)],
            personaId,
            targetData,
          );
          await _db.updateInstanceState(
            instanceId: targetId,
            newState: target.currentState,
            newInstanceData: updated,
          );
          continue;
        }
        if (effect.key != null &&
            machine.instanceDataSchema[effect.key]?.formula != null) {
          throw WorkflowAuthorizationError(
            'Computed field "${effect.key}" cannot be written by an effect',
          );
        }
        data = applyEffects(
          [effect],
          personaId,
          data,
          interpolationData: computed,
        );
      }
    }

    await applyList(effects);
    return data;
  }

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

    final analyses = <String, FormulaAnalysis>{
      for (final entry in formulas.entries)
        entry.key: analyzeFormula(entry.value!),
    };
    for (final entry in analyses.entries) {
      for (final function in entry.value.functionNames) {
        if (!formulaFunctionNames.contains(function)) {
          throw FormulaEvaluationException('Unknown function "$function"');
        }
      }
      for (final field in entry.value.referencedFields) {
        if (!machine.instanceDataSchema.containsKey(field)) {
          throw FormulaEvaluationException(
            'Formula "${entry.key}" references undeclared field "$field"',
          );
        }
      }
    }
    _validateFormulaCycles(analyses, formulas.keys.toSet());

    final unavailable = <String>{};
    for (final entry in machine.instanceDataSchema.entries) {
      if (entry.value.source != null && !data.containsKey(entry.key)) {
        unavailable.add(entry.key);
      }
    }
    var changed = true;
    while (changed) {
      changed = false;
      for (final entry in formulas.entries) {
        if (unavailable.contains(entry.key)) continue;
        if (analyses[entry.key]!.referencedFields.any(unavailable.contains)) {
          unavailable.add(entry.key);
          changed = true;
        }
      }
    }
    final evaluable = Map<String, String?>.fromEntries(
      formulas.entries.where((entry) => !unavailable.contains(entry.key)),
    );
    if (evaluable.isEmpty) return Map<String, dynamic>.from(data);
    return evaluateComputedFields(
      instanceData: data,
      formulas: evaluable,
      viewerId: viewerId,
      actorId: actorId,
    );
  }

  void _validateFormulaCycles(
    Map<String, FormulaAnalysis> analyses,
    Set<String> computedFields,
  ) {
    final active = <String>{};
    final complete = <String>{};
    void visit(String key) {
      if (complete.contains(key)) return;
      if (!active.add(key)) {
        throw FormulaEvaluationException(
          'Circular formula dependency at "$key"',
        );
      }
      for (final dependency in analyses[key]!.referencedFields) {
        if (computedFields.contains(dependency)) visit(dependency);
      }
      active.remove(key);
      complete.add(key);
    }

    for (final key in analyses.keys) {
      visit(key);
    }
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
                    .map(
                      (e) => {
                        'op': e.op,
                        if (e.key != null) 'key': e.key,
                        if (e.value != null) 'value': e.value,
                        if (e.workflowType != null)
                          'workflowType': e.workflowType,
                        if (e.fields != null) 'fields': e.fields,
                        if (e.relatedInstance != null)
                          'relatedInstance': e.relatedInstance,
                        if (e.condition != null) 'if': e.condition,
                        if (e.thenEffects.isNotEmpty)
                          'then': e.thenEffects
                              .map((child) => _serializeEffect(child))
                              .toList(),
                        if (e.elseEffects.isNotEmpty)
                          'else': e.elseEffects
                              .map((child) => _serializeEffect(child))
                              .toList(),
                      },
                    )
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
            if (v.source != null) 'source': v.source,
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
    if (guard.formula != null) m['formula'] = guard.formula;
    if (guard.relatedListMembership != null) {
      m['relatedInstanceField'] =
          guard.relatedListMembership!.relatedInstanceField;
      m['relatedListField'] = guard.relatedListMembership!.relatedListField;
    }
    if (guard.requiresWorkflowsComplete != null &&
        guard.requiresWorkflowsComplete!.isNotEmpty) {
      m['requiresWorkflowsComplete'] = guard.requiresWorkflowsComplete;
    }
    return m.isEmpty ? null : m;
  }

  Map<String, dynamic> _serializeEffect(WorkflowEffect effect) => {
    'op': effect.op,
    if (effect.key != null) 'key': effect.key,
    if (effect.value != null) 'value': effect.value,
    if (effect.workflowType != null) 'workflowType': effect.workflowType,
    if (effect.fields != null) 'fields': effect.fields,
    if (effect.relatedInstance != null)
      'relatedInstance': effect.relatedInstance,
    if (effect.condition != null) 'if': effect.condition,
    if (effect.thenEffects.isNotEmpty)
      'then': effect.thenEffects.map(_serializeEffect).toList(),
    if (effect.elseEffects.isNotEmpty)
      'else': effect.elseEffects.map(_serializeEffect).toList(),
  };
}
