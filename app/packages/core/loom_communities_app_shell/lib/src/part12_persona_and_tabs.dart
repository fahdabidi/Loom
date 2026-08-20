part of '../loom_communities_app_shell.dart';

List<LoomPersonaDefinition> personasForExtensionId(
  String extensionId, {
  LoomExperienceDefinition? experience,
}) {
  final packagePersonas = experience?.personas;
  if (packagePersonas != null && packagePersonas.isNotEmpty) {
    return packagePersonas;
  }
  return _personasByExtensionId[extensionId] ?? _fallbackPersonas;
}

LoomWorkflowPersonaPolicy personaPolicyForWorkflow(
  String extensionId,
  String workflowId, {
  LoomExperienceDefinition? experience,
}) {
  final packagePolicy = experience?.personaPolicies?[workflowId];
  if (packagePolicy != null) {
    return packagePolicy;
  }
  switch (extensionId) {
    case 'ext_garden_club':
      return _gardenPolicy(workflowId);
    case 'ext_book_club':
      return _bookPolicy(workflowId);
    case 'ext_youth_soccer':
      return _soccerPolicy(workflowId);
    case 'ext_hoa':
      return _hoaPolicy(workflowId);
    case 'ext_mosque':
      return _mosquePolicy(workflowId);
    case 'ext_chess_club':
      return _chessPolicy(workflowId);
    case 'ext_camera_club':
      return _cameraPolicy(workflowId);
    case 'ext_platform_social':
      return _platformPolicy(workflowId);
    case 'ext_ad_off':
      return _adOffPolicy(workflowId);
    case 'ext_export_migration':
      return _exportPolicy(workflowId);
  }
  return const LoomWorkflowPersonaPolicy(
    actorPersonaIds: ['local-owner'],
    receiverPersonaIds: ['local-member'],
    receiverEntryText: 'A local community update is available.',
    receiverActionText: 'Receive',
    receiverResultText: 'Local community update received.',
  );
}

LoomPersonaWorkflowState personaWorkflowStateFor({
  required String extensionId,
  required String workflowId,
  required String personaId,
  LoomExperienceDefinition? experience,
}) {
  final policy = personaPolicyForWorkflow(
    extensionId,
    workflowId,
    experience: experience,
  );
  if (policy.actorPersonaIds.contains(personaId)) {
    return LoomPersonaWorkflowState.actor;
  }
  if (policy.receiverPersonaIds.contains(personaId)) {
    return LoomPersonaWorkflowState.receiver;
  }
  if (policy.readOnlyPersonaIds.contains(personaId)) {
    return LoomPersonaWorkflowState.readOnly;
  }
  return LoomPersonaWorkflowState.disabled;
}

LoomPersonaWorkflowView personaWorkflowViewFor({
  required String extensionId,
  required LoomWorkflowDefinition workflow,
  required String personaId,
  required Set<String> completedWorkflowIds,
  required Set<String> receivedWorkflowPersonaKeys,
  LoomExperienceDefinition? experience,
}) {
  final policy = personaPolicyForWorkflow(
    extensionId,
    workflow.workflowId,
    experience: experience,
  );
  final state = personaWorkflowStateFor(
    extensionId: extensionId,
    workflowId: workflow.workflowId,
    personaId: personaId,
    experience: experience,
  );
  final workflowCompleted = completedWorkflowIds.contains(workflow.workflowId);
  final completed =
      workflowCompleted && state == LoomPersonaWorkflowState.actor;
  final received = receivedWorkflowPersonaKeys.contains(
    workflowPersonaReceiptKey(
      workflowId: workflow.workflowId,
      personaId: personaId,
    ),
  );
  final actorWaiting =
      state == LoomPersonaWorkflowState.actor &&
      policy.prerequisiteWorkflowId != null &&
      !completedWorkflowIds.contains(policy.prerequisiteWorkflowId);
  final receiverPrerequisite =
      policy.prerequisiteWorkflowId ?? workflow.workflowId;
  final receiverWaiting =
      state == LoomPersonaWorkflowState.receiver &&
      !completedWorkflowIds.contains(receiverPrerequisite);
  final waitingForPrerequisite =
      !completed && !received && (actorWaiting || receiverWaiting);
  final entryText = _entryTextForState(
    state: state,
    workflow: workflow,
    policy: policy,
    waiting: waitingForPrerequisite,
  );
  return LoomPersonaWorkflowView(
    state: state,
    completed: completed,
    received: received,
    waitingForPrerequisite: waitingForPrerequisite,
    entryText: entryText,
    actionText: _actionTextForState(state, policy, workflow),
    resultText: _resultTextForState(workflow, policy, state),
    personaRationale: _rationaleForState(state, policy),
    waitingText: 'Waiting',
  );
}

