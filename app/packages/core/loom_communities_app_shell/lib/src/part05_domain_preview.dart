part of '../loom_communities_app_shell.dart';

class _DomainPreviewRow {
  const _DomainPreviewRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _DomainPreviewPanel extends StatelessWidget {
  const _DomainPreviewPanel({
    required this.accent,
    required this.foreground,
    required this.title,
    required this.rows,
  });

  final Color accent;
  final Color foreground;
  final String title;
  final List<_DomainPreviewRow> rows;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: foreground.withValues(alpha: 0.22)),
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
            const SizedBox(height: 10),
            for (final row in rows) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(row.icon, color: foreground, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.title,
                          style: textTheme.titleSmall?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          row.body,
                          style: textTheme.bodyMedium?.copyWith(
                            color: foreground.withValues(alpha: 0.88),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (row != rows.last) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _WorkflowSurfacePresenter extends StatelessWidget {
  const _WorkflowSurfacePresenter({
    required this.extensionId,
    required this.workflow,
    required this.view,
    required this.state,
    required this.theme,
    this.modernTheme,
    required this.child,
    required this.onPressed,
    required this.onReceivePressed,
    required this.onExpand,
    required this.onCollapse,
  });

  final String extensionId;
  final LoomWorkflowDefinition workflow;
  final LoomPersonaWorkflowView view;
  final SurfacePresentationState state;
  final LoomCardTheme theme;

  /// Non-null only for communities that opted into the modern card theme —
  /// see `LoomSurfaceTheme.usesModernCardTheme`. `theme` itself is always
  /// populated (bespoke communities resolve a legacy dark/solid theme here
  /// too), so this separate flag is what lets the minimized surface's chips
  /// switch to an accent tint without misclassifying a bespoke community's
  /// own light accent as "modern".
  final LoomCardTheme? modernTheme;
  final Widget child;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;
  final VoidCallback onExpand;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final contract = productionWorkflowContractFor(
      extensionId: extensionId,
      workflow: workflow,
    );
    final foreground = theme.resolvedHeading;
    final borderColor = theme.resolvedBorder;
    final shadowColor = theme.resolvedShadow;
    final isExpanded = state == SurfacePresentationState.expanded;
    final isMedium = state == SurfacePresentationState.medium;
    final radius = isExpanded ? 18.0 : 12.0;

    if (state == SurfacePresentationState.minimized) {
      return _MinimizedWorkflowSurface(
        key: ValueKey('workflow-${workflow.workflowId}'),
        workflow: workflow,
        view: view,
        contract: contract,
        theme: theme,
        modernTheme: modernTheme,
        onExpand: onExpand,
        onPressed: onPressed,
        onReceivePressed: onReceivePressed,
      );
    }

    return Semantics(
      selected: isMedium,
      expanded: isExpanded,
      label:
          '${_displayTitleFor(workflow)} ${isExpanded ? 'expanded' : 'in focus'} surface',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: borderColor.withValues(
              alpha: borderColor.a * (isExpanded ? 1.0 : 0.53),
            ),
            width: isExpanded ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withValues(
                alpha: shadowColor.a * (isExpanded ? 1.08 : 0.67),
              ),
              blurRadius: isExpanded ? 26 : 14,
              offset: Offset(0, isExpanded ? 12 : 7),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Material(
                color: Color.alphaBlend(
                  (theme.accent ?? borderColor).withValues(alpha: 0.14),
                  theme.resolvedFill,
                ),
                child: InkWell(
                  key: ValueKey('workflow-expand-${workflow.workflowId}'),
                  onTap: isExpanded ? onCollapse : onExpand,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isExpanded
                              ? Icons.fullscreen_exit_outlined
                              : Icons.center_focus_strong_outlined,
                          color: foreground,
                          size: 19,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isExpanded
                                ? 'Expanded product surface'
                                : 'In-focus product surface',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: foreground,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        Text(
                          isExpanded ? 'Collapse' : 'Expand',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: foreground,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _MinimizedWorkflowSurface extends StatelessWidget {
  const _MinimizedWorkflowSurface({
    super.key,
    required this.workflow,
    required this.view,
    required this.contract,
    required this.theme,
    this.modernTheme,
    required this.onExpand,
    required this.onPressed,
    required this.onReceivePressed,
  });

  final LoomWorkflowDefinition workflow;
  final LoomPersonaWorkflowView view;
  final LoomProductionWorkflowContract contract;
  final LoomCardTheme theme;

  /// Non-null only for communities that opted into the modern card theme —
  /// see `_WorkflowSurfacePresenter.modernTheme`.
  final LoomCardTheme? modernTheme;
  final VoidCallback onExpand;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;

  @override
  Widget build(BuildContext context) {
    final foreground = theme.resolvedHeading;
    final textTheme = Theme.of(context).textTheme;
    final complete = view.completed || view.received;
    return Semantics(
      button: true,
      label: '${_displayTitleFor(workflow)} minimized surface',
      child: Card(
        margin: EdgeInsets.zero,
        color: theme.resolvedFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.resolvedBorder),
        ),
        child: InkWell(
          onTap: onExpand,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(contract.icon, color: foreground, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _displayTitleFor(workflow),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                              color: foreground,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            complete
                                ? view.completed
                                      ? contract.successTitle
                                      : contract.receiverSurfaceTitle
                                : _domainSummaryFor(
                                    contract.category,
                                    workflow,
                                    view,
                                  ),
                            key: complete
                                ? ValueKey(
                                    view.completed
                                        ? 'workflow-result-${workflow.workflowId}'
                                        : 'workflow-received-result-${workflow.workflowId}',
                                  )
                                : null,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              color: foreground.withValues(alpha: 0.90),
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StateBadge(
                      key: complete
                          ? ValueKey(
                              view.completed
                                  ? 'workflow-complete-${workflow.workflowId}'
                                  : 'workflow-received-${workflow.workflowId}',
                            )
                          : null,
                      icon: complete
                          ? Icons.done
                          : Icons.center_focus_strong_outlined,
                      label: complete ? contract.successChipLabel : 'Minimized',
                      foreground: foreground,
                      accent: modernTheme?.accent,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SurfaceFactPill(
                      icon: Icons.unfold_more_outlined,
                      label: 'Tap for expanded view',
                      foreground: foreground,
                      accent: modernTheme?.accent,
                    ),
                    _SurfaceFactPill(
                      icon: Icons.layers_outlined,
                      label: _surfaceLabelFor(contract.category),
                      foreground: foreground,
                      accent: modernTheme?.accent,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    OutlinedButton.icon(
                      key: ValueKey('workflow-expand-${workflow.workflowId}'),
                      onPressed: onExpand,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: modernTheme?.accent ?? foreground,
                        side: BorderSide(
                          color: modernTheme?.accent != null
                              ? modernTheme!.accent!.withValues(alpha: 0.4)
                              : foreground.withValues(alpha: 0.34),
                        ),
                      ),
                      icon: const Icon(Icons.open_in_full_outlined, size: 18),
                      label: const Text('Expand'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _WorkflowAction(
                        contract: contract,
                        workflow: workflow,
                        view: view,
                        accentOverride: theme.accent,
                        modernTheme: modernTheme,
                        onPressed: onPressed,
                        onReceivePressed: onReceivePressed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkflowTile extends StatelessWidget {
  const _WorkflowTile({
    required this.extensionId,
    required this.workflow,
    required this.view,
    required this.state,
    required this.fallbackAccent,
    this.modernTheme,
    required this.onPressed,
    required this.onReceivePressed,
    this.selectedResponseId,
  });

  final String extensionId;
  final LoomWorkflowDefinition workflow;
  final LoomPersonaWorkflowView view;
  final SurfacePresentationState state;

  /// The cascade-resolved accent (community -> tab -> workflow) to use when
  /// this workflow has no bespoke catalog entry — see
  /// `_fallbackRichWorkflowSpecFor`.
  final Color fallbackAccent;

  /// Non-null only for communities that opted into the modern card theme
  /// (declared an explicit `experience.theme`) — see `LoomSurfaceTheme.
  /// usesModernCardTheme`. Every bespoke catalog community renders with
  /// this null, reproducing today's exact rendering.
  final LoomCardTheme? modernTheme;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;

  /// The [LoomWorkflowResponseChoice.responseId] the actor chose, when the
  /// workflow had more than one response choice. Null for single-choice
  /// workflows or before a choice has been made.
  final String? selectedResponseId;

  @override
  Widget build(BuildContext context) {
    if (extensionId == 'ext_garden_club' &&
        workflow.workflowId == 'garden-event-rsvp') {
      return _GardenEventRsvpTile(
        workflow: workflow,
        view: view,
        onPressed: onPressed,
        onReceivePressed: onReceivePressed,
      );
    }
    if (extensionId == 'ext_garden_club' &&
        workflow.workflowId == 'plant-exchange-submission') {
      return _GardenPlantExchangeTile(
        workflow: workflow,
        view: view,
        onPressed: onPressed,
        onReceivePressed: onReceivePressed,
      );
    }
    final richSpec = _richWorkflowSpecFor(
      workflow.workflowId,
      workflow: workflow,
      fallbackAccent: fallbackAccent,
    );
    if (richSpec != null) {
      return _RichWorkflowTile(
        extensionId: extensionId,
        spec: richSpec,
        workflow: workflow,
        view: view,
        state: state,
        modernTheme: modernTheme,
        selectedResponseId: selectedResponseId,
        onPressed: onPressed,
        onReceivePressed: onReceivePressed,
      );
    }
    final complete = view.completed || view.received;
    final contract = productionWorkflowContractFor(
      extensionId: extensionId,
      workflow: workflow,
    );
    final metadata = _domainMetadataFor(contract.category, workflow);
    // `fallbackAccent` is already resolved through the community -> tab ->
    // workflow theme cascade. The category palette is only a legacy action
    // surface fallback; it must not override the cascade on this shared tile.
    final accent = modernTheme?.accent ?? fallbackAccent;
    final foreground = modernTheme?.resolvedHeading ?? _foregroundFor(accent);
    return DecoratedBox(
      key: ValueKey('workflow-${workflow.workflowId}'),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  complete
                      ? Icons.check_circle_outline
                      : view.state == LoomPersonaWorkflowState.receiver
                      ? Icons.notifications_none
                      : view.state == LoomPersonaWorkflowState.actor
                      ? Icons.radio_button_unchecked
                      : view.state == LoomPersonaWorkflowState.readOnly
                      ? Icons.visibility_outlined
                      : Icons.radio_button_unchecked,
                  color: foreground,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayTitleFor(workflow),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: foreground,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _domainSummaryFor(contract.category, workflow, view),
                        style: TextStyle(
                          color: foreground.withValues(alpha: 0.90),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          for (final detail in metadata)
                            _SurfaceFactPill(
                              icon: _metadataIconFor(detail),
                              label: detail,
                              foreground: foreground,
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _InteractionModelSummary(
                        contract: contract,
                        foreground: foreground,
                      ),
                      Offstage(
                        child: Text(
                          view.personaRationale,
                          key: ValueKey(
                            'workflow-persona-state-${workflow.workflowId}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (view.completed)
              _WorkflowResultPanel(
                key: ValueKey('workflow-result-${workflow.workflowId}'),
                title: contract.successTitle,
                body: _responseResultBody(
                  workflow: workflow,
                  contract: contract,
                  defaultBody:
                      '${contract.resultSummary} ${contract.receiverStateSummary}',
                  selectedResponseId: selectedResponseId,
                ),
                icon: contract.icon,
                accent: accent,
                changeResponseLabel:
                    _responseChoicesFor(workflow, contract).length > 1
                    ? 'Change response'
                    : null,
                onChangeResponse:
                    _responseChoicesFor(workflow, contract).length > 1
                    ? onPressed
                    : null,
              )
            else if (view.received)
              _WorkflowResultPanel(
                key: ValueKey(
                  'workflow-received-result-${workflow.workflowId}',
                ),
                title: contract.receiverSurfaceTitle,
                body:
                    '${_receiverBodyFor(contract.category)} ${contract.receiverStateSummary}',
                icon: Icons.inbox_outlined,
                accent: accent,
              )
            else
              _WorkflowAction(
                contract: contract,
                workflow: workflow,
                view: view,
                modernTheme: modernTheme,
                onPressed: onPressed,
                onReceivePressed: onReceivePressed,
              ),
            if (view.completed)
              Align(
                alignment: Alignment.centerRight,
                child: _StateBadge(
                  key: ValueKey('workflow-complete-${workflow.workflowId}'),
                  icon: Icons.done,
                  label: contract.successChipLabel,
                  foreground: foreground,
                ),
              ),
            if (view.received)
              Align(
                alignment: Alignment.centerRight,
                child: _StateBadge(
                  key: ValueKey('workflow-received-${workflow.workflowId}'),
                  icon: Icons.mark_email_read_outlined,
                  label: 'Received',
                  foreground: foreground,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RichWorkflowTile extends StatelessWidget {
  const _RichWorkflowTile({
    required this.extensionId,
    required this.spec,
    required this.workflow,
    required this.view,
    required this.state,
    this.modernTheme,
    required this.onPressed,
    required this.onReceivePressed,
    this.selectedResponseId,
  });

  final String extensionId;
  final _RichWorkflowSpec spec;
  final LoomWorkflowDefinition workflow;
  final LoomPersonaWorkflowView view;
  final SurfacePresentationState state;

  /// Non-null only for communities that opted into the modern card theme —
  /// see `LoomSurfaceTheme.usesModernCardTheme`. Bespoke catalog workflows
  /// always render with this null, reproducing today's solid-`spec.accent`
  /// fill exactly.
  final LoomCardTheme? modernTheme;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;
  final String? selectedResponseId;

  @override
  Widget build(BuildContext context) {
    final foreground =
        modernTheme?.resolvedHeading ?? _foregroundFor(spec.accent);
    final bodyColor =
        modernTheme?.resolvedBody ?? foreground.withValues(alpha: 0.90);
    final subtitleColor =
        modernTheme?.resolvedBody ?? foreground.withValues(alpha: 0.94);
    final tileFill = modernTheme?.resolvedFill ?? spec.accent;
    final tileBorder = modernTheme?.resolvedBorder;
    final tileShadow =
        modernTheme?.resolvedShadow ?? spec.accent.withValues(alpha: 0.22);
    final textTheme = Theme.of(context).textTheme;
    final complete = view.completed || view.received;
    final isExpanded = state == SurfacePresentationState.expanded;
    final contract = productionWorkflowContractFor(
      extensionId: extensionId,
      workflow: workflow,
    );
    // Only the explicitly-expanded state shows the deeper panels (domain
    // preview, interaction-model summary, task-details prose). The
    // scroll-driven "in focus" (medium) state stays close to the minimized
    // card's footprint so it doesn't balloon in height the moment a card
    // gains focus while scrolling — that dramatic, automatic size jump is
    // what made the transition feel like a sudden, unrelated card swap.
    final domainPreview = isExpanded
        ? _domainPreviewPanelFor(
            workflow.workflowId,
            accent: spec.accent,
            foreground: foreground,
          )
        : null;
    if (spec.layout != _RichWorkflowLayout.standard) {
      return _RichProductSurfaceTile(
        extensionId: extensionId,
        spec: spec,
        workflow: workflow,
        view: view,
        onPressed: onPressed,
        onReceivePressed: onReceivePressed,
      );
    }
    return DecoratedBox(
      key: ValueKey('workflow-${workflow.workflowId}'),
      decoration: BoxDecoration(
        color: tileFill,
        borderRadius: BorderRadius.circular(12),
        border: tileBorder != null ? Border.all(color: tileBorder) : null,
        boxShadow: [
          BoxShadow(
            color: tileShadow,
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
                  backgroundColor: modernTheme?.accent != null
                      ? modernTheme!.accent!.withValues(alpha: 0.15)
                      : foreground.withValues(alpha: 0.13),
                  child: Icon(
                    spec.icon,
                    color: modernTheme?.accent ?? foreground,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spec.title,
                        style: textTheme.titleLarge?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        spec.subtitle,
                        style: textTheme.titleMedium?.copyWith(
                          color: subtitleColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        complete ? spec.completeBody : spec.body,
                        style: textTheme.bodyMedium?.copyWith(color: bodyColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final fact in spec.facts)
                  _SurfaceFactPill(
                    icon: fact.icon,
                    label: fact.label,
                    foreground: foreground,
                    accent: modernTheme?.accent,
                  ),
              ],
            ),
            if (domainPreview != null) ...[
              const SizedBox(height: 12),
              domainPreview,
            ],
            if (isExpanded) ...[
              const SizedBox(height: 12),
              _InteractionModelSummary(
                contract: contract,
                foreground: foreground,
                modernTheme: modernTheme,
              ),
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  color:
                      modernTheme?.resolvedFill ??
                      foreground.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        modernTheme?.resolvedBorder ??
                        foreground.withValues(alpha: 0.20),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        complete ? spec.stateTitle : spec.actionPanelTitle,
                        style: textTheme.titleMedium?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        complete ? spec.completeBody : spec.actionPanelBody,
                        style: textTheme.bodyMedium?.copyWith(color: bodyColor),
                      ),
                      const SizedBox(height: 10),
                      _SurfaceFactPill(
                        icon: Icons.compare_arrows_outlined,
                        label: spec.alternateActionLabel,
                        foreground: foreground,
                        accent: modernTheme?.accent,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (view.completed)
              _WorkflowResultPanel(
                key: ValueKey('workflow-result-${workflow.workflowId}'),
                title: spec.completeTitle,
                body: _responseResultBody(
                  workflow: workflow,
                  contract: contract,
                  defaultBody: spec.completeBody,
                  selectedResponseId: selectedResponseId,
                ),
                icon: spec.icon,
                accent: spec.accent,
                modernTheme: modernTheme,
                changeResponseLabel:
                    _responseChoicesFor(workflow, contract).length > 1
                    ? 'Change response'
                    : null,
                onChangeResponse:
                    _responseChoicesFor(workflow, contract).length > 1
                    ? onPressed
                    : null,
              )
            else if (view.received)
              _WorkflowResultPanel(
                key: ValueKey(
                  'workflow-received-result-${workflow.workflowId}',
                ),
                title: spec.receivedTitle,
                body: spec.receivedBody,
                icon: Icons.inbox_outlined,
                accent: spec.accent,
                modernTheme: modernTheme,
              )
            else
              _WorkflowAction(
                contract: contract,
                workflow: workflow,
                view: view,
                accentOverride: spec.accent,
                modernTheme: modernTheme,
                onPressed: onPressed,
                onReceivePressed: onReceivePressed,
              ),
            Offstage(
              child: Text(
                view.personaRationale,
                key: ValueKey('workflow-persona-state-${workflow.workflowId}'),
              ),
            ),
            if (view.completed)
              Align(
                alignment: Alignment.centerRight,
                child: _StateBadge(
                  key: ValueKey('workflow-complete-${workflow.workflowId}'),
                  icon: Icons.done,
                  label: spec.completeLabel,
                  foreground: foreground,
                  accent: modernTheme?.accent,
                ),
              ),
            if (view.received)
              Align(
                alignment: Alignment.centerRight,
                child: _StateBadge(
                  key: ValueKey('workflow-received-${workflow.workflowId}'),
                  icon: Icons.mark_email_read_outlined,
                  label: 'Received',
                  foreground: foreground,
                  accent: modernTheme?.accent,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RichProductSurfaceTile extends StatelessWidget {
  const _RichProductSurfaceTile({
    required this.extensionId,
    required this.spec,
    required this.workflow,
    required this.view,
    required this.onPressed,
    required this.onReceivePressed,
  });

  final String extensionId;
  final _RichWorkflowSpec spec;
  final LoomWorkflowDefinition workflow;
  final LoomPersonaWorkflowView view;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;

  @override
  Widget build(BuildContext context) {
    final contract = productionWorkflowContractFor(
      extensionId: extensionId,
      workflow: workflow,
    );
    return KeyedSubtree(
      key: ValueKey('workflow-${workflow.workflowId}'),
      child: _ProductSurfaceFrame(
        spec: spec,
        contract: contract,
        workflow: workflow,
        view: view,
        onPressed: onPressed,
        onReceivePressed: onReceivePressed,
      ),
    );
  }
}
