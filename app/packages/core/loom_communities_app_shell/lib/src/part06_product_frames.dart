part of '../loom_communities_app_shell.dart';

class _ProductSurfaceFrame extends StatelessWidget {
  const _ProductSurfaceFrame({
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
  final LoomRoleWorkflowView view;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;

  @override
  Widget build(BuildContext context) {
    return switch (spec.layout) {
      _RichWorkflowLayout.eventDetail => _EventProductFrame(
        spec: spec,
        contract: contract,
        workflow: workflow,
        view: view,
        onPressed: onPressed,
        onReceivePressed: onReceivePressed,
      ),
      _RichWorkflowLayout.exportWizard => _WizardProductFrame(
        spec: spec,
        contract: contract,
        workflow: workflow,
        view: view,
        onPressed: onPressed,
        onReceivePressed: onReceivePressed,
      ),
      _RichWorkflowLayout.paymentReceipt => _ReceiptProductFrame(
        spec: spec,
        contract: contract,
        workflow: workflow,
        view: view,
        onPressed: onPressed,
        onReceivePressed: onReceivePressed,
      ),
      _RichWorkflowLayout.adEntitlement => _AdFreeProductFrame(
        spec: spec,
        contract: contract,
        workflow: workflow,
        view: view,
        onPressed: onPressed,
        onReceivePressed: onReceivePressed,
      ),
      _RichWorkflowLayout.messageThread ||
      _RichWorkflowLayout.noticeDetail ||
      _RichWorkflowLayout.searchAnswer => _FeedProductFrame(
        spec: spec,
        contract: contract,
        workflow: workflow,
        view: view,
        onPressed: onPressed,
        onReceivePressed: onReceivePressed,
      ),
      _RichWorkflowLayout.rosterProfile => _RosterProductFrame(
        spec: spec,
        contract: contract,
        workflow: workflow,
        view: view,
        onPressed: onPressed,
        onReceivePressed: onReceivePressed,
      ),
      _RichWorkflowLayout.clubScoreboard => _ScoreboardProductFrame(
        spec: spec,
        contract: contract,
        workflow: workflow,
        view: view,
        onPressed: onPressed,
        onReceivePressed: onReceivePressed,
      ),
      _RichWorkflowLayout.formSubmission ||
      _RichWorkflowLayout.requestReview ||
      _RichWorkflowLayout.mediaReview => _FormProductFrame(
        spec: spec,
        contract: contract,
        workflow: workflow,
        view: view,
        onPressed: onPressed,
        onReceivePressed: onReceivePressed,
      ),
      _ => _DefaultProductFrame(
        spec: spec,
        contract: contract,
        workflow: workflow,
        view: view,
        onPressed: onPressed,
        onReceivePressed: onReceivePressed,
      ),
    };
  }
}

class _EventProductFrame extends StatelessWidget {
  const _EventProductFrame({
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
  final LoomRoleWorkflowView view;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(spec.accent);
    final textTheme = Theme.of(context).textTheme;
    final complete = view.completed || view.received;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: spec.accent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: foreground.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: foreground.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(spec.icon, color: foreground, size: 32),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spec.title,
                        style: textTheme.headlineSmall?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        complete ? spec.completeBody : spec.body,
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
            _EventDetailPreview(spec: spec),
            const SizedBox(height: 12),
            _SurfaceActionOrResult(
              spec: spec,
              contract: contract,
              workflow: workflow,
              view: view,
              onPressed: onPressed,
              onReceivePressed: onReceivePressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _FormProductFrame extends StatelessWidget {
  const _FormProductFrame({
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
  final LoomRoleWorkflowView view;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(spec.accent);
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: foreground.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(spec.icon, color: foreground, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    spec.title,
                    style: textTheme.headlineSmall?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              spec.subtitle,
              style: textTheme.bodyLarge?.copyWith(
                color: foreground.withValues(alpha: 0.90),
              ),
            ),
            const SizedBox(height: 14),
            _FormSubmissionPreview(spec: spec),
            const SizedBox(height: 12),
            _SurfaceActionOrResult(
              spec: spec,
              contract: contract,
              workflow: workflow,
              view: view,
              onPressed: onPressed,
              onReceivePressed: onReceivePressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptProductFrame extends StatelessWidget {
  const _ReceiptProductFrame({
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
  final LoomRoleWorkflowView view;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(spec.accent);
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: spec.accent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              spec.title,
              style: textTheme.headlineMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              spec.body,
              style: textTheme.bodyMedium?.copyWith(
                color: foreground.withValues(alpha: 0.90),
              ),
            ),
            const SizedBox(height: 14),
            _PaymentReceiptPreview(spec: spec),
            const SizedBox(height: 12),
            _SurfaceActionOrResult(
              spec: spec,
              contract: contract,
              workflow: workflow,
              view: view,
              onPressed: onPressed,
              onReceivePressed: onReceivePressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _AdFreeProductFrame extends StatelessWidget {
  const _AdFreeProductFrame({
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
  final LoomRoleWorkflowView view;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;

  @override
  Widget build(BuildContext context) {
    final foreground = spec.accent;
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: foreground.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: spec.accent.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Icon(spec.icon, color: spec.accent, size: 30),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spec.title,
                        style: textTheme.headlineSmall?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        spec.body,
                        style: textTheme.bodyMedium?.copyWith(
                          color: foreground.withValues(alpha: 0.84),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _AdEntitlementPreview(spec: spec),
            const SizedBox(height: 12),
            _SurfaceActionOrResult(
              spec: spec,
              contract: contract,
              workflow: workflow,
              view: view,
              onPressed: onPressed,
              onReceivePressed: onReceivePressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _WizardProductFrame extends StatelessWidget {
  const _WizardProductFrame({
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
  final LoomRoleWorkflowView view;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(spec.accent);
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          spec.title,
          style: textTheme.headlineSmall?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          spec.subtitle,
          style: textTheme.bodyLarge?.copyWith(
            color: foreground.withValues(alpha: 0.90),
          ),
        ),
        const SizedBox(height: 12),
        _ExportWizardPreview(spec: spec),
        const SizedBox(height: 12),
        _SurfaceActionOrResult(
          spec: spec,
          contract: contract,
          workflow: workflow,
          view: view,
          onPressed: onPressed,
          onReceivePressed: onReceivePressed,
        ),
      ],
    );
  }
}

class _FeedProductFrame extends StatelessWidget {
  const _FeedProductFrame({
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
  final LoomRoleWorkflowView view;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(spec.accent);
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: foreground.withValues(alpha: 0.20)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductSurfacePreview(spec: spec),
            const SizedBox(height: 12),
            Text(
              spec.title,
              style: textTheme.titleLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              spec.body,
              style: textTheme.bodyMedium?.copyWith(
                color: foreground.withValues(alpha: 0.88),
              ),
            ),
            const SizedBox(height: 12),
            _SurfaceActionOrResult(
              spec: spec,
              contract: contract,
              workflow: workflow,
              view: view,
              onPressed: onPressed,
              onReceivePressed: onReceivePressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _RosterProductFrame extends StatelessWidget {
  const _RosterProductFrame({
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
  final LoomRoleWorkflowView view;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(spec.accent);
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: foreground.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              spec.title,
              style: textTheme.headlineSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              spec.body,
              style: textTheme.bodyMedium?.copyWith(
                color: foreground.withValues(alpha: 0.88),
              ),
            ),
            const SizedBox(height: 12),
            _RosterProfilePreview(spec: spec),
            const SizedBox(height: 12),
            _SurfaceActionOrResult(
              spec: spec,
              contract: contract,
              workflow: workflow,
              view: view,
              onPressed: onPressed,
              onReceivePressed: onReceivePressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreboardProductFrame extends StatelessWidget {
  const _ScoreboardProductFrame({
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
  final LoomRoleWorkflowView view;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(spec.accent);
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: spec.accent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              spec.title,
              style: textTheme.headlineMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            _ClubScoreboardPreview(spec: spec),
            const SizedBox(height: 12),
            _SurfaceActionOrResult(
              spec: spec,
              contract: contract,
              workflow: workflow,
              view: view,
              onPressed: onPressed,
              onReceivePressed: onReceivePressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _DefaultProductFrame extends StatelessWidget {
  const _DefaultProductFrame({
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
  final LoomRoleWorkflowView view;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProductDetailPreview(spec: spec),
        const SizedBox(height: 12),
        _SurfaceActionOrResult(
          spec: spec,
          contract: contract,
          workflow: workflow,
          view: view,
          onPressed: onPressed,
          onReceivePressed: onReceivePressed,
        ),
      ],
    );
  }
}
