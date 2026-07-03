part of '../loom_communities_app_shell.dart';

LoomWorkflowCardSurfaceRegistryEntry _cardSurfaceRegistryEntryForWorkflowId(
  String workflowId,
) {
  final id = workflowId.toLowerCase();
  if (id.contains('announcement') ||
      id.contains('publish') ||
      id.contains('notification')) {
    return _registryEntry(
      workflowId: workflowId,
      cardSurfaceFamily: 'announcement',
      apiContract: 'CommunityAnnouncementApi',
      requiredInteractions: const [
        'createDraft',
        'updateDraft',
        'previewAnnouncement',
        'scheduleAnnouncement',
        'publishAnnouncement',
        'cancelScheduledAnnouncement',
        'updatePublishedAnnouncement',
        'unpublishAnnouncement',
        'deliveryStatus',
        'readReceipts',
        'revisionHistory',
      ],
      primaryActions: const ['Save draft', 'Preview', 'Publish', 'Schedule'],
      alternateActions: const ['Edit published update', 'Unpublish'],
    );
  }
  if (id.contains('ad-off')) {
    if (id.contains('settlement')) {
      return _registryEntry(
        workflowId: workflowId,
        cardSurfaceFamily: 'ad-off-settlement',
        apiContract: 'CommunityAdOffSettlementApi',
        requiredInteractions: const [
          'calculateUtilityAllocation',
          'getSettlementRecord',
          'reviewSettlement',
          'correctAllocation',
          'rollbackSettlement',
          'exportSettlementAudit',
          'memberSettlementVisibility',
        ],
        primaryActions: const ['Review settlement', 'Export audit'],
        alternateActions: const ['Correct allocation', 'Rollback'],
      );
    }
    return _registryEntry(
      workflowId: workflowId,
      cardSurfaceFamily: 'ad-off-entitlement',
      apiContract: 'CommunityAdOffEntitlementApi',
      requiredInteractions: const [
        'startCheckout',
        'confirmEntitlement',
        'restoreEntitlement',
        'manageSubscription',
        'openReceipt',
        'listSuppressedAdSlots',
        'verifyNoFillReason',
        'renewOrCancel',
      ],
      primaryActions: const [
        'Activate ad-free',
        'Manage subscription',
        'Restore purchase',
      ],
      alternateActions: const ['Open receipt', 'View suppressed slots'],
    );
  }
  if (id.contains('ad-off') ||
      id.contains('payment') ||
      id.contains('donation') ||
      id.contains('dues') ||
      id.contains('checkout')) {
    return _registryEntry(
      workflowId: workflowId,
      cardSurfaceFamily: 'payment',
      apiContract: 'CommunityPaymentSurfaceApi',
      requiredInteractions: const [
        'createPaymentIntent',
        'confirmPayment',
        'recordFailure',
        'retryPayment',
        'refund',
        'createRecurringPlan',
        'manageRecurringPlan',
        'setDonorVisibility',
        'getReceipt',
        'getEntitlement',
        'settlementStatus',
      ],
      primaryActions: const ['Pay', 'Confirm', 'Manage subscription'],
      alternateActions: const ['Retry', 'Refund', 'Open receipt'],
    );
  }
  if (id.contains('rsvp') ||
      id.contains('event') ||
      id.contains('practice') ||
      id.contains('schedule') ||
      id.contains('photo-walk')) {
    return _registryEntry(
      workflowId: workflowId,
      cardSurfaceFamily: 'event-rsvp',
      apiContract: 'CommunityEventRsvpApi',
      requiredInteractions: const [
        'getEventDetail',
        'respondGoingMaybeNo',
        'changeRsvp',
        'cancelRsvp',
        'joinWaitlist',
        'listAttendees',
        'updateCapacity',
        'sendReminder',
        'calendarState',
        'cancelOrReschedule',
      ],
      primaryActions: const ['Going', 'Maybe', 'Not going'],
      alternateActions: const ['Change response', 'Cancel RSVP'],
    );
  }
  if (id.contains('volunteer') || id.contains('shift')) {
    return _registryEntry(
      workflowId: workflowId,
      cardSurfaceFamily: 'volunteer',
      apiContract: 'CommunityVolunteerApi',
      requiredInteractions: const [
        'listShifts',
        'signup',
        'updateAvailability',
        'cancelSignup',
        'joinWaitlist',
        'listVolunteers',
        'volunteerSummary',
        'assignCoordinator',
        'checkInVolunteer',
        'markNoShow',
        'protectedContactReveal',
      ],
      primaryActions: const ['Sign up', 'Edit availability', 'Confirm in'],
      alternateActions: const ['Cancel signup', 'View volunteers'],
    );
  }
  if (id.contains('plant') || id.contains('exchange')) {
    return _registryEntry(
      workflowId: workflowId,
      cardSurfaceFamily: 'exchange',
      apiContract: 'CommunityExchangeApi',
      requiredInteractions: const [
        'createOffer',
        'updateOffer',
        'cancelOffer',
        'claimOffer',
        'cancelClaim',
        'markUnavailable',
        'schedulePickup',
        'handoffComplete',
        'listClaims',
        'privacyScopedContact',
      ],
      primaryActions: const ['Offer item', 'Claim', 'Schedule pickup'],
      alternateActions: const ['Edit offer', 'Cancel claim'],
    );
  }
  if (id.contains('equipment') ||
      id.contains('gear') ||
      id.contains('loan') ||
      id.contains('racquet')) {
    return _registryEntry(
      workflowId: workflowId,
      cardSurfaceFamily: 'equipment-loan',
      apiContract: 'CommunityEquipmentLoanApi',
      requiredInteractions: const [
        'offerEquipment',
        'requestLoan',
        'approveLoan',
        'declineLoan',
        'schedulePickup',
        'checkOut',
        'returnItem',
        'cancelLoan',
        'listAvailability',
        'privacyScopedContact',
      ],
      primaryActions: const ['Offer equipment', 'Request loan', 'Confirm out'],
      alternateActions: const ['Return item', 'Cancel loan'],
    );
  }
  if (id.contains('nomination')) {
    return _registryEntry(
      workflowId: workflowId,
      cardSurfaceFamily: 'nomination',
      apiContract: 'CommunityNominationApi',
      requiredInteractions: const [
        'createNomination',
        'updateNomination',
        'withdrawNomination',
        'listNominations',
        'detectDuplicate',
        'checkEligibility',
        'linkToBallot',
        'nominationStatus',
      ],
      primaryActions: const ['Nominate', 'Edit nomination'],
      alternateActions: const ['Withdraw nomination'],
    );
  }
  if (id.contains('vote') || id.contains('ballot') || id.contains('poll')) {
    return _registryEntry(
      workflowId: workflowId,
      cardSurfaceFamily: 'vote',
      apiContract: 'CommunityVoteApi',
      requiredInteractions: const [
        'openBallot',
        'castVote',
        'changeVote',
        'clearVote',
        'getVoteState',
        'getResults',
        'publishSelection',
        'auditVote',
      ],
      primaryActions: const ['Vote', 'Change vote'],
      alternateActions: const ['Clear vote', 'View results'],
    );
  }
  if (id.contains('message') ||
      id.contains('discussion') ||
      id.contains('thread')) {
    return _registryEntry(
      workflowId: workflowId,
      cardSurfaceFamily: 'thread',
      apiContract: 'CommunityThreadApi',
      requiredInteractions: const [
        'createThread',
        'reply',
        'editMessage',
        'deleteMessage',
        'markRead',
        'listUnread',
        'muteThread',
        'archiveThread',
        'attachMedia',
        'mentionMember',
      ],
      primaryActions: const ['Reply', 'Mark read'],
      alternateActions: const ['Edit', 'Mute', 'Archive'],
    );
  }
  if (id.contains('care')) {
    return _registryEntry(
      workflowId: workflowId,
      cardSurfaceFamily: 'care-request',
      apiContract: 'CommunityCareRequestApi',
      requiredInteractions: const [
        'createRequest',
        'updateRequest',
        'withdrawRequest',
        'assignCareTeam',
        'reviewRequest',
        'requestChanges',
        'resolveRequest',
        'neutralNotification',
        'readPublicSummary',
        'readProtectedDetails',
        'redactedAudit',
      ],
      primaryActions: const ['Request care', 'Assign care team', 'Resolve'],
      alternateActions: const ['Update request', 'Withdraw'],
    );
  }
  if (id.contains('approval') ||
      id.contains('decision') ||
      id.contains('architectural') ||
      id.contains('request')) {
    return _registryEntry(
      workflowId: workflowId,
      cardSurfaceFamily: 'approval',
      apiContract: 'CommunityApprovalApi',
      requiredInteractions: const [
        'submitRequest',
        'assignReviewer',
        'approve',
        'reject',
        'requestChanges',
        'comment',
        'statusHistory',
        'reopen',
        'appeal',
        'notifyRequester',
      ],
      primaryActions: const ['Approve', 'Reject', 'Request changes'],
      alternateActions: const ['Comment', 'Reopen', 'Appeal'],
    );
  }
  if (id.contains('document') ||
      id.contains('facility') ||
      id.contains('reservation') ||
      id.contains('roster')) {
    return _registryEntry(
      workflowId: workflowId,
      cardSurfaceFamily: 'operations',
      apiContract: 'CommunityOperationsSurfaceApi',
      requiredInteractions: const [
        'listDocuments',
        'openDocument',
        'downloadDocument',
        'acknowledgeDocument',
        'requestAccess',
        'documentVersions',
        'reserveFacility',
        'updateReservation',
        'cancelReservation',
        'resolveConflict',
        'getRoster',
        'updateRosterMember',
        'rosterHistory',
      ],
      primaryActions: const ['Open', 'Reserve', 'Acknowledge'],
      alternateActions: const ['Cancel reservation', 'Request access'],
    );
  }
  if (id.contains('search') ||
      id.contains('digest') ||
      id.contains('citation')) {
    return _registryEntry(
      workflowId: workflowId,
      cardSurfaceFamily: 'knowledge',
      apiContract: 'CommunityKnowledgeSurfaceApi',
      requiredInteractions: const [
        'search',
        'answerQuestion',
        'listCitations',
        'openCitation',
        'saveDigest',
        'shareDigest',
        'refreshIndex',
        'staleCitationCheck',
        'visibilityDecision',
      ],
      primaryActions: const ['Search', 'Open citation', 'Save digest'],
      alternateActions: const ['Share', 'Refresh index'],
    );
  }
  if (id.contains('export') ||
      id.contains('import') ||
      id.contains('transfer') ||
      id.contains('redaction') ||
      id.contains('rollback') ||
      id.contains('checksum')) {
    return _registryEntry(
      workflowId: workflowId,
      cardSurfaceFamily: 'portability',
      apiContract: 'CommunityPortabilitySurfaceApi',
      requiredInteractions: const [
        'createExportPlan',
        'previewRedaction',
        'generateExport',
        'downloadExport',
        'verifyChecksum',
        'cancelExport',
        'retryExport',
        'startTransfer',
        'verifyTransfer',
        'rollbackTransfer',
        'auditTrail',
      ],
      primaryActions: const ['Generate export', 'Download', 'Start transfer'],
      alternateActions: const ['Preview redaction', 'Cancel', 'Retry'],
    );
  }
  if (id.contains('invite') ||
      id.contains('connection') ||
      id.contains('social')) {
    return _registryEntry(
      workflowId: workflowId,
      cardSurfaceFamily: 'social',
      apiContract: 'CommunitySocialSurfaceApi',
      requiredInteractions: const [
        'sendInvite',
        'acceptInvite',
        'declineInvite',
        'cancelInvite',
        'block',
        'unblock',
        'mute',
        'archive',
        'connectionStatus',
        'createThread',
        'reply',
        'markRead',
      ],
      primaryActions: const ['Invite', 'Accept', 'Reply'],
      alternateActions: const ['Decline', 'Block', 'Mute'],
    );
  }
  if (id.contains('ad') || id.contains('sponsor')) {
    return _registryEntry(
      workflowId: workflowId,
      cardSurfaceFamily: 'ad',
      apiContract: 'CommunityAdSurfaceApi',
      requiredInteractions: const [
        'requestAdDecision',
        'recordImpression',
        'recordClick',
        'recordNoFill',
        'getNoFillReason',
        'getDisclosure',
        'getAdOffEntitlement',
        'suppressAds',
        'restoreAds',
        'receiptEvidence',
      ],
      primaryActions: const ['Open sponsor', 'Turn off ads'],
      alternateActions: const ['Restore ads', 'View disclosure'],
    );
  }
  return _registryEntry(
    workflowId: workflowId,
    cardSurfaceFamily: 'form',
    apiContract: 'CommunityFormSurfaceApi',
    requiredInteractions: const [
      'loadForm',
      'validateDraft',
      'saveDraft',
      'submitForm',
      'updateSubmission',
      'withdrawSubmission',
      'routeProtectedFields',
      'reviewSubmission',
      'exportSubmission',
    ],
    primaryActions: const ['Save draft', 'Submit', 'Update'],
    alternateActions: const ['Withdraw', 'Open details'],
  );
}

