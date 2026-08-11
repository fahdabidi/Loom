/// Canonical registry of workflow archetypes for Loom render bindings.
/// This list defines the exhaustive set of supported
/// `RenderBinding.cardSurfaceFamily` values in app state.
enum ArchetypeStatus { real, generic }

/// Metadata describing a known workflow archetype.
class WorkflowArchetype {
  const WorkflowArchetype({
    required this.id,
    required this.purpose,
    required this.status,
  });

  final String id;
  final String purpose;
  final ArchetypeStatus status;
}

/// Canonical workflow archetype registry used by renderer/validator workstreams.
const List<WorkflowArchetype> knownWorkflowArchetypes = <WorkflowArchetype>[
  WorkflowArchetype(
    id: 'event-rsvp',
    purpose: 'Event with RSVP, capacity, and waitlist',
    status: ArchetypeStatus.real,
  ),
  WorkflowArchetype(
    id: 'equipment-loan',
    purpose: 'Browse, borrow, queue for, and return shared items',
    status: ArchetypeStatus.real,
  ),
  WorkflowArchetype(
    id: 'votePoll',
    purpose: 'Ballot with candidates, tally, and results',
    status: ArchetypeStatus.real,
  ),
  WorkflowArchetype(
    id: 'paymentCheckout',
    purpose: 'Dues, donations, or purchase checkout with a receipt',
    status: ArchetypeStatus.generic,
  ),
  WorkflowArchetype(
    id: 'approvalQueueItem',
    purpose: 'A live queue of items awaiting a decision',
    status: ArchetypeStatus.generic,
  ),
  WorkflowArchetype(
    id: 'formEntry',
    purpose: 'Author or edit a record with typed fields',
    status: ArchetypeStatus.generic,
  ),
  WorkflowArchetype(
    id: 'discussionThread',
    purpose: 'A message thread with replies and read state',
    status: ArchetypeStatus.generic,
  ),
  WorkflowArchetype(
    id: 'statusTimeline',
    purpose: 'A timestamped progression of an item through states',
    status: ArchetypeStatus.generic,
  ),
  WorkflowArchetype(
    id: 'notificationInbox',
    purpose: 'A list of notices with unread/read state',
    status: ArchetypeStatus.generic,
  ),
];

final Set<String> knownWorkflowArchetypeIds = <String>{
  for (final archetype in knownWorkflowArchetypes) archetype.id,
};
