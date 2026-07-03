part of '../loom_communities_app_shell.dart';

class _SurfaceActionOrResult extends StatelessWidget {
  const _SurfaceActionOrResult({
    required this.spec,
    required this.contract,
    required this.workflow,
    required this.view,
    required this.onPressed,
    required this.onReceivePressed,
  });

  final _RichWorkflowSpec spec;
  final LoomProductionWorkflowContract contract;
  final LoomWorkflowDefinition workflow;
  final LoomPersonaWorkflowView view;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(spec.accent);
    if (view.completed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _WorkflowResultPanel(
            key: ValueKey('workflow-result-${workflow.workflowId}'),
            title: spec.completeTitle,
            body: spec.completeBody,
            icon: spec.icon,
            accent: spec.accent,
          ),
          const SizedBox(height: 10),
          _LifecycleFollowUpPanel(spec: spec, received: false),
          const SizedBox(height: 10),
          _StateBadge(
            key: ValueKey('workflow-complete-${workflow.workflowId}'),
            icon: Icons.done,
            label: spec.completeLabel,
            foreground: foreground,
          ),
        ],
      );
    }
    if (view.received) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _WorkflowResultPanel(
            key: ValueKey('workflow-received-result-${workflow.workflowId}'),
            title: spec.receivedTitle,
            body: spec.receivedBody,
            icon: Icons.inbox_outlined,
            accent: spec.accent,
          ),
          const SizedBox(height: 10),
          _LifecycleFollowUpPanel(spec: spec, received: true),
          const SizedBox(height: 10),
          _StateBadge(
            key: ValueKey('workflow-received-${workflow.workflowId}'),
            icon: Icons.mark_email_read_outlined,
            label: 'Received',
            foreground: foreground,
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProductSurfaceStatusPanel(spec: spec),
        const SizedBox(height: 12),
        _WorkflowAction(
          contract: contract,
          workflow: workflow,
          view: view,
          onPressed: onPressed,
          onReceivePressed: onReceivePressed,
        ),
        Offstage(
          child: Text(
            view.personaRationale,
            key: ValueKey('workflow-persona-state-${workflow.workflowId}'),
          ),
        ),
      ],
    );
  }
}

class _LifecycleFollowUpPanel extends StatelessWidget {
  const _LifecycleFollowUpPanel({required this.spec, required this.received});

