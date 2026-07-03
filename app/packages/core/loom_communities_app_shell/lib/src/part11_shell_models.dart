part of '../loom_communities_app_shell.dart';

class LoomWorkflowDefinition {
  const LoomWorkflowDefinition({
    required this.workflowId,
    required this.title,
    required this.entryText,
    required this.actionText,
    required this.resultText,
    this.calendarItem,
    this.responseChoices,
    this.theme,
  });

  final String workflowId;
  final String title;
  final String entryText;
  final String actionText;
  final String resultText;

  /// Package-declared dated-event data. Null means this workflow either has
  /// no dated-event aspect, or the community is catalog-driven and has not
  /// been backfilled with real calendar data yet — callers should fall back
  /// to the generic (non-dated) rendering path.
  final LoomCalendarItem? calendarItem;

  /// Package-declared action-surface response choices (e.g. Going/Maybe/
  /// Can't go, or Approve/Reject/Request changes). Null means the caller
  /// should derive a default choice set from the workflow's category —
  /// most categories default to a single choice (today's exact behavior);
  /// see `_defaultResponseChoicesForCategory`.
  final List<LoomWorkflowResponseChoice>? responseChoices;

  /// Package-declared per-workflow theme override, merged on top of the
  /// owning tab's [LoomCardTheme] (which is itself merged on top of the
  /// community-level default). Null means this workflow renders with
  /// whatever its tab resolves to — most workflows should leave this unset.
  final LoomCardTheme? theme;
}

/// One selectable outcome on a workflow's action surface. A workflow with a
/// single choice renders today's one-button confirm surface; more than one
/// choice renders a real branching response surface (e.g. Going/Maybe/Can't
/// go) instead of a generic confirm/cancel pair.
class LoomWorkflowResponseChoice {
  const LoomWorkflowResponseChoice({
    required this.responseId,
    required this.label,
    this.icon = Icons.check_circle_outline,
    this.isDestructive = false,
  });

  final String responseId;
  final String label;
  final IconData icon;
  final bool isDestructive;
}

/// A real, package-declared dated calendar entry backing an
/// `event-rsvp`/`calendar` card-surface workflow, used to replace the
/// Calendar tab's placeholder week strip and prose summary with an actual
/// date/agenda/detail view.
class LoomCalendarItem {
  const LoomCalendarItem({
    required this.dateTime,
    this.location,
    this.capacityLabel,
  });

  final DateTime dateTime;
  final String? location;
  final String? capacityLabel;
}

class LoomProductionWorkflowContract {
  const LoomProductionWorkflowContract({
    required this.workflowId,
    required this.cardSurfaceFamily,
    required this.apiContract,
    required this.requiredInteractions,
    required this.primaryActions,
    required this.alternateActions,
    required this.rendererTarget,
    required this.fakeBackendSupport,
    required this.category,
    required this.surfaceLabel,
    required this.objectLabel,
    required this.screenTitle,
    required this.primaryActionLabel,
    required this.alternateActionLabel,
    required this.decisionSummary,
    required this.inputSummary,
    required this.validationSummary,
    required this.resultSummary,
    required this.receiverStateSummary,
    required this.successTitle,
    required this.successChipLabel,
    required this.receiverSurfaceTitle,
    required this.trustSummary,
    required this.icon,
  });

  final String workflowId;
  final String cardSurfaceFamily;
  final String apiContract;
  final List<String> requiredInteractions;
  final List<String> primaryActions;
  final List<String> alternateActions;
  final String rendererTarget;
  final String fakeBackendSupport;
  final String category;
  final String surfaceLabel;
  final String objectLabel;
  final String screenTitle;
  final String primaryActionLabel;
  final String alternateActionLabel;
  final String decisionSummary;
  final String inputSummary;
  final String validationSummary;
  final String resultSummary;
  final String receiverStateSummary;
  final String successTitle;
  final String successChipLabel;
  final String receiverSurfaceTitle;
  final String trustSummary;
  final IconData icon;
}

class LoomWorkflowCardSurfaceRegistryEntry {
  const LoomWorkflowCardSurfaceRegistryEntry({
    required this.workflowId,
    required this.cardSurfaceFamily,
    required this.apiContract,
    required this.requiredInteractions,
    required this.primaryActions,
    required this.alternateActions,
    required this.rendererTarget,
    required this.fakeBackendSupport,
    this.routeTemplate = '/workflows/:workflowId',
  });

