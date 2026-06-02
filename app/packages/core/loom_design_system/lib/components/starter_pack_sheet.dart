import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import 'starter_pack_member_row.dart';

class CreatorCaptureLandingPanel extends StatelessWidget {
  const CreatorCaptureLandingPanel({
    required this.displayName,
    required this.handle,
    required this.tagline,
    required this.avatarRef,
    required this.alreadyFollowing,
    super.key,
  });

  final String displayName;
  final String handle;
  final String tagline;
  final String avatarRef;
  final bool alreadyFollowing;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('p12_capture_landing_panel'),
      width: double.infinity,
      padding: const EdgeInsets.all(LoomSpacing.lg),
      decoration: BoxDecoration(
        color: LoomColors.ink,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CreatorAvatar(displayName: displayName, avatarRef: avatarRef),
              const SizedBox(width: LoomSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    Text(
                      '@$handle',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: LoomSpacing.md),
          Text(
            tagline,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (alreadyFollowing) ...[
            const SizedBox(height: LoomSpacing.md),
            const _StatusPill(
              icon: Icons.check_circle_rounded,
              label: 'You already follow this creator',
            ),
          ],
        ],
      ),
    );
  }
}

class StarterPackSheet extends StatelessWidget {
  const StarterPackSheet({
    required this.members,
    required this.selectedIds,
    required this.onToggle,
    required this.onConfirm,
    required this.busy,
    super.key,
  });

  final List<StarterPackMemberView> members;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;
  final VoidCallback onConfirm;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final selectedCount = members
        .where(
          (member) =>
              selectedIds.contains(member.channelId) || member.alreadyFollowing,
        )
        .length;
    return Container(
      key: const ValueKey('p12_starter_pack_sheet'),
      width: double.infinity,
      padding: const EdgeInsets.all(LoomSpacing.lg),
      decoration: BoxDecoration(
        color: LoomColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LoomColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.group_add_rounded, color: LoomColors.ink),
              const SizedBox(width: LoomSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Starter pack',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '$selectedCount selected · seeded by creators you already chose',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: LoomColors.mutedInk,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: LoomSpacing.md),
          for (final member in members) ...[
            StarterPackMemberRow(
              member: member,
              selected: selectedIds.contains(member.channelId),
              onToggle: () => onToggle(member.channelId),
            ),
            const SizedBox(height: LoomSpacing.sm),
          ],
          const SizedBox(height: LoomSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('p12_follow_selected_button'),
              onPressed: busy || selectedIds.isEmpty ? null : onConfirm,
              icon: busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(busy ? 'Following selected' : 'Follow selected'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatorAvatar extends StatelessWidget {
  const _CreatorAvatar({required this.displayName, required this.avatarRef});

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
    final accent = avatarRef.length.isEven
        ? const Color(0xFFF2C94C)
        : const Color(0xFF42A782);
    return Container(
      width: 72,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: const TextStyle(
          color: LoomColors.ink,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(32),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
