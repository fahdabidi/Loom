import 'package:flutter/material.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_design_system/loom_design_system.dart';

import '../state/content_list_notifier.dart';

class CreatorContentListScreen extends StatefulWidget {
  const CreatorContentListScreen({required this.channelId, super.key});

  final String channelId;

  @override
  State<CreatorContentListScreen> createState() =>
      _CreatorContentListScreenState();
}

class _CreatorContentListScreenState extends State<CreatorContentListScreen> {
  late final ContentListNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = ContentListNotifier(
      api: resolveCreatorMetadataApi(),
      channelId: widget.channelId,
    )..loadInitial();
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _notifier,
      builder: (context, _) {
        final state = _notifier.state;

        if (state.items.isEmpty && state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.separated(
          padding: const EdgeInsets.all(LoomSpacing.md),
          itemBuilder: (context, index) {
            if (index == state.items.length) {
              return _LoadMoreRow(
                isLoading: state.isLoading,
                canLoadMore: state.canLoadMore,
                onPressed: _notifier.loadMore,
              );
            }

            final item = state.items[index];
            return FeedCard(
              child: ContentTile(
                title: item.title,
                summary: item.summary,
                creatorName: item.creatorName,
                contentTypeLabel: item.contentTypeLabel,
              ),
            );
          },
          separatorBuilder: (_, _) => const SizedBox(height: LoomSpacing.sm),
          itemCount: state.items.length + 1,
        );
      },
    );
  }
}

class _LoadMoreRow extends StatelessWidget {
  const _LoadMoreRow({
    required this.isLoading,
    required this.canLoadMore,
    required this.onPressed,
  });

  final bool isLoading;
  final bool canLoadMore;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!canLoadMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: LoomSpacing.lg),
        child: Center(child: Text('End of catalog')),
      );
    }

    return Center(
      child: FilledButton(onPressed: onPressed, child: const Text('Load more')),
    );
  }
}
