// ignore_for_file: prefer_const_constructors

import 'dart:convert';
import 'dart:io';

typedef JsonMap = Map<String, Object?>;

class CriterionResult {
  CriterionResult({
    required this.id,
    required this.title,
    required this.question,
    required this.scope,
    required this.score,
    required this.verdict,
    required this.blocksPass,
    required this.why,
    required this.requiredFix,
    this.evidenceUsed = const <String>[],
  });

  final String id;
  final String title;
  final String question;
  final String scope;
  final int score;
  final String verdict;
  final bool blocksPass;
  final String why;
  final String requiredFix;
  final List<String> evidenceUsed;

  JsonMap toJson() {
    return <String, Object?>{
      'criterionId': id,
      'title': title,
      'question': question,
      'scope': scope,
      'score': score,
      'verdict': verdict,
      'blocksPass': blocksPass,
      'why': why,
      'requiredFix': requiredFix,
      'evidenceUsed': evidenceUsed,
    };
  }
}

class JudgeResult {
  JudgeResult({
    required this.toolId,
    required this.status,
    required this.criteria,
    required this.errors,
    required this.warnings,
    this.extra = const <String, Object?>{},
  });

  final String toolId;
  final String status;
  final List<CriterionResult> criteria;
  final List<String> errors;
  final List<String> warnings;
  final JsonMap extra;

  bool get passed => status == 'pass';

  JsonMap toJson() {
    return <String, Object?>{
      'toolId': toolId,
      'status': status,
      'criteria': criteria.map((criterion) => criterion.toJson()).toList(),
      'errors': errors,
      'warnings': warnings,
      ...extra,
    };
  }
}

class JudgeSpec {
  const JudgeSpec({
    required this.toolId,
    required this.phase,
    required this.description,
    required this.criteria,
  });

  final String toolId;
  final String phase;
  final String description;
  final List<CriterionDefinition> criteria;
}

class CriterionDefinition {
  const CriterionDefinition({
    required this.id,
    required this.title,
    required this.requiredEvidenceFields,
    required this.failureMessage,
    required this.requiredFix,
    this.question,
    this.scope = 'general',
  });

  final String id;
  final String title;
  final List<String> requiredEvidenceFields;
  final String failureMessage;
  final String requiredFix;
  final String? question;
  final String scope;
}

final specs = <String, JudgeSpec>{
  'workflow-completeness-judge': JudgeSpec(
    toolId: 'workflow-completeness-judge',
    phase: 'B11',
    description:
        'Compares the owner prompt to generated workflows, packages, validation report, and Demo App replay.',
    criteria: <CriterionDefinition>[
      CriterionDefinition(
        id: 'b11-c01-owner-prompt-captured',
        title: 'Owner prompt and requested workflows are captured',
        requiredEvidenceFields: <String>['ownerPrompt', 'requestedWorkflows'],
        failureMessage:
            'The evidence does not prove the original owner prompt and requested workflow list were captured.',
        requiredFix:
            'Record the owner prompt and enumerate requested workflows before generating packages.',
      ),
      CriterionDefinition(
        id: 'b11-c02-workflows-implemented',
        title: 'Every requested workflow is implemented',
        requiredEvidenceFields: <String>['workflowResults'],
        failureMessage:
            'At least one requested workflow lacks implemented=true, validated=true, and complete=true.',
        requiredFix:
            'Add the missing route, seed data, UI test, and workflow result before claiming completion.',
      ),
      CriterionDefinition(
        id: 'b11-c03-packages-generated',
        title: 'Extension and initialization packages are generated',
        requiredEvidenceFields: <String>[
          'extensionPackage',
          'initializationPackage',
        ],
        failureMessage: 'The evidence does not include both package artifacts.',
        requiredFix:
            'Generate and record the .loom-extension.zip and .loom-init.zip paths.',
      ),
      CriterionDefinition(
        id: 'b11-c04-demo-app-validation',
        title: 'Generated packages load and validate in the Demo App',
        requiredEvidenceFields: <String>['demoAppValidation'],
        failureMessage:
            'The evidence does not prove local install/open/workflow validation in the Demo App.',
        requiredFix:
            'Run the Demo App local backend validation and attach the validation report.',
      ),
    ],
  ),
  'ux-contract-judge': JudgeSpec(
    toolId: 'ux-contract-judge',
    phase: 'B21',
    description:
        'Checks every workflow/persona row has a production UX contract before implementation.',
    criteria: <CriterionDefinition>[
      CriterionDefinition(
        id: 'b21-c01-contract-rows-complete',
        title: 'Every workflow/persona row has a production UX contract',
        requiredEvidenceFields: <String>['contractRows'],
        failureMessage: 'Contract rows are missing or incomplete.',
        requiredFix:
            'Add rows with workflowId, persona, realUserGoal, domainSurface, inputs, validation, action, success state, receiver state, and screenshot plan.',
      ),
      CriterionDefinition(
        id: 'b21-c02-domain-surface-planned',
        title: 'Every primary workflow has a planned domain surface',
        requiredEvidenceFields: <String>['contractRows'],
        failureMessage:
            'A primary workflow contract still allows generic workflow-card UX.',
        requiredFix:
            'Replace generic surfaces with concrete event, feed, form, payment, inbox, admin, receipt, search, export, or transfer surfaces.',
      ),
    ],
  ),
  'domain-surface-classifier': JudgeSpec(
    toolId: 'domain-surface-classifier',
    phase: 'B22',
    description:
        'Classifies implemented surfaces and fails primary generic workflow cards.',
    criteria: <CriterionDefinition>[
      CriterionDefinition(
        id: 'b22-c01-primary-surfaces-domain-native',
        title: 'Primary workflow surfaces are domain-native',
        requiredEvidenceFields: <String>['screenRows'],
        failureMessage:
            'A primary screen is classified as generic-workflow-card, checklist-modal, metadata-page, or repeated-card-shell.',
        requiredFix:
            'Replace the primary UI with a domain-native product surface and recapture evidence.',
      ),
      CriterionDefinition(
        id: 'b22-c02-semantic-actions',
        title: 'Primary actions use user-facing semantic labels',
        requiredEvidenceFields: <String>['screenRows'],
        failureMessage:
            'One or more primary actions use harness or implementation labels.',
        requiredFix:
            'Rename actions to the real user task and update UI tests.',
      ),
    ],
  ),
  'persona-ux-judge': JudgeSpec(
    toolId: 'persona-ux-judge',
    phase: 'B23',
    description:
        'Verifies actor, receiver, read-only, disabled, hidden, and unauthorized states from evidence.',
    criteria: <CriterionDefinition>[
      CriterionDefinition(
        id: 'b23-c01-persona-state-coverage',
        title: 'Every persona/workflow state has visible evidence',
        requiredEvidenceFields: <String>['personaRows'],
        failureMessage:
            'Persona state evidence is missing for one or more actor/receiver/unauthorized rows.',
        requiredFix:
            'Capture each persona state and record hidden, disabled, read-only, receiver, or actor behavior.',
      ),
      CriterionDefinition(
        id: 'b23-c02-unauthorized-behavior',
        title: 'Unauthorized personas cannot perform restricted workflows',
        requiredEvidenceFields: <String>['personaRows'],
        failureMessage:
            'Unauthorized behavior is missing or incorrectly passable.',
        requiredFix:
            'Implement and test hidden/disabled/read-only denial behavior for unauthorized personas.',
      ),
    ],
  ),
  'evidence-integrity-auditor': JudgeSpec(
    toolId: 'evidence-integrity-auditor',
    phase: 'B24',
    description:
        'Audits screenshot existence, hashes, freshness, app commit SHA, visible text, and generic-copy scan.',
    criteria: <CriterionDefinition>[
      CriterionDefinition(
        id: 'b24-c01-screenshot-integrity',
        title:
            'Screenshot paths, hashes, timestamps, and app commit SHA are present',
        requiredEvidenceFields: <String>['screenRows'],
        failureMessage: 'Screenshot integrity metadata is missing or stale.',
        requiredFix:
            'Recapture screenshots from the current app commit and record hashes, timestamps, device metadata, and app commit SHA.',
      ),
      CriterionDefinition(
        id: 'b24-c02-visible-text-and-copy-audit',
        title: 'Visible text exists and generic harness copy is absent',
        requiredEvidenceFields: <String>['screenRows'],
        failureMessage:
            'Visible text extraction is missing or generic harness copy remains.',
        requiredFix:
            'Extract visible text for each row and remove user-facing harness/implementation copy.',
      ),
    ],
  ),
  'production-ux-judge': JudgeSpec(
    toolId: 'production-ux-judge',
    phase: 'B25',
    description: 'Scores B25 production UX pass criteria from artifacts only.',
    criteria: <CriterionDefinition>[
      CriterionDefinition(
        id: 'b25-c01-no-blocker-major',
        title: 'No unresolved blocker or major findings',
        question:
            'Are there zero unresolved blocker or major findings in the current production UX evidence?',
        scope: 'evidence',
        requiredEvidenceFields: <String>[
          'unresolvedBlockerFindings',
          'unresolvedMajorFindings',
        ],
        failureMessage:
            'Unresolved blocker or major findings remain, or the counts are missing.',
        requiredFix:
            'Resolve blockers/majors, rerun review, and record zero unresolved blocker/major findings.',
      ),
      CriterionDefinition(
        id: 'b25-c02-blueprint-complete',
        title: 'Every community has a complete production UX blueprint',
        question:
            'Does every community or test app have a complete production UX blueprint that the review actually uses?',
        scope: 'holistic',
        requiredEvidenceFields: <String>['blueprintCoverage'],
        failureMessage: 'Blueprint coverage is missing or incomplete.',
        requiredFix:
            'Complete the per-community blueprint and judge every screen against it.',
      ),
      CriterionDefinition(
        id: 'b25-c03-production-grade-experience',
        title: 'Reviewer can state the experience feels production-grade',
        question:
            'Does the whole experience feel like a real production community app for the target users, not merely an implemented workflow harness?',
        scope: 'holistic',
        requiredEvidenceFields: <String>[
          'finalDecision',
          'holisticQuestionAnswers',
        ],
        failureMessage:
            'The evidence does not contain a defensible production-grade verdict.',
        requiredFix:
            'Run the independent screenshot-first review and record a production-grade verdict grounded in screen evidence.',
      ),
      CriterionDefinition(
        id: 'b25-c04-modern-intentional-ui',
        title: 'UI looks modern and intentionally designed',
        question:
            'Is the UI modern, easy to use, easy to navigate, and visually appealing for the target persona?',
        scope: 'holistic',
        requiredEvidenceFields: <String>[
          'screenRows',
          'holisticQuestionAnswers',
        ],
        failureMessage:
            'Screen rows do not prove modern hierarchy, spacing, and intentional design.',
        requiredFix:
            'Remediate visual hierarchy, spacing, typography, component quality, and recapture screenshots.',
      ),
      CriterionDefinition(
        id: 'b25-c05-community-content-ia',
        title:
            'Screens are organized around community content and jobs-to-be-done',
        question:
            'Is the overall information architecture organized around community content and real jobs-to-be-done instead of workflow lists or validation surfaces?',
        scope: 'holistic',
        requiredEvidenceFields: <String>[
          'screenRows',
          'holisticQuestionAnswers',
        ],
        failureMessage:
            'Primary screens still read as workflow lists, metadata, or validation surfaces.',
        requiredFix:
            'Rebuild home and primary screens around community content and user jobs.',
      ),
      CriterionDefinition(
        id: 'b25-c06-domain-native-primary-surfaces',
        title: 'Primary workflows use domain-specific product surfaces',
        question:
            'For every workflow and persona, is the primary UI a domain-native product surface rather than a generic card, checklist modal, or metadata page?',
        scope: 'workflow-persona',
        requiredEvidenceFields: <String>[
          'screenRows',
          'workflowPersonaScorecards',
        ],
        failureMessage:
            'A primary workflow is still generic-card/checklist/modal/metadata-only.',
        requiredFix:
            'Replace primary generic surfaces with domain-native product surfaces.',
      ),
      CriterionDefinition(
        id: 'b25-c07-screenshot-freshness',
        title: 'Every screen row has fresh screenshot evidence',
        question:
            'Does every reviewed screen row use fresh screenshot evidence from the app version under review, with hash, timestamp, device metadata, and app commit SHA?',
        scope: 'evidence',
        requiredEvidenceFields: <String>['screenRows'],
        failureMessage:
            'Screenshot path, hash, timestamp, device metadata, or app commit SHA is missing or stale.',
        requiredFix:
            'Relaunch the current app, recapture screenshots, and regenerate evidence.',
      ),
      CriterionDefinition(
        id: 'b25-c08-visible-text-specific-critique',
        title: 'Every row has visible text and screen-specific critique',
        question:
            'Does every holistic and workflow/persona review answer cite visible UI/text and provide a critique specific to that screenshot and user task?',
        scope: 'workflow-persona',
        requiredEvidenceFields: <String>[
          'screenRows',
          'workflowPersonaScorecards',
        ],
        failureMessage:
            'Visible text or non-boilerplate row critique is missing.',
        requiredFix:
            'Extract visible text and write a specific critique for each screenshot row.',
      ),
      CriterionDefinition(
        id: 'b25-c09-no-layout-production-defects',
        title: 'No blocking or major layout/content defects remain',
        question:
            'Does the visible UI avoid blocking or major overlap, clipping, crowding, default-scaffold, repeated-card, checklist-modal, and thin-content defects?',
        scope: 'holistic',
        requiredEvidenceFields: <String>['screenRows'],
        failureMessage:
            'The evidence still contains blocker/major overlap, clipping, scaffold, repeated-card, checklist, or thin-content findings.',
        requiredFix: 'Fix layout/content defects and rerun the review.',
      ),
      CriterionDefinition(
        id: 'b25-c10-full-screen-inventory',
        title: 'Every implemented screen/state appears in the matrix',
        question:
            'Does the screen inventory cover every user-facing screen, state, dialog, card, feed item, form, confirmation, error, empty state, persona variant, and action result?',
        scope: 'evidence',
        requiredEvidenceFields: <String>['screenRows'],
        failureMessage:
            'The evidence does not prove complete screen/state inventory coverage.',
        requiredFix:
            'Inventory every screen, dialog, card, feed item, form, state, persona variant, and action result.',
      ),
      CriterionDefinition(
        id: 'b25-c11-schema-v4-consistency',
        title: 'Schema v4 JSON is complete and internally consistent',
        question:
            'Is the schema v4 evidence complete and internally consistent across JSON, markdown review, matrix, remediation log, screenshots, and tracker?',
        scope: 'evidence',
        requiredEvidenceFields: <String>[
          'schemaVersion',
          'reviewStandardVersion',
          'screenRows',
        ],
        failureMessage:
            'The JSON is not schema v4 or is internally inconsistent.',
        requiredFix:
            'Regenerate schema v4 evidence and align JSON, markdown review, remediation log, and tracker.',
      ),
      CriterionDefinition(
        id: 'b25-c12-remediation-proof',
        title: 'Failed prior iterations have proof of remediation',
        question:
            'If any prior loop iteration failed, does the remediation log prove fixes, screenshot refresh, evidence regeneration, tests, commit SHA, and zero remaining blockers/majors?',
        scope: 'remediation',
        requiredEvidenceFields: <String>['remediationIterations'],
        failureMessage:
            'Prior failed iterations are not tied to fixes, screenshots, tests, and rerun result.',
        requiredFix:
            'Update the remediation loop with fixes, screenshot refresh, test commands, remaining findings, and iteration commit SHA.',
      ),
    ],
  ),
};

