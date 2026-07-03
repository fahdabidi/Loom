part of '../loom_communities_app_shell.dart';

class _ActionSurfaceDetail {
  const _ActionSurfaceDetail({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _ActionSurfaceDetailStack extends StatelessWidget {
  const _ActionSurfaceDetailStack({
    required this.accent,
    this.modernTheme,
    required this.rows,
  });

  final Color accent;
  final LoomCardTheme? modernTheme;
  final List<_ActionSurfaceDetail> rows;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final surface = modernTheme?.resolvedFill ??
        Color.alphaBlend(accent.withValues(alpha: 0.86), Colors.black);
    final foreground = modernTheme?.resolvedHeading ?? _foregroundFor(surface);
    final bodyColor = modernTheme?.resolvedBody ?? foreground.withValues(alpha: 0.90);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(10),
        border: modernTheme != null
            ? Border.all(color: modernTheme!.resolvedBorder)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            for (var index = 0; index < rows.length; index++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: foreground.withValues(alpha: 0.12),
                    child: Icon(rows[index].icon, size: 20, color: foreground),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rows[index].title,
                          style: textTheme.titleMedium?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rows[index].body,
                          style: textTheme.bodyMedium?.copyWith(
                            color: bodyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (index != rows.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Divider(color: foreground.withValues(alpha: 0.18)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WorkflowResultPanel extends StatelessWidget {
  const _WorkflowResultPanel({
    super.key,
    required this.title,
    required this.body,
    required this.icon,
    required this.accent,
    this.modernTheme,
    this.changeResponseLabel,
    this.onChangeResponse,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color accent;
  final LoomCardTheme? modernTheme;

  /// When both are set, a text button appears under the result letting the
  /// actor change an already-submitted multi-choice response (e.g. Going ->
  /// Maybe) instead of leaving the result panel permanently static.
  final String? changeResponseLabel;
  final VoidCallback? onChangeResponse;

  @override
  Widget build(BuildContext context) {
    final surface = modernTheme?.resolvedFill ??
        Color.alphaBlend(accent.withValues(alpha: 0.86), Colors.black);
    final foreground = modernTheme?.resolvedHeading ?? _foregroundFor(surface);
    final bodyColor = modernTheme?.resolvedBody ?? foreground.withValues(alpha: 0.90);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(8),
        border: modernTheme != null
            ? Border.all(color: modernTheme!.resolvedBorder)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: foreground),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: bodyColor,
                    ),
                  ),
                  if (onChangeResponse != null && changeResponseLabel != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        key: const ValueKey('workflow-change-response'),
                        style: TextButton.styleFrom(
                          foregroundColor: foreground,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                        ),
                        onPressed: onChangeResponse,
                        child: Text(changeResponseLabel!),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonaStatusStrip extends StatelessWidget {
  const _PersonaStatusStrip({
    required this.persona,
    required this.personaCount,
    required this.foreground,
  });

  final LoomPersonaDefinition persona;
  final int personaCount;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('active-persona-card'),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: foreground.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Icon(Icons.people_outline, color: foreground),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    persona.label,
                    key: ValueKey('active-persona-${persona.personaId}'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${persona.roleLabel} - ${persona.description}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: foreground.withValues(alpha: 0.86),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            DecoratedBox(
              key: const ValueKey('active-persona-count'),
              decoration: BoxDecoration(
                color: foreground.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Text(
                  '$personaCount roles',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExtensionInfoTile extends StatelessWidget {
  const _ExtensionInfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}

class LocalPackageLoaderDialog extends StatefulWidget {
  const LocalPackageLoaderDialog({required this.onInstall});

  final String? Function({
    required String extensionPackagePath,
    required String initializationPackagePath,
  })
  onInstall;

  @override
  State<LocalPackageLoaderDialog> createState() =>
      _LocalPackageLoaderDialogState();
}

class _LocalPackageLoaderDialogState extends State<LocalPackageLoaderDialog> {
  late final TextEditingController _extensionPathController;
  late final TextEditingController _initializationPathController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _extensionPathController = TextEditingController(
      text:
          '/data/user/0/com.example.loom_communities_demo/files/book-club.loom-extension.zip',
    );
    _initializationPathController = TextEditingController(
      text:
          '/data/user/0/com.example.loom_communities_demo/files/book-club.loom-init.zip',
    );
  }

  @override
  void dispose() {
    _extensionPathController.dispose();
    _initializationPathController.dispose();
    super.dispose();
  }

  void _submit() {
    final error = widget.onInstall(
      extensionPackagePath: _extensionPathController.text,
      initializationPackagePath: _initializationPathController.text,
    );
    if (error != null) {
      setState(() {
        _errorText = error;
      });
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add local community'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Point to the extension package and initialization package in the emulator file system.',
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('extension-package-path-field'),
              controller: _extensionPathController,
              decoration: const InputDecoration(
                labelText: 'Extension package',
                helperText: '.loom-extension.zip',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('initialization-package-path-field'),
              controller: _initializationPathController,
              decoration: const InputDecoration(
                labelText: 'Initialization package',
                helperText: '.loom-init.zip',
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                key: const ValueKey('local-loader-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          key: const ValueKey('load-local-community-button'),
          onPressed: _submit,
          icon: const Icon(Icons.upload_file),
          label: const Text('Validate and install'),
        ),
      ],
    );
  }
}

class EmptyCommunityState extends StatelessWidget {
  const EmptyCommunityState({required this.onAddCommunity});

  final VoidCallback onAddCommunity;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'No communities installed',
          style: textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Use Add Community to load a local extension package and initialization package.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          key: const ValueKey('empty-add-community-button'),
          onPressed: onAddCommunity,
          icon: const Icon(Icons.add),
          label: const Text('Add Community'),
        ),
      ],
    );
  }
}

