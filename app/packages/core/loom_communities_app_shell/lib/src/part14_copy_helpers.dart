part of '../loom_communities_app_shell.dart';

String _entryTextForState({
  required LoomPersonaWorkflowState state,
  required LoomWorkflowDefinition workflow,
  required LoomWorkflowPersonaPolicy policy,
  required bool waiting,
}) {
  if (waiting) {
    return 'Waiting for the required prior action.';
  }
  if (state == LoomPersonaWorkflowState.receiver) {
    return policy.receiverEntryText ??
        'A completed result is ready for this role.';
  }
  if (state == LoomPersonaWorkflowState.readOnly) {
    return policy.readOnlyText ??
        'This role can read the current record without editing.';
  }
  if (state == LoomPersonaWorkflowState.disabled) {
    return policy.disabledReason;
  }
  return workflow.entryText;
}

String _actionTextForState(
  LoomPersonaWorkflowState state,
  LoomWorkflowPersonaPolicy policy,
  LoomWorkflowDefinition workflow,
) {
  if (state == LoomPersonaWorkflowState.receiver) {
    return _receiverActionLabel(workflow: workflow, policy: policy);
  }
  if (state == LoomPersonaWorkflowState.readOnly) {
    return 'View only';
  }
  if (state == LoomPersonaWorkflowState.disabled) {
    return 'Not available';
  }
  return _primaryActionLabelFor(workflow);
}

String _resultTextForState(
  LoomWorkflowDefinition workflow,
  LoomWorkflowPersonaPolicy policy,
  LoomPersonaWorkflowState state,
) {
  if (state == LoomPersonaWorkflowState.receiver) {
    return policy.receiverResultText ?? 'Community update received.';
  }
  return workflow.resultText;
}

String _rationaleForState(
  LoomPersonaWorkflowState state,
  LoomWorkflowPersonaPolicy policy,
) {
  switch (state) {
    case LoomPersonaWorkflowState.actor:
      return 'You can manage this item.';
    case LoomPersonaWorkflowState.receiver:
      return 'This item is ready after the first action is finished.';
    case LoomPersonaWorkflowState.readOnly:
      return 'You can read this item without editing it.';
    case LoomPersonaWorkflowState.disabled:
      return policy.disabledReason;
  }
}

String _receiverActionLabel({
  required LoomWorkflowDefinition workflow,
  required LoomWorkflowPersonaPolicy policy,
}) {
  final label = policy.receiverActionText;
  if (label == null || label == 'Receive') {
    return 'Open ${_objectLabelFor(workflow)}';
  }
  if (label == 'Review') {
    return 'Open ${_objectLabelFor(workflow)}';
  }
  return label;
}

String _workflowCategoryFor(LoomWorkflowDefinition workflow) {
  final id = workflow.workflowId;
  final title = workflow.title.toLowerCase();
  if (id.contains('ad-off')) {
    return 'Ad-free';
  }
  if (id.contains('search') ||
      id.contains('digest') ||
      id.contains('citation')) {
    return 'Knowledge';
  }
  if (id.contains('in-stream-ad') ||
      id.contains('top-banner') ||
      id.contains('no-fill') ||
      id.contains('sensitive-no-fill') ||
      id.contains('sponsor')) {
    return 'Ads';
  }
  if (id.contains('rsvp') ||
      title.contains('event') ||
      title.contains('schedule') ||
      title.contains('photo-walk')) {
    return 'Event';
  }
  if (id.contains('payment') ||
      id.contains('dues') ||
      id.contains('donation') ||
      id.contains('checkout') ||
      title.contains('receipt') ||
      title.contains('reservation')) {
    return 'Payment';
  }
  if (id.contains('announcement') ||
      id.contains('publish') ||
      id.contains('notification')) {
    return 'Publishing';
  }
  if (id.contains('approval') ||
      id.contains('decision') ||
      id.contains('review')) {
    return 'Approval';
  }
  if (id.contains('export') ||
      id.contains('import') ||
      id.contains('transfer') ||
      id.contains('redaction') ||
      id.contains('checksum')) {
    return 'Portability';
  }
  if (id.contains('message') ||
      id.contains('connection') ||
      id.contains('banner') ||
      id.contains('blocked') ||
      id.contains('stream')) {
    return 'Platform';
  }
  return 'Form';
}

