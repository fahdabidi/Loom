part of '../loom_communities_app_shell.dart';

class _WorkflowAction extends StatelessWidget {
  const _WorkflowAction({
    required this.contract,
    required this.workflow,
    required this.view,
    required this.onPressed,
    required this.onReceivePressed,
    this.accentOverride,
    this.modernTheme,
  });

  final LoomProductionWorkflowContract contract;
  final LoomWorkflowDefinition workflow;
  final LoomRoleWorkflowView view;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;

  /// The card surface's own resolved accent, when the caller has one in
  /// scope (its tile fill/border color or the cascade-resolved theme
  /// accent) — keeps this button visually consistent with the card it sits
  /// in instead of an unrelated category-keyed color. Null keeps today's
  /// `_categoryAccentColor` fallback (used by bespoke callers that don't
  /// pass an override).
  final Color? accentOverride;

  /// Non-null only for communities that opted into the modern card theme —
  /// see `LoomSurfaceTheme.usesModernCardTheme`. Without this, this button's
  /// foreground was derived from the raw accent's own brightness
  /// (`_foregroundFor(accent)`), which assumed the surrounding card is
  /// filled with that same accent. Once a card switches to the light
  /// surface treatment, that assumption breaks — the accent is classified
  /// "dark" (so foreground resolves to white) while the card underneath is
  /// now near-white, producing a near-invisible white-on-white button.
  /// Resolving the heading color from `modernTheme` instead keeps this
  /// button legible against whichever fill the card actually has.
  final LoomCardTheme? modernTheme;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent =
        accentOverride ?? _categoryAccentColor(contract.category, scheme);
    final foreground = modernTheme?.resolvedHeading ?? _foregroundFor(accent);
    final legacyButtonStyle = FilledButton.styleFrom(
      backgroundColor: foreground.withValues(alpha: 0.14),
      foregroundColor: foreground,
      iconColor: foreground,
      side: BorderSide(color: foreground.withValues(alpha: 0.28)),
    );
    final actorButtonStyle =
        _buttonStyleFor(modernTheme?.primaryButton) ?? legacyButtonStyle;
    final receiverButtonStyle =
        _buttonStyleFor(modernTheme?.secondaryButton) ?? legacyButtonStyle;
    if (view.waitingForPrerequisite) {
      return Align(
        alignment: Alignment.centerRight,
        child: _StateBadge(
          key: ValueKey('workflow-waiting-${workflow.workflowId}'),
          icon: Icons.schedule,
          label: view.waitingText,
          foreground: foreground,
          accent: modernTheme?.accent,
        ),
      );
    }
    if (view.state == LoomRoleWorkflowState.actor) {
      return Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: ValueKey('workflow-button-${workflow.workflowId}'),
            onPressed: onPressed,
            style: actorButtonStyle,
            icon: Icon(contract.icon, size: 18),
            label: Text(
              contract.primaryActionLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    if (view.state == LoomRoleWorkflowState.receiver) {
      return Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            key: ValueKey('workflow-receive-button-${workflow.workflowId}'),
            onPressed: onReceivePressed,
            style: receiverButtonStyle,
            icon: const Icon(Icons.inbox_outlined, size: 18),
            label: Text(
              view.actionText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    if (view.state == LoomRoleWorkflowState.readOnly) {
      return Align(
        alignment: Alignment.centerRight,
        child: _StateBadge(
          key: ValueKey('workflow-read-only-${workflow.workflowId}'),
          icon: Icons.visibility_outlined,
          label: 'Read only',
          foreground: foreground,
          accent: modernTheme?.accent,
        ),
      );
    }
    return Align(
      alignment: Alignment.centerRight,
      child: _StateBadge(
        key: ValueKey('workflow-disabled-${workflow.workflowId}'),
        icon: Icons.block,
        label: view.actionText,
        foreground: foreground,
        accent: modernTheme?.accent,
      ),
    );
  }
}

class _WorkflowActionSurface extends StatelessWidget {
  const _WorkflowActionSurface({
    super.key,
    required this.workflow,
    required this.contract,
    required this.actionLabel,
    required this.confirmButtonKey,
    required this.isReceiverSurface,
    this.fallbackAccent = const Color(0xff246b62),
    this.modernTheme,
    this.onResponseSelected,
  });

  final LoomWorkflowDefinition workflow;
  final LoomProductionWorkflowContract contract;
  final String actionLabel;
  final Key confirmButtonKey;
  final bool isReceiverSurface;

  /// The cascade-resolved accent (community -> tab -> workflow) to use when
  /// this workflow has no bespoke catalog entry — see
  /// `_fallbackRichWorkflowSpecFor`.
  final Color fallbackAccent;

  /// Non-null only for communities that opted into the modern card theme —
  /// see `LoomSurfaceTheme.usesModernCardTheme`.
  final LoomCardTheme? modernTheme;

  /// Invoked with the chosen [LoomWorkflowResponseChoice.responseId] just
  /// before the surface pops `true`, when the workflow has more than one
  /// response choice (e.g. Going/Maybe/Can't go). Not invoked for receiver
  /// surfaces or single-choice workflows, which keep today's plain confirm.
  final ValueChanged<String>? onResponseSelected;

  @override
  Widget build(BuildContext context) {
    if (workflow.workflowId == 'garden-event-rsvp') {
      return _GardenEventRsvpActionSurface(
        workflow: workflow,
        actionLabel: actionLabel,
        confirmButtonKey: confirmButtonKey,
        isReceiverSurface: isReceiverSurface,
      );
    }
    if (workflow.workflowId == 'plant-exchange-submission') {
      return _GardenPlantExchangeActionSurface(
        workflow: workflow,
        actionLabel: actionLabel,
        confirmButtonKey: confirmButtonKey,
        isReceiverSurface: isReceiverSurface,
      );
    }
    final richSpec = _richWorkflowSpecFor(
      workflow.workflowId,
      workflow: workflow,
      fallbackAccent: fallbackAccent,
    );
    if (richSpec != null) {
      return _RichWorkflowActionSurface(
        workflow: workflow,
        contract: contract,
        spec: richSpec,
        actionLabel: actionLabel,
        confirmButtonKey: confirmButtonKey,
        isReceiverSurface: isReceiverSurface,
        modernTheme: modernTheme,
        onResponseSelected: onResponseSelected,
      );
    }
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accent = _categoryAccentColor(contract.category, scheme);
    final foreground = _foregroundFor(accent);
    final metadata = _domainMetadataFor(contract.category, workflow);
    final responseChoices = _responseChoicesFor(workflow, contract);
    final title = isReceiverSurface
        ? contract.receiverSurfaceTitle
        : contract.screenTitle;

    final background = modernTheme != null
        ? Color.alphaBlend(accent.withValues(alpha: 0.035), Colors.white)
        : _actionScreenBackgroundFor(accent);
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: accent,
        foregroundColor: foreground,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.close),
          tooltip: 'Close',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(contract.icon, color: scheme.onPrimary, size: 34),
                  const SizedBox(height: 14),
                  Text(
                    _domainSurfaceTitleFor(contract.category, workflow),
                    style: textTheme.headlineSmall?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _domainSurfaceLeadFor(
                      contract.category,
                      workflow,
                      isReceiverSurface: isReceiverSurface,
                    ),
                    style: textTheme.bodyLarge?.copyWith(
                      color: scheme.onPrimary.withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final detail in metadata)
                        _SurfaceFactPill(
                          icon: _metadataIconFor(detail),
                          label: detail,
                          foreground: scheme.onPrimary,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          _ActionSurfaceDetailStack(
            accent: accent,
            modernTheme: modernTheme,
            rows: [
              _ActionSurfaceDetail(
                icon: Icons.rule_folder_outlined,
                title: 'Open',
                body: contract.decisionSummary,
              ),
              _ActionSurfaceDetail(
                icon: Icons.edit_note_outlined,
                title: 'Form details',
                body:
                    '${contract.inputSummary} ${_surfaceInputFor(contract.category, workflow)}',
              ),
              _ActionSurfaceDetail(
                icon: Icons.compare_arrows_outlined,
                title: 'Alternate option',
                body:
                    '${contract.alternateActionLabel} is available before this is saved.',
              ),
              _ActionSurfaceDetail(
                icon: Icons.task_alt_outlined,
                title: 'Visible result',
                body: isReceiverSurface
                    ? _receiverBodyFor(contract.category)
                    : _surfaceOutcomeFor(contract.category, workflow),
              ),
              _ActionSurfaceDetail(
                icon: Icons.verified_user_outlined,
                title: 'Privacy boundary',
                body: _reviewTrustFor(contract.category),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!isReceiverSurface && responseChoices.length > 1)
            _WorkflowResponseChoiceBar(
              accent: accent,
              modernTheme: modernTheme,
              choices: responseChoices,
              onSelected: (responseId) {
                onResponseSelected?.call(responseId);
                Navigator.of(context).pop(true);
              },
            )
          else
            _InlineActionBar(
              accent: accent,
              modernTheme: modernTheme,
              alternateLabel: contract.alternateActionLabel,
              actionLabel: actionLabel,
              actionIcon: contract.icon,
              confirmButtonKey: confirmButtonKey,
            ),
        ],
      ),
    );
  }
}

class _RichWorkflowActionSurface extends StatelessWidget {
  const _RichWorkflowActionSurface({
    required this.workflow,
    required this.contract,
    required this.spec,
    required this.actionLabel,
    required this.confirmButtonKey,
    required this.isReceiverSurface,
    this.modernTheme,
    this.onResponseSelected,
  });

  final LoomWorkflowDefinition workflow;
  final LoomProductionWorkflowContract contract;
  final _RichWorkflowSpec spec;
  final String actionLabel;
  final Key confirmButtonKey;
  final bool isReceiverSurface;

  /// Non-null only for communities that opted into the modern card theme.
  /// The AppBar stays a solid `spec.accent` regardless (the one chrome
  /// element that stays dark by design); everything else in the body
  /// switches to the light/subtle treatment when this is set.
  final LoomCardTheme? modernTheme;
  final ValueChanged<String>? onResponseSelected;

  @override
  Widget build(BuildContext context) {
    final appBarForeground = _foregroundFor(spec.accent);
    final bodyForeground = modernTheme?.resolvedHeading ?? appBarForeground;
    final domainPreview = _domainPreviewPanelFor(
      workflow.workflowId,
      accent: spec.accent,
      foreground: bodyForeground,
    );
    if (spec.layout != _RichWorkflowLayout.standard) {
      return _RichProductActionSurface(
        workflow: workflow,
        spec: spec,
        actionLabel: actionLabel,
        confirmButtonKey: confirmButtonKey,
        isReceiverSurface: isReceiverSurface,
      );
    }
    final background = modernTheme != null
        ? Color.alphaBlend(spec.accent.withValues(alpha: 0.035), Colors.white)
        : _actionScreenBackgroundFor(spec.accent);
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(
          isReceiverSurface ? spec.receivedTitle : spec.actionSurfaceTitle,
        ),
        backgroundColor: spec.accent,
        foregroundColor: appBarForeground,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.close),
          tooltip: 'Close',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          _GardenHeroPanel(
            key: ValueKey('action-surface-hero-${workflow.workflowId}'),
            accent: spec.accent,
            modernTheme: modernTheme,
            icon: spec.icon,
            title: spec.title,
            subtitle: spec.actionHeroSubtitle,
            body: isReceiverSurface ? spec.receivedBody : spec.actionHeroBody,
          ),
          if (domainPreview != null) ...[
            const SizedBox(height: 14),
            domainPreview,
          ],
          const SizedBox(height: 14),
          _InteractionModelSummary(
            contract: contract,
            foreground: bodyForeground,
            modernTheme: modernTheme,
          ),
          const SizedBox(height: 14),
          _RichInlineActionPanel(
            accent: spec.accent,
            modernTheme: modernTheme,
            facts: spec.facts,
            title: isReceiverSurface
                ? spec.receivedTitle
                : spec.actionPanelTitle,
            body: isReceiverSurface ? spec.receivedBody : spec.actionPanelBody,
            alternateLabel: spec.alternateActionLabel,
            actionLabel: actionLabel,
            actionIcon: spec.icon,
            confirmButtonKey: confirmButtonKey,
            responseChoices: isReceiverSurface
                ? null
                : _responseChoicesFor(workflow, contract),
            onResponseSelected: onResponseSelected,
          ),
          const SizedBox(height: 16),
          _GardenDetailCard(
            accent: spec.accent,
            modernTheme: modernTheme,
            title: spec.detailTitle,
            rows: spec.detailRows,
          ),
          const SizedBox(height: 16),
          _GardenDetailCard(
            accent: spec.accent,
            modernTheme: modernTheme,
            title: spec.stateTitle,
            rows: spec.stateRows,
          ),
        ],
      ),
    );
  }
}