List<LoomPersonaWorkflowMatrixRow> personaWorkflowMatrixForExtensionId(
  String extensionId,
) {
  final experience = experienceForExtensionId(extensionId);
  final personas = personasForExtensionId(extensionId);
  return [
    for (final workflow in experience.workflows)
      for (final persona in personas)
        LoomPersonaWorkflowMatrixRow(
          extensionId: extensionId,
          workflowId: workflow.workflowId,
          personaId: persona.personaId,
          state: personaWorkflowStateFor(
            extensionId: extensionId,
            workflowId: workflow.workflowId,
            personaId: persona.personaId,
          ),
          rationale: _rationaleForState(
            personaWorkflowStateFor(
              extensionId: extensionId,
              workflowId: workflow.workflowId,
              personaId: persona.personaId,
            ),
            personaPolicyForWorkflow(extensionId, workflow.workflowId),
          ),
          prerequisiteWorkflowId: personaPolicyForWorkflow(
            extensionId,
            workflow.workflowId,
          ).prerequisiteWorkflowId,
        ),
  ];
}

List<LoomWorkflowDependency> workflowDependenciesForExtensionId(
  String extensionId,
) {
  final experience = experienceForExtensionId(extensionId);
  return [
    for (final workflow in experience.workflows)
      for (final receiverPersonaId in personaPolicyForWorkflow(
        extensionId,
        workflow.workflowId,
      ).receiverPersonaIds)
        LoomWorkflowDependency(
          extensionId: extensionId,
          workflowId: workflow.workflowId,
          actorPersonaId: personaPolicyForWorkflow(
            extensionId,
            workflow.workflowId,
          ).actorPersonaIds.first,
          receiverPersonaId: receiverPersonaId,
          prerequisiteWorkflowId:
              personaPolicyForWorkflow(
                extensionId,
                workflow.workflowId,
              ).prerequisiteWorkflowId ??
              workflow.workflowId,
        ),
  ];
}

List<LoomAppShellTabSpec> appShellTabsFor({
  required LoomExperienceDefinition experience,
  required String personaId,
  Map<String, Object?> appShellConfiguration = const {},
  bool? hasActiveMembership,
}) {
  final generatedTabs = _generatedAppShellTabsFor();
  final tabs = _mergeDeclarativeTabSpecs(
    personaId: personaId,
    generatedTabs: generatedTabs,
    appShellConfiguration: appShellConfiguration,
  );
  return [
    for (final tab in tabs)
      if (tab.isVisibleFor(
        personaId,
        experience: experience,
        hasActiveMembership: hasActiveMembership,
        personaTypeId: personaId,
      ))
        tab,
  ];
}