LoomWorkflowCardSurfaceRegistryEntry _registryEntry({
  required String workflowId,
  required String cardSurfaceFamily,
  required String apiContract,
  required List<String> requiredInteractions,
  required List<String> primaryActions,
  required List<String> alternateActions,
}) {
  return LoomWorkflowCardSurfaceRegistryEntry(
    workflowId: workflowId,
    cardSurfaceFamily: cardSurfaceFamily,
    apiContract: apiContract,
    requiredInteractions: requiredInteractions,
    primaryActions: primaryActions,
    alternateActions: alternateActions,
    rendererTarget: '',
    fakeBackendSupport:
        'LocalInAppBackend imports the initialization package, stores workflow state, records persona-specific receipts, and exposes the state used by this surface in the Demo App.',
  );
}

String _routeTemplateForSurfaceFamily(String cardSurfaceFamily) {
  switch (cardSurfaceFamily) {
    case 'calendar':
    case 'event-rsvp':
    case 'member-meetup':
      return '/calendar/:workflowId';
    case 'thread':
    case 'social':
    case 'inbox':
      return '/messages/:workflowId';
    case 'equipment-loan':
    case 'exchange':
      return '/marketplace/:workflowId';
    case 'documents':
    case 'external-document-link':
    case 'operations':
    case 'portability':
      return '/documents/:workflowId';
    case 'workflow-status':
    case 'approval':
    case 'form':
      return '/workflows/:workflowId';
    case 'payment':
    case 'ad-off-entitlement':
    case 'ad-off-settlement':
      return '/giving/:workflowId';
    case 'care-request':
    case 'volunteer':
      return '/care/:workflowId';
    case 'announcement':
    case 'ad':
      return '/admin/:workflowId';
  }
  return '/workflows/:workflowId';
}