/// Resolves the response choices an action surface should offer: the
/// workflow's own package-declared choices when present, otherwise a
/// category default. Most categories default to a single choice, which
/// renders identically to today's one-button confirm surface.
List<LoomWorkflowResponseChoice> _responseChoicesFor(
  LoomWorkflowDefinition workflow,
  LoomProductionWorkflowContract contract,
) {
  final declared = workflow.responseChoices;
  if (declared != null && declared.isNotEmpty) {
    return declared;
  }
  return _defaultResponseChoicesForCategory(contract);
}

/// Result-panel body text for a completed workflow. When the actor picked a
/// specific response among more than one choice (e.g. Maybe, not the
/// default Going), the text names that choice instead of [defaultBody] (the
/// success summary every workflow used to share, whether from
/// [LoomProductionWorkflowContract] or a `_RichWorkflowSpec`).
String _responseResultBody({
  required LoomWorkflowDefinition workflow,
  required LoomProductionWorkflowContract contract,
  required String defaultBody,
  String? selectedResponseId,
}) {
  if (selectedResponseId == null) {
    return defaultBody;
  }
  final choices = _responseChoicesFor(workflow, contract);
  if (choices.length <= 1) {
    return defaultBody;
  }
  final selected = choices.firstWhere(
    (choice) => choice.responseId == selectedResponseId,
    orElse: () => choices.first,
  );
  return 'You responded: ${selected.label}. $defaultBody';
}

List<LoomWorkflowResponseChoice> _defaultResponseChoicesForCategory(
  LoomProductionWorkflowContract contract,
) {
  // No category defaults to multi-choice automatically: the catalog's
  // ~11 hardcoded communities span too many workflow-naming conventions to
  // safely enumerate every workflow that would be swept into a category
  // (discovered the hard way — an initial version defaulted Event/Approval
  // categories to 3-way choices and broke an existing catalog workflow that
  // happened to fall through to this same generic path with no bespoke
  // rich-spec entry). Every category keeps today's single-action behavior
  // unless the workflow's package explicitly declares `responseChoices`.
  return [
    LoomWorkflowResponseChoice(
      responseId: 'confirmed',
      label: contract.primaryActionLabel,
      icon: contract.icon,
    ),
  ];
}

String _surfaceLabelFor(String category) {
  switch (category) {
    case 'Event':
      return 'Event details';
    case 'Payment':
      return 'Payment details';
    case 'Ad-free':
      return 'Ad-free account';
    case 'Ads':
      return 'Ad placement';
    case 'Knowledge':
      return 'Knowledge answer';
    case 'Publishing':
      return 'Member update';
    case 'Approval':
      return 'Request changes';
    case 'Portability':
      return 'Data package';
    case 'Platform':
      return 'Community setting';
  }
  return 'Member form';
}

String _objectLabelFor(LoomWorkflowDefinition workflow) {
  var title = _displayTitleFor(workflow).toLowerCase();
  title = title
      .replaceAll(' and ', ' ')
      .replaceAll(',', '')
      .replaceAll('protected ', '')
      .trim();
  if (title.length > 34) {
    return title.substring(0, 34).trim();
  }
  return title;
}

