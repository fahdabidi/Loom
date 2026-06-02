import 'package:flutter/material.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_design_system/loom_design_system.dart';

class CatalogImportConsoleScreen extends StatefulWidget {
  const CatalogImportConsoleScreen({
    required this.channelId,
    required this.onBack,
    super.key,
  });

  final String channelId;
  final VoidCallback onBack;

  @override
  State<CatalogImportConsoleScreen> createState() =>
      _CatalogImportConsoleScreenState();
}

class _CatalogImportConsoleScreenState
    extends State<CatalogImportConsoleScreen> {
  late final ImportPublicMetadataApi _importApi;
  late final ExternalAccountLinkApi _externalAccountApi;

  List<ExternalAccountLink> _accounts = const [];
  List<PublicImportedReference> _references = const [];
  PublicMetadataImportJob? _job;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _importApi = resolveImportPublicMetadataApi();
    _externalAccountApi = resolveExternalAccountLinkApi();
    _load();
  }

  Future<void> _load() async {
    final accounts = await _externalAccountApi.listExternalAccounts(
      channelId: widget.channelId,
    );
    final references = await _importApi.listImportedReferences(
      channelId: widget.channelId,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _accounts = accounts;
      _references = references;
      _loading = false;
    });
  }

  Future<void> _startImport() async {
    if (_accounts.isEmpty || _busy) {
      return;
    }
    setState(() => _busy = true);
    final account = _accounts.first;
    var job = await _importApi.startImport(
      channelId: widget.channelId,
      externalAccountLinkId: account.linkId,
      rightsBasis: 'public_metadata_only',
      maxItems: 12,
      idempotencyKey: 'p13-public-import-${widget.channelId}-${account.linkId}',
    );
    job = await _importApi.getImportJob(
      channelId: widget.channelId,
      jobId: job.jobId,
    );
    final references = await _importApi.listImportedReferences(
      channelId: widget.channelId,
      jobId: job.jobId,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _job = job;
      _references = references;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      key: const ValueKey('p13_catalog_import_console'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        Row(
          children: [
            IconButton(
              key: const ValueKey('p13_catalog_import_back_button'),
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Expanded(
              child: Text(
                'Catalog import',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: LoomSpacing.md),
        StudioImportWizard(
          stateLabel: _job?.status ?? 'Ready',
          importedCount: _references.length,
          onStartImport: _busy ? () {} : _startImport,
        ),
        const SizedBox(height: LoomSpacing.md),
        _ProvenancePanel(accounts: _accounts),
        const SizedBox(height: LoomSpacing.md),
        for (final reference in _references) ...[
          _ImportedReferenceRow(reference: reference),
          const SizedBox(height: LoomSpacing.sm),
        ],
      ],
    );
  }
}

class _ProvenancePanel extends StatelessWidget {
  const _ProvenancePanel({required this.accounts});

  final List<ExternalAccountLink> accounts;

  @override
  Widget build(BuildContext context) {
    final account = accounts.isEmpty ? null : accounts.first;
    return DataDashboardRow(
      key: const ValueKey('p13_catalog_import_provenance'),
      icon: Icons.verified_rounded,
      title: account == null
          ? 'No connected public account'
          : '${account.platform} ${account.handle}',
      subtitle:
          'Imports public metadata only; rights basis and source URLs stay visible.',
    );
  }
}

class _ImportedReferenceRow extends StatelessWidget {
  const _ImportedReferenceRow({required this.reference});

  final PublicImportedReference reference;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('p13_imported_ref_${reference.referenceId}'),
      padding: const EdgeInsets.all(LoomSpacing.md),
      decoration: BoxDecoration(
        color: LoomColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LoomColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.video_library_outlined, color: LoomColors.mutedInk),
          const SizedBox(width: LoomSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reference.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${reference.platform} · ${reference.rightsBasis}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: LoomColors.mutedInk,
                    fontWeight: FontWeight.w800,
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
