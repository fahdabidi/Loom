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
  final isEngineNativeExperience =
      experience.workflowDefinitions?.isNotEmpty ?? false;
  final packageDeclarativeSpecs = [
    ..._declarativeTabSpecsFromConfiguration(appShellConfiguration['tabs']),
    ..._declarativeTabSpecsFromPersonaConfiguration(
      appShellConfiguration['personaTabs'],
      personaId: personaId,
    ),
  ];
  final usesComputedPermissionFallback =
      experience.workflowDefinitions != null ||
      packageDeclarativeSpecs.isNotEmpty;
  final generatedTabs = _generatedAppShellTabsFor(
    experience: experience,
    personaId: personaId,
  );
  final tabs = _mergeDeclarativeTabSpecs(
    experience: experience,
    personaId: personaId,
    generatedTabs: isEngineNativeExperience
        ? _engineNativeTabsFrom(generatedTabs)
        : generatedTabs,
    appShellConfiguration: appShellConfiguration,
    isEngineNativeExperience: isEngineNativeExperience,
  );
  return [
    for (final tab in tabs)
      if (tab.isVisibleFor(
        personaId,
        experience: experience,
        enforceRequiredPermission: usesComputedPermissionFallback,
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
    extensionId: experience.extensionId,
    personaId: personaId,
    appShellConfiguration: appShellConfiguration,
  );
  for (final spec in configured.reversed) {
    if (spec.tabId == tabId) return spec.requiredPermission;
  }

  final generated = _generatedAppShellTabsFor(
    experience: experience,
    personaId: personaId,
  );
  for (final tab in generated) {
    if (tab.tabId == tabId) return tab.requiredPermission;
  }

  // The generated admin tab is persona-gated before it reaches the raw tab
  // list. Keep its permission discoverable for the engine boundary even when
  // the caller is precisely the persona that should be denied it.
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
    // notification controller still applies recipientPersonaId filtering;
    // this only makes the synthetic inbox surface resolve to the existing
    // messages permission at the engine boundary.
    'notifications' || 'notification-inbox' || 'messages' =>
      'community.surface.messages.read',
    'export' || 'search' => 'community.surface.documents.read',
    'timeline' || 'details' || 'form' => 'community.surface.workflow.read',
    _ => null,
  };
}

