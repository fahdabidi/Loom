import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

class ConnectedServiceRow extends StatelessWidget {
  const ConnectedServiceRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.connected,
    required this.onChanged,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool connected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: connected ? LoomColors.moss : LoomColors.surfaceAlt,
        foregroundColor: connected ? Colors.white : LoomColors.ink,
        child: Icon(icon),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(subtitle),
      trailing: Switch(value: connected, onChanged: onChanged),
    );
  }
}

class ConnectionStatusChip extends StatelessWidget {
  const ConnectionStatusChip({required this.connected, super.key});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: connected
            ? LoomColors.moss.withValues(alpha: 0.12)
            : LoomColors.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: connected ? LoomColors.moss : LoomColors.line,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LoomSpacing.sm,
          vertical: 6,
        ),
        child: Text(
          connected ? 'Connected' : 'Disconnected',
          style: TextStyle(
            color: connected ? LoomColors.moss : LoomColors.mutedInk,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
