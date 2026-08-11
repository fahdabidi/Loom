part of '../loom_communities_app_shell.dart';

class _GardenEventRsvpTile extends StatelessWidget {
  const _GardenEventRsvpTile({
    required this.workflow,
    required this.view,
    required this.onPressed,
    required this.onReceivePressed,
  });

  final LoomWorkflowDefinition workflow;
  final LoomPersonaWorkflowView view;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xff2f6f9f);
    final foreground = _foregroundFor(accent);
    final textTheme = Theme.of(context).textTheme;
    final complete = view.completed || view.received;
    return DecoratedBox(
      key: ValueKey('workflow-${workflow.workflowId}'),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: foreground.withValues(alpha: 0.13),
                  child: Icon(
                    Icons.event_available_outlined,
                    color: foreground,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spring Planting Workshop',
                        style: textTheme.titleLarge?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Hands-on bed prep, seedling swap, and seasonal planning with Garden Club members.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: foreground.withValues(alpha: 0.90),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _GardenFactPill(
                  icon: Icons.calendar_today_outlined,
                  label: 'Sat, Apr 18',
                ),
                _GardenFactPill(
                  icon: Icons.schedule_outlined,
                  label: '10:00 AM',
                ),
                _GardenFactPill(
                  icon: Icons.place_outlined,
                  label: 'Riverside Greenhouse',
                ),
                _GardenFactPill(
                  icon: Icons.group_outlined,
                  label: '18 of 24 spots',
                ),
              ],
            ),
            const SizedBox(height: 14),
            DecoratedBox(
              decoration: BoxDecoration(
                color: foreground.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: foreground.withValues(alpha: 0.20)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complete ? 'Your RSVP: Going' : 'Your RSVP',
                      style: textTheme.titleMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      complete
                          ? 'A reminder is set for Saturday morning. You can still change your response before capacity closes.'
                          : 'Choose Going, Maybe, or Not going after checking the schedule, location, host, and capacity.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: foreground.withValues(alpha: 0.90),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (view.completed)
              _WorkflowResultPanel(
                key: ValueKey('workflow-result-${workflow.workflowId}'),
                title: 'RSVP confirmed',
                body:
                    'You are going to Spring Planting Workshop. Calendar, attendee count, and reminder status stay visible.',
                icon: Icons.event_available_outlined,
                accent: accent,
              )
            else if (view.received)
              _WorkflowResultPanel(
                key: ValueKey(
                  'workflow-received-result-${workflow.workflowId}',
                ),
                title: 'Event update ready',
                body:
                    'The event page shows your attendance choice, capacity, and any schedule changes.',
                icon: Icons.inbox_outlined,
                accent: accent,
              )
            else
              _WorkflowAction(
                contract: productionWorkflowContractFor(
                  extensionId: 'ext_garden_club',
                  workflow: workflow,
                ),
                workflow: workflow,
                view: view,
                onPressed: onPressed,
                onReceivePressed: onReceivePressed,
              ),
            if (complete)
              Align(
                alignment: Alignment.centerRight,
                child: _StateBadge(
                  key: ValueKey(
                    view.completed
                        ? 'workflow-complete-${workflow.workflowId}'
                        : 'workflow-received-${workflow.workflowId}',
                  ),
                  icon: view.completed
                      ? Icons.done
                      : Icons.mark_email_read_outlined,
                  label: view.completed ? 'Going' : 'Received',
                  foreground: foreground,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GardenPlantExchangeTile extends StatelessWidget {
  const _GardenPlantExchangeTile({
    required this.workflow,
    required this.view,
    required this.onPressed,
    required this.onReceivePressed,
  });

  final LoomWorkflowDefinition workflow;
  final LoomPersonaWorkflowView view;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xff3f7f4c);
    final foreground = _foregroundFor(accent);
    final textTheme = Theme.of(context).textTheme;
    final complete = view.completed || view.received;
    return DecoratedBox(
      key: ValueKey('workflow-${workflow.workflowId}'),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: foreground.withValues(alpha: 0.13),
                  child: Icon(Icons.local_florist_outlined, color: foreground),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Basil seedlings offer',
                        style: textTheme.titleLarge?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Offer six Sweet Genovese starter pots, choose pickup details, and control what contact info is shared.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: foreground.withValues(alpha: 0.90),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            DecoratedBox(
              decoration: BoxDecoration(
                color: foreground.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: foreground.withValues(alpha: 0.20)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _GardenFactPill(
                          icon: Icons.grass_outlined,
                          label: 'Sweet Genovese basil',
                        ),
                        _GardenFactPill(
                          icon: Icons.inventory_2_outlined,
                          label: '6 starter pots',
                        ),
                        _GardenFactPill(
                          icon: Icons.schedule_outlined,
                          label: 'Pickup Sat 1-3 PM',
                        ),
                        _GardenFactPill(
                          icon: Icons.verified_user_outlined,
                          label: 'Contact after claim',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      complete
                          ? 'Offer posted to the plant exchange board.'
                          : 'Members will see the plant variety, pickup window, privacy note, and how to claim the offer.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: foreground.withValues(alpha: 0.90),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (view.completed)
              _WorkflowResultPanel(
                key: ValueKey('workflow-result-${workflow.workflowId}'),
                title: 'Offer posted',
                body:
                    'Basil seedlings are listed with pickup details and contact sharing limited until a member claims them.',
                icon: Icons.local_florist_outlined,
                accent: accent,
              )
            else if (view.received)
              _WorkflowResultPanel(
                key: ValueKey(
                  'workflow-received-result-${workflow.workflowId}',
                ),
                title: 'Plant offer ready',
                body:
                    'Members can confirm the variety, pickup details, and contact privacy before claiming.',
                icon: Icons.inbox_outlined,
                accent: accent,
              )
            else
              _WorkflowAction(
                contract: productionWorkflowContractFor(
                  extensionId: 'ext_garden_club',
                  workflow: workflow,
                ),
                workflow: workflow,
                view: view,
                onPressed: onPressed,
                onReceivePressed: onReceivePressed,
              ),
            if (complete)
              Align(
                alignment: Alignment.centerRight,
                child: _StateBadge(
                  key: ValueKey(
                    view.completed
                        ? 'workflow-complete-${workflow.workflowId}'
                        : 'workflow-received-${workflow.workflowId}',
                  ),
                  icon: view.completed
                      ? Icons.done
                      : Icons.mark_email_read_outlined,
                  label: view.completed ? 'Posted' : 'Received',
                  foreground: foreground,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GardenFactPill extends StatelessWidget {
  const _GardenFactPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return _SurfaceFactPill(icon: icon, label: label, foreground: Colors.white);
  }
}

Color _foregroundFor(Color background) {
  return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
      ? Colors.white
      : Colors.black;
}

Color _screenBackgroundFor(Color accent) {
  return Color.alphaBlend(accent.withValues(alpha: 0.42), Colors.black);
}

Color _actionScreenBackgroundFor(Color accent) {
  return _screenBackgroundFor(accent);
}

/// Resolves a `FilledButton`/`OutlinedButton` style from a `LoomButtonTheme`
/// token (`LoomCardTheme.primaryButton`/`secondaryButton`) — null when
/// [buttonTheme] is null so callers fall back to their existing legacy
/// button formula unchanged.
ButtonStyle? _buttonStyleFor(LoomButtonTheme? buttonTheme) {
  if (buttonTheme == null) return null;
  final borderWidth = buttonTheme.borderWidth ?? 0;
  return FilledButton.styleFrom(
    backgroundColor: buttonTheme.resolvedFill,
    foregroundColor: buttonTheme.resolvedForeground,
    iconColor: buttonTheme.resolvedForeground,
    side: borderWidth > 0
        ? BorderSide(color: buttonTheme.resolvedBorder, width: borderWidth)
        : BorderSide.none,
    shape: buttonTheme.resolvedShape,
    textStyle: TextStyle(fontWeight: buttonTheme.labelWeight),
  );
}

class _InteractionModelSummary extends StatelessWidget {
  const _InteractionModelSummary({
    required this.contract,
    required this.foreground,
    this.modernTheme,
  });

  final LoomProductionWorkflowContract contract;
  final Color foreground;

  /// Non-null only for communities that opted into the modern card theme —
  /// see `_SurfaceFactPill.accent`.
  final LoomCardTheme? modernTheme;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: modernTheme?.resolvedFill ?? foreground.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              modernTheme?.resolvedBorder ?? foreground.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contract.decisionSummary,
              style: textTheme.bodySmall?.copyWith(
                color: foreground.withValues(alpha: 0.92),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _SurfaceFactPill(
                  icon: Icons.compare_arrows_outlined,
                  label: contract.alternateActionLabel,
                  foreground: foreground,
                  accent: modernTheme?.accent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SurfaceFactPill extends StatelessWidget {
  const _SurfaceFactPill({
    required this.icon,
    required this.label,
    required this.foreground,
    this.maxLines = 1,
    this.accent,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final int maxLines;

  /// Non-null only for communities that opted into the modern card theme —
  /// switches the pill from a `foreground`-tinted gray wash (dark ink at low
  /// alpha reads as flat gray) to an accent tint, matching the reference
  /// `CommunityLaunchCard` chip look.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final tint = accent ?? foreground;
    final contentColor = accent ?? foreground;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint.withValues(alpha: accent != null ? 0.10 : 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: tint.withValues(alpha: accent != null ? 0.24 : 0.22),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: contentColor),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: contentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StateBadge extends StatelessWidget {
  const _StateBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.foreground,
    this.accent,
  });

  final IconData icon;
  final String label;
  final Color foreground;

  /// Non-null only for communities that opted into the modern card theme —
  /// see `_SurfaceFactPill.accent`.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final tint = accent ?? foreground;
    final contentColor = accent ?? foreground;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint.withValues(alpha: accent != null ? 0.12 : 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: tint.withValues(alpha: accent != null ? 0.28 : 0.24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: contentColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: contentColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _displayTitleFor(LoomWorkflowDefinition workflow) {
  switch (workflow.workflowId) {
    case 'hoa-committee-decision':
      return 'Committee decision';
    case 'hoa-export-evidence':
      return 'HOA export';
    case 'ad-off-receipt-evidence':
      return 'Receipt history';
    case 'export-checksum-evidence':
      return 'Checksum record';
    case 'platform-messages-entry':
      return 'Messages';
    case 'platform-connections-entry':
      return 'Connections';
    case 'platform-in-stream-ad':
      return 'Sponsored message';
    case 'platform-top-banner-no-fill':
      return 'Top banner slot';
    case 'platform-sensitive-no-fill':
      return 'Sensitive page ad status';
    case 'chess-route-home':
      return 'Chess Club home';
  }

  var title = workflow.title
      .replaceAll(RegExp(r'\bworkflow\b', caseSensitive: false), '')
      .replaceAll(RegExp(r'\bevidence\b', caseSensitive: false), 'record')
      .replaceAll(RegExp(r'\bsurface\b', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (title.isEmpty) {
    title = 'Community item';
  }
  return title.substring(0, 1).toUpperCase() + title.substring(1);
}

String _domainSummaryFor(
  String category,
  LoomWorkflowDefinition workflow,
  LoomPersonaWorkflowView view,
) {
  if (view.waitingForPrerequisite) {
    return _waitingSummaryFor(category);
  }
  if (view.state == LoomPersonaWorkflowState.disabled) {
    return 'Another community role manages this item.';
  }
  if (view.state == LoomPersonaWorkflowState.readOnly) {
    return 'You can read the current details without changing them.';
  }
  if (view.state == LoomPersonaWorkflowState.receiver) {
    switch (category) {
      case 'Event':
        return 'An event update is ready with your attendance choice.';
      case 'Payment':
        return 'A receipt or giving preference is ready to open.';
      case 'Publishing':
        return 'A community update is ready in your inbox.';
      case 'Approval':
        return 'A decision update is ready with next steps.';
      case 'Portability':
        return 'A data package update is ready to inspect.';
      case 'Platform':
        return 'A member communication or preference update is ready.';
      case 'Form':
        return 'A submitted member form is ready for action and follow-up.';
    }
    return 'A community update is ready to open.';
  }

  final id = workflow.workflowId;
  if (id.contains('announcement')) {
    return 'Draft message includes audience, timing, and delivery details.';
  }
  if (id.contains('notification')) {
    return 'Notification includes sender, audience, timestamp, message body, and receiver inbox state.';
  }
  if (id.contains('rsvp') || id.contains('event')) {
    return 'Event details include date, location, capacity, RSVP action, and attendance result.';
  }
  if (id.contains('practice') || id.contains('schedule')) {
    return 'Practice details include date, location, capacity, RSVP action, and confirmed result.';
  }
  if (id.contains('donation')) {
    return 'Record a 50.00 USD donation with receipt and privacy choices.';
  }
  if (id.contains('dues') || id.contains('payment')) {
    return 'Payment details include amount, payer, and receipt destination.';
  }
  if (id.contains('volunteer') || id.contains('signup')) {
    return 'Volunteer details include shift, availability, and protected contact.';
  }
  if (id.contains('care')) {
    return 'Care request keeps private details protected for the care team.';
  }
  if (id.contains('request') || id.contains('approval')) {
    return 'Submitted details are ready for a decision and member follow-up.';
  }
  if (id.contains('minor-redaction') || id.contains('redaction')) {
    return 'Protected youth roster profile includes minor-data redaction, guardian visibility, and coach-only details.';
  }
  if (id.contains('export') ||
      id.contains('import') ||
      id.contains('transfer') ||
      id.contains('checksum')) {
    return 'Data package includes scope, protected fields, and handoff status.';
  }
  if (id.contains('document')) {
    return 'Community Rules document file is a PDF updated for members with access state.';
  }
  if (id.contains('no-fill')) {
    return 'Ad slot disclosure shows a no-fill result with no sponsored message overlapping content.';
  }
  if (id.contains('message') || id.contains('connection')) {
    return 'Member communication stays scoped to the community relationship.';
  }
  if (id.contains('ad')) {
    return 'Ad preference and sponsored-message behavior are ready to open.';
  }
  return 'Member form captures labeled details, privacy choices, and reviewer handoff.';
}

String _waitingSummaryFor(String category) {
  switch (category) {
    case 'Event':
      return 'Waiting for the organizer to publish the event update.';
    case 'Payment':
      return 'Waiting for the member payment or preference to be saved.';
    case 'Publishing':
      return 'Waiting for the announcement to be sent.';
    case 'Approval':
      return 'Waiting for the request to be submitted first.';
    case 'Portability':
      return 'Waiting for the export package to be prepared.';
    case 'Platform':
      return 'Waiting for the related member action.';
    case 'Form':
      return 'Waiting for the member form to be submitted.';
  }
  return 'Waiting for the first community action.';
}

List<String> _domainMetadataFor(
  String category,
  LoomWorkflowDefinition workflow,
) {
  final id = workflow.workflowId;
  if (id.contains('announcement')) {
    return const ['Members', 'Today', 'From admin', 'Inbox + push'];
  }
  if (id.contains('notification')) {
    return const ['From admin', 'Members', 'Today', 'Inbox + push'];
  }
  if (id.contains('rsvp') ||
      id.contains('event') ||
      id.contains('practice') ||
      id.contains('schedule')) {
    return const [
      'This week',
      'Community venue',
      'Capacity tracked',
      'RSVP available',
    ];
  }
  if (id.contains('donation')) {
    return const ['50.00 USD', 'Receipt saved', 'Private option'];
  }
  if (id.contains('volunteer') || id.contains('signup')) {
    return const ['Open shift', 'Contact protected', 'Coordinator notified'];
  }
  if (id.contains('care')) {
    return const ['Private details', 'Care team', 'Consent checked'];
  }
  if (id.contains('minor-redaction') || id.contains('redaction')) {
    return const ['Minor profile', 'Guardian visibility', 'Coach-only details'];
  }
  if (id.contains('document')) {
    return const ['Members access', 'PDF updated', 'File metadata'];
  }
  if (id.contains('no-fill')) {
    return const ['No-fill state', 'Ad disclosure', 'No sponsored'];
  }
  if (id.contains('ad')) {
    return const ['No ad shown', 'Preference saved', 'Receipt ready'];
  }

  switch (category) {
    case 'Event':
      return const ['This week', 'Community venue', 'Capacity tracked'];
    case 'Payment':
      return const ['Amount ready', 'Receipt saved', 'Member-owned'];
    case 'Publishing':
      return const ['Members', 'Today', 'From admin', 'Inbox + push'];
    case 'Approval':
      return const ['Needs decision', 'Private notes', 'Member notified'];
    case 'Portability':
      return const ['Redacted copy', 'Checksum ready', 'Exportable'];
    case 'Platform':
      return const ['Private by default', 'Membership scoped', 'Ready'];
    case 'Form':
      return const ['Labeled fields', 'Privacy checked', 'Handoff ready'];
  }
  return const ['Labeled fields', 'Privacy checked', 'Handoff ready'];
}

IconData _metadataIconFor(String detail) {
  final lower = detail.toLowerCase();
  if (lower.contains('receipt') || lower.contains('usd')) {
    return Icons.receipt_long_outlined;
  }
  if (lower.contains('private') ||
      lower.contains('protected') ||
      lower.contains('consent')) {
    return Icons.verified_user_outlined;
  }
  if (lower.contains('week') ||
      lower.contains('today') ||
      lower.contains('venue') ||
      lower.contains('shift')) {
    return Icons.event_outlined;
  }
  if (lower.contains('inbox') ||
      lower.contains('notified') ||
      lower.contains('members')) {
    return Icons.notifications_outlined;
  }
  if (lower.contains('export') ||
      lower.contains('checksum') ||
      lower.contains('copy')) {
    return Icons.folder_open_outlined;
  }
  return Icons.check_circle_outline;
}

String _receiverBodyFor(String category) {
  switch (category) {
    case 'Event':
      return 'Your attendance choice and event details are saved.';
    case 'Payment':
      return 'The receipt or preference is available in your records.';
    case 'Publishing':
      return 'The update is now available in the member inbox.';
    case 'Approval':
      return 'The decision is available with the next step for the member.';
    case 'Portability':
      return 'The package status is available with redaction details.';
    case 'Platform':
      return 'The member communication state is up to date.';
  }
  return 'The community update is saved for this member.';
}

String _reviewDetailFor(String category) {
  switch (category) {
    case 'Event':
      return 'Date, location, capacity, and attendee details are ready.';
    case 'Payment':
      return 'Amount, payer, privacy choice, and receipt details are ready.';
    case 'Publishing':
      return 'Message, audience, preview, and send timing are ready.';
    case 'Approval':
      return 'Request details, decision, and member follow-up are ready.';
    case 'Portability':
      return 'Data scope, protected fields, and handoff details are ready.';
    case 'Platform':
      return 'Member communication and preference details are ready.';
  }
  return 'Required details are ready.';
}

String _reviewCheckFor(String category) {
  switch (category) {
    case 'Payment':
      return 'Receipt and privacy settings will be saved with the payment.';
    case 'Publishing':
      return 'Audience and delivery settings will be checked before sending.';
    case 'Portability':
      return 'Protected fields and checksum details will be checked.';
    case 'Platform':
      return 'Membership and privacy settings will be respected.';
  }
  return 'Required details will be checked before submission.';
}

String _reviewResultFor(String category) {
  switch (category) {
    case 'Event':
      return 'Attendance status will be updated.';
    case 'Payment':
      return 'A receipt will be saved.';
    case 'Publishing':
      return 'Members will receive the update.';
    case 'Approval':
      return 'The member will receive the decision.';
    case 'Portability':
      return 'The data package status will be updated.';
    case 'Platform':
      return 'The member setting will be updated.';
  }
  return 'The community record will be saved.';
}

String _reviewTrustFor(String category) {
  switch (category) {
    case 'Payment':
      return 'Payment records stay tied to the member account and receipt history.';
    case 'Publishing':
      return 'Only the selected audience receives this update.';
    case 'Portability':
      return 'Protected data stays redacted before sharing.';
    case 'Platform':
      return 'Private member relationships stay scoped to this community.';
  }
  return 'Private member details stay protected.';
}
