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
    LoomDeclarativeTabSpec(tabId: 'registration', label: 'Registration', iconKey: 'documents', description: 'Guardian guided registration wizard and reviewer timeline on the same engine instance.', rendererContractId: 'workflow-status-timeline-actions', pinningPolicy: 'pin-active-registration', pinningPolicyRationale: 'Youth Soccer pins registration because waiver and payment gates block roster participation.', sectionTitles: ['Registration'], cardSurfaceFamilies: ['guidedProcess', 'statusTimeline'], pinnedWorkflowIds: ['soccer-guardian-join-approval'], requiredPermission: 'community.surface.workflow.read'),
    LoomDeclarativeTabSpec(tabId: 'schedule', label: 'Schedule', iconKey: 'calendar', description: 'Practice and game agenda with RSVP, reminder, field, opponent, and attendance state.', rendererContractId: 'calendar-agenda-event-detail', pinningPolicy: 'pin-next-practice', pinningPolicyRationale: 'Schedule-first is the top Youth Soccer hierarchy.', sectionTitles: ['Schedule'], cardSurfaceFamilies: ['calendarAgenda'], pinnedWorkflowIds: ['soccer-practice-schedule'], requiredPermission: 'community.surface.calendar.read'),
    LoomDeclarativeTabSpec(tabId: 'team', label: 'Team', iconKey: 'groups', description: 'Guardian roster card, coach roster table, and protected minor detail.', rendererContractId: 'workflow-status-timeline-actions', pinningPolicy: 'pin-my-player', pinningPolicyRationale: 'The team tab pins the player roster surface and protected detail card.', sectionTitles: ['Team'], cardSurfaceFamilies: ['stateMachineGrid', 'table', 'protectedDetail', 'documentLibrary'], pinnedWorkflowIds: ['soccer-team-roster'], requiredPermission: 'community.surface.workflow.read'),
    LoomDeclarativeTabSpec(tabId: 'payments', label: 'Payments', iconKey: 'payment', description: 'Guardian registration checkout with receipt, failed payment recovery, refund, and subscription management.', rendererContractId: 'payment-giving-ledger', pinningPolicy: 'pin-registration-fee', pinningPolicyRationale: 'Guardians need the amount, receipt, and next payment action before roster confirmation.', sectionTitles: ['Payments'], cardSurfaceFamilies: ['paymentCheckout'], pinnedWorkflowIds: ['soccer-registration-payment'], visiblePersonaIds: ['guardian'], requiredPermission: 'community.surface.payments.read'),
    LoomDeclarativeTabSpec(tabId: 'documents', label: 'Waivers', iconKey: 'documents', description: 'Waiver library with embedded/external open, acknowledgement, access request, and audit trail.', rendererContractId: 'documents-library-detail', pinningPolicy: 'pin-current-waiver', pinningPolicyRationale: 'The current waiver is the primary document.', sectionTitles: ['Documents'], cardSurfaceFamilies: ['documentLibrary'], pinnedWorkflowIds: ['soccer-waiver-document'], visiblePersonaIds: ['guardian', 'coach'], requiredPermission: 'community.surface.documents.read'),
    LoomDeclarativeTabSpec(tabId: 'coach', label: 'Coach', iconKey: 'admin', description: 'Coach dashboard combining roster, schedule controls, and reminder inbox.', rendererContractId: 'admin-review-compose-queue', pinningPolicy: 'pin-roster-and-reminders', pinningPolicyRationale: 'Coach-only work belongs off the guardian tabs.', sectionTitles: ['Coach'], cardSurfaceFamilies: ['dashboard', 'notificationInbox'], pinnedWorkflowIds: ['soccer-reminder-notification'], visiblePersonaIds: ['coach'], requiredPermission: 'community.surface.navigation.configure'),
    LoomDeclarativeTabSpec(tabId: 'messages', label: 'Messages', iconKey: 'messages', description: 'Team discussion thread for guardian and coach coordination.', rendererContractId: 'messages-inbox-thread-composer', pinningPolicy: 'none-declared-for-messages', pinningPolicyRationale: 'Messages uses threads rather than pinned workflow cards.', sectionTitles: ['Messages'], cardSurfaceFamilies: ['discussionThread'], pinnedWorkflowIds: ['soccer-team-discussion'], requiredPermission: 'community.surface.messages.read'),
    LoomDeclarativeTabSpec(tabId: 'admin', label: 'Export', iconKey: 'admin', description: 'Owner export wizard with minor redaction preview, checksum, transfer, rollback, and retry.', rendererContractId: 'admin-review-compose-queue', pinningPolicy: 'pin-redaction-preview', pinningPolicyRationale: 'Owner export must foreground redaction before transfer.', sectionTitles: ['Admin'], cardSurfaceFamilies: ['exportWizard'], pinnedWorkflowIds: ['soccer-export-metadata'], visiblePersonaIds: ['owner'], requiredPermission: 'community.surface.navigation.configure'),
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
      cardSurfaceFamilies: ['form-entry', 'state-machine-grid', 'discussion-thread'],
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
    LoomDeclarativeTabSpec(tabId: 'calendar', label: 'Calendar', iconKey: 'calendar', description: 'Admin event creation and member RSVP agenda share the same event workflow instance with audience-selected delivery.', rendererContractId: 'calendar-agenda-event-detail', pinningPolicy: 'pin-next-friday-service', pinningPolicyRationale: 'The Friday service and selected-audience invitations are the time-sensitive Mosque surface.', sectionTitles: ['Calendar'], cardSurfaceFamilies: ['formEntry', 'calendarAgenda'], pinnedWorkflowIds: ['mosque-event-rsvp'], requiredPermission: 'community.surface.calendar.read'),
    LoomDeclarativeTabSpec(tabId: 'giving', label: 'Giving', iconKey: 'giving', description: 'Donation checkout, receipts, recurring controls, and durable donor visibility preference.', rendererContractId: 'payment-giving-ledger', pinningPolicy: 'pin-current-donation', pinningPolicyRationale: 'Members need amount, receipt, and privacy state before donating.', sectionTitles: ['Giving'], cardSurfaceFamilies: ['paymentCheckout', 'singleItem'], pinnedWorkflowIds: ['mosque-donation-payment', 'mosque-donor-visibility'], requiredPermission: 'community.surface.payments.read'),
    LoomDeclarativeTabSpec(tabId: 'care', label: 'Care', iconKey: 'care', description: 'Member care request form, private field flags, own volunteer signup, and protected review status.', rendererContractId: 'workflow-status-timeline-actions', pinningPolicy: 'pin-active-care-request', pinningPolicyRationale: 'Care and volunteer follow-up are member-owned status surfaces outside Admin.', sectionTitles: ['Care'], cardSurfaceFamilies: ['formEntry', 'protectedDetail', 'volunteerRoster'], pinnedWorkflowIds: ['mosque-care-request', 'mosque-volunteer-signup'], requiredPermission: 'community.surface.workflow.read'),
    LoomDeclarativeTabSpec(tabId: 'admin', label: 'Admin', iconKey: 'admin', description: 'Announcement composer, volunteer roster controls, donation status, and protected care review.', rendererContractId: 'admin-review-compose-queue', pinningPolicy: 'pin-composer-and-review-queue', pinningPolicyRationale: 'Admin-only publish, volunteer coordination, and assigned care review must stay off member tabs.', sectionTitles: ['Admin'], cardSurfaceFamilies: ['formEntry', 'notificationInbox', 'volunteerRoster', 'protectedDetail'], pinnedWorkflowIds: ['mosque-announcement', 'mosque-volunteer-signup', 'mosque-care-request'], visiblePersonaIds: ['mosque-admin'], requiredPermission: 'community.surface.navigation.configure'),
    LoomDeclarativeTabSpec(tabId: 'search', label: 'Search', iconKey: 'search', description: 'Permission-guarded cited answers over announcements and member-visible sources.', rendererContractId: 'workflow-status-timeline-actions', pinningPolicy: 'pin-current-answer', pinningPolicyRationale: 'Search pins the current cited answer so users can inspect and report sources.', sectionTitles: ['Search'], cardSurfaceFamilies: ['searchAiAnswer'], pinnedWorkflowIds: ['mosque-search-ai-citation'], requiredPermission: 'community.surface.workflow.read'),
    LoomDeclarativeTabSpec(tabId: 'messages', label: 'Messages', iconKey: 'messages', description: 'Discussion threads plus privacy-safe care notifications and announcement inbox.', rendererContractId: 'messages-inbox-thread-composer', pinningPolicy: 'none-declared-for-messages', pinningPolicyRationale: 'Messages uses inbox/thread surfaces rather than pinned workflow cards.', sectionTitles: ['Messages'], cardSurfaceFamilies: ['discussionThread', 'notificationInbox'], pinnedWorkflowIds: ['mosque-discussion-thread', 'mosque-neutral-notification', 'mosque-announcement'], requiredPermission: 'community.surface.messages.read'),
  ],
  'ext_chess_club': [
    LoomDeclarativeTabSpec(tabId: 'matches', label: 'Matches', iconKey: 'board', description: 'Propose, negotiate, confirm, report, correct, and dispute ladder matches.', rendererContractId: 'workflow-status-timeline-actions', pinningPolicy: 'pin-active-match', pinningPolicyRationale: 'Chess Club pins the active match because the proposal, timeline, and confirmed event are one engine instance.', sectionTitles: ['Matches'], cardSurfaceFamilies: ['formEntry', 'statusTimeline', 'calendarAgenda'], pinnedWorkflowIds: ['chess-match-meetup'], requiredPermission: 'community.surface.workflow.read'),
    LoomDeclarativeTabSpec(tabId: 'calendar', label: 'Calendar', iconKey: 'calendar', description: 'Confirmed ladder matches, club nights, tournaments, locations, and reminders.', rendererContractId: 'calendar-agenda-event-detail', pinningPolicy: 'pin-next-club-night', pinningPolicyRationale: 'The next club night is the time-sensitive chess surface.', sectionTitles: ['Calendar'], cardSurfaceFamilies: ['calendarAgenda'], pinnedWorkflowIds: ['chess-club-night'], requiredPermission: 'community.surface.calendar.read'),
    LoomDeclarativeTabSpec(tabId: 'rankings', label: 'Rankings', iconKey: 'board', description: 'Live ladder table with rankingMode emphasis.', rendererContractId: 'workflow-status-timeline-actions', pinningPolicy: 'pin-live-rankings', pinningPolicyRationale: 'Rankings pins the table that is updated by match-result effects.', sectionTitles: ['Rankings'], cardSurfaceFamilies: ['table'], pinnedWorkflowIds: ['chess-rankings-table'], requiredPermission: 'community.surface.workflow.read'),
    LoomDeclarativeTabSpec(tabId: 'documents', label: 'Rules', iconKey: 'documents', description: 'Club rules, ladder policy, embedded open, external open, and download.', rendererContractId: 'documents-library-detail', pinningPolicy: 'pin-club-rules', pinningPolicyRationale: 'The club rules document is the primary documents surface.', sectionTitles: ['Documents'], cardSurfaceFamilies: ['documentLibrary'], pinnedWorkflowIds: ['chess-rules-documents'], visiblePersonaIds: ['chess-organizer'], requiredPermission: 'community.surface.documents.read'),
    LoomDeclarativeTabSpec(tabId: 'admin', label: 'Admin', iconKey: 'admin', description: 'Organizer pairing queue, disputes, rankings publication, and export.', rendererContractId: 'admin-review-compose-queue', pinningPolicy: 'pin-pairing-queue', pinningPolicyRationale: 'Organizer admin pins the pairing queue and export work.', sectionTitles: ['Admin'], cardSurfaceFamilies: ['dashboard', 'statusTimeline', 'exportWizard'], pinnedWorkflowIds: ['chess-pairing-queue'], visiblePersonaIds: ['chess-organizer'], requiredPermission: 'community.surface.navigation.configure'),
    LoomDeclarativeTabSpec(tabId: 'messages', label: 'Messages', iconKey: 'messages', description: 'Pairing discussion threads and club messages.', rendererContractId: 'messages-inbox-thread-composer', pinningPolicy: 'none-declared-for-messages', pinningPolicyRationale: 'Messages uses discussion threads instead of a pinned workflow card.', sectionTitles: ['Messages'], cardSurfaceFamilies: ['discussionThread'], pinnedWorkflowIds: ['chess-discussion-thread'], requiredPermission: 'community.surface.messages.read'),
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
