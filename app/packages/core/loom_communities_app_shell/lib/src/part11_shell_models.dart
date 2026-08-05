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
    this.givingPayment,
    this.documentLibrary,
    this.architecturalRequest,
  });

  final String workflowId;
  final String title;
  final String entryText;
  final String actionText;
  final String resultText;
  final LoomCalendarItem? calendarItem;
  final List<LoomWorkflowResponseChoice>? responseChoices;
  final LoomCardTheme? theme;
  final LoomGivingPayment? givingPayment;
  final LoomDocumentLibrary? documentLibrary;
  final LoomArchitecturalRequest? architecturalRequest;
}

class LoomArchitecturalRequest {
  const LoomArchitecturalRequest({
    required this.projectTypes,
    required this.defaultProjectDescription,
    required this.defaultPropertyAddress,
    required this.defaultRequestedCompletionDate,
    required this.defaultAttachments,
  });

  final List<String> projectTypes;
  final String defaultProjectDescription;
  final String defaultPropertyAddress;
  final String defaultRequestedCompletionDate;
  final String defaultAttachments;
}

class LoomDocumentLibrary {
  const LoomDocumentLibrary({
    required this.categories,
    required this.documents,
  });

  final List<String> categories;
  final List<LoomDocumentItem> documents;
}

class LoomDocumentItem {
  const LoomDocumentItem({
    required this.documentId,
    required this.title,
    required this.category,
    required this.version,
    required this.updatedLabel,
    required this.accessState,
    this.summary,
    this.embeddedLabel = 'Open embedded',
    this.externalLabel = 'Open external',
    this.acknowledgeLabel = 'Acknowledge',
    this.requestAccessLabel = 'Request access',
  });

  final String documentId;
  final String title;
  final String category;
  final String version;
  final String updatedLabel;
  final String accessState;
  final String? summary;
  final String embeddedLabel;
  final String externalLabel;
  final String acknowledgeLabel;
  final String requestAccessLabel;
}

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

class LoomCalendarItem {
  const LoomCalendarItem({
    required this.dateTime,
    this.location,
    this.capacityLabel,
    this.host,
  });

  final DateTime dateTime;
  final String? location;
  final String? capacityLabel;
  final String? host;
}

class LoomGivingPayment {
  const LoomGivingPayment({
    required this.amountLabel,
    this.purpose,
    this.recipient,
    this.cadence,
    this.entitlement,
  });

  final String amountLabel;
  final String? purpose;
  final String? recipient;
  final String? cadence;
  final String? entitlement;
}

class LoomListingState {
  const LoomListingState({
    required this.label,
    this.tone,
    this.showsHolder = false,
    this.showsDue = false,
    this.showsQueue = false,
  });

  final String label;
  final String? tone;
  final bool showsHolder;
  final bool showsDue;
  final bool showsQueue;
}

class LoomListingTransition {
  const LoomListingTransition({
    required this.id,
    required this.label,
    required this.fromStates,
    this.to,
    this.allowedPersonaIds,
    this.requiresWorkflowsComplete = const [],
    this.linkedWorkflowId,
    this.setsHolderToActor = false,
    this.clearsHolder = false,
    this.incrementsQueue = false,
    this.decrementsQueue = false,
    this.removesFromList = false,
    this.addsActorToQueue = false,
    this.removesActorFromQueue = false,
    this.requiresActorInQueue = false,
    this.requiresActorNotInQueue = false,
  });

  final String id;
  final String label;
  final List<String> fromStates;
  final String? to;
  final List<String>? allowedPersonaIds;
  final List<String> requiresWorkflowsComplete;
  final String? linkedWorkflowId;
  final bool setsHolderToActor;
  final bool clearsHolder;
  final bool incrementsQueue;
  final bool decrementsQueue;
  final bool removesFromList;
  final bool addsActorToQueue;
  final bool removesActorFromQueue;
  final bool requiresActorInQueue;
  final bool requiresActorNotInQueue;
}