void runJudgeCli(List<String> args, String toolId) {
  final spec = specs[toolId];
  if (spec == null) {
    stderr.writeln('Unknown judge tool: $toolId');
    exit(64);
  }
  if (args.contains('--help') || args.isEmpty) {
    stdout.writeln(_usage(spec));
    return;
  }
  final inputPath = _argValue(args, '--input');
  if (inputPath == null) {
    stderr.writeln('Missing required --input <json>');
    stdout.writeln(_usage(spec));
    exit(64);
  }
  final outputPath = _argValue(args, '--output');
  final markdownPath = _argValue(args, '--markdown-output');
  final ticketsOutputPath = _argValue(args, '--tickets-output');
  final ticketsMarkdownPath = _argValue(args, '--tickets-markdown-output');
  final basePath = _argValue(args, '--base') ?? Directory.current.path;
  final evidence = _readJsonFile(inputPath);
  final result = judgeEvidence(spec, evidence, basePath: basePath);
  final encoded = const JsonEncoder.withIndent('  ').convert(result.toJson());
  if (outputPath == null) {
    stdout.writeln(encoded);
  } else {
    File(outputPath).writeAsStringSync('$encoded\n');
  }
  if (markdownPath != null) {
    File(markdownPath).writeAsStringSync(_toMarkdown(result));
  }
  final remediationTickets = _asMapList(result.extra['remediationTickets']);
  if (ticketsOutputPath != null) {
    final ticketsDocument = <String, Object?>{
      'schemaVersion': 1,
      'toolId': result.toolId,
      'status': result.status,
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'tickets': remediationTickets,
    };
    File(ticketsOutputPath).writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(ticketsDocument)}\n',
    );
  }
  if (ticketsMarkdownPath != null) {
    File(ticketsMarkdownPath).writeAsStringSync(
      _remediationTicketsMarkdown(
        toolId: result.toolId,
        status: result.status,
        tickets: remediationTickets,
      ),
    );
  }
  if (!result.passed) {
    stderr.writeln('${spec.toolId}: ${result.status}');
    for (final error in result.errors) {
      stderr.writeln('- $error');
    }
    exit(1);
  }
  stdout.writeln('${spec.toolId}: pass');
}

void runB25IterationScorecardCli(List<String> args) {
  if (args.contains('--help') || args.isEmpty) {
    stdout.writeln(_iterationScorecardUsage());
    return;
  }
  final reviewPath = _argValue(args, '--review');
  if (reviewPath == null) {
    stderr.writeln('Missing required --review <json>');
    stdout.writeln(_iterationScorecardUsage());
    exit(64);
  }
  final outputPath = _argValue(args, '--output');
  final markdownPath = _argValue(args, '--markdown-output');
  final judgePath = _argValue(args, '--judge');
  final previousPath = _argValue(args, '--previous');

  final review = _readJsonFile(reviewPath);
  final judge = judgePath == null ? null : _readJsonFile(judgePath);
  final previous = previousPath == null ? null : _readJsonFile(previousPath);
  final scorecard = buildB25IterationScorecard(
    review: review,
    judge: judge,
    previousScorecard: previous,
  );
  final encoded = const JsonEncoder.withIndent('  ').convert(scorecard);
  if (outputPath == null) {
    stdout.writeln(encoded);
  } else {
    File(outputPath).writeAsStringSync('$encoded\n');
  }
  if (markdownPath != null) {
    File(
      markdownPath,
    ).writeAsStringSync(_b25IterationScorecardMarkdown(scorecard));
  }
  stdout.writeln(
    'b25_iteration_scorecard: ${scorecard['status']} remainingBlockingMajor=${(scorecard['convergence'] as JsonMap)['remainingBlockingMajor']}',
  );
}

void runB25RemediationPlannerCli(List<String> args) {
  if (args.contains('--help') || args.isEmpty) {
    stdout.writeln(_remediationPlannerUsage());
    return;
  }
  final ticketsPath = _argValue(args, '--tickets');
  if (ticketsPath == null) {
    stderr.writeln('Missing required --tickets <json>');
    stdout.writeln(_remediationPlannerUsage());
    exit(64);
  }
  final outputPath = _argValue(args, '--output');
  final markdownPath = _argValue(args, '--markdown-output');
  final reviewPath = _argValue(args, '--review');
  final scorecardPath = _argValue(args, '--scorecard');

  final ticketsDocument = _readJsonFile(ticketsPath);
  final review = reviewPath == null ? null : _readJsonFile(reviewPath);
  final scorecard = scorecardPath == null ? null : _readJsonFile(scorecardPath);
  final plan = buildB25RemediationPlan(
    ticketsDocument: ticketsDocument,
    review: review,
    scorecard: scorecard,
    ticketsPath: ticketsPath,
  );
  final encoded = const JsonEncoder.withIndent('  ').convert(plan);
  if (outputPath == null) {
    stdout.writeln(encoded);
  } else {
    File(outputPath).writeAsStringSync('$encoded\n');
  }
  if (markdownPath != null) {
    File(markdownPath).writeAsStringSync(_b25RemediationPlanMarkdown(plan));
  }
  stdout.writeln(
    'b25_remediation_planner: batches=${_asMapList(plan['batches']).length} tickets=${_asMapList(plan['sourceTickets']).length}',
  );
}

void runB25EvidenceCollectorCli(List<String> args) {
  if (args.contains('--help') || args.isEmpty) {
    stdout.writeln(_evidenceCollectorUsage());
    return;
  }
  final evidenceRootPath = _argValue(args, '--evidence-root');
  final outputPath = _argValue(args, '--output');
  if (evidenceRootPath == null || outputPath == null) {
    stderr.writeln('Missing required --evidence-root <dir> or --output <json>');
    stdout.writeln(_evidenceCollectorUsage());
    exit(64);
  }
  final markdownPath = _argValue(args, '--markdown-output');
  final matrixPath = _argValue(args, '--matrix-output');
  final runId =
      _argValue(args, '--run-id') ??
      'b25-v4-${DateTime.now().toUtc().toIso8601String()}';
  final priorReviewPath = _argValue(args, '--prior-review');
  final repoRootPath =
      _argValue(args, '--repo-root') ?? Directory.current.parent.path;
  final review = collectB25Evidence(
    evidenceRootPath: evidenceRootPath,
    repoRootPath: repoRootPath,
    runId: runId,
    priorReview: priorReviewPath == null
        ? null
        : _readJsonFile(priorReviewPath),
  );
  final encoded = const JsonEncoder.withIndent('  ').convert(review);
  File(outputPath).writeAsStringSync('$encoded\n');
  if (markdownPath != null) {
    File(markdownPath).writeAsStringSync(_b25ReviewMarkdown(review));
  }
  if (matrixPath != null) {
    File(matrixPath).writeAsStringSync(_b25ScreenMatrixMarkdown(review));
  }
  stdout.writeln(
    'b25_evidence_collector: wrote ${_asMapList(review['screenRows']).length} screen rows to $outputPath',
  );
}

JsonMap collectB25Evidence({
  required String evidenceRootPath,
  required String repoRootPath,
  required String runId,
  JsonMap? priorReview,
}) {
  final evidenceRoot = Directory(evidenceRootPath);
  if (!evidenceRoot.existsSync()) {
    throw StateError('Evidence root does not exist: $evidenceRootPath');
  }
  final appCommit = _gitShortSha(repoRootPath);
  final manifests = _workflowManifestPaths(evidenceRoot, priorReview);
  final screenRows = <JsonMap>[];
  var rowIndex = 1;
  for (final manifestPath in manifests) {
    final manifest = _readJsonFile(manifestPath);
    final workflows = _asMapList(manifest['workflows']);
    for (final workflow in workflows) {
      final screenshotPaths = _asStringList(workflow['screenshotPaths']);
      final screenshotNames = _asStringList(workflow['screenshotNames']);
      for (var i = 0; i < screenshotPaths.length; i += 1) {
        final path = screenshotPaths[i];
        final file = File(_hostPath(path));
        final screenshotName = i < screenshotNames.length
            ? screenshotNames[i]
            : file.uri.pathSegments.last.replaceAll('.png', '');
        final relativePath = _relativePath(file.path, repoRootPath);
        final rowId =
            'b25-v4-row-${rowIndex.toString().padLeft(3, '0')}-${_slug(_asString(workflow['workflowId'], fallback: screenshotName))}-$i';
        screenRows.add(<String, Object?>{
          'rowId': rowId,
          'communityId': _asString(
            workflow['communityId'],
            fallback: _asString(workflow['appId']),
          ),
          'communityName': _asString(
            workflow['communityName'],
            fallback: _asString(workflow['appId']),
          ),
          'persona': _personaFromScreenshotName(screenshotName),
          'workflowId': _asString(workflow['workflowId']),
          'screenOrState': screenshotName,
          'screenType': _screenTypeFromScreenshotName(screenshotName),
          'screenshotPath': relativePath,
          'screenshotHash': file.existsSync() ? _fileSha256(file.path) : '',
          'screenshotCapturedAt': file.existsSync()
              ? file.lastModifiedSync().toUtc().toIso8601String()
              : '',
          'appCommitSha': appCommit,
          'deviceMetadata':
              '${_asString(workflow['emulatorName'])}; ${_asString(workflow['deviceClass'])}; ${_asString(workflow['apiLevel'])}',
          'visibleTextExtract': _asStringList(
            workflow['expectedAssertions'],
          ).join(' | '),
          'visibleTextExtractionSource':
              'workflow-ui-evidence expectedAssertions',
          'uiPatternClassification': 'pending-independent-review',
          'primarySurfaceType': 'pending-independent-review',
          'screenSpecificCritique':
              'Pending independent B25 UX critique for $screenshotName. Evidence collector captured screenshot metadata only.',
          'verdict': 'pending',
          'severity': 'major',
          'findingIds': <String>['B25-V4-REVIEW-PENDING'],
          'remediationIds': <String>[],
          'retestResult': 'pending-independent-review',
        });
        rowIndex += 1;
      }
    }
  }
  final priorRunIds = <String>[
    if (_asString(priorReview?['currentReviewRunId']).isNotEmpty)
      _asString(priorReview?['currentReviewRunId']),
    ..._asStringList(priorReview?['supersededReviewRunIds']),
  ];
  final blueprintCoverage = _asMapList(priorReview?['blueprintCoverage']);
  return <String, Object?>{
    'schemaVersion': 4,
    'reviewStandardVersion': 'b25-production-ux-v4',
    'currentReviewRunId': runId,
    'supersededReviewRunIds': priorRunIds.toSet().toList(),
    'status': 'needs-independent-review',
    'finalDecision': 'fail',
    'b25CanPass': false,
    'requiresRemediation': true,
    'requiresRerun': true,
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'reviewInputEvidence': <String, Object?>{
      'evidenceRoot': _relativePath(evidenceRoot.path, repoRootPath),
      'workflowEvidenceManifestPaths': manifests
          .map((path) => _relativePath(path, repoRootPath))
          .toList(),
      'workflowManifestCount': manifests.length,
      'screenshotCount': screenRows.length,
      'appCommitSha': appCommit,
    },
    'blueprintPath':
        'docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md',
    'screenMatrixPath':
        'docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md',
    'remediationLoopPath':
        'docs/Build Plan V2/Evidence/B25/product-ux-remediation-loop.md',
    'blueprintCoverage': blueprintCoverage,
    'screenRows': screenRows,
    'findings': <JsonMap>[
      <String, Object?>{
        'findingId': 'B25-V4-REVIEW-PENDING',
        'severity': 'major',
        'status': 'open',
        'title': 'B25 v4 independent UX review is pending',
        'summary':
            'Fresh screenshot metadata has been collected, but holistic direct-question review, workflow/persona direct-question review, and screen-specific UX critique have not been completed.',
        'requiredFix':
            'Run the Production UX Judge Agent against the collected screenshots and fill holisticQuestionAnswers, workflowPersonaScorecards, screen-specific critiques, findings, and remediation links.',
        'blocksPass': true,
      },
    ],
    'holisticQuestionAnswers': <JsonMap>[],
    'workflowPersonaScorecards': <JsonMap>[],
    'remediationIterations': <JsonMap>[
      <String, Object?>{
        'iteration': 1,
        'status': 'evidence-collected-review-pending',
        'screenshotsRefreshed': true,
        'remainingBlockerFindings': 0,
        'remainingMajorFindings': 1,
        'testsRun': <String>['workflow_ui_evidence_test.dart'],
        'commitSha': appCommit,
      },
    ],
    'unresolvedBlockerFindings': <String>[],
    'unresolvedMajorFindings': <String>['B25-V4-REVIEW-PENDING'],
    'ownerAcceptedMinorFindings': <String>[],
    'trackedPolish': <String>[],
    'iterationScorecardPath':
        'docs/Build Plan V2/Evidence/B25/b25-iteration-scorecard-latest.json',
  };
}

