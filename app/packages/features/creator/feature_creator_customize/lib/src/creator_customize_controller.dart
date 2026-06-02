import 'package:flutter/foundation.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_design_system/loom_design_system.dart';

class CreatorCustomizeController extends ChangeNotifier {
  CreatorCustomizeController({
    required String initialCreatorId,
    required CreatorMetadataApi metadataApi,
    required CreatorExperienceApi experienceApi,
    required ExtensionRegistryApi registryApi,
    required StarterPackApi starterPackApi,
  }) : creatorId = initialCreatorId,
       _metadataApi = metadataApi,
       _experienceApi = experienceApi,
       _registryApi = registryApi,
       _starterPackApi = starterPackApi;

  final CreatorMetadataApi _metadataApi;
  final CreatorExperienceApi _experienceApi;
  final ExtensionRegistryApi _registryApi;
  final StarterPackApi _starterPackApi;

  String creatorId;
  ChannelHome? channelHome;
  CreatorExperienceConfig? savedConfig;
  CreatorExperienceConfig? draftConfig;
  StarterPack? starterPack;
  List<ExtensionManifest> catalog = const [];
  bool loading = true;
  bool busy = false;
  bool dirty = false;
  String? errorMessage;
  String? statusMessage;

  static const creatorChoices = [
    CreatorCustomizeChoice(
      channelId: 'creator_nova_clutch',
      label: 'Nova',
      description: 'Competitive arena',
    ),
    CreatorCustomizeChoice(
      channelId: 'creator_ember_hollow',
      label: 'Ember',
      description: 'Creative quests',
    ),
    CreatorCustomizeChoice(
      channelId: 'creator_iron_vael',
      label: 'Iron',
      description: 'Guild goals',
    ),
  ];

  static const themeOptions = [
    StudioThemeOption(
      themeId: 'nova-arena',
      name: 'Arena broadcast',
      primaryHex: '#16213E',
      secondaryHex: '#E94560',
      backgroundHex: '#F6F8FF',
      accentHex: '#22C55E',
    ),
    StudioThemeOption(
      themeId: 'ember-lore',
      name: 'Lore workshop',
      primaryHex: '#3F2E24',
      secondaryHex: '#D97706',
      backgroundHex: '#FAF7F2',
      accentHex: '#4F9F69',
    ),
    StudioThemeOption(
      themeId: 'iron-guild',
      name: 'Guild command',
      primaryHex: '#1F2937',
      secondaryHex: '#9CA3AF',
      backgroundHex: '#F4F5F7',
      accentHex: '#F59E0B',
    ),
  ];

  static const bannerOptions = [
    StudioBannerOption(
      bannerRef: 'seed://banners/nova-clutch',
      label: 'Arena header',
      tone: 'arena',
    ),
    StudioBannerOption(
      bannerRef: 'seed://banners/ember-hollow',
      label: 'Workshop header',
      tone: 'lore',
    ),
    StudioBannerOption(
      bannerRef: 'seed://banners/iron-vael',
      label: 'Guild hall header',
      tone: 'guild',
    ),
  ];

