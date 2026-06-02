import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

class StudioExternalPreview {
  const StudioExternalPreview({
    required this.sourceLabel,
    required this.title,
    required this.summary,
    required this.thumbnailRef,
    required this.sourceUrl,
    required this.searchIndexable,
    required this.aiQueryable,
    this.creatorNote,
  });

  final String sourceLabel;
  final String title;
  final String summary;
  final String thumbnailRef;
  final String sourceUrl;
  final bool searchIndexable;
  final bool aiQueryable;
  final String? creatorNote;
}

class StudioLinkExternalSheet extends StatelessWidget {
  const StudioLinkExternalSheet({
    required this.inputController,
    required this.noteController,
    required this.sourceOptions,
    required this.selectedSource,
    required this.searchIndexable,
    required this.aiQueryable,
    required this.busy,
    required this.onSelectSource,
    required this.onSearchIndexableChanged,
    required this.onAiQueryableChanged,
    required this.onResolve,
    required this.onSave,
    this.preview,
    super.key,
  });

  final TextEditingController inputController;
  final TextEditingController noteController;
  final List<String> sourceOptions;
  final String selectedSource;
  final bool searchIndexable;
  final bool aiQueryable;
  final bool busy;
  final ValueChanged<String> onSelectSource;
  final ValueChanged<bool> onSearchIndexableChanged;
  final ValueChanged<bool> onAiQueryableChanged;
  final VoidCallback onResolve;
  final VoidCallback onSave;
  final StudioExternalPreview? preview;