  final _RichWorkflowSpec spec;
  final bool received;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(spec.accent);
    final textTheme = Theme.of(context).textTheme;
    final labels = _followUpActionLabelsFor(spec, received: received);
    final rows = spec.stateRows.take(2).toList();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: foreground.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              received ? 'Receiver next steps' : _followUpTitleFor(spec.layout),
              style: textTheme.titleMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              received
                  ? spec.receivedBody
                  : 'The saved result keeps status, history, and change actions visible for this community task.',
              style: textTheme.bodyMedium?.copyWith(
                color: foreground.withValues(alpha: 0.88),
              ),
            ),
            if (rows.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (final row in rows)
                _ProductPreviewLine(
                  icon: row.icon,
                  title: row.title,
                  body: row.body,
                ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final label in labels)
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: foreground,
                      side: BorderSide(
                        color: foreground.withValues(alpha: 0.35),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(label),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

List<String> _followUpActionLabelsFor(
  _RichWorkflowSpec spec, {
  required bool received,
}) {
  if (received) {
    return const ['Open inbox', 'Reply', 'Archive'];
  }
  return switch (spec.layout) {
    _RichWorkflowLayout.eventDetail => const [
      'Change RSVP',
      'Add to calendar',
      'Invite member',
    ],
    _RichWorkflowLayout.formSubmission => const [
      'Edit request',
      'Withdraw',
      'View status',
    ],
    _RichWorkflowLayout.paymentReceipt => const [
      'Open receipt',
      'Retry payment',
      'Request refund',
    ],
    _RichWorkflowLayout.rosterProfile => const [
      'Edit visibility',
      'Message team',
      'Export roster',
    ],
    _RichWorkflowLayout.requestReview => const [
      'Request changes',
      'Reopen',
      'View history',
    ],
    _RichWorkflowLayout.searchAnswer => const [
      'Ask follow-up',
      'Open sources',
      'Share answer',
    ],
    _RichWorkflowLayout.exportWizard => const [
      'Download file',
      'Verify checksum',
      'Rollback',
    ],
    _RichWorkflowLayout.messageThread => const [
      'Reply',
      'Mute thread',
      'Archive',
    ],
    _RichWorkflowLayout.noticeDetail => const [
      'Edit notice',
      'View delivery',
      'Send follow-up',
    ],
    _RichWorkflowLayout.clubScoreboard => const [
      'Edit result',
      'Dispute',
      'Open standings',
    ],
    _RichWorkflowLayout.mediaReview => const [
      'Edit submission',
      'Request feedback',
      'Withdraw',
    ],
    _RichWorkflowLayout.adEntitlement => const [
      'Manage plan',
      'Open receipt',
      'Restore',
    ],
    _ => [spec.alternateActionLabel, 'View history', 'Open details'],
  };
}

class _ProductSurfacePreview extends StatelessWidget {
  const _ProductSurfacePreview({required this.spec});

  final _RichWorkflowSpec spec;

  @override
  Widget build(BuildContext context) {
    return switch (spec.layout) {
      _RichWorkflowLayout.eventDetail => _EventDetailPreview(spec: spec),
      _RichWorkflowLayout.formSubmission => _FormSubmissionPreview(spec: spec),
      _RichWorkflowLayout.paymentReceipt => _PaymentReceiptPreview(spec: spec),
      _RichWorkflowLayout.rosterProfile => _RosterProfilePreview(spec: spec),
      _RichWorkflowLayout.requestReview => _RequestReviewPreview(spec: spec),
      _RichWorkflowLayout.searchAnswer => _SearchAnswerPreview(spec: spec),
      _RichWorkflowLayout.exportWizard => _ExportWizardPreview(spec: spec),
      _RichWorkflowLayout.messageThread => _MessageThreadPreview(spec: spec),
      _RichWorkflowLayout.noticeDetail => _NoticeDetailPreview(spec: spec),
      _RichWorkflowLayout.clubScoreboard => _ClubScoreboardPreview(spec: spec),
      _RichWorkflowLayout.mediaReview => _MediaReviewPreview(spec: spec),
      _RichWorkflowLayout.adEntitlement => _AdEntitlementPreview(spec: spec),
      _ => _ProductDetailPreview(spec: spec),
    };
  }
}

class _ProductSurfaceStatusPanel extends StatelessWidget {
  const _ProductSurfaceStatusPanel({required this.spec});

  final _RichWorkflowSpec spec;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(spec.accent);
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
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
              _surfaceStatusTitleFor(spec.layout),
              style: textTheme.titleMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              spec.actionPanelBody,
              style: textTheme.bodyMedium?.copyWith(
                color: foreground.withValues(alpha: 0.90),
              ),
            ),
            const SizedBox(height: 10),
            _SurfaceFactPill(
              icon: Icons.compare_arrows_outlined,
              label: spec.alternateActionLabel,
              foreground: foreground,
            ),
          ],
        ),
      ),
    );
  }
}

String _surfaceStatusTitleFor(_RichWorkflowLayout layout) {
  return switch (layout) {
    _RichWorkflowLayout.eventDetail => 'Response choices',
    _RichWorkflowLayout.formSubmission => 'Submission handoff',
    _RichWorkflowLayout.paymentReceipt => 'Receipt and next steps',
    _RichWorkflowLayout.rosterProfile => 'Roster visibility',
    _RichWorkflowLayout.requestReview => 'Request queue',
    _RichWorkflowLayout.searchAnswer => 'Reading guide',
    _RichWorkflowLayout.exportWizard => 'Package progress',
    _RichWorkflowLayout.messageThread => 'Conversation actions',
    _RichWorkflowLayout.noticeDetail => 'Delivery details',
    _RichWorkflowLayout.clubScoreboard => 'Club board',
    _RichWorkflowLayout.mediaReview => 'Critique details',
    _RichWorkflowLayout.adEntitlement => 'Ad-free controls',
    _ => 'Next step',
  };
}

class _EventDetailPreview extends StatelessWidget {
  const _EventDetailPreview({required this.spec});

  final _RichWorkflowSpec spec;

  @override
  Widget build(BuildContext context) {
    final rows = spec.detailRows.isEmpty ? spec.stateRows : spec.detailRows;
    return _ProductPreviewCard(
      spec: spec,
      title: 'Event details',
      children: [
        for (final row in rows.take(4))
          _ProductPreviewLine(icon: row.icon, title: row.title, body: row.body),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final fact in spec.facts.take(3))
              _SurfaceFactPill(
                icon: fact.icon,
                label: fact.label,
                foreground: _foregroundFor(spec.accent),
              ),
          ],
        ),
      ],
    );
  }
}

class _FormSubmissionPreview extends StatelessWidget {
  const _FormSubmissionPreview({required this.spec});

  final _RichWorkflowSpec spec;

  @override
  Widget build(BuildContext context) {
    return _ProductPreviewCard(
      spec: spec,
      title: 'Submitted details',
      children: [
        for (final row in spec.detailRows.take(3))
          _ProductPreviewLine(icon: row.icon, title: row.title, body: row.body),
        for (final row in spec.stateRows.take(2))
          _ProductPreviewLine(icon: row.icon, title: row.title, body: row.body),
      ],
    );
  }
}

