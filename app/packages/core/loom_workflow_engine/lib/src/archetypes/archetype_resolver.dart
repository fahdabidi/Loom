/// Archetype and action resolution for permission derivation.
///
/// This is the single machine-readable implementation of
/// `docs/references/reference/permissions.md` §4, §5 and §6 step 3. Both the
/// community package validator and the install-time permission installer must
/// import it rather than re-deriving the rules, because this repo has twice
/// been broken by the same failure: the same rules written down in more than
/// one place, drifting apart silently.
///
/// The vocabularies below are the source of truth for machines; permissions.md
/// is the source of truth for humans and authoring agents. They are kept in
/// step by `test/archetype_resolver_spec_sync_test.dart`, which parses the
/// document and fails if either side gains, loses, or renames an action.
library;

/// How a workflow's archetype was determined, per §6 step 3.
enum ArchetypeOrigin {
  /// 3a — a `renderBindings[].cardSurfaceFamily` names a bespoke family.
  declaredBespoke,

  /// 3b — inherited from the binding whose `responseTable.workflowType` names
  /// this workflow. RSVP response rows reach their archetype this way.
  inheritedFromResponseTable,

  /// 3c — no bespoke family; permissions derive structurally from §5.
  generic,

  /// 3d — no bindings and no `responseTable` owner. Derives nothing at all.
  none,
}

/// The archetype of one workflow, and how it was arrived at.
class ResolvedArchetype {
  const ResolvedArchetype({
    required this.family,
    required this.origin,
    this.inheritedFrom,
    this.conflictingBespokeFamilies = const <String>[],
  });

  /// The `cardSurfaceFamily` that governs this workflow, or null for
  /// [ArchetypeOrigin.none].
  final String? family;

  final ArchetypeOrigin origin;

  /// For [ArchetypeOrigin.inheritedFromResponseTable], the workflow type that
  /// owns the binding this archetype came from.
  final String? inheritedFrom;

  /// Set when two or more *bespoke* families are named by one workflow's
  /// bindings, which §8 treats as an error because the archetype is then
  /// genuinely undecidable. Mixing one bespoke family with generic ones is
  /// normal and is not reported here.
  final List<String> conflictingBespokeFamilies;

  bool get isBespoke =>
      origin == ArchetypeOrigin.declaredBespoke ||
      origin == ArchetypeOrigin.inheritedFromResponseTable;

  bool get requiresAction => isBespoke;
}

/// How a read decision is reached for one archetype's instances.
///
/// Every model is additive over `roles` and every model **fails closed**: an
/// unset identity field matches nobody, so an instance belonging to no one is
/// visible to no one. That is why seed data carrying no identity renders
/// nothing rather than leaking.
enum VisibilityModel {
  /// Only the roles a state's `readGuard` admits.
  roles,

  /// Plus whoever created the instance.
  owner,

  /// Plus anyone the instance was explicitly shared with.
  ownerAndShared,

  /// Plus anyone in the instance's participant set.
  participants,

  /// Plus the two named sides of a request.
  parties,

  /// Plus the addressee, and only the addressee.
  recipient,
}

/// Where an archetype's rules are actually enforced today.
enum EnforcementBoundary {
  /// Evaluated by `LocalWorkflowEngineApi` on the device, over local sqlite.
  /// Advisory: correct for the UI, but not a security boundary, because no
  /// server evaluates it. There is no workflow service yet.
  clientEngine,

  /// Evaluated by a real backend service.
  server,
}

/// What one archetype guarantees, as opposed to what a community declares.
///
/// This is the machine-readable form of `docs/references/archetypes/CONTRACTS.md`,
/// read by the validator today and by the workflow service once it exists.
class ArchetypeContract {
  const ArchetypeContract({
    required this.family,
    required this.isBespoke,
    required this.bookkeeping,
    required this.visibility,
    required this.enforcement,
    this.placement = const <String>{},
    this.sharingGrantable = const <String>{},
  });

  final String family;

  /// Bespoke archetypes carry a closed action vocabulary that supplies
  /// semantics. Generic ones derive everything structurally.
  final bool isBespoke;

