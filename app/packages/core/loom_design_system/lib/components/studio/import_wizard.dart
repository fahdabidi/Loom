import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

class StudioImportWizard extends StatelessWidget {
  const StudioImportWizard({
    required this.stateLabel,
    required this.importedCount,
    required this.onStartImport,
    super.key,
  });

  final String stateLabel;
  final int importedCount;
  final VoidCallback onStartImport;

  @override
  Widget build(BuildContext context) {
    return _MiniPanel(
      icon: Icons.cloud_download_outlined,
      title: 'Catalog import',
      subtitle: '$stateLabel - $importedCount imported refs',
      buttonKey: const ValueKey('p2_start_import_button'),
      buttonLabel: 'Start import',
      onPressed: onStartImport,
    );
  }
}

class StudioAiPanel extends StatelessWidget {
  const StudioAiPanel({
    required this.enabled,
    required this.onEnable,
    super.key,
  });

  final bool enabled;
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    return _MiniPanel(
      icon: Icons.psychology_alt_outlined,
      title: 'AI archive',
      subtitle: enabled ? 'Q&A and summaries enabled' : 'Not enabled yet',
      buttonKey: const ValueKey('p2_enable_ai_button'),
      buttonLabel: 'Enable AI',
      onPressed: onEnable,
    );
  }
}

class _MiniPanel extends StatelessWidget {
  const _MiniPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonKey,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Key buttonKey;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LoomSpacing.md),
      decoration: BoxDecoration(
        color: LoomColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LoomColors.line),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: LoomColors.sun.withAlpha(48),
            child: Icon(icon, color: LoomColors.ink),
          ),
          const SizedBox(width: LoomSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: LoomColors.mutedInk),
                ),
              ],
            ),
          ),
          FilledButton(
            key: buttonKey,
            onPressed: onPressed,
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}
