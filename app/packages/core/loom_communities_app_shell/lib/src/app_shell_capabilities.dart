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

/// Fallback when an absent `rendererContractId` cannot be derived from the
/// tab's render bindings.
const String defaultAppShellTabRendererContractId =
    'engine-native-generic-list';

/// Open-vocabulary tab ids whose semantics are special-cased by an implemented
/// renderer contract. All other declared ids use the generic list pipeline.
const Set<String> specialCasedAppShellTabIds = <String>{
  'home',
  'messages',
  'calendar',
  'notification-inbox',
  'marketplace',
  'giving',
  'documents',
  'care',
  'admin',
};

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