class _RichProductActionSurface extends StatelessWidget {
  const _RichProductActionSurface({
    required this.workflow,
    required this.spec,
    required this.actionLabel,
    required this.confirmButtonKey,
    required this.isReceiverSurface,
  });

  final LoomWorkflowDefinition workflow;
  final _RichWorkflowSpec spec;
  final String actionLabel;
  final Key confirmButtonKey;
  final bool isReceiverSurface;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(spec.accent);
    return Scaffold(
      backgroundColor: _actionScreenBackgroundFor(spec.accent),
      appBar: AppBar(
        title: Text(
          isReceiverSurface ? spec.receivedTitle : spec.actionSurfaceTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        toolbarHeight: 88,
        backgroundColor: spec.accent,
        foregroundColor: foreground,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.close),
          tooltip: 'Close',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: _actionSurfaceChildren(
          spec: spec,
          isReceiverSurface: isReceiverSurface,
          actionLabel: actionLabel,
          confirmButtonKey: confirmButtonKey,
        ),
      ),
    );
  }
}

List<Widget> _actionSurfaceChildren({
  required _RichWorkflowSpec spec,
  required bool isReceiverSurface,
  required String actionLabel,
  required Key confirmButtonKey,
}) {
  final actionBar = _InlineActionBar(
    accent: spec.accent,
    alternateLabel: spec.alternateActionLabel,
    actionLabel: actionLabel,
    actionIcon: spec.icon,
    confirmButtonKey: confirmButtonKey,
  );
  final hero = _GardenHeroPanel(
    accent: spec.accent,
    icon: spec.icon,
    title: spec.title,
    subtitle: spec.actionHeroSubtitle,
    body: isReceiverSurface ? spec.receivedBody : spec.actionHeroBody,
  );
  final details = _GardenDetailCard(
    accent: spec.accent,
    title: spec.detailTitle,
    rows: spec.detailRows,
  );
  final followUp = _GardenDetailCard(
    accent: spec.accent,
    title: _followUpTitleFor(spec.layout),
    rows: spec.stateRows,
  );
  final preview = _ProductSurfacePreview(spec: spec);
  return switch (spec.layout) {
    _RichWorkflowLayout.exportWizard => [
      _ExportWizardPreview(spec: spec),
      const SizedBox(height: 16),
      _ExportActionConsole(
        spec: spec,
        actionLabel: actionLabel,
        confirmButtonKey: confirmButtonKey,
      ),
    ],
    _RichWorkflowLayout.adEntitlement => [
      _AdEntitlementPreview(spec: spec),
      const SizedBox(height: 16),
      _AdEntitlementActionConsole(
        spec: spec,
        actionLabel: actionLabel,
        confirmButtonKey: confirmButtonKey,
      ),
    ],
    _RichWorkflowLayout.paymentReceipt => [
      _PaymentReceiptPreview(spec: spec),
      const SizedBox(height: 16),
      _PaymentActionConsole(
        spec: spec,
        actionLabel: actionLabel,
        confirmButtonKey: confirmButtonKey,
      ),
    ],
    _RichWorkflowLayout.messageThread ||
    _RichWorkflowLayout.noticeDetail ||
    _RichWorkflowLayout.searchAnswer => [
      preview,
      const SizedBox(height: 16),
      _CommunicationActionConsole(
        spec: spec,
        actionLabel: actionLabel,
        confirmButtonKey: confirmButtonKey,
      ),
      const SizedBox(height: 16),
      details,
    ],
    _RichWorkflowLayout.eventDetail => [
      _EventDetailPreview(spec: spec),
      const SizedBox(height: 16),
      _EventActionConsole(
        spec: spec,
        actionLabel: actionLabel,
        confirmButtonKey: confirmButtonKey,
      ),
    ],
    _RichWorkflowLayout.rosterProfile => [
      _RosterProfilePreview(spec: spec),
      const SizedBox(height: 16),
      _RosterActionConsole(
        spec: spec,
        actionLabel: actionLabel,
        confirmButtonKey: confirmButtonKey,
      ),
      const SizedBox(height: 16),
      details,
    ],
    _RichWorkflowLayout.clubScoreboard => [
      _ClubScoreboardPreview(spec: spec),
      const SizedBox(height: 16),
      _ClubActionConsole(
        spec: spec,
        actionLabel: actionLabel,
        confirmButtonKey: confirmButtonKey,
      ),
    ],
    _RichWorkflowLayout.formSubmission ||
    _RichWorkflowLayout.requestReview ||
    _RichWorkflowLayout.mediaReview => [
      preview,
      const SizedBox(height: 16),
      _FormActionConsole(
        spec: spec,
        actionLabel: actionLabel,
        confirmButtonKey: confirmButtonKey,
      ),
    ],
    _ => [
      hero,
      const SizedBox(height: 14),
      preview,
      const SizedBox(height: 16),
      actionBar,
      const SizedBox(height: 16),
      details,
      const SizedBox(height: 16),
      followUp,
    ],
  };
}