String _primaryActionLabelFor(LoomWorkflowDefinition workflow) {
  final id = workflow.workflowId;
  if (id.contains('plant-exchange')) {
    return 'Offer plant';
  }
  if (id.contains('match') || id.contains('chess')) {
    return 'Record match result';
  }
  if (id.contains('rsvp')) {
    return 'RSVP to event';
  }
  if (id.contains('payment') || id.contains('dues')) {
    return 'Pay and save receipt';
  }
  if (id.contains('donation')) {
    return 'Record donation';
  }
  if (id.contains('checkout')) {
    return id.contains('ad-off')
        ? 'Start ad-free checkout'
        : 'Confirm checkout';
  }
  if (id.contains('entitlement')) {
    return 'Manage entitlement';
  }
  if (id.contains('receipt')) {
    return 'Open receipt';
  }
  if (id.contains('suppression')) {
    return 'Verify ad suppression';
  }
  if (id.contains('settlement')) {
    return 'Review settlement';
  }
  if (id.contains('announcement')) {
    return 'Publish announcement';
  }
  if (id.contains('publish') || id.contains('selection')) {
    return 'Publish announcement';
  }
  if (id.contains('schedule')) {
    return 'Publish schedule';
  }
  if (id.contains('reminder')) {
    return 'Send reminder';
  }
  if (id.contains('notification')) {
    return 'Send notification';
  }
  if (id.contains('approval') || id.contains('decision')) {
    return 'Approve request';
  }
  if (id.contains('export')) {
    return 'Generate export';
  }
  if (id.contains('import')) {
    return 'Preview import';
  }
  if (id.contains('transfer-verification')) {
    return 'Verify transfer';
  }
  if (id.contains('rollback')) {
    return 'Run rollback';
  }
  if (id.contains('search') || id.contains('digest')) {
    return 'Generate cited answer';
  }
  if (id.contains('invite')) {
    return 'Send invite';
  }
  if (id.contains('messages')) {
    return 'Reply';
  }
  if (id.contains('connections')) {
    return 'Connect';
  }
  if (id.contains('blocked')) {
    return 'Confirm blocked state';
  }
  if (id.contains('ad') || id.contains('banner')) {
    return 'Open ad details';
  }
  if (id.contains('vote')) {
    return 'Record vote';
  }
  if (id.contains('nomination')) {
    return 'Submit nomination';
  }
  if (id.contains('message')) {
    return 'Send message';
  }
  if (id.contains('request')) {
    return 'Submit request';
  }
  if (id.contains('signup')) {
    return 'Submit signup';
  }
  if (id.contains('submission')) {
    return 'Submit';
  }
  if (id.contains('reservation')) {
    return 'Reserve and pay';
  }
  if (id.contains('document')) {
    return 'Open document';
  }
  if (id.contains('roster')) {
    return 'Open roster';
  }
  if (id.contains('redaction')) {
    return 'Preview redaction';
  }
  if (id.contains('visibility')) {
    return 'Save visibility';
  }
  if (id.contains('route') || id.contains('open')) {
    return 'Open community home';
  }
  final action = workflow.actionText.replaceAll(RegExp(r'\.$'), '');
  return action.length <= 36 ? action : 'Start ${_objectLabelFor(workflow)}';
}

String _alternateActionLabelFor(LoomWorkflowDefinition workflow) {
  final id = workflow.workflowId;
  if (id.contains('announcement')) {
    return 'Preview announcement';
  }
  if (id.contains('publish') || id.contains('selection')) {
    return 'Save draft';
  }
  if (id.contains('rsvp') ||
      id.contains('event') ||
      id.contains('practice') ||
      id.contains('photo-walk')) {
    return 'Change response';
  }
  if (id.contains('ad-off')) {
    return id.contains('settlement')
        ? 'Correct allocation'
        : 'Restore or cancel';
  }
  if (id.contains('payment') ||
      id.contains('dues') ||
      id.contains('donation') ||
      id.contains('checkout')) {
    return 'Change amount';
  }
  if (id.contains('document')) {
    return 'Save document';
  }
  if (id.contains('architectural') ||
      id.contains('approval') ||
      id.contains('decision')) {
    return 'Request changes';
  }
  if (id.contains('care')) {
    return 'Update privacy';
  }
  if (id.contains('gear')) {
    return 'Change request';
  }
  if (id.contains('plant-exchange')) {
    return 'Edit offer';
  }
  if (id.contains('nomination')) {
    return 'Edit nomination';
  }
  if (id.contains('vote')) {
    return 'Change vote';
  }
  if (id.contains('critique')) {
    return 'Edit critique';
  }
  if (id.contains('match') || id.contains('chess')) {
    return 'Edit score';
  }
  if (id.contains('invite')) {
    return 'Decline invite';
  }
  if (id.contains('message') || id.contains('connection')) {
    return 'Archive thread';
  }
  if (id.contains('export') ||
      id.contains('transfer') ||
      id.contains('import')) {
    return 'Change scope';
  }
  if (id.contains('request')) {
    return 'Edit request';
  }
  if (id.contains('signup')) {
    return 'Edit availability';
  }
  return 'Edit response';
}

