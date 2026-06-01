import 'package:flutter/material.dart';

import '../tokens/colors.dart';

class CitationLink extends StatelessWidget {
  const CitationLink({
    required this.title,
    required this.startLabel,
    required this.onTap,
    super.key,
  });

  final String title;
  final String startLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.article_rounded, size: 18),
      label: Text('$title - $startLabel', overflow: TextOverflow.ellipsis),
      labelStyle: const TextStyle(fontWeight: FontWeight.w800),
      backgroundColor: LoomColors.surfaceAlt,
      side: const BorderSide(color: LoomColors.line),
      onPressed: onTap,
    );
  }
}