  /// Per-person state the archetype maintains itself. A community declares
  /// none of these fields and writes no idempotence guard against them.
  final Set<String> bookkeeping;

  final VisibilityModel visibility;

  final EnforcementBoundary enforcement;

  /// Transition ids given a position other than the generic button row. Only
  /// `equipment-loan` has any, and only for layout — legality always comes
  /// from `availableTransitionsAsync`.
  final Set<String> placement;

  /// Actions a share may grant, for archetypes whose visibility model supports
  /// sharing.
  final Set<String> sharingGrantable;

  /// Community-defined actions are permitted on every archetype. A transition
  /// that declares no `action` derives structurally and renders in the generic
  /// button row.
  bool get allowsCustomActions => true;
}

/// One permission-bearing action in an archetype or governance vocabulary.
///
/// Keeping the user-facing catalog text with the action identifier makes the
/// resolver the single source of truth for both permission derivation and
/// permission presentation. The required fields deliberately make an action
/// without a display name or description a compile-time error.
class ArchetypeAction {
  const ArchetypeAction({
    required this.id,
    required this.displayName,
    required this.description,
  });

  /// The action portion of a permission id, for example `respond`.
  final String id;

  /// A concise, user-facing verb phrase for permission catalogs.
  final String displayName;

  /// A one-line explanation of what granting this action permits.
  final String description;
}

/// Resolves archetypes and maps actions to permission ids.
class ArchetypeResolver {
  const ArchetypeResolver();

  /// The full contract per archetype. See
  /// `docs/references/archetypes/CONTRACTS.md`.
  static const Map<String, ArchetypeContract> contracts = {
    'documentLibrary': ArchetypeContract(
      family: 'documentLibrary',
      isBespoke: true,
      bookkeeping: {
        'openedFanIds',
        'acknowledgedFanIds',
        'savedFanIds',
        'downloadedFanIds',
        'accessRequestedFanIds',
        'sharedWithFanIds',
      },
      visibility: VisibilityModel.ownerAndShared,
      sharingGrantable: {'open', 'download', 'edit'},
      enforcement: EnforcementBoundary.clientEngine,
    ),
    'equipment-loan': ArchetypeContract(
      family: 'equipment-loan',
      isBespoke: true,
      bookkeeping: {'queuedFanIds', 'currentHolderFanId'},
      visibility: VisibilityModel.owner,
      // The only placement in the app shell: six ids matched by name in
      // part36, purely to position them.
      placement: {
        'borrow',
        'claim',
        'join-queue',
        'leave-queue',
        'return',
        'return-game',
      },
      enforcement: EnforcementBoundary.clientEngine,
    ),
    'calendar': ArchetypeContract(
      family: 'calendar',
      isBespoke: true,
      // Only reminders. No attendance arrays, because nobody attends a
      // calendar item -- a community wanting those has picked the wrong family.
      bookkeeping: {'reminderFanIds'},
      visibility: VisibilityModel.owner,
      enforcement: EnforcementBoundary.clientEngine,
    ),
    'event-rsvp': ArchetypeContract(
      family: 'event-rsvp',
      isBespoke: true,
      bookkeeping: {
        'goingFanIds',
        'maybeFanIds',
        'notGoingFanIds',
        'waitlistFanIds',
        'reminderFanIds',
      },
      visibility: VisibilityModel.owner,
      enforcement: EnforcementBoundary.clientEngine,
    ),
    'exportWizard': ArchetypeContract(
      family: 'exportWizard',
      isBespoke: true,
      bookkeeping: {},
      visibility: VisibilityModel.owner,
      enforcement: EnforcementBoundary.clientEngine,
    ),
    'searchAiAnswer': ArchetypeContract(
      family: 'searchAiAnswer',
      isBespoke: true,
      bookkeeping: {'savedFanIds'},
      visibility: VisibilityModel.owner,
      enforcement: EnforcementBoundary.clientEngine,
    ),
    'votePoll': ArchetypeContract(
      family: 'votePoll',
      isBespoke: true,
      // Who has voted, never how they voted. Tallies are derived.
      bookkeeping: {'votedFanIds'},
      visibility: VisibilityModel.roles,
      enforcement: EnforcementBoundary.clientEngine,
    ),
    'approvalQueueItem': ArchetypeContract(
      family: 'approvalQueueItem',
      isBespoke: false,
      bookkeeping: {},
      visibility: VisibilityModel.parties,
      enforcement: EnforcementBoundary.clientEngine,
    ),
    'formEntry': ArchetypeContract(
      family: 'formEntry',
      isBespoke: false,
      bookkeeping: {},
      visibility: VisibilityModel.owner,
      enforcement: EnforcementBoundary.clientEngine,
    ),
    'discussionThread': ArchetypeContract(
      family: 'discussionThread',
      isBespoke: false,
      bookkeeping: {'readByFanIds', 'mutedByFanIds'},
      visibility: VisibilityModel.participants,
      enforcement: EnforcementBoundary.clientEngine,
    ),
    'notificationInbox': ArchetypeContract(
      family: 'notificationInbox',
      isBespoke: false,
      bookkeeping: {
        'dismissedByFanIds',
        'clickedByFanIds',
        'impressionedByFanIds',
        'acknowledgedByFanIds',
      },
      visibility: VisibilityModel.recipient,
      enforcement: EnforcementBoundary.clientEngine,
    ),
    'paymentCheckout': ArchetypeContract(
      family: 'paymentCheckout',
      isBespoke: false,
      bookkeeping: {},
      visibility: VisibilityModel.parties,
      enforcement: EnforcementBoundary.clientEngine,
    ),
    'statusTimeline': ArchetypeContract(
      family: 'statusTimeline',
      isBespoke: false,
      bookkeeping: {},
      visibility: VisibilityModel.roles,
      enforcement: EnforcementBoundary.clientEngine,
    ),
    'table': ArchetypeContract(
      family: 'table',
      isBespoke: false,
      bookkeeping: {},
      visibility: VisibilityModel.owner,
      enforcement: EnforcementBoundary.clientEngine,
    ),
  };

