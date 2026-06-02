import 'package:flutter/material.dart';

import 'channel_theme.dart';

class ChannelBanner extends StatelessWidget {
  const ChannelBanner({
    required this.theme,
    required this.bannerRef,
    required this.child,
    super.key,
  });

  final LoomChannelTheme theme;
  final String bannerRef;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('p16_channel_banner_$bannerRef'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.primary, theme.secondary],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -18,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 168,
              color: Colors.white.withAlpha(34),
            ),
          ),
          Positioned(
            right: 18,
            bottom: 18,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(36),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Text(
                  theme.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