JsonMap buildB25IterationScorecard({
  required JsonMap review,
  JsonMap? judge,
  JsonMap? previousScorecard,
}) {
  final findings = _asMapList(review['findings']);
  final counts = _findingCounts(findings);
  final currentBlocking = _blockingFindingIds(findings);
  final previousBlocking = _previousBlockingFindingIds(previousScorecard);
  final resolvedThisPass = previousBlocking.difference(currentBlocking);
  final newThisPass = currentBlocking.difference(previousBlocking);
  final judgeSummary = _judgeSummary(judge);
  final blockingCriterionFailures = _asInt(
    judgeSummary['blockingCriterionFailures'],
  );
  final finalDecision = _asString(review['finalDecision']);
  final b25CanPass =
      review['b25CanPass'] == true &&
      finalDecision == 'pass' &&
      _asInt(counts['unresolvedCriticalBlocker']) == 0 &&
      _asInt(counts['unresolvedMajor']) == 0 &&
      (judge == null || _asString(judge['status']) == 'pass') &&
      blockingCriterionFailures == 0;
  final status = b25CanPass ? 'pass' : 'fail';
  final blockingFindings = findings
      .where((finding) => _isBlockingSeverity(finding) && !_isResolved(finding))
      .map(_findingSummary)
      .toList();
  final resolvedFindingsThisPass = findings
      .where((finding) => resolvedThisPass.contains(_findingId(finding)))
      .map(_findingSummary)
      .toList();
  final newFindingsThisPass = findings
      .where((finding) => newThisPass.contains(_findingId(finding)))
      .map(_findingSummary)
      .toList();

  return <String, Object?>{
    'schemaVersion': 1,
    'scorecardType': 'b25-iteration',
    'reviewRunId': _asString(review['currentReviewRunId'], fallback: 'unknown'),
    'reviewStandardVersion': _asString(review['reviewStandardVersion']),
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'status': status,
    'finalDecision': finalDecision,
    'b25CanPass': b25CanPass,
    'findingCounts': counts,
    'convergence': <String, Object?>{
      'previousReviewRunId': _asString(previousScorecard?['reviewRunId']),
      'resolvedCriticalBlockerThisPass': _countByIds(
        findings,
        resolvedThisPass,
        severity: 'critical-blocker',
      ),
      'resolvedMajorThisPass': _countByIds(
        findings,
        resolvedThisPass,
        severity: 'major',
      ),
      'newCriticalBlockerThisPass': _countByIds(
        findings,
        newThisPass,
        severity: 'critical-blocker',
      ),
      'newMajorThisPass': _countByIds(findings, newThisPass, severity: 'major'),
      'resolvedBlockingMajorThisPass': resolvedThisPass.length,
      'newBlockingMajorThisPass': newThisPass.length,
      'remainingBlockingMajor': currentBlocking.length,
    },
    'judgeSummary': judgeSummary,
    'blockingFindings': blockingFindings,
    'resolvedBlockingFindingsThisPass': resolvedFindingsThisPass,
    'newBlockingFindingsThisPass': newFindingsThisPass,
    'requiredNextAction': b25CanPass
        ? 'B25 can close after required gates pass and tracker/manifest are stamped.'
        : 'Create a remediation batch for unresolved blocker/major findings or failed judge criteria, then rebuild, recapture, regenerate evidence, rerun judge tools, and create the next iteration scorecard.',
  };
}

JsonMap buildB25RemediationPlan({
  required JsonMap ticketsDocument,
  JsonMap? review,
  JsonMap? scorecard,
  required String ticketsPath,
}) {
  final tickets = _asMapList(ticketsDocument['tickets']);
  final firstTicket = tickets.isEmpty ? null : tickets.first;
  final runId = _asString(
    review?['currentReviewRunId'] ??
        firstTicket?['reviewRunId'] ??
        scorecard?['reviewRunId'],
    fallback: 'unknown-review-run',
  );
  final batches = <JsonMap>[
    _remediationBatch(
      batchId: 'B25-RB-001-independent-review-evidence',
      title: 'Complete independent review evidence and critique',
      purpose:
          'Turn captured screenshots into complete independent UX review evidence before attempting UI remediation.',
      tickets: _ticketsForCriteria(tickets, <String>{
        'b25-c03-production-grade-experience',
        'b25-c04-modern-intentional-ui',
        'b25-c08-visible-text-specific-critique',
        'b25-c09-no-layout-production-defects',
      }),
      actions: <String>[
        'Fill holistic direct-question answers with screenshot-grounded yes/no/partial judgments.',
        'Fill every screen row with visible text and screen-specific critique.',
        'Fill workflow/persona scorecards for every reviewed workflow/persona pair.',
        'Keep reviewer context limited to screenshots, blueprint, evidence, and pass criteria.',
      ],
    ),
    _remediationBatch(
      batchId: 'B25-RB-002-domain-native-ux-remediation',
      title: 'Remediate domain-native IA and primary workflow surfaces',
      purpose:
          'Apply product UX fixes found by the independent critique so primary screens feel like production community surfaces.',
      tickets: _ticketsForCriteria(tickets, <String>{
        'b25-c05-community-content-ia',
        'b25-c06-domain-native-primary-surfaces',
        'b25-c04-modern-intentional-ui',
        'b25-c09-no-layout-production-defects',
      }),
      actions: <String>[
        'Replace any primary global workflow lists, metadata pages, checklist modals, or repeated generic cards with domain-native surfaces.',
        'Rebuild primary homes and flows around community content and jobs-to-be-done.',
        'Improve hierarchy, spacing, typography, component quality, navigation clarity, and mobile layout.',
        'Update copy/content so visible UI speaks to the target persona and task, not to validation mechanics.',
      ],
    ),
    _remediationBatch(
      batchId: 'B25-RB-003-recapture-rerun-closeout',
      title: 'Recapture evidence, rerun judges, and close resolved tickets',
      purpose:
          'Prove the remediation with fresh screenshots, scorecards, and a committed iteration boundary.',
      tickets: tickets,
      actions: <String>[
        'Rebuild and relaunch the Demo App on the reviewed emulator/device.',
        'Recapture affected screenshots with hashes, timestamps, device metadata, and app commit SHA.',
        'Regenerate B25 schema v4 review JSON, markdown review, screen matrix, remediation tickets, and iteration scorecard.',
        'Commit the full iteration before starting the next UX feedback loop.',
      ],
    ),
  ].where((batch) => _asMapList(batch['tickets']).isNotEmpty).toList();

  return <String, Object?>{
    'schemaVersion': 1,
    'planType': 'b25-remediation-plan',
    'reviewRunId': runId,
    'status': tickets.isEmpty ? 'no-open-tickets' : 'open',
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'sourceTicketsPath': ticketsPath,
    'sourceTicketCount': tickets.length,
    'sourceTickets': tickets
        .map(
          (ticket) => <String, Object?>{
            'ticketId': _asString(ticket['ticketId']),
            'sourceCriterionId': _asString(ticket['sourceCriterionId']),
            'severity': _asString(ticket['severity']),
            'status': _asString(ticket['status']),
            'title': _asString(ticket['title']),
          },
        )
        .toList(),
    'scorecardSummary': <String, Object?>{
      'status': _asString(scorecard?['status']),
      'remainingBlockingMajor': _asInt(
        (scorecard?['convergence'] as JsonMap?)?['remainingBlockingMajor'],
      ),
      'blockingCriterionFailures': _asInt(
        (scorecard?['judgeSummary'] as JsonMap?)?['blockingCriterionFailures'],
      ),
    },
    'batches': batches,
    'plannerRules': <String>[
      'Worker agents implement from remediation batches, not from optimistic summaries.',
      'The independent judge must rerun after each batch that changes UI, evidence, or critique.',
      'No next UX feedback loop starts until the current remediation iteration is committed.',
    ],
  };
}

JsonMap _remediationBatch({
  required String batchId,
  required String title,
  required String purpose,
  required List<JsonMap> tickets,
  required List<String> actions,
}) {
  final ticketIds = tickets
      .map((ticket) => _asString(ticket['ticketId']))
      .where((id) => id.isNotEmpty)
      .toList();
  final evidence = <String>{
    for (final ticket in tickets) ..._asStringList(ticket['affectedEvidence']),
    for (final ticket in tickets) ..._asStringList(ticket['evidenceToCollect']),
  }.toList();
  final acceptance = <String>{
    for (final ticket in tickets) ..._asStringList(ticket['acceptanceChecks']),
  }.toList();
  final rerun = <String>{
    for (final ticket in tickets) ..._asStringList(ticket['rerunCommands']),
  }.toList();
  final implementation = <String>{
    for (final ticket in tickets)
      ..._asStringList(ticket['implementationGuidance']),
  }.toList();
  return <String, Object?>{
    'batchId': batchId,
    'status': 'open',
    'title': title,
    'purpose': purpose,
    'ticketIds': ticketIds,
    'tickets': tickets,
    'workerActions': actions,
    'implementationGuidance': implementation,
    'evidenceToUpdate': evidence,
    'acceptanceChecks': acceptance,
    'rerunCommands': rerun,
    'commitBoundary':
        'Commit this remediation batch, refreshed evidence, judge outputs, scorecards, and tracker updates before the next UX feedback loop. If the committed pass still fails, the following pass starts by sending its tickets to the Remediation Planner.',
  };
}

List<JsonMap> _ticketsForCriteria(List<JsonMap> tickets, Set<String> criteria) {
  return tickets
      .where(
        (ticket) => criteria.contains(_asString(ticket['sourceCriterionId'])),
      )
      .toList();
}

JudgeResult judgeEvidence(
  JudgeSpec spec,
  JsonMap evidence, {
  required String basePath,
}) {
  final errors = <String>[];
  final warnings = <String>[];
  final criteria = <CriterionResult>[];
  for (final definition in spec.criteria) {
    final result = _evaluateCriterion(definition, evidence, basePath);
    criteria.add(result);
    if (result.blocksPass) {
      errors.add('${definition.id}: ${result.why}');
    }
  }
  _runCommonEvidenceChecks(spec.toolId, evidence, basePath, errors, warnings);
  final status = errors.isEmpty ? 'pass' : 'fail';
  return JudgeResult(
    toolId: spec.toolId,
    status: status,
    criteria: criteria,
    errors: errors,
    warnings: warnings,
    extra: _extraScorecards(spec, evidence, criteria),
  );
}

