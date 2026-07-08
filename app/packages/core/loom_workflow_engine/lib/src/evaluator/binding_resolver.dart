import '../models/workflow_models.dart';

/// Returns all [RenderBinding]s that match the given [currentState] and at
/// least one of the provided [personaRoles].
///
/// A persona may hold multiple roles on the same instance (§2a). This function
/// returns every matching binding — all of them — so the rendering layer can
/// render each one independently. `role: "any"` always matches regardless of
/// persona roles.
List<RenderBinding> resolveBindings(
  LoomWorkflowStateMachine machine,
  String currentState,
  Iterable<String> personaRoles,
    {
  Map<String, dynamic> instanceData = const {},
  String? personaId,
}) {
  return machine.renderBindings.where((binding) {
    // Must cover the current state.
    if (!binding.states.contains(currentState)) return false;

    // "any" matches every role.
    if (binding.role == 'any') return true;

    if (binding.role == 'receiver' &&
        binding.audienceMemberField != null &&
        _usesDynamicAudience(instanceData)) {
      return _isDynamicAudienceMember(
        instanceData: instanceData,
        audienceMemberField: binding.audienceMemberField!,
        personaId: personaId,
      );
    }

    // At least one of the persona's roles must match.
    return personaRoles.any((r) => r == binding.role);
  }).toList();
}

bool _usesDynamicAudience(Map<String, dynamic> instanceData) {
  final scope = instanceData['audienceScope'];
  return scope == 'selected' || scope == 'individual';
}

bool _isDynamicAudienceMember({
  required Map<String, dynamic> instanceData,
  required String audienceMemberField,
  required String? personaId,
}) {
  if (personaId == null || personaId.isEmpty) return false;
  final invited = instanceData[audienceMemberField];
  if (invited is Iterable) return invited.contains(personaId);
  return false;
}