String _decisionSummaryFor(String category, LoomWorkflowDefinition workflow) {
  final id = workflow.workflowId;
  if (id.contains('announcement') || id.contains('publish')) {
    return 'Message body, audience, delivery timing, preview, and draft option stay visible before publishing.';
  }
  if (id.contains('rsvp') ||
      id.contains('event') ||
      id.contains('practice') ||
      id.contains('photo-walk')) {
    return 'Event date, time, location, capacity, and Going/Maybe/Not going options are visible.';
  }
  if (id.contains('ad-off')) {
    return id.contains('settlement')
        ? 'Funded amount, settlement ID, utility allocation, audit status, correction, and rollback path are visible.'
        : 'Entitlement scope, renewal or expiry, receipt link, restore/manage action, and affected ad slots are visible.';
  }
  if (id.contains('payment') ||
      id.contains('dues') ||
      id.contains('donation') ||
      id.contains('checkout') ||
      id.contains('ad-off')) {
    return 'Amount, payer context, visibility, receipt destination, retry, refund, and manage-payment options are visible.';
  }
  if (id.contains('document')) {
    return 'Document access, version, download, save, share, and access-request options are visible.';
  }
  if (id.contains('architectural') ||
      id.contains('approval') ||
      id.contains('request')) {
    return 'Request details, approval, rejection, revision request, comments, and status history are visible.';
  }
  if (id.contains('care')) {
    return 'Care details, recipient visibility, privacy settings, protected fields, and follow-up option are visible.';
  }
  if (id.contains('gear')) {
    return 'Owner, pickup, due date, borrower queue, claim, decline, change, and return options are visible.';
  }
  if (id.contains('plant-exchange')) {
    return 'Variety, pickup, protected contact, claim, offer, edit, and cancel options are visible.';
  }
  if (id.contains('critique')) {
    return 'Image, prompt, consent note, comments, submit, edit, withdraw, and resubmit options are visible.';
  }
  if (id.contains('match') || id.contains('chess')) {
    return 'Opponent, round, score, standings impact, save, edit, correct, and dispute options are visible.';
  }
  if (id.contains('message') ||
      id.contains('connection') ||
      id.contains('invite')) {
    return 'Sender, recipient, message body, timestamp, reply, send, accept, decline, mute, archive, and block options are visible.';
  }
  if (id.contains('export') ||
      id.contains('transfer') ||
      id.contains('import')) {
    return 'Scope, redaction, checksum, destination, retry, rollback, and change-scope options are visible.';
  }
  return 'This view shows editable details, current progress, and the next step before saving.';
}

