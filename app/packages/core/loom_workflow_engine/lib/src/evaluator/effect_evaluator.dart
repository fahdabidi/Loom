import '../models/workflow_models.dart';

/// Applies a list of [WorkflowEffect]s to a copy of [instanceData] and returns
/// the new map. `$actor` in effect values is resolved to [personaId]. Does not
/// mutate the original map.
Map<String, dynamic> applyEffects(
  List<WorkflowEffect> effects,
  String personaId,
  Map<String, dynamic> instanceData, {
  Map<String, dynamic>? interpolationData,
}) {
  final result = Map<String, dynamic>.from(instanceData);

  for (final effect in effects) {
    // Skip presentation-only ops (e.g. removeFromTileGrid) that have no key
    if (effect.key == null) continue;
    final resolvedValue = resolveEffectValue(
      effect.value,
      personaId,
      interpolationData ?? result,
    );
    final resolvedKey = effect.key!.replaceAll('\$actor', personaId);
    _applyOne(result, effect.op, resolvedKey, resolvedValue);
  }

  return result;
}

/// Resolves `$actor` to the acting persona ID, passes other values through.
dynamic resolveEffectValue(
  dynamic value,
  String personaId,
  Map<String, dynamic> instanceData,
) {
  if (value == '\$actor') return personaId;
  if (value is String) {
    var resolved = value
        .replaceAll('\$actor', personaId)
        .replaceAll('\$timestamp', DateTime.now().toUtc().toIso8601String());
    for (final entry in instanceData.entries) {
      resolved = resolved.replaceAll('{${entry.key}}', '${entry.value}');
    }
    return resolved;
  }
  if (value is List) {
    return value
        .map((item) => resolveEffectValue(item, personaId, instanceData))
        .toList();
  }
  if (value is Map) {
    return value.map(
      (key, item) =>
          MapEntry(key, resolveEffectValue(item, personaId, instanceData)),
    );
  }
  return value;
}

/// Applies a single effect operation to the mutable [data] map.
void _applyOne(
  Map<String, dynamic> data,
  String op,
  String key,
  dynamic value,
) {
  switch (op) {
    case 'set':
      if (key.contains('.')) {
        _setNestedMapValue(data, key, value);
      } else {
        data[key] = value;
      }
      break;

    case 'appendUnique':
    case 'append':
      final existing = data[key];
      if (existing is List) {
        final list = List<dynamic>.from(existing);
        if (op == 'append' || !list.contains(value)) {
          list.add(value);
        }
        data[key] = list;
      } else {
        // First write: create a new list containing the value.
        data[key] = [value];
      }
      break;

    case 'removeValue':
      final existing = data[key];
      if (existing is List) {
        data[key] = List<dynamic>.from(existing)..remove(value);
      }
      // If not a list, no-op (safe).
      break;

    case 'increment':
      final current = data[key];
      if (current is num) {
        data[key] = current + 1;
      } else {
        // Treat absent or non-numeric as 0 → 1.
        data[key] = 1;
      }
      break;

    case 'decrement':
      final current = data[key];
      if (current is num) {
        final next = current - 1;
        data[key] = next < 0 ? 0 : next; // clamp at 0
      } else {
        // Treat absent or non-numeric as 0 → stays 0 (clamped).
        data[key] = 0;
      }
      break;

    default:
      // Unknown ops are silently ignored (presentation concerns like
      // removeFromTileGrid pass through without crashing the engine).
      break;
  }
}

void _setNestedMapValue(
  Map<String, dynamic> data,
  String dottedKey,
  dynamic value,
) {
  final parts = dottedKey.split('.');
  if (parts.length != 2 || parts.any((part) => part.isEmpty)) {
    data[dottedKey] = value;
    return;
  }
  final existing = data[parts.first];
  final next = existing is Map
      ? Map<String, dynamic>.from(existing)
      : <String, dynamic>{};
  next[parts.last] = value;
  data[parts.first] = next;
}
