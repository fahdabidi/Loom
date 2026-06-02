import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import 'channel/channel_banner.dart';
import 'channel/channel_theme.dart';

class CreatorChannelHeader extends StatelessWidget {
  const CreatorChannelHeader({
    required this.displayName,
    required this.handle,
    required this.vertical,
    required this.isFollowed,
    required this.isBlocked,
    required this.onFollow,
    required this.onUnfollow,
    required this.onBlock,
    required this.onBack,
    this.channelTheme = LoomChannelTheme.fallback,
    this.bannerRef = 'seed://banners/default',
    super.key,
  });

  final String displayName;
  final String handle;
  final String vertical;
  final bool isFollowed;
  final bool isBlocked;
  final VoidCallback onFollow;
  final VoidCallback onUnfollow;
  final VoidCallback onBlock;
  final VoidCallback onBack;
  final LoomChannelTheme channelTheme;
  final String bannerRef;

  @override
  Widget build(BuildContext context) {
    return ChannelBanner(
      theme: channelTheme,
      bannerRef: bannerRef,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              key: const ValueKey('p4_channel_back_button'),
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              color: Colors.white,
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: LoomColors.aqua,
                  child: Text(
                    displayName.characters.first,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@$handle · $vertical',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    key: ValueKey(
                      isFollowed ? 'p4_unfollow_button' : 'p4_follow_button',
                    ),
                    onPressed: isBlocked
                        ? null
                        : isFollowed
                        ? onUnfollow
                        : onFollow,
                    icon: Icon(
                      isFollowed
                          ? Icons.person_remove_rounded
                          : Icons.person_add_alt_1_rounded,
                    ),
                    label: Text(isFollowed ? 'Unfollow' : 'Follow'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: channelTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Tooltip(
                  message: 'Block creator',
                  child: IconButton.filled(
                    key: const ValueKey('p4_block_button'),
                    onPressed: isBlocked ? null : onBlock,
                    icon: const Icon(Icons.block_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withAlpha(34),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (isBlocked) ...[
              const SizedBox(height: 10),
              const Text(
                'Blocked. This creator is hidden from recommendations.',
                key: ValueKey('p4_blocked_state'),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