CriterionResult _evaluateCriterion(
  CriterionDefinition definition,
  JsonMap evidence,
  String basePath,
) {
  final explicit = _explicitCriterion(definition.id, evidence);
  if (explicit != null) {
    final score = _asInt(explicit['score']);
    final verdict = _asString(explicit['verdict']);
    final blocksPass =
        explicit['blocksPass'] == true ||
        verdict == 'fail' ||
        verdict == 'blocker' ||
        verdict == 'major' ||
        score < 80;
    return CriterionResult(
      id: definition.id,
      title: definition.title,
      question: _questionFor(definition),
      scope: definition.scope,
      score: score,
      verdict: blocksPass ? 'fail' : 'pass',
      blocksPass: blocksPass,
      why: _asString(
        explicit['why'],
        fallback: blocksPass ? definition.failureMessage : 'Criterion passed.',
      ),
      requiredFix: _asString(
        explicit['requiredFix'],
        fallback: blocksPass ? definition.requiredFix : 'None.',
      ),
      evidenceUsed: _asStringList(explicit['evidenceUsed']),
    );
  }

  final missing = definition.requiredEvidenceFields
      .where((field) => !_hasRequiredEvidence(field, evidence[field]))
      .toList();
  if (missing.isNotEmpty) {
    return CriterionResult(
      id: definition.id,
      title: definition.title,
      question: _questionFor(definition),
      scope: definition.scope,
      score: 0,
      verdict: 'fail',
      blocksPass: true,
      why:
          '${definition.failureMessage} Missing evidence fields: ${missing.join(', ')}.',
      requiredFix: definition.requiredFix,
    );
  }

  final derivedFailure = _derivedFailure(definition.id, evidence, basePath);
  if (derivedFailure != null) {
    return CriterionResult(
      id: definition.id,
      title: definition.title,
      question: _questionFor(definition),
      scope: definition.scope,
      score: derivedFailure.score,
      verdict: 'fail',
      blocksPass: true,
      why: derivedFailure.message,
      requiredFix: definition.requiredFix,
      evidenceUsed: derivedFailure.evidenceUsed,
    );
  }

  return CriterionResult(
    id: definition.id,
    title: definition.title,
    question: _questionFor(definition),
    scope: definition.scope,
    score: 100,
    verdict: 'pass',
    blocksPass: false,
    why:
        'Required evidence is present and no blocking derived failures were found.',
    requiredFix: 'None.',
  );
}

_DerivedFailure? _derivedFailure(
  String criterionId,
  JsonMap evidence,
  String basePath,
) {
  final screenRows = _asMapList(evidence['screenRows']);
  switch (criterionId) {
    case 'b11-c02-workflows-implemented':
      final workflowResults = _asMapList(evidence['workflowResults']);
      final failing = workflowResults.where((row) {
        return row['implemented'] != true ||
            row['validated'] != true ||
            row['complete'] != true;
      }).toList();
      if (workflowResults.isEmpty || failing.isNotEmpty) {
        return _DerivedFailure(
          score: 40,
          message:
              'Workflow results are empty or contain workflows that are not implemented, validated, and complete.',
        );
      }
      break;
    case 'b21-c02-domain-surface-planned':
      return _failOnGenericRows(_asMapList(evidence['contractRows']));
    case 'b22-c01-primary-surfaces-domain-native':
    case 'b25-c06-domain-native-primary-surfaces':
      return _failOnGenericRows(screenRows) ??
          _failOnWorkflowPersonaScorecards(evidence);
    case 'b25-c03-production-grade-experience':
    case 'b25-c04-modern-intentional-ui':
    case 'b25-c05-community-content-ia':
    case 'b25-c09-no-layout-production-defects':
      return _failOnDirectQuestionAnswers(
        _asMapList(evidence['holisticQuestionAnswers']),
        requiredScope: 'holistic',
      );
    case 'b23-c01-persona-state-coverage':
    case 'b23-c02-unauthorized-behavior':
      final rows = _asMapList(evidence['personaRows']);
      if (rows.isEmpty || rows.any((row) => row['verdict'] == 'fail')) {
        return _DerivedFailure(
          score: 50,
          message:
              'Persona rows are empty or include failed persona-state evidence.',
        );
      }
      break;
    case 'b24-c01-screenshot-integrity':
    case 'b25-c07-screenshot-freshness':
      return _failOnScreenshotIntegrity(screenRows, basePath);
    case 'b24-c02-visible-text-and-copy-audit':
    case 'b25-c08-visible-text-specific-critique':
      return _failOnVisibleTextOrBoilerplate(screenRows) ??
          _failOnWorkflowPersonaScorecards(evidence);
    case 'b25-c01-no-blocker-major':
      final blockers = _count(evidence['unresolvedBlockerFindings']);
      final majors = _count(evidence['unresolvedMajorFindings']);
      if (blockers > 0 || majors > 0) {
        return _DerivedFailure(
          score: 0,
          message:
              'Unresolved blocker/major counts are blocker=$blockers major=$majors.',
        );
      }
      break;
    case 'b25-c11-schema-v4-consistency':
      if (evidence['schemaVersion'] != 4 ||
          evidence['reviewStandardVersion'] != 'b25-production-ux-v4') {
        return _DerivedFailure(
          score: 0,
          message:
              'Expected schemaVersion=4 and reviewStandardVersion=b25-production-ux-v4.',
        );
      }
      break;
  }
  return null;
}

List<String> _workflowManifestPaths(
  Directory evidenceRoot,
  JsonMap? priorReview,
) {
  final aggregate = File(
    '${evidenceRoot.path}/B20/all-workflow-ui-evidence.json',
  );
  if (aggregate.existsSync()) {
    final manifest = _readJsonFile(aggregate.path);
    return _asStringList(
      manifest['workflowEvidenceManifestPaths'],
    ).map(_hostPath).where((path) => File(path).existsSync()).toList();
  }
  final paths = <String>[];
  for (final entity in evidenceRoot.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('workflow-ui-evidence.json')) {
      paths.add(entity.path);
    }
  }
  if (paths.isNotEmpty) {
    paths.sort();
    return paths;
  }
  return _asStringList(
    (priorReview?['reviewInputEvidence']
        as JsonMap?)?['workflowEvidenceManifestPaths'],
  ).map(_hostPath).where((path) => File(path).existsSync()).toList();
}

String _hostPath(String path) {
  if (Platform.isWindows && path.startsWith('/mnt/c/')) {
    return 'C:/${path.substring('/mnt/c/'.length)}'.replaceAll('/', r'\');
  }
  if (!Platform.isWindows && RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path)) {
    final drive = path.substring(0, 1).toLowerCase();
    final rest = path.substring(2).replaceAll(r'\', '/');
    return '/mnt/$drive$rest';
  }
  return path;
}

String _relativePath(String path, String repoRootPath) {
  final normalizedPath = _hostPath(path).replaceAll(r'\', '/');
  final normalizedRoot = _hostPath(repoRootPath).replaceAll(r'\', '/');
  if (normalizedPath.startsWith('$normalizedRoot/')) {
    return normalizedPath.substring(normalizedRoot.length + 1);
  }
  return normalizedPath;
}

String _gitShortSha(String repoRootPath) {
  final result = Process.runSync('git', <String>[
    '-C',
    _hostPath(repoRootPath),
    'rev-parse',
    '--short',
    'HEAD',
  ], runInShell: true);
  if (result.exitCode == 0) {
    return result.stdout.toString().trim();
  }
  return 'unknown';
}

String _fileSha256(String path) {
  final result = Process.runSync('sha256sum', <String>[_hostPath(path)]);
  if (result.exitCode == 0) {
    return result.stdout.toString().trim().split(RegExp(r'\s+')).first;
  }
  final certUtil = Process.runSync('certutil', <String>[
    '-hashfile',
    _hostPath(path),
    'SHA256',
  ], runInShell: true);
  if (certUtil.exitCode == 0) {
    final lines = certUtil.stdout
        .toString()
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(line))
        .toList();
    if (lines.isNotEmpty) {
      return lines.first.toLowerCase();
    }
  }
  return '';
}

String _personaFromScreenshotName(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('admin')) {
    return 'admin';
  }
  if (lower.contains('member')) {
    return 'member';
  }
  if (lower.contains('owner')) {
    return 'owner';
  }
  if (lower.contains('organizer')) {
    return 'organizer';
  }
  if (lower.contains('parent')) {
    return 'parent';
  }
  if (lower.contains('coach')) {
    return 'coach';
  }
  return 'persona-under-review';
}

String _screenTypeFromScreenshotName(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('start')) {
    return 'entry';
  }
  if (lower.contains('action') || lower.contains('dialog')) {
    return 'action-or-review';
  }
  if (lower.contains('complete') || lower.contains('received')) {
    return 'result';
  }
  if (lower.contains('ready')) {
    return 'receiver-state';
  }
  if (lower.contains('picker')) {
    return 'persona-picker';
  }
  return 'screen-state';
}