class LoomListingStateMachine {
  const LoomListingStateMachine({
    required this.initialState,
    required this.states,
    required this.transitions,
  });

  final String initialState;
  final Map<String, LoomListingState> states;
  final List<LoomListingTransition> transitions;

  List<LoomListingTransition> transitionsFrom(String state) {
    return transitions.where((t) => t.fromStates.contains(state)).toList();
  }

  List<LoomListingTransition> availableActions(
    String currentState,
    String personaId, {
    LoomMarketplaceListing? listing,
  }) {
    return transitionsFrom(currentState)
        .where(
          (t) =>
              (t.allowedPersonaIds == null ||
                  t.allowedPersonaIds!.isEmpty ||
                  t.allowedPersonaIds!.contains(personaId)) &&
              t.requiresWorkflowsComplete.isEmpty &&
              (t.requiresActorInQueue
                  ? listing != null &&
                        listing.queuedPersonaIds.contains(personaId)
                  : true) &&
              (t.requiresActorNotInQueue
                  ? listing != null &&
                        !listing.queuedPersonaIds.contains(personaId)
                  : true),
        )
        .toList();
  }
}

class LoomMarketplaceListing {
  const LoomMarketplaceListing({
    required this.listingId,
    required this.title,
    this.category,
    this.iconKey,
    this.condition,
    this.availability = 'available',
    this.currentHolderLabel,
    this.queueLength = 0,
    this.dueLabel,
    this.description,
    this.linkedWorkflowId,
    this.template,
    this.stateMachine,
    this.state,
    this.queuedPersonaIds = const [],
  });

  final String listingId;
  final String title;
  final String? category;
  final String? iconKey;
  final String? condition;
  final String availability;
  final String? currentHolderLabel;
  final int queueLength;
  final String? dueLabel;
  final String? description;
  final String? linkedWorkflowId;
  final String? template;
  final LoomListingStateMachine? stateMachine;
  final String? state;
  final List<String> queuedPersonaIds;

  LoomMarketplaceListing copyWith({
    String? listingId,
    String? title,
    String? category,
    String? iconKey,
    String? condition,
    String? availability,
    String? currentHolderLabel,
    int? queueLength,
    String? dueLabel,
    String? description,
    String? linkedWorkflowId,
    String? template,
    LoomListingStateMachine? stateMachine,
    String? state,
    List<String>? queuedPersonaIds,
  }) {
    return LoomMarketplaceListing(
      listingId: listingId ?? this.listingId,
      title: title ?? this.title,
      category: category ?? this.category,
      iconKey: iconKey ?? this.iconKey,
      condition: condition ?? this.condition,
      availability: availability ?? this.availability,
      currentHolderLabel: currentHolderLabel ?? this.currentHolderLabel,
      queueLength: queueLength ?? this.queueLength,
      dueLabel: dueLabel ?? this.dueLabel,
      description: description ?? this.description,
      linkedWorkflowId: linkedWorkflowId ?? this.linkedWorkflowId,
      template: template ?? this.template,
      stateMachine: stateMachine ?? this.stateMachine,
      state: state ?? this.state,
      queuedPersonaIds: queuedPersonaIds ?? this.queuedPersonaIds,
    );
  }
}

class LoomMessageThread {
  const LoomMessageThread({
    required this.threadId,
    required this.subject,
    required this.participantPersonaIds,
    required this.messages,
    this.muted = false,
    this.archived = false,
  });

  final String threadId;
  final String subject;
  final List<String> participantPersonaIds;
  final List<LoomMessage> messages;
  final bool muted;
  final bool archived;

  LoomMessageThread copyWith({
    String? threadId,
    String? subject,
    List<String>? participantPersonaIds,
    List<LoomMessage>? messages,
    bool? muted,
    bool? archived,
  }) {
    return LoomMessageThread(
      threadId: threadId ?? this.threadId,
      subject: subject ?? this.subject,
      participantPersonaIds:
          participantPersonaIds ?? this.participantPersonaIds,
      messages: messages ?? this.messages,
      muted: muted ?? this.muted,
      archived: archived ?? this.archived,
    );
  }
}

