import 'dart:async';

import '../models/workflow_models.dart';

/// Resolves whether an individual account has active membership in this
/// engine's community.
///
/// The workflow engine deliberately does not depend on the app-shell auth
/// implementation. Callers that use `membersOnly` visibility can inject the
/// lookup from their account store instead.
typedef ActiveMembershipLookup = FutureOr<bool> Function(String fanId);

/// Resolves whether a caller may reach a workflow-backed surface.
///
/// The app shell owns the permission taxonomy and supplies this callback to
/// the domain-agnostic engine. Keeping the callback here avoids a dependency
/// from the workflow engine back onto app-shell models while still allowing
/// query and mutation entrypoints to enforce the same policy as the UI.
typedef WorkflowSurfacePermissionLookup =
    FutureOr<bool> Function({
      required String fanId,
      String? roleId,
      String? tabId,
      String? workflowType,
    });

/// The result of an `applyTransition` call.
class WorkflowTransitionResult {
  final String newState;
  final Map<String, dynamic> newInstanceData;

  const WorkflowTransitionResult({
    required this.newState,
    required this.newInstanceData,
  });
}

/// A page of workflow instances from `queryInstances`.
class InstancePage {
  final List<WorkflowInstance> items;
  final String? nextCursor;
  final bool hasMore;

  const InstancePage({
    required this.items,
    this.nextCursor,
    this.hasMore = false,
  });
}

/// A single workflow instance row.
class WorkflowInstance {
  final String instanceId;
  final String workflowType;
  final String currentState;
  final Map<String, dynamic> instanceData;
  final String createdByFanId;

  const WorkflowInstance({
    required this.instanceId,
    required this.workflowType,
    required this.currentState,
    required this.instanceData,
    required this.createdByFanId,
  });
}

/// Sort direction for `queryInstances`.
enum SortDirection { asc, desc }

/// A sort specification for `queryInstances`.
class SortSpec {
  final String key;
  final SortDirection direction;

  const SortSpec({required this.key, this.direction = SortDirection.asc});
}

/// Surface query parameters consumed by `queryInstances`.
class SurfaceQuery {
  final String? searchText;
  final Map<String, String>? filters;
  final SortSpec? sort;
  final String? dateWindowStart;
  final String? dateWindowEnd;
  final String? audienceMemberField;
  final String audienceScopeField;

  const SurfaceQuery({
    this.searchText,
    this.filters,
    this.sort,
    this.dateWindowStart,
    this.dateWindowEnd,
    this.audienceMemberField,
    this.audienceScopeField = 'audienceScope',
  });

  const SurfaceQuery.empty() : this();
}

/// Abstract API for the workflow engine — every implementation (local SQLite
/// or remote Firestore) must satisfy this interface. Card-surface UI code only
/// ever talks to this abstraction.
abstract class WorkflowEngineApi {
  /// READ a collection of instances visible on a given tab for a given fan.
  Future<InstancePage> queryInstances({
    required String tabId,
    required String fanId,
    SurfaceQuery query = const SurfaceQuery.empty(),
    int limit = 25,
    String? cursor,
  });

  /// READ the transitions available on ONE instance for one fan.
  List<LoomWorkflowTransition> availableTransitions({
    required String workflowType,
    required String instanceId,
    required String currentState,
    required Map<String, dynamic> instanceData,
    required String fanId,
  });

  /// Async transition resolution, including cross-instance guard checks.
  Future<List<LoomWorkflowTransition>> availableTransitionsAsync({
    required String workflowType,
    required String instanceId,
    required String currentState,
    required Map<String, dynamic> instanceData,
    required String fanId,
  });

  /// MUTATE one instance via a state-changing transition.
  ///
  /// [inputs] carries caller-supplied values for transition inputs declared
  /// in the transition's `inputs` schema (GAP-1).  Missing required inputs
  /// are refused with a [StateError].
  Future<WorkflowTransitionResult> applyTransition({
    required String workflowType,
    required String instanceId,
    required String transitionId,
    required String fanId,
    Map<String, dynamic>? inputs,
  });

  /// CREATE a new workflow instance.
  Future<String> createInstance({
    required String workflowType,
    required Map<String, dynamic> initialInstanceData,
    required String fanId,
  });

  /// Atomically CREATE many new workflow instances in one operation.
  Future<List<String>> createInstances({
    required String workflowType,
    required List<Map<String, dynamic>> initialInstanceDataList,
    required String fanId,
  });

  /// EDIT fields on an existing instance without transitioning state.
  Future<void> updateInstanceFields({
    required String workflowType,
    required String instanceId,
    required Map<String, dynamic> fieldUpdates,
    required String fanId,
  });

  /// Reads a scalar or grouped aggregate from persisted workflow instances.
  /// With [groupBy], returns rows containing [groupBy] and [op].
  /// When [fanId] is supplied, workflow visibility and read guards are
  /// applied before aggregation. Omitting it preserves the unscoped
  /// system-truth read used by internal guard math.
  Future<dynamic> aggregate({
    required String workflowType,
    required String column,
    required String op,
    Map<String, dynamic>? filter,
    String? groupBy,
    String? fanId,
  });

  Future<List<WorkflowInstance>> dueNotifications({required DateTime asOf});
}