String _slug(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

JsonMap _findingCounts(List<JsonMap> findings) {
  var total = 0;
  var criticalBlocker = 0;
  var major = 0;
  var minor = 0;
  var polish = 0;
  var unresolvedCriticalBlocker = 0;
  var unresolvedMajor = 0;
  var resolvedCriticalBlocker = 0;
  var resolvedMajor = 0;
  for (final finding in findings) {
    total += 1;
    final severity = _normalizedSeverity(finding);
    final resolved = _isResolved(finding);
    if (severity == 'critical-blocker') {
      criticalBlocker += 1;
      if (resolved) {
        resolvedCriticalBlocker += 1;
      } else {
        unresolvedCriticalBlocker += 1;
      }
    } else if (severity == 'major') {
      major += 1;
      if (resolved) {
        resolvedMajor += 1;
      } else {
        unresolvedMajor += 1;
      }
    } else if (severity == 'minor') {
      minor += 1;
    } else if (severity == 'polish') {
      polish += 1;
    }
  }
  return <String, Object?>{
    'total': total,
    'criticalBlocker': criticalBlocker,
    'major': major,
    'minor': minor,
    'polish': polish,
    'unresolvedCriticalBlocker': unresolvedCriticalBlocker,
    'unresolvedMajor': unresolvedMajor,
    'unresolvedBlockingMajor': unresolvedCriticalBlocker + unresolvedMajor,
    'resolvedCriticalBlocker': resolvedCriticalBlocker,
    'resolvedMajor': resolvedMajor,
    'resolvedBlockingMajor': resolvedCriticalBlocker + resolvedMajor,
  };
}

JsonMap _judgeSummary(JsonMap? judge) {
  if (judge == null) {
    return <String, Object?>{
      'status': 'not-supplied',
      'totalCriteria': 0,
      'passedCriteria': 0,
      'failedCriteria': 0,
      'blockingCriterionFailures': 0,
      'holisticPass': false,
      'workflowPersonaPass': false,
    };
  }
  final criteria = _asMapList(judge['criteria']);
  final failed = criteria
      .where(
        (criterion) =>
            criterion['blocksPass'] == true ||
            _asString(criterion['verdict']) == 'fail',
      )
      .toList();
  final holistic = _asMapList(
    (judge['holisticProductScorecard'] as JsonMap?)?['criteria'],
  );
  final workflowPersona = _asMapList(judge['workflowPersonaCriteria']);
  return <String, Object?>{
    'status': _asString(judge['status']),
    'totalCriteria': criteria.length,
    'passedCriteria': criteria.length - failed.length,
    'failedCriteria': failed.length,
    'blockingCriterionFailures': failed.length,
    'holisticPass':
        holistic.isNotEmpty &&
        holistic.every((row) => row['blocksPass'] != true),
    'workflowPersonaPass':
        workflowPersona.isNotEmpty &&
        workflowPersona.every((row) => row['blocksPass'] != true),
  };
}

Set<String> _blockingFindingIds(List<JsonMap> findings) {
  return findings
      .where((finding) => _isBlockingSeverity(finding) && !_isResolved(finding))
      .map(_findingId)
      .where((id) => id.isNotEmpty)
      .toSet();
}

Set<String> _previousBlockingFindingIds(JsonMap? previousScorecard) {
  if (previousScorecard == null) {
    return <String>{};
  }
  return _asMapList(
    previousScorecard['blockingFindings'],
  ).map(_findingId).where((id) => id.isNotEmpty).toSet();
}

int _countByIds(
  List<JsonMap> findings,
  Set<String> ids, {
  required String severity,
}) {
  return findings
      .where((finding) => ids.contains(_findingId(finding)))
      .where((finding) => _normalizedSeverity(finding) == severity)
      .length;
}

bool _isBlockingSeverity(JsonMap finding) {
  final severity = _normalizedSeverity(finding);
  return severity == 'critical-blocker' || severity == 'major';
}

bool _isResolved(JsonMap finding) {
  final status = _asString(finding['status']).toLowerCase();
  return finding['resolved'] == true || status == 'resolved';
}

String _normalizedSeverity(JsonMap finding) {
  final severity = _asString(finding['severity']).toLowerCase();
  if (severity == 'critical' || severity == 'blocker') {
    return 'critical-blocker';
  }
  if (severity == 'major') {
    return 'major';
  }
  if (severity == 'minor') {
    return 'minor';
  }
  if (severity == 'polish') {
    return 'polish';
  }
  return severity;
}

String _findingId(JsonMap finding) {
  return _asString(
    finding['findingId'] ?? finding['id'] ?? finding['rowId'] ?? 'unknown',
  );
}

JsonMap _findingSummary(JsonMap finding) {
  return <String, Object?>{
    'findingId': _findingId(finding),
    'severity': _normalizedSeverity(finding),
    'status': _asString(finding['status']),
    'title': _asString(
      finding['title'] ?? finding['summary'] ?? finding['issue'],
    ),
    'requiredFix': _asString(
      finding['requiredFix'] ?? finding['recommendedFix'],
    ),
  };
}

String _b25IterationScorecardMarkdown(JsonMap scorecard) {
  final counts = scorecard['findingCounts'] as JsonMap;
  final convergence = scorecard['convergence'] as JsonMap;
  final judge = scorecard['judgeSummary'] as JsonMap;
  final buffer = StringBuffer()
    ..writeln('# B25 Iteration Scorecard')
    ..writeln()
    ..writeln('| Field | Value |')
    ..writeln('| --- | --- |')
    ..writeln(
      '| Review run | `${_escape(_asString(scorecard['reviewRunId']))}` |',
    )
    ..writeln('| Status | `${_escape(_asString(scorecard['status']))}` |')
    ..writeln(
      '| Final decision | `${_escape(_asString(scorecard['finalDecision']))}` |',
    )
    ..writeln('| B25 can pass | `${scorecard['b25CanPass']}` |')
    ..writeln(
      '| Remaining critical/blocker + major | ${convergence['remainingBlockingMajor']} |',
    )
    ..writeln(
      '| Resolved critical/blocker + major this pass | ${convergence['resolvedBlockingMajorThisPass']} |',
    )
    ..writeln(
      '| New critical/blocker + major this pass | ${convergence['newBlockingMajorThisPass']} |',
    )
    ..writeln()
    ..writeln('## Finding Counts')
    ..writeln()
    ..writeln('| Severity | Total | Unresolved | Resolved |')
    ..writeln('| --- | ---: | ---: | ---: |')
    ..writeln(
      '| Critical/blocker | ${counts['criticalBlocker']} | ${counts['unresolvedCriticalBlocker']} | ${counts['resolvedCriticalBlocker']} |',
    )
    ..writeln(
      '| Major | ${counts['major']} | ${counts['unresolvedMajor']} | ${counts['resolvedMajor']} |',
    )
    ..writeln('| Minor | ${counts['minor']} | n/a | n/a |')
    ..writeln('| Polish | ${counts['polish']} | n/a | n/a |')
    ..writeln()
    ..writeln('## Judge Summary')
    ..writeln()
    ..writeln('| Field | Value |')
    ..writeln('| --- | --- |')
    ..writeln('| Judge status | `${_escape(_asString(judge['status']))}` |')
    ..writeln(
      '| Criteria passed | ${judge['passedCriteria']} / ${judge['totalCriteria']} |',
    )
    ..writeln(
      '| Blocking criterion failures | ${judge['blockingCriterionFailures']} |',
    )
    ..writeln('| Holistic direct-question pass | `${judge['holisticPass']}` |')
    ..writeln(
      '| Workflow/persona direct-question pass | `${judge['workflowPersonaPass']}` |',
    )
    ..writeln()
    ..writeln('## Blocking Findings')
    ..writeln()
    ..writeln('| Finding | Severity | Status | Required fix |')
    ..writeln('| --- | --- | --- | --- |');
  final blocking = _asMapList(scorecard['blockingFindings']);
  if (blocking.isEmpty) {
    buffer.writeln('| None | n/a | n/a | n/a |');
  } else {
    for (final finding in blocking) {
      buffer.writeln(
        '| `${_escape(_findingId(finding))}` | ${_escape(_asString(finding['severity']))} | ${_escape(_asString(finding['status']))} | ${_escape(_asString(finding['requiredFix']))} |',
      );
    }
  }
  buffer
    ..writeln()
    ..writeln('## Required Next Action')
    ..writeln()
    ..writeln(_asString(scorecard['requiredNextAction']));
  return buffer.toString();
}

String _b25ReviewMarkdown(JsonMap review) {
  final rows = _asMapList(review['screenRows']);
  final findings = _asMapList(review['findings']);
  final buffer = StringBuffer()
    ..writeln('# B25 Independent Production UX Review')
    ..writeln()
    ..writeln(
      'Review run: `${_escape(_asString(review['currentReviewRunId']))}`',
    )
    ..writeln()
    ..writeln('Status: `${_escape(_asString(review['status']))}`')
    ..writeln()
    ..writeln(
      'Final decision: `${_escape(_asString(review['finalDecision']))}`',
    )
    ..writeln()
    ..writeln('Screen rows collected: ${rows.length}')
    ..writeln()
    ..writeln('## Current Findings')
    ..writeln()
    ..writeln('| Finding | Severity | Status | Required fix |')
    ..writeln('| --- | --- | --- | --- |');
  for (final finding in findings) {
    buffer.writeln(
      '| `${_escape(_findingId(finding))}` | ${_escape(_asString(finding['severity']))} | ${_escape(_asString(finding['status']))} | ${_escape(_asString(finding['requiredFix']))} |',
    );
  }
  buffer
    ..writeln()
    ..writeln('## Review Note')
    ..writeln()
    ..writeln(
      'This file was generated by the deterministic B25 evidence collector. It proves screenshot metadata capture, not product UX quality. The Production UX Judge Agent must fill screen-specific critiques, holistic direct-question answers, workflow/persona scorecards, findings, remediation links, and final pass/fail decision before B25 can close.',
    );
  return buffer.toString();
}

String _b25ScreenMatrixMarkdown(JsonMap review) {
  final rows = _asMapList(review['screenRows']);
  final buffer = StringBuffer()
    ..writeln('# B25 Product UX Screen Review Matrix')
    ..writeln()
    ..writeln(
      '| Row | Community | Persona | Workflow | Screen/state | Screenshot | Hash | Verdict | Critique |',
    )
    ..writeln('| --- | --- | --- | --- | --- | --- | --- | --- | --- |');
  for (final row in rows) {
    buffer.writeln(
      '| `${_escape(_asString(row['rowId']))}` | ${_escape(_asString(row['communityName']))} | ${_escape(_asString(row['persona']))} | `${_escape(_asString(row['workflowId']))}` | ${_escape(_asString(row['screenOrState']))} | ${_escape(_asString(row['screenshotPath']))} | `${_escape(_asString(row['screenshotHash']))}` | ${_escape(_asString(row['verdict']))} | ${_escape(_asString(row['screenSpecificCritique']))} |',
    );
  }
  return buffer.toString();
}

String _evidenceCollectorUsage() {
  return '''
b25_evidence_collector (B25)
Builds schema v4 B25 screenshot evidence from workflow UI evidence manifests.

Usage:
  dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root <docs/Build Plan V2/Evidence> --repo-root <repo-root> --run-id <id> --prior-review <old-review.json> --output <independent-production-ux-review.json> [--markdown-output <review.md>] [--matrix-output <matrix.md>]
''';
}

String _iterationScorecardUsage() {
  return '''
b25_iteration_scorecard (B25)
Summarizes one B25 review/remediation pass and tracks convergence.

Usage:
  dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review <independent-production-ux-review.json> [--judge <production-ux-criteria-scorecard.json>] [--previous <previous-scorecard.json>] [--output <scorecard.json>] [--markdown-output <scorecard.md>]
''';
}

String _remediationPlannerUsage() {
  return '''
b25_remediation_planner (B25)
Converts B25 remediation tickets into ordered worker-agent remediation batches.

Usage:
  dart run packages/tooling/loom_ux_judges/bin/b25_remediation_planner.dart --tickets <b25-remediation-tickets.json> [--review <independent-production-ux-review.json>] [--scorecard <b25-iteration-scorecard.json>] [--output <plan.json>] [--markdown-output <plan.md>]
''';
}

String _b25RemediationPlanMarkdown(JsonMap plan) {
  final batches = _asMapList(plan['batches']);
  final sourceTickets = _asMapList(plan['sourceTickets']);
  final scorecard = plan['scorecardSummary'] as JsonMap? ?? <String, Object?>{};
  final buffer = StringBuffer()
    ..writeln('# B25 Remediation Plan')
    ..writeln()
    ..writeln('| Field | Value |')
    ..writeln('| --- | --- |')
    ..writeln('| Review run | `${_escape(_asString(plan['reviewRunId']))}` |')
    ..writeln('| Status | `${_escape(_asString(plan['status']))}` |')
    ..writeln(
      '| Source tickets | `${_escape(_asString(plan['sourceTicketsPath']))}` |',
    )
    ..writeln('| Ticket count | ${plan['sourceTicketCount']} |')
    ..writeln(
      '| Scorecard status | `${_escape(_asString(scorecard['status']))}` |',
    )
    ..writeln(
      '| Remaining blocker/major | ${scorecard['remainingBlockingMajor']} |',
    )
    ..writeln(
      '| Blocking criteria failures | ${scorecard['blockingCriterionFailures']} |',
    )
    ..writeln()
    ..writeln('## Source Tickets')
    ..writeln()
    ..writeln('| Ticket | Source criterion | Severity | Status | Title |')
    ..writeln('| --- | --- | --- | --- | --- |');
  if (sourceTickets.isEmpty) {
    buffer.writeln('| None | n/a | n/a | n/a | n/a |');
  } else {
    for (final ticket in sourceTickets) {
      buffer.writeln(
        '| `${_escape(_asString(ticket['ticketId']))}` | `${_escape(_asString(ticket['sourceCriterionId']))}` | ${_escape(_asString(ticket['severity']))} | ${_escape(_asString(ticket['status']))} | ${_escape(_asString(ticket['title']))} |',
      );
    }
  }
  buffer.writeln();
  for (final batch in batches) {
    buffer
      ..writeln(
        '## ${_escape(_asString(batch['batchId']))}: ${_escape(_asString(batch['title']))}',
      )
      ..writeln()
      ..writeln(_escape(_asString(batch['purpose'])))
      ..writeln()
      ..writeln('| Field | Value |')
      ..writeln('| --- | --- |')
      ..writeln('| Status | ${_escape(_asString(batch['status']))} |')
      ..writeln(
        '| Ticket IDs | ${_escape(_asStringList(batch['ticketIds']).join(', '))} |',
      )
      ..writeln()
      ..writeln('### Worker Actions');
    for (final action in _asStringList(batch['workerActions'])) {
      buffer.writeln('- ${_escape(action)}');
    }
    buffer
      ..writeln()
      ..writeln('### Implementation Guidance');
    for (final guidance in _asStringList(batch['implementationGuidance'])) {
      buffer.writeln('- ${_escape(guidance)}');
    }
    buffer
      ..writeln()
      ..writeln('### Evidence To Update');
    for (final evidence in _asStringList(batch['evidenceToUpdate'])) {
      buffer.writeln('- ${_escape(evidence)}');
    }
    buffer
      ..writeln()
      ..writeln('### Acceptance Checks');
    for (final check in _asStringList(batch['acceptanceChecks'])) {
      buffer.writeln('- ${_escape(check)}');
    }
    buffer
      ..writeln()
      ..writeln('### Rerun Commands');
    for (final command in _asStringList(batch['rerunCommands'])) {
      buffer.writeln('- `${_escape(command)}`');
    }
    buffer
      ..writeln()
      ..writeln('### Commit Boundary')
      ..writeln()
      ..writeln(_escape(_asString(batch['commitBoundary'])))
      ..writeln();
  }
  final rules = _asStringList(plan['plannerRules']);
  if (rules.isNotEmpty) {
    buffer
      ..writeln('## Planner Rules')
      ..writeln();
    for (final rule in rules) {
      buffer.writeln('- ${_escape(rule)}');
    }
  }
  return buffer.toString();
}

JsonMap _extraScorecards(
  JudgeSpec spec,
  JsonMap evidence,
  List<CriterionResult> criteria,
) {
  if (spec.toolId != 'production-ux-judge') {
    return <String, Object?>{};
  }
  final remediationTickets = _b25RemediationTickets(evidence, criteria);
  return <String, Object?>{
    'holisticProductScorecard': <String, Object?>{
      'questions': _asMapList(evidence['holisticQuestionAnswers']),
      'criteria': criteria
          .where((criterion) => criterion.scope == 'holistic')
          .map((criterion) => criterion.toJson())
          .toList(),
    },
    'workflowPersonaScorecards': _asMapList(
      evidence['workflowPersonaScorecards'],
    ),
    'workflowPersonaCriteria': criteria
        .where((criterion) => criterion.scope == 'workflow-persona')
        .map((criterion) => criterion.toJson())
        .toList(),
    'evidenceIntegrityCriteria': criteria
        .where((criterion) => criterion.scope == 'evidence')
        .map((criterion) => criterion.toJson())
        .toList(),
    'remediationCriteria': criteria
        .where((criterion) => criterion.scope == 'remediation')
        .map((criterion) => criterion.toJson())
        .toList(),
    'remediationTickets': remediationTickets,
  };
}

List<JsonMap> _b25RemediationTickets(
  JsonMap evidence,
  List<CriterionResult> criteria,
) {
  final findings = _asMapList(evidence['findings']);
  final runId = _asString(
    evidence['currentReviewRunId'],
    fallback: 'unknown-review-run',
  );
  final allBlockingFindingIds = findings
      .where((finding) => _isBlockingSeverity(finding) && !_isResolved(finding))
      .map(_findingId)
      .where((id) => id.isNotEmpty)
      .toList();
  final tickets = <JsonMap>[];
  var index = 1;
  for (final criterion in criteria.where((criterion) => criterion.blocksPass)) {
    final relatedFindings = _relatedB25FindingIds(
      criterion,
      allBlockingFindingIds,
    );
    final ticketId =
        'B25-RT-${index.toString().padLeft(3, '0')}-${_slug(criterion.id)}';
    tickets.add(<String, Object?>{
      'ticketId': ticketId,
      'ticketSchemaVersion': 1,
      'phase': 'B25',
      'reviewRunId': runId,
      'status': 'open',
      'severity': 'major',
      'priority': 'P1',
      'sourceCriterionId': criterion.id,
      'sourceFindingIds': relatedFindings,
      'title': criterion.title,
      'directQuestion': criterion.question,
      'whyItFailed': criterion.why,
      'requiredOutcome': criterion.requiredFix,
      'affectedScope': _affectedScopeForB25Criterion(criterion.id, criterion),
      'problemStatement': _problemStatementForB25Criterion(criterion.id),
      'rootCauseHypothesis': _rootCauseForB25Criterion(criterion.id),
      'targetExperience': _targetExperienceForB25Criterion(criterion.id),
      'uxPrinciples': _uxPrinciplesForB25Criterion(criterion.id),
      'concreteImprovements': _improvementsForB25Criterion(criterion.id),
      'implementationGuidance': _implementationGuidanceForB25Criterion(
        criterion.id,
      ),
      'contentGuidance': _contentGuidanceForB25Criterion(criterion.id),
      'visualGuidance': _visualGuidanceForB25Criterion(criterion.id),
      'affectedEvidence': _affectedEvidenceForB25Criterion(criterion.id),
      'evidenceToCollect': _evidenceToCollectForB25Criterion(criterion.id),
      'acceptanceChecks': _acceptanceChecksForB25Criterion(criterion.id),
      'rerunCommands': _b25RerunCommands(),
      'nonGoals': _nonGoalsForB25Criterion(criterion.id),
      'commitBoundary':
          'Commit this remediation iteration, refreshed evidence, scorecards, tickets, and tracker updates before starting the next UX feedback loop.',
    });
    index += 1;
  }
  return tickets;
}

JsonMap _affectedScopeForB25Criterion(
  String criterionId,
  CriterionResult criterion,
) {
  return <String, Object?>{
    'scope': criterion.scope,
    'communities': criterion.scope == 'holistic'
        ? <String>['all reviewed communities/test apps']
        : <String>['communities referenced by failing workflow/persona rows'],
    'personas': criterion.scope == 'workflow-persona'
        ? <String>['personas referenced by failing workflow/persona rows']
        : <String>['all reviewed target personas'],
    'workflows': criterion.scope == 'workflow-persona'
        ? <String>['workflows referenced by failing scorecards']
        : <String>['all primary reviewed workflows'],
    'screenRows': criterion.evidenceUsed.isEmpty
        ? <String>['derive from independent-production-ux-review.json']
        : criterion.evidenceUsed,
    'screenshots': <String>[
      'fresh B25 screenshot rows linked from product-ux-screen-review-matrix.md',
    ],
  };
}

String _problemStatementForB25Criterion(String criterionId) {
  switch (criterionId) {
    case 'b25-c01-no-blocker-major':
      return 'B25 still has unresolved major production UX findings, so the app cannot be considered production-grade.';
    case 'b25-c03-production-grade-experience':
      return 'The evidence does not prove that target users experience the app as a real production community product rather than a workflow validation harness.';
    case 'b25-c04-modern-intentional-ui':
      return 'The evidence does not prove that the UI is modern, visually intentional, easy to navigate, and appealing for the target personas.';
    case 'b25-c05-community-content-ia':
      return 'The evidence does not prove that primary screens are organized around community content and jobs-to-be-done instead of workflow lists or validation surfaces.';
    case 'b25-c06-domain-native-primary-surfaces':
      return 'The evidence does not prove that each primary workflow/persona UI is a domain-native product surface rather than a generic card, checklist modal, or metadata page.';
    case 'b25-c08-visible-text-specific-critique':
      return 'The review rows and direct-question answers do not include enough visible text and screen-specific critique to guide implementation.';
    case 'b25-c09-no-layout-production-defects':
      return 'The evidence does not prove that the visible UI is free of major overlap, clipping, crowding, repeated-card, checklist-modal, or thin-content defects.';
    default:
      return 'The B25 production UX criterion failed and requires a concrete remediation plan.';
  }
}

String _rootCauseForB25Criterion(String criterionId) {
  switch (criterionId) {
    case 'b25-c01-no-blocker-major':
      return 'The review loop has not yet converted all blocking judge failures into completed, evidence-backed fixes.';
    case 'b25-c03-production-grade-experience':
      return 'The pass has evidence capture, but not a completed independent product-quality judgment grounded in screenshots.';
    case 'b25-c04-modern-intentional-ui':
      return 'The pass lacks screenshot-backed judgment of hierarchy, spacing, navigation clarity, component polish, and visual identity.';
    case 'b25-c05-community-content-ia':
      return 'The app may still be organized around implementation/workflow concepts instead of the mental model and daily jobs of community users.';
    case 'b25-c06-domain-native-primary-surfaces':
      return 'Primary workflow surfaces may still rely on generic repeated cards or validation-state UI instead of task-specific product screens.';
    case 'b25-c08-visible-text-specific-critique':
      return 'The judge output is not detailed enough; rows may be boilerplate or missing actual visible UI/text references.';
    case 'b25-c09-no-layout-production-defects':
      return 'The pass has not performed a screenshot-grounded defect audit for mobile layout, density, component quality, and content depth.';
    default:
      return 'The evidence does not yet satisfy the B25 production UX standard.';
  }
}

String _targetExperienceForB25Criterion(String criterionId) {
  switch (criterionId) {
    case 'b25-c03-production-grade-experience':
      return 'A target user should immediately understand the community, see relevant content, and complete meaningful tasks without recognizing the app as a test harness.';
    case 'b25-c04-modern-intentional-ui':
      return 'Screens should feel intentionally designed, polished, readable, well-spaced, navigable, and visually coherent on the reviewed device.';
    case 'b25-c05-community-content-ia':
      return 'The home and primary flows should lead with community-specific sections, content, and jobs-to-be-done rather than implementation categories.';
    case 'b25-c06-domain-native-primary-surfaces':
      return 'Each primary workflow should use the product surface a real app would use for that job, such as an event detail, feed item, donation flow, care form, review queue, thread, receipt, search result, export wizard, or transfer status screen.';
    case 'b25-c08-visible-text-specific-critique':
      return 'Every row should tell a worker exactly what was visible, why it did or did not work for the persona/task, and what must change.';
    case 'b25-c09-no-layout-production-defects':
      return 'The reviewed UI should have no major overlap, clipping, crowding, default scaffold feel, repeated-card primary UX, checklist-modal primary UX, or thin placeholder content.';
    case 'b25-c01-no-blocker-major':
    default:
      return 'The next B25 pass should show zero unresolved blocker/major findings and a scorecard that can close the phase.';
  }
}

List<String> _uxPrinciplesForB25Criterion(String criterionId) {
  switch (criterionId) {
    case 'b25-c03-production-grade-experience':
      return <String>[
        'Judge what the visible product proves, not what the implementation intended.',
        'Prioritize target-user comprehension, task completion, and product credibility.',
      ];
    case 'b25-c04-modern-intentional-ui':
      return <String>[
        'Clear visual hierarchy',
        'Predictable navigation',
        'Consistent spacing and component quality',
        'Modern mobile readability and touch targets',
      ];
    case 'b25-c05-community-content-ia':
      return <String>[
        'Community content first',
        'Jobs-to-be-done information architecture',
        'No global workflow-list primary UX',
      ];
    case 'b25-c06-domain-native-primary-surfaces':
      return <String>[
        'Primary surfaces must match the domain task',
        'Generic cards are acceptable only as secondary support, not primary workflow UI',
      ];
    case 'b25-c08-visible-text-specific-critique':
      return <String>[
        'Evidence must cite visible UI and text',
        'Critique must be screen-specific and non-boilerplate',
      ];
    case 'b25-c09-no-layout-production-defects':
      return <String>[
        'No major layout defects',
        'No thin placeholder content',
        'No checklist or scaffold feel on primary screens',
      ];
    default:
      return <String>['Resolve blocking UX evidence before closing B25'];
  }
}

List<String> _relatedB25FindingIds(
  CriterionResult criterion,
  List<String> allBlockingFindingIds,
) {
  switch (criterion.id) {
    case 'b25-c01-no-blocker-major':
      return allBlockingFindingIds;
    case 'b25-c03-production-grade-experience':
    case 'b25-c04-modern-intentional-ui':
    case 'b25-c05-community-content-ia':
    case 'b25-c09-no-layout-production-defects':
      return allBlockingFindingIds.contains('B25-HOLISTIC-UNPROVEN')
          ? <String>['B25-HOLISTIC-UNPROVEN']
          : allBlockingFindingIds;
    case 'b25-c06-domain-native-primary-surfaces':
    case 'b25-c08-visible-text-specific-critique':
      return allBlockingFindingIds.contains('B25-WORKFLOW-PERSONA-UNPROVEN')
          ? <String>['B25-WORKFLOW-PERSONA-UNPROVEN']
          : allBlockingFindingIds;
    default:
      return allBlockingFindingIds;
  }
}

List<String> _improvementsForB25Criterion(String criterionId) {
  switch (criterionId) {
    case 'b25-c01-no-blocker-major':
      return <String>[
        'Resolve every open blocker/major remediation ticket or downgrade only with owner acceptance and evidence.',
        'Update `findings`, unresolved finding arrays, remediation log, and iteration scorecard after fixes.',
        'Rerun the production UX judge and verify unresolved blocker/major counts are zero.',
      ];
    case 'b25-c03-production-grade-experience':
      return <String>[
        'Run a screenshot-first holistic review of the full community experience from the target-user perspective.',
        'Record direct yes/no answers that cite visible UI and explain whether the experience feels like a real production community app.',
        'Fix any whole-product issues where screens feel like validation harnesses, implementation summaries, or thin prototypes.',
      ];
    case 'b25-c04-modern-intentional-ui':
      return <String>[
        'Improve visual hierarchy, typography scale, spacing rhythm, component polish, and content grouping on primary screens.',
        'Ensure navigation and primary actions are obvious without reading implementation or workflow taxonomy.',
        'Recapture screenshots and cite visible evidence proving the UI is modern, easy to use, easy to navigate, and visually appealing.',
      ];
    case 'b25-c05-community-content-ia':
      return <String>[
        'Rework primary home/detail screens around community jobs-to-be-done and domain content.',
        'Replace any global workflow-list organization with sections such as announcements, events, dues, messages, documents, care requests, teams, or equivalent community-specific content.',
        'Update holistic answers and screen critiques to prove users see community tasks and content first.',
      ];
    case 'b25-c06-domain-native-primary-surfaces':
      return <String>[
        'Review every primary workflow/persona row and classify the visible UI as domain-native, secondary-supporting, or generic.',
        'Replace primary generic cards, checklist modals, metadata pages, or repeated card shells with domain-specific product surfaces.',
        'Create workflow/persona scorecards proving each primary workflow surface is domain-native for its target persona.',
      ];
    case 'b25-c08-visible-text-specific-critique':
      return <String>[
        'Extract visible text for every reviewed screenshot row.',
        'Write a non-boilerplate critique for every row that names visible UI elements, visible text, the persona, and the user task.',
        'Remove duplicated or reusable critiques; each critique must be specific enough that it cannot apply unchanged to an unrelated screen.',
      ];
    case 'b25-c09-no-layout-production-defects':
      return <String>[
        'Audit screenshots for overlap, clipping, crowding, default scaffold appearance, repeated-card primary UX, checklist-modal UX, and thin placeholder content.',
        'Fix any blocking or major layout/content defects and document before/after screenshot references.',
        'Update holistic direct-question answers with screenshot-backed proof that no major layout/content defects remain.',
      ];
    default:
      return <String>[
        'Fix the failed criterion, update evidence, rerun judge tools, and record the result in the iteration scorecard.',
      ];
  }
}

List<String> _affectedEvidenceForB25Criterion(String criterionId) {
  switch (criterionId) {
    case 'b25-c03-production-grade-experience':
    case 'b25-c04-modern-intentional-ui':
    case 'b25-c05-community-content-ia':
    case 'b25-c09-no-layout-production-defects':
      return <String>[
        'independent-production-ux-review.json holisticQuestionAnswers',
        'independent-production-ux-review.md holistic review summary',
        'product-ux-screen-review-matrix.md relevant screen rows',
        'production-ux-criteria-scorecard.json/.md',
      ];
    case 'b25-c06-domain-native-primary-surfaces':
    case 'b25-c08-visible-text-specific-critique':
      return <String>[
        'independent-production-ux-review.json workflowPersonaScorecards',
        'independent-production-ux-review.json screenRows',
        'product-ux-screen-review-matrix.md every workflow/persona row',
        'production-ux-criteria-scorecard.json/.md',
      ];
    case 'b25-c01-no-blocker-major':
      return <String>[
        'independent-production-ux-review.json findings',
        'product-ux-remediation-loop.md',
        'b25-iteration-scorecard-latest.json/.md',
        'Build Tracker.md B25 row and execution ledger',
      ];
    default:
      return <String>[
        'independent-production-ux-review.json',
        'production-ux-criteria-scorecard.json/.md',
      ];
  }
}

List<String> _implementationGuidanceForB25Criterion(String criterionId) {
  switch (criterionId) {
    case 'b25-c03-production-grade-experience':
    case 'b25-c04-modern-intentional-ui':
    case 'b25-c05-community-content-ia':
    case 'b25-c09-no-layout-production-defects':
      return <String>[
        'Inspect `apps/loom_communities_demo/lib` for the primary community home, shell, card, detail, and workflow surface widgets.',
        'Compare every change against `docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md` before coding.',
        'Update widget tests and B25 evidence expectations when user-facing hierarchy, copy, or surface structure changes.',
      ];
    case 'b25-c06-domain-native-primary-surfaces':
      return <String>[
        'Inspect workflow surface builders and replace primary generic card/checklist/modal renderers with task-specific widgets.',
        'Use B21 production UX contracts to choose the target surface type for each workflow/persona pair.',
        'Update screenshot evidence manifests so each replaced surface is captured at entry, action, and result states.',
      ];
    case 'b25-c08-visible-text-specific-critique':
      return <String>[
        'Update the B25 judge/review artifact, not only app UI code.',
        'Fill `screenRows[].visibleTextExtract`, `screenRows[].screenSpecificCritique`, `holisticQuestionAnswers`, and `workflowPersonaScorecards` with screenshot-specific content.',
        'Regenerate markdown review and matrix files from the updated schema v4 JSON.',
      ];
    case 'b25-c01-no-blocker-major':
    default:
      return <String>[
        'Use each open remediation ticket as the implementation backlog.',
        'Update review JSON, remediation log, scorecards, tracker, and screenshots together.',
      ];
  }
}

List<String> _contentGuidanceForB25Criterion(String criterionId) {
  switch (criterionId) {
    case 'b25-c05-community-content-ia':
      return <String>[
        'Lead screens with community-specific content: announcements, events, requests, payments, documents, messages, teams, facilities, or equivalent domain sections.',
        'Remove or demote labels that describe workflow categories, evidence, local routes, or implementation mechanics.',
        'Use realistic names, dates, amounts, authors, locations, status, receipts, and next steps where the workflow requires them.',
      ];
    case 'b25-c06-domain-native-primary-surfaces':
      return <String>[
        'Write copy that matches the task: RSVP, donate, publish, approve, submit, review, search, export, transfer, invite, or reply.',
        'Each primary surface should include the domain data a user needs to decide and act.',
      ];
    case 'b25-c08-visible-text-specific-critique':
      return <String>[
        'Quote or summarize visible labels, headings, section names, action text, and result copy in the critique.',
        'Explain why that visible content does or does not support the persona and task.',
      ];
    default:
      return <String>[
        'Replace placeholder, framework, workflow, evidence, or metadata language with user-facing product copy.',
        'Use content that helps the target persona understand status, options, consequences, and next steps.',
      ];
  }
}

List<String> _visualGuidanceForB25Criterion(String criterionId) {
  switch (criterionId) {
    case 'b25-c04-modern-intentional-ui':
      return <String>[
        'Check hierarchy: page title, section headings, primary actions, secondary metadata, and result states should be visually distinct.',
        'Check spacing and density on mobile: avoid crowded repeated cards, clipped text, overlapping controls, and weak touch targets.',
        'Use consistent component styling and avoid default scaffold or test-harness appearance.',
      ];
    case 'b25-c09-no-layout-production-defects':
      return <String>[
        'Audit screenshots for overlap, clipping, crowding, bottom control collisions, dense repeated cards, and modals that hide primary workflow context.',
        'Prefer stable responsive dimensions and scroll-safe spacing for cards, lists, dialogs, and floating actions.',
      ];
    case 'b25-c05-community-content-ia':
      return <String>[
        'Group content into scannable community sections with clear visual hierarchy.',
        'Make the primary path visible without requiring users to scan a global workflow list.',
      ];
    default:
      return <String>[
        'Use screenshot evidence to judge visual hierarchy, density, navigation clarity, and polish on the reviewed device.',
      ];
  }
}

List<String> _evidenceToCollectForB25Criterion(String criterionId) {
  switch (criterionId) {
    case 'b25-c03-production-grade-experience':
    case 'b25-c04-modern-intentional-ui':
    case 'b25-c05-community-content-ia':
    case 'b25-c09-no-layout-production-defects':
      return <String>[
        'Fresh holistic screenshots for primary homes, navigation, representative detail surfaces, and representative completion/result states.',
        '`holisticQuestionAnswers` with visible evidence, score, pass/fail answer, and specific rationale.',
        'Updated `production-ux-criteria-scorecard.json/.md` showing the criterion passes.',
      ];
    case 'b25-c06-domain-native-primary-surfaces':
      return <String>[
        'Fresh screenshots for every primary workflow/persona surface that was replaced or reviewed.',
        '`workflowPersonaScorecards` with task-specific domain-native surface judgments.',
        'Screen matrix rows showing `primarySurfaceType` or classification is not generic for primary workflows.',
      ];
    case 'b25-c08-visible-text-specific-critique':
      return <String>[
        'Visible text extracts for every reviewed row.',
        'Non-boilerplate screen-specific critique for every reviewed row.',
        'Updated markdown matrix matching the JSON evidence.',
      ];
    default:
      return <String>[
        'Updated review JSON, scorecards, screenshots, remediation log, and tracker evidence for the fixed criterion.',
      ];
  }
}

List<String> _acceptanceChecksForB25Criterion(String criterionId) {
  final shared = <String>[
    '`production_ux_judge.dart` has no blocking failure for this criterion.',
    '`b25_iteration_scorecard.dart` records the ticket as resolved or no longer blocking.',
    'Screenshots are refreshed and hashes/timestamps/app commit SHA match the reviewed app version.',
  ];
  switch (criterionId) {
    case 'b25-c03-production-grade-experience':
    case 'b25-c04-modern-intentional-ui':
    case 'b25-c05-community-content-ia':
    case 'b25-c09-no-layout-production-defects':
      return <String>[
        'Holistic direct-question answers are present, screenshot-backed, non-boilerplate, and pass.',
        ...shared,
      ];
    case 'b25-c06-domain-native-primary-surfaces':
    case 'b25-c08-visible-text-specific-critique':
      return <String>[
        'Every workflow/persona scorecard is present, screenshot-backed, non-boilerplate, and pass.',
        ...shared,
      ];
    case 'b25-c01-no-blocker-major':
      return <String>[
        'Unresolved blocker and major finding counts are both zero.',
        ...shared,
      ];
    default:
      return shared;
  }
}

List<String> _nonGoalsForB25Criterion(String criterionId) {
  switch (criterionId) {
    case 'b25-c03-production-grade-experience':
    case 'b25-c04-modern-intentional-ui':
      return <String>[
        'Do not pass based on implementation intent or code structure.',
        'Do not treat a captured screenshot as proof of product quality without direct-question answers.',
        'Do not fix only labels while leaving generic scaffold structure unchanged.',
      ];
    case 'b25-c05-community-content-ia':
    case 'b25-c06-domain-native-primary-surfaces':
      return <String>[
        'Do not rename a generic workflow card and call it domain-native.',
        'Do not keep global workflow lists as the primary home or primary workflow UI.',
        'Do not use metadata/settings pages as substitutes for task-specific product surfaces.',
      ];
    case 'b25-c08-visible-text-specific-critique':
      return <String>[
        'Do not reuse the same critique across unrelated screens.',
        'Do not write critique that could apply without seeing the screenshot.',
      ];
    default:
      return <String>[
        'Do not close the ticket without fresh evidence and a passing judge rerun.',
      ];
  }
}

List<String> _b25RerunCommands() {
  return <String>[
    'dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\\ Plan\\ V2/Evidence --repo-root .. --run-id <next-run-id> --prior-review ../docs/Build\\ Plan\\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\\ Plan\\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\\ Plan\\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\\ Plan\\ V2/Evidence/B25/product-ux-screen-review-matrix.md',
    'dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\\ Plan\\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\\ Plan\\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\\ Plan\\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\\ Plan\\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\\ Plan\\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md',
    'dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\\ Plan\\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\\ Plan\\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\\ Plan\\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\\ Plan\\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\\ Plan\\ V2/Evidence/B25/b25-iteration-scorecard-latest.md',
  ];
}

String _questionFor(CriterionDefinition definition) {
  return definition.question ?? definition.title;
}

_DerivedFailure? _failOnDirectQuestionAnswers(
  List<JsonMap> answers, {
  required String requiredScope,
}) {
  if (answers.isEmpty) {
    return _DerivedFailure(
      score: 0,
      message: 'No $requiredScope direct-question answers were supplied.',
    );
  }
  final failing = <String>[];
  for (final answer in answers) {
    final answerValue = _asString(answer['answer'] ?? answer['verdict']);
    final score = _asInt(answer['score']);
    final blocksPass = answer['blocksPass'] == true;
    final visibleEvidence = _asString(
      answer['visibleEvidence'] ?? answer['evidence'] ?? answer['visibleText'],
    );
    final question = _asString(answer['question']);
    final critique = _asString(
      answer['why'] ?? answer['whyItFails'] ?? answer['critique'],
    );
    final badAnswer =
        answerValue == 'no' ||
        answerValue == 'fail' ||
        answerValue == 'partial' ||
        blocksPass ||
        score < 80;
    if (question.isEmpty ||
        visibleEvidence.trim().length < 12 ||
        critique.trim().length < 12 ||
        badAnswer) {
      failing.add(_rowId(answer));
    }
  }
  if (failing.isNotEmpty) {
    return _DerivedFailure(
      score: 55,
      message:
          '$requiredScope direct-question answers are missing, weak, partial, or blocking: ${failing.join(', ')}.',
      evidenceUsed: failing,
    );
  }
  return null;
}

_DerivedFailure? _failOnWorkflowPersonaScorecards(JsonMap evidence) {
  final scorecards = _asMapList(evidence['workflowPersonaScorecards']);
  if (scorecards.isEmpty) {
    return _DerivedFailure(
      score: 0,
      message: 'No workflow/persona direct-question scorecards were supplied.',
    );
  }
  final failing = <String>[];
  for (final scorecard in scorecards) {
    final workflowId = _asString(scorecard['workflowId']);
    final persona = _asString(scorecard['persona']);
    final questions = _asMapList(scorecard['questions']);
    if (workflowId.isEmpty || persona.isEmpty || questions.isEmpty) {
      failing.add(_rowId(scorecard));
      continue;
    }
    final questionFailure = _failOnDirectQuestionAnswers(
      questions,
      requiredScope: 'workflow/persona $workflowId/$persona',
    );
    if (questionFailure != null) {
      failing.add('$workflowId/$persona');
    }
  }
  if (failing.isNotEmpty) {
    return _DerivedFailure(
      score: 55,
      message:
          'Workflow/persona direct-question scorecards have missing or blocking answers: ${failing.join(', ')}.',
      evidenceUsed: failing,
    );
  }
  return null;
}

_DerivedFailure? _failOnGenericRows(List<JsonMap> rows) {
  final genericValues = <String>{
    'generic-workflow-card',
    'checklist-modal',
    'metadata-page',
    'repeated-card-shell',
    'global-workflow-list',
  };
  final failing = <String>[];
  for (final row in rows) {
    final primary =
        row['primary'] == true ||
        row['primarySurface'] == true ||
        row['surfacePriority'] == 'primary' ||
        row['primarySurfaceType'] == 'primary';
    final classification = _asString(
      row['uiPatternClassification'] ??
          row['surfaceClassification'] ??
          row['domainSurface'],
    );
    if (primary && genericValues.contains(classification)) {
      failing.add(_rowId(row));
    }
  }
  if (rows.isEmpty || failing.isNotEmpty) {
    return _DerivedFailure(
      score: rows.isEmpty ? 0 : 55,
      message: rows.isEmpty
          ? 'No rows were supplied for surface classification.'
          : 'Primary generic surfaces found: ${failing.join(', ')}.',
      evidenceUsed: failing,
    );
  }
  return null;
}

_DerivedFailure? _failOnScreenshotIntegrity(
  List<JsonMap> rows,
  String basePath,
) {
  final failing = <String>[];
  for (final row in rows) {
    final path = _asString(row['screenshotPath'] ?? row['screenshot']);
    final hash = _asString(row['screenshotHash']);
    final capturedAt = _asString(
      row['screenshotCapturedAt'] ?? row['capturedAt'],
    );
    final commit = _asString(row['appCommitSha']);
    final device = _asString(
      row['device'] ?? row['emulatorDevice'] ?? row['deviceMetadata'],
    );
    if (path.isEmpty ||
        hash.isEmpty ||
        capturedAt.isEmpty ||
        commit.isEmpty ||
        device.isEmpty ||
        !_fileExists(basePath, path)) {
      failing.add(_rowId(row));
    }
  }
  if (rows.isEmpty || failing.isNotEmpty) {
    return _DerivedFailure(
      score: rows.isEmpty ? 0 : 60,
      message: rows.isEmpty
          ? 'No screen rows were supplied for screenshot integrity.'
          : 'Rows with missing or invalid screenshot metadata: ${failing.join(', ')}.',
      evidenceUsed: failing,
    );
  }
  return null;
}

_DerivedFailure? _failOnVisibleTextOrBoilerplate(List<JsonMap> rows) {
  final failing = <String>[];
  final critiques = <String, List<String>>{};
  for (final row in rows) {
    final rowId = _rowId(row);
    final visibleText = _asString(
      row['visibleTextExtract'] ?? row['visibleText'],
    );
    final critique = _asString(
      row['screenSpecificCritique'] ?? row['critique'],
    );
    if (visibleText.trim().length < 8 || critique.trim().length < 24) {
      failing.add(rowId);
    }
    final normalized = critique
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isNotEmpty) {
      critiques.putIfAbsent(normalized, () => <String>[]).add(rowId);
    }
  }
  for (final entry in critiques.entries) {
    if (entry.value.length > 1) {
      failing.addAll(entry.value.map((id) => '$id duplicate-critique'));
    }
  }
  if (rows.isEmpty || failing.isNotEmpty) {
    return _DerivedFailure(
      score: rows.isEmpty ? 0 : 55,
      message: rows.isEmpty
          ? 'No screen rows were supplied for visible-text/critique audit.'
          : 'Rows with missing visible text, weak critique, or duplicate critique: ${failing.join(', ')}.',
      evidenceUsed: failing,
    );
  }
  return null;
}

