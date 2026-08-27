import 'dart:async';
import 'dart:convert';
import 'dart:math';

import '../archetypes/archetype_resolver.dart';
import '../evaluator/effect_evaluator.dart';
import '../evaluator/formula_evaluator.dart';
import '../evaluator/guard_evaluator.dart';
import '../evaluator/recurrence_evaluator.dart';
import '../evaluator/source_query.dart';
import '../evaluator/transition_evaluator.dart' as trans_eval;
import '../models/workflow_models.dart';
import '../store/database.dart';
import '../workflow_capabilities.dart';
import 'notification_delivery_service.dart';
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

/// Distinguishes an unavailable transition caused by its guard from other
/// transition failures. `transitionRelated` intentionally treats only this
/// case as a no-op.
class _TransitionGuardFailure implements Exception {
  final String message;

  const _TransitionGuardFailure(this.message);
}

/// The read-only result of resolving a transition's availability.
///
/// Resolution includes all checks which may reject a public transition before
/// its transaction begins: the declared state, guards, and required inputs.
class _ResolvedTransition {
  final LoomWorkflowStateMachine machine;
  final WorkflowInstanceRow row;
  final Map<String, dynamic> data;
  final LoomWorkflowTransition transition;
  final Map<String, dynamic>? inputs;

  const _ResolvedTransition({
    required this.machine,
    required this.row,
    required this.data,
    required this.transition,
    required this.inputs,
  });
}

/// A hydrated query row together with the definition used to authorize it.
class _QueryCandidate {
  final WorkflowInstanceRow row;
  final WorkflowInstance instance;
  final LoomWorkflowStateMachine? machine;

  const _QueryCandidate({
    required this.row,
    required this.instance,
    required this.machine,
  });
}

/// SQLite-backed implementation of [WorkflowEngineApi].
///
/// Uses [WorkflowDatabase] (sqlite3, transitively available via drift) so
/// every read/write goes through a real transactional storage layer.
class LocalWorkflowEngineApi implements WorkflowEngineApi {
  /// Actor-set mutations promised by the archetype contract tables.
  ///
  /// These are engine semantics, not authored effects. Keeping the mapping
  /// next to transition application makes the dual-writer Phase A/Phase F
  /// straddle explicit: authored effects run first, then this pass restores
  /// set semantics for the field the workflow currently spells.
  static const Map<
    String,
    Map<String, (String, _ArchetypeBookkeepingOperation)>
  >
  _archetypeBookkeepingByAction = {
    'documentLibrary': {
      'open': ('openedFanIds', _ArchetypeBookkeepingOperation.addActor),
      'acknowledge': (
        'acknowledgedFanIds',
        _ArchetypeBookkeepingOperation.addActor,
      ),
      'save': ('savedFanIds', _ArchetypeBookkeepingOperation.addActor),
      'unsave': ('savedFanIds', _ArchetypeBookkeepingOperation.removeActor),
      'download': ('downloadedFanIds', _ArchetypeBookkeepingOperation.addActor),
      'request_access': (
        'accessRequestedFanIds',
        _ArchetypeBookkeepingOperation.addActor,
      ),
      'withdraw_access_request': (
        'accessRequestedFanIds',
        _ArchetypeBookkeepingOperation.removeActor,
      ),
    },
    'equipment-loan': {
      'join_queue': ('queuedFanIds', _ArchetypeBookkeepingOperation.addActor),
      'leave_queue': (
        'queuedFanIds',
        _ArchetypeBookkeepingOperation.removeActor,
      ),
    },
    'event-rsvp': {
      'set_reminder': (
        'reminderFanIds',
        _ArchetypeBookkeepingOperation.addActor,
      ),
    },
  };

  /// Actor-set membership required before an archetype action may run.
  ///
  /// Packages may omit guards which only make engine-owned bookkeeping
  /// idempotent, so these checks must gate both rendered availability and
  /// direct transition application.
  static const Map<String, Map<String, (String, bool)>>
  _archetypeMembershipEligibilityByAction = {
    'equipment-loan': {
      'join_queue': ('queuedFanIds', false),
      'leave_queue': ('queuedFanIds', true),
    },
  };

  final WorkflowDatabase _db;
  final String _communityId;
  final DateTime Function() _clock;
  final NotificationDeliveryService? _notificationDeliveryService;
  bool _failClosedOnMissingDefinition;
  ActiveMembershipLookup? _activeMembershipLookup;
  WorkflowSurfacePermissionLookup? _surfacePermissionLookup;

  /// Registry of loaded workflow definitions, keyed by definition ID
  /// (`"communityId_workflowType"`).
  final Map<String, LoomWorkflowStateMachine> _definitions = {};
  Map<String, ResolvedArchetype> _resolvedArchetypes = const {};

  /// Maps individual fan ids to their declared role ids.
  /// Set before any guard-evaluating calls so
  /// [allowedRoleIds]-style checks compare the type, not the individual id.
  final Map<String, Set<String>> _roleIdsByFanId = {};

  /// Registers one role for an individual fan account.
  ///
  /// This remains a convenience for existing callers. It replaces the fan's
  /// full role set with the supplied single role.
  void setRoleForFan(String fanId, String roleId) {
    setRolesForFan(fanId, {roleId});
  }

  /// Replaces every role registered for an individual fan account.
  ///
  /// A defensive copy prevents a caller from mutating the stored role set
  /// after registration. Empty sets are deliberately stored: they represent
  /// an explicit fail-closed resolution rather than an unresolved fallback.
  void setRolesForFan(String fanId, Set<String> roleIds) {
    _roleIdsByFanId[fanId] = Set.unmodifiable(Set<String>.of(roleIds));
  }

  LocalWorkflowEngineApi({
    required WorkflowDatabase db,
    required String communityId,
    DateTime Function()? clock,
    NotificationDeliveryService? notificationDeliveryService,
    ActiveMembershipLookup? activeMembershipLookup,
    WorkflowSurfacePermissionLookup? surfacePermissionLookup,
    bool failClosedOnMissingDefinition = false,
  }) : _db = db,
       _communityId = communityId,
       _clock = clock ?? DateTime.now,
       _notificationDeliveryService = notificationDeliveryService,
       _failClosedOnMissingDefinition = failClosedOnMissingDefinition,
       _activeMembershipLookup = activeMembershipLookup,
       _surfacePermissionLookup = surfacePermissionLookup;

  /// Updates the membership lookup after construction when the app-shell auth
  /// store becomes available. This preserves the injected P4a pattern while
  /// allowing the shared engine to be installed before a session exists.
  void setActiveMembershipLookup(ActiveMembershipLookup? lookup) {
    _activeMembershipLookup = lookup;
  }

  /// Installs the app-shell-owned surface permission policy used at the
  /// engine boundary. The workflow engine remains provider-neutral; the
  /// callback is expected to delegate to the app shell's permission helper.
  void setSurfacePermissionLookup(WorkflowSurfacePermissionLookup? lookup) {
    _surfacePermissionLookup = lookup;
  }

  /// Selects whether persisted instances without an installed definition are
  /// hidden. Server-authoritative callers enable this so wholesale definition
  /// replacement makes retired workflow instances unreachable.
  void setFailClosedOnMissingDefinition(bool failClosed) {
    _failClosedOnMissingDefinition = failClosed;
  }

  // ── populate definitions (called before any API use) ──────────────────

  /// Registers a workflow definition from JSON.
  void registerDefinition(LoomWorkflowStateMachine machine) {
    final defId = '${_communityId}_${machine.workflowType}';
    _definitions[defId] = machine;
    _resolveRegisteredArchetypes();
    unawaited(
      _db.upsertDefinition(
        definitionId: defId,
        workflowType: machine.workflowType,
        definitionJson: jsonEncode(_serializeMachine(machine)),
        version: 1,
      ),
    );
  }

  /// Replaces this community's definitions as one durable database operation.
  ///
  /// Raw maps are persisted so installation does not silently discard a field
  /// merely because the in-memory model does not need it while rendering.
  Future<Set<String>> replaceDefinitions({
    required Map<String, Map<String, dynamic>> definitions,
    required int version,
  }) async {
    final parsed = <String, LoomWorkflowStateMachine>{
      for (final entry in definitions.entries)
        entry.key: LoomWorkflowStateMachine.fromJson(entry.value, entry.key),
    };
    final removed = await _db.replaceDefinitionsForCommunity(
      communityId: _communityId,
      definitions: definitions,
      version: version,
    );
    _definitions
      ..clear()
      ..addEntries(
        parsed.entries.map(
          (entry) => MapEntry('${_communityId}_${entry.key}', entry.value),
        ),
      );
    _resolveRegisteredArchetypes();
    return removed;
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
    _resolveRegisteredArchetypes();
    return machine;
  }

