import 'package:flutter/material.dart';

import '../tokens/colors.dart';

class PostView extends StatelessWidget {
  const PostView({
    required this.title,
    required this.body,
    required this.onComplete,
    required this.isComplete,
    super.key,
  });

  final String title;
  final String body;
  final VoidCallback onComplete;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('p4_post_view'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LoomColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(body, style: const TextStyle(height: 1.35)),
          const SizedBox(height: 14),
          FilledButton.icon(
            key: const ValueKey('p4_complete_button'),
            onPressed: isComplete ? null : onComplete,
            icon: Icon(isComplete ? Icons.check_rounded : Icons.done_rounded),
            label: Text(isComplete ? 'Completed' : 'Mark complete'),
          ),
        ],
      ),
    );
  }
}
