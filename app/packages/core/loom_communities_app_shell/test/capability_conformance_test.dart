import 'dart:convert';
import 'dart:io';

import 'package:loom_communities_app_shell/src/app_shell_capabilities.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';
import 'package:test/test.dart';

const _shippedCommunityPaths = <String>[
  'docs/references/communities/'
      'Loom_Communities_Workflow_Engine_CameraClub_Example.jsonc',
  'docs/references/communities/'
      'Loom_Communities_Workflow_Engine_NeighborhoodBookClub_Example.jsonc',
  'docs/references/communities/'
      'Loom_Communities_Workflow_Engine_GardenClub_Example.jsonc',
  'docs/references/communities/'
      'Loom_Communities_Workflow_Engine_ChessClub_Example.jsonc',
  'docs/references/communities/'
      'Loom_Communities_Workflow_Engine_MasjidNur_Example.jsonc',
  'docs/references/communities/'
      'Loom_Communities_Workflow_Engine_RiversideYouthSoccer_Example.jsonc',
];

Directory _repositoryRoot() {
  var directory = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (File(
      '${directory.path}/docs/references/archetypes/README.md',
    ).existsSync()) {
      return directory;
    }
    directory = directory.parent;
  }
  throw StateError('Could not locate the repository root.');
}

String _readRepositoryFile(String relativePath) =>
    File('${_repositoryRoot().path}/$relativePath').readAsStringSync();

Set<String> _documentedCardSurfaceFamilies() {
  final readme = _readRepositoryFile('docs/references/archetypes/README.md');
  final start = readme.indexOf('## The archetypes (all 13');
  final end = readme.indexOf('\n## ', start + 1);
  if (start < 0 || end < 0) {
    throw StateError('Could not find the canonical archetype table.');
  }
  final section = readme.substring(start, end);
  return {
    for (final match in RegExp(
      r'^\| `([^`]+)` \|',
      multiLine: true,
    ).allMatches(section))
      if (match.group(1) != 'cardSurfaceFamily') match.group(1)!,
  };
}

Set<String> _perInstanceDispatcherCases() {
  final source = _readRepositoryFile(
    'app/packages/core/loom_communities_app_shell/lib/src/'
    'part27_engine_native_binding_dispatcher.dart',
  );
  final start = source.indexOf('switch (resolved.binding.cardSurfaceFamily)');
  final end = source.indexOf('\n      default:', start);
  if (start < 0 || end < 0) {
    throw StateError('Could not find EngineNativeArchetypeCard dispatch.');
  }
  return {
    for (final match in RegExp(
      r"case '([^']+)':",
    ).allMatches(source.substring(start, end)))
      match.group(1)!,
  };
}

Set<String> _tabRendererSwitchCases() {
  final source = _readRepositoryFile(
    'app/packages/core/loom_communities_app_shell/lib/src/'
    'part02_tab_shell.dart',
  );
  final start = source.indexOf('switch (rendererId)');
  final end = source.indexOf('\n    // Home falls through', start);
  if (start < 0 || end < 0) {
    throw StateError('Could not find _TabNativeRenderer dispatch.');
  }
  return {
    for (final match in RegExp(
      r"case '([^']+)':",
    ).allMatches(source.substring(start, end)))
      match.group(1)!,
  };
}

Map<String, ({String rendererId, Set<String> tabIds})>
_tabRendererRegistryEntries() {
  final source = _readRepositoryFile(
    'app/packages/core/loom_communities_app_shell/lib/src/'
    'part11_shell_models.dart',
  );
  final start = source.indexOf(
    'const _tabRendererContractsById = <String, LoomTabRendererContract>{',
  );
  final end = source.indexOf(
    '\n};\n\nLoomTabRendererContract tabRendererContractFor',
    start,
  );
  if (start < 0 || end < 0) {
    throw StateError('Could not find the tab renderer contract registry.');
  }

  final entries = <String, ({String rendererId, Set<String> tabIds})>{};
  final entryPattern = RegExp(
    r"^  '([^']+)': LoomTabRendererContract\(\n"
    r"    rendererId: '([^']+)',[\s\S]*?"
    r"^    tabIds: (?:const )?\[([^\]]*)\],",
    multiLine: true,
  );
  for (final match in entryPattern.allMatches(source.substring(start, end))) {
    entries[match.group(1)!] = (
      rendererId: match.group(2)!,
      tabIds: {
        for (final tabIdMatch in RegExp(
          r"'([^']+)'",
        ).allMatches(match.group(3)!))
          tabIdMatch.group(1)!,
      },
    );
  }
  if (entries.isEmpty) {
    throw StateError('Could not parse the tab renderer contract registry.');
  }
  return entries;
}