  void _resolveRegisteredArchetypes() {
    _resolvedArchetypes = const ArchetypeResolver().resolveAll({
      for (final machine in _definitions.values)
        machine.workflowType: _serializeMachine(machine),
    });
  }

  // ── WorkflowEngineApi ─────────────────────────────────────────────────

  @override
  Future<InstancePage> queryInstances({
    required String tabId,
    required String fanId,
    String? workflowType,
    SurfaceQuery query = const SurfaceQuery.empty(),
    int limit = 25,
    String? cursor,
  }) async {
    await _requireSurfacePermission(fanId: fanId, tabId: tabId);
    final sortKey = query.sort?.key ?? 'title';

    final rows = await _db.queryInstancesKeyset(
      communityId: _communityId,
      workflowType: workflowType,
      cursor: cursor,
      limit: limit,
      sortKey: sortKey,
    );

    // Keep the legacy path byte-for-byte equivalent for communities whose
    // definitions are all public or omit visibility. When a restricted
    // definition is present in the over-fetched batch, switch to the
    // filtered path so hidden rows cannot drive the returned cursor.
    final hasActiveVisibility = await _containsActiveReadVisibility(
      rows.take(limit + 1),
    );
    if (!hasActiveVisibility) {
      return _legacyQueryPage(
        rows: rows,
        sortKey: sortKey,
        fanId: fanId,
        query: query,
        limit: limit,
      );
    }

    return _filteredQueryPage(
      initialRows: rows,
      sortKey: sortKey,
      fanId: fanId,
      workflowType: workflowType,
      query: query,
      limit: limit,
    );
  }

  /// Reads one instance through the same hydration and visibility path used by
  /// [queryInstances]. Returns null for missing, cross-community, retired, or
  /// unreadable instances so an authoritative adapter need not disclose which
  /// case occurred.
  Future<WorkflowInstance?> readVisibleInstance({
    required String instanceId,
    required String fanId,
  }) async {
    final row = await _db.readInstance(instanceId);
    if (row == null || row.communityId != _communityId) return null;
    final candidate = await _hydrateQueryRow(row, fanId);
    if (!await _isVisibleToFan(
      candidate.instance,
      candidate.machine,
      fanId,
      () => _isActiveMember(fanId),
    )) {
      return null;
    }
    return candidate.instance;
  }

  Future<InstancePage> _legacyQueryPage({
    required List<WorkflowInstanceRow> rows,
    required String sortKey,
    required String fanId,
    required SurfaceQuery query,
    required int limit,
  }) async {
    final rawRows = rows
        .take(limit)
        .where(
          (row) => _matchesAudienceQuery(
            _rawInstance(row).instanceData,
            fanId,
            query,
          ),
        )
        .toList();
    final candidates = await Future.wait(
      rawRows.map((row) => _hydrateQueryRow(row, fanId)),
    );
    final items = candidates.map((candidate) => candidate.instance).toList();

    final hasMore = rows.length > limit;
    String? nextCursor;
    if (hasMore && items.isNotEmpty) {
      final lastRow = rows[limit - 1];
      nextCursor = _cursorForRow(sortKey, lastRow);
    }

    return InstancePage(items: items, nextCursor: nextCursor, hasMore: hasMore);
  }

  Future<InstancePage> _filteredQueryPage({
    required List<WorkflowInstanceRow> initialRows,
    required String sortKey,
    required String fanId,
    String? workflowType,
    required SurfaceQuery query,
    required int limit,
  }) async {
    final visibleCandidates = <_QueryCandidate>[];
    var rows = initialRows;
    WorkflowInstanceRow? lastScannedRow;
    Future<bool>? activeMembership;
    Future<bool> lookupActiveMembership() =>
        activeMembership ??= _isActiveMember(fanId);

    while (rows.isNotEmpty) {
      var reachedPageBoundary = false;
      for (final row in rows) {
        lastScannedRow = row;
        final rawInstance = _rawInstance(row);
        if (!_matchesAudienceQuery(rawInstance.instanceData, fanId, query)) {
          continue;
        }
        final candidate = await _hydrateQueryRow(row, fanId);
        if (await _isVisibleToFan(
          candidate.instance,
          candidate.machine,
          fanId,
          lookupActiveMembership,
        )) {
          visibleCandidates.add(candidate);
          if (visibleCandidates.length > limit) {
            reachedPageBoundary = true;
            break;
          }
        }
      }

      if (reachedPageBoundary) break;
      if (rows.length < limit + 1 || lastScannedRow == null) break;

      rows = await _db.queryInstancesKeyset(
        communityId: _communityId,
        workflowType: workflowType,
        cursor: _cursorForRow(sortKey, lastScannedRow),
        limit: limit,
        sortKey: sortKey,
      );
    }

    final hasMore = visibleCandidates.length > limit;
    final items = visibleCandidates
        .take(limit)
        .map((candidate) => candidate.instance)
        .toList();
    String? nextCursor;
    if (hasMore && items.isNotEmpty) {
      nextCursor = _cursorForRow(sortKey, visibleCandidates[limit - 1].row);
    }

    return InstancePage(items: items, nextCursor: nextCursor, hasMore: hasMore);
  }

  WorkflowInstance _rawInstance(WorkflowInstanceRow row) => WorkflowInstance(
    instanceId: row.instanceId,
    workflowType: row.workflowType,
    currentState: row.currentState,
    instanceData: jsonDecode(row.instanceData) as Map<String, dynamic>,
    createdByFanId: row.createdByFanId,
  );

  /// Hydrates source fields and computes formulas before any read guard runs.
  Future<_QueryCandidate> _hydrateQueryRow(
    WorkflowInstanceRow row,
    String fanId,
  ) async {
    final raw = _rawInstance(row);
    final machine = await _getDefinition(raw.workflowType);
    final hydrated = machine != null
        ? await _hydrateSourceFields(raw.instanceData, machine, raw.instanceId)
        : raw.instanceData;
    final instance = WorkflowInstance(
      instanceId: raw.instanceId,
      workflowType: raw.workflowType,
      currentState: raw.currentState,
      instanceData: _withComputedFields(hydrated, machine, viewerId: fanId),
      createdByFanId: raw.createdByFanId,
    );
    return _QueryCandidate(row: row, instance: instance, machine: machine);
  }

