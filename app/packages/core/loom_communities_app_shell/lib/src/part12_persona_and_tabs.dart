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
    experience: experience,
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
  required LoomExperienceDefinition experience,
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
        rendererContractId:
            override.rendererContractId ?? generated.rendererContractId,
        pinningPolicy: generated.pinningPolicy,
        pinningPolicyRationale: generated.pinningPolicyRationale,
        sectionTitles: generated.sectionTitles,
        cardSurfaceFamilies: generated.cardSurfaceFamilies,
        pinnedWorkflowIds: generated.pinnedWorkflowIds,
        visiblePersonaIds: generated.visiblePersonaIds,
      );
    } else {
      mergedById[override.tabId] = override.toTabSpec(
        derivedRendererContractId: _rendererContractIdForDeclarativeTab(
          experience: experience,
          tab: override,
        ),
      );
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

String _rendererContractIdForDeclarativeTab({
  required LoomExperienceDefinition experience,
  required LoomDeclarativeTabSpec tab,
}) {
  final declaredRendererContractId = tab.rendererContractId;
  if (declaredRendererContractId != null) {
    return declaredRendererContractId;
  }

  // A contract that names the tab owns it even when its family vocabulary is
  // stale or the tab has no bindings yet. Prefer the narrowest declaration so
  // a single-tab contract wins over a broader multi-tab contract.
  final tabContracts = <MapEntry<String, LoomTabRendererContract>>[
    for (final entry in _tabRendererContractsById.entries)
      if (entry.value.tabIds.contains(tab.tabId)) entry,
  ];
  if (tabContracts.isNotEmpty) {
    final mostSpecificTabIdCount = tabContracts
        .map((entry) => entry.value.tabIds.length)
        .reduce((left, right) => left < right ? left : right);
    final mostSpecificTabContracts = tabContracts
        .where((entry) => entry.value.tabIds.length == mostSpecificTabIdCount)
        .toList(growable: false);
    if (mostSpecificTabContracts.length == 1) {
      return mostSpecificTabContracts.single.key;
    }
    // An equal-specificity collision is not safe to resolve by registry order.
    return defaultAppShellTabRendererContractId;
  }

  // Family coverage is only a fallback for tabs no contract names.
  final boundSurfaceFamilies = <String>{
    for (final definition
        in experience.workflowDefinitions?.values ??
            const <LoomWorkflowStateMachine>[])
      for (final binding in definition.renderBindings)
        if (binding.tabId == tab.tabId) binding.cardSurfaceFamily,
  };
  if (boundSurfaceFamilies.isEmpty) {
    return defaultAppShellTabRendererContractId;
  }

  final matchingContracts = <MapEntry<String, LoomTabRendererContract>>[
    for (final entry in _tabRendererContractsById.entries)
      if (entry.value.surfaceFamilies.isNotEmpty &&
          boundSurfaceFamilies.every(entry.value.supportsSurfaceFamily))
        entry,
  ];
  if (matchingContracts.length == 1) {
    return matchingContracts.single.key;
  }

  return defaultAppShellTabRendererContractId;
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
  final rendererContractId = _readShellString(value, const [
    'rendererContractId',
    'renderer',
    'rendererId',
  ]);
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

/// Derives whether a role can act in a workflow-backed surface.
///
/// A role is admitted when it appears in a transition's `allowedRoleIds` or
/// in a render binding's `kind: create` action `byRoleIds`. An unguarded or
/// runtime-only guarded transition also admits the role: per-instance guards
/// cannot be resolved before rows are loaded, so the engine's instance
/// filtering must produce the empty state. The derivation scans every
/// transition and create action on every workflow bound to the requested tab,
/// including response workflows reached through `responseTable`.
bool personaHasPermission(
  LoomExperienceDefinition experience,
  String personaId, {
  String? tabId,
  String? workflowType,
  String? personaTypeId,
}) {
  if (tabId == 'home' || tabId == 'messages') {
    return true;
  }
  final subjectPersonaId = personaTypeId ?? personaId;
  final definitions = _surfaceWorkflowDefinitions(
    experience,
    tabId: tabId,
    workflowType: workflowType,
  );
  if (definitions.isEmpty) {
    // A declarative tab does not have to be workflow-backed. With no bound
    // workflow there is no workflow role guard to narrow its visibility, so
    // preserve the historical public-read behavior for these surfaces.
    return true;
  }

  var hasRoleGuard = false;
  for (final definition in definitions) {
    for (final transition in definition.transitions) {
      final allowedRoleIds = transition.guard.allowedPersonaIds;
      if (allowedRoleIds == null || allowedRoleIds.isEmpty) {
        return true;
      }
      hasRoleGuard = true;
      if (_personaMatchesAllowedIds(
        allowedRoleIds,
        experience,
        subjectPersonaId,
      )) {
        return true;
      }
    }

    for (final binding in definition.renderBindings) {
      for (final action in binding.actions) {
        if (action.kind != 'create') continue;
        final byRoleIds = action.byPersonaIds;
        if (byRoleIds == null || byRoleIds.isEmpty) continue;
        hasRoleGuard = true;
        if (_personaMatchesAllowedIds(
          byRoleIds,
          experience,
          subjectPersonaId,
        )) {
          return true;
        }
      }
    }
  }

  return !hasRoleGuard;
}

List<LoomWorkflowStateMachine> _surfaceWorkflowDefinitions(
  LoomExperienceDefinition experience, {
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
    final responseWorkflowTypes = <String>{
      for (final definition in definitions)
        for (final binding in definition.renderBindings)
          if (binding.tabId == tabId && binding.responseTable != null)
            binding.responseTable!.workflowType,
    };
    return [
      for (final definition in definitions)
        if (definition.renderBindings.any(
              (binding) => binding.tabId == tabId,
            ) ||
            responseWorkflowTypes.contains(definition.workflowType))
          definition,
    ];
  }
  return definitions;
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
