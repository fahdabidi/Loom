import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

class AiResultTile extends StatelessWidget {
  const AiResultTile({
    required this.resultKey,
    required this.title,
    required this.summary,
    required this.thumbnailRef,
    required this.sourceLabel,
    required this.rankReason,
    required this.isExternal,
    this.accurateMatchLabel,
    this.originalTitle,
    this.creatorName,
    this.titleRiskSignals = const [],
    this.onOpen,
    this.onWhy,
    super.key,
  });

  final String resultKey;
  final String title;
  final String summary;
  final String thumbnailRef;
  final String sourceLabel;
  final String rankReason;
  final bool isExternal;
  final String? accurateMatchLabel;
  final String? originalTitle;
  final String? creatorName;
  final List<String> titleRiskSignals;
  final VoidCallback? onOpen;
  final VoidCallback? onWhy;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey(resultKey),
      onTap: onOpen,
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
            _AiResultPoster(
              thumbnailRef: thumbnailRef,
              isExternal: isExternal,
              sourceLabel: sourceLabel,
            ),
            const SizedBox(width: LoomSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _SourceChip(
                        label: sourceLabel,
                        icon: isExternal
                            ? Icons.public_rounded
                            : Icons.verified_rounded,
                      ),
                      if (titleRiskSignals.isNotEmpty)
                        const _SourceChip(
                          label: 'Title checked',
                          icon: Icons.fact_check_rounded,
                        ),
                    ],
                  ),
                  const SizedBox(height: LoomSpacing.xs),
                  if (isExternal && accurateMatchLabel != null) ...[
                    Text(
                      accurateMatchLabel!,
                      key: ValueKey('${resultKey}_accurate_match'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      originalTitle ?? title,
                      key: ValueKey('${resultKey}_original_title'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: LoomColors.mutedInk,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ] else ...[
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    if (creatorName != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        creatorName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: LoomColors.mutedInk,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: LoomSpacing.xs),
                  Text(
                    summary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: LoomColors.mutedInk,
                      height: 1.22,
                    ),
                  ),
                  const SizedBox(height: LoomSpacing.xs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          rankReason,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: LoomColors.moss,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Why ranked',
                        onPressed: onWhy,
                        icon: const Icon(Icons.info_outline_rounded, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiResultPoster extends StatelessWidget {
  const _AiResultPoster({
    required this.thumbnailRef,
    required this.isExternal,
    required this.sourceLabel,
  });

  final String thumbnailRef;
  final bool isExternal;
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
                child: Icon(
                  isExternal ? Icons.play_arrow_rounded : Icons.article_rounded,
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

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('p23_source_chip_$label'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: LoomColors.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: LoomColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: LoomColors.mutedInk),
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