String _receiverStateSummaryFor(
  String category,
  LoomWorkflowDefinition workflow,
) {
  final id = workflow.workflowId;
  if (id.contains('announcement') || id.contains('publish')) {
    return 'Members see it later in the inbox, notification list, and read receipt.';
  }
  if (id.contains('rsvp') ||
      id.contains('event') ||
      id.contains('practice') ||
      id.contains('photo-walk')) {
    return 'The calendar, attendee roster, and member record remain visible after the response.';
  }
  if (id.contains('ad-off')) {
    return id.contains('settlement')
        ? 'Settlement ID, funded amount, audit status, utility impact, correction, and rollback path remain visible.'
        : 'Ad-free entitlement, receipt, renewal, restore path, and suppressed ad slots remain available.';
  }
  if (id.contains('payment') ||
      id.contains('dues') ||
      id.contains('donation') ||
      id.contains('checkout') ||
      id.contains('ad-off')) {
    return 'Receipt history, donor or member account status, and entitlement state remain available.';
  }
  if (id.contains('document')) {
    return 'Members keep access, read-only viewer state, and download history where allowed.';
  }
  if (id.contains('architectural') ||
      id.contains('approval') ||
      id.contains('request') ||
      id.contains('care')) {
    return 'Reviewer, owner, committee, notification, and request status are visible after submission.';
  }
  if (id.contains('gear') || id.contains('plant-exchange')) {
    return 'Owner, borrower, contact, pickup, and handoff status stay visible.';
  }
  if (id.contains('critique')) {
    return 'Reviewer feedback, comments, and member follow-up stay visible.';
  }
  if (id.contains('match') || id.contains('chess')) {
    return 'Opponent, standings, next pairing, and recorded result remain visible.';
  }
  if (id.contains('message') ||
      id.contains('connection') ||
      id.contains('invite')) {
    return 'Recipient inbox, thread, and connection record remain visible.';
  }
  if (id.contains('export') ||
      id.contains('transfer') ||
      id.contains('import')) {
    return 'Provider, destination, rollback, audit, and transfer progress remain visible.';
  }
  return 'History, receiver status, and next step remain visible.';
}

String _screenTitleFor(String category, LoomWorkflowDefinition workflow) {
  switch (category) {
    case 'Event':
      return 'Event details';
    case 'Payment':
      return 'Payment checkout';
    case 'Ad-free':
      return 'Ad-free account';
    case 'Ads':
      return 'Ad slot state';
    case 'Knowledge':
      return 'Cited answer';
    case 'Publishing':
      return 'Announcement composer';
    case 'Approval':
      return 'Decision desk';
    case 'Portability':
      return 'Data package';
    case 'Platform':
      return 'Member setting';
  }
  return '${_objectLabelFor(workflow).substring(0, 1).toUpperCase()}${_objectLabelFor(workflow).substring(1)} details';
}

Color _categoryAccentColor(String category, ColorScheme scheme) {
  switch (category) {
    case 'Event':
      return const Color(0xff2f6f9f);
    case 'Payment':
      return const Color(0xff7b4f9d);
    case 'Ad-free':
      return const Color(0xff4d668f);
    case 'Ads':
      return const Color(0xff6d5a1e);
    case 'Knowledge':
      return const Color(0xff4e5fa8);
    case 'Publishing':
      return const Color(0xff00796b);
    case 'Approval':
      return const Color(0xff8a5a00);
    case 'Portability':
      return const Color(0xff4556a4);
    case 'Platform':
      return const Color(0xff7a5c00);
    case 'Form':
      return const Color(0xff3f7f4c);
  }
  return scheme.primary;
}

String _domainSurfaceTitleFor(
  String category,
  LoomWorkflowDefinition workflow,
) {
  switch (category) {
    case 'Event':
      return 'Coordinate attendance';
    case 'Payment':
      return 'Record payment';
    case 'Ad-free':
      return 'Manage ad-free account';
    case 'Ads':
      return 'Review sponsored placement';
    case 'Knowledge':
      return 'Use cited answer';
    case 'Publishing':
      return 'Send community notice';
    case 'Approval':
      return 'Resolve member request';
    case 'Portability':
      return 'Prepare export handoff';
    case 'Platform':
      return 'Update member channel';
    case 'Form':
      return 'Submit member form';
  }
  return _displayTitleFor(workflow);
}

