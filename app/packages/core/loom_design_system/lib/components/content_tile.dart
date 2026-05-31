import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';

class ContentTile extends StatelessWidget {
  const ContentTile({
    required this.title,
    required this.summary,
    required this.creatorName,
    required this.contentTypeLabel,
    required this.thumbnailRef,
    super.key,
  });

  final String title;
  final String summary;
  final String creatorName;
  final String contentTypeLabel;
  final String thumbnailRef;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SeedPoster(
          thumbnailRef: thumbnailRef,
          title: title,
          contentTypeLabel: contentTypeLabel,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            LoomSpacing.md,
            LoomSpacing.md,
            LoomSpacing.md,
            LoomSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CreatorAvatar(name: creatorName, thumbnailRef: thumbnailRef),
              const SizedBox(width: LoomSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            creatorName,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: LoomSpacing.xs),
                        const Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: LoomColors.aqua,
                        ),
                      ],
                    ),
                    const SizedBox(height: LoomSpacing.xxs),
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: LoomSpacing.xs),
                    Text(
                      summary,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: LoomColors.mutedInk,
                        height: 1.28,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            LoomSpacing.md,
            0,
            LoomSpacing.md,
            LoomSpacing.md,
          ),
          child: Row(
            children: [
              _ActionChip(
                icon: contentTypeLabel == 'Video'
                    ? Icons.play_arrow_rounded
                    : Icons.article_rounded,
                label: contentTypeLabel == 'Video' ? 'Play' : 'Read',
              ),
              const SizedBox(width: LoomSpacing.xs),
              const _ActionIcon(icon: Icons.favorite_border_rounded),
              const _ActionIcon(icon: Icons.ios_share_rounded),
              const _ActionIcon(icon: Icons.bookmark_border_rounded),
              const Spacer(),
              Text(
                'Why this',
                style: textTheme.labelMedium?.copyWith(
                  color: LoomColors.mutedInk,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.info_outline_rounded,
                color: LoomColors.mutedInk,
                size: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SeedPoster extends StatelessWidget {
  const _SeedPoster({
    required this.thumbnailRef,
    required this.title,
    required this.contentTypeLabel,
  });

  final String thumbnailRef;
  final String title;
  final String contentTypeLabel;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(thumbnailRef);
    final icon = contentTypeLabel == 'Video'
        ? Icons.play_arrow_rounded
        : Icons.article_rounded;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: palette,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -24,
              top: -20,
              child: Icon(icon, size: 156, color: Colors.white.withAlpha(34)),
            ),
            Positioned(
              left: LoomSpacing.md,
              top: LoomSpacing.md,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: LoomSpacing.sm,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(104),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: LoomColors.surface, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      contentTypeLabel,
                      style: const TextStyle(
                        color: LoomColors.surface,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: LoomSpacing.md,
              right: LoomSpacing.md,
              bottom: LoomSpacing.md,
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: LoomColors.surface,
                  fontWeight: FontWeight.w900,
                  height: 1.03,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatorAvatar extends StatelessWidget {
  const _CreatorAvatar({required this.name, required this.thumbnailRef});

  final String name;
  final String thumbnailRef;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(thumbnailRef).reversed.toList();
    final initials = name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.characters.first)
        .join();

    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: palette),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        initials,
        style: const TextStyle(
          color: LoomColors.surface,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: LoomSpacing.sm),
      decoration: BoxDecoration(
        color: LoomColors.ink,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: LoomColors.surface, size: 18),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: LoomColors.surface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: () {},
        icon: Icon(icon, size: 20),
      ),
    );
  }
}

List<Color> _paletteFor(String seed) {
  if (seed.contains('solar')) {
    return const [Color(0xFF0F6B55), Color(0xFFF2C94C)];
  }
  if (seed.contains('ferment')) {
    return const [Color(0xFF7C2D46), Color(0xFFEFA94A)];
  }
  if (seed.contains('motion')) {
    return const [Color(0xFF1C508A), Color(0xFF69C7B8)];
  }
  return const [LoomColors.charcoal, LoomColors.aqua];
}
