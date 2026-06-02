import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_local_store/loom_local_store.dart'
    show
        ChannelThemeRecord,
        CreatorExperienceConfigRecord,
        DemoLocalStore,
        InstalledExtensionRefRecord,
        SurfaceModuleRecord;

class CreatorExperienceFake implements CreatorExperienceApi {
  const CreatorExperienceFake(
    this._store, {
    this.latency = const Duration(milliseconds: 90),
  });

  final DemoLocalStore _store;
  final Duration latency;

  @override
  Future<CreatorExperienceConfig> getExperienceConfig({
    required String channelId,
  }) async {
    await Future<void>.delayed(latency);
    return _mapConfig(await _store.creatorExperienceConfig(channelId));
  }

  @override
  Future<CreatorExperienceConfig> putExperienceConfig({
    required CreatorExperienceConfig config,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    return _mapConfig(
      await _store.putCreatorExperienceConfig(
        config: _toConfigRecord(config),
        idempotencyKey: idempotencyKey,
      ),
    );
  }
}

CreatorExperienceConfig _mapConfig(CreatorExperienceConfigRecord record) {
  return CreatorExperienceConfig(
    channelId: record.channelId,
    theme: _mapTheme(record.theme),
    bannerRef: record.bannerRef,
    surfaceModules: record.surfaceModules.map(_mapModule).toList(),
    aiPersona: record.aiPersona,
    adPosture: record.adPosture,
    installedExtensions: record.installedExtensions
        .map(_mapInstalledRef)
        .toList(),
    version: record.version,
    updatedAt: record.updatedAt,
  );
}

CreatorExperienceConfigRecord _toConfigRecord(CreatorExperienceConfig config) {
  return CreatorExperienceConfigRecord(
    channelId: config.channelId,
    theme: _toThemeRecord(config.theme),
    bannerRef: config.bannerRef,
    surfaceModules: config.surfaceModules.map(_toModuleRecord).toList(),
    aiPersona: config.aiPersona,
    adPosture: config.adPosture,
    installedExtensions: config.installedExtensions
        .map(_toInstalledRefRecord)
        .toList(),
    version: config.version,
    updatedAt: config.updatedAt,
  );
}

ChannelTheme _mapTheme(ChannelThemeRecord record) {
  return ChannelTheme(
    themeId: record.themeId,
    name: record.name,
    primaryHex: record.primaryHex,
    secondaryHex: record.secondaryHex,
    backgroundHex: record.backgroundHex,
    surfaceHex: record.surfaceHex,
    textHex: record.textHex,
    accentHex: record.accentHex,
  );
}

ChannelThemeRecord _toThemeRecord(ChannelTheme theme) {
  return ChannelThemeRecord(
    themeId: theme.themeId,
    name: theme.name,
    primaryHex: theme.primaryHex,
    secondaryHex: theme.secondaryHex,
    backgroundHex: theme.backgroundHex,
    surfaceHex: theme.surfaceHex,
    textHex: theme.textHex,
    accentHex: theme.accentHex,
  );
}

SurfaceModule _mapModule(SurfaceModuleRecord record) {
  return SurfaceModule(
    moduleId: record.moduleId,
    kind: record.kind,
    title: record.title,
    surface: record.surface,
    sortOrder: record.sortOrder,
    enabled: record.enabled,
    extensionId: record.extensionId,
    config: record.config,
  );
}

SurfaceModuleRecord _toModuleRecord(SurfaceModule module) {
  return SurfaceModuleRecord(
    moduleId: module.moduleId,
    kind: module.kind,
    title: module.title,
    surface: module.surface,
    sortOrder: module.sortOrder,
    enabled: module.enabled,
    extensionId: module.extensionId,
    config: module.config,
  );
}

InstalledExtensionRef _mapInstalledRef(InstalledExtensionRefRecord record) {
  return InstalledExtensionRef(
    installId: record.installId,
    extensionId: record.extensionId,
    name: record.name,
    version: record.version,
    surfaces: record.surfaces,
    state: record.state,
    moduleIds: record.moduleIds,
  );
}

InstalledExtensionRefRecord _toInstalledRefRecord(InstalledExtensionRef ref) {
  return InstalledExtensionRefRecord(
    installId: ref.installId,
    extensionId: ref.extensionId,
    name: ref.name,
    version: ref.version,
    surfaces: ref.surfaces,
    state: ref.state,
    moduleIds: ref.moduleIds,
  );
}