class LoomMessage {
  const LoomMessage({
    required this.messageId,
    required this.senderPersonaId,
    required this.body,
    required this.timestamp,
  });

  final String messageId;
  final String senderPersonaId;
  final String body;
  final DateTime timestamp;
}

class LoomNotificationItem {
  const LoomNotificationItem({
    required this.notificationId,
    required this.title,
    required this.body,
    required this.source,
    required this.timestamp,
    required this.recipientPersonaIds,
    this.isUnread = true,
  });

  final String notificationId;
  final String title;
  final String body;
  final String source;
  final DateTime timestamp;
  final List<String> recipientPersonaIds;
  final bool isUnread;
}

class LoomExportWizardSeed {
  const LoomExportWizardSeed({required this.wizardId, required this.scope});

  final String wizardId;
  final List<String> scope;
}

class LoomVolunteerShiftSeed {
  const LoomVolunteerShiftSeed({
    required this.shiftId,
    required this.title,
    required this.capacity,
    this.filled = 0,
  });

  final String shiftId;
  final String title;
  final int capacity;
  final int filled;
}

class LoomAiSearchAnswer {
  const LoomAiSearchAnswer({
    required this.query,
    required this.answer,
    required this.citations,
  });

  final String query;
  final String answer;
  final List<String> citations;
}

class LoomAudiencePickerSeed {
  const LoomAudiencePickerSeed({
    required this.audienceId,
    required this.title,
    this.invitedPersonaIds = const [],
  });

  final String audienceId;
  final String title;
  final List<String> invitedPersonaIds;
}

class LoomSingleItemPreferenceSeed {
  const LoomSingleItemPreferenceSeed({
    required this.preferenceId,
    required this.title,
    required this.initialValue,
  });

  final String preferenceId;
  final String title;
  final String initialValue;
}

class LoomStatusTimelineEvent {
  const LoomStatusTimelineEvent({
    required this.eventId,
    required this.timestamp,
    required this.label,
  });
  final String eventId;
  final DateTime timestamp;
  final String label;
}

class LoomStatusTimelineSeed {
  const LoomStatusTimelineSeed({
    required this.timelineId,
    required this.title,
    required this.events,
  });
  final String timelineId;
  final String title;
  final List<LoomStatusTimelineEvent> events;
}

class LoomProtectedDetailSeed {
  const LoomProtectedDetailSeed({
    required this.detailId,
    required this.title,
    required this.ownerPersonaId,
    required this.assignedTo,
    required this.fullDetail,
  });
  final String detailId;
  final String title;
  final String ownerPersonaId;
  final List<String> assignedTo;
  final String fullDetail;
}

