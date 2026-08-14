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

/// Resolves archetypes and maps actions to permission ids.
class ArchetypeResolver {
  const ArchetypeResolver();

  /// The six families with a dispatcher case in
  /// `part27_engine_native_binding_dispatcher.dart`. Their widgets look
  /// transitions up by id, so their vocabulary is closed.
  static const Set<String> bespokeFamilies = {
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

  /// Closed action vocabularies, permissions.md §4.
  static const Map<String, Set<String>> bespokeVocabularies = {
    'event-rsvp': {
      'view',
      'create',
      'edit',
      'cancel',
      'reopen',
      'respond',
      'withdraw_response',
      'join_waitlist',
      'set_reminder',
      'propose_change',
      'record_outcome',
    },
    'equipment-loan': {
      'view',
      'list_item',
      'pause_listing',
      'delist',
      'request',
      'decide_request',
      'withdraw_request',
      'claim',
      'join_queue',
      'leave_queue',
      'take_custody',
      'return',
      'renew',
      'report_issue',
    },
    'documentLibrary': {
      'view',
      'upload',
      'archive',
      'restore',
      'acknowledge',
      'open',
      'download',
      'mark_read',
      'mark_unread',
      'save',
      'unsave',
      'request_access',
      'withdraw_access_request',
      'grant_access',
      'share',
      'request_follow_up',
    },
    'exportWizard': {
      'view',
      'configure_scope',
      'preview',
      'approve_redaction',
      'run',
      'download',
      'rollback',
      'retry',
      'cancel',
      'record_outcome',
      'decide_transfer',
    },
    'votePoll': {
      'view',
      'create',
      'vote',
      'change_vote',
      'close',
      'publish_result',
    },
    'searchAiAnswer': {
      'view',
      'ask',
      'withdraw_query',
      'curate',
      'add_citation',
      'report',
      'moderate',
    },
  };

  /// The four structurally-derived actions available to generic families, §5.
  static const Set<String> genericActions = {
    'create',
    'advance',
    'terminate',
    'view',
  };

  /// `cardSurfaceFamily` -> permission-id prefix. Permission ids are
  /// `<archetype_snake_case>.<action>`.
  static const Map<String, String> permissionPrefixes = {
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
                (family) =>
                    declared.every(
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