  /// The six families with a dispatcher case in
  /// `part27_engine_native_binding_dispatcher.dart`. Their widgets look
  /// transitions up by id, so their vocabulary is closed.
  static const Set<String> bespokeFamilies = {
    'calendar',
    'event-rsvp',
    'votePoll',
    'equipment-loan',
    'documentLibrary',
    'searchAiAnswer',
    'exportWizard',
  };

  /// The seven families that reach `GenericWorkflowInstanceCard`. `table` is
  /// here despite rendering as a grid: that is list layout only, decided in
  /// `part32`, and carries no semantic contract.
  static const Set<String> genericFamilies = {
    'paymentCheckout',
    'approvalQueueItem',
    'formEntry',
    'discussionThread',
    'statusTimeline',
    'notificationInbox',
    'table',
  };

  /// Typed closed action vocabularies, permissions.md §4.
  static const Map<String, Set<ArchetypeAction>> bespokeActionRecords = {
    // `event-rsvp` minus `respond`, `withdraw_response` and `join_waitlist`.
    // The absence of those three is the entire difference: a prayer time or a
    // bin collection is a dated item nobody attends.
    'calendar': {
      ArchetypeAction(
        id: 'view',
        displayName: 'View calendar',
        description: 'Browse scheduled community items.',
      ),
      ArchetypeAction(
        id: 'create',
        displayName: 'Create calendar item',
        description: 'Add a dated item to the community calendar.',
      ),
      ArchetypeAction(
        id: 'edit',
        displayName: 'Edit calendar item',
        description: 'Update the details of a scheduled calendar item.',
      ),
      ArchetypeAction(
        id: 'cancel',
        displayName: 'Cancel calendar item',
        description: 'Cancel a scheduled calendar item.',
      ),
      ArchetypeAction(
        id: 'reopen',
        displayName: 'Reopen calendar item',
        description: 'Restore a cancelled calendar item.',
      ),
      ArchetypeAction(
        id: 'set_reminder',
        displayName: 'Set reminder',
        description: 'Schedule a reminder for a calendar item.',
      ),
      ArchetypeAction(
        id: 'deliver_reminder',
        displayName: 'Deliver reminder',
        description: 'Send a scheduled calendar reminder.',
      ),
      ArchetypeAction(
        id: 'propose_change',
        displayName: 'Propose change',
        description: 'Suggest an update to a calendar item.',
      ),
      ArchetypeAction(
        id: 'record_outcome',
        displayName: 'Record outcome',
        description: 'Record the result of a calendar item.',
      ),
    },
    'event-rsvp': {
      ArchetypeAction(
        id: 'view',
        displayName: 'View event',
        description: 'Open an event and see its details.',
      ),
      ArchetypeAction(
        id: 'create',
        displayName: 'Create event',
        description: 'Add an event for community members.',
      ),
      ArchetypeAction(
        id: 'edit',
        displayName: 'Edit event',
        description: 'Update an event’s details.',
      ),
      ArchetypeAction(
        id: 'cancel',
        displayName: 'Cancel event',
        description: 'Cancel a scheduled event.',
      ),
      ArchetypeAction(
        id: 'reopen',
        displayName: 'Reopen event',
        description: 'Restore a cancelled event.',
      ),
      ArchetypeAction(
        id: 'respond',
        displayName: 'Respond to event',
        description: 'Record an attendance response for an event.',
      ),
      ArchetypeAction(
        id: 'withdraw_response',
        displayName: 'Withdraw response',
        description: 'Remove an attendance response from an event.',
      ),
      ArchetypeAction(
        id: 'join_waitlist',
        displayName: 'Join waitlist',
        description: 'Add an attendance response to an event waitlist.',
      ),
      ArchetypeAction(
        id: 'set_reminder',
        displayName: 'Set reminder',
        description: 'Schedule a reminder for an event.',
      ),
      ArchetypeAction(
        id: 'send_reminder',
        displayName: 'Send reminder',
        description: 'Send an event reminder to attendees.',
      ),
      ArchetypeAction(
        id: 'deliver_reminder',
        displayName: 'Deliver reminder',
        description: 'Deliver a scheduled event reminder.',
      ),
      ArchetypeAction(
        id: 'propose_change',
        displayName: 'Propose change',
        description: 'Suggest an update to an event.',
      ),
      ArchetypeAction(
        id: 'record_outcome',
        displayName: 'Record outcome',
        description: 'Record the result of an event.',
      ),
    },
    'equipment-loan': {
      ArchetypeAction(
        id: 'view',
        displayName: 'View listings',
        description: 'Browse equipment listings and loan details.',
      ),
      ArchetypeAction(
        id: 'create',
        displayName: 'Create listing',
        description: 'Create a new equipment listing.',
      ),
      ArchetypeAction(
        id: 'list_item',
        displayName: 'List item',
        description: 'Make an equipment item available to the community.',
      ),
      ArchetypeAction(
        id: 'pause_listing',
        displayName: 'Pause listing',
        description: 'Temporarily make an equipment listing unavailable.',
      ),
      ArchetypeAction(
        id: 'delist',
        displayName: 'Delist item',
        description: 'Remove an equipment item from listings.',
      ),
      ArchetypeAction(
        id: 'request',
        displayName: 'Request item',
        description: 'Request to borrow an equipment item.',
      ),
      ArchetypeAction(
        id: 'decide_request',
        displayName: 'Decide request',
        description: 'Approve or decline an equipment request.',
      ),
      ArchetypeAction(
        id: 'withdraw_request',
        displayName: 'Withdraw request',
        description: 'Cancel an equipment request.',
      ),
      ArchetypeAction(
        id: 'claim',
        displayName: 'Claim item',
        description: 'Claim an available equipment item.',
      ),
      ArchetypeAction(
        id: 'join_queue',
        displayName: 'Join queue',
        description: 'Join the waiting queue for an equipment item.',
      ),
      ArchetypeAction(
        id: 'leave_queue',
        displayName: 'Leave queue',
        description: 'Leave the waiting queue for an equipment item.',
      ),
      ArchetypeAction(
        id: 'take_custody',
        displayName: 'Take custody',
        description: 'Record that an equipment item has been collected.',
      ),
      ArchetypeAction(
        id: 'return',
        displayName: 'Return item',
        description: 'Record the return of an equipment item.',
      ),
      ArchetypeAction(
        id: 'renew',
        displayName: 'Renew loan',
        description: 'Extend the loan period for an equipment item.',
      ),
      ArchetypeAction(
        id: 'report_issue',
        displayName: 'Report issue',
        description: 'Report a problem with an equipment item or loan.',
      ),
    },
    'documentLibrary': {
      ArchetypeAction(
        id: 'view',
        displayName: 'View documents',
        description: 'Browse documents in the library.',
      ),
      ArchetypeAction(
        id: 'create',
        displayName: 'Create document',
        description: 'Create a document in the library.',
      ),
      ArchetypeAction(
        id: 'upload',
        displayName: 'Upload document',
        description: 'Add a document to the library.',
      ),
      // A document has a life before it is published. Without these three, an
      // ordinary policy -- "only the Board may edit, publish or delete;
      // unpublished documents are Board-only" -- cannot be expressed at all,
      // because a document has no unpublished state and no way to leave one.
      ArchetypeAction(
        id: 'edit',
        displayName: 'Edit document',
        description: 'Update a document’s content or details.',
      ),
      ArchetypeAction(
        id: 'publish',
        displayName: 'Publish document',
        description: 'Make a document available to its audience.',
      ),
      ArchetypeAction(
        id: 'delete',
        displayName: 'Delete document',
        description: 'Permanently remove a document from the library.',
      ),
      ArchetypeAction(
        id: 'archive',
        displayName: 'Archive document',
        description: 'Move a document out of the active library.',
      ),
      ArchetypeAction(
        id: 'restore',
        displayName: 'Restore document',
        description: 'Return an archived document to the library.',
      ),
      ArchetypeAction(
        id: 'acknowledge',
        displayName: 'Acknowledge document',
        description: 'Confirm that a document has been reviewed.',
      ),
      ArchetypeAction(
        id: 'open',
        displayName: 'Open document',
        description: 'Open a document for reading.',
      ),
      ArchetypeAction(
        id: 'download',
        displayName: 'Download document',
        description: 'Download a copy of a document.',
      ),
      ArchetypeAction(
        id: 'mark_read',
        displayName: 'Mark as read',
        description: 'Mark a document as read.',
      ),
      ArchetypeAction(
        id: 'mark_unread',
        displayName: 'Mark as unread',
        description: 'Mark a document as unread.',
      ),
      ArchetypeAction(
        id: 'save',
        displayName: 'Save document',
        description: 'Save a document for later reference.',
      ),
      ArchetypeAction(
        id: 'unsave',
        displayName: 'Remove saved document',
        description: 'Remove a document from saved items.',
      ),
      ArchetypeAction(
        id: 'request_access',
        displayName: 'Request access',
        description: 'Request permission to access a document.',
      ),
      ArchetypeAction(
        id: 'withdraw_access_request',
        displayName: 'Withdraw access request',
        description: 'Cancel a request to access a document.',
      ),
      ArchetypeAction(
        id: 'grant_access',
        displayName: 'Grant access',
        description: 'Give another member access to a document.',
      ),
      ArchetypeAction(
        id: 'share',
        displayName: 'Share document',
        description: 'Share a document with other members.',
      ),
      ArchetypeAction(
        id: 'request_follow_up',
        displayName: 'Request follow-up',
        description: 'Ask for follow-up on a document.',
      ),
    },
    'exportWizard': {
      ArchetypeAction(
        id: 'view',
        displayName: 'View export',
        description: 'Open an export and see its status.',
      ),
      ArchetypeAction(
        id: 'create',
        displayName: 'Create export',
        description: 'Start a new data export.',
      ),
      ArchetypeAction(
        id: 'configure_scope',
        displayName: 'Configure export scope',
        description: 'Choose the data included in an export.',
      ),
      ArchetypeAction(
        id: 'preview',
        displayName: 'Preview export',
        description: 'Review an export before it runs.',
      ),
      ArchetypeAction(
        id: 'approve_redaction',
        displayName: 'Approve redaction',
        description: 'Approve redactions before an export runs.',
      ),
      ArchetypeAction(
        id: 'run',
        displayName: 'Run export',
        description: 'Generate an export from the selected data.',
      ),
      ArchetypeAction(
        id: 'download',
        displayName: 'Download export',
        description: 'Download a completed export.',
      ),
      ArchetypeAction(
        id: 'rollback',
        displayName: 'Roll back export',
        description: 'Reverse a completed export operation.',
      ),
      ArchetypeAction(
        id: 'retry',
        displayName: 'Retry export',
        description: 'Run an export again after a failure.',
      ),
      ArchetypeAction(
        id: 'cancel',
        displayName: 'Cancel export',
        description: 'Stop an export before it completes.',
      ),
      ArchetypeAction(
        id: 'record_outcome',
        displayName: 'Record outcome',
        description: 'Record the result of an export.',
      ),
      ArchetypeAction(
        id: 'decide_transfer',
        displayName: 'Decide transfer',
        description: 'Approve or decline an export transfer.',
      ),
    },
    'votePoll': {
      ArchetypeAction(
        id: 'view',
        displayName: 'View poll',
        description: 'Open a poll and see its details.',
      ),
      ArchetypeAction(
        id: 'create',
        displayName: 'Create poll',
        description: 'Create a poll for community members.',
      ),
      ArchetypeAction(
        id: 'vote',
        displayName: 'Vote in poll',
        description: 'Cast a vote in a poll.',
      ),
      ArchetypeAction(
        id: 'change_vote',
        displayName: 'Change vote',
        description: 'Change a vote before the poll closes.',
      ),
      ArchetypeAction(
        id: 'close',
        displayName: 'Close poll',
        description: 'Close a poll to further voting.',
      ),
      ArchetypeAction(
        id: 'publish_result',
        displayName: 'Publish results',
        description: 'Share a poll’s results with its audience.',
      ),
    },
    'searchAiAnswer': {
      ArchetypeAction(
        id: 'view',
        displayName: 'View answers',
        description: 'Browse answers to community questions.',
      ),
      ArchetypeAction(
        id: 'create',
        displayName: 'Create answer',
        description: 'Create a saved answer for a community question.',
      ),
      ArchetypeAction(
        id: 'ask',
        displayName: 'Ask question',
        description: 'Ask a question and request an answer.',
      ),
      ArchetypeAction(
        id: 'withdraw_query',
        displayName: 'Withdraw question',
        description: 'Withdraw a question before it is answered.',
      ),
      ArchetypeAction(
        id: 'curate',
        displayName: 'Curate answer',
        description: 'Review and improve a saved answer.',
      ),
      ArchetypeAction(
        id: 'add_citation',
        displayName: 'Add citation',
        description: 'Add a source citation to an answer.',
      ),
      ArchetypeAction(
        id: 'report',
        displayName: 'Report answer',
        description: 'Report an answer for review.',
      ),
      ArchetypeAction(
        id: 'moderate',
        displayName: 'Moderate answer',
        description: 'Review a reported answer and take action.',
      ),
    },
  };