class LoomFormEntrySeed {
  const LoomFormEntrySeed({
    required this.formId,
    required this.title,
    required this.referenceTime,
    required this.notificationsEnabled,
    required this.reminderOffset,
  });
  final String formId;
  final String title;
  final DateTime referenceTime;
  final bool notificationsEnabled;
  final String reminderOffset;
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
    if (tabId == 'home') return true;
    if (tabId == 'messages') return false;
    if (pinnedWorkflowIds.contains(workflow.workflowId)) return true;
    final sectionTitle = _sectionTitleFor(workflow);
    if (sectionTitles.contains(sectionTitle)) return true;
    final registry = cardSurfaceRegistryEntryFor(
      extensionId: extensionId,
      workflow: workflow,
    );
    return cardSurfaceFamilies.contains(registry.cardSurfaceFamily);
  }

  String descriptionFor(LoomPersonaDefinition persona) {
    if (visiblePersonaIds.isEmpty) return description;
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
  'notification-inbox': LoomTabRendererContract(
    rendererId: 'NotificationInboxTabSurface',
    label: 'Notification inbox with read state and dismissal',
    tabIds: ['notifications'],
    surfaceFamilies: ['notificationInbox'],
    requiredAnatomy: [
      'notification list',
      'unread count',
      'timestamps',
      'dismiss action',
    ],
    requiredInteractions: [
      'listNotifications',
      'markNotificationRead',
      'dismissNotification',
    ],
    requiredStates: ['unread', 'read', 'dismissed', 'empty'],
    evidenceRequirements: [
      'notification inbox screenshot',
      'dismissed notification screenshot',
    ],
    fallbackPolicy:
        'Notifications require an inbox list with unread state; a single preview card is not sufficient.',
  ),
  'notification-inbox-engine-native': LoomTabRendererContract(
    rendererId: 'NotificationDedicatedTabSurface',
    label: 'Engine-native notification inbox (dedicatedTab presentation style)',
    tabIds: ['notification-inbox'],
    surfaceFamilies: ['notification'],
    requiredAnatomy: ['notification list', 'unread indicator', 'timestamps'],
    requiredInteractions: ['listNotifications', 'markNotificationRead'],
    requiredStates: ['unread', 'read', 'empty'],
    evidenceRequirements: ['notification dedicated tab screenshot'],
    fallbackPolicy:
        'Notifications require a scrollable list with unread state; a single preview card is not sufficient.',
  ),
  'export-wizard-stepper': LoomTabRendererContract(
    rendererId: 'ExportWizardTabSurface',
    label:
        'Export wizard with gated preview, generation, transfer, and result steps',
    tabIds: ['export'],
    surfaceFamilies: ['exportWizard'],
    requiredAnatomy: [
      'stepper',
      'export scope preview',
      'gated actions',
      'result state',
    ],
    requiredInteractions: [
      'previewExport',
      'generateExport',
      'transferExport',
      'retryExport',
      'rollbackExport',
    ],
    requiredStates: [
      'preview',
      'generating',
      'transferring',
      'complete',
      'failed',
    ],
    evidenceRequirements: [
      'export stepper screenshot',
      'gated next-step screenshot',
    ],
    fallbackPolicy:
        'Export flows need an explicit sequential stepper rather than a flat action row.',
  ),
  'volunteer-roster': LoomTabRendererContract(
    rendererId: 'VolunteerRosterTabSurface',
    label: 'Volunteer roster with live shift capacity',
    tabIds: ['roster'],
    surfaceFamilies: ['volunteerRoster'],
    requiredAnatomy: ['multiple shifts', 'capacity meter', 'sign-up action'],
    requiredInteractions: ['listVolunteerShifts', 'signUpForShift'],
    requiredStates: ['open capacity', 'partially filled', 'full'],
    evidenceRequirements: [
      'volunteer roster screenshot',
      'capacity update screenshot',
    ],
    fallbackPolicy:
        'Volunteer rosters require simultaneous shift visibility and live capacity, not a single selected shift.',
  ),
  'ai-search': LoomTabRendererContract(
    rendererId: 'AiSearchTabSurface',
    label: 'AI search with canned cited answers',
    tabIds: ['search'],
    surfaceFamilies: ['searchAiAnswer'],
    requiredAnatomy: ['query input', 'answer', 'citations', 'not-found state'],
    requiredInteractions: ['submitSearchQuery'],
    requiredStates: ['ready', 'answer found', 'no citation found'],
    evidenceRequirements: [
      'AI search answer screenshot',
      'no-citation screenshot',
    ],
    fallbackPolicy:
        'AI search requires a query-driven cited result, not static preview copy.',
  ),
  'audience-picker': LoomTabRendererContract(
    rendererId: 'AudiencePickerTabSurface',
    label: 'Audience picker with removable member chips',
    tabIds: ['audience'],
    surfaceFamilies: ['audiencePicker'],
    requiredAnatomy: ['selected member chips', 'checkable member list'],
    requiredInteractions: ['selectAudienceMember', 'deselectAudienceMember'],
    requiredStates: ['member selected', 'member not selected'],
    evidenceRequirements: ['audience picker screenshot'],
    fallbackPolicy:
        'Audience fields require structured persona IDs rather than comma-separated text.',
  ),
  'single-item-preference': LoomTabRendererContract(
    rendererId: 'SingleItemPreferenceTabSurface',
    label: 'Single-item preference with visibly exclusive selection',
    tabIds: ['preferences'],
    surfaceFamilies: ['singleItem'],
    requiredAnatomy: ['all preference options', 'selected option indicator'],
    requiredInteractions: ['setSinglePreference'],
    requiredStates: ['all-updates', 'event-updates', 'no-reminders'],
    evidenceRequirements: ['single-item preference screenshot'],
    fallbackPolicy:
        'Exclusive preferences require a grouped selection control rather than transition buttons.',
  ),
  'status-timeline': LoomTabRendererContract(
    rendererId: 'StatusTimelineTabSurface',
    label: 'Timestamped status timeline',
    tabIds: ['timeline'],
    surfaceFamilies: ['statusTimeline'],
    requiredAnatomy: ['vertical progression line', 'timestamped nodes'],
    requiredInteractions: ['viewStatusHistory'],
    requiredStates: ['chronological event history'],
    evidenceRequirements: ['timeline screenshot'],
    fallbackPolicy:
        'Status history must render as a visual timeline, not text rows.',
  ),
  'protected-detail': LoomTabRendererContract(
    rendererId: 'ProtectedDetailTabSurface',
    label: 'Protected detail with a distinct masked state',
    tabIds: ['details'],
    surfaceFamilies: ['protectedDetail'],
    requiredAnatomy: [
      'full detail',
      'locked masked detail',
      'why-hidden explanation',
    ],
    requiredInteractions: ['viewProtectedDetail'],
    requiredStates: ['authorized', 'masked'],
    evidenceRequirements: [
      'authorized detail screenshot',
      'masked detail screenshot',
    ],
    fallbackPolicy:
        'Protected content needs a visible lock treatment, not substituted text.',
  ),
  'form-entry-controls': LoomTabRendererContract(
    rendererId: 'FormEntryTabSurface',
    label: 'Form notification controls',
    tabIds: ['form'],
    surfaceFamilies: ['formEntry'],
    requiredAnatomy: ['checkbox', 'relative-time picker'],
    requiredInteractions: ['setNotificationsEnabled', 'setReminderOffset'],
    requiredStates: ['editing'],
    evidenceRequirements: ['form control screenshot'],
    fallbackPolicy: 'Form controls must persist typed values.',
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
    this.threads,
    this.notifications,
    this.exportWizard,
    this.volunteerShifts,
    this.aiSearchAnswers,
    this.audiencePicker,
    this.singleItemPreference,
    this.statusTimeline,
    this.protectedDetail,
    this.formEntry,
    this.marketplaceListings,
    this.marketplaceTemplate,
    this.themeOverride,
    this.calendarDateRailEntries,
    this.tabThemeOverrides = const {},
    this.creatableAction,
    this.notificationPresentation,
    this.tabCreatableActionStyles = const {},
    this.workflowDefinitions,
    this.workflowInstances,
  });

  final String extensionId;
  final String displayName;
  final String tagline;
  final int accentColor;
  final List<LoomWorkflowDefinition> workflows;
  final List<LoomPersonaDefinition>? personas;
  final Map<String, LoomWorkflowPersonaPolicy>? personaPolicies;
  final List<LoomMessageThread>? threads;
  final List<LoomNotificationItem>? notifications;
  final LoomExportWizardSeed? exportWizard;
  final List<LoomVolunteerShiftSeed>? volunteerShifts;
  final List<LoomAiSearchAnswer>? aiSearchAnswers;
  final LoomAudiencePickerSeed? audiencePicker;
  final LoomSingleItemPreferenceSeed? singleItemPreference;
  final LoomStatusTimelineSeed? statusTimeline;
  final LoomProtectedDetailSeed? protectedDetail;
  final LoomFormEntrySeed? formEntry;
  final List<LoomMarketplaceListing>? marketplaceListings;
  final LoomListingStateMachine? marketplaceTemplate;
  final LoomCardTheme? themeOverride;
  final List<CalendarDateRailEntry>? calendarDateRailEntries;
  final Map<String, LoomCardTheme> tabThemeOverrides;
  final LoomCreatableActionStyle? creatableAction;
  final LoomNotificationPresentation? notificationPresentation;
  final Map<String, LoomCreatableActionStyle> tabCreatableActionStyles;
  final Map<String, LoomWorkflowStateMachine>? workflowDefinitions;
  final List<LoomWorkflowSeedInstance>? workflowInstances;

  String get resolvedNotificationPresentationStyle =>
      notificationPresentation?.style ?? 'bell';
}

