import 'package:flutter/material.dart';

import 'channel_theme.dart';

class ChannelMediaBackdrop extends StatelessWidget {
  const ChannelMediaBackdrop({
    required this.theme,
    required this.bannerRef,
    super.key,
  });

  final LoomChannelTheme theme;
  final String bannerRef;

  @override
  Widget build(BuildContext context) {
    final profile = _profileFor(bannerRef);
    return Positioned.fill(
      key: ValueKey('p20_channel_media_$bannerRef'),
      child: ClipRect(
        child: Stack(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.primary,
                    profile.overlayColor(theme),
                    theme.secondary,
                  ],
                ),
              ),
              child: const SizedBox.expand(),
            ),
            Positioned(
              left: -36,
              top: 22,
              child: _MotifRing(color: Colors.white.withAlpha(24), size: 156),
            ),
            Positioned(
              right: -20,
              top: -10,
              child: Icon(
                profile.icon,
                size: 178,
                color: Colors.white.withAlpha(44),
              ),
            ),
            Positioned(
              right: 18,
              bottom: 18,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(54),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withAlpha(56)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Text(
                    profile.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MotifRing extends StatelessWidget {
  const _MotifRing({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 18),
      ),
    );
  }
}

class _BannerProfile {
  const _BannerProfile({
    required this.label,
    required this.icon,
    required this.tint,
  });

  final String label;
  final IconData icon;
  final Color tint;

  Color overlayColor(LoomChannelTheme theme) {
    return Color.alphaBlend(tint.withAlpha(120), theme.primary);
  }
}

_BannerProfile _profileFor(String bannerRef) {
  if (bannerRef.contains('nova') || bannerRef.contains('frame')) {
    return const _BannerProfile(
      label: 'Arena media',
      icon: Icons.sports_esports_rounded,
      tint: Color(0xFF2563EB),
    );
  }
  if (bannerRef.contains('ember')) {
    return const _BannerProfile(
      label: 'Quest media',
      icon: Icons.auto_stories_rounded,
      tint: Color(0xFFB45309),
    );
  }
  if (bannerRef.contains('drift')) {
    return const _BannerProfile(
      label: 'Community media',
      icon: Icons.groups_3_rounded,
      tint: Color(0xFF6366F1),
    );
  }
  if (bannerRef.contains('iron')) {
    return const _BannerProfile(
      label: 'Guild media',
      icon: Icons.shield_rounded,
      tint: Color(0xFF374151),
    );
  }
  return const _BannerProfile(
    label: 'Creator media',
    icon: Icons.auto_awesome_rounded,
    tint: Color(0xFF167A55),
  );
}