String _followUpTitleFor(_RichWorkflowLayout layout) {
  return switch (layout) {
    _RichWorkflowLayout.eventDetail => 'After you respond',
    _RichWorkflowLayout.formSubmission => 'After submission',
    _RichWorkflowLayout.paymentReceipt => 'Receipt and account',
    _RichWorkflowLayout.rosterProfile => 'Role visibility',
    _RichWorkflowLayout.requestReview => 'Request outcome',
    _RichWorkflowLayout.searchAnswer => 'Saved answer',
    _RichWorkflowLayout.exportWizard => 'After export',
    _RichWorkflowLayout.messageThread => 'After message',
    _RichWorkflowLayout.noticeDetail => 'After delivery',
    _RichWorkflowLayout.clubScoreboard => 'Club record',
    _RichWorkflowLayout.mediaReview => 'After critique',
    _RichWorkflowLayout.adEntitlement => 'Ad-free account',
    _ => 'Next steps',
  };
}

String _resultTitleFor(_RichWorkflowLayout layout) {
  return switch (layout) {
    _RichWorkflowLayout.eventDetail => 'Attendance saved',
    _RichWorkflowLayout.formSubmission => 'Submitted request',
    _RichWorkflowLayout.paymentReceipt => 'Receipt saved',
    _RichWorkflowLayout.rosterProfile => 'Visibility updated',
    _RichWorkflowLayout.requestReview => 'Request updated',
    _RichWorkflowLayout.searchAnswer => 'Answer saved',
    _RichWorkflowLayout.exportWizard => 'Export progress',
    _RichWorkflowLayout.messageThread => 'Thread updated',
    _RichWorkflowLayout.noticeDetail => 'Message delivered',
    _RichWorkflowLayout.clubScoreboard => 'Club result saved',
    _RichWorkflowLayout.mediaReview => 'Critique state',
    _RichWorkflowLayout.adEntitlement => 'Ad setting saved',
    _ => 'Result and next step',
  };
}