  @override
  Widget build(BuildContext context) {
    final resolvedPreview = preview;
    return Container(
      key: const ValueKey('p25_link_external_sheet'),
      padding: const EdgeInsets.all(LoomSpacing.md),
      decoration: BoxDecoration(
        color: LoomColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LoomColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.add_link_rounded),
              const SizedBox(width: LoomSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Link external content',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Resolve a public preview, keep the original title and thumbnail, then place it in the fan channel.',
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
          const SizedBox(height: LoomSpacing.md),
          Wrap(
            spacing: LoomSpacing.sm,
            runSpacing: LoomSpacing.sm,
            children: [
              for (final source in sourceOptions)
                ChoiceChip(
                  key: ValueKey('p25_source_chip_$source'),
                  selected: source == selectedSource,
                  label: Text(source),
                  onSelected: busy ? null : (_) => onSelectSource(source),
                ),
            ],
          ),
          const SizedBox(height: LoomSpacing.md),
          TextField(
            key: const ValueKey('p25_external_link_input'),
            controller: inputController,
            enabled: !busy,
            decoration: const InputDecoration(
              labelText: 'URL or external ID',
              prefixIcon: Icon(Icons.link_rounded),
            ),
          ),
          const SizedBox(height: LoomSpacing.sm),
          TextField(
            key: const ValueKey('p25_external_link_note'),
            controller: noteController,
            enabled: !busy,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Creator note',
              prefixIcon: Icon(Icons.edit_note_rounded),
            ),
          ),
          const SizedBox(height: LoomSpacing.sm),
          _SwitchRow(
            keyName: 'p25_external_search_indexable_toggle',
            icon: Icons.manage_search_rounded,
            title: 'Search indexable',
            subtitle: 'Let public search find this linked reference.',
            value: searchIndexable,
            enabled: !busy,
            onChanged: onSearchIndexableChanged,
          ),
          _SwitchRow(
            keyName: 'p25_external_ai_queryable_toggle',
            icon: Icons.auto_awesome_rounded,
            title: 'AI queryable',
            subtitle: 'Allow connected fan agents to include this reference.',
            value: aiQueryable,
            enabled: !busy,
            onChanged: onAiQueryableChanged,
          ),
          const SizedBox(height: LoomSpacing.md),
          if (resolvedPreview != null) ...[
            ExternalContentFeedTile(
              tileKey: 'p25_external_preview_tile',
              sourceLabel: resolvedPreview.sourceLabel,
              originalTitle: resolvedPreview.title,
              summary: resolvedPreview.summary,
              thumbnailRef: resolvedPreview.thumbnailRef,
              creatorNote: resolvedPreview.creatorNote,
              footer:
                  '${resolvedPreview.searchIndexable ? 'Search on' : 'Search off'} - ${resolvedPreview.aiQueryable ? 'AI on' : 'AI off'}',
            ),
            const SizedBox(height: LoomSpacing.md),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('p25_resolve_external_link_button'),
                  onPressed: busy ? null : onResolve,
                  icon: const Icon(Icons.travel_explore_rounded),
                  label: const Text('Resolve preview'),
                ),
              ),
              const SizedBox(width: LoomSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('p25_save_external_link_button'),
                  onPressed: busy || resolvedPreview == null ? null : onSave,
                  icon: const Icon(Icons.playlist_add_rounded),
                  label: const Text('Add to feed'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ExternalContentFeedTile extends StatelessWidget {
  const ExternalContentFeedTile({
    required this.tileKey,
    required this.sourceLabel,
    required this.originalTitle,
    required this.summary,
    required this.thumbnailRef,
    this.creatorNote,
    this.footer,
    this.onTap,
    super.key,
  });

  final String tileKey;
  final String sourceLabel;
  final String originalTitle;
  final String summary;
  final String thumbnailRef;
  final String? creatorNote;
  final String? footer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey(tileKey),
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(LoomSpacing.sm),
        decoration: BoxDecoration(
          color: LoomColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: LoomColors.line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ExternalPoster(
              thumbnailRef: thumbnailRef,
              sourceLabel: sourceLabel,
            ),
            const SizedBox(width: LoomSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SourcePill(label: sourceLabel),
                  const SizedBox(height: LoomSpacing.xs),
                  Text(
                    originalTitle,
                    key: ValueKey('${tileKey}_original_title'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: LoomSpacing.xs),
                  Text(
                    summary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: LoomColors.mutedInk,
                      height: 1.24,
                    ),
                  ),
                  if (creatorNote != null && creatorNote!.isNotEmpty) ...[
                    const SizedBox(height: LoomSpacing.xs),
                    Text(
                      creatorNote!,
                      key: ValueKey('${tileKey}_creator_note'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: LoomColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  if (footer != null) ...[
                    const SizedBox(height: LoomSpacing.xs),
                    Text(
                      footer!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: LoomColors.moss,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                color: LoomColors.mutedInk,
              ),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.keyName,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String keyName;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      key: ValueKey(keyName),
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }
}

class _ExternalPoster extends StatelessWidget {
  const _ExternalPoster({
    required this.thumbnailRef,
    required this.sourceLabel,
  });

  final String thumbnailRef;
  final String sourceLabel;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 112,
        height: 72,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _thumbnailBackground(),
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(150),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnailBackground() {
    if (thumbnailRef.startsWith('http://') ||
        thumbnailRef.startsWith('https://')) {
      return Image.network(
        thumbnailRef,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            _FallbackPoster(seed: thumbnailRef, label: sourceLabel),
      );
    }
    return _FallbackPoster(seed: thumbnailRef, label: sourceLabel);
  }
}

class _FallbackPoster extends StatelessWidget {
  const _FallbackPoster({required this.seed, required this.label});

  final String seed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = _posterGradientFor(seed);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette,
        ),
      ),
      child: Center(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SourcePill extends StatelessWidget {
  const _SourcePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('p25_external_content_source_chip_$label'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: LoomColors.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: LoomColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.public_rounded,
            size: 14,
            color: LoomColors.mutedInk,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: LoomColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

List<Color> _posterGradientFor(String seed) {
  final hash = seed.codeUnits.fold<int>(0, (sum, codeUnit) => sum + codeUnit);
  final palettes = const [
    [Color(0xFF172A3A), Color(0xFF1C8EA8)],
    [Color(0xFF253528), Color(0xFFF2C94C)],
    [Color(0xFF2E253A), Color(0xFF7C5CFC)],
    [Color(0xFF332B20), Color(0xFFE45858)],
  ];
  return palettes[hash % palettes.length];
}
