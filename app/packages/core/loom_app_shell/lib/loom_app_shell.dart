import 'package:flutter/material.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_design_system/loom_design_system.dart';

export 'package:loom_design_system/loom_design_system.dart' show buildLoomTheme;

enum RoleScope { fanApp, creatorStudio }

extension RoleScopeLabel on RoleScope {
  String get label {
    switch (this) {
      case RoleScope.fanApp:
        return 'Fan App';
      case RoleScope.creatorStudio:
        return 'Creator Studio';
    }
  }
}

typedef RoleSurfaceBuilder = Widget Function(BuildContext context);

CreatorMetadataApi? _creatorMetadataApi;
FanPassportApi? _fanPassportApi;
FanVaultApi? _fanVaultApi;
CreatorChannelRegistryApi? _creatorChannelRegistryApi;

void registerCreatorMetadataApi(CreatorMetadataApi api) {
  _creatorMetadataApi = api;
}

void registerFanPassportApi(FanPassportApi api) {
  _fanPassportApi = api;
}

void registerFanVaultApi(FanVaultApi api) {
  _fanVaultApi = api;
}

void registerCreatorChannelRegistryApi(CreatorChannelRegistryApi api) {
  _creatorChannelRegistryApi = api;
}

void resetAppShellDependencies() {
  _creatorMetadataApi = null;
  _fanPassportApi = null;
  _fanVaultApi = null;
  _creatorChannelRegistryApi = null;
}

CreatorMetadataApi resolveCreatorMetadataApi() {
  final api = _creatorMetadataApi;
  if (api == null) {
    throw StateError('CreatorMetadataApi has not been registered.');
  }
  return api;
}

FanPassportApi resolveFanPassportApi() {
  final api = _fanPassportApi;
  if (api == null) {
    throw StateError('FanPassportApi has not been registered.');
  }
  return api;
}

FanVaultApi resolveFanVaultApi() {
  final api = _fanVaultApi;
  if (api == null) {
    throw StateError('FanVaultApi has not been registered.');
  }
  return api;
}

CreatorChannelRegistryApi resolveCreatorChannelRegistryApi() {
  final api = _creatorChannelRegistryApi;
  if (api == null) {
    throw StateError('CreatorChannelRegistryApi has not been registered.');
  }
  return api;
}

class LoomDemoShell extends StatefulWidget {
  const LoomDemoShell({
    required this.fanBuilder,
    required this.studioBuilder,
    super.key,
  });

  final RoleSurfaceBuilder fanBuilder;
  final RoleSurfaceBuilder studioBuilder;

  @override
  State<LoomDemoShell> createState() => _LoomDemoShellState();
}

class _LoomDemoShellState extends State<LoomDemoShell> {
  RoleScope _role = RoleScope.fanApp;

  @override
  Widget build(BuildContext context) {
    final labels = RoleScope.values.map((role) => role.label).toList();
    final selectedIndex = RoleScope.values.indexOf(_role);

    return LoomNavScaffold(
      title: _role.label,
      roleSwitcher: RoleSwitcher(
        labels: labels,
        selectedIndex: selectedIndex,
        onChanged: (index) {
          setState(() {
            _role = RoleScope.values[index];
          });
        },
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: KeyedSubtree(
          key: ValueKey<RoleScope>(_role),
          child: _role == RoleScope.fanApp
              ? widget.fanBuilder(context)
              : widget.studioBuilder(context),
        ),
      ),
    );
  }
}