/// Resolves the permission declared by the tab a workflow engine call is
/// trying to reach. This is intentionally read-only metadata resolution; it
/// does not apply the persona visibility filter used by [appShellTabsFor].
String? requiredPermissionForTab({
  required LoomExperienceDefinition experience,
  required String tabId,
  String personaId = '',
  Map<String, Object?> appShellConfiguration = const {},
}) {
  final configured = _declarativeTabSpecsFor(
    personaId: personaId,
    appShellConfiguration: appShellConfiguration,
  );
  for (final spec in configured.reversed) {
    if (spec.tabId == tabId) return spec.requiredPermission;
  }

  final generated = _generatedAppShellTabsFor();
  for (final tab in generated) {
    if (tab.tabId == tabId) return tab.requiredPermission;
  }

  // Keep permissions for internal engine surfaces discoverable even when the
  // surface is not represented by a visible app-shell tab.
  return switch (tabId) {
    'home' => 'community.surface.navigation.read',
    'calendar' => 'community.surface.calendar.read',
    'documents' => 'community.surface.documents.read',
    'marketplace' => 'community.surface.marketplace.read',
    'giving' => 'community.surface.payments.read',
    'requests' => 'community.surface.requests.read',
    'care' || 'roster' => 'community.surface.care.read',
    'admin' => 'community.surface.navigation.configure',
    // Engine-native notification surfaces use this internal tab ID even when
    // they are mounted as AppBar/FAB/fixed-card chrome rather than a tab. The
    // notification controller still applies recipientFanId filtering;
    // this only makes the synthetic inbox surface resolve to the existing
    // messages permission at the engine boundary.
    'notifications' ||
    'notification-inbox' ||
    'messages' => 'community.surface.messages.read',
    'export' || 'search' => 'community.surface.documents.read',
    'timeline' || 'details' || 'form' => 'community.surface.workflow.read',
    _ => null,
  };
}

List<LoomAppShellTabSpec> _generatedAppShellTabsFor() {
  return const [
    const LoomAppShellTabSpec(
      tabId: 'home',
      label: 'Home',
      icon: Icons.home_outlined,
      description: 'Pinned and unassigned community surfaces.',
      rendererContractId: 'home-surface-stack',
      pinningPolicy: 'none-declared-for-home',
      pinningPolicyRationale:
          'Home intentionally keeps the first visible surface in focus instead of pinning one workflow across every community.',
      requiredPermission: 'community.surface.navigation.read',
    ),
    const LoomAppShellTabSpec(
      tabId: 'messages',
      label: 'Messages',
      icon: Icons.forum_outlined,
      description: 'Messages and connections with other members.',
      rendererContractId: 'messages-inbox-thread-composer',
      pinningPolicy: 'none-declared-for-messages',
      pinningPolicyRationale:
          'Messages uses a conversation surface rather than a pinned workflow card, so no pinned card surface is appropriate.',
      requiredPermission: 'community.surface.messages.read',
    ),
  ];
}

bool _hasEngineNativeCalendarBinding(LoomExperienceDefinition experience) =>
    experience.workflowDefinitions?.values.any(
      (definition) => definition.renderBindings.any(
        (binding) => binding.tabId == 'calendar',
      ),
    ) ??
    false;

bool _hasEngineNativeBinding(
  LoomExperienceDefinition experience,
  String tabId,
) =>
    experience.workflowDefinitions?.values.any(
      (definition) =>
          definition.renderBindings.any((binding) => binding.tabId == tabId),
    ) ??
    false;