  Future<void> load() async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait<Object>([
        _metadataApi.getChannelHome(
          channelId: creatorId,
          passportId: 'passport_demo_fan',
        ),
        _experienceApi.getExperienceConfig(channelId: creatorId),
        _registryApi.listExtensions(certifiedOnly: true),
        _starterPackApi.getStarterPack(
          channelId: creatorId,
          passportId: 'passport_demo_fan',
        ),
      ]);
      channelHome = results[0] as ChannelHome;
      savedConfig = results[1] as CreatorExperienceConfig;
      draftConfig = _copyConfig(savedConfig!);
      catalog = results[2] as List<ExtensionManifest>;
      starterPack = results[3] as StarterPack;
      dirty = false;
      statusMessage = 'Loaded ${channelHome!.displayName}.';
    } catch (error) {
      errorMessage = '$error';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> selectCreator(String channelId) async {
    if (channelId == creatorId || busy) {
      return;
    }
    creatorId = channelId;
    await load();
  }

  void selectTheme(StudioThemeOption option) {
    final draft = draftConfig;
    if (draft == null) {
      return;
    }
    draftConfig = _copyConfig(
      draft,
      theme: ChannelTheme(
        themeId: option.themeId,
        name: option.name,
        primaryHex: option.primaryHex,
        secondaryHex: option.secondaryHex,
        backgroundHex: option.backgroundHex,
        surfaceHex: '#FFFFFF',
        textHex: '#111827',
        accentHex: option.accentHex,
      ),
    );
    _markDirty('Theme will update the fan channel preview.');
  }

  void selectBanner(StudioBannerOption option) {
    final draft = draftConfig;
    if (draft == null) {
      return;
    }
    draftConfig = _copyConfig(draft, bannerRef: option.bannerRef);
    _markDirty('Banner will update the fan channel header.');
  }

  Future<void> installExtension(ExtensionManifest manifest) async {
    if (busy) {
      return;
    }
    await _runBusy(() async {
      final install = await _registryApi.installExtension(
        channelId: creatorId,
        extensionId: manifest.extensionId,
        version: manifest.latestVersion,
        approvedPermissions: manifest.permissions,
        approvedSurfaces: manifest.surfaces.where(_safeSurface).toList(),
        config: _defaultConfigFor(manifest),
        idempotencyKey:
            'p19-install-$creatorId-${manifest.extensionId}-${manifest.latestVersion}',
      );
      _attachInstalledExtension(manifest, install);
      await save();
      statusMessage = '${manifest.name} installed with scoped permissions.';
    });
  }

  Future<void> retuneExtension(String extensionId) async {
    final manifest = catalog
        .where((candidate) => candidate.extensionId == extensionId)
        .firstOrNull;
    if (manifest == null || busy) {
      return;
    }
    await _runBusy(() async {
      final config = _retunedConfigFor(manifest);
      final install = await _registryApi.installExtension(
        channelId: creatorId,
        extensionId: manifest.extensionId,
        version: manifest.latestVersion,
        approvedPermissions: manifest.permissions,
        approvedSurfaces: manifest.surfaces.where(_safeSurface).toList(),
        config: config,
        idempotencyKey:
            'p19-retune-$creatorId-${manifest.extensionId}-${DateTime.now().microsecondsSinceEpoch}',
      );
      _attachInstalledExtension(manifest, install, overrideConfig: config);
      await save();
      statusMessage = '${manifest.name} configuration updated.';
    });
  }

  Future<void> suspendExtension(String extensionId) async {
    final manifest = catalog
        .where((candidate) => candidate.extensionId == extensionId)
        .firstOrNull;
    if (manifest == null || busy) {
      return;
    }
    await _runBusy(() async {
      await _registryApi.suspendExtension(
        channelId: creatorId,
        extensionId: extensionId,
        reason: 'Creator disabled from customize console',
        idempotencyKey:
            'p19-suspend-$creatorId-$extensionId-${DateTime.now().microsecondsSinceEpoch}',
      );
      final draft = draftConfig;
      if (draft != null) {
        draftConfig = _copyConfig(
          draft,
          surfaceModules: draft.surfaceModules
              .where((module) => module.extensionId != extensionId)
              .toList(growable: false),
          installedExtensions: draft.installedExtensions
              .where((install) => install.extensionId != extensionId)
              .toList(growable: false),
        );
        await save();
      }
      statusMessage = '${manifest.name} suspended and removed from preview.';
    });
  }

  void moveModule(String moduleId, int delta) {
    final draft = draftConfig;
    if (draft == null) {
      return;
    }
    final modules = [...draft.surfaceModules]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final index = modules.indexWhere((module) => module.moduleId == moduleId);
    final target = index + delta;
    if (index < 0 || target < 0 || target >= modules.length) {
      return;
    }
    final current = modules.removeAt(index);
    modules.insert(target, current);
    draftConfig = _copyConfig(draft, surfaceModules: _renumber(modules));
    _markDirty('Module order changed in the preview.');
  }

  void toggleModule(String moduleId) {
    final draft = draftConfig;
    if (draft == null) {
      return;
    }
    draftConfig = _copyConfig(
      draft,
      surfaceModules: draft.surfaceModules
          .map(
            (module) => module.moduleId == moduleId
                ? _copyModule(module, enabled: !module.enabled)
                : module,
          )
          .toList(growable: false),
    );
    _markDirty('Module visibility changed in the preview.');
  }

  Future<void> save() async {
    final draft = draftConfig;
    if (draft == null || busy && !dirty) {
      return;
    }
    final persisted = await _experienceApi.putExperienceConfig(
      config: _copyConfig(
        draft,
        version: draft.version + 1,
        updatedAt: DateTime.now().toUtc(),
      ),
      idempotencyKey:
          'p19-save-$creatorId-${DateTime.now().microsecondsSinceEpoch}',
    );
    savedConfig = persisted;
    draftConfig = _copyConfig(persisted);
    dirty = false;
    statusMessage = 'Saved. Fan channel now reads this config.';
    notifyListeners();
  }

  Future<void> assembleGamingStarterPack() async {
    if (busy) {
      return;
    }
    await _runBusy(() async {
      starterPack = await _starterPackApi.putStarterPack(
        channelId: creatorId,
        passportId: 'passport_demo_fan',
        memberChannelIds: const [
          'creator_nova_clutch',
          'creator_ember_hollow',
          'creator_frame_by_frame',
          'creator_drift_and_chill',
          'creator_iron_vael',
        ],
        defaultSelectedChannelIds: const [
          'creator_nova_clutch',
          'creator_ember_hollow',
          'creator_frame_by_frame',
          'creator_drift_and_chill',
          'creator_iron_vael',
        ],
        idempotencyKey: 'p19-gaming-starter-pack-$creatorId',
      );
      statusMessage = 'Gaming starter pack assembled with five creators.';
    });
  }

  StudioExtensionCatalogItem catalogItem(ExtensionManifest manifest) {
    final installed =
        draftConfig?.installedExtensions.any(
          (install) => install.extensionId == manifest.extensionId,
        ) ??
        false;
    return StudioExtensionCatalogItem(
      extensionId: manifest.extensionId,
      name: manifest.name,
      category: manifest.category,
      riskTier: manifest.riskTier,
      description: manifest.description,
      surfaces: manifest.surfaces,
      permissions: manifest.permissions,
      installed: installed,
    );
  }

  Map<String, String> configForExtension(String extensionId) {
    return draftConfig?.surfaceModules
            .where((module) => module.extensionId == extensionId)
            .firstOrNull
            ?.config ??
        const {};
  }

  void _attachInstalledExtension(
    ExtensionManifest manifest,
    ExtensionInstall install, {
    Map<String, String>? overrideConfig,
  }) {
    final draft = draftConfig;
    if (draft == null) {
      return;
    }
    final moduleId = _moduleIdFor(manifest.extensionId);
    final existingModules = draft.surfaceModules
        .where((module) => module.extensionId != manifest.extensionId)
        .toList(growable: false);
    final nextModule = SurfaceModule(
      moduleId: moduleId,
      kind: 'extension',
      title: manifest.name,
      surface: 'feed_module',
      sortOrder: existingModules.length,
      enabled: true,
      extensionId: manifest.extensionId,
      config: overrideConfig ?? install.config,
    );
    final ref = InstalledExtensionRef(
      installId: install.installId,
      extensionId: manifest.extensionId,
      name: manifest.name,
      version: install.version,
      surfaces: install.approvedSurfaces,
      state: install.state,
      moduleIds: [moduleId],
    );
    draftConfig = _copyConfig(
      draft,
      surfaceModules: _renumber([...existingModules, nextModule]),
      installedExtensions: [
        for (final current in draft.installedExtensions)
          if (current.extensionId != manifest.extensionId) current,
        ref,
      ],
    );
    dirty = true;
    notifyListeners();
  }

  void _markDirty(String message) {
    dirty = true;
    statusMessage = message;
    notifyListeners();
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      errorMessage = '$error';
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}

class CreatorCustomizeChoice {
  const CreatorCustomizeChoice({
    required this.channelId,
    required this.label,
    required this.description,
  });

  final String channelId;
  final String label;
  final String description;
}

bool _safeSurface(String surface) {
  return surface == 'feed_module' || surface == 'channel_header';
}

String _moduleIdFor(String extensionId) {
  return extensionId.replaceFirst('ext_', '');
}

Map<String, String> _defaultConfigFor(ExtensionManifest manifest) {
  switch (manifest.extensionId) {
    case 'ext_clip_arena':
      return const {
        'cta': 'Vote the creator clip',
        'seedHeadline': 'Community highlight',
        'season': 'Studio season',
      };
    case 'ext_pickem':
      return const {
        'question': 'What should the creator attempt next?',
        'options': 'Boss run|Build challenge|Community match',
      };
    case 'ext_hypewars':
      return const {'goal': 'Community unlock', 'goalCents': '18000'};
    case 'ext_quest_log':
      return const {
        'quest': 'Complete the weekly creator quest',
        'description': 'Fans complete one challenge and earn a badge.',
        'badge': 'Quest crew',
      };
    case 'ext_build_showcase':
      return const {'prompt': 'Submit a fan build for the next stream'};
    case 'ext_guild_quest':
      return const {
        'goal': 'Complete the guild milestone',
        'target': '30',
        'milestones': 'Open lobby|Bonus creator stream',
      };
  }
  return const {'cta': 'Join the creator activity'};
}

Map<String, String> _retunedConfigFor(ExtensionManifest manifest) {
  final base = _defaultConfigFor(manifest);
  return {
    ...base,
    if (manifest.extensionId == 'ext_hypewars') 'goalCents': '24000',
    if (manifest.extensionId == 'ext_guild_quest') 'target': '45',
    'studioPreset': 'retuned',
  };
}

List<SurfaceModule> _renumber(List<SurfaceModule> modules) {
  return [
    for (var index = 0; index < modules.length; index++)
      _copyModule(modules[index], sortOrder: index),
  ];
}

SurfaceModule _copyModule(
  SurfaceModule module, {
  int? sortOrder,
  bool? enabled,
  Map<String, String>? config,
}) {
  return SurfaceModule(
    moduleId: module.moduleId,
    kind: module.kind,
    title: module.title,
    surface: module.surface,
    sortOrder: sortOrder ?? module.sortOrder,
    enabled: enabled ?? module.enabled,
    extensionId: module.extensionId,
    config: config ?? module.config,
  );
}

CreatorExperienceConfig _copyConfig(
  CreatorExperienceConfig config, {
  ChannelTheme? theme,
  String? bannerRef,
  List<SurfaceModule>? surfaceModules,
  String? aiPersona,
  String? adPosture,
  List<InstalledExtensionRef>? installedExtensions,
  int? version,
  DateTime? updatedAt,
}) {
  return CreatorExperienceConfig(
    channelId: config.channelId,
    theme: theme ?? config.theme,
    bannerRef: bannerRef ?? config.bannerRef,
    surfaceModules: surfaceModules ?? config.surfaceModules,
    aiPersona: aiPersona ?? config.aiPersona,
    adPosture: adPosture ?? config.adPosture,
    installedExtensions: installedExtensions ?? config.installedExtensions,
    version: version ?? config.version,
    updatedAt: updatedAt ?? config.updatedAt,
  );
}
