import 'evaluator/formula_evaluator.dart';
import 'models/workflow_archetypes.dart';

/// Effect operations implemented by the workflow engine.
const String workflowEffectSet = 'set';
const String workflowEffectAppend = 'append';
const String workflowEffectAppendUnique = 'appendUnique';
const String workflowEffectRemoveValue = 'removeValue';
const String workflowEffectIncrement = 'increment';
const String workflowEffectDecrement = 'decrement';
const String workflowEffectBranch = 'branch';
const String workflowEffectCreateInstance = 'createInstance';
const String workflowEffectRemoveFromTileGrid = 'removeFromTileGrid';
const String workflowEffectTransitionRelated = 'transitionRelated';
const String workflowEffectGenerateRecurringInstances =
    'generateRecurringInstances';

const Set<String> supportedWorkflowEffectOperations = <String>{
  workflowEffectSet,
  workflowEffectAppend,
  workflowEffectAppendUnique,
  workflowEffectRemoveValue,
  workflowEffectIncrement,
  workflowEffectDecrement,
  workflowEffectBranch,
  workflowEffectCreateInstance,
  workflowEffectRemoveFromTileGrid,
  workflowEffectTransitionRelated,
  workflowEffectGenerateRecurringInstances,
};

/// Guard kinds implemented by the workflow engine.
///
/// These are the conceptual names used by `requiresCapabilities`. Most map
/// directly to one guard-object key; `relatedListMembership` is represented in
/// JSON by the `relatedInstanceField` + `relatedListField` pair.
const String workflowGuardAllowedRoleIds = 'allowedRoleIds';
const String workflowGuardActorInList = 'actorInList';
const String workflowGuardInstanceDataEquals = 'instanceDataEquals';
const String workflowGuardFormula = 'formula';
const String workflowGuardRelatedListMembership = 'relatedListMembership';
const String workflowGuardRelatedAggregate = 'relatedAggregate';
const String workflowGuardRequiresWorkflowsComplete =
    'requiresWorkflowsComplete';
const String workflowGuardCancellationDeadline = 'cancellationDeadline';
const String workflowGuardLocationOverlap = 'locationOverlap';
const String workflowGuardActorEqualsField = 'actorEqualsField';

/// JSON keys which together encode [workflowGuardRelatedListMembership].
const String workflowGuardRelatedInstanceFieldKey = 'relatedInstanceField';
const String workflowGuardRelatedListFieldKey = 'relatedListField';

const Set<String> supportedWorkflowGuardKinds = <String>{
  workflowGuardAllowedRoleIds,
  workflowGuardActorInList,
  workflowGuardInstanceDataEquals,
  workflowGuardFormula,
  workflowGuardRelatedListMembership,
  workflowGuardRelatedAggregate,
  workflowGuardRequiresWorkflowsComplete,
  workflowGuardCancellationDeadline,
  workflowGuardLocationOverlap,
  workflowGuardActorEqualsField,
};

/// Formula functions implemented by the parser and evaluator.
///
/// [formulaFunctionNames] is also the evaluator's admission check, so this is
/// an alias rather than a second hand-copied vocabulary.
const Set<String> supportedWorkflowFormulaFunctions = formulaFunctionNames;

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
    'formula' => supportedWorkflowFormulaFunctions.contains(name),
    'field' => supportedInstanceDataFieldTypes.contains(
      name.endsWith('?') ? name.substring(0, name.length - 1) : name,
    ),
    _ => false,
  };
}
