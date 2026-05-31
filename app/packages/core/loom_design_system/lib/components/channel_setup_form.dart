import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';

class ChannelSetupForm extends StatelessWidget {
  const ChannelSetupForm({
    required this.displayNameController,
    required this.handleController,
    required this.descriptionController,
    required this.verticalController,
    super.key,
  });

  final TextEditingController displayNameController;
  final TextEditingController handleController;
  final TextEditingController descriptionController;
  final TextEditingController verticalController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChannelPreview(
          displayName: displayNameController.text,
          handle: handleController.text,
          vertical: verticalController.text,
          description: descriptionController.text,
        ),
        const SizedBox(height: LoomSpacing.lg),
        Text(
          'Channel basics',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: LoomSpacing.md),
        TextField(
          key: const ValueKey('creator_display_name_field'),
          controller: displayNameController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.badge_outlined),
            labelText: 'Channel name',
          ),
        ),
        const SizedBox(height: LoomSpacing.md),
        TextField(
          key: const ValueKey('creator_handle_field'),
          controller: handleController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.alternate_email_rounded),
            prefixText: '@',
            labelText: 'Handle',
          ),
        ),
        const SizedBox(height: LoomSpacing.md),
        TextField(
          key: const ValueKey('creator_vertical_field'),
          controller: verticalController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.category_outlined),
            labelText: 'Category',
          ),
        ),
        const SizedBox(height: LoomSpacing.md),
        TextField(
          key: const ValueKey('creator_description_field'),
          controller: descriptionController,
          minLines: 3,
          maxLines: 4,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.notes_rounded),
            labelText: 'Channel description',
          ),
        ),
      ],
    );
  }
}

class _ChannelPreview extends StatelessWidget {
  const _ChannelPreview({
    required this.displayName,
    required this.handle,
    required this.vertical,
    required this.description,
  });

  final String displayName;
  final String handle;
  final String vertical;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: LoomColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: LoomColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 118,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF167A55), Color(0xFF1C8EA8)],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  top: -20,
                  child: Icon(
                    Icons.video_camera_back_rounded,
                    size: 132,
                    color: Colors.white.withAlpha(36),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(LoomSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: LoomColors.ink,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: LoomColors.surface, width: 3),
                      ),
                      child: Text(
                        _initials(displayName),
                        style: const TextStyle(
                          color: LoomColors.surface,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: LoomSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            '@$handle',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: LoomColors.mutedInk,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: LoomSpacing.xs),
                          Chip(label: Text(vertical)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: LoomSpacing.md),
                Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: LoomColors.mutedInk,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _initials(String value) {
  final parts = value
      .split(' ')
      .where((part) => part.trim().isNotEmpty)
      .take(2)
      .map((part) => part.characters.first.toUpperCase());
  final initials = parts.join();
  return initials.isEmpty ? 'L' : initials;
}