void _runCommonEvidenceChecks(
  String toolId,
  JsonMap evidence,
  String basePath,
  List<String> errors,
  List<String> warnings,
) {
  if (toolId == 'production-ux-judge') {
    final finalDecision = _asString(evidence['finalDecision']);
    if (finalDecision.isNotEmpty && finalDecision != 'pass') {
      errors.add('finalDecision is $finalDecision, not pass.');
    }
    final holisticFailure = _failOnDirectQuestionAnswers(
      _asMapList(evidence['holisticQuestionAnswers']),
      requiredScope: 'holistic',
    );
    if (holisticFailure != null) {
      errors.add('holistic direct-question pass: ${holisticFailure.message}');
    }
    final workflowPersonaFailure = _failOnWorkflowPersonaScorecards(evidence);
    if (workflowPersonaFailure != null) {
      errors.add(
        'workflow/persona direct-question pass: ${workflowPersonaFailure.message}',
      );
    }
  }
  final findings = _asMapList(evidence['findings']);
  for (final finding in findings) {
    final severity = _asString(finding['severity']);
    final unresolved =
        finding['resolved'] != true && finding['status'] != 'resolved';
    if (unresolved && (severity == 'blocker' || severity == 'major')) {
      errors.add('Unresolved $severity finding: ${_rowId(finding)}.');
    }
  }
  final unknownKeys = evidence.keys
      .where((key) => key.startsWith('TODO'))
      .toList();
  if (unknownKeys.isNotEmpty) {
    warnings.add('Evidence contains TODO keys: ${unknownKeys.join(', ')}.');
  }
}