  final String workflowId;
  final String cardSurfaceFamily;
  final String apiContract;
  final List<String> requiredInteractions;
  final List<String> primaryActions;
  final List<String> alternateActions;
  final String rendererTarget;
  final String fakeBackendSupport;
  final String routeTemplate;
}

class LoomTabRendererContract {
  const LoomTabRendererContract({
    required this.rendererId,
    required this.label,
    required this.tabIds,
    required this.surfaceFamilies,
    required this.requiredAnatomy,
    required this.requiredInteractions,
    required this.requiredStates,
    required this.evidenceRequirements,
    required this.fallbackPolicy,
  });

  final String rendererId;
  final String label;
  final List<String> tabIds;
  final List<String> surfaceFamilies;
  final List<String> requiredAnatomy;
  final List<String> requiredInteractions;
  final List<String> requiredStates;
  final List<String> evidenceRequirements;
  final String fallbackPolicy;

  bool supportsSurfaceFamily(String family) {
    return surfaceFamilies.contains(family);
  }
}

class LoomAppShellTabSpec {
  const LoomAppShellTabSpec({
    required this.tabId,
    required this.label,
    required this.icon,
    required this.description,
    this.rendererContractId = 'home-surface-stack',
    this.pinningPolicy = 'none',
    this.pinningPolicyRationale =
        'No pinned surface is needed for this tab; users should scan the tab content in order.',
    this.sectionTitles = const [],
    this.cardSurfaceFamilies = const [],
    this.pinnedWorkflowIds = const [],
    this.visiblePersonaIds = const [],
    this.requiredPermission = 'community.surface.navigation.read',
  });

  final String tabId;
  final String label;
  final IconData icon;
  final String description;
  final String rendererContractId;
  final String pinningPolicy;
  final String pinningPolicyRationale;
  final List<String> sectionTitles;
  final List<String> cardSurfaceFamilies;
  final List<String> pinnedWorkflowIds;
  final List<String> visiblePersonaIds;
  final String requiredPermission;

  bool isVisibleFor(String personaId) {
    return visiblePersonaIds.isEmpty || visiblePersonaIds.contains(personaId);
  }

  bool matchesWorkflow({
    required String extensionId,
    required LoomWorkflowDefinition workflow,
  }) {
    if (tabId == 'home') {
      return true;
    }
    if (tabId == 'messages') {
      return false;
    }
    if (pinnedWorkflowIds.contains(workflow.workflowId)) {
      return true;
    }
    final sectionTitle = _sectionTitleFor(workflow);
    if (sectionTitles.contains(sectionTitle)) {
      return true;
    }
    final registry = cardSurfaceRegistryEntryFor(
      extensionId: extensionId,
      workflow: workflow,
    );
    return cardSurfaceFamilies.contains(registry.cardSurfaceFamily);
  }

  String descriptionFor(LoomPersonaDefinition persona) {
    if (visiblePersonaIds.isEmpty) {
      return description;
    }
    return '$description Tuned for ${persona.label}.';
  }

  bool get declaresPinnedSurfaces => pinnedWorkflowIds.isNotEmpty;

  bool get hasExplicitPinningPolicy =>
      pinningPolicy.trim().isNotEmpty &&
      pinningPolicyRationale.trim().length >= 12;

  LoomTabRendererContract get rendererContract =>
      tabRendererContractFor(rendererContractId);
}

class LoomDeclarativeTabSpec {
  const LoomDeclarativeTabSpec({
    required this.tabId,
    required this.label,
    required this.iconKey,
    required this.description,
    required this.rendererContractId,
    this.pinningPolicy = 'none',
    this.pinningPolicyRationale =
        'This tab uses ordered content rather than a pinned surface.',
    this.sectionTitles = const [],
    this.cardSurfaceFamilies = const [],
    this.pinnedWorkflowIds = const [],
    this.visiblePersonaIds = const [],
    this.requiredPermission = 'community.surface.navigation.read',
  });