class _PaymentReceiptPreview extends StatelessWidget {
  const _PaymentReceiptPreview({required this.spec});

  final _RichWorkflowSpec spec;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(spec.accent);
    return _ProductPreviewCard(
      spec: spec,
      title: 'Payment summary',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final fact in spec.facts.take(4))
              _SurfaceFactPill(
                icon: fact.icon,
                label: fact.label,
                foreground: foreground,
              ),
          ],
        ),
        for (final row in [
          ...spec.detailRows.take(2),
          ...spec.stateRows.take(2),
        ])
          _ProductPreviewLine(icon: row.icon, title: row.title, body: row.body),
      ],
    );
  }
}

class _RosterProfilePreview extends StatelessWidget {
  const _RosterProfilePreview({required this.spec});

  final _RichWorkflowSpec spec;

  @override
  Widget build(BuildContext context) {
    return _ProductPreviewCard(
      spec: spec,
      title: 'Roster and visibility',
      children: [
        for (final row in spec.detailRows.take(4))
          _ProductPreviewLine(icon: row.icon, title: row.title, body: row.body),
      ],
    );
  }
}

class _RequestReviewPreview extends StatelessWidget {
  const _RequestReviewPreview({required this.spec});

  final _RichWorkflowSpec spec;

  @override
  Widget build(BuildContext context) {
    final rows = [...spec.detailRows.take(3), ...spec.stateRows.take(2)];
    return _ProductPreviewCard(
      spec: spec,
      title: 'Decision queue',
      children: [
        for (var index = 0; index < rows.length; index++)
          _WizardStepLine(
            index: index + 1,
            icon: rows[index].icon,
            title: rows[index].title,
            body: rows[index].body,
          ),
      ],
    );
  }
}

class _SearchAnswerPreview extends StatelessWidget {
  const _SearchAnswerPreview({required this.spec});

  final _RichWorkflowSpec spec;

  @override
  Widget build(BuildContext context) {
    return _ProductPreviewCard(
      spec: spec,
      title: 'Answer with sources',
      children: [
        _ProductPreviewLine(
          icon: Icons.search_outlined,
          title: 'Query',
          body: spec.subtitle,
        ),
        for (final row in spec.detailRows.take(3))
          _ProductPreviewLine(icon: row.icon, title: row.title, body: row.body),
      ],
    );
  }
}

class _ExportWizardPreview extends StatelessWidget {
  const _ExportWizardPreview({required this.spec});

  final _RichWorkflowSpec spec;

  @override
  Widget build(BuildContext context) {
    final rows = [...spec.detailRows.take(3), ...spec.stateRows.take(2)];
    return _ProductPreviewCard(
      spec: spec,
      title: 'Export steps',
      children: [
        for (var index = 0; index < rows.length; index++)
          _WizardStepLine(
            index: index + 1,
            icon: rows[index].icon,
            title: rows[index].title,
            body: rows[index].body,
          ),
      ],
    );
  }
}

class _MessageThreadPreview extends StatelessWidget {
  const _MessageThreadPreview({required this.spec});

  final _RichWorkflowSpec spec;

  @override
  Widget build(BuildContext context) {
    return _ProductPreviewCard(
      spec: spec,
      title: 'Conversation',
      children: [
        for (final row in spec.detailRows.take(3))
          _ChatBubbleLine(
            icon: row.icon,
            title: row.title,
            body: row.body,
            alignRight: row.title.toLowerCase().contains('body'),
          ),
        for (final row in spec.stateRows.take(1))
          _ProductPreviewLine(icon: row.icon, title: row.title, body: row.body),
      ],
    );
  }
}

class _NoticeDetailPreview extends StatelessWidget {
  const _NoticeDetailPreview({required this.spec});

  final _RichWorkflowSpec spec;

  @override
  Widget build(BuildContext context) {
    return _ProductPreviewCard(
      spec: spec,
      title: 'Notice preview',
      children: [
        for (final row in spec.detailRows.take(4))
          _ProductPreviewLine(icon: row.icon, title: row.title, body: row.body),
        for (final row in spec.stateRows.take(1))
          _ProductPreviewLine(icon: row.icon, title: row.title, body: row.body),
      ],
    );
  }
}

class _ClubScoreboardPreview extends StatelessWidget {
  const _ClubScoreboardPreview({required this.spec});

  final _RichWorkflowSpec spec;

  @override
  Widget build(BuildContext context) {
    return _ProductPreviewCard(
      spec: spec,
      title: 'Club board',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final fact in spec.facts)
              _SurfaceFactPill(
                icon: fact.icon,
                label: fact.label,
                foreground: _foregroundFor(spec.accent),
              ),
          ],
        ),
        for (final row in spec.detailRows.take(3))
          _ProductPreviewLine(icon: row.icon, title: row.title, body: row.body),
      ],
    );
  }
}

