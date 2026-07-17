part of '../loom_communities_app_shell.dart';

/// Generic, tab-agnostic projection for engine-declared bindings that don't
/// need calendar semantics: a scrollable list of [EngineNativeArchetypeCard]s,
/// one per resolved binding, in tile display context.
class EngineNativeListSurface extends StatefulWidget {
  const EngineNativeListSurface({
    super.key,
    required this.experience,
    required this.persona,
    required this.tabId,
    required this.accent,
    required this.modernTheme,
    this.engine,
  });

  final LoomExperienceDefinition experience;
  final LoomPersonaDefinition persona;
  final String tabId;
  final Color accent;
  final LoomCardTheme? modernTheme;
  final WorkflowEngineApi? engine;

  @override
  State<EngineNativeListSurface> createState() =>
      _EngineNativeListSurfaceState();
}

class _EngineNativeListSurfaceState extends State<EngineNativeListSurface> {
  Future<WorkflowEngineApi>? _engineFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant EngineNativeListSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.experience.extensionId != widget.experience.extensionId ||
        oldWidget.engine != widget.engine ||
        oldWidget.persona.personaId != widget.persona.personaId ||
        oldWidget.tabId != widget.tabId) {
      _load();
    }
  }

  void _load() {
    final extensionId = widget.experience.extensionId;
    setState(() {
      _engineFuture = widget.engine == null
          ? workflowEngineForExtensionId(extensionId)
          : Future<WorkflowEngineApi>.value(widget.engine);
    });
  }

  @override
  Widget build(BuildContext context) {
    final definitions = widget.experience.workflowDefinitions;
    if (definitions == null) return const SizedBox();
    return FutureBuilder<WorkflowEngineApi>(
      future: _engineFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Column(
            key: ValueKey('engine-native-list-error-${widget.tabId}'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Could not load ${widget.tabId}: ${snapshot.error}'),
              TextButton(
                key: ValueKey('engine-native-list-retry-${widget.tabId}'),
                onPressed: _load,
                child: const Text('Retry'),
              ),
            ],
          );
        }
        if (!snapshot.hasData) {
          return SizedBox(
            key: ValueKey('engine-native-list-loading-${widget.tabId}'),
          );
        }
        final engine = snapshot.data!;
        final personaId = resolveEnginePersonaId(widget.persona.personaId);
        return EngineNativeBindingDispatcher(
          engine: engine,
          definitions: definitions,
          tabId: widget.tabId,
          personaId: personaId,
          rolesForInstance: (instance, viewerPersonaId) =>
              instance.createdByPersonaId == viewerPersonaId
              ? const <String>['actor']
              : const <String>[],
          builder: (context, bindings, changed) {
            if (bindings.isEmpty) {
              return SizedBox(
                key: ValueKey('engine-native-list-empty-${widget.tabId}'),
              );
            }
            return Column(
              key: ValueKey('engine-native-list-root-${widget.tabId}'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final resolved in bindings)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: EngineNativeArchetypeCard(
                      contentKey: ValueKey(
                        'engine-native-list-item-${widget.tabId}-${resolved.instance.instanceId}-${resolved.definitionBindingIndex}',
                      ),
                      resolved: resolved,
                      engine: engine,
                      personaId: personaId,
                      accent: widget.accent,
                      onInstanceChanged: changed,
                      modernTheme: widget.modernTheme,
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