/// A declarative item in Calendar's per-day agenda date rail.
///
/// These fields intentionally mirror the community configuration exactly;
/// absent rails are resolved by the Calendar renderer for backwards
/// compatibility with its original two-item presentation.
class CalendarDateRailEntry {
  const CalendarDateRailEntry({
    this.kind,
    this.token,
    this.formula,
    this.style,
    this.colorSource,
  });

  final String? kind;
  final String? token;
  final String? formula;
  final String? style;
  final String? colorSource;
}

/// Community-wide or per-tab presentation defaults for `creatable` bindings.
/// The individual fields deliberately remain nullable: tab values cascade over
/// the corresponding community-wide field independently.
class LoomCreatableActionStyle {
  const LoomCreatableActionStyle({
    this.multiActionStyle,
    this.presentationStyle,
  });

  final String? multiActionStyle;
  final String? presentationStyle;

  factory LoomCreatableActionStyle.fromJson(Map<String, Object?> json) {
    return LoomCreatableActionStyle(
      multiActionStyle: json['multiActionStyle'] as String?,
      presentationStyle: json['presentationStyle'] as String?,
    );
  }
}

class LoomNotificationPresentation {
  const LoomNotificationPresentation({this.style});

  final String? style;

  factory LoomNotificationPresentation.fromJson(Map<String, Object?> json) {
    return LoomNotificationPresentation(style: json['style'] as String?);
  }
}