class _MediaReviewPreview extends StatelessWidget {
  const _MediaReviewPreview({required this.spec});

  final _RichWorkflowSpec spec;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(spec.accent);
    return _ProductPreviewCard(
      spec: spec,
      title: 'Photo critique',
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: foreground.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: foreground.withValues(alpha: 0.22)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: foreground.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Icon(
                      Icons.photo_camera_back_outlined,
                      color: foreground,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Golden hour bridge study',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Member photo, critique prompt, consent, comment thread, edit/withdraw, and reviewer result are visible.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: foreground.withValues(alpha: 0.86),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        for (final row in spec.detailRows.take(3))
          _ProductPreviewLine(icon: row.icon, title: row.title, body: row.body),
        for (final row in spec.stateRows.take(2))
          _ProductPreviewLine(icon: row.icon, title: row.title, body: row.body),
      ],
    );
  }
}

class _AdEntitlementPreview extends StatelessWidget {
  const _AdEntitlementPreview({required this.spec});

  final _RichWorkflowSpec spec;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(spec.accent);
    final title = spec.title.toLowerCase();
    final account =
        title.contains('ad-off') ||
        title.contains('ad-free') ||
        title.contains('settlement') ||
        title.contains('entitlement') ||
        title.contains('receipt');
    final sponsored =
        !account &&
        !title.contains('no-fill') &&
        !title.contains('guard') &&
        !title.contains('suppression');
    return _ProductPreviewCard(
      spec: spec,
      title: sponsored
          ? 'In-stream placement'
          : account
          ? 'Ad-free account'
          : 'Ad slot state',
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: foreground.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: foreground.withValues(alpha: 0.24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      sponsored
                          ? Icons.campaign_outlined
                          : Icons.web_asset_off_outlined,
                      color: foreground,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sponsored
                            ? 'Sponsored by Neighborhood Newsletter'
                            : account
                            ? 'Ad-free status active'
                            : 'No sponsored message right now',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  sponsored
                      ? 'Disclosure, sponsor creative, impression state, dismiss, report, and manage-ad controls sit inside the stream.'
                      : account
                      ? 'Entitlement, receipt, renewal, restore action, and affected ad slots stay together without payment-screen context.'
                      : 'Reserved slot, no-fill reason, privacy-safe suppression, and manage-ad controls preserve layout without covering content.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: foreground.withValues(alpha: 0.86),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        for (final row in spec.detailRows.take(2))
          _ProductPreviewLine(icon: row.icon, title: row.title, body: row.body),
        for (final row in spec.stateRows.take(3))
          _ProductPreviewLine(icon: row.icon, title: row.title, body: row.body),
      ],
    );
  }
}

class _ProductDetailPreview extends StatelessWidget {
  const _ProductDetailPreview({required this.spec});

  final _RichWorkflowSpec spec;

  @override
  Widget build(BuildContext context) {
    return _ProductPreviewCard(
      spec: spec,
      title: spec.detailTitle,
      children: [
        for (final row in spec.detailRows.take(3))
          _ProductPreviewLine(icon: row.icon, title: row.title, body: row.body),
      ],
    );
  }
}

class _ProductPreviewCard extends StatelessWidget {
  const _ProductPreviewCard({
    required this.spec,
    required this.title,
    required this.children,
  });

  final _RichWorkflowSpec spec;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(spec.accent);
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: foreground.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: foreground),
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
              const SizedBox(height: 10),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductPreviewLine extends StatelessWidget {
  const _ProductPreviewLine({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final foreground = DefaultTextStyle.of(context).style.color ?? Colors.white;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: foreground.withValues(alpha: 0.92)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: textTheme.bodySmall?.copyWith(
                    color: foreground.withValues(alpha: 0.86),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WizardStepLine extends StatelessWidget {
  const _WizardStepLine({
    required this.index,
    required this.icon,
    required this.title,
    required this.body,
  });

  final int index;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final foreground = DefaultTextStyle.of(context).style.color ?? Colors.white;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: foreground.withValues(alpha: 0.18),
            child: Text(
              '$index',
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ProductPreviewLine(icon: icon, title: title, body: body),
          ),
        ],
      ),
    );
  }
}

class _ChatBubbleLine extends StatelessWidget {
  const _ChatBubbleLine({
    required this.icon,
    required this.title,
    required this.body,
    required this.alignRight,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final foreground = DefaultTextStyle.of(context).style.color ?? Colors.white;
    final textTheme = Theme.of(context).textTheme;
    final bubble = DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: alignRight ? 0.20 : 0.11),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: foreground.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleSmall?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: textTheme.bodySmall?.copyWith(
                      color: foreground.withValues(alpha: 0.86),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: bubble,
        ),
      ),
    );
  }
}

