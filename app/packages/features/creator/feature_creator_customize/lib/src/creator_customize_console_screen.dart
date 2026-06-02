import 'package:flutter/material.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_design_system/loom_design_system.dart';

import 'creator_customize_controller.dart';

class CreatorCustomizeConsoleScreen extends StatefulWidget {
  const CreatorCustomizeConsoleScreen({
    required this.creatorId,
    required this.onBack,
    super.key,
  });

  final String creatorId;
  final VoidCallback onBack;

  @override
  State<CreatorCustomizeConsoleScreen> createState() =>
      _CreatorCustomizeConsoleScreenState();
}

class _CreatorCustomizeConsoleScreenState
    extends State<CreatorCustomizeConsoleScreen> {
  late final CreatorCustomizeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CreatorCustomizeController(
      initialCreatorId: widget.creatorId,
      metadataApi: resolveCreatorMetadataApi(),
      experienceApi: resolveCreatorExperienceApi(),
      registryApi: resolveExtensionRegistryApi(),
      starterPackApi: resolveStarterPackApi(),
    )..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.loading) {
          return const Center(
            key: ValueKey('p19_customize_loading'),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: LoadingSkeleton(
                rows: 4,
                title: 'Loading customization console',
              ),
            ),
          );
        }
        if (_controller.errorMessage != null) {
          return _CustomizeError(
            message: _controller.errorMessage!,
            onBack: widget.onBack,
            onRetry: _controller.load,
          );
        }
        final home = _controller.channelHome;
        final config = _controller.draftConfig;
        if (home == null || config == null) {
          return _CustomizeError(
            message: 'Creator customization state is unavailable.',
            onBack: widget.onBack,
            onRetry: _controller.load,
          );
        }
        return StudioCustomizeConsole(
          title: 'Customize fan experience',
          subtitle: '${home.displayName} · @${home.handle}',
          busy: _controller.busy,
          dirty: _controller.dirty,
          status: _controller.statusMessage,
          onBack: widget.onBack,
          onSave: _controller.save,
          editor: _Editor(controller: _controller, config: config),
          preview: _Preview(home: home, config: config),
        );
      },
    );
  }
}

class _Editor extends StatelessWidget {
  const _Editor({required this.controller, required this.config});

  final CreatorCustomizeController controller;
  final CreatorExperienceConfig config;

  @override
  Widget build(BuildContext context) {
    final installedIds = config.installedExtensions
        .map((install) => install.extensionId)
        .toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CreatorSelector(controller: controller),
        const SizedBox(height: LoomSpacing.md),
        StudioThemePicker(
          options: CreatorCustomizeController.themeOptions,
          selectedThemeId: config.theme.themeId,
          onSelect: controller.selectTheme,
        ),
        const SizedBox(height: LoomSpacing.md),
        StudioBannerPicker(
          options: CreatorCustomizeController.bannerOptions,
          selectedBannerRef: config.bannerRef,
          onSelect: controller.selectBanner,
        ),
        const SizedBox(height: LoomSpacing.md),
        StudioModuleArranger(
          modules: config.surfaceModules
              .map(
                (module) => StudioModuleItem(
                  moduleId: module.moduleId,
                  title: module.title,
                  kind: module.kind,
                  enabled: module.enabled,
                  extensionName: module.extensionId,
                ),
              )
              .toList(growable: false),
          onMoveUp: (moduleId) => controller.moveModule(moduleId, -1),
          onMoveDown: (moduleId) => controller.moveModule(moduleId, 1),
          onToggleEnabled: controller.toggleModule,
        ),
        const SizedBox(height: LoomSpacing.md),
        StudioExtensionBrowser(
          items: controller.catalog
              .map(controller.catalogItem)
              .toList(growable: false),
          onInstall: (item) => _confirmInstall(context, controller, item),
          onSuspend: (item) => controller.suspendExtension(item.extensionId),
        ),
        const SizedBox(height: LoomSpacing.md),
        for (final install in config.installedExtensions) ...[
          StudioExtensionConfigForm(
            title: '${install.name} configuration',
            entries: controller.configForExtension(install.extensionId),
          ),
          const SizedBox(height: LoomSpacing.sm),
          FilledButton.tonalIcon(
            key: ValueKey('p19_reconfigure_${install.extensionId}_button'),
            onPressed: installedIds.contains(install.extensionId)
                ? () => controller.retuneExtension(install.extensionId)
                : null,
            icon: const Icon(Icons.tune_rounded),
            label: Text('Retune ${install.name}'),
          ),
          const SizedBox(height: LoomSpacing.md),
        ],
        _StarterPackAssembler(controller: controller),
      ],
    );
  }

  void _confirmInstall(
    BuildContext context,
    CreatorCustomizeController controller,
    StudioExtensionCatalogItem item,
  ) {
    final manifest = controller.catalog
        .where((candidate) => candidate.extensionId == item.extensionId)
        .firstOrNull;
    if (manifest == null) {
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => StudioExtensionInstallSheet(
        name: manifest.name,
        riskTier: manifest.riskTier,
        permissions: manifest.permissions,
        surfaces: manifest.surfaces.where(_safeSurface).toList(),
        configPreview: controller.configForExtension(manifest.extensionId),
        onCancel: () => Navigator.of(sheetContext).pop(),
        onApprove: () {
          Navigator.of(sheetContext).pop();
          controller.installExtension(manifest);
        },
      ),
    );
  }
}