String _domainSurfaceLeadFor(
  String category,
  LoomWorkflowDefinition workflow, {
  required bool isReceiverSurface,
}) {
  if (isReceiverSurface) {
    switch (category) {
      case 'Event':
        return 'Member attendance and event changes are shown in one place.';
      case 'Payment':
        return 'The member can open the receipt, privacy choice, and amount.';
      case 'Ad-free':
        return 'The member sees ad-free entitlement, receipt, renewal, and affected ad slots.';
      case 'Ads':
        return 'The member sees disclosure, no-fill reason, dismissal, or report state.';
      case 'Knowledge':
        return 'The member sees the cited answer, source visibility, and saved digest state.';
      case 'Publishing':
        return 'The member sees the message, audience, and delivery channel.';
      case 'Approval':
        return 'The member sees the decision and the next action.';
      case 'Portability':
        return 'The member can open scope, status, and protected-data handling.';
      case 'Platform':
        return 'The member sees the channel or relationship change.';
      case 'Form':
        return 'The reviewer can open the submitted details and follow-up option.';
    }
  }
  switch (category) {
    case 'Event':
      return 'This screen helps you publish event details, capacity, and attendance state.';
    case 'Payment':
      return 'This screen helps you capture the amount, receipt, and privacy setting.';
    case 'Ad-free':
      return 'This screen helps you manage entitlement, receipt, renewal, restore, and affected ad slots.';
    case 'Ads':
      return 'This screen helps you inspect disclosure, reserved slot, sponsor or no-fill reason, and controls.';
    case 'Knowledge':
      return 'This screen helps you inspect query, answer, citations, source visibility, and follow-up.';
    case 'Publishing':
      return 'This screen helps you send a scoped announcement to the selected audience.';
    case 'Approval':
      return 'This screen helps you record the decision and member follow-up.';
    case 'Portability':
      return 'This screen helps you package export scope, redaction, and handoff status.';
    case 'Platform':
      return 'This screen helps you change a member communication or relationship setting.';
    case 'Form':
      return 'This screen helps you submit structured member details.';
  }
  return workflow.entryText;
}

String _surfaceInputFor(String category, LoomWorkflowDefinition workflow) {
  switch (category) {
    case 'Event':
      return 'Date, location, capacity, and attendee state are included.';
    case 'Payment':
      return 'Amount, payer, privacy choice, and receipt destination are included.';
    case 'Ad-free':
      return 'Entitlement scope, renewal, receipt, restore/manage action, and affected ad slots are included.';
    case 'Ads':
      return 'Reserved slot, disclosure/no-fill reason, impression state, and report/dismiss controls are included.';
    case 'Knowledge':
      return 'Query, answer, citations, source visibility, save/share, and refresh state are included.';
    case 'Publishing':
      return 'Message, audience, preview, and delivery channel are included.';
    case 'Approval':
      return 'Request details, decision, and follow-up note are included.';
    case 'Portability':
      return 'Scope, redaction, checksum, and handoff destination are included.';
    case 'Platform':
      return 'Member channel, relationship, and preference details are included.';
    case 'Form':
      return 'Required fields, privacy choices, and reviewer handoff are included.';
  }
  return _domainSummaryFor(
    category,
    workflow,
    LoomPersonaWorkflowView(
      state: LoomPersonaWorkflowState.actor,
      completed: false,
      received: false,
      waitingForPrerequisite: false,
      entryText: workflow.entryText,
      actionText: workflow.actionText,
      resultText: workflow.resultText,
      personaRationale: 'Actor may complete this action.',
      waitingText: '',
    ),
  );
}

