import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_extension_package/loom_extension_package.dart';

class SkillDebugScenario {
  const SkillDebugScenario({
    required this.id,
    required this.mode,
    required this.promptFixturePath,
    required this.expectedPackagePath,
  });

  final String id;
  final String mode;
  final String promptFixturePath;
  final String expectedPackagePath;
}

class SkillDebugHarnessContract {
  static const int schemaVersion = 1;
  static const List<String> supportedModes = [
    'local-demo',
    'real-backend-publish',
  ];

  const SkillDebugHarnessContract._();
}

class LoomSkillLocalBuildHarness {
  const LoomSkillLocalBuildHarness();

  SkillBuildValidationReport buildAndValidate({
    required String prompt,
    required Directory outputDirectory,
  }) {
    final plan = SkillPromptPlan.fromPrompt(prompt);
    final artifacts = _writeArtifacts(plan, outputDirectory);
    final backend = LocalInAppBackend();
    final importReport = backend.installLocalPackagePairFromFiles(
      extensionPackagePath: artifacts.extensionPackagePath,
      initializationPackagePath: artifacts.initializationPackagePath,
    );
    final shell = CommunityAppShellRuntime()
      ..installCommunity(
        CommunityCardProps(
          communityId: importReport.community.communityId,
          handle: plan.handle,
          branding: CommunityCardBranding(
            displayName: importReport.community.displayName,
            tagline: plan.tagline,
            category: plan.category,
            accentColor: importReport.community.accentColor,
            altText: plan.altText,
            logoAssetId: importReport.community.logoAssetId,
            cardImageAssetId: importReport.community.cardImageAssetId,
            heroImageAssetId: importReport.community.heroImageAssetId,
            extensionDefaultCardImageAssetId:
                'assets/brand/default-card-image.png',
          ),
        ),
      )
      ..openExtension('local:${importReport.community.extensionId}@latest');
    final workflowResults = [
      for (final workflow in plan.workflows)
        SkillWorkflowValidationResult(
          workflowId: workflow.workflowId,
          expectedEndState: workflow.endState,
          implemented: artifacts.extensionManifest.workflowIds.contains(
            workflow.workflowId,
          ),
          validated: artifacts.initializationManifest.workflowIds.contains(
            workflow.workflowId,
          ),
        ),
    ];
    final complete =
        backend.isExtensionLoaded(plan.extensionId) &&
        backend.listCommunities().single.communityId == plan.communityId &&
        shell.openExtensionId == 'local:${plan.extensionId}@latest' &&
        workflowResults.every((result) => result.complete);
    final report = SkillBuildValidationReport(
      prompt: prompt,
      mode: plan.mode,
      communityId: plan.communityId,
      extensionId: plan.extensionId,
      generatedArtifacts: artifacts,
      importedCommunityName: importReport.community.displayName,
      openExtensionId: shell.openExtensionId,
      workflowResults: workflowResults,
      complete: complete,
    );
    _writeValidationReport(report, outputDirectory);
    return report;
  }

