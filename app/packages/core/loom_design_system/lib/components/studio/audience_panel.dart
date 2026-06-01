import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

class AudiencePanel extends StatelessWidget {
  const AudiencePanel({
    required this.approvedFanCount,
    required this.permissionStatus,
    required this.topCategories,
    required this.permissionedFields,
    required this.permissionedValues,
    this.onCreateRequest,
    this.onQueryData,
    super.key,
  });

  final int approvedFanCount;
  final String permissionStatus;
  final List<String> topCategories;
  final List<String> permissionedFields;
  final Map<String, List<String>> permissionedValues;
  final VoidCallback? onCreateRequest;
  final VoidCallback? onQueryData;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(LoomSpacing.lg),
          decoration: BoxDecoration(
            color: LoomColors.ink,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Permissioned audience',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: LoomSpacing.sm),
              Text(
                '$approvedFanCount approved fan${approvedFanCount == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: LoomSpacing.xs),
              Text(
                permissionStatus,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: LoomSpacing.md),
        Wrap(
          spacing: LoomSpacing.xs,
          runSpacing: LoomSpacing.xs,
          children: [
            if (topCategories.isEmpty)
              const Chip(label: Text('No approved categories yet'))
            else
              for (final category in topCategories)
                Chip(
                  label: Text(category),
                  side: BorderSide.none,
                  backgroundColor: LoomColors.surfaceAlt,
                ),
          ],
        ),
        const SizedBox(height: LoomSpacing.md),
        Wrap(
          spacing: LoomSpacing.sm,
          runSpacing: LoomSpacing.sm,
          children: [
            if (onCreateRequest != null)
              FilledButton.icon(
                key: const ValueKey('p7_create_grant_request_button'),
                onPressed: onCreateRequest,
                icon: const Icon(Icons.send_rounded),
                label: const Text('Request grant'),
              ),
            if (onQueryData != null)
              FilledButton.tonalIcon(
                key: const ValueKey('p7_query_audience_button'),
                onPressed: onQueryData,
                icon: const Icon(Icons.query_stats_rounded),
                label: const Text('Query approved data'),
              ),
          ],
        ),
        const SizedBox(height: LoomSpacing.md),
        Container(
          key: const ValueKey('p7_permissioned_fields'),
          width: double.infinity,
          padding: const EdgeInsets.all(LoomSpacing.md),
          decoration: BoxDecoration(
            color: LoomColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: LoomColors.line),
          ),
          child: permissionedFields.isEmpty
              ? const Text('No permissioned fields returned yet.')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Returned fields',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: LoomSpacing.sm),
                    for (final field in permissionedFields)
                      Text(
                        '${_fieldLabel(field)}: ${permissionedValues[field]?.join(', ') ?? 'Allowed'}',
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

String _fieldLabel(String field) {
  switch (field) {
    case 'interest_categories':
      return 'Interest categories';
    case 'interest_tokens':
      return 'Interest tokens';
    default:
      return field.replaceAll('_', ' ');
  }
}
