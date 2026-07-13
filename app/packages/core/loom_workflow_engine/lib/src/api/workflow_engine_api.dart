import '../models/workflow_models.dart';

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
  final String createdByPersonaId;

  const WorkflowInstance({
    required this.instanceId,
    required this.workflowType,
    required this.currentState,
    required this.instanceData,
    required this.createdByPersonaId,
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
  /// READ a collection of instances visible on a given tab for a given persona.
  Future<InstancePage> queryInstances({
    required String tabId,
    required String personaId,
    SurfaceQuery query = const SurfaceQuery.empty(),
    int limit = 25,
    String? cursor,
  });

  /// READ the transitions available on ONE instance for one persona.
  List<LoomWorkflowTransition> availableTransitions({
    required String workflowType,
    required String instanceId,
    required String currentState,
    required Map<String, dynamic> instanceData,
    required String personaId,
  });

  /// MUTATE one instance via a state-changing transition.
  Future<WorkflowTransitionResult> applyTransition({
    required String workflowType,
    required String instanceId,
    required String transitionId,
    required String personaId,
  });

  /// CREATE a new workflow instance.
  Future<String> createInstance({
    required String workflowType,
    required Map<String, dynamic> initialInstanceData,
    required String personaId,
  });

  /// EDIT fields on an existing instance without transitioning state.
  Future<void> updateInstanceFields({
    required String workflowType,
    required String instanceId,
    required Map<String, dynamic> fieldUpdates,
    required String personaId,
  });

  /// Reads a scalar or grouped aggregate from persisted workflow instances.
  /// With [groupBy], returns rows containing [groupBy] and [op].
  Future<dynamic> aggregate({
    required String workflowType,
    required String column,
    required String op,
    Map<String, dynamic>? filter,
    String? groupBy,
  });
}