List<LoomAppShellTabSpec> _mergeDeclarativeTabSpecs({
  required String personaId,
  required List<LoomAppShellTabSpec> generatedTabs,
  required Map<String, Object?> appShellConfiguration,
}) {
  final overrides = _declarativeTabSpecsFor(
    personaId: personaId,
    appShellConfiguration: appShellConfiguration,
  );
  final mergedById = <String, LoomAppShellTabSpec>{
    for (final tab in generatedTabs) tab.tabId: tab,
  };
  for (final override in overrides) {
    if ((override.tabId == 'home' || override.tabId == 'messages') &&
        mergedById[override.tabId] != null) {
      final generated = mergedById[override.tabId]!;
      mergedById[override.tabId] = LoomAppShellTabSpec(
        tabId: generated.tabId,
        label: override.label,
        icon: _tabIconForKey(override.iconKey),
        description: override.description,
        rendererContractId: generated.rendererContractId,
        pinningPolicy: generated.pinningPolicy,
        pinningPolicyRationale: generated.pinningPolicyRationale,
        sectionTitles: generated.sectionTitles,
        cardSurfaceFamilies: generated.cardSurfaceFamilies,
        pinnedWorkflowIds: generated.pinnedWorkflowIds,
        visiblePersonaIds: generated.visiblePersonaIds,
        requiredPermission: generated.requiredPermission,
      );
    } else {
      mergedById[override.tabId] = override.toTabSpec();
    }
  }
  // A LinkedHashSet, not a list: `mergedById` is keyed by tabId and so already
  // collapses duplicates, but this ordering pass emits one entry per
  // *occurrence*, so any tabId appearing twice in `overrides` renders the same
  // tab twice. That happens for real -- `overrides` concatenates the
  // configuration's `tabs` and this role's `roleTabs`, and installing a
  // package over an already-preloaded shell contributes both. Set semantics
  // keep first-occurrence order while making the id unique by construction.
  final orderedIds = <String>{
    'home',
    ...overrides
        .map((override) => override.tabId)
        .where((tabId) => tabId != 'home' && tabId != 'messages'),
    for (final tab in generatedTabs)
      if (!overrides.any((override) => override.tabId == tab.tabId) &&
          tab.tabId != 'home' &&
          tab.tabId != 'messages')
        tab.tabId,
    'messages',
  };
  return [
    for (final tabId in orderedIds)
      if (mergedById[tabId] != null) mergedById[tabId]!,
  ];
}

List<LoomDeclarativeTabSpec> _declarativeTabSpecsFor({
  required String personaId,
  Map<String, Object?> appShellConfiguration = const {},
}) {
  final packageGlobal = _declarativeTabSpecsFromConfiguration(
    appShellConfiguration['tabs'],
  );
  final packagePersona = _declarativeTabSpecsFromPersonaConfiguration(
    appShellConfiguration['roleTabs'],
    personaId: personaId,
  );
  return [...packageGlobal, ...packagePersona];
}

List<LoomDeclarativeTabSpec> _declarativeTabSpecsFromPersonaConfiguration(
  Object? value, {
  required String personaId,
}) {
  if (value is! Map<String, Object?>) {
    return const [];
  }
  return _declarativeTabSpecsFromConfiguration(value[personaId]);
}

List<LoomDeclarativeTabSpec> _declarativeTabSpecsFromConfiguration(
  Object? value,
) {
  if (value is! List<Object?>) {
    return const [];
  }
  return [
    for (final item in value)
      if (_declarativeTabSpecFromMap(item) case final spec?) spec,
  ];
}

LoomDeclarativeTabSpec? _declarativeTabSpecFromMap(Object? value) {
  if (value is! Map<String, Object?>) {
    return null;
  }
  final tabId = _readShellString(value, const ['tabId', 'id']);
  final label = _readShellString(value, const ['label', 'title']);
  final iconKey = _readShellString(value, const ['iconKey', 'icon']) ?? 'home';
  final rendererContractId =
      _readShellString(value, const [
        'rendererContractId',
        'renderer',
        'rendererId',
      ]) ??
      'engine-native-generic-list';
  if (tabId == null || label == null) {
    return null;
  }
  return LoomDeclarativeTabSpec(
    tabId: tabId,
    label: label,
    iconKey: iconKey,
    description:
        _readShellString(value, const ['description', 'subtitle']) ??
        '$label surfaces for this community.',
    rendererContractId: rendererContractId,
    pinningPolicy: _readShellString(value, const ['pinningPolicy']) ?? 'none',
    pinningPolicyRationale:
        _readShellString(value, const ['pinningPolicyRationale']) ??
        'This package declares the tab pinning policy explicitly.',
    sectionTitles: _readShellStringList(value, const [
      'sectionTitles',
      'sections',
    ]),
    cardSurfaceFamilies: _readShellStringList(value, const [
      'cardSurfaceFamilies',
      'surfaceFamilies',
      'cardSurfaces',
    ]),
    pinnedWorkflowIds: _readShellStringList(value, const [
      'pinnedWorkflowIds',
      'pinnedSurfaces',
      'pinnedWorkflowIds',
    ]),
    visiblePersonaIds: _readShellStringList(value, const ['visibleRoleIds']),
    requiredPermission:
        _readShellString(value, const ['requiredPermission', 'permission']) ??
        'community.surface.navigation.read',
  );
}