class LoomWorkflowSeedInstance {
  final String instanceId;
  final String workflowType;
  final String currentState;
  final Map<String, dynamic> instanceData;
  final String? createdByPersonaId;
  const LoomWorkflowSeedInstance({
    required this.instanceId,
    required this.workflowType,
    required this.currentState,
    required this.instanceData,
    this.createdByPersonaId,
  });
  factory LoomWorkflowSeedInstance.fromJson(Map<String, dynamic> json) =>
      LoomWorkflowSeedInstance(
        instanceId: json['instanceId'] as String,
        workflowType: json['workflowType'] as String,
        currentState: json['currentState'] as String,
        instanceData: json['instanceData'] is Map
            ? Map<String, dynamic>.from(json['instanceData'] as Map)
            : const {},
        createdByPersonaId: json['createdByPersonaId'] as String?,
      );
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
    this.accountId,
  });

  /// The persona TYPE id (e.g. `tabletop-member`) -- shared by every account
  /// playing that role. Use this for role/policy-scoped checks (tab
  /// visibility, `actorPersonaIds`/`byPersonaIds` matching against
  /// community-declared role lists).
  final String personaId;
  final String label;
  final String roleLabel;
  final String description;

  /// The specific signed-in individual account's id (e.g.
  /// `tabletop-member-03`), when signed in as a specific person via "Sign in
  /// as a specific person...". Null when only a persona TYPE is selected (no
  /// specific individual signed in) -- callers needing an actor id for
  /// per-individual engine scoping (queries/transitions/creation, anywhere
  /// data is genuinely scoped per account rather than per role) should read
  /// `accountId ?? personaId`, never `personaId` alone.
  final String? accountId;
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