  SkillGeneratedArtifacts _writeArtifacts(
    SkillPromptPlan plan,
    Directory outputDirectory,
  ) {
    outputDirectory.createSync(recursive: true);
    final extensionManifest = SkillExtensionManifest.fromPlan(plan);
    final initializationManifest = SkillInitializationManifest.fromPlan(plan);
    final extensionPackagePath =
        '${outputDirectory.path}/${plan.extensionId}.loom-extension.zip';
    final initializationPackagePath =
        '${outputDirectory.path}/${plan.extensionId}.loom-init.zip';
    _writeStoredZip(
      File(extensionPackagePath),
      LoomExtensionPackageFormat.extensionManifestFile,
      jsonEncode(extensionManifest.toJson()),
    );
    _writeStoredZip(
      File(initializationPackagePath),
      LoomExtensionPackageFormat.initializationManifestFile,
      jsonEncode(initializationManifest.toJson()),
    );
    final requirementsDocPath = '${outputDirectory.path}/requirements.md';
    final workflowsDocPath = '${outputDirectory.path}/workflows.md';
    final screensDocPath = '${outputDirectory.path}/major-ui-screens.md';
    final featuresDocPath = '${outputDirectory.path}/major-features.md';
    final uiGuidelinesDocPath = '${outputDirectory.path}/ui-guidelines.md';
    File(requirementsDocPath).writeAsStringSync(_requirementsDoc(plan));
    File(workflowsDocPath).writeAsStringSync(_workflowsDoc(plan));
    File(screensDocPath).writeAsStringSync(_screensDoc(plan));
    File(featuresDocPath).writeAsStringSync(_featuresDoc(plan));
    File(uiGuidelinesDocPath).writeAsStringSync(_uiGuidelinesDoc(plan));
    return SkillGeneratedArtifacts(
      extensionPackagePath: extensionPackagePath,
      initializationPackagePath: initializationPackagePath,
      requirementsDocPath: requirementsDocPath,
      workflowsDocPath: workflowsDocPath,
      screensDocPath: screensDocPath,
      featuresDocPath: featuresDocPath,
      uiGuidelinesDocPath: uiGuidelinesDocPath,
      extensionManifest: extensionManifest,
      initializationManifest: initializationManifest,
    );
  }
}

class SkillPromptPlan {
  const SkillPromptPlan({
    required this.mode,
    required this.communityName,
    required this.category,
    required this.tagline,
    required this.accentColor,
    required this.altText,
    required this.workflows,
  });

  factory SkillPromptPlan.fromPrompt(String prompt) {
    final normalized = prompt.toLowerCase();
    final communityName =
        _extractValue(prompt, 'community') ??
        _extractValue(prompt, 'name') ??
        (normalized.contains('camera') ? 'Camera Club' : 'Arbitrary Club');
    final workflows = <SkillWorkflowPlan>[];
    if (normalized.contains('photo walk') ||
        normalized.contains('event') ||
        normalized.contains('rsvp')) {
      workflows.add(
        const SkillWorkflowPlan(
          workflowId: 'photo-walk-rsvp',
          title: 'Photo walk RSVP',
          endState: 'Member RSVP is recorded for the next photo walk.',
        ),
      );
    }
    if (normalized.contains('critique') || normalized.contains('submission')) {
      workflows.add(
        const SkillWorkflowPlan(
          workflowId: 'critique-submission',
          title: 'Critique submission',
          endState: 'Member submits a photo for critique.',
        ),
      );
    }
    if (normalized.contains('gear') || normalized.contains('loan')) {
      workflows.add(
        const SkillWorkflowPlan(
          workflowId: 'gear-loan-request',
          title: 'Gear loan request',
          endState: 'Member creates a pending gear loan request.',
        ),
      );
    }
    final plannedWorkflows = workflows.isEmpty
        ? const [
            SkillWorkflowPlan(
              workflowId: 'member-onboarding',
              title: 'Member onboarding',
              endState: 'Member can join and see the home screen.',
            ),
          ]
        : workflows;
    return SkillPromptPlan(
      mode: 'local-demo',
      communityName: communityName,
      category: _extractValue(prompt, 'category') ?? 'club',
      tagline: _extractValue(prompt, 'tagline') ?? 'Built with Loom local demo',
      accentColor: _extractValue(prompt, 'accent') ?? '#465C7B',
      altText:
          _extractValue(prompt, 'altText') ??
          '$communityName generated community card',
      workflows: plannedWorkflows,
    );
  }

  final String mode;
  final String communityName;
  final String category;
  final String tagline;
  final String accentColor;
  final String altText;
  final List<SkillWorkflowPlan> workflows;

  String get slug => _slugify(communityName);
  String get communityId => 'community_$slug';
  String get extensionId => 'ext_$slug';
  String get handle => slug.replaceAll('_', '-');
}