String? _readShellString(Map<String, Object?> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

List<String> _readShellStringList(Map<String, Object?> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is List<Object?>) {
      return value
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
  }
  return const [];
}

IconData _tabIconForKey(String iconKey) {
  switch (iconKey) {
    case 'home':
      return Icons.home_outlined;
    case 'calendar':
      return Icons.calendar_month_outlined;
    case 'documents':
      return Icons.folder_open_outlined;
    case 'marketplace':
      return Icons.storefront_outlined;
    case 'gear':
      return Icons.photo_camera_back_outlined;
    case 'messages':
      return Icons.forum_outlined;
    case 'notifications':
      return Icons.notifications_outlined;
    case 'groups':
      return Icons.groups_outlined;
    case 'giving':
    case 'payment':
      return Icons.payments_outlined;
    case 'care':
      return Icons.volunteer_activism_outlined;
    case 'admin':
      return Icons.admin_panel_settings_outlined;
    case 'board':
      return Icons.fact_check_outlined;
  }
  return Icons.apps_outlined;
}

bool _personaCanAdministerAnyWorkflow(
  LoomExperienceDefinition experience,
  String personaId,
) {
  final engineDefinitions = experience.workflowDefinitions;
  if (engineDefinitions != null && engineDefinitions.isNotEmpty) {
    final engineAdminDefinitions = engineDefinitions.values.where(
      (definition) =>
          definition.renderBindings.any((binding) => binding.tabId == 'admin'),
    );
    if (engineAdminDefinitions.isNotEmpty) {
      // Engine-native experiences intentionally do not populate the legacy
      // `experience.workflows` list. Use only the transitions reachable from
      // the states declared by an Admin binding: a member may be allowed to
      // submit a proposal, but that does not make them an administrator who
      // can decide the pending queue.
      return engineAdminDefinitions.any((definition) {
        final adminStates = definition.renderBindings
            .where((binding) => binding.tabId == 'admin')
            .expand((binding) => binding.states)
            .toSet();
        return definition.transitions.any(
          (transition) =>
              transition.from.any((state) => adminStates.contains(state)) &&
              (transition.guard.allowedPersonaIds?.contains(personaId) ??
                  false),
        );
      });
    }
  }
  return experience.workflows.any((workflow) {
    final state = personaWorkflowStateFor(
      extensionId: experience.extensionId,
      workflowId: workflow.workflowId,
      personaId: personaId,
      experience: experience,
    );
    if (state == LoomPersonaWorkflowState.receiver &&
        workflow.architecturalRequest != null) {
      return true;
    }
    if (state != LoomPersonaWorkflowState.actor) {
      return false;
    }
    final entry = cardSurfaceRegistryEntryFor(
      extensionId: experience.extensionId,
      workflow: workflow,
    );
    return entry.cardSurfaceFamily == 'announcement' ||
        entry.cardSurfaceFamily == 'approval' ||
        entry.cardSurfaceFamily == 'ad' ||
        entry.cardSurfaceFamily == 'workflow-status' ||
        _sectionTitleFor(workflow) == 'Requests and approvals';
  });
}

