import 'package:flutter/material.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_design_system/loom_design_system.dart';

class CreatorExportWizardScreen extends StatefulWidget {
  const CreatorExportWizardScreen({
    required this.creatorId,
    required this.onBack,
    super.key,
  });

  final String creatorId;
  final VoidCallback onBack;

  @override
  State<CreatorExportWizardScreen> createState() =>
      _CreatorExportWizardScreenState();
}

class _CreatorExportWizardScreenState extends State<CreatorExportWizardScreen> {
  late final MigrationExportApi _exportApi;
  ExportJob? _job;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _exportApi = resolveMigrationExportApi();
  }

  Future<void> _createExport() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    final created = await _exportApi.createExportJob(
      creatorId: widget.creatorId,
      idempotencyKey: 'p9-export-${widget.creatorId}',
    );
    if (!mounted) {
      return;
    }
    setState(() => _job = created);

    final processing = await _exportApi.getExportJob(created.id);
    if (!mounted) {
      return;
    }
    setState(() => _job = processing);

    final complete = await _exportApi.getExportJob(created.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _job = complete;
      _busy = false;
    });
  }

  void _openBundle() {
    final bundle = _job?.bundle;
    if (bundle == null) {
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              'Portable bundle',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: LoomSpacing.sm),
            Text(
              bundle.bundleRef,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: LoomSpacing.md),
            SelectableText(
              bundle.portableJson,
              key: const ValueKey('p9_export_bundle_json'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = _job;
    final bundle = job?.bundle;
    return ListView(
      key: const ValueKey('p9_export_screen'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        Row(
          children: [
            IconButton(
              key: const ValueKey('p9_export_back_button'),
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Expanded(
              child: Text(
                'Export',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        StudioExportPanel(
          key: bundle == null
              ? const ValueKey('p9_export_pending')
              : const ValueKey('p9_export_complete'),
          busy: _busy,
          stateLabel: _stateLabel(job),
          summaryLabel: _summaryLabel(bundle),
          sections:
              bundle?.sections
                  .map(
                    (section) => ExportPanelSection(
                      label: section.label,
                      countLabel: '${section.itemCount}',
                      description: section.description,
                    ),
                  )
                  .toList(growable: false) ??
              const [],
          onCreateExport: _createExport,
          onOpenBundle: bundle == null ? null : _openBundle,
        ),
        if (bundle != null) ...[
          const SizedBox(height: LoomSpacing.md),
          ReceiptStatement(
            key: const ValueKey('p9_export_bundle_summary'),
            title: 'Bundle contents',
            rows: [
              ReceiptStatementRow(
                icon: Icons.video_library_rounded,
                title: 'Content and manifests',
                subtitle: 'Portable catalog and creator-published manifests',
                trailing: '${bundle.contentCount}',
              ),
              ReceiptStatementRow(
                icon: Icons.receipt_long_rounded,
                title: 'Receipt ledger',
                subtitle: 'Receipts tied to exported creator content',
                trailing: '${bundle.receiptCount}',
              ),
              ReceiptStatementRow(
                icon: Icons.payments_rounded,
                title: 'Settlement history',
                subtitle: 'Payout statements included in the bundle',
                trailing: '${bundle.settlementCount}',
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _stateLabel(ExportJob? job) {
    if (job == null) {
      return 'Ready to create a portable bundle';
    }
    return switch (job.state) {
      ExportJobState.queued => 'Queued for bundle assembly',
      ExportJobState.processing => 'Collecting channel, content, receipts',
      ExportJobState.complete => 'Export complete',
    };
  }

  String _summaryLabel(ExportBundle? bundle) {
    if (bundle == null) {
      return 'Create a JSON bundle with channel metadata, content catalog, receipts, settlement history, and configured creator policies.';
    }
    return '${bundle.creatorName} export ${bundle.bundleRef} is ready with ${bundle.contentCount} content records and ${bundle.receiptCount} receipts.';
  }
}
