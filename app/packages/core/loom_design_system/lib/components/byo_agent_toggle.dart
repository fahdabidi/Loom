import 'package:flutter/material.dart';

import '../tokens/colors.dart';

class ByoAgentToggle extends StatelessWidget {
  const ByoAgentToggle({
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: enabled ? LoomColors.surfaceAlt : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: enabled ? LoomColors.moss : LoomColors.line),
      ),
      child: SwitchListTile(
        key: const ValueKey('p5_summary_rank_toggle'),
        value: enabled,
        onChanged: onChanged,
        secondary: const Icon(Icons.smart_toy_outlined),
        title: const Text(
          'Summary-first agent',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: const Text('Rank by creator summaries; deemphasize titles.'),
      ),
    );
  }
}