  /// Typed structurally-derived actions available to generic families, §5.
  static const Set<ArchetypeAction> genericActionRecords = {
    ArchetypeAction(
      id: 'create',
      displayName: 'Create item',
      description: 'Create a new community item.',
    ),
    ArchetypeAction(
      id: 'advance',
      displayName: 'Advance item',
      description: 'Move a community item to its next state.',
    ),
    ArchetypeAction(
      id: 'terminate',
      displayName: 'Terminate item',
      description: 'End a community item before its normal completion.',
    ),
    ArchetypeAction(
      id: 'view',
      displayName: 'View item',
      description: 'Open a community item and see its details.',
    ),
  };

  /// Typed permission-bearing actions for the community governance family.
  static const Set<ArchetypeAction> governanceActions = {
    ArchetypeAction(
      id: 'view',
      displayName: 'View community',
      description: 'Open the community and see its public surfaces.',
    ),
    ArchetypeAction(
      id: 'invite',
      displayName: 'Invite members',
      description: 'Issue invitations to join this community.',
    ),
    ArchetypeAction(
      id: 'manage_members',
      displayName: 'Manage members',
      description: 'Add, suspend, or remove members of this community.',
    ),
    ArchetypeAction(
      id: 'manage_roles',
      displayName: 'Manage roles',
      description: 'Assign or revoke roles held by members of this community.',
    ),
    ArchetypeAction(
      id: 'manage_settings',
      displayName: 'Manage community settings',
      description: 'Edit community profile, branding, and tab configuration.',
    ),
  };

