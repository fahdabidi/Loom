/// Card-surface families with a dedicated App Shell rendering path.
///
/// Six dispatch per instance in `EngineNativeArchetypeCard`. `table` dispatches
/// one level higher in `EngineNativeListSurface` because its widget consumes a
/// group of instances rather than one instance at a time.
const Set<String> supportedAppShellBespokeCardSurfaceFamilies = <String>{
  'event-rsvp',
  'votePoll',
  'equipment-loan',
  'table',
  'documentLibrary',
  'searchAiAnswer',
  'exportWizard',
};

/// Card-surface families intentionally rendered by
/// `GenericWorkflowInstanceCard`.
const Set<String> supportedAppShellGenericCardSurfaceFamilies = <String>{
  'paymentCheckout',
  'approvalQueueItem',
  'formEntry',
  'discussionThread',
  'statusTimeline',
  'notificationInbox',
};

/// Renderer contracts with an implemented branch in `_TabNativeRenderer`.
///
/// The map binds the package-facing `rendererContractId` to the renderer's
/// internal implementation id. Registry entries omitted from this map are
/// documentation/catalog entries only and currently fall through to Home.
const Map<String, String> supportedAppShellTabRendererContracts =
    <String, String>{
      'home-surface-stack': 'HomeTabSurfaceStack',
      'engine-native-generic-list': 'EngineNativeGenericListSurface',
      'calendar-agenda-event-detail': 'CalendarTabSurface',
      'messages-inbox-thread-composer': 'MessagesTabSurface',
      'notification-inbox-engine-native': 'NotificationDedicatedTabSurface',
      'marketplace-browse-listing-detail': 'MarketplaceTabSurface',
      'payment-giving-ledger': 'PaymentGivingTabSurface',
      'documents-library-detail': 'DocumentsTabSurface',
      'workflow-status-timeline-actions': 'WorkflowStatusSurface',
      'care-volunteer-request-queue': 'CareVolunteerTabSurface',
      'admin-review-compose-queue': 'AdminReviewComposeTabSurface',
    };

/// The archetypes with a dedicated whole-tab App Shell surface.
///
/// Every other archetype belongs in `EngineNativeListSurface`, which performs
/// the live tab query and dispatches each instance to its card-level renderer.
/// This map is deliberately keyed by archetype, never by the community-owned
/// tab id.
const Map<String, String> appShellTabNativeRendererContractIdsByArchetype =
    <String, String>{
      'event-rsvp': 'calendar-agenda-event-detail',
      'equipment-loan': 'marketplace-browse-listing-detail',
    };

/// Default when a tab does not bind exactly one tab-native archetype.
const String defaultAppShellTabRendererContractId =
    'engine-native-generic-list';

/// Layout styles implemented when a tab contributes multiple create FABs.
const String appShellFabStyleSpeedDial = 'speedDial';
const String appShellFabStyleStacked = 'stacked';
const String appShellFabStyleSingleFirst = 'singleFirst';

const Set<String> supportedAppShellFabStyles = <String>{
  appShellFabStyleSpeedDial,
  appShellFabStyleStacked,
  appShellFabStyleSingleFirst,
};

/// Presentation modes implemented for forms launched from create actions.
const String appShellPresentationModePopup = 'popup';
const String appShellPresentationModeSlideOutBottom = 'slideOutBottom';
const String appShellPresentationModeSlideOutLeft = 'slideOutLeft';
const String appShellPresentationModeSlideOutRight = 'slideOutRight';

const Set<String> supportedAppShellPresentationModes = <String>{
  appShellPresentationModePopup,
  appShellPresentationModeSlideOutBottom,
  appShellPresentationModeSlideOutLeft,
  appShellPresentationModeSlideOutRight,
};
