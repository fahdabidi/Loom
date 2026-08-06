part of loom_communities_app_shell;

/// Shared data access for the real `notification` workflow type.
///
/// The notification workflow scopes unread state through its FSM state, not
/// through a boolean in [WorkflowInstance.instanceData]. Query results also
/// need client-side recipient filtering because [SurfaceQuery] does not
/// express equality against arbitrary instance-data fields.
class NotificationInboxController {
  static const workflowType = 'notification';

  final WorkflowEngineApi engine;
  final String personaId;

  const NotificationInboxController({
    required this.engine,
    required this.personaId,
  });

  /// Counts this persona's unread notification instances by their real FSM
  /// state, using the engine's reserved `$state` aggregate field.
  Future<int> unreadCount() async {
    final count = await engine.aggregate(
      workflowType: workflowType,
      column: 'recipientPersonaId',
      op: 'count',
      filter: {'recipientPersonaId': personaId, r'$state': 'unread'},
      personaId: personaId,
    );
    return (count as num).toInt();
  }

  /// Creates the live query source consumed by [RepeaterSurface.live].
  ///
  /// The source deliberately uses the existing query contract. Callers that
  /// render the source directly through [RepeaterSurface] should apply
  /// [filterMine] to the fetched page; [queryPage] provides that scoped page
  /// operation for data-layer consumers that do not own the repeater.
  RepeaterQuerySource live({
    String tabId = 'notification-inbox',
    SurfaceQuery query = const SurfaceQuery.empty(),
  }) => RepeaterQuerySource(
    engine: engine,
    workflowType: workflowType,
    personaId: personaId,
    query: query,
    tabId: tabId,
  );

  /// Fetches one page and removes notifications addressed to another persona.
  ///
  /// [queryInstances] does not apply arbitrary instance-data filters, so this
  /// post-filter is part of the controller's list-scoping contract.
  Future<InstancePage> queryPage({
    String tabId = 'notification-inbox',
    SurfaceQuery query = const SurfaceQuery.empty(),
    int limit = 1000,
    String? cursor,
  }) async {
    final page = await engine.queryInstances(
      tabId: tabId,
      personaId: personaId,
      query: query,
      limit: limit,
      cursor: cursor,
    );
    return InstancePage(
      items: filterMine(page.items),
      nextCursor: page.nextCursor,
      hasMore: page.hasMore,
    );
  }

  /// Filters a RepeaterSurface-fetched page (or any raw instance list) down
  /// to this persona's own notification instances.
  List<WorkflowInstance> filterMine(List<WorkflowInstance> items) => items
      .where(
        (item) =>
            item.workflowType == workflowType &&
            item.instanceData['recipientPersonaId'] == personaId,
      )
      .toList(growable: false);

  /// Marks [notification] read through the workflow's guarded transition.
  ///
  /// The engine enforces the `actorEqualsField` guard, so callers cannot use
  /// this method to mark another persona's notification read.
  Future<void> markRead(WorkflowInstance notification) async {
    await engine.applyTransition(
      workflowType: workflowType,
      instanceId: notification.instanceId,
      transitionId: 'mark-read',
      personaId: personaId,
    );
  }
}