JsonMap _readJsonFile(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Input not found: $path');
    exit(66);
  }
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! JsonMap) {
    stderr.writeln('Input must be a JSON object: $path');
    exit(65);
  }
  return decoded;
}

JsonMap? _explicitCriterion(String id, JsonMap evidence) {
  final criteria = evidence['criteriaScores'] ?? evidence['criteria'];
  for (final row in _asMapList(criteria)) {
    if (row['criterionId'] == id || row['id'] == id) {
      return row;
    }
  }
  return null;
}

String _usage(JudgeSpec spec) {
  return '''
${spec.toolId} (${spec.phase})
${spec.description}

Usage:
  dart run packages/tooling/loom_ux_judges/bin/${spec.toolId.replaceAll('-', '_')}.dart --input <evidence.json> [--base <repo-root>] [--output <scorecard.json>] [--markdown-output <scorecard.md>] [--tickets-output <tickets.json>] [--tickets-markdown-output <tickets.md>]
''';
}

String _remediationTicketsMarkdown({
  required String toolId,
  required String status,
  required List<JsonMap> tickets,
}) {
  final buffer = StringBuffer()
    ..writeln('# Remediation Tickets')
    ..writeln()
    ..writeln('| Field | Value |')
    ..writeln('| --- | --- |')
    ..writeln('| Tool | `${_escape(toolId)}` |')
    ..writeln('| Status | `${_escape(status)}` |')
    ..writeln('| Open tickets | ${tickets.length} |');
  if (tickets.isEmpty) {
    buffer
      ..writeln()
      ..writeln('No remediation tickets.');
    return buffer.toString();
  }
  for (final ticket in tickets) {
    buffer
      ..writeln()
      ..writeln('## ${_escape(_asString(ticket['ticketId']))}')
      ..writeln()
      ..writeln('| Field | Value |')
      ..writeln('| --- | --- |')
      ..writeln('| Severity | ${_escape(_asString(ticket['severity']))} |')
      ..writeln('| Priority | ${_escape(_asString(ticket['priority']))} |')
      ..writeln('| Status | ${_escape(_asString(ticket['status']))} |')
      ..writeln(
        '| Review run | `${_escape(_asString(ticket['reviewRunId']))}` |',
      )
      ..writeln(
        '| Source criterion | `${_escape(_asString(ticket['sourceCriterionId']))}` |',
      )
      ..writeln(
        '| Source findings | ${_escape(_asStringList(ticket['sourceFindingIds']).join(', '))} |',
      )
      ..writeln('| Title | ${_escape(_asString(ticket['title']))} |')
      ..writeln(
        '| Direct question | ${_escape(_asString(ticket['directQuestion']))} |',
      )
      ..writeln(
        '| Why it failed | ${_escape(_asString(ticket['whyItFailed']))} |',
      )
      ..writeln(
        '| Required outcome | ${_escape(_asString(ticket['requiredOutcome']))} |',
      )
      ..writeln()
      ..writeln('### Problem Statement')
      ..writeln()
      ..writeln(_escape(_asString(ticket['problemStatement'])))
      ..writeln()
      ..writeln('### Root Cause Hypothesis')
      ..writeln()
      ..writeln(_escape(_asString(ticket['rootCauseHypothesis'])))
      ..writeln()
      ..writeln('### Target Experience')
      ..writeln()
      ..writeln(_escape(_asString(ticket['targetExperience'])))
      ..writeln()
      ..writeln('### UX Principles');
    for (final principle in _asStringList(ticket['uxPrinciples'])) {
      buffer.writeln('- ${_escape(principle)}');
    }
    buffer
      ..writeln()
      ..writeln('### Concrete Improvements');
    for (final improvement in _asStringList(ticket['concreteImprovements'])) {
      buffer.writeln('- ${_escape(improvement)}');
    }
    buffer
      ..writeln()
      ..writeln('### Implementation Guidance');
    for (final guidance in _asStringList(ticket['implementationGuidance'])) {
      buffer.writeln('- ${_escape(guidance)}');
    }
    buffer
      ..writeln()
      ..writeln('### Content Guidance');
    for (final guidance in _asStringList(ticket['contentGuidance'])) {
      buffer.writeln('- ${_escape(guidance)}');
    }
    buffer
      ..writeln()
      ..writeln('### Visual Guidance');
    for (final guidance in _asStringList(ticket['visualGuidance'])) {
      buffer.writeln('- ${_escape(guidance)}');
    }
    buffer
      ..writeln()
      ..writeln('### Affected Evidence');
    for (final artifact in _asStringList(ticket['affectedEvidence'])) {
      buffer.writeln('- `${_escape(artifact)}`');
    }
    buffer
      ..writeln()
      ..writeln('### Evidence To Collect');
    for (final artifact in _asStringList(ticket['evidenceToCollect'])) {
      buffer.writeln('- ${_escape(artifact)}');
    }
    buffer
      ..writeln()
      ..writeln('### Acceptance Checks');
    for (final check in _asStringList(ticket['acceptanceChecks'])) {
      buffer.writeln('- ${_escape(check)}');
    }
    buffer
      ..writeln()
      ..writeln('### Non-Goals');
    for (final nonGoal in _asStringList(ticket['nonGoals'])) {
      buffer.writeln('- ${_escape(nonGoal)}');
    }
    buffer
      ..writeln()
      ..writeln('### Commit Boundary')
      ..writeln()
      ..writeln(_escape(_asString(ticket['commitBoundary'])))
      ..writeln()
      ..writeln('### Rerun Commands');
    for (final command in _asStringList(ticket['rerunCommands'])) {
      buffer.writeln('- `${_escape(command)}`');
    }
  }
  return buffer.toString();
}

