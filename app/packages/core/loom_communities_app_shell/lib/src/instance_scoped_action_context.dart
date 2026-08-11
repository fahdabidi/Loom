part of '../loom_communities_app_shell.dart';

/// Resolves action prefill tokens for create actions.
/// - `{context.id}` and `{context.<field>}` are resolved from the host instance
///   when present (instance scope).
/// - `$actor` and `$timestamp` are resolved for both scopes.
Map<String, dynamic> resolveInstanceScopedPrefill(
  Map<String, dynamic>? prefill,
  WorkflowInstance instance, {
  String? actorId,
}) {
  if (prefill == null || prefill.isEmpty) return const {};
  return {
    for (final entry in prefill.entries)
      entry.key: _resolveInstanceScopedValue(
        entry.value,
        instance,
        actorId: actorId,
      ),
  };
}

Map<String, dynamic> resolveTabScopedPrefill(
  Map<String, dynamic>? prefill,
  String actorId,
) {
  if (prefill == null || prefill.isEmpty) return const {};
  return {
    for (final entry in prefill.entries)
      entry.key: _resolveInstanceScopedValue(
        entry.value,
        null,
        actorId: actorId,
      ),
  };
}

dynamic _resolveInstanceScopedValue(
  dynamic value,
  WorkflowInstance? instance, {
  String? actorId,
}) {
  if (value is! String) return value;
  if (value == '\$actor') return actorId ?? value;
  final withTimestamp = value.replaceAll(
    '\$timestamp',
    DateTime.now().toUtc().toIso8601String(),
  );
  if (instance == null) {
    return withTimestamp.replaceAll('\$actor', actorId ?? value);
  }
  if (withTimestamp == '{context.id}') return instance.instanceId;
  final match = RegExp(r'^\{context\.([^}]+)\}$').firstMatch(withTimestamp);
  if (match != null) return instance.instanceData[match.group(1)!];
  return withTimestamp.replaceAll('\$actor', actorId ?? value);
}