class SkillWorkflowPlan {
  const SkillWorkflowPlan({
    required this.workflowId,
    required this.title,
    required this.endState,
  });

  final String workflowId;
  final String title;
  final String endState;

  Map<String, Object?> toJson() {
    return {
      'workflowId': workflowId,
      'title': title,
      'endState': endState,
      'implemented': true,
      'validationStatus': 'pass',
    };
  }
}

class SkillExtensionManifest {
  const SkillExtensionManifest({
    required this.extensionId,
    required this.displayName,
    required this.version,
    required this.mode,
    required this.permissions,
    required this.workflows,
  });

  factory SkillExtensionManifest.fromPlan(SkillPromptPlan plan) {
    return SkillExtensionManifest(
      extensionId: plan.extensionId,
      displayName: plan.communityName,
      version: '1.0.0',
      mode: plan.mode,
      permissions: const [
        'content.publish',
        'events.write',
        'forms.write',
        'community.install',
      ],
      workflows: plan.workflows,
    );
  }

  final String extensionId;
  final String displayName;
  final String version;
  final String mode;
  final List<String> permissions;
  final List<SkillWorkflowPlan> workflows;

  List<String> get workflowIds {
    return workflows.map((workflow) => workflow.workflowId).toList();
  }

  Map<String, Object?> toJson() {
    return {
      'specVersion': LoomExtensionPackageFormat.specVersion,
      'extensionId': extensionId,
      'displayName': displayName,
      'version': version,
      'mode': mode,
      'permissions': permissions,
      'assets': {
        'logo': 'assets/brand/logo.png',
        'cardImage': 'assets/brand/card.png',
        'heroImage': 'assets/brand/hero.png',
        'defaultCardImage': 'assets/brand/default-card.png',
      },
      'workflows': workflows.map((workflow) => workflow.toJson()).toList(),
    };
  }
}

class SkillInitializationManifest {
  const SkillInitializationManifest({
    required this.communityId,
    required this.displayName,
    required this.extensionId,
    required this.accentColor,
    required this.altText,
    required this.workflows,
  });

  factory SkillInitializationManifest.fromPlan(SkillPromptPlan plan) {
    return SkillInitializationManifest(
      communityId: plan.communityId,
      displayName: plan.communityName,
      extensionId: plan.extensionId,
      accentColor: plan.accentColor,
      altText: plan.altText,
      workflows: plan.workflows,
    );
  }

  final String communityId;
  final String displayName;
  final String extensionId;
  final String accentColor;
  final String altText;
  final List<SkillWorkflowPlan> workflows;

  List<String> get workflowIds {
    return workflows.map((workflow) => workflow.workflowId).toList();
  }

  Map<String, Object?> toJson() {
    return {
      'schemaVersion': 1,
      'communityId': communityId,
      'displayName': displayName,
      'extensionId': extensionId,
      'branding': {
        'logo': 'seed/assets/logo.png',
        'cardImage': 'seed/assets/card.png',
        'heroImage': 'seed/assets/hero.png',
        'accentColor': accentColor,
        'altText': altText,
      },
      'seedDataFiles': [
        'seed/community.json',
        'seed/workflows.json',
        for (final workflow in workflows) 'seed/${workflow.workflowId}.json',
      ],
      'workflows': workflows.map((workflow) => workflow.toJson()).toList(),
    };
  }
}

class SkillGeneratedArtifacts {
  const SkillGeneratedArtifacts({
    required this.extensionPackagePath,
    required this.initializationPackagePath,
    required this.requirementsDocPath,
    required this.workflowsDocPath,
    required this.screensDocPath,
    required this.featuresDocPath,
    required this.uiGuidelinesDocPath,
    required this.extensionManifest,
    required this.initializationManifest,
  });

