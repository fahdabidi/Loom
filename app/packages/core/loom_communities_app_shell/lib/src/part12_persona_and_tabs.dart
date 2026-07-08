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
}) {
  final generatedTabs = <LoomAppShellTabSpec>[
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
    if (_hasAnySection(experience, const ['Upcoming events']))
      LoomAppShellTabSpec(
        tabId: 'calendar',
        label: 'Calendar',
        icon: Icons.calendar_month_outlined,
        description: 'Events, schedules, capacity, and reminders.',
        rendererContractId: 'calendar-agenda-event-detail',
        pinningPolicy: 'pin-first-critical-surface',
        pinningPolicyRationale:
            'Calendar tabs pin the next dated event so members can act on the most time-sensitive schedule item first.',
        sectionTitles: const ['Upcoming events'],
        cardSurfaceFamilies: const ['event-rsvp', 'calendar'],
        pinnedWorkflowIds: _pinnedWorkflowIdsForSections(experience, const [
          'Upcoming events',
        ]),
        requiredPermission: 'community.surface.calendar.read',
      ),
    if (_hasAnySection(experience, const ['Documents and data']))
      LoomAppShellTabSpec(
        tabId: 'documents',
        label: 'Documents',
        icon: Icons.folder_open_outlined,
        description: 'Documents, exports, transfers, and audit records.',
        rendererContractId: 'documents-library-detail',
        pinningPolicy: 'pin-first-critical-surface',
        pinningPolicyRationale:
            'Document tabs pin the most important document or status surface so owners see the current record before browsing history.',
        sectionTitles: const ['Documents and data'],
        cardSurfaceFamilies: const [
          'documents',
          'external-document-link',
          'operations',
          'portability',
          'workflow-status',
        ],
        pinnedWorkflowIds: _pinnedWorkflowIdsForSections(experience, const [
          'Documents and data',
        ]),
        requiredPermission: 'community.surface.documents.read',
      ),
    if (_hasAnySurfaceFamily(experience, const ['exchange', 'equipment-loan']))
      LoomAppShellTabSpec(
        tabId: 'marketplace',
        label: 'Marketplace',
        icon: Icons.storefront_outlined,
        description: 'Shared items, offers, claims, loans, and giveaways.',
        rendererContractId: 'marketplace-browse-listing-detail',
        pinningPolicy: 'pin-first-critical-surface',
        pinningPolicyRationale:
            'Marketplace tabs pin the most immediately actionable listing so members can browse, claim, or update availability quickly.',
        sectionTitles: const ['Care and volunteers', 'Member tools'],
        cardSurfaceFamilies: const ['exchange', 'equipment-loan'],
        pinnedWorkflowIds: _pinnedWorkflowIdsForSurfaceFamilies(
          experience,
          const ['exchange', 'equipment-loan'],
        ),
        requiredPermission: 'community.surface.marketplace.read',
      ),
    if (_hasAnySection(experience, const ['Giving']))
      LoomAppShellTabSpec(
        tabId: 'giving',
        label: _paymentTabLabelFor(experience),
        icon: Icons.payments_outlined,
        description: 'Payments, dues, donations, receipts, and ad-off state.',
        rendererContractId: 'payment-giving-ledger',
        pinningPolicy: 'pin-first-critical-surface',
        pinningPolicyRationale:
            'Giving tabs pin the current payment or receipt state because members need the amount, status, and next action first.',
        sectionTitles: const ['Giving'],
        cardSurfaceFamilies: const ['payment', 'ad-off-entitlement'],
        pinnedWorkflowIds: _pinnedWorkflowIdsForSections(experience, const [
          'Giving',
        ]),
        requiredPermission: 'community.surface.payments.read',
      ),
    if (experience.workflows.any((workflow) => workflow.architecturalRequest != null))
      LoomAppShellTabSpec(
        tabId: 'requests',
        label: 'Requests',
        icon: Icons.fact_check_outlined,
        description: 'Submit and track architectural requests.',
        rendererContractId: 'workflow-status-timeline-actions',
        pinningPolicy: 'pin-first-critical-surface',
        pinningPolicyRationale:
            'Request tabs pin the active case so homeowners can see status and next actions.',
        sectionTitles: const ['Requests and approvals'],
        cardSurfaceFamilies: const ['formEntry', 'statusTimeline', 'workflow-status'],
        pinnedWorkflowIds: _pinnedWorkflowIdsForSurfaceFamilies(
          experience,
          const ['formEntry', 'statusTimeline', 'workflow-status', 'approval'],
        ),
        requiredPermission: 'community.surface.requests.read',
      ),
    if (_hasAnySurfaceFamily(experience, const ['volunteer', 'care-request']))
      LoomAppShellTabSpec(
        tabId: 'care',
        label: 'Care',
        icon: Icons.volunteer_activism_outlined,
        description: 'Care requests, volunteer shifts, and member support.',
        rendererContractId: 'care-volunteer-request-queue',
        pinningPolicy: 'pin-first-critical-surface',
        pinningPolicyRationale:
            'Care tabs pin the most urgent request or volunteer shift so the support workflow remains immediately visible.',
        sectionTitles: const ['Care and volunteers'],
        cardSurfaceFamilies: const ['volunteer', 'care-request'],
        pinnedWorkflowIds: _pinnedWorkflowIdsForSurfaceFamilies(
          experience,
          const ['volunteer', 'care-request'],
        ),
        requiredPermission: 'community.surface.care.read',
      ),
    if (_personaCanAdministerAnyWorkflow(experience, personaId))
      LoomAppShellTabSpec(
        tabId: 'admin',
        label: _adminTabLabelFor(experience.extensionId),
        icon: Icons.admin_panel_settings_outlined,
        description: 'Role-specific publishing, approvals, and operations.',
        rendererContractId: 'admin-review-compose-queue',
        pinningPolicy: 'pin-first-critical-surface',
        pinningPolicyRationale:
            'Admin tabs pin the first pending approval or publishing task so administrators see the queue item that needs action.',
        sectionTitles: const [
          'Announcements',
          'Requests and approvals',
          'Sponsored placement',
        ],
        cardSurfaceFamilies: const [
          'announcement',
          'approval',
          'ad',
          'workflow-status',
        ],
        pinnedWorkflowIds: _pinnedWorkflowIdsForSurfaceFamilies(
          experience,
          const ['announcement', 'approval', 'ad', 'workflow-status'],
        ),
        visiblePersonaIds: [personaId],
        requiredPermission: 'community.surface.navigation.configure',
      ),
    const LoomAppShellTabSpec(
      tabId: 'messages',
      label: 'Messages',
      icon: Icons.forum_outlined,
      description: 'Shell-owned communication and connections.',
      rendererContractId: 'messages-inbox-thread-composer',
      pinningPolicy: 'none-declared-for-messages',
      pinningPolicyRationale:
          'Messages uses a conversation surface rather than a pinned workflow card, so no pinned card surface is appropriate.',
      requiredPermission: 'community.surface.messages.read',
    ),
  ];
  return [
    for (final tab in _mergeDeclarativeTabSpecs(
      experience: experience,
      personaId: personaId,
      generatedTabs: generatedTabs,
      appShellConfiguration: appShellConfiguration,
    ))
      if (tab.isVisibleFor(personaId)) tab,
  ];
}

