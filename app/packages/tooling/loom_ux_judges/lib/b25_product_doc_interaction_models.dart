import 'dart:convert';
import 'dart:io';

typedef B25JsonMap = Map<String, Object?>;

const b25SemanticInteractionModelHeading =
    '### B25 Semantic Interaction Models';

const b25InteractionModelAssetRepositoryPath =
    'app/packages/core/loom_communities_app_shell/assets/'
    'b25_semantic_interaction_models.json';

const b25InteractionModelFlutterAssetPath =
    'packages/loom_communities_app_shell/assets/'
    'b25_semantic_interaction_models.json';

const b25DisallowedGenericSubstitutes = <String>[
  'accept',
  'cancel',
  'ok',
  'complete workflow',
  'complete',
  'confirm',
  'continue',
];

class B25ProductCommunitySource {
  const B25ProductCommunitySource({
    required this.communityId,
    required this.communityName,
    required this.extensionId,
    required this.productDocPath,
  });

  final String communityId;
  final String communityName;
  final String extensionId;
  final String productDocPath;

  B25JsonMap toJson() => <String, Object?>{
    'communityId': communityId,
    'communityName': communityName,
    'extensionId': extensionId,
    'productDocPath': productDocPath,
  };
}

const b25ProductCommunitySources = <B25ProductCommunitySource>[
  B25ProductCommunitySource(
    communityId: 'community_ad_off',
    communityName: 'Ad-Free Community',
    extensionId: 'ext_ad_free_community',
    productDocPath:
        'docs/references/communities/ad-free-community-product-experience.md',
  ),
  B25ProductCommunitySource(
    communityId: 'community_camera_club',
    communityName: 'Camera Club',
    extensionId: 'ext_camera_club',
    productDocPath:
        'docs/references/communities/camera-club-product-experience.md',
  ),
  B25ProductCommunitySource(
    communityId: 'community_hoa',
    communityName: 'Cedar Commons HOA',
    extensionId: 'ext_cedar_commons_hoa',
    productDocPath:
        'docs/references/communities/cedar-commons-hoa-product-experience.md',
  ),
  B25ProductCommunitySource(
    communityId: 'community_chess_club',
    communityName: 'Chess Club',
    extensionId: 'ext_chess_club',
    productDocPath:
        'docs/references/communities/chess-club-product-experience.md',
  ),
  B25ProductCommunitySource(
    communityId: 'community_export_migration',
    communityName: 'Data Portability Community',
    extensionId: 'ext_data_portability_community',
    productDocPath:
        'docs/references/communities/data-portability-community-product-experience.md',
  ),
  B25ProductCommunitySource(
    communityId: 'community_garden_club',
    communityName: 'Garden Club',
    extensionId: 'ext_garden_club',
    productDocPath:
        'docs/references/communities/garden-club-product-experience.md',
  ),
  B25ProductCommunitySource(
    communityId: 'community_mosque',
    communityName: 'Masjid Nur',
    extensionId: 'ext_mosque',
    productDocPath:
        'docs/references/communities/masjid-nur-product-experience.md',
  ),
  B25ProductCommunitySource(
    communityId: 'community_platform_social',
    communityName: 'Member Social Space',
    extensionId: 'ext_member_social_space',
    productDocPath:
        'docs/references/communities/member-social-space-product-experience.md',
  ),
  B25ProductCommunitySource(
    communityId: 'community_book_club',
    communityName: 'Neighborhood Book Club',
    extensionId: 'ext_neighborhood_book_club',
    productDocPath:
        'docs/references/communities/neighborhood-book-club-product-experience.md',
  ),
  B25ProductCommunitySource(
    communityId: 'community_youth_soccer',
    communityName: 'Riverside Youth Soccer',
    extensionId: 'ext_youth_soccer',
    productDocPath:
        'docs/references/communities/riverside-youth-soccer-product-experience.md',
  ),
];

class B25ProductDocInteractionModel {
  const B25ProductDocInteractionModel({
    required this.communityId,
    required this.communityName,
    required this.extensionId,
    required this.productDocPath,
    required this.workflowId,
    required this.role,
    required this.expectedDecision,
    required this.requiredPrimaryActions,
    required this.requiredAlternateActions,
    required this.resultAndReceiverState,
    this.alternateRequirementNote = '',
  });

  factory B25ProductDocInteractionModel.fromJson(B25JsonMap json) {
    List<String> strings(String key) =>
        (json[key] as List<Object?>? ?? const [])
            .map((value) => value.toString())
            .toList(growable: false);

    return B25ProductDocInteractionModel(
      communityId: json['communityId'].toString(),
      communityName: json['communityName'].toString(),
      extensionId: json['extensionId'].toString(),
      productDocPath: json['productDocPath'].toString(),
      workflowId: json['workflowId'].toString(),
      role: json['role'].toString(),
      expectedDecision: json['expectedDecision'].toString(),
      requiredPrimaryActions: strings('requiredPrimaryActions'),
      requiredAlternateActions: strings('requiredAlternateActions'),
      resultAndReceiverState: json['resultAndReceiverState'].toString(),
      alternateRequirementNote:
          json['alternateRequirementNote']?.toString() ?? '',
    );
  }