/// Resolves the permission carried by a tab spec against the workflow
/// definitions that can actually render on that surface.
///
/// The synchronous form is used during tab construction. Membership lookups
/// are asynchronous in the engine, so callers that have the live lookup
/// should use [personaHasPermissionAsync] at an engine boundary. A supplied
/// [hasActiveMembership] snapshot keeps the synchronous tab path deterministic
/// and fails closed for `membersOnly` when no active account is known.
bool personaHasPermission(
  LoomExperienceDefinition experience,
  String personaId,
  String requiredPermission, {
  String? tabId,
  String? workflowType,
  String? personaTypeId,
  bool? hasActiveMembership,
}) {
  final permission = requiredPermission.trim();
  if (permission.isEmpty) return false;
  final subjectPersonaId = personaTypeId ?? personaId;
  final definitions = _permissionWorkflowDefinitions(
    experience,
    permission,
    tabId: tabId,
    workflowType: workflowType,
  );
  final isReadPermission = permission.endsWith('.read');

  if (isReadPermission) {
    // Legacy workflow definitions have no workflow-level visibility block and
    // therefore retain their historical public-read behavior.
    if (definitions.isEmpty) return true;
    return definitions.any(
      (definition) => _readPermissionCouldAdmitPersona(
        definition,
        experience,
        subjectPersonaId,
        hasActiveMembership: hasActiveMembership,
      ),
    );
  }

  // Keep the existing JSON-derived admin check as the first write-side path;
  // the generalized guard scan below extends it to ordinary workflow writes,
  // edits, and creation guards without duplicating its legacy behavior.
  if (permission.endsWith('.configure') &&
      _personaCanAdministerAnyWorkflow(experience, subjectPersonaId)) {
    return true;
  }
  if (definitions.isEmpty) {
    return _personaCanAdministerAnyWorkflow(experience, subjectPersonaId);
  }
  return definitions.any(
    (definition) =>
        _writePermissionAllowsPersona(definition, experience, subjectPersonaId),
  );
}

/// Async companion for the engine boundary. It deliberately shares the same
/// definition/guard logic as [personaHasPermission] while resolving the
/// injected P4a membership lookup only for `membersOnly` workflows.
Future<bool> personaHasPermissionAsync(
  LoomExperienceDefinition experience,
  String personaId,
  String requiredPermission, {
  ActiveMembershipLookup? activeMembershipLookup,
  String? tabId,
  String? workflowType,
  String? personaTypeId,
  bool? hasActiveMembership,
}) async {
  final permission = requiredPermission.trim();
  if (permission.isEmpty) return false;
  if (!permission.endsWith('.read')) {
    return personaHasPermission(
      experience,
      personaId,
      permission,
      tabId: tabId,
      workflowType: workflowType,
      personaTypeId: personaTypeId,
      hasActiveMembership: hasActiveMembership,
    );
  }

  final definitions = _permissionWorkflowDefinitions(
    experience,
    permission,
    tabId: tabId,
    workflowType: workflowType,
  );
  if (definitions.isEmpty) return true;
  final subjectPersonaId = personaTypeId ?? personaId;
  bool? membership;
  for (final definition in definitions) {
    switch (definition.visibility.defaultValue) {
      case WorkflowVisibilityDefault.public:
        return true;
      case WorkflowVisibilityDefault.membersOnly:
        membership ??= hasActiveMembership;
        membership ??= activeMembershipLookup == null
            ? false
            : await activeMembershipLookup(personaId);
        if (membership == true) return true;
      case WorkflowVisibilityDefault.guarded:
        if (_readPermissionCouldAdmitPersona(
          definition,
          experience,
          subjectPersonaId,
          hasActiveMembership: membership,
        )) {
          return true;
        }
    }
  }
  return false;
}