String _surfaceOutcomeFor(String category, LoomWorkflowDefinition workflow) {
  switch (category) {
    case 'Event':
      return 'Attendance, capacity, and reminders update for the community.';
    case 'Payment':
      return 'The payment record and receipt become available to the right member.';
    case 'Ad-free':
      return 'The entitlement, renewal or expiry, receipt, restore path, and ad suppression state remain visible.';
    case 'Ads':
      return 'The ad slot preserves layout with disclosure, impression/no-fill, and member controls visible.';
    case 'Knowledge':
      return 'The cited answer can be saved, shared, refreshed, and checked for stale sources.';
    case 'Publishing':
      return 'The announcement appears in the member inbox and notification channel.';
    case 'Approval':
      return 'The decision is saved with the next step visible to the member.';
    case 'Portability':
      return 'The export package can be inspected with redaction and checksum details.';
    case 'Platform':
      return 'The communication or relationship setting changes for this community.';
    case 'Form':
      return 'The submission is routed to the reviewer with protected details preserved.';
  }
  return _successBodyFor(category, workflow);
}

String _inputSummaryFor(String category, LoomWorkflowDefinition workflow) {
  switch (category) {
    case 'Event':
      return 'Date, location, capacity, and attendee details are ready.';
    case 'Payment':
      return 'Amount, payer, privacy choice, and receipt details are ready.';
    case 'Ad-free':
      return 'Entitlement scope, receipt, renewal, restore, and suppressed ad slots are ready.';
    case 'Ads':
      return 'Disclosure, slot state, no-fill reason, and member controls are ready.';
    case 'Knowledge':
      return 'Query, answer, citations, source visibility, and follow-up prompts are ready.';
    case 'Publishing':
      return 'Message, audience, preview, and send timing are ready.';
    case 'Approval':
      return 'Request details, decision, and follow-up are ready.';
    case 'Portability':
      return 'Data scope, redaction, checksum, and handoff details are ready.';
    case 'Platform':
      return 'Member communication and preference details are ready.';
  }
  if (workflow.workflowId.contains('care')) {
    return 'Public summary, private details, and consent choices are ready.';
  }
  return 'Required details are ready.';
}

String _validationSummaryFor(String category) {
  switch (category) {
    case 'Payment':
      return 'Receipt and privacy settings are saved with the payment.';
    case 'Ad-free':
      return 'Entitlement, receipt, restore/manage action, and affected ad slots are checked.';
    case 'Ads':
      return 'Disclosure, impression/no-fill state, and member controls are checked.';
    case 'Knowledge':
      return 'Citations, source visibility, stale-source handling, and saved digest state are checked.';
    case 'Publishing':
      return 'Audience, citation, and notification scope are reviewed before send.';
    case 'Portability':
      return 'Protected fields, redaction, and checksums are verified.';
    case 'Platform':
      return 'Membership and privacy settings are respected.';
  }
  return 'Required details are checked before submission.';
}

String _successTitleFor(String category, LoomWorkflowDefinition workflow) {
  final id = workflow.workflowId;
  if (id.contains('message')) {
    return 'Message sent';
  }
  if (id.contains('connection') || id.contains('invite')) {
    return 'Connection accepted';
  }
  if (id.contains('announcement')) {
    return 'Announcement posted';
  }
  if (id.contains('rsvp')) {
    return 'RSVP confirmed';
  }
  if (id.contains('donation')) {
    return 'Donation recorded';
  }
  if (id.contains('volunteer') || id.contains('signup')) {
    return 'Signup saved';
  }
  if (id.contains('care')) {
    return 'Care request sent';
  }
  switch (category) {
    case 'Payment':
      return 'Receipt saved';
    case 'Ad-free':
      return 'Ad-free account updated';
    case 'Ads':
      return 'Ad slot recorded';
    case 'Knowledge':
      return 'Answer saved';
    case 'Publishing':
      return 'Update sent';
    case 'Approval':
      return 'Request outcome saved';
    case 'Portability':
      return 'Data package ready';
    case 'Platform':
      return 'Setting saved';
    case 'Event':
      return 'Event updated';
  }
  return 'Record saved';
}

