import 'evaluator/formula_evaluator.dart';
import 'models/workflow_archetypes.dart';

/// Effect operations implemented by the workflow engine.
const Set<String> supportedWorkflowEffectOperations = <String>{
  'set',
  'append',
  'appendUnique',
  'removeValue',
  'increment',
  'decrement',
  'branch',
  'createInstance',
  'removeFromTileGrid',
  'transitionRelated',
  'generateRecurringInstances',
};

/// Guard kinds implemented by the workflow engine.
///
/// These are the conceptual names used by `requiresCapabilities`. Most map
/// directly to one guard-object key; `relatedListMembership` is represented in
/// JSON by the `relatedInstanceField` + `relatedListField` pair.
const Set<String> supportedWorkflowGuardKinds = <String>{
  'allowedRoleIds',
  'actorInList',
  'instanceDataEquals',
  'formula',
  'relatedListMembership',
  'relatedAggregate',
  'requiresWorkflowsComplete',
  'cancellationDeadline',
  'locationOverlap',
  'actorEqualsField',
};

/// Base `instanceDataSchema` field types implemented by the engine and shell.
///
/// A trailing `?` is the grammar's nullable modifier rather than a separate
/// capability, so `field.url` covers both `url` and `url?` declarations.
const Set<String> supportedInstanceDataFieldTypes = <String>{
  'text',
  'textarea',
  'number',
  'int',
  'bool',
  'date',
  'time',
  'list',
  'map',
  'fanId',
  'fanId[]',
  'roleId',
  'roleId[]',
  'image',
  'url',
};

/// Whether this build implements a fully-qualified package capability.
///
/// Unknown namespaces and unknown names both return false so loaders and
/// validators can fail closed for packages authored against newer builds.
bool supportsCommunityCapability(String capability) {
  final separator = capability.indexOf('.');
  if (separator <= 0 || separator == capability.length - 1) return false;

  final namespace = capability.substring(0, separator);
  final name = capability.substring(separator + 1);
  return switch (namespace) {
    'archetype' => knownWorkflowArchetypeIds.contains(name),
    'effect' => supportedWorkflowEffectOperations.contains(name),
    'guard' => supportedWorkflowGuardKinds.contains(name),
    'formula' => formulaFunctionNames.contains(name),
    'field' => supportedInstanceDataFieldTypes.contains(
      name.endsWith('?') ? name.substring(0, name.length - 1) : name,
    ),
    _ => false,
  };
}