  final String tabId;
  final String label;
  final String iconKey;
  final String description;
  final String rendererContractId;
  final String pinningPolicy;
  final String pinningPolicyRationale;
  final List<String> sectionTitles;
  final List<String> cardSurfaceFamilies;
  final List<String> pinnedWorkflowIds;
  final List<String> visiblePersonaIds;
  final String requiredPermission;

  LoomAppShellTabSpec toTabSpec() {
    return LoomAppShellTabSpec(
      tabId: tabId,
      label: label,
      icon: _tabIconForKey(iconKey),
      description: description,
      rendererContractId: rendererContractId,
      pinningPolicy: pinningPolicy,
      pinningPolicyRationale: pinningPolicyRationale,
      sectionTitles: sectionTitles,
      cardSurfaceFamilies: cardSurfaceFamilies,
      pinnedWorkflowIds: pinnedWorkflowIds,
      visiblePersonaIds: visiblePersonaIds,
      requiredPermission: requiredPermission,
    );
  }
}

class CommunityAppShellCustomizationSpec {
  const CommunityAppShellCustomizationSpec({
    required this.experience,
    required this.persona,
    required this.tabs,
    required this.selectedTab,
    required this.visibleWorkflowIds,
    required this.focusKey,
    required this.focusedWorkflowId,
    required this.presentationStatesByWorkflowId,
    required this.theme,
  });

  factory CommunityAppShellCustomizationSpec.fromSelection({
    required LoomExperienceDefinition experience,
    required LoomPersonaDefinition persona,
    required List<LoomAppShellTabSpec> tabs,
    required LoomAppShellTabSpec selectedTab,
    required List<String> visibleWorkflowIds,
    required String? focusedWorkflowId,
    required String? expandedWorkflowId,
  }) {
    final states = <String, String>{};
    for (final workflowId in visibleWorkflowIds) {
      states[workflowId] = expandedWorkflowId == workflowId
          ? 'expanded'
          : focusedWorkflowId == workflowId
          ? 'medium'
          : 'minimized';
    }
    final accent = Color(experience.accentColor);
    final usesModernCardTheme = experience.themeOverride != null;
    final communityCard = LoomCardTheme.merge(
      LoomCardTheme.deriveFromAccent(accent, lightSurface: usesModernCardTheme),
      experience.themeOverride,
    );
    final tabCard = LoomCardTheme.merge(
      communityCard,
      experience.tabThemeOverrides[selectedTab.tabId],
    );
    final background = usesModernCardTheme
        ? Color.alphaBlend(accent.withValues(alpha: 0.035), Colors.white)
        : _screenBackgroundFor(accent);
    return CommunityAppShellCustomizationSpec(
      experience: experience,
      persona: persona,
      tabs: List.unmodifiable(tabs),
      selectedTab: selectedTab,
      visibleWorkflowIds: List.unmodifiable(visibleWorkflowIds),
      focusKey: '${persona.personaId}:${selectedTab.tabId}',
      focusedWorkflowId: focusedWorkflowId,
      presentationStatesByWorkflowId: Map.unmodifiable(states),
      theme: LoomSurfaceTheme(
        accent: accent,
        background: background,
        tabHeight: 76,
        density: 'comfortable-mobile',
        imageTreatment: 'community-icon-badge',
        communityCard: communityCard,
        tabCard: tabCard,
        usesModernCardTheme: usesModernCardTheme,
      ),
    );
  }

  final LoomExperienceDefinition experience;
  final LoomPersonaDefinition persona;
  final List<LoomAppShellTabSpec> tabs;
  final LoomAppShellTabSpec selectedTab;
  final List<String> visibleWorkflowIds;
  final String focusKey;
  final String? focusedWorkflowId;
  final Map<String, String> presentationStatesByWorkflowId;
  final LoomSurfaceTheme theme;

  Map<String, LoomTabRendererContract> get rendererContractsByTabId {
    return Map.unmodifiable({
      for (final tab in tabs) tab.tabId: tab.rendererContract,
    });
  }

