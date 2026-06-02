import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';

class StarterPackMemberView {
  const StarterPackMemberView({
    required this.channelId,
    required this.displayName,
    required this.handle,
    required this.reason,
    required this.avatarRef,
    required this.isSourceCreator,
    required this.alreadyFollowing,
  });

  final String channelId;
  final String displayName;
  final String handle;
  final String reason;
  final String avatarRef;
  final bool isSourceCreator;
  final bool alreadyFollowing;
}

class StarterPackMemberRow extends StatelessWidget {
  const StarterPackMemberRow({
    required this.member,
    required this.selected,
    required this.onToggle,
    super.key,
  });

  final StarterPackMemberView member;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final locked = member.alreadyFollowing;
    final active = selected || locked;
    return InkWell(
      key: ValueKey('starter_pack_member_${member.channelId}'),
      onTap: locked ? null : onToggle,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(LoomSpacing.md),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFEAF8F5) : LoomColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? const Color(0xFF42A782) : LoomColors.line,
            width: active ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            _Avatar(
              displayName: member.displayName,
              avatarRef: member.avatarRef,
            ),
            const SizedBox(width: LoomSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          member.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      if (member.isSourceCreator) const _Pill(label: 'Invite'),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${member.handle}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: LoomColors.mutedInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    locked ? 'Already following' : member.reason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: locked
                          ? const Color(0xFF167A55)
                          : LoomColors.mutedInk,
                      height: 1.22,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: LoomSpacing.sm),
            Icon(
              active ? Icons.check_circle_rounded : Icons.add_circle_outline,
              color: active ? const Color(0xFF167A55) : LoomColors.mutedInk,
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.displayName, required this.avatarRef});

  final String displayName;
  final String avatarRef;

  @override
  Widget build(BuildContext context) {
    final initials = displayName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.characters.first.toUpperCase())
        .join();
    final seed = avatarRef.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    final palette = [
      const [Color(0xFF0F6B55), Color(0xFFF2C94C)],
      const [Color(0xFF1D4E89), Color(0xFFFFB703)],
      const [Color(0xFF8F2D56), Color(0xFFFFD166)],
      const [Color(0xFF2D6A4F), Color(0xFF90BE6D)],
    ][seed % 4];

    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: palette),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: LoomColors.ink,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