  /// Permission-id prefix for the community governance family.
  static const String governancePermissionPrefix = 'community';

  /// Closed action vocabularies, permissions.md §4.
  ///
  /// This compatibility accessor preserves the existing string-shaped API for
  /// callers that derive or validate action ids. New code that needs catalog
  /// metadata should use [bespokeActionRecords].
  static final Map<String, Set<String>> bespokeVocabularies = Map.unmodifiable({
    for (final entry in bespokeActionRecords.entries)
      entry.key: Set.unmodifiable({
        for (final action in entry.value) action.id,
      }),
  });

  /// The four structurally-derived action ids available to generic families.
  ///
  /// This preserves the existing string-shaped API; catalog consumers should
  /// use [genericActionRecords].
  static final Set<String> genericActions = Set.unmodifiable({
    for (final action in genericActionRecords) action.id,
  });

  /// The community governance action ids, retained as a derived convenience
  /// view for callers that only need ids.
  static final Set<String> governanceActionIds = Set.unmodifiable({
    for (final action in governanceActions) action.id,
  });

  /// `cardSurfaceFamily` -> permission-id prefix. Permission ids are
  /// `<archetype_snake_case>.<action>`.
  static const Map<String, String> permissionPrefixes = {
    'calendar': 'calendar',
    'event-rsvp': 'event_rsvp',
    'votePoll': 'vote_poll',
    'equipment-loan': 'equipment_loan',
    'documentLibrary': 'document_library',
    'searchAiAnswer': 'search_ai_answer',
    'exportWizard': 'export_wizard',
    'paymentCheckout': 'payment_checkout',
    'approvalQueueItem': 'approval_queue_item',
    'formEntry': 'form_entry',
    'discussionThread': 'discussion_thread',
    'statusTimeline': 'status_timeline',
    'notificationInbox': 'notification_inbox',
    'table': 'table',
  };

