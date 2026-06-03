import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

class StudioCustomizeConsole extends StatelessWidget {
  const StudioCustomizeConsole({
    required this.title,
    required this.subtitle,
    required this.busy,
    required this.dirty,
    required this.onSave,
    required this.editor,
    required this.preview,
    this.status,
    super.key,
  });

  final String title;
  final String subtitle;
  final bool busy;
  final bool dirty;
  final VoidCallback onSave;
  final String? status;
  final Widget editor;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('p19_customize_console'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: LoomColors.mutedInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              key: const ValueKey('p19_save_experience_button'),
              onPressed: busy || !dirty ? null : onSave,
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: const Text('Save'),
            ),
          ],
        ),
        if (status != null) ...[
          const SizedBox(height: LoomSpacing.sm),
          _StatusBanner(status: status!, dirty: dirty),
        ],
        const SizedBox(height: LoomSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 760) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  preview,
                  const SizedBox(height: LoomSpacing.md),
                  editor,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: editor),
                const SizedBox(width: LoomSpacing.md),
                Expanded(flex: 4, child: preview),
              ],
            );
          },
        ),
      ],
    );
  }
}

class StudioPreviewPanel extends StatelessWidget {
  const StudioPreviewPanel({
    required this.creatorName,
    required this.handle,
    required this.themeName,
    required this.bannerRef,
    required this.aiPersona,
    required this.adPosture,
    required this.modules,
    required this.primaryHex,
    required this.accentHex,
    super.key,
  });

  final String creatorName;
  final String handle;
  final String themeName;
  final String bannerRef;
  final String aiPersona;
  final String adPosture;
  final List<StudioPreviewModule> modules;
  final String primaryHex;
  final String accentHex;

  @override
  Widget build(BuildContext context) {
    final primary = _colorFromHex(primaryHex, LoomColors.ink);
    final accent = _colorFromHex(accentHex, LoomColors.moss);
    return Container(
      key: const ValueKey('p19_live_preview_panel'),
      padding: const EdgeInsets.all(LoomSpacing.md),
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
              Icon(Icons.visibility_rounded, color: primary),
              const SizedBox(width: LoomSpacing.sm),
              Expanded(
                child: Text(
                  'Live preview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: LoomSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(LoomSpacing.md),
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  creatorName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '@$handle',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: LoomSpacing.sm),
                Text(bannerRef, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: LoomSpacing.md),
          _PreviewFact(
            icon: Icons.palette_rounded,
            title: themeName,
            subtitle: 'Theme applied to header, modules, and action states.',
            color: accent,
          ),
          _PreviewFact(
            icon: Icons.auto_awesome_rounded,
            title: aiPersona,
            subtitle: adPosture,
            color: primary,
          ),
          const SizedBox(height: LoomSpacing.sm),
          for (final module in modules)
            _PreviewModuleRow(
              key: ValueKey('p19_preview_module_${module.moduleId}'),
              module: module,
              color: module.enabled ? primary : LoomColors.mutedInk,
            ),
        ],
      ),
    );
  }
}

class StudioPreviewModule {
  const StudioPreviewModule({
    required this.moduleId,
    required this.title,
    required this.kind,
    required this.enabled,
    this.extensionName,
  });

  final String moduleId;
  final String title;
  final String kind;
  final bool enabled;
  final String? extensionName;
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status, required this.dirty});

  final String status;
  final bool dirty;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('p19_customize_status'),
      padding: const EdgeInsets.all(LoomSpacing.md),
      decoration: BoxDecoration(
        color: dirty
            ? LoomColors.sun.withAlpha(42)
            : LoomColors.moss.withAlpha(34),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: dirty ? LoomColors.sun : LoomColors.moss.withAlpha(90),
        ),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: LoomColors.ink,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PreviewFact extends StatelessWidget {
  const _PreviewFact({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LoomSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: LoomSpacing.sm),
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: LoomColors.mutedInk,
                    height: 1.25,
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

class _PreviewModuleRow extends StatelessWidget {
  const _PreviewModuleRow({
    required this.module,
    required this.color,
    super.key,
  });

  final StudioPreviewModule module;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: LoomSpacing.sm),
      padding: const EdgeInsets.all(LoomSpacing.md),
      decoration: BoxDecoration(
        color: LoomColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LoomColors.line),
      ),
      child: Row(
        children: [
          Icon(
            module.kind == 'extension'
                ? Icons.extension_rounded
                : Icons.view_agenda_rounded,
            color: color,
          ),
          const SizedBox(width: LoomSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  module.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  module.extensionName ?? module.kind,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: LoomColors.mutedInk),
                ),
              ],
            ),
          ),
          Icon(
            module.enabled
                ? Icons.check_circle_rounded
                : Icons.remove_circle_outline_rounded,
            color: color,
            size: 18,
          ),
        ],
      ),
    );
  }
}

Color _colorFromHex(String value, Color fallback) {
  final hex = value.replaceFirst('#', '');
  if (hex.length != 6) {
    return fallback;
  }
  final parsed = int.tryParse(hex, radix: 16);
  if (parsed == null) {
    return fallback;
  }
  return Color(0xFF000000 | parsed);
}