  final String communityId;
  final String communityName;
  final String extensionId;
  final String productDocPath;
  final String workflowId;
  final String role;
  final String expectedDecision;
  final List<String> requiredPrimaryActions;
  final List<String> requiredAlternateActions;
  final String resultAndReceiverState;
  final String alternateRequirementNote;

  B25JsonMap toJson() => <String, Object?>{
    'communityId': communityId,
    'communityName': communityName,
    'extensionId': extensionId,
    'productDocPath': productDocPath,
    'workflowId': workflowId,
    'role': role,
    'expectedDecision': expectedDecision,
    'requiredPrimaryActions': requiredPrimaryActions,
    'requiredAlternateActions': requiredAlternateActions,
    'resultAndReceiverState': resultAndReceiverState,
    if (alternateRequirementNote.isNotEmpty)
      'alternateRequirementNote': alternateRequirementNote,
  };
}

class B25ProductDocInteractionCatalog {
  B25ProductDocInteractionCatalog._(this.models) {
    for (final model in models) {
      final key = _rowKey(model.communityId, model.workflowId, model.role);
      if (_modelsByKey.containsKey(key)) {
        throw StateError(
          'Duplicate B25 product-doc interaction model for community '
          '`${model.communityId}`, workflow `${model.workflowId}`, '
          '$_productDocRoleLabel `${model.role}`.',
        );
      }
      _modelsByKey[key] = model;
    }
  }

  factory B25ProductDocInteractionCatalog.fromRepositoryRoot(
    Directory repositoryRoot,
  ) {
    final models = <B25ProductDocInteractionModel>[];
    for (final source in b25ProductCommunitySources) {
      final file = File('${repositoryRoot.path}/${source.productDocPath}');
      if (!file.existsSync()) {
        throw StateError(
          'Missing B25 product experience doc for community '
          '`${source.communityName}` (`${source.communityId}`): '
          '${file.path}',
        );
      }
      models.addAll(_parseProductDoc(source, file.readAsStringSync()));
    }
    return B25ProductDocInteractionCatalog._(models);
  }

  factory B25ProductDocInteractionCatalog.fromAssetJson(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! B25JsonMap) {
      throw const FormatException(
        'B25 interaction-model asset root must be a JSON object.',
      );
    }
    final rows = decoded['rows'];
    if (rows is! List<Object?>) {
      throw const FormatException(
        'B25 interaction-model asset must contain a rows array.',
      );
    }
    return B25ProductDocInteractionCatalog._(
      rows
          .map((row) {
            if (row is! B25JsonMap) {
              throw const FormatException(
                'Every B25 interaction-model asset row must be a JSON object.',
              );
            }
            return B25ProductDocInteractionModel.fromJson(row);
          })
          .toList(growable: false),
    );
  }

  final List<B25ProductDocInteractionModel> models;
  final Map<String, B25ProductDocInteractionModel> _modelsByKey = {};

  B25ProductDocInteractionModel requireModel({
    required String communityId,
    required String communityName,
    required String workflowId,
    required String role,
  }) {
    final source = _sourceForCommunity(
      communityId: communityId,
      communityName: communityName,
    );
    if (source == null) {
      throw StateError(
        'No B25 product-doc community entry for community '
        '`${communityName.isEmpty ? communityId : communityName}` '
        '(`${communityId.isEmpty ? 'missing-community-id' : communityId}`), '
        'workflow `$workflowId`, $_productDocRoleLabel `$role`.',
      );
    }
    final model = _modelsByKey[_rowKey(source.communityId, workflowId, role)];
    if (model == null) {
      throw StateError(
        'No B25 product-doc interaction model for community '
        '`${source.communityName}` (`${source.communityId}`), workflow '
        '`$workflowId`, $_productDocRoleLabel `$role` in '
        '`${source.productDocPath}`.',
      );
    }
    return model;
  }

  B25JsonMap toAssetJson() => <String, Object?>{
    'schemaVersion': 1,
    'source': 'B25 Semantic Interaction Models product-doc tables',
    'rowCount': models.length,
    'communities': b25ProductCommunitySources
        .map((source) => source.toJson())
        .toList(growable: false),
    'rows': models.map((model) => model.toJson()).toList(growable: false),
  };

  String toCanonicalAssetString() =>
      '${const JsonEncoder.withIndent('  ').convert(toAssetJson())}\n';
}

Directory locateB25RepositoryRoot([Directory? start]) {
  var directory = start ?? Directory.current;
  for (var i = 0; i < 10; i += 1) {
    if (Directory(
      '${directory.path}/docs/references/communities',
    ).existsSync()) {
      return directory;
    }
    final parent = directory.parent;
    if (parent.path == directory.path) break;
    directory = parent;
  }
  throw StateError(
    'Could not locate the Loom repository root containing '
    '`docs/references/communities` from `${(start ?? Directory.current).path}`.',
  );
}

