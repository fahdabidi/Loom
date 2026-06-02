import 'package:flutter/material.dart';

import 'channel_media_backdrop.dart';
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
    return SizedBox(
      key: ValueKey('p16_channel_banner_$bannerRef'),
      child: Stack(
        children: [
          ChannelMediaBackdrop(theme: theme, bannerRef: bannerRef),
          Positioned(
            left: 18,
            bottom: 18,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(38),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withAlpha(52)),
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
