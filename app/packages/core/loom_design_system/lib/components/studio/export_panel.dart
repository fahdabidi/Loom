import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

class StudioExportPanel extends StatelessWidget {
  const StudioExportPanel({
    required this.stateLabel,
    required this.summaryLabel,
    required this.sections,
    this.onCreateExport,
    this.onOpenBundle,
    this.busy = false,
    super.key,
  });

  final String stateLabel;
  final String summaryLabel;
  final List<ExportPanelSection> sections;
  final VoidCallback? onCreateExport;
  final VoidCallback? onOpenBundle;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(LoomSpacing.lg),
      decoration: BoxDecoration(
        color: LoomColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LoomColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: LoomColors.aqua.withAlpha(42),
                child: const Icon(Icons.archive_rounded),
              ),
              const SizedBox(width: LoomSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Portable export',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      stateLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: LoomColors.mutedInk,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (busy)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: LoomSpacing.md),
          Text(
            summaryLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: LoomColors.mutedInk,
              height: 1.28,
            ),
          ),
          const SizedBox(height: LoomSpacing.md),
          if (sections.isEmpty)
            const _ExportEmptyState()
          else
            Column(
              children: [
                for (final section in sections)
                  _ExportSectionRow(section: section),
              ],
            ),
          const SizedBox(height: LoomSpacing.md),
          Wrap(
            spacing: LoomSpacing.sm,
            runSpacing: LoomSpacing.sm,
            children: [
              FilledButton.icon(
                key: const ValueKey('p9_create_export_button'),
                onPressed: busy ? null : onCreateExport,
                icon: const Icon(Icons.file_upload_outlined),
                label: const Text('Create export'),
              ),
              FilledButton.tonalIcon(
                key: const ValueKey('p9_open_bundle_button'),
                onPressed: onOpenBundle,
                icon: const Icon(Icons.code_rounded),
                label: const Text('Review bundle'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ExportPanelSection {
  const ExportPanelSection({
    required this.label,
    required this.countLabel,
    required this.description,
  });

  final String label;
  final String countLabel;
  final String description;
}

class _ExportSectionRow extends StatelessWidget {
  const _ExportSectionRow({required this.section});

  final ExportPanelSection section;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.check_circle_rounded, color: LoomColors.moss),
      title: Text(section.label),
      subtitle: Text(section.description),
      trailing: Text(
        section.countLabel,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _ExportEmptyState extends StatelessWidget {
  const _ExportEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(LoomSpacing.md),
      decoration: BoxDecoration(
        color: LoomColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'No export bundle has been generated in this demo session.',
        style: TextStyle(
          color: LoomColors.mutedInk,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