File generateB25InteractionModelAsset({Directory? repositoryRoot}) {
  final root = repositoryRoot ?? locateB25RepositoryRoot();
  final catalog = B25ProductDocInteractionCatalog.fromRepositoryRoot(root);
  final output = File('${root.path}/$b25InteractionModelAssetRepositoryPath');
  output.parent.createSync(recursive: true);
  output.writeAsStringSync(catalog.toCanonicalAssetString());
  return output;
}

List<B25ProductDocInteractionModel> _parseProductDoc(
  B25ProductCommunitySource source,
  String markdown,
) {
  final lines = const LineSplitter().convert(markdown);
  final headingIndex = lines.indexWhere(
    (line) => line.trim() == b25SemanticInteractionModelHeading,
  );
  if (headingIndex < 0) {
    throw StateError(
      'Missing `$b25SemanticInteractionModelHeading` in '
      '`${source.productDocPath}` for `${source.communityName}`.',
    );
  }

  const expectedHeader = <String>[
    'Workflow',
    'Per'
        'sona',
    'Expected decision',
    'Required primary actions',
    'Required alternate/change/reject actions',
    'Result and receiver state',
  ];
  var headerSeen = false;
  final models = <B25ProductDocInteractionModel>[];
  for (var index = headingIndex + 1; index < lines.length; index += 1) {
    final line = lines[index].trim();
    if (line.startsWith('### ') && line != b25SemanticInteractionModelHeading) {
      break;
    }
    if (!line.startsWith('|')) continue;
    final cells = _markdownTableCells(line);
    if (!headerSeen) {
      if (_listEquals(cells, expectedHeader)) {
        headerSeen = true;
      }
      continue;
    }
    if (cells.every((cell) => RegExp(r'^:?-{3,}:?$').hasMatch(cell))) {
      continue;
    }
    if (cells.length != expectedHeader.length) {
      throw FormatException(
        'Malformed B25 table row at `${source.productDocPath}:${index + 1}`: '
        'expected ${expectedHeader.length} cells, found ${cells.length}.',
      );
    }
    if (cells.any((cell) => cell.isEmpty)) {
      throw FormatException(
        'Malformed B25 table row at `${source.productDocPath}:${index + 1}`: '
        'every cell is required.',
      );
    }
    final alternateCell = cells[4];
    final alternateDeclaresNone = alternateCell.toLowerCase().startsWith(
      '(none',
    );
    models.add(
      B25ProductDocInteractionModel(
        communityId: source.communityId,
        communityName: source.communityName,
        extensionId: source.extensionId,
        productDocPath: source.productDocPath,
        workflowId: _stripMarkdownCode(cells[0]),
        role: _stripMarkdownCode(cells[1]).toLowerCase(),
        expectedDecision: cells[2],
        requiredPrimaryActions: _parseSynonymSet(cells[3]),
        requiredAlternateActions: alternateDeclaresNone
            ? const <String>[]
            : _parseSynonymSet(alternateCell),
        alternateRequirementNote: alternateDeclaresNone ? alternateCell : '',
        resultAndReceiverState: cells[5],
      ),
    );
  }
  if (!headerSeen || models.isEmpty) {
    throw StateError(
      'No B25 semantic interaction-model rows found in '
      '`${source.productDocPath}` for `${source.communityName}`.',
    );
  }
  return models;
}

List<String> _markdownTableCells(String line) {
  final trimmed = line.trim();
  final withoutLeading = trimmed.startsWith('|')
      ? trimmed.substring(1)
      : trimmed;
  final withoutEdges = withoutLeading.endsWith('|')
      ? withoutLeading.substring(0, withoutLeading.length - 1)
      : withoutLeading;
  return withoutEdges.split('|').map((cell) => cell.trim()).toList();
}

List<String> _parseSynonymSet(String cell) => cell
    .split(',')
    .map((term) => _stripMarkdownCode(term.trim()))
    .where((term) => term.isNotEmpty)
    .toList(growable: false);

String _stripMarkdownCode(String value) {
  final trimmed = value.trim();
  if (trimmed.length >= 2 && trimmed.startsWith('`') && trimmed.endsWith('`')) {
    return trimmed.substring(1, trimmed.length - 1).trim();
  }
  return trimmed;
}

B25ProductCommunitySource? _sourceForCommunity({
  required String communityId,
  required String communityName,
}) {
  final normalizedId = _normalize(communityId);
  final normalizedName = _normalize(communityName);
  for (final source in b25ProductCommunitySources) {
    if (normalizedId.isNotEmpty &&
        <String>{
          _normalize(source.communityId),
          _normalize(source.extensionId),
        }.contains(normalizedId)) {
      return source;
    }
  }
  for (final source in b25ProductCommunitySources) {
    if (normalizedName.isNotEmpty &&
        _normalize(source.communityName) == normalizedName) {
      return source;
    }
  }
  return null;
}

const _productDocRoleLabel =
    'per'
    'sona';

String _rowKey(String communityId, String workflowId, String role) =>
    '${_normalize(communityId)}::${_normalize(workflowId)}::${_normalize(role)}';

String _normalize(String value) => value.trim().toLowerCase();

bool _listEquals(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