  /// The permission a `(family, action)` pair requires, e.g.
  /// `event_rsvp.respond`. Returns null for a family this resolver does not
  /// know, which callers should treat as a finding rather than a crash.
  String? permissionId(String family, String action) {
    final prefix = permissionPrefixes[family];
    return prefix == null ? null : '$prefix.$action';
  }

  /// Whether [action] is legal for [family].
  bool isActionInVocabulary(String family, String action) =>
      bespokeVocabularies[family]?.contains(action) ?? false;

  /// Resolves every workflow in one experience, keyed by workflow type.
  ///
  /// [workflowDefinitions] is the raw `experience.workflowDefinitions` map —
  /// raw, not the parsed `LoomWorkflowStateMachine`, because that model drops
  /// unknown keys and `action` is one of them.
  Map<String, ResolvedArchetype> resolveAll(
    Map<String, Object?> workflowDefinitions,
  ) {
    // §6 step 3b: build the responseTable ownership map first, so a workflow
    // with no bindings of its own can inherit from the binding that targets it.
    final inherited = <String, _ResponseTableOwner>{};
    for (final entry in workflowDefinitions.entries) {
      final workflow = entry.value;
      if (workflow is! Map) continue;
      for (final binding in _bindingsOf(workflow)) {
        final responseTable = binding['responseTable'];
        final family = binding['cardSurfaceFamily'];
        if (responseTable is! Map || family is! String) continue;
        final target = responseTable['workflowType'];
        if (target is String && target.isNotEmpty) {
          inherited[target] = _ResponseTableOwner(entry.key, family);
        }
      }
    }

    final resolved = <String, ResolvedArchetype>{};
    for (final entry in workflowDefinitions.entries) {
      final workflow = entry.value;
      if (workflow is! Map) continue;
      resolved[entry.key] = _resolveOne(entry.key, workflow, inherited);
    }
    return resolved;
  }