String _rendererTargetForWorkflow({
  required String extensionId,
  required String workflowId,
}) {
  final entry = _cardSurfaceRegistryEntryForWorkflowId(workflowId);
  final rendererContract = tabRendererContractFor(
    _rendererContractIdForSurfaceFamily(entry.cardSurfaceFamily),
  );
  final surfaceRenderer = _surfaceRendererNameForSurfaceFamily(
    entry.cardSurfaceFamily,
  );
  if (extensionId == 'ext_garden_club' && workflowId == 'garden-event-rsvp') {
    return '${rendererContract.rendererId}/$surfaceRenderer + _GardenEventRsvpActionSurface';
  }
  if (extensionId == 'ext_garden_club' &&
      workflowId == 'plant-exchange-submission') {
    return '${rendererContract.rendererId}/$surfaceRenderer + _GardenPlantExchangeActionSurface';
  }
  if (_richWorkflowSpecFor(workflowId) != null) {
    return '${rendererContract.rendererId}/$surfaceRenderer + _RichWorkflowActionSurface';
  }
  return '${rendererContract.rendererId}/$surfaceRenderer + _WorkflowActionSurface';
}

String _rendererContractIdForSurfaceFamily(String cardSurfaceFamily) {
  switch (cardSurfaceFamily) {
    case 'calendar':
    case 'event-rsvp':
    case 'member-meetup':
      return 'calendar-agenda-event-detail';
    case 'thread':
    case 'social':
    case 'inbox':
      return 'messages-inbox-thread-composer';
    case 'equipment-loan':
    case 'exchange':
      return 'marketplace-browse-listing-detail';
    case 'documents':
    case 'external-document-link':
    case 'operations':
    case 'portability':
      return 'documents-library-detail';
    case 'workflow-status':
    case 'approval':
    case 'form':
      return 'workflow-status-timeline-actions';
    case 'payment':
    case 'ad-off-entitlement':
    case 'ad-off-settlement':
      return 'payment-giving-ledger';
    case 'care-request':
    case 'volunteer':
      return 'care-volunteer-request-queue';
    case 'announcement':
    case 'ad':
      return 'admin-review-compose-queue';
  }
  return 'home-surface-stack';
}

