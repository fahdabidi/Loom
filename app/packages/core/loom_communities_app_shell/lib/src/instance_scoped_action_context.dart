part of '../loom_communities_app_shell.dart';

/// Resolves instance-scoped action prefill tokens against the host card.
///
/// The action grammar deliberately limits this resolver to the host instance:
/// `{context.id}` is its persisted id and `{context.<field>}` reads its
/// instance data. Values without a context token are passed through unchanged.
Map<String, dynamic> resolveInstanceScopedPrefill(
  Map<String, dynamic>? prefill,
  WorkflowInstance instance,
) {
  if (prefill == null || prefill.isEmpty) return const {};
  return {
    for (final entry in prefill.entries)
      entry.key: _resolveInstanceScopedValue(entry.value, instance),
  };
}

dynamic _resolveInstanceScopedValue(dynamic value, WorkflowInstance instance) {
  if (value is! String) return value;
  if (value == '{context.id}') return instance.instanceId;
  final match = RegExp(r'^\{context\.([^}]+)\}$').firstMatch(value);
  return match == null ? value : instance.instanceData[match.group(1)!];
}