  /// Resolves the [LoomCardTheme] a given workflow's card surface should
  /// render with, regardless of which tab currently lists it (e.g. Home
  /// lists every workflow): looks up the workflow's *owning* tab — its
  /// dedicated tab if it has one, else Home — merges any `tabThemes`
  /// override for that tab onto the community default, then merges the
  /// workflow's own theme override on top. `home` is excluded from the
  /// match search itself since `LoomAppShellTabSpec.matchesWorkflow` always
  /// returns true for it (Home lists every workflow), which would otherwise
  /// make it win the search for every workflow regardless of its real tab.
  LoomCardTheme cardThemeFor(LoomWorkflowDefinition workflow) {
    final owningTab = tabs.firstWhere(
      (tab) =>
          tab.tabId != 'home' &&
          tab.matchesWorkflow(
            extensionId: experience.extensionId,
            workflow: workflow,
          ),
      orElse: () => selectedTab,
    );
    final tabCard = owningTab.tabId == selectedTab.tabId
        ? theme.tabCard
        : LoomCardTheme.merge(
            theme.communityCard,
            experience.tabThemeOverrides[owningTab.tabId],
          );
    return LoomCardTheme.merge(tabCard, workflow.theme);
  }
}

const _tabRendererContractsById = <String, LoomTabRendererContract>{
  'home-surface-stack': LoomTabRendererContract(
    rendererId: 'HomeTabSurfaceStack',
    label: 'Home surface stack',
    tabIds: ['home'],
    surfaceFamilies: [
      'community-home',
      'announcement',
      'event-rsvp',
      'calendar',
      'volunteer',
      'care-request',
      'approval',
      'workflow-status',
      'payment',
      'exchange',
      'equipment-loan',
      'documents',
      'external-document-link',
      'operations',
      'thread',
      'social',
      'form',
    ],
    requiredAnatomy: [
      'community identity header',
      'pinned or in-focus surface region',
      'minimized surface stack',
      'medium in-focus surface',
      'tap-to-expanded detail state',
    ],
    requiredInteractions: [
      'resolveCommunityTheme',
      'resolvePersonaTabs',
      'getPersonaSurfacePresentationState',
      'updatePersonaSurfacePresentationState',
      'previewNavigationConfiguration',
    ],
    requiredStates: ['minimized', 'medium', 'expanded', 'pinned or no-pin'],
    evidenceRequirements: [
      'community list minimized/medium card screenshots',
      'in-community minimized, medium, and expanded surface screenshots',
      'theme token proof',
      'explicit pinning policy proof',
    ],
    fallbackPolicy:
        'May host unassigned surfaces, but primary workflows should move to a tab-native renderer when a dedicated tab exists.',
  ),
  'calendar-agenda-event-detail': LoomTabRendererContract(
    rendererId: 'CalendarTabSurface',
    label: 'Calendar month/week/agenda and event detail',
    tabIds: ['calendar'],
    surfaceFamilies: ['calendar', 'event-rsvp', 'member-meetup'],
    requiredAnatomy: [
      'month or week/date strip',
      'agenda list grouped by date',
      'event detail with title, time, location, capacity, host, and reminders',
      'RSVP or meetup action state',
    ],
    requiredInteractions: [
      'listCalendarItems',
      'getCalendarItem',
      'openLinkedSurface',
      'respondGoingMaybeNo',
      'changeRsvp',
      'cancelRsvp',
      'joinWaitlist',
      'setReminder',
    ],
    requiredStates: [
      'empty schedule',
      'upcoming item',
      'selected detail',
      'responded',
      'waitlisted or full',
      'cancelled or rescheduled',
    ],
    evidenceRequirements: [
      'calendar tab screenshot',
      'selected event detail screenshot',
      'RSVP/change response screenshot',
      'receiver or reminder state screenshot',
    ],
    fallbackPolicy:
        'Event workflows may appear on Home as summaries, but Calendar owns dated browsing and event detail rendering.',
  ),
  'messages-inbox-thread-composer': LoomTabRendererContract(
    rendererId: 'MessagesTabSurface',
    label: 'Messages inbox, thread, composer, unread, and invites',
    tabIds: ['messages'],
    surfaceFamilies: ['thread', 'social', 'inbox'],
    requiredAnatomy: [
      'conversation or inbox list',
      'unread badges',
      'thread detail',
      'message composer',
      'connection invite/accept/decline state',
    ],
    requiredInteractions: [
      'createThread',
      'reply',
      'markRead',
      'listUnread',
      'muteThread',
      'archiveThread',
      'sendInvite',
      'acceptInvite',
      'declineInvite',
      'connectionStatus',
    ],
    requiredStates: [
      'empty inbox',
      'unread',
      'thread open',
      'sending',
      'sent/read',
      'muted/archived',
      'invite pending',
    ],
    evidenceRequirements: [
      'messages tab inbox screenshot',
      'thread detail screenshot',
      'composer/action screenshot',
      'connection invite or state screenshot',
    ],
    fallbackPolicy:
        'Messages must not render as a generic workflow list; it needs a chat/thread information architecture.',
  ),
  'marketplace-browse-listing-detail': LoomTabRendererContract(
    rendererId: 'MarketplaceTabSurface',
    label: 'Marketplace browse, search, listing, detail, custody, and queue',
    tabIds: ['marketplace'],
    surfaceFamilies: ['equipment-loan', 'exchange'],
    requiredAnatomy: [
      'browse/search/filter header',
      'listing grid or list',
      'listing detail with owner, availability, custody, queue, condition, and pickup',
      'list your item action',
      'loan/giveaway action state',
    ],
    requiredInteractions: [
      'browseEquipment',
      'searchEquipment',
      'listEquipmentListing',
      'updateEquipmentListing',
      'removeEquipmentListing',
      'requestLoan',
      'joinLoanQueue',
      'getCurrentHolder',
      'listCustodyHistory',
      'returnItem',
      'claimGiveaway',
      'transferGiveawayOwnership',
    ],
    requiredStates: [
      'available',
      'reserved',
      'checked out/current holder',
      'queued',
      'returned',
      'giveaway claimed',
      'delisted',
    ],
    evidenceRequirements: [
      'marketplace browse screenshot',
      'listing detail screenshot',
      'loan/giveaway action screenshot',
      'current holder or queue screenshot',
    ],
    fallbackPolicy:
        'Marketplace surfaces require browse and listing affordances; a single workflow card is not sufficient.',
  ),
  'documents-library-detail': LoomTabRendererContract(
    rendererId: 'DocumentsTabSurface',
    label: 'Documents library, detail, embedded, and external open',
    tabIds: ['documents'],
    surfaceFamilies: [
      'documents',
      'external-document-link',
      'operations',
      'portability',
      'workflow-status',
    ],
    requiredAnatomy: [
      'document library categories',
      'document detail with metadata and permissions',
      'embedded open affordance',
      'external app/link open affordance',
      'version/access/acknowledgement state',
    ],
    requiredInteractions: [
      'listDocuments',
      'getDocumentDetail',
      'openEmbeddedDocument',
      'openExternalDocument',
      'downloadDocument',
      'acknowledgeDocument',
      'requestDocumentAccess',
      'listDocumentVersions',
      'documentAuditTrail',
    ],
    requiredStates: [
      'available',
      'restricted',
      'access requested',
      'opened embedded',
      'opened external',
      'acknowledged',
      'retired/versioned',
    ],
    evidenceRequirements: [
      'documents tab library screenshot',
      'document detail screenshot',
      'embedded open screenshot or handoff proof',
      'external open screenshot or handoff proof',
    ],
    fallbackPolicy:
        'Document and portability workflows may summarize on Home, but Documents owns library/detail/open rendering.',
  ),
  'workflow-status-timeline-actions': LoomTabRendererContract(
    rendererId: 'WorkflowStatusSurface',
    label: 'Workflow status timeline and actions',
    tabIds: ['home', 'admin', 'documents'],
    surfaceFamilies: ['workflow-status', 'approval', 'form', 'operations'],
    requiredAnatomy: [
      'status timeline',
      'current step and owner',
      'submitted details',
      'comments/documents/payment needed',
      'next actions and alternate/reopen paths',
    ],
    requiredInteractions: [
      'createWorkflowInstance',
      'getWorkflowStatus',
      'listWorkflowSteps',
      'transitionWorkflowStep',
      'requestWorkflowChanges',
      'approveWorkflowStep',
      'rejectWorkflowStep',
      'addWorkflowComment',
      'attachWorkflowDocument',
      'reopenWorkflow',
    ],
    requiredStates: [
      'submitted',
      'under review',
      'feedback needed',
      'payment needed',
      'approved/rejected',
      'reopened',
      'cancelled',
    ],
    evidenceRequirements: [
      'timeline screenshot',
      'current step screenshot',
      'action/result screenshot',
      'receiver/notification state screenshot',
    ],
    fallbackPolicy:
        'Use this renderer for arbitrary multi-step requests instead of fixed approval cards when the workflow has variable steps.',
  ),
  'payment-giving-ledger': LoomTabRendererContract(
    rendererId: 'PaymentGivingTabSurface',
    label: 'Giving, payment, receipt, and entitlement ledger',
    tabIds: ['giving'],
    surfaceFamilies: ['payment', 'ad-off-entitlement', 'ad-off-settlement'],
    requiredAnatomy: [
      'amount and purpose summary',
      'checkout or payment intent',
      'receipt and audit state',
      'subscription/entitlement management',
    ],
    requiredInteractions: [
      'createPaymentIntent',
      'confirmPayment',
      'retryPayment',
      'refund',
      'manageRecurringPlan',
      'getReceipt',
      'getEntitlement',
      'settlementStatus',
    ],
    requiredStates: [
      'due',
      'checkout',
      'paid',
      'failed/retry',
      'refunded',
      'recurring',
      'entitled',
    ],
    evidenceRequirements: [
      'giving tab screenshot',
      'payment detail screenshot',
      'receipt/entitlement screenshot',
    ],
    fallbackPolicy:
        'Payment summaries may appear elsewhere, but Giving owns checkout, receipt, and entitlement depth.',
  ),
  'care-volunteer-request-queue': LoomTabRendererContract(
    rendererId: 'CareVolunteerTabSurface',
    label: 'Care requests, volunteer shifts, roster, and privacy',
    tabIds: ['care'],
    surfaceFamilies: ['care-request', 'volunteer'],
    requiredAnatomy: [
      'request or shift queue',
      'protected/public data split',
      'roster or volunteer count',
      'assignment/check-in state',
      'neutral notification state',
    ],
    requiredInteractions: [
      'createRequest',
      'assignCareTeam',
      'reviewRequest',
      'resolveRequest',
      'listShifts',
      'signup',
      'listVolunteers',
      'protectedContactReveal',
      'checkIn',
    ],
    requiredStates: [
      'open request',
      'assigned',
      'resolved',
      'shift open',
      'signed up',
      'checked in',
      'protected',
    ],
    evidenceRequirements: [
      'care tab queue screenshot',
      'request/detail screenshot',
      'volunteer roster/count screenshot',
      'protected contact handling screenshot',
    ],
    fallbackPolicy:
        'Care and volunteer tasks need privacy-aware queues/details, not generic action cards.',
  ),
  'admin-review-compose-queue': LoomTabRendererContract(
    rendererId: 'AdminReviewComposeTabSurface',
    label: 'Admin compose, approval queue, sponsorship, and moderation',
    tabIds: ['admin'],
    surfaceFamilies: ['announcement', 'approval', 'ad', 'workflow-status'],
    requiredAnatomy: [
      'role-specific task queue',
      'composer or reviewer detail',
      'preview/status/audit summary',
      'approve/reject/request changes actions',
    ],
    requiredInteractions: [
      'createDraft',
      'previewAnnouncement',
      'publishAnnouncement',
      'assignReviewer',
      'approve',
      'reject',
      'requestChanges',
      'comment',
      'recordImpression',
      'getDisclosure',
    ],
    requiredStates: [
      'draft',
      'preview',
      'published',
      'pending review',
      'approved',
      'rejected',
      'changes requested',
      'disclosed',
    ],
    evidenceRequirements: [
      'admin tab queue screenshot',
      'compose/detail screenshot',
      'decision/action screenshot',
      'result/audit screenshot',
    ],
    fallbackPolicy:
        'Admin tasks need queues and compose/review surfaces; do not expose them as undifferentiated workflow cards.',
  ),
};