String _surfaceRendererNameForSurfaceFamily(String cardSurfaceFamily) {
  switch (cardSurfaceFamily) {
    case 'calendar':
      return 'CalendarItemRenderer';
    case 'event-rsvp':
      return 'EventRsvpDetailRenderer';
    case 'member-meetup':
      return 'MeetupDetailRenderer';
    case 'thread':
      return 'ThreadPreviewRenderer';
    case 'social':
      return 'ConnectionInviteRenderer';
    case 'inbox':
      return 'InboxItemRenderer';
    case 'equipment-loan':
      return 'MarketplaceListingDetailRenderer';
    case 'exchange':
      return 'ExchangeOfferRenderer';
    case 'documents':
      return 'DocumentDetailRenderer';
    case 'external-document-link':
      return 'ExternalDocumentRenderer';
    case 'operations':
      return 'OperationsRecordRenderer';
    case 'portability':
      return 'PortabilityStatusRenderer';
    case 'workflow-status':
      return 'WorkflowStatusTimelineRenderer';
    case 'approval':
      return 'ApprovalRequestTimelineRenderer';
    case 'form':
      return 'FormSubmissionStatusRenderer';
    case 'payment':
      return 'PaymentReceiptRenderer';
    case 'ad-off-entitlement':
      return 'AdOffEntitlementRenderer';
    case 'ad-off-settlement':
      return 'AdOffSettlementRenderer';
    case 'care-request':
      return 'CareRequestDetailRenderer';
    case 'volunteer':
      return 'VolunteerShiftRenderer';
    case 'announcement':
      return 'AnnouncementComposerRenderer';
    case 'ad':
      return 'SponsoredPlacementRenderer';
  }
  return 'SurfaceStackRenderer';
}

