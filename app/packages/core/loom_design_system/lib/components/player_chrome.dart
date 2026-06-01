import 'package:flutter/material.dart';

import '../tokens/colors.dart';

class PlayerChrome extends StatelessWidget {
  const PlayerChrome({
    required this.title,
    required this.thumbnailRef,
    required this.isComplete,
    required this.onComplete,
    super.key,
  });

  final String title;
  final String thumbnailRef;
  final bool isComplete;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(thumbnailRef);
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: LinearGradient(colors: palette)),
        child: Stack(
          children: [
            Center(
              child: IconButton.filled(
                key: const ValueKey('p4_complete_button'),
                onPressed: isComplete ? null : onComplete,
                icon: Icon(
                  isComplete ? Icons.check_rounded : Icons.play_arrow_rounded,
                  size: 42,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withAlpha(210),
                  foregroundColor: LoomColors.ink,
                  minimumSize: const Size(76, 76),
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
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