String _successBodyFor(String category, LoomWorkflowDefinition workflow) {
  final id = workflow.workflowId;
  if (id.contains('message')) {
    return 'The message is sent and received in the community thread.';
  }
  if (id.contains('connection') || id.contains('invite')) {
    return 'The member connection is accepted and visible in the community network.';
  }
  if (id.contains('announcement')) {
    return 'Members can now read the announcement in their community inbox.';
  }
  if (id.contains('rsvp')) {
    return 'Attendance, capacity, and confirmation details are up to date.';
  }
  if (id.contains('donation')) {
    return 'The donation and receipt are saved with the selected privacy choice.';
  }
  if (id.contains('volunteer') || id.contains('signup')) {
    return 'The coordinator can open the signup and protected contact details.';
  }
  if (id.contains('care')) {
    return 'The care team can open the private request details.';
  }
  switch (category) {
    case 'Event':
      return 'Event details and attendance records are up to date.';
    case 'Payment':
      return 'The receipt is saved and available to the member.';
    case 'Ad-free':
      return 'The entitlement, receipt, renewal, restore path, and suppressed ad slots remain visible.';
    case 'Ads':
      return 'The slot keeps disclosure/no-fill state, member control, and stable layout visible.';
    case 'Knowledge':
      return 'The cited answer is saved with source visibility and refresh/follow-up actions.';
    case 'Publishing':
      return 'The update is available to the selected audience.';
    case 'Approval':
      return 'The request outcome is saved and ready for member follow-up.';
    case 'Portability':
      return 'The data package is ready with protected fields handled.';
    case 'Platform':
      return 'The member setting is up to date.';
  }
  return 'The community record is saved.';
}

String _receiverTitleFor(String category, String objectLabel) {
  switch (category) {
    case 'Event':
      return 'Event update ready';
    case 'Payment':
      return 'Receipt ready';
    case 'Ad-free':
      return 'Ad-free status ready';
    case 'Ads':
      return 'Ad slot state ready';
    case 'Knowledge':
      return 'Saved answer ready';
    case 'Publishing':
      return 'Update ready';
    case 'Approval':
      return 'Request update ready';
    case 'Portability':
      return 'Data package ready';
    case 'Platform':
      return 'Member update ready';
  }
  return '${objectLabel.substring(0, 1).toUpperCase()}${objectLabel.substring(1)} ready';
}

String _successChipLabelFor(String category) {
  switch (category) {
    case 'Payment':
      return 'Receipt';
    case 'Ad-free':
      return 'Ad-free';
    case 'Ads':
      return 'Recorded';
    case 'Knowledge':
      return 'Saved';
    case 'Publishing':
      return 'Sent';
    case 'Approval':
      return 'Reviewed';
    case 'Portability':
      return 'Ready';
    case 'Platform':
      return 'Verified';
    case 'Event':
      return 'Going';
  }
  return 'Saved';
}

String _trustSummaryFor(String category) {
  switch (category) {
    case 'Payment':
      return 'Payments and receipts stay tied to the member account.';
    case 'Ad-free':
      return 'Ad-free entitlement and receipt records stay tied to the member account.';
    case 'Ads':
      return 'Sponsored placement and no-fill decisions preserve member trust.';
    case 'Knowledge':
      return 'Answers stay permission-aware and cite visible sources.';
    case 'Publishing':
      return 'Only the selected audience receives the update.';
    case 'Portability':
      return 'Protected data stays redacted before sharing.';
    case 'Platform':
      return 'Private member relationships stay scoped to this community.';
  }
  return 'Private member details stay protected.';
}

IconData _iconFor(String category) {
  switch (category) {
    case 'Event':
      return Icons.event_available_outlined;
    case 'Payment':
      return Icons.receipt_long_outlined;
    case 'Ad-free':
      return Icons.block_outlined;
    case 'Ads':
      return Icons.campaign_outlined;
    case 'Knowledge':
      return Icons.manage_search_outlined;
    case 'Publishing':
      return Icons.campaign_outlined;
    case 'Approval':
      return Icons.task_alt_outlined;
    case 'Portability':
      return Icons.file_download_outlined;
    case 'Platform':
      return Icons.hub_outlined;
  }
  return Icons.assignment_outlined;
}