List<String> productionUxGenericCopyViolations() {
  const banned = [
    'Community workflows',
    'Complete workflow',
    'Can perform this workflow',
    'Action available for this role',
    'Receives the result',
    'Uses ',
    ' surface',
    'App Shell',
    'Shell-owned',
    'Workflow result',
    'workflow evidence',
    'evidence',
    'Workflow checklist',
    'local route',
    'workflow route',
  ];
  LoomPersonaWorkflowView viewFor(
    LoomPersonaWorkflowState state, {
    bool waiting = false,
  }) {
    return LoomPersonaWorkflowView(
      state: state,
      completed: false,
      received: false,
      waitingForPrerequisite: waiting,
      entryText: '',
      actionText: '',
      resultText: '',
      personaRationale: '',
      waitingText: '',
    );
  }

  final surfaces = <String>[
    for (final title in _orderedSectionTitles) title,
    for (final target in loomEvidenceTargets)
      for (final section in _communitySectionsFor(
        experienceForExtensionId(target.extensionId),
      )) ...[
        section.title,
        section.subtitle,
        for (final workflow in section.workflows) ...[
          _displayTitleFor(workflow),
          _domainSummaryFor(
            _workflowCategoryFor(workflow),
            workflow,
            viewFor(LoomPersonaWorkflowState.actor),
          ),
          _domainSummaryFor(
            _workflowCategoryFor(workflow),
            workflow,
            viewFor(LoomPersonaWorkflowState.receiver),
          ),
          _domainSummaryFor(
            _workflowCategoryFor(workflow),
            workflow,
            viewFor(LoomPersonaWorkflowState.readOnly),
          ),
          _domainSummaryFor(
            _workflowCategoryFor(workflow),
            workflow,
            viewFor(LoomPersonaWorkflowState.disabled),
          ),
          _domainSummaryFor(
            _workflowCategoryFor(workflow),
            workflow,
            viewFor(LoomPersonaWorkflowState.actor, waiting: true),
          ),
          ..._domainMetadataFor(_workflowCategoryFor(workflow), workflow),
          _reviewDetailFor(_workflowCategoryFor(workflow)),
          _reviewCheckFor(_workflowCategoryFor(workflow)),
          _reviewResultFor(_workflowCategoryFor(workflow)),
          _reviewTrustFor(_workflowCategoryFor(workflow)),
          productionWorkflowContractFor(
            extensionId: target.extensionId,
            workflow: workflow,
          ).surfaceLabel,
          productionWorkflowContractFor(
            extensionId: target.extensionId,
            workflow: workflow,
          ).screenTitle,
          productionWorkflowContractFor(
            extensionId: target.extensionId,
            workflow: workflow,
          ).primaryActionLabel,
          productionWorkflowContractFor(
            extensionId: target.extensionId,
            workflow: workflow,
          ).alternateActionLabel,
          productionWorkflowContractFor(
            extensionId: target.extensionId,
            workflow: workflow,
          ).decisionSummary,
          productionWorkflowContractFor(
            extensionId: target.extensionId,
            workflow: workflow,
          ).inputSummary,
          productionWorkflowContractFor(
            extensionId: target.extensionId,
            workflow: workflow,
          ).validationSummary,
          productionWorkflowContractFor(
            extensionId: target.extensionId,
            workflow: workflow,
          ).resultSummary,
          productionWorkflowContractFor(
            extensionId: target.extensionId,
            workflow: workflow,
          ).receiverStateSummary,
          productionWorkflowContractFor(
            extensionId: target.extensionId,
            workflow: workflow,
          ).successTitle,
          productionWorkflowContractFor(
            extensionId: target.extensionId,
            workflow: workflow,
          ).successChipLabel,
          productionWorkflowContractFor(
            extensionId: target.extensionId,
            workflow: workflow,
          ).receiverSurfaceTitle,
          productionWorkflowContractFor(
            extensionId: target.extensionId,
            workflow: workflow,
          ).trustSummary,
        ],
      ],
    _rationaleForState(
      LoomPersonaWorkflowState.actor,
      const LoomWorkflowPersonaPolicy(actorPersonaIds: ['actor']),
    ),
    _rationaleForState(
      LoomPersonaWorkflowState.receiver,
      const LoomWorkflowPersonaPolicy(actorPersonaIds: ['actor']),
    ),
    _rationaleForState(
      LoomPersonaWorkflowState.readOnly,
      const LoomWorkflowPersonaPolicy(actorPersonaIds: ['actor']),
    ),
    _entryTextForState(
      state: LoomPersonaWorkflowState.readOnly,
      workflow: experienceForExtensionId('unknown').workflows.first,
      policy: const LoomWorkflowPersonaPolicy(actorPersonaIds: ['actor']),
      waiting: false,
    ),
    _entryTextForState(
      state: LoomPersonaWorkflowState.actor,
      workflow: experienceForExtensionId('unknown').workflows.first,
      policy: const LoomWorkflowPersonaPolicy(actorPersonaIds: ['actor']),
      waiting: true,
    ),
  ];
  return [
    for (final surface in surfaces)
      for (final bannedText in banned)
        if (surface.toLowerCase().contains(bannedText.toLowerCase()))
          '$bannedText -> $surface',
  ];
}