List<LoomWorkflowStateMachine> _permissionWorkflowDefinitions(
  LoomExperienceDefinition experience,
  String permission, {
  String? tabId,
  String? workflowType,
}) {
  final definitions =
      experience.workflowDefinitions?.values.toList() ??
      const <LoomWorkflowStateMachine>[];
  if (definitions.isEmpty) return const [];
  if (workflowType != null) {
    return [
      for (final definition in definitions)
        if (definition.workflowType == workflowType) definition,
    ];
  }
  if (tabId != null) {
    return [
      for (final definition in definitions)
        if (definition.renderBindings.any((binding) => binding.tabId == tabId))
          definition,
    ];
  }

  final domain = _permissionDomain(permission);
  final aliases = _permissionTabAliases(domain);
  final matching = [
    for (final definition in definitions)
      if (definition.renderBindings.any(
        (binding) => aliases.contains(binding.tabId),
      ))
        definition,
  ];
  if (matching.isNotEmpty) return matching;
  if (definitions.length == 1) return definitions;
  return const [];
}

String _permissionDomain(String permission) {
  final parts = permission.split('.');
  return parts.length >= 4 ? parts[2] : '';
}

Set<String> _permissionTabAliases(String domain) {
  return switch (domain) {
    'navigation' => const {'home', 'admin'},
    'calendar' => const {'calendar', 'schedule'},
    'documents' => const {'documents', 'export', 'search'},
    'marketplace' => const {'marketplace', 'library'},
    'payments' || 'payment' => const {'giving', 'payments'},
    'requests' || 'approval' => const {'requests', 'request', 'admin'},
    'care' || 'volunteer' => const {'care', 'roster'},
    'messages' ||
    'social' ||
    'thread' ||
    'inbox' => const {'messages', 'notifications', 'notification-inbox'},
    'workflow' || 'workflow-status' => const {
      'home',
      'requests',
      'timeline',
      'details',
      'form',
    },
    _ => {domain},
  };
}

bool _readPermissionCouldAdmitPersona(
  LoomWorkflowStateMachine definition,
  LoomExperienceDefinition experience,
  String personaId, {
  bool? hasActiveMembership,
}) {
  switch (definition.visibility.defaultValue) {
    case WorkflowVisibilityDefault.public:
      return true;
    case WorkflowVisibilityDefault.membersOnly:
      return hasActiveMembership == true;
    case WorkflowVisibilityDefault.guarded:
      final fields = definition.visibility.fields;
      if (fields.sharedWith != null ||
          fields.participants.isNotEmpty ||
          fields.recipient != null ||
          fields.parties.any(
            (principal) => switch (principal) {
              WorkflowVisibilityFieldPrincipal() => true,
              WorkflowVisibilityRolePrincipal(:final roleId) =>
                roleId == personaId,
            },
          )) {
        // Field principals are instance-scoped: this coarse surface check
        // must admit a persona who could own a matching row. The engine's
        // per-instance visibility check still enforces the concrete identity
        // before returning data.
        return true;
      }
      final guards = <WorkflowGuard>[];
      for (final state in definition.states.values) {
        final guard = state.readGuard ?? definition.visibility.readGuard;
        if (guard != null) guards.add(guard);
      }
      if (guards.isEmpty) return false;
      return guards.any(
        (guard) => _readGuardCouldAdmitPersona(guard, experience, personaId),
      );
  }
}

bool _readGuardCouldAdmitPersona(
  WorkflowGuard guard,
  LoomExperienceDefinition experience,
  String personaId,
) {
  final allowed = guard.allowedPersonaIds;
  if (allowed != null &&
      allowed.isNotEmpty &&
      !_personaMatchesAllowedIds(allowed, experience, personaId)) {
    return false;
  }
  // Other guard shapes describe instance data that could be authored for this
  // persona. Without live instances, their existence is possible rather than
  // disproven; this mirrors availableTransitions' guard-admissibility model.
  return true;
}

bool _writePermissionAllowsPersona(
  LoomWorkflowStateMachine definition,
  LoomExperienceDefinition experience,
  String personaId,
) {
  bool guardAllows(WorkflowGuard? guard) {
    final allowed = guard?.allowedPersonaIds;
    return allowed != null &&
        allowed.isNotEmpty &&
        _personaMatchesAllowedIds(allowed, experience, personaId);
  }

  if (definition.transitions.any(
    (transition) => guardAllows(transition.guard),
  )) {
    return true;
  }
  return definition.states.values.any(
    (state) => guardAllows(state.editGuard) || guardAllows(state.creationGuard),
  );
}