List<_ActionSurfaceDetail> _actionProofRowsFor(_RichWorkflowLayout layout) {
  return switch (layout) {
    _RichWorkflowLayout.eventDetail => const [
      _ActionSurfaceDetail(
        icon: Icons.event_outlined,
        title: 'Event details',
        body:
            'Title, date, time, location, host, capacity, and current attendance are visible before responding.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.how_to_reg_outlined,
        title: 'Attendance options',
        body:
            'Going, Maybe, Not going, and Change response remain available while the event is open.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.notifications_active_outlined,
        title: 'Member reminder',
        body:
            'The saved response keeps calendar, reminder, and capacity status visible.',
      ),
    ],
    _RichWorkflowLayout.paymentReceipt => const [
      _ActionSurfaceDetail(
        icon: Icons.payments_outlined,
        title: 'Payment context',
        body:
            'Amount, payer, recipient, method, visibility, and retry/refund path are visible before checkout.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.receipt_long_outlined,
        title: 'Receipt',
        body:
            'Receipt destination, payment status, entitlement, and history are kept after payment.',
      ),
    ],
    _RichWorkflowLayout.exportWizard => const [
      _ActionSurfaceDetail(
        icon: Icons.inventory_2_outlined,
        title: 'Export scope',
        body:
            'Selected records, redaction choices, destination, file size, and checksum are shown as export steps.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.verified_outlined,
        title: 'Verification and recovery',
        body:
            'Download, retry, cancel, rollback, and audit status stay visible after the export action.',
      ),
    ],
    _RichWorkflowLayout.messageThread ||
    _RichWorkflowLayout.noticeDetail => const [
      _ActionSurfaceDetail(
        icon: Icons.person_outline,
        title: 'Sender and receiver',
        body:
            'Sender, recipient or audience, timestamp, body, and delivery channel are visible.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.forum_outlined,
        title: 'Conversation state',
        body:
            'Reply, read/unread, archive, mute, block, draft, or resend actions match the message state.',
      ),
    ],
    _RichWorkflowLayout.searchAnswer => const [
      _ActionSurfaceDetail(
        icon: Icons.search_outlined,
        title: 'Query and answer',
        body:
            'The user sees the query, answer, citations, source visibility, and follow-up options.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.bookmark_border_outlined,
        title: 'Saved citation state',
        body:
            'Save, share, refine, and stale-source handling are visible after opening the result.',
      ),
    ],
    _RichWorkflowLayout.adEntitlement => const [
      _ActionSurfaceDetail(
        icon: Icons.block_outlined,
        title: 'Ad-free account',
        body:
            'Entitlement scope, renewal or expiry, receipt link, restore/manage action, and affected ad slots are visible.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Receipt or settlement',
        body:
            'Payment receipt, settlement ID, utility allocation, audit status, correction, and rollback path remain visible where applicable.',
      ),
    ],
    _RichWorkflowLayout.rosterProfile => const [
      _ActionSurfaceDetail(
        icon: Icons.groups_outlined,
        title: 'Roster records',
        body:
            'Member names, roles, counts, status, and protected fields are visible according to the active actor identity.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.privacy_tip_outlined,
        title: 'Protected visibility',
        body:
            'Hidden, redacted, filter, message, and export actions follow the role policy.',
      ),
    ],
    _RichWorkflowLayout.clubScoreboard => const [
      _ActionSurfaceDetail(
        icon: Icons.how_to_vote_outlined,
        title: 'Choice and standing',
        body:
            'Nominations, ballot options, selected title, match result, or standings are visible before saving.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.timeline_outlined,
        title: 'Open result',
        body:
            'Change vote, dispute score, view results, and next meeting or round stay available.',
      ),
    ],
    _RichWorkflowLayout.mediaReview => const [
      _ActionSurfaceDetail(
        icon: Icons.image_outlined,
        title: 'Submission artifact',
        body:
            'Image, caption, consent, prompt, reviewer, and comment status are visible.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.rate_review_outlined,
        title: 'Critique path',
        body:
            'Edit, withdraw, request feedback, and reviewer result remain attached to the image.',
      ),
    ],
    _RichWorkflowLayout.formSubmission ||
    _RichWorkflowLayout.requestReview => const [
      _ActionSurfaceDetail(
        icon: Icons.edit_note_outlined,
        title: 'Submitted fields',
        body:
            'Labeled fields, privacy indicators, attachments, assignee, and status are visible.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.rule_outlined,
        title: 'Review path',
        body:
            'Edit, withdraw, approve, reject, request changes, reopen, or appeal actions match the state.',
      ),
    ],
    _ => const [
      _ActionSurfaceDetail(
        icon: Icons.info_outline,
        title: 'Task context',
        body:
            'The screen shows the object, useful details, available actions, and saved result for this community task.',
      ),
    ],
  };
}

class _EventActionConsole extends StatelessWidget {
  const _EventActionConsole({
    required this.spec,
    required this.actionLabel,
    required this.confirmButtonKey,
  });

  final _RichWorkflowSpec spec;
  final String actionLabel;
  final Key confirmButtonKey;

  @override
  Widget build(BuildContext context) {
    return _DomainActionConsole(
      spec: spec,
      title: 'Choose attendance',
      body:
          'Event date, capacity, location, host note, and reminders are visible before choosing Going, Maybe, or Not going.',
      primaryLabel: actionLabel,
      alternateLabels: const ['Maybe', 'Not going', 'Change later'],
      primaryIcon: Icons.event_available_outlined,
      leadingRows: spec.detailRows.take(3).toList(),
      resultRows: spec.stateRows.take(3).toList(),
      confirmButtonKey: confirmButtonKey,
    );
  }
}

class _FormActionConsole extends StatelessWidget {
  const _FormActionConsole({
    required this.spec,
    required this.actionLabel,
    required this.confirmButtonKey,
  });

  final _RichWorkflowSpec spec;
  final String actionLabel;
  final Key confirmButtonKey;

