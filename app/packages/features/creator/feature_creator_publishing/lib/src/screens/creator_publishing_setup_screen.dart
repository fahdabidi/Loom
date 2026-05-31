import 'package:flutter/material.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_design_system/loom_design_system.dart';

import '../state/creator_publishing_controller.dart';

class CreatorPublishingSetupScreen extends StatefulWidget {
  const CreatorPublishingSetupScreen({required this.channelId, super.key});

  final String channelId;

  @override
  State<CreatorPublishingSetupScreen> createState() =>
      _CreatorPublishingSetupScreenState();
}

class _CreatorPublishingSetupScreenState
    extends State<CreatorPublishingSetupScreen> {
  late final CreatorPublishingController _controller;
  late final TextEditingController _titleController;
  late final TextEditingController _summaryController;

  @override
  void initState() {
    super.initState();
    _controller = CreatorPublishingController(
      channelId: widget.channelId,
      metadataApi: resolveCreatorMetadataApi(),
      contentHostApi: resolveContentHostApi(),
      migrationExportApi: resolveMigrationExportApi(),
      entitlementLedgerApi: resolveEntitlementLedgerApi(),
      aiGatewayApi: resolveAiGatewayApi(),
    )..load();
    _titleController = TextEditingController(
      text: 'Battery backup sizing without guesswork',
    );
    _summaryController = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final draft = _controller.summaryDraft;
        if (draft != null && _summaryController.text.isEmpty) {
          _summaryController.text = draft;
        }

        return ListView(
          key: const ValueKey('p2_studio_scroll'),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
          children: [
            _StudioHeader(isLoading: _controller.isLoading),
            const SizedBox(height: LoomSpacing.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  StudioStatusCard(
                    icon: Icons.video_library_outlined,
                    label: 'published items',
                    value: '${_controller.publishedCount}',
                  ),
                  const SizedBox(width: LoomSpacing.sm),
                  StudioStatusCard(
                    icon: Icons.workspace_premium_outlined,
                    label: 'membership tiers',
                    value: '${_controller.tiers.length}',
                  ),
                  const SizedBox(width: LoomSpacing.sm),
                  StudioStatusCard(
                    icon: Icons.verified_user_outlined,
                    label: 'ad policy',
                    value: _controller.adPolicy == null ? 'open' : 'set',
                  ),
                ],
              ),
            ),
            const SizedBox(height: LoomSpacing.md),
            StudioPublishComposer(
              titleController: _titleController,
              summaryController: _summaryController,
              errorText: _controller.errorMessage,
              onDraftSummary: () => _controller.draftSummary(
                title: _titleController.text,
                sourceNote: 'battery sizing, outage coverage, and payback',
              ),
              onPublishWithoutSummary: () =>
                  _controller.publishWithoutSummary(_titleController.text),
              onPublishVideo: () => _controller.publishVideo(
                title: _titleController.text,
                summary: _summaryController.text,
              ),
              onPublishPost: () => _controller.publishPost(
                title: _titleController.text,
                summary: _summaryController.text,
              ),
            ),
            if (_controller.lastPublished != null) ...[
              const SizedBox(height: LoomSpacing.sm),
              _StatusLine(
                key: const ValueKey('p2_publish_success'),
                text:
                    'Published ${_controller.lastPublished!.title} - manifest v${_controller.lastPublished!.schemaVersion}',
              ),
            ],
            const SizedBox(height: LoomSpacing.md),
            StudioImportWizard(
              stateLabel: _importStateLabel,
              importedCount: _controller.importedCount,
              onStartImport: _controller.startImport,
            ),
            if (_controller.importJob?.state.name == 'complete')
              const _StatusLine(
                key: ValueKey('p2_import_success'),
                text: 'Import complete - external refs available',
              ),
            const SizedBox(height: LoomSpacing.md),
            StudioMonetizationEditor(
              tierCount: _controller.tiers.length,
              entitlementCount: _controller.entitlements.length,
              onDefineTiers: _controller.defineTiers,
            ),
            if (_controller.entitlements.isNotEmpty)
              _StatusLine(
                key: const ValueKey('p2_membership_success'),
                text:
                    'Membership setup complete - ${_controller.entitlements.length} entitlements registered',
              ),
            const SizedBox(height: LoomSpacing.md),
            StudioAdPolicyEditor(
              savedLabel: _controller.adPolicy == null
                  ? 'Contextual ads may run until policy is saved.'
                  : 'Policy saved - blocks gambling and alcohol.',
              onSavePolicy: _controller.saveAdPolicy,
            ),
            if (_controller.adPolicy != null)
              const _StatusLine(
                key: ValueKey('p2_ad_policy_success'),
                text: 'CreatorAdPolicy persisted',
              ),
            const SizedBox(height: LoomSpacing.md),
            StudioAiPanel(
              enabled: _controller.aiPolicy?.archiveQaEnabled ?? false,
              onEnable: _controller.enableAi,
            ),
            if (_controller.aiPolicy?.archiveQaEnabled ?? false)
              const _StatusLine(
                key: ValueKey('p2_ai_success'),
                text: 'AIContentPolicy stored - Q&A and summaries enabled',
              ),
          ],
        );
      },
    );
  }

  String get _importStateLabel {
    final job = _controller.importJob;
    if (job == null) {
      return 'Ready';
    }
    return job.state.name;
  }
}

class _StudioHeader extends StatelessWidget {
  const _StudioHeader({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LoomColors.ink,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Chip(
                label: Text('Phase 2 setup'),
                avatar: Icon(Icons.tune_rounded, size: 18),
              ),
              const Spacer(),
              if (isLoading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: LoomSpacing.md),
          Text(
            'Prepare content, money, ads, and AI before discovery.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: LoomColors.surface,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: LoomSpacing.sm),
          Text(
            'This work console keeps the publishing path visible while advanced controls stay compact.',
            style: TextStyle(color: LoomColors.surface.withAlpha(210)),
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: LoomSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: LoomColors.moss),
          const SizedBox(width: LoomSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