Iterable<Map<String, dynamic>> _declaredTabs(
  Map<String, dynamic> package,
) sync* {
  final appShell = package['appShell'];
  if (appShell is! Map) return;

  Iterable<Map<String, dynamic>> tabsFrom(Object? value) sync* {
    if (value is! List) return;
    for (final tab in value) {
      if (tab is Map) yield Map<String, dynamic>.from(tab);
    }
  }

  yield* tabsFrom(appShell['tabs']);
  final roleTabs = appShell['roleTabs'];
  if (roleTabs is Map) {
    for (final tabs in roleTabs.values) {
      yield* tabsFrom(tabs);
    }
  }
}

Set<String> _bindingTabIds(Map<String, dynamic> package) {
  final experience = package['experience'];
  if (experience is! Map) return const {};
  final definitions = experience['workflowDefinitions'];
  if (definitions is! Map) return const {};
  return {
    for (final definition in definitions.values)
      if (definition is Map)
        for (final binding
            in definition['renderBindings'] is List
                ? definition['renderBindings'] as List
                : const [])
          if (binding is Map && binding['tabId'] is String)
            binding['tabId'] as String,
  };
}

void main() {
  test(
    'every documented cardSurfaceFamily has one intentional shell renderer',
    () {
      final documented = _documentedCardSurfaceFamilies();
      final declared = <String>{
        ...supportedAppShellBespokeCardSurfaceFamilies,
        ...supportedAppShellGenericCardSurfaceFamilies,
      };

      expect(
        supportedAppShellBespokeCardSurfaceFamilies.intersection(
          supportedAppShellGenericCardSurfaceFamilies,
        ),
        isEmpty,
      );
      expect(declared, documented);

      final perInstanceBespoke = supportedAppShellBespokeCardSurfaceFamilies
          .difference(const {'table'});
      expect(_perInstanceDispatcherCases(), perInstanceBespoke);

      final listSurfaceSource = _readRepositoryFile(
        'app/packages/core/loom_communities_app_shell/lib/src/'
        'part32_engine_native_list_surface.dart',
      );
      expect(
        listSurfaceSource,
        contains("resolved.binding.cardSurfaceFamily == 'table'"),
        reason: '`table` must remain explicitly dispatched at list level.',
      );
    },
  );

  test('every shipped tabId resolves to a real shell renderer', () {
    final actualRendererCases = _tabRendererSwitchCases();
    final declaredRendererCases = supportedAppShellTabRendererContracts.values
        .where((rendererId) => rendererId != 'HomeTabSurfaceStack')
        .toSet();
    expect(actualRendererCases, declaredRendererCases);

    final registry = _tabRendererRegistryEntries();
    final specialTabIds = <String>{};
    for (final entry in supportedAppShellTabRendererContracts.entries) {
      final contract = registry[entry.key];
      expect(
        contract,
        isNotNull,
        reason: '${entry.key} is absent from the renderer contract registry',
      );
      expect(contract!.rendererId, entry.value);
      specialTabIds.addAll(contract.tabIds);
    }
    expect(specialTabIds, specialCasedAppShellTabIds);

    final discrepancies = <String>[];
    for (final path in _shippedCommunityPaths) {
      final package =
          jsonDecode(stripJsonComments(_readRepositoryFile(path)))
              as Map<String, dynamic>;
      final bindingTabIds = _bindingTabIds(package);
      for (final tab in _declaredTabs(package)) {
        final tabId = tab['tabId'];
        if (tabId is! String || tabId.trim().isEmpty) {
          discrepancies.add('$path declares a tab without a non-empty tabId');
          continue;
        }
        final rendererContractId =
            tab['rendererContractId'] as String? ??
            defaultAppShellTabRendererContractId;
        if (!supportedAppShellTabRendererContracts.containsKey(
          rendererContractId,
        )) {
          discrepancies.add(
            '$path tab "$tabId" names rendererContractId '
            '"$rendererContractId", which the shell does not dispatch',
          );
          continue;
        }
        if (rendererContractId == defaultAppShellTabRendererContractId &&
            !bindingTabIds.contains(tabId)) {
          discrepancies.add(
            '$path tab "$tabId" uses the generic list renderer but no '
            'renderBinding targets that tabId',
          );
        }
      }
    }

    expect(discrepancies, isEmpty, reason: discrepancies.join('\n'));
  });
}
