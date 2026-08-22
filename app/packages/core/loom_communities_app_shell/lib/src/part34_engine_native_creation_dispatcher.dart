part of '../loom_communities_app_shell.dart';

/// Renders the creation UI for a given `cardSurfaceFamily`, the creation-mode
/// counterpart to [EngineNativeArchetypeCard]'s view-mode dispatch
/// (`part27_engine_native_binding_dispatcher.dart`). Same rule applies here:
/// this is the single place `cardSurfaceFamily` is ever switched on for
/// creation purposes — add a case here for any future bespoke creation UI,
/// do not special-case creation dispatch anywhere else.
class EngineNativeArchetypeCreationCard extends StatelessWidget {
  const EngineNativeArchetypeCreationCard({
    super.key,
    required this.cardSurfaceFamily,
    required this.workflowType,
    required this.machine,
    required this.engine,
    required this.fanId,
    required this.keyPrefix,
    this.onCreated,
    this.title,
    this.resolvedInitialValues = const {},
    this.audienceCandidates = const [],
  });

  final String? cardSurfaceFamily;
  final String workflowType;
  final LoomWorkflowStateMachine machine;
  final WorkflowEngineApi engine;
  final String fanId;
  final String keyPrefix;
  final Future<void> Function(String instanceId)? onCreated;
  final String? title;
  final Map<String, dynamic> resolvedInitialValues;
  final List<AudienceMultiSelectCandidate> audienceCandidates;

  @override
  Widget build(BuildContext context) {
    switch (cardSurfaceFamily) {
      case 'event-rsvp':
        // No bespoke creation UI exists for event-rsvp yet — it uses the
        // same generic surface as everything else today. This case exists
        // as the real extension point for when one is needed, mirroring
        // EngineNativeArchetypeCard's own event-rsvp view-mode case.
        return GenericWorkflowCreationCard(
          workflowType: workflowType,
          machine: machine,
          engine: engine,
          fanId: fanId,
          keyPrefix: keyPrefix,
          onCreated: onCreated,
          title: title,
          resolvedInitialValues: resolvedInitialValues,
          audienceCandidates: audienceCandidates,
        );
      default:
        return GenericWorkflowCreationCard(
          workflowType: workflowType,
          machine: machine,
          engine: engine,
          fanId: fanId,
          keyPrefix: keyPrefix,
          onCreated: onCreated,
          title: title,
          resolvedInitialValues: resolvedInitialValues,
          audienceCandidates: audienceCandidates,
        );
    }
  }
}