String _toMarkdown(JudgeResult result) {
  final buffer = StringBuffer()
    ..writeln('# ${result.toolId} Scorecard')
    ..writeln()
    ..writeln('Status: `${result.status}`')
    ..writeln()
    ..writeln(
      '| Criterion | Scope | Direct question | Score | Verdict | Blocks pass | Why | Required fix |',
    )
    ..writeln('| --- | --- | --- | ---: | --- | --- | --- | --- |');
  for (final criterion in result.criteria) {
    buffer.writeln(
      '| `${criterion.id}` ${_escape(criterion.title)} | ${criterion.scope} | ${_escape(criterion.question)} | ${criterion.score} | ${criterion.verdict} | ${criterion.blocksPass} | ${_escape(criterion.why)} | ${_escape(criterion.requiredFix)} |',
    );
  }
  if (result.errors.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('## Errors');
    for (final error in result.errors) {
      buffer.writeln('- ${_escape(error)}');
    }
  }
  final remediationTickets = _asMapList(result.extra['remediationTickets']);
  if (remediationTickets.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('## Remediation Tickets')
      ..writeln()
      ..writeln(
        '| Ticket | Severity | Source | Title | Concrete improvements | Acceptance checks |',
      )
      ..writeln('| --- | --- | --- | --- | --- | --- |');
    for (final ticket in remediationTickets) {
      final improvements = _asStringList(
        ticket['concreteImprovements'],
      ).map((item) => '- $item').join('<br>');
      final checks = _asStringList(
        ticket['acceptanceChecks'],
      ).map((item) => '- $item').join('<br>');
      buffer.writeln(
        '| `${_escape(_asString(ticket['ticketId']))}` | ${_escape(_asString(ticket['severity']))} | `${_escape(_asString(ticket['sourceCriterionId']))}` | ${_escape(_asString(ticket['title']))} | ${_escape(improvements)} | ${_escape(checks)} |',
      );
    }
  }
  if (result.warnings.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('## Warnings');
    for (final warning in result.warnings) {
      buffer.writeln('- ${_escape(warning)}');
    }
  }
  return buffer.toString();
}

String _escape(String value) {
  return value.replaceAll('|', r'\|').replaceAll('\n', ' ');
}

String? _argValue(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index == -1 || index + 1 >= args.length) {
    return null;
  }
  return args[index + 1];
}

bool _hasUsefulValue(Object? value) {
  if (value == null) {
    return false;
  }
  if (value is String) {
    return value.trim().isNotEmpty;
  }
  if (value is Iterable) {
    return value.isNotEmpty;
  }
  if (value is Map) {
    return value.isNotEmpty;
  }
  return true;
}

bool _hasRequiredEvidence(String field, Object? value) {
  if (field == 'unresolvedBlockerFindings' ||
      field == 'unresolvedMajorFindings' ||
      field == 'ownerAcceptedMinorFindings' ||
      field == 'trackedPolish') {
    return value != null;
  }
  return _hasUsefulValue(value);
}

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

String _asString(Object? value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  if (value is String) {
    return value;
  }
  return value.toString();
}

List<String> _asStringList(Object? value) {
  if (value is List) {
    return value
        .map((item) => _asString(item))
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return <String>[];
}

List<JsonMap> _asMapList(Object? value) {
  if (value is List) {
    return value.whereType<JsonMap>().toList();
  }
  return <JsonMap>[];
}

int _count(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  if (value is List) {
    return value.length;
  }
  if (value == null) {
    return -1;
  }
  return int.tryParse(value.toString()) ?? -1;
}

String _rowId(JsonMap row) {
  return _asString(
    row['rowId'] ??
        row['findingId'] ??
        row['workflowId'] ??
        row['personaId'] ??
        row['id'] ??
        'unknown-row',
  );
}

bool _fileExists(String basePath, String path) {
  final direct = File(path);
  if (direct.existsSync()) {
    return true;
  }
  return File('$basePath/$path').existsSync();
}

class _DerivedFailure {
  _DerivedFailure({
    required this.score,
    required this.message,
    this.evidenceUsed = const <String>[],
  });

  final int score;
  final String message;
  final List<String> evidenceUsed;
}