LoomTabRendererContract tabRendererContractFor(String rendererContractId) {
  return _tabRendererContractsById[rendererContractId] ??
      _tabRendererContractsById['home-surface-stack']!;
}

List<LoomTabRendererContract> allTabRendererContracts() {
  return List.unmodifiable(_tabRendererContractsById.values);
}

class LoomExperienceDefinition {
  const LoomExperienceDefinition({
    required this.extensionId,
    required this.displayName,
    required this.tagline,
    required this.accentColor,
    required this.workflows,
    this.personas,
    this.personaPolicies,
    this.themeOverride,
    this.tabThemeOverrides = const {},
  });

  final String extensionId;
  final String displayName;
  final String tagline;
  final int accentColor;
  final List<LoomWorkflowDefinition> workflows;

  /// Package-declared personas. Null means "not package-driven": callers
  /// should fall back to [personasForExtensionId]'s hardcoded catalog.
  final List<LoomPersonaDefinition>? personas;

  /// Package-declared per-workflow persona policy, keyed by workflowId. Null
  /// (or a missing workflowId key) means "not package-driven": callers
  /// should fall back to [personaPolicyForWorkflow]'s hardcoded catalog.
  final Map<String, LoomWorkflowPersonaPolicy>? personaPolicies;

  /// Package-declared community-level theme override, merged on top of the
  /// theme derived from [accentColor]. Null means the community renders
  /// with the plain accent-derived default.
  final LoomCardTheme? themeOverride;