class _CreatorSelector extends StatelessWidget {
  const _CreatorSelector({required this.controller});

  final CreatorCustomizeController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('p19_creator_selector'),
      padding: const EdgeInsets.all(LoomSpacing.md),
      decoration: BoxDecoration(
        color: LoomColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LoomColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Creator',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: LoomSpacing.sm),
          Wrap(
            spacing: LoomSpacing.sm,
            runSpacing: LoomSpacing.sm,
            children: [
              for (final choice in CreatorCustomizeController.creatorChoices)
                ChoiceChip(
                  key: ValueKey('p19_creator_${choice.channelId}'),
                  selected: controller.creatorId == choice.channelId,
                  label: Text(choice.label),
                  onSelected: (_) => controller.selectCreator(choice.channelId),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StarterPackAssembler extends StatelessWidget {
  const _StarterPackAssembler({required this.controller});

  final CreatorCustomizeController controller;

  @override
  Widget build(BuildContext context) {
    final pack = controller.starterPack;
    return Container(
      key: const ValueKey('p19_starter_pack_assembler'),
      padding: const EdgeInsets.all(LoomSpacing.md),
      decoration: BoxDecoration(
        color: LoomColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LoomColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.group_add_rounded),
              const SizedBox(width: LoomSpacing.sm),
              Expanded(
                child: Text(
                  'Gaming starter pack',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: LoomSpacing.sm),
          Text(
            pack == null
                ? 'Assemble the five-creator gaming pack.'
                : '${pack.members.length} creators · ${pack.starterPackToken}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: LoomColors.mutedInk),
          ),
          const SizedBox(height: LoomSpacing.md),
          FilledButton.icon(
            key: const ValueKey('p19_assemble_starter_pack_button'),
            onPressed: controller.busy
                ? null
                : controller.assembleGamingStarterPack,
            icon: const Icon(Icons.playlist_add_check_rounded),
            label: const Text('Assemble pack'),
          ),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.home, required this.config});

  final ChannelHome home;
  final CreatorExperienceConfig config;

  @override
  Widget build(BuildContext context) {
    return StudioPreviewPanel(
      creatorName: home.displayName,
      handle: home.handle,
      themeName: config.theme.name,
      bannerRef: config.bannerRef,
      aiPersona: config.aiPersona,
      adPosture: config.adPosture,
      primaryHex: config.theme.primaryHex,
      accentHex: config.theme.accentHex,
      modules: config.surfaceModules
          .map(
            (module) => StudioPreviewModule(
              moduleId: module.moduleId,
              title: module.title,
              kind: module.kind,
              enabled: module.enabled,
              extensionName: module.extensionId,
            ),
          )
          .toList(growable: false),
    );
  }
}

class _CustomizeError extends StatelessWidget {
  const _CustomizeError({
    required this.message,
    required this.onBack,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        IconButton(
          onPressed: onBack,
          alignment: Alignment.centerLeft,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        LoomErrorState(
          title: 'Customization unavailable',
          body: message,
          onRetry: onRetry,
        ),
      ],
    );
  }
}

bool _safeSurface(String surface) {
  return surface == 'feed_module' || surface == 'channel_header';
}
