import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

class StudioAdPolicySelection {
  const StudioAdPolicySelection({
    required this.allowedCategories,
    required this.blockedCategories,
  });

  final List<String> allowedCategories;
  final List<String> blockedCategories;
}

class StudioAdPolicyEditor extends StatefulWidget {
  const StudioAdPolicyEditor({
    required this.savedLabel,
    required this.onSavePolicy,
    this.initialAllowedCategories = const ['home_energy', 'sustainable_living'],
    this.initialBlockedCategories = const ['gambling', 'alcohol'],
    super.key,
  });

  final String savedLabel;
  final List<String> initialAllowedCategories;
  final List<String> initialBlockedCategories;
  final Future<void> Function(StudioAdPolicySelection selection) onSavePolicy;

  @override
  State<StudioAdPolicyEditor> createState() => _StudioAdPolicyEditorState();
}

class _StudioAdPolicyEditorState extends State<StudioAdPolicyEditor> {
  late Set<String> _allowedCategories;
  late Set<String> _blockedCategories;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _allowedCategories = widget.initialAllowedCategories.toSet();
    _blockedCategories = widget.initialBlockedCategories.toSet();
  }

  void _setDecision(String category, _PolicyDecision decision) {
    setState(() {
      switch (decision) {
        case _PolicyDecision.allow:
          _allowedCategories.add(category);
          _blockedCategories.remove(category);
          break;
        case _PolicyDecision.block:
          _blockedCategories.add(category);
          _allowedCategories.remove(category);
          break;
        case _PolicyDecision.none:
          _allowedCategories.remove(category);
          _blockedCategories.remove(category);
          break;
      }
    });
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSavePolicy(
        StudioAdPolicySelection(
          allowedCategories: _allowedCategories.toList(growable: false),
          blockedCategories: _blockedCategories.toList(growable: false),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LoomSpacing.md),
      decoration: BoxDecoration(
        color: LoomColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LoomColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Creator ad policy',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: LoomSpacing.xs),
          Text(
            'Choose what can run and what is blocked before saving.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: LoomColors.mutedInk),
          ),
          const SizedBox(height: LoomSpacing.md),
          for (final choice in _primaryChoices) ...[
            _PolicyChoiceRow(
              choice: choice,
              allowed: _allowedCategories.contains(choice.id),
              blocked: _blockedCategories.contains(choice.id),
              onDecision: (decision) => _setDecision(choice.id, decision),
            ),
            const SizedBox(height: LoomSpacing.sm),
          ],
          Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              visualDensity: VisualDensity.compact,
            ),
            child: ExpansionTile(
              key: const ValueKey('p2_ad_policy_more_choices'),
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: const Text(
                'More policy choices',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              children: [
                for (final choice in _expandedChoices) ...[
                  _PolicyChoiceRow(
                    choice: choice,
                    allowed: _allowedCategories.contains(choice.id),
                    blocked: _blockedCategories.contains(choice.id),
                    onDecision: (decision) => _setDecision(choice.id, decision),
                  ),
                  const SizedBox(height: LoomSpacing.sm),
                ],
              ],
            ),
          ),
          const SizedBox(height: LoomSpacing.sm),
          _SelectionSummary(
            allowedCategories: _allowedCategories,
            blockedCategories: _blockedCategories,
          ),
          const SizedBox(height: LoomSpacing.sm),
          Text(
            widget.savedLabel,
            key: const ValueKey('p2_ad_policy_status'),
            style: const TextStyle(color: LoomColors.mutedInk),
          ),
          const SizedBox(height: LoomSpacing.md),
          FilledButton.icon(
            key: const ValueKey('p2_save_ad_policy_button'),
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.verified_user_outlined),
            label: Text(_saving ? 'Saving policy' : 'Save policy'),
          ),
        ],
      ),
    );
  }
}

class _PolicyChoice {
  const _PolicyChoice({required this.id, required this.label});

  final String id;
  final String label;
}

enum _PolicyDecision { allow, block, none }

const _primaryChoices = [
  _PolicyChoice(id: 'home_energy', label: 'Home energy'),
  _PolicyChoice(id: 'sustainable_living', label: 'Sustainable living'),
  _PolicyChoice(id: 'gambling', label: 'Gambling'),
  _PolicyChoice(id: 'alcohol', label: 'Alcohol'),
];

const _expandedChoices = [
  _PolicyChoice(id: 'personal_finance', label: 'Personal finance'),
  _PolicyChoice(id: 'mobility', label: 'Mobility'),
  _PolicyChoice(id: 'crypto', label: 'Crypto'),
  _PolicyChoice(id: 'political', label: 'Political'),
  _PolicyChoice(id: 'medical_claims', label: 'Medical claims'),
];

class _PolicyChoiceRow extends StatelessWidget {
  const _PolicyChoiceRow({
    required this.choice,
    required this.allowed,
    required this.blocked,
    required this.onDecision,
  });

  final _PolicyChoice choice;
  final bool allowed;
  final bool blocked;
  final ValueChanged<_PolicyDecision> onDecision;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: LoomColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LoomColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              choice.label,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: LoomSpacing.sm),
          ChoiceChip(
            key: ValueKey('p2_ad_allow_${choice.id}'),
            label: const Text('Allow'),
            selected: allowed,
            onSelected: (_) => onDecision(
              allowed ? _PolicyDecision.none : _PolicyDecision.allow,
            ),
          ),
          const SizedBox(width: LoomSpacing.xs),
          ChoiceChip(
            key: ValueKey('p2_ad_block_${choice.id}'),
            label: const Text('Block'),
            selected: blocked,
            onSelected: (_) => onDecision(
              blocked ? _PolicyDecision.none : _PolicyDecision.block,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionSummary extends StatelessWidget {
  const _SelectionSummary({
    required this.allowedCategories,
    required this.blockedCategories,
  });

  final Set<String> allowedCategories;
  final Set<String> blockedCategories;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCDEBE4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.fact_check_outlined, color: LoomColors.moss),
          const SizedBox(width: LoomSpacing.sm),
          Expanded(
            child: Text(
              'Allow ${_labels(allowedCategories)}. Block ${_labels(blockedCategories)}.',
              style: const TextStyle(
                color: LoomColors.ink,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _labels(Set<String> ids) {
  if (ids.isEmpty) {
    return 'none selected';
  }
  return ids.map(_labelForCategory).join(', ');
}

String _labelForCategory(String id) {
  for (final choice in [..._primaryChoices, ..._expandedChoices]) {
    if (choice.id == id) {
      return choice.label.toLowerCase();
    }
  }
  return id.replaceAll('_', ' ');
}