  /// Package-declared per-tab theme overrides, keyed by `tabId`, merged on
  /// top of the community-level theme for whichever tab is selected. Empty
  /// means no tab has a distinct look from the community default.
  final Map<String, LoomCardTheme> tabThemeOverrides;
}

class LoomEvidenceTarget {
  const LoomEvidenceTarget({
    required this.phase,
    required this.communityId,
    required this.communityName,
    required this.handle,
    required this.extensionId,
    required this.accentColor,
    required this.seedDataFiles,
  });

  final String phase;
  final String communityId;
  final String communityName;
  final String handle;
  final String extensionId;
  final String accentColor;
  final List<String> seedDataFiles;
}

class LoomPersonaDefinition {
  const LoomPersonaDefinition({
    required this.personaId,
    required this.label,
    required this.roleLabel,
    required this.description,
  });

  final String personaId;
  final String label;
  final String roleLabel;
  final String description;
}

enum LoomPersonaWorkflowState { actor, receiver, readOnly, disabled }

class LoomWorkflowPersonaPolicy {
  const LoomWorkflowPersonaPolicy({
    required this.actorPersonaIds,
    this.receiverPersonaIds = const [],
    this.readOnlyPersonaIds = const [],
    this.prerequisiteWorkflowId,
    this.receiverEntryText,
    this.receiverActionText,
    this.receiverResultText,
    this.readOnlyText,
    this.disabledReason = 'Not available for this persona',
  });

