class ExtensionManifest {
  const ExtensionManifest({
    required this.extensionId,
    required this.name,
    required this.category,
    required this.riskTier,
    required this.surfaces,
    required this.permissions,
    required this.exportBehavior,
    required this.certificationState,
    required this.latestVersion,
    required this.description,
  });

  final String extensionId;
  final String name;
  final String category;
  final String riskTier;
  final List<String> surfaces;
  final List<String> permissions;
  final String exportBehavior;
  final String certificationState;
  final String latestVersion;
  final String description;
}

class ExtensionVersion {
  const ExtensionVersion({
    required this.extensionId,
    required this.version,
    required this.state,
    required this.submittedAt,
    this.certifiedAt,
  });

  final String extensionId;
  final String version;
  final String state;
  final DateTime submittedAt;
  final DateTime? certifiedAt;
}

class ExtensionInstall {
  const ExtensionInstall({
    required this.installId,
    required this.channelId,
    required this.extensionId,
    required this.version,
    required this.approvedPermissions,
    required this.approvedSurfaces,
    required this.config,
    required this.state,
    required this.installedAt,
    required this.updatedAt,
  });

  final String installId;
  final String channelId;
  final String extensionId;
  final String version;
  final List<String> approvedPermissions;
  final List<String> approvedSurfaces;
  final Map<String, String> config;
  final String state;
  final DateTime installedAt;
  final DateTime updatedAt;
}

class ExtensionSession {
  const ExtensionSession({
    required this.sessionId,
    required this.channelId,
    required this.extensionId,
    required this.version,
    required this.surface,
    required this.fanId,
    required this.pairwiseCreatorFanId,
    required this.state,
    required this.allowedPermissions,
    required this.createdAt,
  });

  final String sessionId;
  final String channelId;
  final String extensionId;
  final String version;
  final String surface;
  final String fanId;
  final String pairwiseCreatorFanId;
  final String state;
  final List<String> allowedPermissions;
  final DateTime createdAt;
}

class ExtensionEvent {
  const ExtensionEvent({
    required this.eventId,
    required this.sessionId,
    required this.type,
    required this.payload,
    required this.createdAt,
    required this.idempotencyKey,
  });

  final String eventId;
  final String sessionId;
  final String type;
  final Map<String, String> payload;
  final DateTime createdAt;
  final String idempotencyKey;
}

class ExtensionStateEntry {
  const ExtensionStateEntry({
    required this.scopeKey,
    required this.key,
    required this.value,
    required this.exportBehavior,
    required this.updatedAt,
  });

  final String scopeKey;
  final String key;
  final Map<String, String> value;
  final String exportBehavior;
  final DateTime updatedAt;
}

class ExtensionStateExport {
  const ExtensionStateExport({
    required this.exportId,
    required this.channelId,
    required this.generatedAt,
    required this.entries,
    this.fanId,
  });

  final String exportId;
  final String channelId;
  final String? fanId;
  final DateTime generatedAt;
  final List<ExtensionStateEntry> entries;
}

class ChannelTheme {
  const ChannelTheme({
    required this.themeId,
    required this.name,
    required this.primaryHex,
    required this.secondaryHex,
    required this.backgroundHex,
    required this.surfaceHex,
    required this.textHex,
    required this.accentHex,
  });

  final String themeId;
  final String name;
  final String primaryHex;
  final String secondaryHex;
  final String backgroundHex;
  final String surfaceHex;
  final String textHex;
  final String accentHex;
}

class SurfaceModule {
  const SurfaceModule({
    required this.moduleId,
    required this.kind,
    required this.title,
    required this.surface,
    required this.sortOrder,
    required this.enabled,
    required this.config,
    this.extensionId,
  });

  final String moduleId;
  final String kind;
  final String title;
  final String surface;
  final int sortOrder;
  final bool enabled;
  final String? extensionId;
  final Map<String, String> config;
}

class InstalledExtensionRef {
  const InstalledExtensionRef({
    required this.installId,
    required this.extensionId,
    required this.name,
    required this.version,
    required this.surfaces,
    required this.state,
    required this.moduleIds,
  });

  final String installId;
  final String extensionId;
  final String name;
  final String version;
  final List<String> surfaces;
  final String state;
  final List<String> moduleIds;
}

class CreatorExperienceConfig {
  const CreatorExperienceConfig({
    required this.channelId,
    required this.theme,
    required this.bannerRef,
    required this.surfaceModules,
    required this.aiPersona,
    required this.adPosture,
    required this.installedExtensions,
    required this.version,
    required this.updatedAt,
  });

  final String channelId;
  final ChannelTheme theme;
  final String bannerRef;
  final List<SurfaceModule> surfaceModules;
  final String aiPersona;
  final String adPosture;
  final List<InstalledExtensionRef> installedExtensions;
  final int version;
  final DateTime updatedAt;
}