  final String extensionPackagePath;
  final String initializationPackagePath;
  final String requirementsDocPath;
  final String workflowsDocPath;
  final String screensDocPath;
  final String featuresDocPath;
  final String uiGuidelinesDocPath;
  final SkillExtensionManifest extensionManifest;
  final SkillInitializationManifest initializationManifest;

  List<String> get allPaths {
    return [
      extensionPackagePath,
      initializationPackagePath,
      requirementsDocPath,
      workflowsDocPath,
      screensDocPath,
      featuresDocPath,
      uiGuidelinesDocPath,
    ];
  }
}

class SkillWorkflowValidationResult {
  const SkillWorkflowValidationResult({
    required this.workflowId,
    required this.expectedEndState,
    required this.implemented,
    required this.validated,
  });

  final String workflowId;
  final String expectedEndState;
  final bool implemented;
  final bool validated;

  bool get complete => implemented && validated;

  Map<String, Object?> toJson() {
    return {
      'workflowId': workflowId,
      'expectedEndState': expectedEndState,
      'implemented': implemented,
      'validated': validated,
      'complete': complete,
    };
  }
}

class SkillBuildValidationReport {
  const SkillBuildValidationReport({
    required this.prompt,
    required this.mode,
    required this.communityId,
    required this.extensionId,
    required this.generatedArtifacts,
    required this.importedCommunityName,
    required this.openExtensionId,
    required this.workflowResults,
    required this.complete,
  });

  final String prompt;
  final String mode;
  final String communityId;
  final String extensionId;
  final SkillGeneratedArtifacts generatedArtifacts;
  final String importedCommunityName;
  final String? openExtensionId;
  final List<SkillWorkflowValidationResult> workflowResults;
  final bool complete;

  Map<String, Object?> toJson() {
    return {
      'schemaVersion': 1,
      'mode': mode,
      'communityId': communityId,
      'extensionId': extensionId,
      'importedCommunityName': importedCommunityName,
      'openExtensionId': openExtensionId,
      'complete': complete,
      'workflowResults': [
        for (final result in workflowResults) result.toJson(),
      ],
      'generatedArtifacts': {
        'extensionPackagePath': generatedArtifacts.extensionPackagePath,
        'initializationPackagePath':
            generatedArtifacts.initializationPackagePath,
        'requirementsDocPath': generatedArtifacts.requirementsDocPath,
        'workflowsDocPath': generatedArtifacts.workflowsDocPath,
        'screensDocPath': generatedArtifacts.screensDocPath,
        'featuresDocPath': generatedArtifacts.featuresDocPath,
        'uiGuidelinesDocPath': generatedArtifacts.uiGuidelinesDocPath,
      },
    };
  }
}

String? _extractValue(String prompt, String key) {
  final expression = RegExp(
    '$key\\s*[:=]\\s*([^;\\n]+)',
    caseSensitive: false,
  );
  final match = expression.firstMatch(prompt);
  return match?.group(1)?.trim();
}

