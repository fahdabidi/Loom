import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../channel/channel_theme.dart';
import 'hype_meter.dart';
import 'vote_button.dart';

class HypeWarsModule extends StatelessWidget {
  const HypeWarsModule({
    required this.goalLabel,
    required this.totalCents,
    required this.goalCents,
    required this.walletBalanceCents,
    required this.theme,
    required this.onSendHype,
    required this.statusLabel,
    super.key,
  });

  final String goalLabel;
  final int totalCents;
  final int goalCents;
  final int walletBalanceCents;
  final LoomChannelTheme theme;
  final VoidCallback onSendHype;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          goalLabel,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: LoomColors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        HypeMeter(
          totalCents: totalCents,
          goalCents: goalCents,
          accentColor: theme.accent,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                'Simulated wallet: ${_money(walletBalanceCents)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: LoomColors.mutedInk),
              ),
            ),
            ExtensionVoteButton(
              label: 'Send hype',
              icon: Icons.bolt_rounded,
              onPressed: onSendHype,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          statusLabel,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: LoomColors.mutedInk),
        ),
      ],
    );
  }
}

String _money(int cents) {
  return '\$${(cents / 100).toStringAsFixed(2)}';
}