List<LoomAppShellTabSpec> _mergeDeclarativeTabSpecs({
  required LoomExperienceDefinition experience,
  required String personaId,
  required List<LoomAppShellTabSpec> generatedTabs,
  required Map<String, Object?> appShellConfiguration,
}) {
  final overrides = _declarativeTabSpecsFor(
    extensionId: experience.extensionId,
    personaId: personaId,
    appShellConfiguration: appShellConfiguration,
  );
  if (overrides.isEmpty) {
    return generatedTabs;
  }
  final mergedById = <String, LoomAppShellTabSpec>{
    for (final tab in generatedTabs) tab.tabId: tab,
  };
  for (final override in overrides) {
    mergedById[override.tabId] = override.toTabSpec();
  }
  final orderedIds = <String>[
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
  ];
  return [
    for (final tabId in orderedIds)
      if (mergedById[tabId] != null) mergedById[tabId]!,
  ];
}

List<LoomDeclarativeTabSpec> _declarativeTabSpecsFor({
  required String extensionId,
  required String personaId,
  Map<String, Object?> appShellConfiguration = const {},
}) {
  final packageGlobal = _declarativeTabSpecsFromConfiguration(
    appShellConfiguration['tabs'],
  );
  final packagePersona = _declarativeTabSpecsFromPersonaConfiguration(
    appShellConfiguration['personaTabs'],
    personaId: personaId,
  );
  final global = _declarativeTabSpecsByExtensionId[extensionId] ?? const [];
  final persona =
      _declarativeTabSpecsByExtensionAndPersona['$extensionId::$personaId'] ??
      const [];
  return [...global, ...persona, ...packageGlobal, ...packagePersona];
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
  if (tabId == null || label == null || rendererContractId == null) {
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
    visiblePersonaIds: _readShellStringList(value, const [
      'visiblePersonaIds',
      'personas',
    ]),
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
    case 'giving':
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

const _declarativeTabSpecsByExtensionId = <String, List<LoomDeclarativeTabSpec>>{
  'ext_camera_club': [
    LoomDeclarativeTabSpec(
      tabId: 'calendar',
      label: 'Walks',
      iconKey: 'calendar',
      description: 'Photo walks, critique deadlines, reminders, and RSVPs.',
      rendererContractId: 'calendar-agenda-event-detail',
      pinningPolicy: 'pin-next-photo-walk',
      pinningPolicyRationale:
          'Camera Club pins the next walk because members need the route, time, capacity, and gear reminder first.',
      sectionTitles: ['Upcoming events'],
      cardSurfaceFamilies: ['event-rsvp', 'calendar'],
      pinnedWorkflowIds: ['photo-walk-rsvp'],
      requiredPermission: 'community.surface.calendar.read',
    ),
    LoomDeclarativeTabSpec(
      tabId: 'marketplace',
      label: 'Gear',
      iconKey: 'gear',
      description: 'Browse, request, loan, queue for, and return shared gear.',
      rendererContractId: 'marketplace-browse-listing-detail',
      pinningPolicy: 'pin-featured-available-listing',
      pinningPolicyRationale:
          'Gear tabs pin the featured available item so members can see availability and current-holder state immediately.',
      cardSurfaceFamilies: ['equipment-loan'],
      pinnedWorkflowIds: ['gear-loan-request'],
      requiredPermission: 'community.surface.marketplace.read',
    ),
    LoomDeclarativeTabSpec(
      tabId: 'messages',
      label: 'Club chat',
      iconKey: 'messages',
      description:
          'Threads, critique follow-up, walk coordination, and invites.',
      rendererContractId: 'messages-inbox-thread-composer',
      pinningPolicy: 'none-declared-for-messages',
      pinningPolicyRationale:
          'Club chat uses inbox and thread surfaces, so no pinned workflow card is appropriate.',
      requiredPermission: 'community.surface.messages.read',
    ),
  ],
  'ext_garden_club': [
    LoomDeclarativeTabSpec(
      tabId: 'marketplace',
      label: 'Exchange',
      iconKey: 'marketplace',
      description:
          'Browse offers, plant claims, pickup windows, and handoff state.',
      rendererContractId: 'marketplace-browse-listing-detail',
      pinningPolicy: 'pin-featured-available-listing',
      pinningPolicyRationale:
          'Garden exchange pins the most actionable offer so members can see variety, pickup, claim, and privacy state first.',
      cardSurfaceFamilies: ['exchange', 'equipment-loan'],
      pinnedWorkflowIds: ['plant-exchange-submission'],
      requiredPermission: 'community.surface.marketplace.read',
    ),
  ],
  'ext_hoa': [
    LoomDeclarativeTabSpec(
      tabId: 'admin',
      label: 'Board',
      iconKey: 'board',
      description:
          'Architectural decisions, dues, documents, and owner follow-up.',
      rendererContractId: 'admin-review-compose-queue',
      pinningPolicy: 'pin-first-critical-surface',
      pinningPolicyRationale:
          'Board tabs pin the first review or payment item that needs a decision.',
      sectionTitles: ['Requests and approvals', 'Giving', 'Documents and data'],
      cardSurfaceFamilies: [
        'approval',
        'payment',
        'operations',
        'workflow-status',
      ],
      visiblePersonaIds: ['hoa-board'],
      requiredPermission: 'community.surface.navigation.configure',
    ),
  ],
};

const _declarativeTabSpecsByExtensionAndPersona =
    <String, List<LoomDeclarativeTabSpec>>{};

bool _hasAnySection(
  LoomExperienceDefinition experience,
  List<String> sectionTitles,
) {
  return experience.workflows.any(
    (workflow) => sectionTitles.contains(_sectionTitleFor(workflow)),
  );
}

bool _hasAnySurfaceFamily(
  LoomExperienceDefinition experience,
  List<String> surfaceFamilies,
) {
  return experience.workflows.any((workflow) {
    final entry = cardSurfaceRegistryEntryFor(
      extensionId: experience.extensionId,
      workflow: workflow,
    );
    return surfaceFamilies.contains(entry.cardSurfaceFamily);
  });
}

bool _personaCanAdministerAnyWorkflow(
  LoomExperienceDefinition experience,
  String personaId,
) {
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

String _adminTabLabelFor(String extensionId) {
  switch (extensionId) {
    case 'ext_youth_soccer':
      return 'Coach';
    case 'ext_hoa':
      return 'Board';
    case 'ext_mosque':
      return 'Admin';
    case 'ext_garden_club':
      return 'Organize';
    case 'ext_book_club':
      return 'Host';
  }
  return 'Admin';
}

String _paymentTabLabelFor(LoomExperienceDefinition experience) {
  if (experience.workflows.any(
    (workflow) => workflow.workflowId == 'hoa-dues-payment',
  )) {
    return 'Payments';
  }
  return 'Giving';
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

List<String> _pinnedWorkflowIdsForSections(
  LoomExperienceDefinition experience,
  List<String> sectionTitles,
) {
  return [
    for (final workflow in experience.workflows)
      if (sectionTitles.contains(_sectionTitleFor(workflow)))
        workflow.workflowId,
  ].take(1).toList(growable: false);
}

List<String> _pinnedWorkflowIdsForSurfaceFamilies(
  LoomExperienceDefinition experience,
  List<String> surfaceFamilies,
) {
  return [
    for (final workflow in experience.workflows)
      if (surfaceFamilies.contains(
        cardSurfaceRegistryEntryFor(
          extensionId: experience.extensionId,
          workflow: workflow,
        ).cardSurfaceFamily,
      ))
        workflow.workflowId,
  ].take(1).toList(growable: false);
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
