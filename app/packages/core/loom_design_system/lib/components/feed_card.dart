import 'package:flutter/material.dart';

import '../tokens/colors.dart';

class FeedCard extends StatelessWidget {
  const FeedCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: LoomColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: LoomColors.line),
      ),
      child: child,
    );
  }
}