  Future<bool> _containsActiveReadVisibility(
    Iterable<WorkflowInstanceRow> rows,
  ) async {
    for (final row in rows) {
      final machine = await _getDefinition(row.workflowType);
      if (machine == null && _failClosedOnMissingDefinition) return true;
      if (machine == null) continue;
      if (machine.visibility.defaultValue != WorkflowVisibilityDefault.public) {
        return true;
      }
      // A public workflow can still restrict individual states. Without this,
      // the filtering shortcut below would decide a page of public rows needs
      // no visibility pass and hand back exactly the guarded drafts the state
      // guard exists to withhold -- which is the Book Club case, the worst of
      // the three.
      if (machine.states.values.any((state) => state.readGuard != null)) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _isActiveMember(String fanId) async {
    final lookup = _activeMembershipLookup;
    if (lookup == null) return false;
    return lookup(fanId);
  }

  Future<void> _requireSurfacePermission({
    required String fanId,
    String? tabId,
    String? workflowType,
  }) async {
    final lookup = _surfacePermissionLookup;
    if (lookup == null) return;
    final roleIds = _roleIdsByFanId[fanId] ?? const <String>{};
    final allowed = roleIds.isEmpty
        ? await lookup(fanId: fanId, tabId: tabId, workflowType: workflowType)
        : await _hasSurfacePermissionForAnyRole(
            lookup,
            fanId: fanId,
            roleIds: roleIds,
            tabId: tabId,
            workflowType: workflowType,
          );
    if (!allowed) {
      final surface = tabId ?? workflowType ?? 'unknown';
      throw StateError('Permission denied for surface "$surface" for $fanId');
    }
  }

  Future<bool> _hasSurfacePermissionForAnyRole(
    WorkflowSurfacePermissionLookup lookup, {
    required String fanId,
    required Set<String> roleIds,
    required String? tabId,
    required String? workflowType,
  }) async {
    for (final roleId in roleIds) {
      if (await lookup(
        fanId: fanId,
        roleId: roleId,
        tabId: tabId,
        workflowType: workflowType,
      )) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _isVisibleToFan(
    WorkflowInstance instance,
    LoomWorkflowStateMachine? machine,
    String fanId,
    Future<bool> Function() activeMembership,
  ) async {
    if (machine == null) return !_failClosedOnMissingDefinition;
    // The `owner` visibility model (CONTRACTS.md §3), which every archetype
    // supports: whoever created an instance can always read it. Only `guarded`
    // honoured this before, so a creator who was not an active member could not
    // read their own `membersOnly` instance -- their own submitted request, for
    // example, the moment their membership lapsed.
    //
    // Fails closed by construction: an unset creator matches nobody, rather
    // than matching an unset viewer. That asymmetry is the whole point of the
    // "all models fail closed" clause -- seed data carrying no identity must
    // render to no one instead of leaking to everyone.
    if (instance.createdByFanId.isNotEmpty &&
        instance.createdByFanId == fanId) {
      return true;
    }
    if (_isVisibleThroughArchetype(instance, machine, fanId)) {
      return true;
    }
    // A state's own readGuard narrows, whatever the workflow's default is.
    //
    // This used to be consulted only under `guarded`, so a state guard declared
    // alongside a `public` or `membersOnly` default was parsed, stored, and
    // silently ignored. Three shipped workflows relied on it: Cedar Commons
    // HOA kept draft, archived and deleted documents to `hoa-board` under a
    // `membersOnly` default, and Book Club kept nomination and selection drafts
    // to a role under a `public` one -- which made those drafts readable by
    // anyone at all.
    //
    // The packages were authored correctly. `document-library.md` §3 states
    // that "per-state read guards already exist ... which the engine prefers
    // over the workflow-level guard", and pairs a `membersOnly` default with
    // board-only state guards in its worked example. The engine simply did not
    // implement the contract its own reference described.
    //
    // Narrowing only. Creator and archetype-share visibility are decided above
    // this and still apply, so an author can always read their own draft.
    final stateGuard = machine.states[instance.currentState]?.readGuard;
    if (stateGuard != null) {
      return evaluateGuard(
        stateGuard,
        fanId,
        instance.instanceData,
        roleIds: _roleIdsByFanId[fanId],
        clock: _clock,
      );
    }

    switch (machine.visibility.defaultValue) {
      case WorkflowVisibilityDefault.public:
        return true;
      case WorkflowVisibilityDefault.membersOnly:
        return activeMembership();
      case WorkflowVisibilityDefault.guarded:
        final readGuard = machine.visibility.readGuard;
        if (readGuard == null) return false;
        return evaluateGuard(
          readGuard,
          fanId,
          instance.instanceData,
          roleIds: _roleIdsByFanId[fanId],
          clock: _clock,
        );
    }
  }

  /// Which transitions [fanId] may invoke because a document was shared with
  /// them, rather than because of a role they hold.
  ///
  /// This implements `ArchetypeContract.sharingGrantable`, which has been
  /// declared since the archetype contracts were written and read by nothing.
  /// `documentLibrary` declares `{open, download, edit}`: being shared a
  /// document lets you open, download and edit it, and nothing else.
  ///
  /// The grantable set comes from the contract, never from community JSON. A
  /// package that could name its own grantable actions could add `delete` and
  /// hand an individual the power to destroy a document the community's roles
  /// reserve to a board -- so lifecycle actions are not grantable to anyone,
  /// by construction rather than by policy.
  ///
  /// Returns a predicate rather than a bool so the shared-with membership test
  /// runs once per instance instead of once per transition.
  bool Function(LoomWorkflowTransition transition) _archetypeGrantPredicate(
    LoomWorkflowStateMachine machine,
    Map<String, dynamic> instanceData,
    String fanId,
  ) {
    const denyAll = _denyAllTransitions;
    final family = _resolvedArchetypes[machine.workflowType]?.family;
    final contract = ArchetypeResolver.contracts[family];
    if (contract == null || contract.sharingGrantable.isEmpty) return denyAll;

    // The community names the field; the archetype does not fix it. An
    // undeclared field grants nobody anything, which is the same fail-closed
    // reading the visibility model applies.
    final sharedField = machine.visibility.fields.sharedWith;
    if (sharedField == null || sharedField.isEmpty) return denyAll;

    if (!_identityFieldMatches(
      instanceData,
      sharedField,
      fanId,
      shape: _IdentityFieldShape.list,
    )) {
      return denyAll;
    }

    return (transition) {
      final action = transition.action;
      // A transition declaring no action is community-defined. The archetype
      // has no idea what it means, so it cannot be granted -- the same honest
      // outcome such transitions get for per-person bookkeeping.
      return action != null && contract.sharingGrantable.contains(action);
    };
  }

  bool _isVisibleThroughArchetype(
    WorkflowInstance instance,
    LoomWorkflowStateMachine machine,
    String fanId,
  ) {
    final family = _resolvedArchetypes[machine.workflowType]?.family;
    final model = ArchetypeResolver.contracts[family]?.visibility;
    final fields = machine.visibility.fields;

    return switch (model) {
      VisibilityModel.ownerAndShared =>
        fields.sharedWith != null &&
            _identityFieldMatches(
              instance.instanceData,
              fields.sharedWith!,
              fanId,
              shape: _IdentityFieldShape.list,
            ),
      VisibilityModel.participants => fields.participants.any(
        (field) => _identityFieldMatches(
          instance.instanceData,
          field,
          fanId,
          shape: _IdentityFieldShape.scalarOrList,
        ),
      ),
      VisibilityModel.parties => fields.parties.any(
        (principal) => switch (principal) {
          WorkflowVisibilityFieldPrincipal(:final fieldName) =>
            _identityFieldMatches(
              instance.instanceData,
              fieldName,
              fanId,
              shape: _IdentityFieldShape.scalar,
            ),
          WorkflowVisibilityRolePrincipal(:final roleId) =>
            _visibilityRoleMatches(fanId, roleId),
        },
      ),
      VisibilityModel.recipient =>
        fields.recipient != null &&
            _identityFieldMatches(
              instance.instanceData,
              fields.recipient!,
              fanId,
              shape: _IdentityFieldShape.scalar,
            ),
      VisibilityModel.roles || VisibilityModel.owner || null => false,
    };
  }

  bool _visibilityRoleMatches(String fanId, String roleId) {
    if (fanId.isEmpty || roleId.isEmpty) return false;
    final resolvedRoleIds = _roleIdsByFanId[fanId];
    return resolvedRoleIds != null && resolvedRoleIds.contains(roleId);
  }

  /// Reads the declared specVersion 4 identity field exactly as authored.
  ///
  /// Empty viewers and empty/unset field values never match. The declared
  /// field name is the only source of truth.
  bool _identityFieldMatches(
    Map<String, dynamic> instanceData,
    String declaredField,
    String fanId, {
    required _IdentityFieldShape shape,
    List<String>? candidateSpellings,
  }) {
    if (declaredField.isEmpty) return false;

    final spellings = <String>[declaredField];
    candidateSpellings?.addAll(spellings);
    if (fanId.isEmpty) return false;

    for (final field in spellings) {
      final value = instanceData[field];
      if (shape != _IdentityFieldShape.list &&
          value is String &&
          value.isNotEmpty &&
          value == fanId) {
        return true;
      }
      if (shape != _IdentityFieldShape.scalar && value is Iterable) {
        if (value.any(
          (entry) => entry is String && entry.isNotEmpty && entry == fanId,
        )) {
          return true;
        }
      }
    }
    return false;
  }

  String _cursorForRow(String sortKey, WorkflowInstanceRow row) {
    final data = jsonDecode(row.instanceData) as Map<String, dynamic>;
    final cursorValue = '${data[sortKey] ?? ''}';
    // Encode sortKey into cursor so the DB layer can detect mismatches.
    return '$sortKey\x1f$cursorValue\x1f${row.instanceId}';
  }

  bool _matchesAudienceQuery(
    Map<String, dynamic> instanceData,
    String fanId,
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
    if (invited is Iterable) return invited.contains(fanId);
    return false;
  }

  /// Reads every persisted row for [workflowType] in this community.
  /// Used by both [aggregate] and GAP-4 source-query execution.
  Future<List<Map<String, dynamic>>> _readAllInstancesOfType(
    String workflowType,
  ) async {
    final rows = await _db.queryInstancesKeyset(
      communityId: _communityId,
      limit: 1 << 30,
      sortKey: 'instanceId',
    );
    return rows.where((row) => row.workflowType == workflowType).map((row) {
      final data = jsonDecode(row.instanceData) as Map<String, dynamic>;
      if (data.containsKey(r'$state') || data.containsKey(r'$id')) {
        throw StateError(
          r'instanceData must not define reserved keys "$state" or "$id"',
        );
      }
      return {...data, r'$state': row.currentState, r'$id': row.instanceId};
    }).toList();
  }

  /// Reads and filters rows for a viewer-scoped aggregate. The unscoped
  /// aggregate path above remains the system-truth path used by guard math.
  Future<List<Map<String, dynamic>>> _readVisibleInstancesOfType(
    String workflowType,
    String fanId,
  ) async {
    final rows = await _db.queryInstancesKeyset(
      communityId: _communityId,
      limit: 1 << 30,
      sortKey: 'instanceId',
    );
    Future<bool>? activeMembership;
    Future<bool> lookupActiveMembership() =>
        activeMembership ??= _isActiveMember(fanId);
    final visible = <Map<String, dynamic>>[];

    for (final row in rows.where((row) => row.workflowType == workflowType)) {
      final raw = _rawInstance(row).instanceData;
      if (raw.containsKey(r'$state') || raw.containsKey(r'$id')) {
        throw StateError(
          r'instanceData must not define reserved keys "$state" or "$id"',
        );
      }
      final candidate = await _hydrateQueryRow(row, fanId);
      if (!await _isVisibleToFan(
        candidate.instance,
        candidate.machine,
        fanId,
        lookupActiveMembership,
      )) {
        continue;
      }
      visible.add({
        ...candidate.instance.instanceData,
        r'$state': row.currentState,
        r'$id': row.instanceId,
      });
    }
    return visible;
  }

  @override
  Future<dynamic> aggregate({
    required String workflowType,
    required String column,
    required String op,
    Map<String, dynamic>? filter,
    String? groupBy,
    String? fanId,
  }) async {
    const supported = {'count', 'sum', 'avg', 'min', 'max', 'countDistinct'};
    if (!supported.contains(op)) {
      throw ArgumentError.value(op, 'op', 'Unsupported aggregate operation');
    }
    final allRows = fanId == null
        ? await _readAllInstancesOfType(workflowType)
        : await _readVisibleInstancesOfType(workflowType, fanId);
    final data = allRows
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

      // Compute before filtering. `dueAt` is not always a stored value: Cedar
      // Commons HOA derives its reservation reminder with
      // `if(reminderEnabled == true, subtractHours(combineDateAndTime(eventDate,
      // eventTime), 24), null)`, so the stored map holds `reminderEnabled` and
      // no `dueAt` at all. Reading the raw map skipped every such row, which
      // meant the community that models reminders most completely could never
      // receive one.
      //
      // The cost is real and accepted: the definition lookup and source-field
      // hydration now run for every row rather than only for rows that already
      // matched. A reminder that cannot be found is worse than a sweep that
      // does more work.
      final machine = await _getDefinition(row.workflowType);
      final hydrated = machine != null
          ? await _hydrateSourceFields(data, machine, row.instanceId)
          : data;
      final computed = _withComputedFields(hydrated, machine);

      // Two shapes, because `dueAt` arrives two ways. A stored one is the ISO
      // string an effect wrote; a computed one is whatever the formula
      // evaluated to, and `subtractHours(combineDateAndTime(...))` yields a
      // DateTime rather than text. Checking only for a String was why the
      // computed case stayed invisible even after the filter moved.
      // Two ways a reminder says when it is due, and the declared one wins.
      //
      // A `reminder` block is the package stating intent -- "24 hours before
      // eventDate/eventTime, when reminderEnabled" -- and the platform working
      // out the instant. That is where the calculation belongs: the grammar
      // stays declarative, and the timezone question has one home instead of
      // being spread across every formula that combines a date with a time.
      //
      // A stored `dueAt` is the other shape and stays supported: Book Club and
      // Garden Club materialise a notification instance whose dueAt is written
      // outright by a createInstance effect. That is data, not calculation, so
      // there is nothing to move.
      final declared = machine?.reminder?.dueAtFor(computed);
      final rawDueAt = declared ?? computed['dueAt'];
      final DateTime? dueAt = switch (rawDueAt) {
        final DateTime value => value,
        final String value => DateTime.tryParse(value),
        _ => null,
      };
      // NOTE: a computed `dueAt` is timezone-naive. `combineDateAndTime` builds
      // it from a bare date and time, so it lands in the server's local zone,
      // while `asOf` arrives as UTC. The comparison is therefore correct only
      // relative to wherever this runs: the same reservation is due at a
      // different absolute instant on a PDT server than on a UTC one. Filed
      // rather than fixed here -- the formula grammar has no timezone, so the
      // fix is a spec question, not a comparison one.
      if (dueAt == null || dueAt.isAfter(asOf)) continue;

      due.add(
        WorkflowInstance(
          instanceId: row.instanceId,
          workflowType: row.workflowType,
          currentState: row.currentState,
          instanceData: computed,
          createdByFanId: row.createdByFanId,
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
    required String fanId,
  }) {
    final defId = '${_communityId}_$workflowType';
    final machine = _definitions[defId];
    if (machine == null) return const [];

    final resolvedData = _withComputedFields(
      instanceData,
      machine,
      viewerId: fanId,
    );
    return trans_eval.availableTransitions(
      machine,
      currentState,
      fanId,
      resolvedData,
      roleIds: _roleIdsByFanId[fanId],
      clock: _clock,
      grantedByArchetype: _archetypeGrantPredicate(
        machine,
        resolvedData,
        fanId,
      ),
    );
  }

  @override
  Future<List<LoomWorkflowTransition>> availableTransitionsAsync({
    required String workflowType,
    required String instanceId,
    required String currentState,
    required Map<String, dynamic> instanceData,
    required String fanId,
  }) async {
    final machine = await _getDefinition(workflowType);
    if (machine == null) return const [];
    // Cross-workflow guards must use the same live completion projection as
    // applyTransition. Without this read, a just-paid dues instance remains
    // invisible to the UI action resolver even though the mutation is
    // already persisted.
    final completedWorkflowIds = await completedWorkflowIdsForFan(fanId);
    final computedForFan = _withComputedFields(
      instanceData,
      machine,
      viewerId: fanId,
    );
    final candidates = trans_eval.availableTransitions(
      machine,
      currentState,
      fanId,
      computedForFan,
      roleIds: _roleIdsByFanId[fanId],
      completedWorkflowIds: completedWorkflowIds,
      skipRelatedAggregate: true,
      clock: _clock,
      grantedByArchetype: _archetypeGrantPredicate(
        machine,
        computedForFan,
        fanId,
      ),
    );
    final result = <LoomWorkflowTransition>[];
    for (final transition in candidates) {
      if (!_isArchetypeActionEligible(
        machine: machine,
        transition: transition,
        instanceData: instanceData,
        fanId: fanId,
      )) {
        continue;
      }
      if (!await _passesRelatedListGuard(
        transition.guard,
        instanceData,
        fanId,
      )) {
        continue;
      }
      if (!await _passesRelatedAggregateGuard(
        transition.guard,
        instanceData,
        fanId,
      )) {
        continue;
      }
      result.add(transition);
    }
    return result;
  }

  Future<Set<String>> completedWorkflowIdsForFan(String fanId) async {
    final rows = await _db.queryInstancesForFan(
      communityId: _communityId,
      fanId: fanId,
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
    required String fanId,
    Map<String, dynamic>? inputs,
  }) async {
    try {
      await _requireSurfacePermission(fanId: fanId, workflowType: workflowType);
      // Resolve guards and GAP-1 inputs before opening a transaction. Besides
      // preserving the public validation contract, this means an expected
      // StateError never enters the database transaction machinery.
      final resolved = await _resolveTransition(
        workflowType: workflowType,
        instanceId: instanceId,
        transitionId: transitionId,
        fanId: fanId,
        inputs: inputs,
        validateInputs: true,
      );
      late final WorkflowTransitionResult result;
      await _db.transaction(() async {
        result = await _applyTransitionWithinTransaction(
          resolved: resolved,
          fanId: fanId,
        );
      });
      final machine = await _getDefinition(workflowType);
      return WorkflowTransitionResult(
        newState: result.newState,
        newInstanceData: await _hydrateSourceFields(
          result.newInstanceData,
          machine!,
          instanceId,
        ),
      );
    } on _TransitionGuardFailure catch (error) {
      throw StateError(error.message);
    }
  }

  /// Resolves a transition without performing writes or opening a transaction.
  ///
  /// This phase deliberately contains all failures which must occur before a
  /// top-level [applyTransition] transaction, including GAP-1 input checks.
  Future<_ResolvedTransition> _resolveTransition({
    required String workflowType,
    required String instanceId,
    required String transitionId,
    required String fanId,
    Map<String, dynamic>? inputs,
    required bool validateInputs,
  }) async {
    final machine = await _getDefinition(workflowType);
    if (machine == null) {
      throw StateError('Unknown workflow type: $workflowType');
    }

    final row = await _db.readInstance(instanceId);
    if (row == null) throw StateError('Instance $instanceId not found');

    final data = jsonDecode(row.instanceData) as Map<String, dynamic>;
    final completedWorkflowIds = await completedWorkflowIdsForFan(fanId);
    final computedData = _withComputedFields(
      data,
      machine,
      viewerId: fanId,
      actorId: fanId,
    );
    final transitions = trans_eval.availableTransitions(
      machine,
      row.currentState,
      fanId,
      computedData,
      roleIds: _roleIdsByFanId[fanId],
      completedWorkflowIds: completedWorkflowIds,
      skipRelatedAggregate: true,
      clock: _clock,
      grantedByArchetype: _archetypeGrantPredicate(
        machine,
        computedData,
        fanId,
      ),
    );

    final declaredTransition = machine.transitions.firstWhere(
      (t) => t.id == transitionId,
      orElse: () => throw StateError('Unknown transition $transitionId'),
    );
    if (!declaredTransition.from.contains(row.currentState)) {
      throw StateError(
        'Transition $transitionId not available from state ${row.currentState}',
      );
    }
    LoomWorkflowTransition? transition;
    for (final candidate in transitions) {
      if (candidate.id == transitionId) {
        transition = candidate;
        break;
      }
    }
    if (transition == null) {
      throw _TransitionGuardFailure(
        'Transition $transitionId is not available for $fanId',
      );
    }
    if (!_isArchetypeActionEligible(
      machine: machine,
      transition: transition,
      instanceData: data,
      fanId: fanId,
    )) {
      throw _TransitionGuardFailure(
        'Transition $transitionId is not available for $fanId',
      );
    }
    if (!await _passesRelatedListGuard(transition.guard, data, fanId)) {
      throw _TransitionGuardFailure(
        'Transition $transitionId is not available for $fanId',
      );
    }
    if (!await _passesRelatedAggregateGuard(transition.guard, data, fanId)) {
      throw _TransitionGuardFailure(
        'Transition $transitionId is not available for $fanId',
      );
    }

    // GAP-1: validate required transition inputs outside a transaction.
    if (validateInputs && transition.inputs != null) {
      for (final entry in transition.inputs!.entries) {
        if (entry.value.required &&
            (inputs == null || !inputs.containsKey(entry.key))) {
          throw StateError(
            'Transition $transitionId requires input "${entry.key}"',
          );
        }
      }
    }

    return _ResolvedTransition(
      machine: machine,
      row: row,
      data: data,
      transition: transition,
      inputs: inputs,
    );
  }

  /// Applies a resolved transition while the caller owns the database
  /// transaction.
  ///
  /// Cross-instance effects use this helper directly so they neither nest
  /// transactions nor bypass the target's live guards.
  Future<WorkflowTransitionResult> _applyTransitionWithinTransaction({
    required _ResolvedTransition resolved,
    required String fanId,
  }) async {
    final machine = resolved.machine;
    final row = resolved.row;
    final data = resolved.data;
    final transition = resolved.transition;
    final inputs = resolved.inputs;
    final instanceId = row.instanceId;

    final newState = transition.to ?? row.currentState;

    if (_containsTransitionRelated(transition.effects)) {
      // Make this transition's new state visible to cross-instance effects.
      // This is essential when a target's fresh relatedAggregate guard
      // observes the source row (for example, a going RSVP releasing a seat
      // for a waitlist promotion). The surrounding transaction rolls this
      // provisional update back if an effect later fails.
      await _db.updateInstanceState(
        instanceId: instanceId,
        newState: newState,
        newInstanceData: _storageOnly(data, machine),
      );
    }

    final effectedData = await _applyExtendedEffects(
      transition.effects,
      machine: machine,
      sourceData: data,
      fanId: fanId,
      inputValues: inputs,
      instanceId: instanceId,
    );
    final newData = _applyArchetypeBookkeeping(
      machine: machine,
      transition: transition,
      sourceData: effectedData,
      fanId: fanId,
    );
    await _db.updateInstanceState(
      instanceId: instanceId,
      newState: newState,
      newInstanceData: _storageOnly(newData, machine),
    );
    if (transition.action == 'create') {
      await _fanOutEventRsvpResponseRows(
        eventMachine: machine,
        eventInstanceId: instanceId,
        createdByFanId: fanId,
      );
    }

    return WorkflowTransitionResult(
      newState: newState,
      newInstanceData: newData,
    );
  }

  /// Materializes the response-table row owned by `event-rsvp` for every
  /// currently active, registered community member.
  ///
  /// Registration is the engine's existing enumerable membership boundary:
  /// [setRoleForFan] supplies account ids, and [_activeMembershipLookup]
  /// filters them against the same account store used by members-only reads.
  /// No workflow or community JSON supplies identities.
  Future<void> _fanOutEventRsvpResponseRows({
    required LoomWorkflowStateMachine eventMachine,
    required String eventInstanceId,
    required String createdByFanId,
  }) async {
    final resolved = _resolvedArchetypes[eventMachine.workflowType];
    if (resolved?.family != 'event-rsvp') return;

    ResponseTableSpec? responseTable;
    for (final binding in eventMachine.renderBindings) {
      if (binding.cardSurfaceFamily == 'event-rsvp' &&
          binding.responseTable != null) {
        responseTable = binding.responseTable;
        break;
      }
    }
    if (responseTable == null) return;
    final responseSpec = responseTable;

    final responseMachine = await _getDefinition(responseSpec.workflowType);
    if (responseMachine == null) {
      throw StateError(
        'Unknown event-rsvp response workflow type: '
        '${responseSpec.workflowType}',
      );
    }

    const responseIdentityField = 'fanId';
    if (!responseMachine.instanceDataSchema.containsKey(
      responseIdentityField,
    )) {
      throw StateError(
        'event-rsvp response workflow ${responseSpec.workflowType} must '
        'declare fanId in instanceDataSchema',
      );
    }

    final registeredFanIds = _roleIdsByFanId.keys.toList(growable: false);
    final membershipLookup = _activeMembershipLookup;
    final memberFanIds = membershipLookup == null
        ? registeredFanIds
        : <String>[
            for (final fanId in registeredFanIds)
              if (await membershipLookup(fanId)) fanId,
          ];
    if (memberFanIds.isEmpty) return;

    final existingRows = (await _readAllInstancesOfType(
      responseSpec.workflowType,
    )).where((row) => row[responseSpec.eventField] == eventInstanceId);
    for (final memberFanId in memberFanIds) {
      final alreadyExists = existingRows.any(
        (row) => _identityFieldMatches(
          row,
          responseIdentityField,
          memberFanId,
          shape: _IdentityFieldShape.scalar,
        ),
      );
      if (alreadyExists) continue;

      await _createInstanceValidated(
        workflowType: responseSpec.workflowType,
        initialInstanceData: <String, dynamic>{
          responseSpec.eventField: eventInstanceId,
          responseIdentityField: memberFanId,
        },
        fanId: createdByFanId,
      );
    }
  }

  @override
  Future<String> createInstance({
    required String workflowType,
    required Map<String, dynamic> initialInstanceData,
    required String fanId,
  }) => _createInstanceFromCreateAction(
    workflowType: workflowType,
    initialInstanceData: initialInstanceData,
    fanId: fanId,
  );

  /// Creates one row through the singular creation action used by current
  /// packages, then supplies their pre-action-grammar event-rsvp behavior.
  Future<String> _createInstanceFromCreateAction({
    required String workflowType,
    required Map<String, dynamic> initialInstanceData,
    required String fanId,
  }) async {
    final instanceId = await _createInstanceValidated(
      workflowType: workflowType,
      initialInstanceData: initialInstanceData,
      fanId: fanId,
    );
    final machine = await _getDefinition(workflowType);
    if (machine != null &&
        !machine.transitions.any(
          (transition) => transition.action == 'create',
        )) {
      // Existing packages express tab-level creation as a render-binding
      // `kind: create` action whose submit path calls this singular API
      // directly. Once a workflow declares an explicit create transition, the
      // transaction path above is the sole trigger instead.
      await _fanOutEventRsvpResponseRows(
        eventMachine: machine,
        eventInstanceId: instanceId,
        createdByFanId: fanId,
      );
    }
    return instanceId;
  }

  @override
  Future<List<String>> createInstances({
    required String workflowType,
    required List<Map<String, dynamic>> initialInstanceDataList,
    required String fanId,
  }) async {
    final ids = <String>[];
    await _db.transaction(() async {
      for (final initialInstanceData in initialInstanceDataList) {
        ids.add(
          await _createInstanceValidated(
            workflowType: workflowType,
            initialInstanceData: initialInstanceData,
            fanId: fanId,
          ),
        );
      }
    });
    return ids;
  }

  Future<String> _createInstanceValidated({
    required String workflowType,
    required Map<String, dynamic> initialInstanceData,
    required String fanId,
  }) async {
    final machine = await _getDefinition(workflowType);
    if (machine == null) {
      throw StateError('Unknown workflow type: $workflowType');
    }

    _validateSeedData(machine, initialInstanceData);

    final initialState = machine.states[machine.initialState];
    if (initialState == null) {
      throw StateError(
        'Unknown state ${machine.initialState} for $workflowType',
      );
    }
    final creationGuard = initialState.creationGuard;
    if (creationGuard != null &&
        !await _passesGuard(
          creationGuard,
          initialInstanceData,
          fanId,
          workflowType: workflowType,
        )) {
      throw StateError('Creation of $workflowType is not available for $fanId');
    }

    final instanceId = '${_communityId}_${workflowType}_${_generateId()}';
    await _db.insertInstance(
      instanceId: instanceId,
      communityId: _communityId,
      workflowType: workflowType,
      currentState: machine.initialState,
      instanceData: initialInstanceData,
      createdByFanId: fanId,
    );

    // NOTE: this branch is dead against every shipped community. It fires only
    // when `workflowType` is literally 'notification', and no package declares
    // one by that name -- the five that have a notification workflow call it
    // `book-notification`, `garden-notification`, `hoa-owner-notification`,
    // `mosque-neutral-notification` or `soccer-reminder-notification`. It also
    // delivers at creation, which is the wrong moment for a reminder carrying a
    // future `dueAt`.
    //
    // Left in place rather than removed: it is covered by
    // notification_delivery_service_test.dart, and deleting a mechanism to
    // replace it is a separate change from adding the one that works. Real
    // delivery is now LoomReminderSweeper in the app shell, sweeping
    // `dueNotifications(asOf:)` -- which is what permissions.md has always
    // described `deliver_reminder` as.
    final deliveryService = _notificationDeliveryService;
    if (workflowType == 'notification' && deliveryService != null) {
      final notification = WorkflowInstance(
        instanceId: instanceId,
        workflowType: workflowType,
        currentState: machine.initialState,
        instanceData: Map<String, dynamic>.from(initialInstanceData),
        createdByFanId: fanId,
      );
      unawaited(() async {
        try {
          await deliveryService.deliver(notification);
        } catch (_) {
          // Delivery is best-effort. A platform/backend failure must not
          // affect the already-committed workflow instance creation.
        }
      }());
    }

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
            existing.createdByFanId != instance.createdByFanId ||
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
          createdByFanId: instance.createdByFanId,
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
    required String fanId,
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

      final data = jsonDecode(row.instanceData) as Map<String, dynamic>;
      if (fieldUpdates.isNotEmpty) {
        final editGuard = stateDef.editGuard;
        // A location-overlap edit guard must examine the proposed booking,
        // while existing edit guards retain their established current-data
        // authorization semantics.
        final guardData = editGuard?.locationOverlap != null
            ? {...data, ...fieldUpdates}
            : data;
        if (editGuard != null &&
            !await _passesGuard(
              editGuard,
              guardData,
              fanId,
              workflowType: workflowType,
              instanceId: instanceId,
            )) {
          throw WorkflowAuthorizationError(
            'Fields are not editable in state "${row.currentState}" for $fanId',
          );
        }
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
        if (schema != null && schema.isMachineWritten) {
          throw WorkflowAuthorizationError(
            'Field "$key" is written by the ${schema.writableBy} and cannot be '
            'user-edited',
          );
        }
      }

      data.addAll(fieldUpdates);
      await _db.updateInstanceState(
        instanceId: instanceId,
        newState: row.currentState,
        newInstanceData: data,
      );
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  /// Storage-only projection of instance data.
  ///
  /// Computed fields exist only on the read projection. Their evaluated
  /// values are re-derived by [_withComputedFields] on every read and must
  /// never be handed to the database, since some computed types (for example
  /// [DateTime]) are not JSON-encodable.
  Map<String, dynamic> _storageOnly(
    Map<String, dynamic> data,
    LoomWorkflowStateMachine machine,
  ) => {
    for (final entry in data.entries)
      if (machine.instanceDataSchema[entry.key]?.formula == null)
        entry.key: entry.value,
  };

  Map<String, dynamic> _applyArchetypeBookkeeping({
    required LoomWorkflowStateMachine machine,
    required LoomWorkflowTransition transition,
    required Map<String, dynamic> sourceData,
    required String fanId,
  }) {
    final family = _resolvedArchetypes[machine.workflowType]?.family;
    final action = transition.action;
    if (family == null || action == null) return sourceData;

    final rule = _archetypeBookkeepingByAction[family]?[action];
    if (rule == null) return sourceData;
    final (contractField, operation) = rule;

    final candidateSpellings = <String>[];
    final actorIsPresent = _identityFieldMatches(
      sourceData,
      contractField,
      fanId,
      shape: _IdentityFieldShape.list,
      candidateSpellings: candidateSpellings,
    );
    final storageField = candidateSpellings.firstWhere(
      machine.instanceDataSchema.containsKey,
      orElse: () => candidateSpellings.firstWhere(
        sourceData.containsKey,
        orElse: () => contractField,
      ),
    );

    final existing = sourceData[storageField];
    final existingList = existing is List
        ? List<dynamic>.from(existing)
        : <dynamic>[];
    final actorCount = existingList.where((value) => value == fanId).length;

    switch (operation) {
      case _ArchetypeBookkeepingOperation.addActor:
        // A match under the other D8 spelling already represents this actor.
        // Do not create a second physical entry while both spellings coexist.
        if (actorIsPresent && actorCount <= 1) return sourceData;
        return Map<String, dynamic>.from(sourceData)
          ..[storageField] = <dynamic>[
            ...existingList.where((value) => value != fanId),
            fanId,
          ];
      case _ArchetypeBookkeepingOperation.removeActor:
        if (!actorIsPresent || actorCount == 0) return sourceData;
        return Map<String, dynamic>.from(sourceData)
          ..[storageField] = existingList
              .where((value) => value != fanId)
              .toList(growable: false);
    }
  }

  bool _isArchetypeActionEligible({
    required LoomWorkflowStateMachine machine,
    required LoomWorkflowTransition transition,
    required Map<String, dynamic> instanceData,
    required String fanId,
  }) {
    final family = _resolvedArchetypes[machine.workflowType]?.family;
    final action = transition.action;
    if (family == null || action == null) return true;

    final rule = _archetypeMembershipEligibilityByAction[family]?[action];
    if (rule == null) return true;
    final (contractField, actorMustBePresent) = rule;
    final actorIsPresent = _identityFieldMatches(
      instanceData,
      contractField,
      fanId,
      shape: _IdentityFieldShape.list,
    );
    return actorIsPresent == actorMustBePresent;
  }

  /// Checks a guard's database-backed conditions before its synchronous ones.
  ///
  /// [evaluateGuard] intentionally skips related aggregates here because the
  /// preceding helper resolves and evaluates them against live database data.
  Future<bool> _passesGuard(
    WorkflowGuard guard,
    Map<String, dynamic> data,
    String fanId, {
    String? workflowType,
    String? instanceId,
  }) async {
    if (!await _passesRelatedListGuard(guard, data, fanId)) return false;
    if (!await _passesRelatedAggregateGuard(guard, data, fanId)) {
      return false;
    }
    if (!await _passesLocationOverlapGuard(
      guard,
      data,
      workflowType: workflowType,
      instanceId: instanceId,
    )) {
      return false;
    }
    return evaluateGuard(
      guard,
      fanId,
      data,
      roleIds: _roleIdsByFanId[fanId],
      skipRelatedAggregate: true,
      clock: _clock,
    );
  }

  Future<bool> _passesLocationOverlapGuard(
    WorkflowGuard guard,
    Map<String, dynamic> sourceData, {
    required String? workflowType,
    required String? instanceId,
  }) async {
    final overlap = guard.locationOverlap;
    if (overlap == null) return true;
    if (workflowType == null) return false;

    final location = sourceData[overlap.locationField];
    final start = combineDateAndTime(
      sourceData,
      dateField: overlap.dateField,
      timeField: overlap.timeField,
    );
    if (start == null || overlap.durationMinutes <= 0) return false;
    final end = start.add(
      Duration(
        milliseconds: (overlap.durationMinutes * Duration.millisecondsPerMinute)
            .round(),
      ),
    );

    for (final candidate in await _readAllInstancesOfType(workflowType)) {
      if (candidate[r'$id'] == instanceId ||
          candidate[overlap.locationField] != location) {
        continue;
      }
      final candidateStart = combineDateAndTime(
        candidate,
        dateField: overlap.dateField,
        timeField: overlap.timeField,
      );
      if (candidateStart == null) continue;
      final candidateEnd = candidateStart.add(
        Duration(
          milliseconds:
              (overlap.durationMinutes * Duration.millisecondsPerMinute)
                  .round(),
        ),
      );
      if (start.isBefore(candidateEnd) && candidateStart.isBefore(end)) {
        return false;
      }
    }
    return true;
  }

  Future<bool> _passesRelatedListGuard(
    WorkflowGuard guard,
    Map<String, dynamic> sourceData,
    String fanId,
  ) async {
    final related = guard.relatedListMembership;
    if (related == null) return true;
    final id = sourceData[related.relatedInstanceField];
    if (id is! String || id.isEmpty) return false;
    final row = await _db.readInstance(id);
    if (row == null) return false;
    final data = jsonDecode(row.instanceData) as Map<String, dynamic>;
    final members = data[related.relatedListField];
    return members is Iterable && members.contains(fanId);
  }

  Future<bool> _passesRelatedAggregateGuard(
    WorkflowGuard guard,
    Map<String, dynamic> sourceData,
    String fanId,
  ) async {
    final related = guard.relatedAggregate;
    if (related == null) return true;
    final filter = <String, dynamic>{
      for (final entry in related.filter.entries)
        entry.key: _resolveRelatedAggregateValue(entry.value, sourceData),
    };
    final aggregate = await this.aggregate(
      workflowType: related.workflowType,
      column: related.field ?? '',
      op: related.op,
      filter: filter,
    );
    final compareTo = await _resolveRelatedAggregateCompareTo(
      related.compareTo,
      sourceData,
    );
    return evaluateGuard(
      WorkflowGuard(relatedAggregate: related),
      fanId,
      sourceData,
      roleIds: _roleIdsByFanId[fanId],
      precomputedRelatedAggregate: aggregate is num ? aggregate : null,
      resolvedRelatedAggregateCompareTo: compareTo,
    );
  }

  dynamic _resolveRelatedAggregateValue(
    dynamic value,
    Map<String, dynamic> sourceData,
  ) {
    if (value is String && value.startsWith('{') && value.endsWith('}')) {
      return sourceData[value.substring(1, value.length - 1)];
    }
    return value;
  }

  Future<num?> _resolveRelatedAggregateCompareTo(
    dynamic compareTo,
    Map<String, dynamic> sourceData,
  ) async {
    if (compareTo is num) return compareTo;
    if (compareTo is! Map) return null;
    final relatedInstanceField = compareTo['relatedInstanceField'];
    final field = compareTo['field'];
    if (relatedInstanceField is! String || field is! String) return null;
    final id = sourceData[relatedInstanceField];
    if (id is! String || id.isEmpty) return null;
    final row = await _db.readInstance(id);
    if (row == null) return null;
    final target = jsonDecode(row.instanceData) as Map<String, dynamic>;
    final value = target[field];
    return value is num ? value : null;
  }

  Future<Map<String, dynamic>> _applyExtendedEffects(
    List<WorkflowEffect> effects, {
    required LoomWorkflowStateMachine machine,
    required Map<String, dynamic> sourceData,
    required String fanId,
    Map<String, dynamic>? inputValues,
    required String instanceId,
  }) async {
    var data = Map<String, dynamic>.from(sourceData);
    Future<void> applyList(List<WorkflowEffect> list) async {
      for (final effect in list) {
        final hydrated = await _hydrateSourceFields(data, machine, instanceId);
        final computed = _withComputedFields(
          hydrated,
          machine,
          viewerId: fanId,
          actorId: fanId,
        );
        if (effect.op == workflowEffectBranch) {
          if (effect.condition == null) {
            throw StateError('branch effect requires an "if" formula');
          }
          final condition = evaluateFormula(
            effect.condition!,
            instanceData: computed,
            viewerId: fanId,
            actorId: fanId,
          );
          if (condition is! bool) {
            throw StateError('branch "if" formula must evaluate to bool');
          }
          await applyList(condition ? effect.thenEffects : effect.elseEffects);
          continue;
        }
        if (effect.op == workflowEffectCreateInstance) {
          if (effect.workflowType == null || effect.fields == null) {
            throw StateError('createInstance requires workflowType and fields');
          }
          final fields = resolveEffectValue(
            effect.fields,
            fanId,
            computed,
            inputValues: inputValues,
            instanceId: instanceId,
          );
          await _createInstanceFromCreateAction(
            workflowType: effect.workflowType!,
            initialInstanceData: Map<String, dynamic>.from(fields as Map),
            fanId: fanId,
          );
          continue;
        }
        if (effect.op == workflowEffectSet && effect.relatedInstance != null) {
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
          final value = resolveEffectValue(
            effect.value,
            fanId,
            computed,
            instanceId: instanceId,
          );
          final updated = applyEffects(
            [
              WorkflowEffect(
                op: workflowEffectSet,
                key: effect.key,
                value: value,
              ),
            ],
            fanId,
            targetData,
            instanceId: instanceId,
          );
          await _db.updateInstanceState(
            instanceId: targetId,
            newState: target.currentState,
            newInstanceData: updated,
          );
          continue;
        }
        if (effect.op == workflowEffectTransitionRelated) {
          final relatedQuery = effect.relatedQuery;
          final transitionId = effect.transitionId;
          if (relatedQuery == null || transitionId == null) {
            throw StateError(
              'transitionRelated requires relatedQuery and transitionId',
            );
          }
          final filter = <String, dynamic>{
            for (final entry in relatedQuery.filter.entries)
              entry.key: _resolveRelatedAggregateValue(entry.value, computed),
          };
          final matches =
              (await _readAllInstancesOfType(relatedQuery.workflowType))
                  .where(
                    (row) => filter.entries.every(
                      (entry) => row[entry.key] == entry.value,
                    ),
                  )
                  .toList();
          final sortKey = relatedQuery.sortKey;
          if (sortKey != null) {
            matches.sort((left, right) {
              final leftValue = left[sortKey];
              final rightValue = right[sortKey];
              if (leftValue == null && rightValue == null) return 0;
              if (leftValue == null) return -1;
              if (rightValue == null) return 1;
              if (leftValue is Comparable && rightValue is Comparable) {
                return leftValue.compareTo(rightValue);
              }
              return 0;
            });
          }
          if (matches.isEmpty) continue;
          final targetId = matches.first[r'$id'];
          if (targetId is! String) {
            throw StateError(
              'transitionRelated match is missing reserved \$id',
            );
          }
          try {
            final resolved = await _resolveTransition(
              workflowType: relatedQuery.workflowType,
              instanceId: targetId,
              transitionId: transitionId,
              fanId: fanId,
              validateInputs: false,
            );
            final targetResult = await _applyTransitionWithinTransaction(
              resolved: resolved,
              fanId: fanId,
            );
            final onSuccessEffects = effect.onSuccessEffects;
            if (onSuccessEffects != null) {
              final targetData = await _applyExtendedEffects(
                onSuccessEffects,
                machine: resolved.machine,
                sourceData: targetResult.newInstanceData,
                fanId: fanId,
                instanceId: targetId,
              );
              await _db.updateInstanceState(
                instanceId: targetId,
                newState: targetResult.newState,
                newInstanceData: _storageOnly(targetData, resolved.machine),
              );
            }
          } on _TransitionGuardFailure {
            // A target guard failure deliberately does not affect the source.
          }
          continue;
        }
        if (effect.op == workflowEffectGenerateRecurringInstances) {
          final workflowType = effect.workflowType;
          final anchorField = effect.anchorField;
          final fields = effect.fields;
          final recurrenceRuleTemplate = effect.recurrenceRule;
          if (workflowType == null ||
              anchorField == null ||
              fields == null ||
              recurrenceRuleTemplate == null) {
            throw StateError(
              'generateRecurringInstances requires workflowType, anchorField, fields, '
              'and recurrenceRule',
            );
          }
          if (!fields.containsKey(anchorField)) {
            throw StateError(
              'generateRecurringInstances anchorField "$anchorField" must be a key in fields',
            );
          }

          final seriesId = _generateId();
          final fieldsWithSeriesToken = substituteSeriesIdToken(
            fields,
            seriesId,
          );
          final resolvedRule = resolveEffectValue(
            recurrenceRuleTemplate,
            fanId,
            computed,
            inputValues: inputValues,
            instanceId: instanceId,
          );
          final rule = RecurrenceRule.fromResolvedJson(
            Map<String, dynamic>.from(resolvedRule as Map),
          );
          final anchorRaw = resolveEffectValue(
            (fieldsWithSeriesToken as Map)[anchorField],
            fanId,
            computed,
            inputValues: inputValues,
            instanceId: instanceId,
          );
          final anchor = DateTime.parse(anchorRaw as String);
          final occurrenceDates = computeRecurrenceOccurrences(anchor, rule);

          data = applyEffects(
            [
              WorkflowEffect(
                op: workflowEffectSet,
                key: 'seriesId',
                value: seriesId,
              ),
            ],
            fanId,
            data,
            instanceId: instanceId,
          );
          for (var i = 1; i < occurrenceDates.length; i++) {
            final occurrenceFields =
                Map<String, dynamic>.from(fieldsWithSeriesToken)
                  ..[anchorField] = occurrenceDates[i]
                      .toIso8601String()
                      .substring(0, 10);
            final resolvedFields = resolveEffectValue(
              occurrenceFields,
              fanId,
              computed,
              inputValues: inputValues,
              instanceId: instanceId,
            );
            final occurrenceId = await _createInstanceValidated(
              workflowType: workflowType,
              initialInstanceData: Map<String, dynamic>.from(
                resolvedFields as Map,
              ),
              fanId: fanId,
            );
            final occurrenceMachine = await _getDefinition(workflowType);
            if (occurrenceMachine != null) {
              await _fanOutEventRsvpResponseRows(
                eventMachine: occurrenceMachine,
                eventInstanceId: occurrenceId,
                createdByFanId: fanId,
              );
            }
          }
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
          fanId,
          data,
          interpolationData: computed,
          inputValues: inputValues,
          instanceId: instanceId,
        );
      }
    }

    await applyList(effects);
    return data;
  }

  bool _containsTransitionRelated(List<WorkflowEffect> effects) => effects.any(
    (effect) =>
        effect.op == workflowEffectTransitionRelated ||
        _containsTransitionRelated(effect.thenEffects) ||
        _containsTransitionRelated(effect.elseEffects),
  );

  /// Executes GAP-4 source queries for every field with a `source`
  /// on the given machine and populates them into [data].
  Future<Map<String, dynamic>> _hydrateSourceFields(
    Map<String, dynamic> data,
    LoomWorkflowStateMachine machine,
    String instanceId,
  ) async {
    final result = Map<String, dynamic>.from(data);
    for (final entry in machine.instanceDataSchema.entries) {
      if (entry.value.source == null || result.containsKey(entry.key)) {
        continue;
      }
      final query = SourceQuery.tryParse(entry.value.source);
      if (query == null) continue;
      try {
        final localValue = query.localField == 'id'
            ? instanceId
            : result[query.localField];
        if (localValue == null) continue;
        final allRows = await _readAllInstancesOfType(query.workflowType);
        final matches = allRows
            .where((row) => row[query.foreignField] == localValue)
            .toList();
        if (matches.isNotEmpty) {
          result[entry.key] = matches;
        }
      } catch (_) {
        // Source resolution failed — leave field unpopulated.
      }
    }
    return result;
  }

  /// Instance data as consumers see it: formula fields evaluated, and the
  /// declared reminder surfaced as a value.
  ///
  /// `reminderAt` is computed by the platform and handed over as data. That is
  /// the point of moving reminders out of the formula language -- the package
  /// declares when it wants one, the platform works out the instant, and every
  /// reader keeps reading a field. The calendar surface already reads
  /// `reminderAt` to decide whether a reminder has fired, and does not need to
  /// know the value stopped being a formula.
  Map<String, dynamic> _withComputedFields(
    Map<String, dynamic> data,
    LoomWorkflowStateMachine? machine, {
    String? viewerId,
    String? actorId,
  }) {
    final computed = Map<String, dynamic>.from(
      _withFormulaFields(data, machine, viewerId: viewerId, actorId: actorId),
    );
    final reminder = machine?.reminder;
    if (reminder != null) {
      final dueAt = reminder.dueAtFor(computed);
      // Absent rather than null when no reminder is wanted: a key holding null
      // and a key that is not there read the same to every consumer here, and
      // omitting it keeps instance data free of fields that mean nothing.
      if (dueAt != null) computed['reminderAt'] = dueAt;
    }
    return computed;
  }

  Map<String, dynamic> _withFormulaFields(
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
      clock: _clock,
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
          if (v.editGuard != null) 'editGuard': _serializeGuard(v.editGuard!),
          if (v.creationGuard != null)
            'creationGuard': _serializeGuard(v.creationGuard!),
          if (v.readGuard != null)
            'readGuard': _serializeGuard(v.readGuard!) ?? <String, dynamic>{},
        }),
      ),
      'transitions': machine.transitions
          .map(
            (t) => {
              'id': t.id,
              'label': t.label,
              if (t.action != null) 'action': t.action,
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
                        if (e.relatedQuery != null)
                          'relatedQuery': {
                            'workflowType': e.relatedQuery!.workflowType,
                            'filter': e.relatedQuery!.filter,
                            if (e.relatedQuery!.sortKey != null)
                              'sortKey': e.relatedQuery!.sortKey,
                            if (e.relatedQuery!.limit != null)
                              'limit': e.relatedQuery!.limit,
                          },
                        if (e.transitionId != null)
                          'transitionId': e.transitionId,
                        if (e.onSuccessEffects != null)
                          'onSuccessEffects': e.onSuccessEffects!
                              .map(_serializeEffect)
                              .toList(),
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
                'audience': b.role,
                'tabId': b.tabId,
                'cardSurfaceFamily': b.cardSurfaceFamily,
                'bindingKind': b.bindingKind,
                if (b.audienceMemberField != null)
                  'audienceMemberField': b.audienceMemberField,
                if (b.responseTable != null)
                  'responseTable': {
                    'workflowType': b.responseTable!.workflowType,
                    'eventField': b.responseTable!.eventField,
                    'pendingStates': b.responseTable!.pendingStates,
                  },
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
      if (machine.visibility.isDeclared)
        'visibility': {
          'default': machine.visibility.defaultValue.name,
          if (!machine.visibility.fields.isEmpty)
            'fields': {
              if (machine.visibility.fields.sharedWith != null)
                'sharedWith': machine.visibility.fields.sharedWith,
              if (machine.visibility.fields.participants.isNotEmpty)
                'participants': machine.visibility.fields.participants,
              if (machine.visibility.fields.parties.isNotEmpty)
                'parties': [
                  for (final principal in machine.visibility.fields.parties)
                    switch (principal) {
                      WorkflowVisibilityFieldPrincipal(:final fieldName) =>
                        fieldName,
                      WorkflowVisibilityRolePrincipal(:final roleId) => {
                        'role': roleId,
                      },
                    },
                ],
              if (machine.visibility.fields.recipient != null)
                'recipient': machine.visibility.fields.recipient,
            },
          if (machine.visibility.readGuard != null)
            'readGuard':
                _serializeGuard(machine.visibility.readGuard!) ??
                <String, dynamic>{},
        },
    };
    return map;
  }

  Map<String, dynamic>? _serializeGuard(WorkflowGuard guard) {
    if (guard.isEmpty) return null;
    final m = <String, dynamic>{};
    if (guard.allowedRoleIds != null && guard.allowedRoleIds!.isNotEmpty) {
      m['allowedRoleIds'] = guard.allowedRoleIds;
    }
    if (guard.actorInList != null) {
      m['actorInList'] = {
        'key': guard.actorInList!.key,
        'present': guard.actorInList!.present,
      };
    }
    if (guard.actorEqualsField != null) {
      m['actorEqualsField'] = {'key': guard.actorEqualsField!.key};
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
    if (guard.cancellationDeadline != null) {
      m['cancellationDeadline'] = {
        'dateField': guard.cancellationDeadline!.dateField,
        if (guard.cancellationDeadline!.timeField != null)
          'timeField': guard.cancellationDeadline!.timeField,
        'hoursBefore': guard.cancellationDeadline!.hoursBefore,
      };
    }
    if (guard.locationOverlap != null) {
      m['locationOverlap'] = {
        'locationField': guard.locationOverlap!.locationField,
        'dateField': guard.locationOverlap!.dateField,
        if (guard.locationOverlap!.timeField != null)
          'timeField': guard.locationOverlap!.timeField,
        'durationMinutes': guard.locationOverlap!.durationMinutes,
      };
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
    if (effect.relatedQuery != null)
      'relatedQuery': {
        'workflowType': effect.relatedQuery!.workflowType,
        'filter': effect.relatedQuery!.filter,
        if (effect.relatedQuery!.sortKey != null)
          'sortKey': effect.relatedQuery!.sortKey,
        if (effect.relatedQuery!.limit != null)
          'limit': effect.relatedQuery!.limit,
      },
    if (effect.transitionId != null) 'transitionId': effect.transitionId,
    if (effect.onSuccessEffects != null)
      'onSuccessEffects': effect.onSuccessEffects!
          .map(_serializeEffect)
          .toList(),
    if (effect.condition != null) 'if': effect.condition,
    if (effect.thenEffects.isNotEmpty)
      'then': effect.thenEffects.map(_serializeEffect).toList(),
    if (effect.elseEffects.isNotEmpty)
      'else': effect.elseEffects.map(_serializeEffect).toList(),
  };
}

enum _IdentityFieldShape { scalar, list, scalarOrList }

enum _ArchetypeBookkeepingOperation { addActor, removeActor }

/// A grant predicate that refuses every transition.
///
/// A named constant rather than an inline closure so the several fail-closed
/// paths above cannot drift apart.
bool _denyAllTransitions(LoomWorkflowTransition transition) => false;
