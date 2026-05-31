import 'package:flutter/material.dart';

import '../../tokens/spacing.dart';

class LoomNavScaffold extends StatelessWidget {
  const LoomNavScaffold({
    required this.title,
    required this.roleSwitcher,
    required this.child,
    super.key,
  });

  final String title;
  final Widget roleSwitcher;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: LoomSpacing.md),
            child: roleSwitcher,
          ),
        ],
      ),
      body: SafeArea(child: child),
    );
  }
}