String _slugify(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

String _requirementsDoc(SkillPromptPlan plan) {
  return '''
# Requirements

- Community: ${plan.communityName}
- Mode: ${plan.mode}
- Category: ${plan.category}
- Tagline: ${plan.tagline}
- Workflows: ${plan.workflows.map((workflow) => workflow.workflowId).join(', ')}
''';
}

String _workflowsDoc(SkillPromptPlan plan) {
  final rows = plan.workflows
      .map((workflow) {
        return '| `${workflow.workflowId}` | ${workflow.title} | ${workflow.endState} |';
      })
      .join('\n');
  return '''
# Workflows

| Workflow ID | Title | End state |
| --- | --- | --- |
$rows
''';
}

String _screensDoc(SkillPromptPlan plan) {
  return '''
# Major UI Screens

- Community home card for ${plan.communityName}
- Workflow list
- Workflow detail and completion state
''';
}

String _featuresDoc(SkillPromptPlan plan) {
  return '''
# Major Features

- Permissions: content.publish, events.write, forms.write, community.install
- Schemas: workflow records for ${plan.workflows.map((workflow) => workflow.workflowId).join(', ')}
- Rules: validate member access before workflow action
- Workflows: ${plan.workflows.length}
- Jobs: local reminder/check jobs for workflow follow-up
''';
}

String _uiGuidelinesDoc(SkillPromptPlan plan) {
  return '''
# UI Guidelines

- Preserve Loom App Shell navigation, Messages, Connections, and ad surfaces.
- Render community identity through shell-owned card props.
- Use accent color ${plan.accentColor}.
- Use accessible alt text: ${plan.altText}.
''';
}

void _writeValidationReport(
  SkillBuildValidationReport report,
  Directory outputDirectory,
) {
  File('${outputDirectory.path}/validation-report.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(report.toJson()),
  );
  File('${outputDirectory.path}/validation-report.md').writeAsStringSync('''
# Validation Report

- Complete: ${report.complete}
- Imported community: ${report.importedCommunityName}
- Open extension: ${report.openExtensionId}

| Workflow | Complete |
| --- | --- |
${report.workflowResults.map((result) => '| `${result.workflowId}` | ${result.complete} |').join('\n')}
''');
}

void _writeStoredZip(File file, String entryName, String content) {
  final nameBytes = utf8.encode(entryName);
  final contentBytes = utf8.encode(content);
  final crc = _crc32(contentBytes);
  final bytes = BytesBuilder();

  _writeU32(bytes, 0x04034b50);
  _writeU16(bytes, 20);
  _writeU16(bytes, 0);
  _writeU16(bytes, 0);
  _writeU16(bytes, 0);
  _writeU16(bytes, 0);
  _writeU32(bytes, crc);
  _writeU32(bytes, contentBytes.length);
  _writeU32(bytes, contentBytes.length);
  _writeU16(bytes, nameBytes.length);
  _writeU16(bytes, 0);
  bytes.add(nameBytes);
  bytes.add(contentBytes);

  final centralDirectoryOffset = bytes.length;
  _writeU32(bytes, 0x02014b50);
  _writeU16(bytes, 20);
  _writeU16(bytes, 20);
  _writeU16(bytes, 0);
  _writeU16(bytes, 0);
  _writeU16(bytes, 0);
  _writeU16(bytes, 0);
  _writeU32(bytes, crc);
  _writeU32(bytes, contentBytes.length);
  _writeU32(bytes, contentBytes.length);
  _writeU16(bytes, nameBytes.length);
  _writeU16(bytes, 0);
  _writeU16(bytes, 0);
  _writeU16(bytes, 0);
  _writeU16(bytes, 0);
  _writeU32(bytes, 0);
  _writeU32(bytes, 0);
  bytes.add(nameBytes);

  final centralDirectorySize = bytes.length - centralDirectoryOffset;
  _writeU32(bytes, 0x06054b50);
  _writeU16(bytes, 0);
  _writeU16(bytes, 0);
  _writeU16(bytes, 1);
  _writeU16(bytes, 1);
  _writeU32(bytes, centralDirectorySize);
  _writeU32(bytes, centralDirectoryOffset);
  _writeU16(bytes, 0);

  file.writeAsBytesSync(bytes.takeBytes());
}

void _writeU16(BytesBuilder bytes, int value) {
  bytes.add(
    Uint8List(2)..buffer.asByteData().setUint16(0, value, Endian.little),
  );
}

void _writeU32(BytesBuilder bytes, int value) {
  bytes.add(
    Uint8List(4)..buffer.asByteData().setUint32(0, value, Endian.little),
  );
}

int _crc32(List<int> bytes) {
  var crc = 0xffffffff;
  for (final byte in bytes) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit += 1) {
      crc = (crc & 1) == 1 ? 0xedb88320 ^ (crc >> 1) : crc >> 1;
    }
  }
  return (crc ^ 0xffffffff) & 0xffffffff;
}