  final List<String> actorPersonaIds;
  final List<String> receiverPersonaIds;
  final List<String> readOnlyPersonaIds;
  final String? prerequisiteWorkflowId;
  final String? receiverEntryText;
  final String? receiverActionText;
  final String? receiverResultText;
  final String? readOnlyText;
  final String disabledReason;
}

class LoomPersonaWorkflowView {
  const LoomPersonaWorkflowView({
    required this.state,
    required this.completed,
    required this.received,
    required this.waitingForPrerequisite,
    required this.entryText,
    required this.actionText,
    required this.resultText,
    required this.personaRationale,
    required this.waitingText,
  });

  final LoomPersonaWorkflowState state;
  final bool completed;
  final bool received;
  final bool waitingForPrerequisite;
  final String entryText;
  final String actionText;
  final String resultText;
  final String personaRationale;
  final String waitingText;
}

class LoomPersonaWorkflowMatrixRow {
  const LoomPersonaWorkflowMatrixRow({
    required this.extensionId,
    required this.workflowId,
    required this.personaId,
    required this.state,
    required this.rationale,
    this.prerequisiteWorkflowId,
  });

  final String extensionId;
  final String workflowId;
  final String personaId;
  final LoomPersonaWorkflowState state;
  final String rationale;
  final String? prerequisiteWorkflowId;
}

class LoomWorkflowDependency {
  const LoomWorkflowDependency({
    required this.extensionId,
    required this.workflowId,
    required this.actorPersonaId,
    required this.receiverPersonaId,
    required this.prerequisiteWorkflowId,
  });

  final String extensionId;
  final String workflowId;
  final String actorPersonaId;
  final String receiverPersonaId;
  final String prerequisiteWorkflowId;
}