bool _personaMatchesAllowedIds(
  Iterable<String> allowedPersonaIds,
  LoomExperienceDefinition experience,
  String personaId,
) {
  if (allowedPersonaIds.contains(personaId)) return true;
  final persona = experience.personas?.where(
    (candidate) => candidate.accountId == personaId,
  );
  return persona?.any(
        (candidate) => allowedPersonaIds.contains(candidate.personaId),
      ) ??
      false;
}

String workflowPersonaReceiptKey({
  required String workflowId,
  required String personaId,
}) {
  return '$workflowId::$personaId';
}

List<LoomWorkflowCardSurfaceRegistryEntry> cardSurfaceRegistryForExtensionId(
  String extensionId,
) {
  final experience = experienceForExtensionId(extensionId);
  return [
    for (final workflow in experience.workflows)
      cardSurfaceRegistryEntryFor(extensionId: extensionId, workflow: workflow),
  ];
}

LoomWorkflowCardSurfaceRegistryEntry cardSurfaceRegistryEntryFor({
  required String extensionId,
  required LoomWorkflowDefinition workflow,
}) {
  final base = _cardSurfaceRegistryEntryForWorkflowId(workflow.workflowId);
  return LoomWorkflowCardSurfaceRegistryEntry(
    workflowId: workflow.workflowId,
    cardSurfaceFamily: base.cardSurfaceFamily,
    apiContract: base.apiContract,
    requiredInteractions: base.requiredInteractions,
    primaryActions: base.primaryActions,
    alternateActions: base.alternateActions,
    rendererTarget: _rendererTargetForWorkflow(
      extensionId: extensionId,
      workflowId: workflow.workflowId,
    ),
    fakeBackendSupport: base.fakeBackendSupport,
    routeTemplate: _routeTemplateForSurfaceFamily(base.cardSurfaceFamily),
  );
}

LoomProductionWorkflowContract productionWorkflowContractFor({
  required String extensionId,
  required LoomWorkflowDefinition workflow,
}) {
  final category = _workflowCategoryFor(workflow);
  final objectLabel = _objectLabelFor(workflow);
  final cardSurface = cardSurfaceRegistryEntryFor(
    extensionId: extensionId,
    workflow: workflow,
  );
  return LoomProductionWorkflowContract(
    workflowId: workflow.workflowId,
    cardSurfaceFamily: cardSurface.cardSurfaceFamily,
    apiContract: cardSurface.apiContract,
    requiredInteractions: cardSurface.requiredInteractions,
    primaryActions: <String>{
      _primaryActionLabelFor(workflow),
      ...cardSurface.primaryActions,
    }.toList(),
    alternateActions: <String>{
      _alternateActionLabelFor(workflow),
      ...cardSurface.alternateActions,
    }.toList(),
    rendererTarget: cardSurface.rendererTarget,
    fakeBackendSupport: cardSurface.fakeBackendSupport,
    category: category,
    surfaceLabel: _surfaceLabelFor(category),
    objectLabel: objectLabel,
    screenTitle: _screenTitleFor(category, workflow),
    primaryActionLabel: _primaryActionLabelFor(workflow),
    alternateActionLabel: _alternateActionLabelFor(workflow),
    decisionSummary: _decisionSummaryFor(category, workflow),
    inputSummary: _inputSummaryFor(category, workflow),
    validationSummary: _validationSummaryFor(category),
    resultSummary: _successBodyFor(category, workflow),
    receiverStateSummary: _receiverStateSummaryFor(category, workflow),
    successTitle: _successTitleFor(category, workflow),
    successChipLabel: _successChipLabelFor(category),
    receiverSurfaceTitle: _receiverTitleFor(category, objectLabel),
    trustSummary: _trustSummaryFor(category),
    icon: _iconFor(category),
  );
}
