import 'dart:async';

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../tokens/colors.dart';

class YoutubeEmbedPlayer extends StatefulWidget {
  const YoutubeEmbedPlayer({
    required this.videoId,
    this.enabled = true,
    this.autoPlay = false,
    this.fallbackLabel = 'External video player',
    super.key,
  });

  final String videoId;
  final bool enabled;
  final bool autoPlay;
  final String fallbackLabel;

  @override
  State<YoutubeEmbedPlayer> createState() => _YoutubeEmbedPlayerState();
}

class _YoutubeEmbedPlayerState extends State<YoutubeEmbedPlayer> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _controller = _buildController();
    }
  }

  @override
  void didUpdateWidget(YoutubeEmbedPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) {
      final controller = _controller;
      _controller = null;
      if (controller != null) {
        unawaited(controller.close());
      }
      return;
    }
    if (!oldWidget.enabled || oldWidget.videoId != widget.videoId) {
      final controller = _controller;
      _controller = _buildController();
      if (controller != null) {
        unawaited(controller.close());
      }
    }
  }

  @override
  void dispose() {
    final controller = _controller;
    if (controller != null) {
      unawaited(controller.close());
    }
    super.dispose();
  }

  YoutubePlayerController _buildController() {
    return YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: widget.autoPlay,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        strictRelatedVideos: true,
        privacyEnhancedMode: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (!widget.enabled || controller == null) {
      return _PlayerFallback(label: widget.fallbackLabel);
    }
    return Container(
      key: const ValueKey('p24_youtube_embed_player'),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LoomColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: YoutubePlayer(
        controller: controller,
        aspectRatio: 16 / 9,
        backgroundColor: Colors.black,
        autoFullScreen: true,
      ),
    );
  }
}

class _PlayerFallback extends StatelessWidget {
  const _PlayerFallback({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      key: const ValueKey('p24_youtube_embed_player_mock'),
      aspectRatio: 16 / 9,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: LoomColors.charcoal,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
