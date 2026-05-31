import 'package:flutter/material.dart';

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
      children: [
        TextField(
          key: const ValueKey('creator_display_name_field'),
          controller: displayNameController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Channel name'),
        ),
        const SizedBox(height: LoomSpacing.md),
        TextField(
          key: const ValueKey('creator_handle_field'),
          controller: handleController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            prefixText: '@',
            labelText: 'Handle',
          ),
        ),
        const SizedBox(height: LoomSpacing.md),
        TextField(
          key: const ValueKey('creator_vertical_field'),
          controller: verticalController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Category'),
        ),
        const SizedBox(height: LoomSpacing.md),
        TextField(
          key: const ValueKey('creator_description_field'),
          controller: descriptionController,
          minLines: 3,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Channel description'),
        ),
      ],
    );
  }
}