  ResolvedArchetype _resolveOne(
    String workflowType,
    Map<Object?, Object?> workflow,
    Map<String, _ResponseTableOwner> inherited,
  ) {
    final families = <String>{};
    for (final binding in _bindingsOf(workflow)) {
      final family = binding['cardSurfaceFamily'];
      if (family is String && family.isNotEmpty) families.add(family);
    }

    final bespoke = families.where(bespokeFamilies.contains).toList()..sort();

    // 3a — a bespoke family wins. Generic bindings alongside it do not compete;
    // a workflow routinely renders a primary bespoke surface on one tab and a
    // generic summary on another.
    if (bespoke.length == 1) {
      return ResolvedArchetype(
        family: bespoke.single,
        origin: ArchetypeOrigin.declaredBespoke,
      );
    }
    if (bespoke.length > 1) {
      // More than one bespoke family is not automatically ambiguous. A workflow
      // may render a primary surface in one family and a summary in another --
      // Tabletop's `tournament-event` pairs an event-rsvp calendar card with a
      // votePoll attendance/quorum summary, and the dispatcher special-cases it
      // by name. What matters is whether the transitions could belong to more
      // than one vocabulary. Resolve by asking which family can account for
      // every action the workflow declares.
      final declared = _declaredActions(workflow);
      final candidates = declared.isEmpty
          ? bespoke
          : bespoke
                .where(
                  (family) => declared.every(
                    (action) =>
                        bespokeVocabularies[family]?.contains(action) ?? false,
                  ),
                )
                .toList();
      if (candidates.length == 1) {
        return ResolvedArchetype(
          family: candidates.single,
          origin: ArchetypeOrigin.declaredBespoke,
        );
      }
      return ResolvedArchetype(
        family: bespoke.first,
        origin: ArchetypeOrigin.declaredBespoke,
        conflictingBespokeFamilies: bespoke,
      );
    }

    // 3b — inherit through responseTable before falling back to generic, so an
    // RSVP response workflow is bespoke and its transitions do need an action.
    if (families.isEmpty) {
      final owner = inherited[workflowType];
      if (owner != null) {
        return ResolvedArchetype(
          family: owner.family,
          origin: bespokeFamilies.contains(owner.family)
              ? ArchetypeOrigin.inheritedFromResponseTable
              : ArchetypeOrigin.generic,
          inheritedFrom: owner.workflowType,
        );
      }
      // 3d — no bindings, no responseTable owner. Never rendered as an
      // invocable surface; derives nothing.
      return const ResolvedArchetype(
        family: null,
        origin: ArchetypeOrigin.none,
      );
    }

    // 3c — generic.
    final sorted = families.toList()..sort();
    return ResolvedArchetype(
      family: sorted.first,
      origin: ArchetypeOrigin.generic,
    );
  }

  static Set<String> _declaredActions(Map<Object?, Object?> workflow) {
    final actions = <String>{};
    final transitions = workflow['transitions'];
    if (transitions is! List) return actions;
    for (final transition in transitions) {
      if (transition is! Map) continue;
      final action = transition['action'];
      if (action is String && action.isNotEmpty) actions.add(action);
    }
    return actions;
  }

  static Iterable<Map<Object?, Object?>> _bindingsOf(
    Map<Object?, Object?> workflow,
  ) sync* {
    final bindings = workflow['renderBindings'];
    if (bindings is! List) return;
    for (final binding in bindings) {
      if (binding is Map) yield binding;
    }
  }
}

class _ResponseTableOwner {
  const _ResponseTableOwner(this.workflowType, this.family);
  final String workflowType;
  final String family;
}