List<LoomAppShellTabSpec> _generatedAppShellTabsFor({
  required LoomExperienceDefinition experience,
  required String personaId,
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
    if (_hasAnySection(experience, const ['Upcoming events']) ||
        _hasEngineNativeCalendarBinding(experience))
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
    if (_hasAnySection(experience, const ['Giving']) ||
        _hasEngineNativeBinding(experience, 'giving'))
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
    if (experience.workflows.any(
      (workflow) => workflow.architecturalRequest != null,
    ))
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
        cardSurfaceFamilies: const [
          'formEntry',
          'statusTimeline',
          'workflow-status',
        ],
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
    if (experience.notifications?.isNotEmpty ?? false)
      const LoomAppShellTabSpec(
        tabId: 'notifications',
        label: 'Notifications',
        icon: Icons.notifications_outlined,
        description: 'Updates, reminders, and member notices.',
        rendererContractId: 'notification-inbox',
        pinningPolicy: 'none-declared-for-notifications',
        pinningPolicyRationale:
            'Notifications are chronological inbox items rather than pinned workflow cards.',
        requiredPermission: 'community.surface.messages.read',
      ),
    if (experience.exportWizard != null)
      const LoomAppShellTabSpec(
        tabId: 'export',
        label: 'Export',
        icon: Icons.ios_share_outlined,
        description: 'Review, generate, and transfer a community export.',
        rendererContractId: 'export-wizard-stepper',
        pinningPolicy: 'none-declared-for-export',
        pinningPolicyRationale:
            'Exports are completed as a sequential wizard rather than a pinned card.',
        requiredPermission: 'community.surface.documents.read',
      ),
    if (experience.volunteerShifts?.isNotEmpty ?? false)
      const LoomAppShellTabSpec(
        tabId: 'roster',
        label: 'Roster',
        icon: Icons.volunteer_activism_outlined,
        description: 'Volunteer shifts and remaining capacity.',
        rendererContractId: 'volunteer-roster',
        pinningPolicy: 'none-declared-for-roster',
        pinningPolicyRationale:
            'Volunteer shifts are browsed together so members can compare available capacity.',
        requiredPermission: 'community.surface.care.read',
      ),
    if (experience.aiSearchAnswers?.isNotEmpty ?? false)
      const LoomAppShellTabSpec(
        tabId: 'search',
        label: 'Search',
        icon: Icons.search_outlined,
        description: 'Search the club knowledge base for cited answers.',
        rendererContractId: 'ai-search',
        pinningPolicy: 'none-declared-for-search',
        pinningPolicyRationale:
            'Search results are query-specific platform-service responses rather than pinned workflow cards.',
        requiredPermission: 'community.surface.documents.read',
      ),
    if (experience.audiencePicker != null)
      const LoomAppShellTabSpec(
        tabId: 'audience',
        label: 'Audience',
        icon: Icons.people_alt_outlined,
        description: 'Choose members for an event invitation.',
        rendererContractId: 'audience-picker',
        pinningPolicy: 'none-declared-for-audience-picker',
        pinningPolicyRationale:
            'Audience selection is a structured member-field editor rather than a pinned workflow card.',
        requiredPermission: 'community.surface.messages.read',
      ),
    if (experience.singleItemPreference != null)
      const LoomAppShellTabSpec(
        tabId: 'preferences',
        label: 'Preferences',
        icon: Icons.tune_outlined,
        description: 'Choose how often the club should send reminders.',
        rendererContractId: 'single-item-preference',
        pinningPolicy: 'none-declared-for-preferences',
        pinningPolicyRationale:
            'A member preference is edited in place as one mutually exclusive value.',
        requiredPermission: 'community.surface.messages.read',
      ),
    if (experience.statusTimeline != null)
      const LoomAppShellTabSpec(
        tabId: 'timeline',
        label: 'Timeline',
        icon: Icons.timeline_outlined,
        description: 'Follow the event status progression.',
        rendererContractId: 'status-timeline',
        pinningPolicy: 'none-declared-for-timeline',
        pinningPolicyRationale:
            'Timeline events are read in chronological visual order.',
        requiredPermission: 'community.surface.workflow.read',
      ),
    if (experience.protectedDetail != null)
      const LoomAppShellTabSpec(
        tabId: 'details',
        label: 'Details',
        icon: Icons.lock_outline,
        description: 'View protected event details.',
        rendererContractId: 'protected-detail',
        pinningPolicy: 'none-declared-for-protected-detail',
        pinningPolicyRationale: 'Protected details use viewer-aware masking.',
        requiredPermission: 'community.surface.workflow.read',
      ),
    if (experience.formEntry != null)
      const LoomAppShellTabSpec(
        tabId: 'form',
        label: 'Form',
        icon: Icons.edit_note_outlined,
        description: 'Set event notification preferences.',
        rendererContractId: 'form-entry-controls',
        pinningPolicy: 'none-declared-for-form',
        pinningPolicyRationale: 'Typed controls edit a real form instance.',
        requiredPermission: 'community.surface.workflow.read',
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
  return generatedTabs;
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
      (definition) => definition.renderBindings.any(
        (binding) => binding.tabId == tabId,
      ),
    ) ??
    false;

List<LoomAppShellTabSpec> _mergeDeclarativeTabSpecs({
  required LoomExperienceDefinition experience,
  required String personaId,
  required List<LoomAppShellTabSpec> generatedTabs,
  required Map<String, Object?> appShellConfiguration,
  required bool isEngineNativeExperience,
}) {
  final overrides = _declarativeTabSpecsFor(
    extensionId: experience.extensionId,
    personaId: personaId,
    appShellConfiguration: appShellConfiguration,
    isEngineNativeExperience: isEngineNativeExperience,
  );
  final mergedById = <String, LoomAppShellTabSpec>{
    for (final tab in generatedTabs) tab.tabId: tab,
  };
  for (final override in overrides) {
    if (_engineNativeSpecialTabIdsForCosmetics.contains(override.tabId) &&
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
        // The generated 'admin' entry's visiblePersonaIds is a
        // self-referential [personaId] (always trivially true once
        // included at all -- real gating already happened via
        // _personaCanAdministerAnyWorkflow above, in _generatedAppShellTabsFor).
        // A legacy declarative override that declares its OWN real,
        // persona-independent permission list (e.g. ext_hoa's admin tab:
        // visiblePersonaIds: ['hoa-board']) must keep governing final
        // visibility -- preferring the generated value here would let
        // "admin" leak to any persona the (legacy, quirky, unrelated to
        // this ticket) _personaCanAdministerAnyWorkflow heuristic happens
        // to also generate an entry for, discarding the override's real
        // permission list. Only fall back to generated's value when the
        // override didn't declare one at all (the common case once Ticket 4
        // adds cosmetic-only JSON declarations with no visiblePersonaIds).
        visiblePersonaIds: override.visiblePersonaIds.isNotEmpty
            ? override.visiblePersonaIds
            : generated.visiblePersonaIds,
        requiredPermission: generated.requiredPermission,
      );
    } else {
      mergedById[override.tabId] = override.toTabSpec();
    }
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

List<LoomAppShellTabSpec> _engineNativeTabsFrom(
  List<LoomAppShellTabSpec> specs,
) {
  return [
    for (final spec in specs)
      if (_isEngineNativeTabId(spec.tabId)) spec,
  ];
}

bool _isEngineNativeTabId(String tabId) =>
    _engineNativeTabIds.contains(tabId);

const _engineNativeTabIds = {
  'home',
  'calendar',
  'marketplace',
  'giving',
  'admin',
  'messages',
};
const _engineNativeSpecialTabIdsForCosmetics = {
  'calendar',
  'marketplace',
  'giving',
  'admin',
};

List<LoomDeclarativeTabSpec> _declarativeTabSpecsFor({
  required String extensionId,
  required String personaId,
  Map<String, Object?> appShellConfiguration = const {},
  bool isEngineNativeExperience = false,
}) {
  final packageGlobal = _declarativeTabSpecsFromConfiguration(
    appShellConfiguration['tabs'],
  );
  final packagePersona = _declarativeTabSpecsFromPersonaConfiguration(
    appShellConfiguration['personaTabs'],
    personaId: personaId,
  );
  // The static per-extension tables below are the legacy, hardcoded-by-
  // community declarations (CJM.7/CJM.8's own target) -- filtered to the
  // closed six-tabId set for engine-native experiences. This is NOT just an
  // obsolete-id filter: some real communities (e.g. Camera Club's calendar
  // tab, labeled "Walks") still get their special-4 (calendar/marketplace/
  // giving/admin) cosmetic override from this legacy table, since Ticket 4
  // (migrating those overrides into appShell.tabs[] JSON) hasn't landed
  // yet -- dropping the whole table for engine-native experiences would
  // silently regress those communities' tab labels/icons/descriptions back
  // to the generic hardcoded fallback. Filtering to the closed six keeps
  // obsolete custom ids (critique, books, matches, rankings, etc.) out
  // while preserving the special-4's legitimate overrides; once a real
  // appShell.tabs[]/personaTabs JSON declaration exists for the same tabId
  // (packageGlobal/packagePersona below), it's appended after this table in
  // the returned list, so later-wins merge order in
  // _mergeDeclarativeTabSpecs already gives JSON declarations precedence --
  // no special-casing needed here for that handoff.
  var global = _declarativeTabSpecsByExtensionId[extensionId] ?? const [];
  var persona =
      _declarativeTabSpecsByExtensionAndPersona['$extensionId::$personaId'] ??
      const [];
  if (isEngineNativeExperience) {
    global = global.where((spec) => _isEngineNativeTabId(spec.tabId)).toList();
    persona = persona
        .where((spec) => _isEngineNativeTabId(spec.tabId))
        .toList();
  }
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

const _declarativeTabSpecsByExtensionId = <String, List<LoomDeclarativeTabSpec>>{
  'ext_youth_soccer': [
    LoomDeclarativeTabSpec(
      tabId: 'registration',
      label: 'Registration',
      iconKey: 'documents',
      description:
          'Guardian guided registration wizard and reviewer timeline on the same engine instance.',
      rendererContractId: 'workflow-status-timeline-actions',
      pinningPolicy: 'pin-active-registration',
      pinningPolicyRationale:
          'Youth Soccer pins registration because waiver and payment gates block roster participation.',
      sectionTitles: ['Registration'],
      cardSurfaceFamilies: ['guidedProcess', 'statusTimeline'],
      pinnedWorkflowIds: ['soccer-guardian-join-approval'],
      requiredPermission: 'community.surface.workflow.read',
    ),
    LoomDeclarativeTabSpec(
      tabId: 'schedule',
      label: 'Schedule',
      iconKey: 'calendar',
      description:
          'Practice and game agenda with RSVP, reminder, field, opponent, and attendance state.',
      rendererContractId: 'calendar-agenda-event-detail',
      pinningPolicy: 'pin-next-practice',
      pinningPolicyRationale:
          'Schedule-first is the top Youth Soccer hierarchy.',
      sectionTitles: ['Schedule'],
      cardSurfaceFamilies: ['calendarAgenda'],
      pinnedWorkflowIds: ['soccer-practice-schedule'],
      requiredPermission: 'community.surface.calendar.read',
    ),
    LoomDeclarativeTabSpec(
      tabId: 'payments',
      label: 'Payments',
      iconKey: 'payment',
      description:
          'Guardian registration checkout with receipt, failed payment recovery, refund, and subscription management.',
      rendererContractId: 'payment-giving-ledger',
      pinningPolicy: 'pin-registration-fee',
      pinningPolicyRationale:
          'Guardians need the amount, receipt, and next payment action before roster confirmation.',
      sectionTitles: ['Payments'],
      cardSurfaceFamilies: ['paymentCheckout'],
      pinnedWorkflowIds: ['soccer-registration-payment'],
      visiblePersonaIds: ['guardian'],
      requiredPermission: 'community.surface.payments.read',
    ),
    LoomDeclarativeTabSpec(
      tabId: 'documents',
      label: 'Waivers',
      iconKey: 'documents',
      description:
          'Waiver library with embedded/external open, acknowledgement, access request, and audit trail.',
      rendererContractId: 'documents-library-detail',
      pinningPolicy: 'pin-current-waiver',
      pinningPolicyRationale: 'The current waiver is the primary document.',
      sectionTitles: ['Documents'],
      cardSurfaceFamilies: ['documentLibrary'],
      pinnedWorkflowIds: ['soccer-waiver-document'],
      visiblePersonaIds: ['guardian', 'coach'],
      requiredPermission: 'community.surface.documents.read',
    ),
    LoomDeclarativeTabSpec(
      tabId: 'coach',
      label: 'Coach',
      iconKey: 'admin',
      description:
          'Coach dashboard combining roster, schedule controls, and reminder inbox.',
      rendererContractId: 'admin-review-compose-queue',
      pinningPolicy: 'pin-roster-and-reminders',
      pinningPolicyRationale: 'Coach-only work belongs off the guardian tabs.',
      sectionTitles: ['Coach'],
      cardSurfaceFamilies: ['dashboard', 'notificationInbox'],
      pinnedWorkflowIds: ['soccer-reminder-notification'],
      visiblePersonaIds: ['coach'],
      requiredPermission: 'community.surface.navigation.configure',
    ),
    LoomDeclarativeTabSpec(
      tabId: 'messages',
      label: 'Messages',
      iconKey: 'messages',
      description:
          'Team discussion thread for guardian and coach coordination.',
      rendererContractId: 'messages-inbox-thread-composer',
      pinningPolicy: 'none-declared-for-messages',
      pinningPolicyRationale:
          'Messages uses threads rather than pinned workflow cards.',
      sectionTitles: ['Messages'],
      cardSurfaceFamilies: ['discussionThread'],
      pinnedWorkflowIds: ['soccer-team-discussion'],
      requiredPermission: 'community.surface.messages.read',
    ),
    LoomDeclarativeTabSpec(
      tabId: 'admin',
      label: 'Export',
      iconKey: 'admin',
      description:
          'Owner export wizard with minor redaction preview, checksum, transfer, rollback, and retry.',
      rendererContractId: 'admin-review-compose-queue',
      pinningPolicy: 'pin-redaction-preview',
      pinningPolicyRationale:
          'Owner export must foreground redaction before transfer.',
      sectionTitles: ['Admin'],
      cardSurfaceFamilies: ['exportWizard'],
      pinnedWorkflowIds: ['soccer-export-metadata'],
      visiblePersonaIds: ['owner'],
      requiredPermission: 'community.surface.navigation.configure',
    ),
  ],
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
      tabId: 'critique',
      label: 'Critique',
      iconKey: 'documents',
      description:
          'Submit photos, browse critique thumbnails, and keep feedback attached to the same submission.',
      rendererContractId: 'workflow-status-timeline-actions',
      pinningPolicy: 'pin-active-critique-submission',
      pinningPolicyRationale:
          'Critique pins the active photo submission so members see submission state and reviewer feedback together.',
      sectionTitles: ['Critique'],
      cardSurfaceFamilies: [
        'form-entry',
        'state-machine-grid',
        'discussion-thread',
      ],
      pinnedWorkflowIds: ['critique-submission'],
      requiredPermission: 'community.surface.workflow.read',
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
    LoomDeclarativeTabSpec(
      tabId: 'admin',
      label: 'Admin',
      iconKey: 'admin',
      description:
          'Organizer validation status for requested workflows and completion evidence.',
      rendererContractId: 'admin-review-compose-queue',
      pinningPolicy: 'pin-validation-report',
      pinningPolicyRationale:
          'Camera organizers need the validation report isolated from member-facing critique and gear surfaces.',
      sectionTitles: ['Admin'],
      cardSurfaceFamilies: ['workflow-status'],
      pinnedWorkflowIds: ['camera-validation-report'],
      visiblePersonaIds: ['camera-organizer'],
      requiredPermission: 'community.surface.navigation.configure',
    ),
  ],
  'ext_book_club': [
    LoomDeclarativeTabSpec(
      tabId: 'calendar',
      label: 'Calendar',
      iconKey: 'calendar',
      description:
          'Meeting dates, locations, recurrence, reminders, and RSVP state.',
      rendererContractId: 'calendar-agenda-event-detail',
      pinningPolicy: 'pin-next-meeting',
      pinningPolicyRationale:
          'Book Club pins the next meeting so members see time, location, and RSVP state before discussion.',
      sectionTitles: ['Calendar'],
      cardSurfaceFamilies: ['calendarAgenda'],
      pinnedWorkflowIds: ['book-meeting-rsvp'],
      requiredPermission: 'community.surface.calendar.read',
    ),
    LoomDeclarativeTabSpec(
      tabId: 'books',
      label: 'Books',
      iconKey: 'documents',
      description:
          'Nominate books, vote on the ballot, and publish the selection.',
      rendererContractId: 'workflow-status-timeline-actions',
      pinningPolicy: 'pin-open-ballot',
      pinningPolicyRationale:
          'Book Club pins nominations and the active ballot so members can act before the deadline.',
      sectionTitles: ['Books'],
      cardSurfaceFamilies: ['formEntry', 'votePoll', 'notificationInbox'],
      pinnedWorkflowIds: ['book-nomination', 'book-vote'],
      requiredPermission: 'community.surface.workflow.read',
    ),
    LoomDeclarativeTabSpec(
      tabId: 'library',
      label: 'Library',
      iconKey: 'marketplace',
      description:
          'Browse shared books, DVDs, audiobooks, games, loans, queues, and giveaways.',
      rendererContractId: 'marketplace-browse-listing-detail',
      pinningPolicy: 'pin-featured-shared-item',
      pinningPolicyRationale:
          'The shared library pins the most actionable available item and preserves custody state.',
      sectionTitles: ['Library'],
      cardSurfaceFamilies: ['stateMachineGrid'],
      pinnedWorkflowIds: ['book-library-item'],
      requiredPermission: 'community.surface.marketplace.read',
    ),
    LoomDeclarativeTabSpec(
      tabId: 'discussions',
      label: 'Discussions',
      iconKey: 'messages',
      description: 'Current-book discussion prompts, replies, and moderation.',
      rendererContractId: 'messages-inbox-thread-composer',
      pinningPolicy: 'pin-current-book-thread',
      pinningPolicyRationale:
          'Discussion follows the current selection and keeps replies tied to that book context.',
      sectionTitles: ['Discussions'],
      cardSurfaceFamilies: ['discussionThread'],
      pinnedWorkflowIds: ['book-discussion-message'],
      requiredPermission: 'community.surface.messages.read',
    ),
    LoomDeclarativeTabSpec(
      tabId: 'documents',
      label: 'Materials',
      iconKey: 'documents',
      description: 'Reading guides, author links, excerpts, and downloads.',
      rendererContractId: 'documents-library-detail',
      pinningPolicy: 'pin-current-reading-materials',
      pinningPolicyRationale:
          'Materials are tied to the current reading cycle and should open from their own tab.',
      sectionTitles: ['Documents'],
      cardSurfaceFamilies: ['documentLibrary'],
      pinnedWorkflowIds: ['book-reading-material'],
      requiredPermission: 'community.surface.documents.read',
    ),
    LoomDeclarativeTabSpec(
      tabId: 'search',
      label: 'Search',
      iconKey: 'search',
      description: 'Ask cited questions over discussion history and guides.',
      rendererContractId: 'workflow-status-timeline-actions',
      pinningPolicy: 'pin-cited-digest',
      pinningPolicyRationale:
          'Search pins the cited digest so members can inspect sources before sharing conclusions.',
      sectionTitles: ['Search'],
      cardSurfaceFamilies: ['searchAiAnswer'],
      pinnedWorkflowIds: ['book-search-ai-digest'],
      requiredPermission: 'community.surface.workflow.read',
    ),
    LoomDeclarativeTabSpec(
      tabId: 'admin',
      label: 'Host',
      iconKey: 'admin',
      description: 'Publish selections and export book-club records.',
      rendererContractId: 'admin-review-compose-queue',
      pinningPolicy: 'pin-publish-and-export',
      pinningPolicyRationale:
          'Organizer-only actions belong on the Host tab, not member-facing Home or Books surfaces.',
      sectionTitles: ['Admin'],
      cardSurfaceFamilies: ['notificationInbox', 'exportWizard'],
      pinnedWorkflowIds: ['book-selection-publish', 'book-export-metadata'],
      visiblePersonaIds: ['book-organizer'],
      requiredPermission: 'community.surface.navigation.configure',
    ),
  ],
  'ext_mosque': [
    LoomDeclarativeTabSpec(
      tabId: 'calendar',
      label: 'Calendar',
      iconKey: 'calendar',
      description:
          'Admin event creation and member RSVP agenda share the same event workflow instance with audience-selected delivery.',
      rendererContractId: 'calendar-agenda-event-detail',
      pinningPolicy: 'pin-next-friday-service',
      pinningPolicyRationale:
          'The Friday service and selected-audience invitations are the time-sensitive Mosque surface.',
      sectionTitles: ['Calendar'],
      cardSurfaceFamilies: ['formEntry', 'calendarAgenda'],
      pinnedWorkflowIds: ['mosque-event-rsvp'],
      requiredPermission: 'community.surface.calendar.read',
    ),
    LoomDeclarativeTabSpec(
      tabId: 'giving',
      label: 'Giving',
      iconKey: 'giving',
      description:
          'Donation checkout, receipts, recurring controls, and durable donor visibility preference.',
      rendererContractId: 'payment-giving-ledger',
      pinningPolicy: 'pin-current-donation',
      pinningPolicyRationale:
          'Members need amount, receipt, and privacy state before donating.',
      sectionTitles: ['Giving'],
      cardSurfaceFamilies: ['paymentCheckout', 'singleItem'],
      pinnedWorkflowIds: ['mosque-donation-payment', 'mosque-donor-visibility'],
      requiredPermission: 'community.surface.payments.read',
    ),
    LoomDeclarativeTabSpec(
      tabId: 'care',
      label: 'Care',
      iconKey: 'care',
      description:
          'Member care request form, private field flags, own volunteer signup, and protected review status.',
      rendererContractId: 'workflow-status-timeline-actions',
      pinningPolicy: 'pin-active-care-request',
      pinningPolicyRationale:
          'Care and volunteer follow-up are member-owned status surfaces outside Admin.',
      sectionTitles: ['Care'],
      cardSurfaceFamilies: ['formEntry', 'protectedDetail', 'volunteerRoster'],
      pinnedWorkflowIds: ['mosque-care-request', 'mosque-volunteer-signup'],
      requiredPermission: 'community.surface.workflow.read',
    ),
    LoomDeclarativeTabSpec(
      tabId: 'admin',
      label: 'Admin',
      iconKey: 'admin',
      description:
          'Announcement composer, volunteer roster controls, donation status, and protected care review.',
      rendererContractId: 'admin-review-compose-queue',
      pinningPolicy: 'pin-composer-and-review-queue',
      pinningPolicyRationale:
          'Admin-only publish, volunteer coordination, and assigned care review must stay off member tabs.',
      sectionTitles: ['Admin'],
      cardSurfaceFamilies: [
        'formEntry',
        'notificationInbox',
        'volunteerRoster',
        'protectedDetail',
      ],
      pinnedWorkflowIds: [
        'mosque-announcement',
        'mosque-volunteer-signup',
        'mosque-care-request',
      ],
      visiblePersonaIds: ['mosque-admin'],
      requiredPermission: 'community.surface.navigation.configure',
    ),
    LoomDeclarativeTabSpec(
      tabId: 'search',
      label: 'Search',
      iconKey: 'search',
      description:
          'Permission-guarded cited answers over announcements and member-visible sources.',
      rendererContractId: 'workflow-status-timeline-actions',
      pinningPolicy: 'pin-current-answer',
      pinningPolicyRationale:
          'Search pins the current cited answer so users can inspect and report sources.',
      sectionTitles: ['Search'],
      cardSurfaceFamilies: ['searchAiAnswer'],
      pinnedWorkflowIds: ['mosque-search-ai-citation'],
      requiredPermission: 'community.surface.workflow.read',
    ),
    LoomDeclarativeTabSpec(
      tabId: 'messages',
      label: 'Messages',
      iconKey: 'messages',
      description:
          'Discussion threads plus privacy-safe care notifications and announcement inbox.',
      rendererContractId: 'messages-inbox-thread-composer',
      pinningPolicy: 'none-declared-for-messages',
      pinningPolicyRationale:
          'Messages uses inbox/thread surfaces rather than pinned workflow cards.',
      sectionTitles: ['Messages'],
      cardSurfaceFamilies: ['discussionThread', 'notificationInbox'],
      pinnedWorkflowIds: [
        'mosque-discussion-thread',
        'mosque-neutral-notification',
        'mosque-announcement',
      ],
      requiredPermission: 'community.surface.messages.read',
    ),
  ],
  'ext_chess_club': [
    LoomDeclarativeTabSpec(
      tabId: 'matches',
      label: 'Matches',
      iconKey: 'board',
      description:
          'Propose, negotiate, confirm, report, correct, and dispute ladder matches.',
      rendererContractId: 'workflow-status-timeline-actions',
      pinningPolicy: 'pin-active-match',
      pinningPolicyRationale:
          'Chess Club pins the active match because the proposal, timeline, and confirmed event are one engine instance.',
      sectionTitles: ['Matches'],
      cardSurfaceFamilies: ['formEntry', 'statusTimeline', 'calendarAgenda'],
      pinnedWorkflowIds: ['chess-match-meetup'],
      requiredPermission: 'community.surface.workflow.read',
    ),
    LoomDeclarativeTabSpec(
      tabId: 'calendar',
      label: 'Calendar',
      iconKey: 'calendar',
      description:
          'Confirmed ladder matches, club nights, tournaments, locations, and reminders.',
      rendererContractId: 'calendar-agenda-event-detail',
      pinningPolicy: 'pin-next-club-night',
      pinningPolicyRationale:
          'The next club night is the time-sensitive chess surface.',
      sectionTitles: ['Calendar'],
      cardSurfaceFamilies: ['calendarAgenda'],
      pinnedWorkflowIds: ['chess-club-night'],
      requiredPermission: 'community.surface.calendar.read',
    ),
    LoomDeclarativeTabSpec(
      tabId: 'rankings',
      label: 'Rankings',
      iconKey: 'board',
      description: 'Live ladder table with rankingMode emphasis.',
      rendererContractId: 'workflow-status-timeline-actions',
      pinningPolicy: 'pin-live-rankings',
      pinningPolicyRationale:
          'Rankings pins the table that is updated by match-result effects.',
      sectionTitles: ['Rankings'],
      cardSurfaceFamilies: ['table'],
      pinnedWorkflowIds: ['chess-rankings-table'],
      requiredPermission: 'community.surface.workflow.read',
    ),
    LoomDeclarativeTabSpec(
      tabId: 'documents',
      label: 'Rules',
      iconKey: 'documents',
      description:
          'Club rules, ladder policy, embedded open, external open, and download.',
      rendererContractId: 'documents-library-detail',
      pinningPolicy: 'pin-club-rules',
      pinningPolicyRationale:
          'The club rules document is the primary documents surface.',
      sectionTitles: ['Documents'],
      cardSurfaceFamilies: ['documentLibrary'],
      pinnedWorkflowIds: ['chess-rules-documents'],
      visiblePersonaIds: ['chess-organizer'],
      requiredPermission: 'community.surface.documents.read',
    ),
    LoomDeclarativeTabSpec(
      tabId: 'admin',
      label: 'Admin',
      iconKey: 'admin',
      description:
          'Organizer pairing queue, disputes, rankings publication, and export.',
      rendererContractId: 'admin-review-compose-queue',
      pinningPolicy: 'pin-pairing-queue',
      pinningPolicyRationale:
          'Organizer admin pins the pairing queue and export work.',
      sectionTitles: ['Admin'],
      cardSurfaceFamilies: ['dashboard', 'statusTimeline', 'exportWizard'],
      pinnedWorkflowIds: ['chess-pairing-queue'],
      visiblePersonaIds: ['chess-organizer'],
      requiredPermission: 'community.surface.navigation.configure',
    ),
    LoomDeclarativeTabSpec(
      tabId: 'messages',
      label: 'Messages',
      iconKey: 'messages',
      description: 'Pairing discussion threads and club messages.',
      rendererContractId: 'messages-inbox-thread-composer',
      pinningPolicy: 'none-declared-for-messages',
      pinningPolicyRationale:
          'Messages uses discussion threads instead of a pinned workflow card.',
      sectionTitles: ['Messages'],
      cardSurfaceFamilies: ['discussionThread'],
      pinnedWorkflowIds: ['chess-discussion-thread'],
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
  final hasLegacySurfaceFamily = experience.workflows.any((workflow) {
    final entry = cardSurfaceRegistryEntryFor(
      extensionId: experience.extensionId,
      workflow: workflow,
    );
    return surfaceFamilies.contains(entry.cardSurfaceFamily);
  });
  final hasEngineNativeSurfaceFamily =
      experience.workflowDefinitions?.values.any(
        (definition) => definition.renderBindings.any(
          (binding) => surfaceFamilies.contains(binding.cardSurfaceFamily),
        ),
      ) ??
      false;
  return hasLegacySurfaceFamily || hasEngineNativeSurfaceFamily;
}

bool _personaCanAdministerAnyWorkflow(
  LoomExperienceDefinition experience,
  String personaId,
) {
  final engineDefinitions = experience.workflowDefinitions;
  if (engineDefinitions != null && engineDefinitions.isNotEmpty) {
    final engineAdminDefinitions = engineDefinitions.values.where(
      (definition) => definition.renderBindings.any(
        (binding) => binding.tabId == 'admin',
      ),
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
