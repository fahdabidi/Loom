import 'package:flutter/material.dart';

class FeedCard extends StatelessWidget {
  const FeedCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(clipBehavior: Clip.antiAlias, child: child);
  }
}