  @override
  Widget build(BuildContext context) {
    final labels = spec.layout == _RichWorkflowLayout.mediaReview
        ? const ['Edit submission', 'Withdraw', 'Request feedback']
        : const ['Edit details', 'Save draft', 'Cancel request'];
    return _DomainActionConsole(
      spec: spec,
      title: spec.layout == _RichWorkflowLayout.mediaReview
          ? 'Submission review'
          : 'Submitted request',
      body:
          'Labeled fields, privacy handling, assignee, and status are visible before submitting or editing.',
      primaryLabel: actionLabel,
      alternateLabels: labels,
      primaryIcon: spec.icon,
      leadingRows: spec.detailRows.take(4).toList(),
      resultRows: spec.stateRows.take(3).toList(),
      confirmButtonKey: confirmButtonKey,
    );
  }
}

class _PaymentActionConsole extends StatelessWidget {
  const _PaymentActionConsole({
    required this.spec,
    required this.actionLabel,
    required this.confirmButtonKey,
  });

  final _RichWorkflowSpec spec;
  final String actionLabel;
  final Key confirmButtonKey;

  @override
  Widget build(BuildContext context) {
    return _DomainActionConsole(
      spec: spec,
      title: 'Checkout and receipt',
      body:
          'Payer, amount, privacy choice, entitlement, receipt destination, and retry/refund options are visible.',
      primaryLabel: actionLabel,
      alternateLabels: const ['Change amount', 'Use another method', 'Cancel'],
      primaryIcon: Icons.receipt_long_outlined,
      leadingRows: spec.detailRows.take(3).toList(),
      resultRows: spec.stateRows.take(4).toList(),
      confirmButtonKey: confirmButtonKey,
    );
  }
}

class _AdEntitlementActionConsole extends StatelessWidget {
  const _AdEntitlementActionConsole({
    required this.spec,
    required this.actionLabel,
    required this.confirmButtonKey,
  });

  final _RichWorkflowSpec spec;
  final String actionLabel;
  final Key confirmButtonKey;

  @override
  Widget build(BuildContext context) {
    final text = '${spec.title} ${spec.subtitle}'.toLowerCase();
    final settlement = text.contains('settlement');
    final account =
        text.contains('ad-off') ||
        text.contains('ad-free') ||
        text.contains('entitlement') ||
        text.contains('receipt') ||
        settlement;
    return _DomainActionConsole(
      spec: spec,
      title: settlement
          ? 'Settlement and audit'
          : account
          ? 'Ad-free account controls'
          : 'Sponsored-message controls',
      body: settlement
          ? 'Review funded amount, settlement ID, utility impact, audit status, and correction or rollback path.'
          : account
          ? 'Review entitlement, renewal, receipt, restore/manage action, and affected ad slots.'
          : 'Review reserved slot behavior, disclosure, no-fill reason, entitlement, receipt, and restore option.',
      primaryLabel: actionLabel,
      alternateLabels: settlement
          ? const ['Correct allocation', 'Rollback', 'Export audit']
          : account
          ? const ['Manage subscription', 'Restore purchase', 'Open receipt']
          : const ['Manage entitlement', 'Report ad issue', 'Restore receipt'],
      primaryIcon: Icons.block_outlined,
      leadingRows: spec.detailRows.take(4).toList(),
      resultRows: spec.stateRows.take(4).toList(),
      confirmButtonKey: confirmButtonKey,
    );
  }
}

class _ExportActionConsole extends StatelessWidget {
  const _ExportActionConsole({
    required this.spec,
    required this.actionLabel,
    required this.confirmButtonKey,
  });

  final _RichWorkflowSpec spec;
  final String actionLabel;
  final Key confirmButtonKey;

  @override
  Widget build(BuildContext context) {
    final text = '${spec.title} ${spec.subtitle}'.toLowerCase();
    final alternates = text.contains('rollback')
        ? const ['Start rollback', 'Retry transfer', 'Keep current']
        : text.contains('checksum')
        ? const ['Verify checksum', 'Download receipt', 'Retry']
        : text.contains('schema')
        ? const ['Exclude schema', 'Open fields', 'Keep selected']
        : const ['Change scope', 'Preview redaction', 'Retry export'];
    return _DomainActionConsole(
      spec: spec,
      title: 'Export workspace',
      body:
          'Scope, redaction, checksum, destination, transfer status, rollback, and audit evidence are visible.',
      primaryLabel: actionLabel,
      alternateLabels: alternates,
      primaryIcon: Icons.folder_zip_outlined,
      leadingRows: spec.detailRows.take(4).toList(),
      resultRows: spec.stateRows.take(4).toList(),
      confirmButtonKey: confirmButtonKey,
    );
  }
}

class _CommunicationActionConsole extends StatelessWidget {
  const _CommunicationActionConsole({
    required this.spec,
    required this.actionLabel,
    required this.confirmButtonKey,
  });

  final _RichWorkflowSpec spec;
  final String actionLabel;
  final Key confirmButtonKey;

  @override
  Widget build(BuildContext context) {
    final notice = spec.layout == _RichWorkflowLayout.noticeDetail;
    final search = spec.layout == _RichWorkflowLayout.searchAnswer;
    return _DomainActionConsole(
      spec: spec,
      title: search
          ? 'Answer actions'
          : notice
          ? 'Delivery actions'
          : 'Thread actions',
      body: search
          ? 'Open cited sources, save the answer, refine the query, or share it with members.'
          : notice
          ? 'Review audience, sender, message body, timing, and receiver state before sending.'
          : 'Read sender, body, timestamp, and choose reply, mute, archive, or block.',
      primaryLabel: actionLabel,
      alternateLabels: search
          ? const ['Open sources', 'Refine query', 'Save for later']
          : notice
          ? const ['Preview', 'Save draft', 'Change audience']
          : const ['Reply', 'Mute', 'Archive'],
      primaryIcon: spec.icon,
      leadingRows: spec.detailRows.take(4).toList(),
      resultRows: spec.stateRows.take(3).toList(),
      confirmButtonKey: confirmButtonKey,
    );
  }
}

class _RosterActionConsole extends StatelessWidget {
  const _RosterActionConsole({
    required this.spec,
    required this.actionLabel,
    required this.confirmButtonKey,
  });

  final _RichWorkflowSpec spec;
  final String actionLabel;
  final Key confirmButtonKey;

  @override
  Widget build(BuildContext context) {
    return _DomainActionConsole(
      spec: spec,
      title: 'Roster visibility',
      body:
          'Review member names, role-filtered details, protected fields, and who can see each item.',
      primaryLabel: actionLabel,
      alternateLabels: const [
        'Filter roster',
        'Hide protected fields',
        'Export list',
      ],
      primaryIcon: Icons.people_alt_outlined,
      leadingRows: spec.detailRows.take(4).toList(),
      resultRows: spec.stateRows.take(3).toList(),
      confirmButtonKey: confirmButtonKey,
    );
  }
}

class _ClubActionConsole extends StatelessWidget {
  const _ClubActionConsole({
    required this.spec,
    required this.actionLabel,
    required this.confirmButtonKey,
  });

  final _RichWorkflowSpec spec;
  final String actionLabel;
  final Key confirmButtonKey;

  @override
  Widget build(BuildContext context) {
    return _DomainActionConsole(
      spec: spec,
      title: 'Club record',
      body:
          'Review players, round, score, result, standings impact, and next club action.',
      primaryLabel: actionLabel,
      alternateLabels: const ['Edit score', 'Dispute result', 'Open standings'],
      primaryIcon: Icons.emoji_events_outlined,
      leadingRows: spec.detailRows.take(4).toList(),
      resultRows: spec.stateRows.take(3).toList(),
      confirmButtonKey: confirmButtonKey,
    );
  }
}

class _DomainActionConsole extends StatelessWidget {
  const _DomainActionConsole({
    required this.spec,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.alternateLabels,
    required this.primaryIcon,
    required this.leadingRows,
    required this.resultRows,
    required this.confirmButtonKey,
  });

  final _RichWorkflowSpec spec;
  final String title;
  final String body;
  final String primaryLabel;
  final List<String> alternateLabels;
  final IconData primaryIcon;
  final List<_ActionSurfaceDetail> leadingRows;
  final List<_ActionSurfaceDetail> resultRows;
  final Key confirmButtonKey;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(spec.accent);
    final textTheme = Theme.of(context).textTheme;
    final proofRows = _actionProofRowsFor(spec.layout);
    final outlined = OutlinedButton.styleFrom(
      foregroundColor: foreground,
      side: BorderSide(color: foreground.withValues(alpha: 0.35)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: foreground.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: foreground),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleLarge?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                style: textTheme.bodyMedium?.copyWith(
                  color: foreground.withValues(alpha: 0.88),
                ),
              ),
              const SizedBox(height: 12),
              for (final row in proofRows)
                _ProductPreviewLine(
                  icon: row.icon,
                  title: row.title,
                  body: row.body,
                ),
              const SizedBox(height: 4),
              for (final row in leadingRows)
                _ProductPreviewLine(
                  icon: row.icon,
                  title: row.title,
                  body: row.body,
                ),
              const SizedBox(height: 2),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final label in alternateLabels.take(3))
                    OutlinedButton(
                      onPressed: () {},
                      style: outlined,
                      child: Text(label),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: confirmButtonKey,
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: Icon(primaryIcon, size: 18),
                  label: Text(primaryLabel, textAlign: TextAlign.center),
                ),
              ),
              if (resultRows.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Text(
                  _resultTitleFor(spec.layout),
                  style: textTheme.titleMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                for (final row in resultRows)
                  _ProductPreviewLine(
                    icon: row.icon,
                    title: row.title,
                    body: row.body,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GardenEventRsvpActionSurface extends StatelessWidget {
  const _GardenEventRsvpActionSurface({
    required this.workflow,
    required this.actionLabel,
    required this.confirmButtonKey,
    required this.isReceiverSurface,
  });

  final LoomWorkflowDefinition workflow;
  final String actionLabel;
  final Key confirmButtonKey;
  final bool isReceiverSurface;

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xff2f6f9f);
    final foreground = _foregroundFor(accent);
    return Scaffold(
      backgroundColor: _actionScreenBackgroundFor(accent),
      appBar: AppBar(
        title: Text(isReceiverSurface ? 'Event update' : 'Spring Workshop'),
        backgroundColor: accent,
        foregroundColor: foreground,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.close),
          tooltip: 'Close',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          _GardenHeroPanel(
            accent: accent,
            icon: Icons.event_available_outlined,
            title: 'Spring Planting Workshop',
            subtitle: 'Saturday, Apr 18 at 10:00 AM - Riverside Greenhouse',
            body:
                'Join the club for bed prep, seedling setup, and a shared planning session before the spring exchange opens.',
          ),
          const SizedBox(height: 14),
          _GardenRsvpChoicePanel(
            accent: accent,
            actionLabel: actionLabel,
            confirmButtonKey: confirmButtonKey,
          ),
          const SizedBox(height: 16),
          _GardenDetailCard(
            accent: accent,
            title: 'Event details',
            rows: const [
              _ActionSurfaceDetail(
                icon: Icons.person_outline,
                title: 'Host',
                body: 'Maya Chen, Garden Club coordinator',
              ),
              _ActionSurfaceDetail(
                icon: Icons.group_outlined,
                title: 'Capacity',
                body: '18 members going, 6 spots left, waitlist opens at 24.',
              ),
              _ActionSurfaceDetail(
                icon: Icons.place_outlined,
                title: 'Location',
                body:
                    'Riverside Greenhouse, north entrance. Bring gloves and a labeled seed tray.',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _GardenDetailCard(
            accent: accent,
            title: 'Your response',
            rows: [
              const _ActionSurfaceDetail(
                icon: Icons.check_circle_outline,
                title: 'Going',
                body:
                    'Reserve your spot and receive the morning reminder in your community inbox.',
              ),
              const _ActionSurfaceDetail(
                icon: Icons.help_outline,
                title: 'Maybe',
                body:
                    'Keep the event on your calendar without taking a capacity spot yet.',
              ),
              const _ActionSurfaceDetail(
                icon: Icons.swap_horiz_outlined,
                title: 'Change later',
                body:
                    'You can change response before Saturday; the attendee count updates for everyone.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GardenPlantExchangeActionSurface extends StatelessWidget {
  const _GardenPlantExchangeActionSurface({
    required this.workflow,
    required this.actionLabel,
    required this.confirmButtonKey,
    required this.isReceiverSurface,
  });

  final LoomWorkflowDefinition workflow;
  final String actionLabel;
  final Key confirmButtonKey;
  final bool isReceiverSurface;

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xff3f7f4c);
    final foreground = _foregroundFor(accent);
    return Scaffold(
      backgroundColor: _actionScreenBackgroundFor(accent),
      appBar: AppBar(
        title: Text(isReceiverSurface ? 'Plant offer' : 'Offer a plant'),
        backgroundColor: accent,
        foregroundColor: foreground,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.close),
          tooltip: 'Close',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          _GardenHeroPanel(
            accent: accent,
            icon: Icons.local_florist_outlined,
            title: 'Basil seedlings',
            subtitle: 'Sweet Genovese - 6 starter pots',
            body:
                'Share healthy starts with nearby members and choose exactly what contact details are visible after a claim.',
          ),
          const SizedBox(height: 14),
          _GardenInlineActionPanel(
            accent: accent,
            title: 'Marketplace listing',
            body:
                'Confirm the variety, pickup window, and privacy note before the offer appears on the plant exchange board.',
            alternateLabel: 'Edit offer',
            actionLabel: actionLabel,
            actionIcon: Icons.local_florist_outlined,
            confirmButtonKey: confirmButtonKey,
          ),
          const SizedBox(height: 16),
          _GardenDetailCard(
            accent: accent,
            title: 'Offer preview',
            rows: const [
              _ActionSurfaceDetail(
                icon: Icons.grass_outlined,
                title: 'Plant details',
                body:
                    'Sweet Genovese basil, six starter pots, rooted and ready for transplant this week.',
              ),
              _ActionSurfaceDetail(
                icon: Icons.schedule_outlined,
                title: 'Pickup',
                body:
                    'Saturday 1-3 PM at the community shed, with porch pickup available if weather changes.',
              ),
              _ActionSurfaceDetail(
                icon: Icons.person_outline,
                title: 'Shared with claimants',
                body:
                    'First name and in-app contact only. Phone and address stay private until you confirm.',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _GardenDetailCard(
            accent: accent,
            title: 'Member marketplace state',
            rows: const [
              _ActionSurfaceDetail(
                icon: Icons.storefront_outlined,
                title: 'Board placement',
                body:
                    'Appears under Available plants with variety, quantity, pickup window, and claim status.',
              ),
              _ActionSurfaceDetail(
                icon: Icons.edit_note_outlined,
                title: 'Edit or cancel',
                body:
                    'You can edit quantity, pickup time, or cancel if all seedlings are claimed elsewhere.',
              ),
              _ActionSurfaceDetail(
                icon: Icons.verified_user_outlined,
                title: 'Privacy',
                body:
                    'Claim requests are routed through Loom so contact details remain protected.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GardenRsvpChoicePanel extends StatelessWidget {
  const _GardenRsvpChoicePanel({
    required this.accent,
    required this.actionLabel,
    required this.confirmButtonKey,
  });

  final Color accent;
  final String actionLabel;
  final Key confirmButtonKey;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(accent);
    final textTheme = Theme.of(context).textTheme;
    final buttonStyle = OutlinedButton.styleFrom(
      foregroundColor: foreground,
      side: BorderSide(color: foreground.withValues(alpha: 0.30)),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: foreground.withValues(alpha: 0.20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose your response',
              style: textTheme.titleMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your RSVP updates the attendee count and leaves a reminder in your community inbox.',
              style: textTheme.bodyMedium?.copyWith(
                color: foreground.withValues(alpha: 0.90),
              ),
            ),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _GardenFactPill(icon: Icons.group_outlined, label: '18 going'),
                _GardenFactPill(
                  icon: Icons.event_seat_outlined,
                  label: '6 spots left',
                ),
                _GardenFactPill(
                  icon: Icons.lock_open_outlined,
                  label: 'RSVP open',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Going'),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  style: buttonStyle,
                  icon: const Icon(Icons.help_outline, size: 18),
                  label: const Text('Maybe'),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  style: buttonStyle,
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Not going'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Maybe later'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    key: confirmButtonKey,
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.event_available_outlined, size: 18),
                    label: Text(actionLabel, textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GardenInlineActionPanel extends StatelessWidget {
  const _GardenInlineActionPanel({
    required this.accent,
    required this.title,
    required this.body,
    required this.alternateLabel,
    required this.actionLabel,
    required this.actionIcon,
    required this.confirmButtonKey,
  });

  final Color accent;
  final String title;
  final String body;
  final String alternateLabel;
  final String actionLabel;
  final IconData actionIcon;
  final Key confirmButtonKey;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(accent);
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: foreground.withValues(alpha: 0.20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: textTheme.bodyMedium?.copyWith(
                color: foreground.withValues(alpha: 0.90),
              ),
            ),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _GardenFactPill(
                  icon: Icons.verified_user_outlined,
                  label: 'Contact after claim',
                ),
                _GardenFactPill(
                  icon: Icons.lock_outline,
                  label: 'Phone/address private',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  key: confirmButtonKey,
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: Icon(actionIcon, size: 18),
                  label: Text(
                    actionLabel,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: foreground,
                    side: BorderSide(color: foreground.withValues(alpha: 0.28)),
                  ),
                  icon: const Icon(Icons.compare_arrows_outlined, size: 18),
                  label: Text(
                    alternateLabel,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RichInlineActionPanel extends StatelessWidget {
  const _RichInlineActionPanel({
    required this.accent,
    this.modernTheme,
    required this.facts,
    required this.title,
    required this.body,
    required this.alternateLabel,
    required this.actionLabel,
    required this.actionIcon,
    required this.confirmButtonKey,
    this.responseChoices,
    this.onResponseSelected,
  });

  final Color accent;
  final LoomCardTheme? modernTheme;
  final List<_RichFact> facts;
  final String title;
  final String body;
  final String alternateLabel;
  final String actionLabel;
  final IconData actionIcon;
  final Key confirmButtonKey;

  /// When this has more than one entry, a real branching response bar
  /// (e.g. Going/Maybe/Can't go) replaces the plain confirm/cancel pair
  /// below, and [onResponseSelected] is invoked with the chosen
  /// [LoomWorkflowResponseChoice.responseId] before popping `true`.
  final List<LoomWorkflowResponseChoice>? responseChoices;
  final ValueChanged<String>? onResponseSelected;

  @override
  Widget build(BuildContext context) {
    final foreground = modernTheme?.resolvedHeading ?? _foregroundFor(accent);
    final bodyColor =
        modernTheme?.resolvedBody ?? foreground.withValues(alpha: 0.90);
    final textTheme = Theme.of(context).textTheme;
    final primaryStyle = _buttonStyleFor(modernTheme?.primaryButton);
    final cancelForeground = modernTheme?.accent ?? foreground;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: modernTheme?.resolvedFill ?? foreground.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              modernTheme?.resolvedBorder ?? foreground.withValues(alpha: 0.20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(body, style: textTheme.bodyMedium?.copyWith(color: bodyColor)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final fact in facts)
                  _SurfaceFactPill(
                    icon: fact.icon,
                    label: fact.label,
                    foreground: foreground,
                    accent: modernTheme?.accent,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (responseChoices != null && responseChoices!.length > 1)
              _WorkflowResponseChoiceBar(
                accent: accent,
                modernTheme: modernTheme,
                choices: responseChoices!,
                onSelected: (responseId) {
                  onResponseSelected?.call(responseId);
                  Navigator.of(context).pop(true);
                },
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 360;
                  final primary = FilledButton.icon(
                    key: confirmButtonKey,
                    onPressed: () => Navigator.of(context).pop(true),
                    style: primaryStyle,
                    icon: compact
                        ? const SizedBox.shrink()
                        : Icon(actionIcon, size: 18),
                    label: Text(
                      actionLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  );
                  final secondary = TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: modernTheme != null
                        ? TextButton.styleFrom(
                            foregroundColor: cancelForeground,
                          )
                        : null,
                    child: Text(
                      alternateLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        primary,
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: secondary,
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      secondary,
                      const SizedBox(width: 12),
                      Expanded(child: primary),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _InlineActionBar extends StatelessWidget {
  const _InlineActionBar({
    required this.accent,
    this.modernTheme,
    required this.alternateLabel,
    required this.actionLabel,
    required this.actionIcon,
    required this.confirmButtonKey,
  });

  final Color accent;
  final LoomCardTheme? modernTheme;
  final String alternateLabel;
  final String actionLabel;
  final IconData actionIcon;
  final Key confirmButtonKey;

  @override
  Widget build(BuildContext context) {
    final foreground = modernTheme?.resolvedHeading ?? _foregroundFor(accent);
    final primaryStyle = _buttonStyleFor(modernTheme?.primaryButton);
    final cancelForeground = modernTheme?.accent ?? foreground;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: modernTheme?.resolvedFill ?? foreground.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              modernTheme?.resolvedBorder ?? foreground.withValues(alpha: 0.20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: modernTheme != null
                  ? TextButton.styleFrom(foregroundColor: cancelForeground)
                  : null,
              child: Text(alternateLabel),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                key: confirmButtonKey,
                onPressed: () => Navigator.of(context).pop(true),
                style: primaryStyle,
                icon: Icon(actionIcon, size: 18),
                label: Text(actionLabel, textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Real branching response surface for workflows with more than one
/// [LoomWorkflowResponseChoice] (e.g. Going/Maybe/Can't go, or
/// Approve/Reject/Request changes) — replaces the generic confirm/cancel
/// pair with one button per real outcome.
class _WorkflowResponseChoiceBar extends StatelessWidget {
  const _WorkflowResponseChoiceBar({
    required this.accent,
    this.modernTheme,
    required this.choices,
    required this.onSelected,
  });

  final Color accent;
  final LoomCardTheme? modernTheme;
  final List<LoomWorkflowResponseChoice> choices;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final foreground = modernTheme?.resolvedHeading ?? _foregroundFor(accent);
    final errorColor = Theme.of(context).colorScheme.error;
    final primaryStyle = _buttonStyleFor(modernTheme?.primaryButton);
    final secondaryStyle = _buttonStyleFor(modernTheme?.secondaryButton);
    final firstNonDestructiveId = choices
        .firstWhere(
          (choice) => !choice.isDestructive,
          orElse: () => choices.first,
        )
        .responseId;
    return DecoratedBox(
      key: const ValueKey('workflow-response-choice-bar'),
      decoration: BoxDecoration(
        color: modernTheme?.resolvedFill ?? foreground.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              modernTheme?.resolvedBorder ?? foreground.withValues(alpha: 0.20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final choice in choices) ...[
              FilledButton.icon(
                key: ValueKey('workflow-response-${choice.responseId}'),
                style: choice.isDestructive
                    ? FilledButton.styleFrom(backgroundColor: errorColor)
                    : (choice.responseId == firstNonDestructiveId
                          ? primaryStyle
                          : secondaryStyle),
                onPressed: () => onSelected(choice.responseId),
                icon: Icon(choice.icon, size: 18),
                label: Text(choice.label, textAlign: TextAlign.center),
              ),
              if (choice != choices.last) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _GardenHeroPanel extends StatelessWidget {
  const _GardenHeroPanel({
    super.key,
    required this.accent,
    this.modernTheme,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
  });

  final Color accent;

  /// Non-null only for the generic standard-layout action surface when its
  /// community opted into the modern card theme. The two truly-bespoke
  /// garden action surfaces never pass this, so they keep today's exact
  /// solid-`accent` rendering.
  final LoomCardTheme? modernTheme;
  final IconData icon;
  final String title;
  final String subtitle;
  final String body;

  @override
  Widget build(BuildContext context) {
    final foreground = modernTheme?.resolvedHeading ?? _foregroundFor(accent);
    final fill = modernTheme?.resolvedFill ?? accent;
    final subtitleColor =
        modernTheme?.resolvedBody ?? foreground.withValues(alpha: 0.92);
    final bodyColor =
        modernTheme?.resolvedBody ?? foreground.withValues(alpha: 0.90);
    final shadow =
        modernTheme?.resolvedShadow ?? accent.withValues(alpha: 0.22);
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
        border: modernTheme != null
            ? Border.all(color: modernTheme!.resolvedBorder)
            : null,
        boxShadow: [
          BoxShadow(color: shadow, blurRadius: 18, offset: const Offset(0, 10)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: foreground.withValues(alpha: 0.14),
              child: Icon(icon, color: foreground, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: textTheme.headlineSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: textTheme.titleMedium?.copyWith(
                color: subtitleColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(body, style: textTheme.bodyLarge?.copyWith(color: bodyColor)),
          ],
        ),
      ),
    );
  }
}

class _GardenDetailCard extends StatelessWidget {
  const _GardenDetailCard({
    required this.accent,
    this.modernTheme,
    required this.title,
    required this.rows,
  });

  final Color accent;
  final LoomCardTheme? modernTheme;
  final String title;
  final List<_ActionSurfaceDetail> rows;

  @override
  Widget build(BuildContext context) {
    final surface =
        modernTheme?.resolvedFill ??
        Color.alphaBlend(accent.withValues(alpha: 0.84), Colors.black);
    final foreground = modernTheme?.resolvedHeading ?? _foregroundFor(surface);
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              modernTheme?.resolvedBorder ?? foreground.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.titleLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            _ActionSurfaceDetailStack(
              accent: accent,
              modernTheme: modernTheme,
              rows: rows,
            ),
          ],
        ),
      ),
    );
  }
}
