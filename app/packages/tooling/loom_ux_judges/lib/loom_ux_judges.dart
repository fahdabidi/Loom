// ignore_for_file: prefer_const_constructors

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

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

void runB25WorkflowPersonaCoverageCollectorCli(List<String> args) {
  if (args.contains('--help') || args.isEmpty) {
    stdout.writeln(_coverageCollectorUsage());
    return;
  }
  final inputPath = _argValue(args, '--input');
  final outputPath = _argValue(args, '--output');
  if (inputPath == null || outputPath == null) {
    stderr.writeln('Missing required --input <json> or --output <json>');
    stdout.writeln(_coverageCollectorUsage());
    exit(64);
  }
  final markdownPath = _argValue(args, '--markdown-output');
  final review = _readJsonFile(inputPath);
  final enriched = buildB25WorkflowPersonaCoverage(review);
  final encoded = const JsonEncoder.withIndent('  ').convert(enriched);
  File(outputPath).writeAsStringSync('$encoded\n');
  if (markdownPath != null) {
    File(
      markdownPath,
    ).writeAsStringSync(_b25WorkflowPersonaCoverageMarkdown(enriched));
  }
  final summary = enriched['workflowPersonaCoverageSummary'] as JsonMap;
  stdout.writeln(
    'b25_workflow_persona_coverage_collector: status=${summary['status']} coverageRows=${summary['coverageRowCount']} failing=${summary['failingCoverageRowCount']}',
  );
}

void runB25VisualInspectionAuditorCli(List<String> args) {
  if (args.contains('--help') || args.isEmpty) {
    stdout.writeln(_visualInspectionAuditorUsage());
    return;
  }
  final inputPath = _argValue(args, '--input');
  final outputPath = _argValue(args, '--output');
  if (inputPath == null || outputPath == null) {
    stderr.writeln('Missing required --input <json> or --output <json>');
    stdout.writeln(_visualInspectionAuditorUsage());
    exit(64);
  }
  final markdownPath = _argValue(args, '--markdown-output');
  final audited = buildB25VisualInspectionAudit(_readJsonFile(inputPath));
  final encoded = const JsonEncoder.withIndent('  ').convert(audited);
  File(outputPath).writeAsStringSync('$encoded\n');
  if (markdownPath != null) {
    File(markdownPath).writeAsStringSync(_b25VisualInspectionMarkdown(audited));
  }
  final summary = audited['visualInspectionSummary'] as JsonMap;
  stdout.writeln(
    'b25_visual_inspection_auditor: status=${summary['status']} rows=${summary['screenRowCount']} failing=${summary['failingScreenRowCount']}',
  );
  if (summary['status'] == 'fail') {
    exit(1);
  }
}

void runB25IndependentUxJudgeCli(List<String> args) {
  if (args.contains('--help') || args.isEmpty) {
    stdout.writeln(_independentUxJudgeUsage());
    return;
  }
  final inputPath = _argValue(args, '--input');
  final outputPath = _argValue(args, '--output');
  if (inputPath == null || outputPath == null) {
    stderr.writeln('Missing required --input <json> or --output <json>');
    stdout.writeln(_independentUxJudgeUsage());
    exit(64);
  }
  final markdownPath = _argValue(args, '--markdown-output');
  final matrixPath = _argValue(args, '--matrix-output');
  final judged = buildB25IndependentUxReview(_readJsonFile(inputPath));
  final encoded = const JsonEncoder.withIndent('  ').convert(judged);
  File(outputPath).writeAsStringSync('$encoded\n');
  if (markdownPath != null) {
    File(markdownPath).writeAsStringSync(_b25ReviewMarkdown(judged));
  }
  if (matrixPath != null) {
    File(matrixPath).writeAsStringSync(_b25ScreenMatrixMarkdown(judged));
  }
  stdout.writeln(
    'b25_independent_ux_judge: ${judged['finalDecision']} findings=${_asMapList(judged['findings']).length} workflowPersonaScorecards=${_asMapList(judged['workflowPersonaScorecards']).length}',
  );
  if (judged['finalDecision'] != 'pass') {
    exit(1);
  }
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
      final workflowId = _asString(workflow['workflowId']);
      if (_isNonProductionEvidenceWorkflow(workflowId)) {
        continue;
      }
      final screenshotPaths = _asStringList(workflow['screenshotPaths']);
      final screenshotNames = _asStringList(workflow['screenshotNames']);
      final screenshotVisibleTexts = _asStringList(
        workflow['screenshotVisibleTexts'],
      );
      for (var i = 0; i < screenshotPaths.length; i += 1) {
        final path = screenshotPaths[i];
        final file = File(_hostPath(path));
        final screenshotName = i < screenshotNames.length
            ? screenshotNames[i]
            : file.uri.pathSegments.last.replaceAll('.png', '');
        final relativePath = _relativePath(file.path, repoRootPath);
        final rowId =
            'b25-v4-row-${rowIndex.toString().padLeft(3, '0')}-${_slug(_asString(workflow['workflowId'], fallback: screenshotName))}-$i';
        final communityId = _asString(
          workflow['communityId'],
          fallback: _asString(workflow['appId']),
        );
        final visibleText =
            i < screenshotVisibleTexts.length &&
                screenshotVisibleTexts[i].trim().isNotEmpty
            ? screenshotVisibleTexts[i].trim()
            : _asStringList(workflow['expectedAssertions']).join(' | ');
        final visibleTextSource =
            i < screenshotVisibleTexts.length &&
                screenshotVisibleTexts[i].trim().isNotEmpty
            ? 'screenshot-visible-text'
            : 'manual-visible-text-review';
        final persona = _personaForEvidence(
          workflowId: workflowId,
          communityId: communityId,
          screenshotName: screenshotName,
        );
        screenRows.add(<String, Object?>{
          'rowId': rowId,
          'communityId': communityId,
          'communityName': _asString(
            workflow['communityName'],
            fallback: _asString(workflow['appId']),
          ),
          'persona': persona,
          'personaId': _personaIdForEvidence(
            persona: persona,
            communityId: communityId,
          ),
          'workflowId': workflowId,
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
          'visibleTextExtract': visibleText,
          'visibleTextExtractionSource': visibleTextSource,
          'visibleTextSourceNotes':
              visibleTextSource == 'screenshot-visible-text'
              ? 'Visible text captured from Text widgets during the same integration-test step as the screenshot.'
              : 'Manual visible-text summary carried forward from workflow UI evidence assertions because the screenshot did not include a live text capture.',
          'uiPatternClassification': _initialB25SurfaceClassification(
            workflowId: workflowId,
            visibleText: visibleText,
          ),
          'primarySurfaceType': _initialB25PrimarySurfaceType(
            workflowId: workflowId,
            visibleText: visibleText,
          ),
          'targetProductionSurface': _targetProductionSurfaceForWorkflow(
            workflowId,
          ),
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
        'Resolve every evidenceRepairWorkItem before assigning UI implementation work for that same community/workflow/persona.',
        'Keep reviewer context limited to screenshots, blueprint, evidence, and pass criteria.',
      ],
      includeUiWorkItems: false,
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
        'Start only after the matching evidenceRepairWorkItems have concrete personas, screenshot-derived visible text, and screen-specific critiques.',
        'Replace any primary global workflow lists, metadata pages, checklist modals, or repeated generic cards with domain-native surfaces.',
        'Rebuild primary homes and flows around community content and jobs-to-be-done.',
        'Improve hierarchy, spacing, typography, component quality, navigation clarity, and mobile layout.',
        'Update copy/content so visible UI speaks to the target persona and task, not to validation mechanics.',
      ],
      includeEvidenceWorkItems: false,
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
    'schemaVersion': 3,
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
    'workItemSummary': _b25WorkItemSummary(batches),
    'batches': batches,
    'plannerRules': <String>[
      'Worker agents implement from remediation batches, not from optimistic summaries.',
      'Evidence repair work items must be completed and rerun before UI remediation work items for the same community/workflow/persona are assigned.',
      'UI remediation work must be scoped by community/workflow/persona and target production surface, not by a broad global ticket summary.',
      'The independent judge must rerun after each batch that changes UI, evidence, or critique.',
      'No next UX feedback loop starts until the current remediation iteration is committed.',
    ],
  };
}

JsonMap buildB25WorkflowPersonaCoverage(JsonMap review) {
  final rows = _asMapList(review['screenRows']);
  final enrichedRows = <JsonMap>[];
  final grouped = <String, List<JsonMap>>{};
  var fallbackIndex = 1;
  for (final original in rows) {
    final row = JsonMap.of(original);
    final rowId = _asString(
      row['rowId'] ?? row['screenRowId'],
      fallback:
          'b25-v4-row-${fallbackIndex.toString().padLeft(3, '0')}-${_slug(_asString(row['workflowId'], fallback: 'screen'))}',
    );
    fallbackIndex += 1;
    final persona = _asString(row['persona'], fallback: 'persona-under-review');
    final personaId = _asString(
      row['personaId'],
      fallback: _personaIdFromLabel(persona),
    );
    row['rowId'] = rowId;
    row['screenRowId'] = rowId;
    row['persona'] = persona;
    row['personaId'] = personaId;
    row['coveragePersonaStatus'] = _isSpecificPersona(persona, personaId)
        ? 'specific-persona'
        : 'persona-missing-or-generic';
    enrichedRows.add(row);

    final key = [
      _asString(row['communityId'], fallback: 'unknown-community'),
      _asString(row['workflowId'], fallback: 'unknown-workflow'),
      personaId.isNotEmpty ? personaId : persona,
    ].join('::');
    grouped.putIfAbsent(key, () => <JsonMap>[]).add(row);
  }

  final coverageRows = <JsonMap>[];
  var coverageIndex = 1;
  for (final entry in grouped.entries) {
    final groupRows = entry.value;
    final first = groupRows.first;
    final screenTypes = groupRows
        .map((row) => _asString(row['screenType']))
        .where((value) => value.isNotEmpty)
        .toSet();
    final screenNames = groupRows
        .map((row) => _asString(row['screenOrState']))
        .where((value) => value.isNotEmpty)
        .toSet();
    final persona = _asString(
      first['persona'],
      fallback: 'persona-under-review',
    );
    final personaId = _asString(first['personaId']);
    final workflowId = _asString(first['workflowId']);
    final supportSingleStateEvidence =
        _workflowIsSupportSurface(workflowId) && groupRows.isNotEmpty;
    final hasEntry =
        supportSingleStateEvidence ||
        screenTypes.contains('entry') ||
        screenNames.any(
          (name) =>
              name.toLowerCase().contains('start') ||
              name.toLowerCase().contains('ready') ||
              name.toLowerCase().contains('active') ||
              name.toLowerCase().contains('selected') ||
              name.toLowerCase().contains('picker') ||
              name.toLowerCase().contains('actor'),
        );
    final hasAction =
        supportSingleStateEvidence ||
        screenTypes.contains('action-or-review') ||
        screenNames.any(
          (name) =>
              name.toLowerCase().contains('action') ||
              name.toLowerCase().contains('dialog') ||
              name.toLowerCase().contains('review') ||
              name.toLowerCase().contains('actor') ||
              name.toLowerCase().contains('picker'),
        );
    final hasResult =
        supportSingleStateEvidence ||
        screenTypes.contains('result') ||
        screenTypes.contains('receiver-state') ||
        screenNames.any(
          (name) =>
              name.toLowerCase().contains('complete') ||
              name.toLowerCase().contains('result') ||
              name.toLowerCase().contains('received') ||
              name.toLowerCase().contains('ready') ||
              name.toLowerCase().contains('active') ||
              name.toLowerCase().contains('selected') ||
              name.toLowerCase().contains('actor'),
        );
    final missing = <String>[
      if (!_isSpecificPersona(persona, personaId)) 'specific persona/personaId',
      if (!hasEntry) 'entry/start screenshot',
      if (!hasAction) 'action/review screenshot',
      if (!hasResult) 'result/receiver screenshot',
    ];
    final coverageRowId =
        'b25-wp-${coverageIndex.toString().padLeft(3, '0')}-${_slug(_asString(first['workflowId'], fallback: 'workflow'))}-${_slug(personaId.isNotEmpty ? personaId : persona)}';
    coverageIndex += 1;
    coverageRows.add(<String, Object?>{
      'coverageRowId': coverageRowId,
      'status': missing.isEmpty ? 'pass' : 'fail',
      'communityId': _asString(first['communityId']),
      'communityName': _asString(first['communityName']),
      'workflowId': _asString(first['workflowId']),
      'persona': persona,
      'personaId': personaId,
      'screenRowIds': groupRows.map(_rowId).toList(),
      'screenshotPaths': groupRows
          .map((row) => _asString(row['screenshotPath']))
          .where((path) => path.isNotEmpty)
          .toList(),
      'screenStates': screenNames.toList()..sort(),
      'hasEntryScreenshot': hasEntry,
      'hasActionScreenshot': hasAction,
      'hasResultScreenshot': hasResult,
      'hasSpecificPersona': _isSpecificPersona(persona, personaId),
      'missingEvidence': missing,
      'requiredFix': missing.isEmpty
          ? 'None.'
          : 'Capture or map the missing workflow/persona evidence before independent UX judgment.',
    });
  }

  final failingCoverageRows = coverageRows
      .where((row) => _asString(row['status']) != 'pass')
      .toList();
  final findings = _replaceGeneratedFindings(
    _asMapList(review['findings']),
    generatedBy: 'b25-workflow-persona-coverage-collector',
  );
  if (failingCoverageRows.isNotEmpty) {
    findings.add(<String, Object?>{
      'findingId': 'B25-WORKFLOW-PERSONA-COVERAGE-INCOMPLETE',
      'severity': 'major',
      'status': 'open',
      'title': 'Workflow/persona screenshot coverage is incomplete',
      'summary':
          '${failingCoverageRows.length} workflow/persona coverage rows are missing specific personas or entry/action/result screenshot evidence.',
      'requiredFix':
          'Capture full workflow/persona evidence before running the independent UX judge.',
      'blocksPass': true,
      'generatedBy': 'b25-workflow-persona-coverage-collector',
      'affectedCoverageRowIds': failingCoverageRows
          .map((row) => _asString(row['coverageRowId']))
          .toList(),
    });
  }

  final result = JsonMap.of(review)
    ..['screenRows'] = enrichedRows
    ..['workflowPersonaCoverage'] = coverageRows
    ..['workflowPersonaCoverageSummary'] = <String, Object?>{
      'status': failingCoverageRows.isEmpty ? 'pass' : 'fail',
      'coverageRowCount': coverageRows.length,
      'failingCoverageRowCount': failingCoverageRows.length,
      'specificPersonaRowCount': coverageRows
          .where((row) => row['hasSpecificPersona'] == true)
          .length,
      'genericPersonaRowCount': coverageRows
          .where((row) => row['hasSpecificPersona'] != true)
          .length,
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
    }
    ..['findings'] = findings
    ..['unresolvedMajorFindings'] = _blockingFindingIds(findings).toList()
    ..['requiresRemediation'] = failingCoverageRows.isNotEmpty
    ..['requiresRerun'] = failingCoverageRows.isNotEmpty;
  return result;
}

JsonMap buildB25VisualInspectionAudit(JsonMap review) {
  final screenRows = <JsonMap>[];
  var failingRows = 0;
  for (final row in _asMapList(review['screenRows'])) {
    final inspection = _inspectScreenshotVisually(row);
    if (inspection['status'] == 'fail') {
      failingRows += 1;
    }
    final findingIds = <String>{
      ..._asStringList(row['findingIds']),
      ..._asStringList(inspection['findingIds']),
    }.where((id) => id.isNotEmpty).toList();
    screenRows.add(
      JsonMap.of(row)
        ..['visualInspection'] = inspection
        ..['findingIds'] = findingIds,
    );
  }
  return JsonMap.of(review)
    ..['screenRows'] = screenRows
    ..['visualInspectionSummary'] = <String, Object?>{
      'status': failingRows == 0 ? 'pass' : 'fail',
      'screenRowCount': screenRows.length,
      'failingScreenRowCount': failingRows,
      'passedScreenRowCount': screenRows.length - failingRows,
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'findingIds': <String>{
        for (final row in screenRows)
          ..._asStringList(
            (row['visualInspection'] as JsonMap?)?['findingIds'],
          ),
      }.where((id) => id.isNotEmpty).toList(),
    };
}

JsonMap buildB25IndependentUxReview(JsonMap review) {
  final withVisualAudit = review.containsKey('visualInspectionSummary')
      ? JsonMap.of(review)
      : buildB25VisualInspectionAudit(review);
  final withCoverage = withVisualAudit.containsKey('workflowPersonaCoverage')
      ? JsonMap.of(withVisualAudit)
      : buildB25WorkflowPersonaCoverage(withVisualAudit);
  final coverageRows = _asMapList(withCoverage['workflowPersonaCoverage']);
  final coverageByKey = <String, JsonMap>{
    for (final row in coverageRows)
      _coverageKey(
        _asString(row['communityId']),
        _asString(row['workflowId']),
        _asString(row['personaId'], fallback: _asString(row['persona'])),
      ): row,
  };
  final screenRows = <JsonMap>[];
  for (final row in _asMapList(withCoverage['screenRows'])) {
    final coverage =
        coverageByKey[_coverageKey(
          _asString(row['communityId']),
          _asString(row['workflowId']),
          _asString(row['personaId'], fallback: _asString(row['persona'])),
        )];
    screenRows.add(_independentScreenReviewRow(row, coverage));
  }

  final workflowScorecards = coverageRows
      .map((coverage) => _workflowPersonaScorecard(coverage, screenRows))
      .toList();
  final holisticAnswers = _holisticAnswers(
    withCoverage,
    workflowScorecards,
    screenRows,
  );
  final findings = _independentUxFindings(
    withCoverage,
    screenRows,
    workflowScorecards,
    holisticAnswers,
  );
  final unresolvedBlockers = findings
      .where(
        (finding) =>
            _normalizedSeverity(finding) == 'critical-blocker' &&
            !_isResolved(finding),
      )
      .map(_findingId)
      .toList();
  final unresolvedMajors = findings
      .where(
        (finding) =>
            _normalizedSeverity(finding) == 'major' && !_isResolved(finding),
      )
      .map(_findingId)
      .toList();
  final canPass =
      unresolvedBlockers.isEmpty &&
      unresolvedMajors.isEmpty &&
      holisticAnswers.every((answer) => answer['blocksPass'] != true) &&
      workflowScorecards.every((scorecard) => scorecard['blocksPass'] != true);

  return JsonMap.of(withCoverage)
    ..['status'] = canPass
        ? 'independent-review-pass'
        : 'independent-review-fail'
    ..['finalDecision'] = canPass ? 'pass' : 'fail'
    ..['b25CanPass'] = canPass
    ..['requiresRemediation'] = !canPass
    ..['requiresRerun'] = !canPass
    ..['generatedAt'] = DateTime.now().toUtc().toIso8601String()
    ..['screenRows'] = screenRows
    ..['findings'] = findings
    ..['holisticQuestionAnswers'] = holisticAnswers
    ..['workflowPersonaScorecards'] = workflowScorecards
    ..['unresolvedBlockerFindings'] = unresolvedBlockers
    ..['unresolvedMajorFindings'] = unresolvedMajors
    ..['remediationIterations'] = <JsonMap>[
      ..._asMapList(withCoverage['remediationIterations']),
      <String, Object?>{
        'iteration':
            _asMapList(withCoverage['remediationIterations']).length + 1,
        'status': canPass
            ? 'independent-review-pass'
            : 'independent-review-fail',
        'screenshotsRefreshed': true,
        'remainingBlockerFindings': unresolvedBlockers.length,
        'remainingMajorFindings': unresolvedMajors.length,
        'testsRun': <String>[
          'b25_workflow_persona_coverage_collector.dart',
          'b25_independent_ux_judge.dart',
        ],
        'commitSha': _asString(
          (withCoverage['reviewInputEvidence'] as JsonMap?)?['appCommitSha'],
        ),
      },
    ];
}

JsonMap _independentScreenReviewRow(JsonMap row, JsonMap? coverage) {
  final updated = JsonMap.of(row);
  final rowId = _rowId(row);
  final visibleText = _asString(row['visibleTextExtract']);
  final source = _asString(row['visibleTextExtractionSource']);
  final persona = _asString(row['persona'], fallback: 'persona-under-review');
  final personaId = _asString(row['personaId']);
  final workflowId = _asString(row['workflowId']);
  final coverageMissing = _asStringList(coverage?['missingEvidence']);
  final classification = _asString(row['uiPatternClassification']);
  final primarySurface = _asString(row['primarySurfaceType']);
  final visualInspection = _inspectScreenshotVisually(row);
  final visualFindingIds = _asStringList(visualInspection['findingIds']);
  final baseFindingIds = _asStringList(
    row['findingIds'],
  ).where((id) => id != 'B25-V4-REVIEW-PENDING').toList();
  final findingIds = <String>{
    ...baseFindingIds,
    if (coverageMissing.isNotEmpty) 'B25-WORKFLOW-PERSONA-COVERAGE-INCOMPLETE',
    if (!_isSpecificPersona(persona, personaId)) 'B25-PERSONA-SCOPE-MISSING',
    if (visibleText.isEmpty) 'B25-VISIBLE-TEXT-MISSING',
    if (source != 'screenshot-visible-text' && source != 'ocr-visible-text')
      'B25-VISIBLE-TEXT-NOT-SCREEN-EXTRACTED',
    if (_surfaceClassificationIsUnverified(classification, primarySurface))
      'B25-DOMAIN-SURFACE-UNVERIFIED',
    ...visualFindingIds,
  }.toList();
  final critique = StringBuffer()
    ..write('Screen `$rowId` for workflow `$workflowId` ');
  if (_isSpecificPersona(persona, personaId)) {
    critique.write('and persona `$persona` ');
  } else {
    critique.write('does not identify a specific production persona; ');
  }
  critique.write('shows visible text evidence: ');
  critique.write(visibleText.isEmpty ? '<missing>' : '"$visibleText"');
  if (source.isNotEmpty && source != 'screenshot-visible-text') {
    critique.write(
      '. The visible text source is `$source`, so this row is not proven by screenshot-derived OCR/manual extraction.',
    );
  }
  critique.write(
    ' Visual inspection: ${_asString(visualInspection['summary'])}',
  );
  if (coverageMissing.isNotEmpty) {
    critique.write(' Coverage is incomplete: ${coverageMissing.join(', ')}.');
  }
  if (_surfaceClassificationIsUnverified(classification, primarySurface)) {
    critique.write(
      ' The row still lacks screenshot-backed proof that the primary surface is domain-native; current classification is `${classification.isEmpty ? 'missing' : classification}` and primary surface is `${primarySurface.isEmpty ? 'missing' : primarySurface}`.',
    );
  }
  final verdict = findingIds.isEmpty ? 'pass' : 'fail';
  updated
    ..['screenSpecificCritique'] = critique.toString()
    ..['productUxCritique'] = critique.toString()
    ..['uiPatternClassification'] = findingIds.isEmpty
        ? 'domain-native-reviewed'
        : 'coverage-or-review-incomplete'
    ..['primarySurfaceType'] = findingIds.isEmpty
        ? 'domain-native'
        : 'unverified-primary-surface'
    ..['primary'] = true
    ..['targetProductionSurface'] = _targetProductionSurfaceForWorkflow(
      workflowId,
    )
    ..['visualInspection'] = visualInspection
    ..['referencePatternsToCopy'] = _b25ReferencePatternsForWorkflow(workflowId)
    ..['referenceResearchQueries'] = _referenceResearchQueriesForWorkflow(
      workflowId,
    )
    ..['verdict'] = verdict
    ..['severity'] = verdict == 'pass' ? 'none' : 'major'
    ..['findingIds'] = findingIds
    ..['retestResult'] = verdict == 'pass'
        ? 'pass'
        : 'requires-remediation-and-recapture';
  return updated;
}

JsonMap _inspectScreenshotVisually(JsonMap row) {
  final path = _asString(row['screenshotPath'] ?? row['screenshot']);
  final file = _resolveScreenshotFile(path);
  final findingIds = <String>[];
  if (path.isEmpty || file == null || !file.existsSync()) {
    return <String, Object?>{
      'status': 'fail',
      'summary':
          'Screenshot pixels could not be inspected because the screenshot file was not found.',
      'screenshotPath': path,
      'findingIds': <String>['B25-VISUAL-INSPECTION-MISSING'],
      'metrics': <String, Object?>{},
      'signals': <String, Object?>{},
    };
  }

  final decoded = img.decodeImage(file.readAsBytesSync());
  if (decoded == null) {
    return <String, Object?>{
      'status': 'fail',
      'summary':
          'Screenshot pixels could not be inspected because the image decoder could not read the file.',
      'screenshotPath': file.path,
      'findingIds': <String>['B25-VISUAL-INSPECTION-MISSING'],
      'metrics': <String, Object?>{},
      'signals': <String, Object?>{},
    };
  }

  final metrics = _visualMetrics(decoded);
  final visibleText = _asString(row['visibleTextExtract']).toLowerCase();
  final screenType = _asString(row['screenType']).toLowerCase();
  final workflowId = _asString(row['workflowId']).toLowerCase();
  final screenName = _asString(row['screenOrState']).toLowerCase();
  final isPrimaryWorkflow = !_workflowIsSupportSurface(workflowId);
  final actionLike =
      screenType.contains('action') ||
      screenType.contains('review') ||
      screenName.contains('action') ||
      screenName.contains('dialog') ||
      screenName.contains('actor') ||
      screenName.contains('review');

  final modalOverlayLikely = metrics.modalOverlayLikely;
  final repeatedCardShellLikely =
      metrics.cardBandCount >= 4 || metrics.largeSurfaceBandCount >= 5;
  final weakVisualIdentityLikely =
      metrics.accentPixelRatio < 0.025 && metrics.saturatedPixelRatio < 0.075;
  final thinContentLikely =
      metrics.darkInkRatio < 0.055 && metrics.edgeDensity < 0.045;
  final defaultScaffoldLikely =
      weakVisualIdentityLikely &&
      (repeatedCardShellLikely || thinContentLikely);
  final checklistLanguageLikely =
      visibleText.contains('ready') ||
      visibleText.contains('will be checked') ||
      visibleText.contains('recorded') ||
      visibleText.contains('workflow') ||
      visibleText.contains('evidence');
  final checklistModalLikely =
      modalOverlayLikely && (actionLike || checklistLanguageLikely);

  if (checklistModalLikely) {
    findingIds.add('B25-CHECKLIST-MODAL-LIKELY');
  }
  if (isPrimaryWorkflow && repeatedCardShellLikely) {
    findingIds.add('B25-REPEATED-CARD-SHELL-LIKELY');
  }
  if (isPrimaryWorkflow && thinContentLikely) {
    findingIds.add('B25-THIN-CONTENT-LIKELY');
  }
  if (isPrimaryWorkflow && weakVisualIdentityLikely) {
    findingIds.add('B25-WEAK-VISUAL-IDENTITY');
  }
  if (isPrimaryWorkflow && defaultScaffoldLikely) {
    findingIds.add('B25-DEFAULT-SCAFFOLD-LIKELY');
  }

  final signals = <String, Object?>{
    'modalOverlayLikely': modalOverlayLikely,
    'checklistModalLikely': checklistModalLikely,
    'repeatedCardShellLikely': repeatedCardShellLikely,
    'thinContentLikely': thinContentLikely,
    'weakVisualIdentityLikely': weakVisualIdentityLikely,
    'defaultScaffoldLikely': defaultScaffoldLikely,
    'actionLike': actionLike,
    'primaryWorkflow': isPrimaryWorkflow,
  };
  final summaryParts = <String>[
    'decoded ${decoded.width}x${decoded.height}px',
    'edgeDensity=${metrics.edgeDensity.toStringAsFixed(3)}',
    'darkInk=${metrics.darkInkRatio.toStringAsFixed(3)}',
    'accent=${metrics.accentPixelRatio.toStringAsFixed(3)}',
    'cardBands=${metrics.cardBandCount}',
    'modalOverlay=$modalOverlayLikely',
  ];
  if (findingIds.isNotEmpty) {
    summaryParts.add('visual findings: ${findingIds.join(', ')}');
  } else {
    summaryParts.add(
      'no deterministic pixel/layout blocker was found; reviewer still must validate product fit from screenshot content',
    );
  }

  return <String, Object?>{
    'status': findingIds.isEmpty ? 'pass' : 'fail',
    'summary': summaryParts.join('; '),
    'screenshotPath': file.path,
    'findingIds': findingIds,
    'metrics': metrics.toJson(),
    'signals': signals,
  };
}

File? _resolveScreenshotFile(String path) {
  if (path.trim().isEmpty) {
    return null;
  }
  final candidates = <String>[
    path,
    _hostPath(path),
    if (!RegExp(r'^[A-Za-z]:[\\/]|^/').hasMatch(path)) '../$path',
    if (!RegExp(r'^[A-Za-z]:[\\/]|^/').hasMatch(path)) '../../$path',
    if (!RegExp(r'^[A-Za-z]:[\\/]|^/').hasMatch(path)) '../../../$path',
  ];
  final seen = <String>{};
  for (final candidate in candidates) {
    final host = _hostPath(candidate);
    if (!seen.add(host)) {
      continue;
    }
    final file = File(host);
    if (file.existsSync()) {
      return file;
    }
  }
  return null;
}

_VisualMetrics _visualMetrics(img.Image image) {
  final width = image.width;
  final height = image.height;
  final sampleStepX = math.max(1, (width / 90).floor());
  final sampleStepY = math.max(1, (height / 160).floor());
  var samples = 0;
  var nearWhite = 0;
  var darkInk = 0;
  var saturated = 0;
  var accent = 0;
  var centerLight = 0;
  var centerSamples = 0;
  var outerDim = 0;
  var outerSamples = 0;
  var edgeTransitions = 0;
  final buckets = <int>{};

  for (var y = 0; y < height; y += sampleStepY) {
    double? previousLuma;
    for (var x = 0; x < width; x += sampleStepX) {
      final pixel = image.getPixel(x, y);
      final r = pixel.r.toDouble();
      final g = pixel.g.toDouble();
      final b = pixel.b.toDouble();
      final luma = _luma(r, g, b);
      final saturation = _saturation(r, g, b);
      samples += 1;
      buckets.add(((r ~/ 48) << 8) | ((g ~/ 48) << 4) | (b ~/ 48));
      if (luma > 232) {
        nearWhite += 1;
      }
      if (luma < 112) {
        darkInk += 1;
      }
      if (saturation > 0.20) {
        saturated += 1;
      }
      if (saturation > 0.24 && luma > 55 && luma < 210) {
        accent += 1;
      }
      final inCenter =
          x > width * 0.18 &&
          x < width * 0.82 &&
          y > height * 0.22 &&
          y < height * 0.80;
      if (inCenter) {
        centerSamples += 1;
        if (luma > 218) {
          centerLight += 1;
        }
      } else {
        outerSamples += 1;
        if (luma > 40 && luma < 170 && saturation < 0.18) {
          outerDim += 1;
        }
      }
      if (previousLuma != null && (luma - previousLuma).abs() > 42) {
        edgeTransitions += 1;
      }
      previousLuma = luma;
    }
  }

  final cardBands = _countCardBands(image);
  final largeSurfaceBands = _countLargeSurfaceBands(image);
  final centerLightRatio = _ratio(centerLight, centerSamples);
  final outerDimRatio = _ratio(outerDim, outerSamples);
  return _VisualMetrics(
    width: width,
    height: height,
    colorBucketCount: buckets.length,
    nearWhiteRatio: _ratio(nearWhite, samples),
    darkInkRatio: _ratio(darkInk, samples),
    saturatedPixelRatio: _ratio(saturated, samples),
    accentPixelRatio: _ratio(accent, samples),
    edgeDensity: _ratio(edgeTransitions, samples),
    centerLightRatio: centerLightRatio,
    outerDimRatio: outerDimRatio,
    cardBandCount: cardBands,
    largeSurfaceBandCount: largeSurfaceBands,
    modalOverlayLikely: centerLightRatio > 0.58 && outerDimRatio > 0.28,
  );
}

int _countCardBands(img.Image image) {
  final width = image.width;
  final height = image.height;
  final stepY = math.max(1, (height / 180).floor());
  final stepX = math.max(1, (width / 70).floor());
  var bands = 0;
  var inBand = false;
  for (var y = 0; y < height; y += stepY) {
    var lightInterior = 0;
    var total = 0;
    for (
      var x = (width * 0.07).floor();
      x < (width * 0.93).floor();
      x += stepX
    ) {
      final pixel = image.getPixel(x, y);
      final luma = _luma(
        pixel.r.toDouble(),
        pixel.g.toDouble(),
        pixel.b.toDouble(),
      );
      total += 1;
      if (luma > 214 && luma < 250) {
        lightInterior += 1;
      }
    }
    final band = total > 0 && lightInterior / total > 0.58;
    if (band && !inBand) {
      bands += 1;
    }
    inBand = band;
  }
  return bands;
}

int _countLargeSurfaceBands(img.Image image) {
  final width = image.width;
  final height = image.height;
  final stepY = math.max(1, (height / 120).floor());
  final stepX = math.max(1, (width / 60).floor());
  var bands = 0;
  var inBand = false;
  for (var y = 0; y < height; y += stepY) {
    var nonBackground = 0;
    var total = 0;
    for (
      var x = (width * 0.05).floor();
      x < (width * 0.95).floor();
      x += stepX
    ) {
      final pixel = image.getPixel(x, y);
      final luma = _luma(
        pixel.r.toDouble(),
        pixel.g.toDouble(),
        pixel.b.toDouble(),
      );
      total += 1;
      if (luma > 185 && luma < 248) {
        nonBackground += 1;
      }
    }
    final band = total > 0 && nonBackground / total > 0.66;
    if (band && !inBand) {
      bands += 1;
    }
    inBand = band;
  }
  return bands;
}

double _luma(double r, double g, double b) {
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _saturation(double r, double g, double b) {
  final maxValue = math.max(r, math.max(g, b));
  final minValue = math.min(r, math.min(g, b));
  if (maxValue <= 0) {
    return 0;
  }
  return (maxValue - minValue) / maxValue;
}

double _ratio(int numerator, int denominator) {
  if (denominator <= 0) {
    return 0;
  }
  return numerator / denominator;
}

class _VisualMetrics {
  const _VisualMetrics({
    required this.width,
    required this.height,
    required this.colorBucketCount,
    required this.nearWhiteRatio,
    required this.darkInkRatio,
    required this.saturatedPixelRatio,
    required this.accentPixelRatio,
    required this.edgeDensity,
    required this.centerLightRatio,
    required this.outerDimRatio,
    required this.cardBandCount,
    required this.largeSurfaceBandCount,
    required this.modalOverlayLikely,
  });

  final int width;
  final int height;
  final int colorBucketCount;
  final double nearWhiteRatio;
  final double darkInkRatio;
  final double saturatedPixelRatio;
  final double accentPixelRatio;
  final double edgeDensity;
  final double centerLightRatio;
  final double outerDimRatio;
  final int cardBandCount;
  final int largeSurfaceBandCount;
  final bool modalOverlayLikely;

  JsonMap toJson() {
    return <String, Object?>{
      'width': width,
      'height': height,
      'colorBucketCount': colorBucketCount,
      'nearWhiteRatio': nearWhiteRatio,
      'darkInkRatio': darkInkRatio,
      'saturatedPixelRatio': saturatedPixelRatio,
      'accentPixelRatio': accentPixelRatio,
      'edgeDensity': edgeDensity,
      'centerLightRatio': centerLightRatio,
      'outerDimRatio': outerDimRatio,
      'cardBandCount': cardBandCount,
      'largeSurfaceBandCount': largeSurfaceBandCount,
      'modalOverlayLikely': modalOverlayLikely,
    };
  }
}

JsonMap _workflowPersonaScorecard(JsonMap coverage, List<JsonMap> screenRows) {
  final coverageRowId = _asString(coverage['coverageRowId']);
  final workflowId = _asString(coverage['workflowId']);
  final persona = _asString(coverage['persona']);
  final personaId = _asString(coverage['personaId']);
  final relatedRows = screenRows.where((row) {
    return _asString(row['workflowId']) == workflowId &&
        _asString(row['communityId']) == _asString(coverage['communityId']) &&
        (_asString(row['personaId']) == personaId ||
            _asString(row['persona']) == persona);
  }).toList();
  final missing = _asStringList(coverage['missingEvidence']);
  final rowFailures = relatedRows
      .where((row) => _asString(row['verdict']) == 'fail')
      .map(_rowId)
      .toList();
  final visualFailures = relatedRows
      .where((row) {
        final inspection = row['visualInspection'] as JsonMap?;
        return inspection != null && inspection['status'] == 'fail';
      })
      .map(_rowId)
      .toList();
  final textEvidence = relatedRows
      .map((row) => _asString(row['visibleTextExtract']))
      .where((text) => text.isNotEmpty)
      .take(3)
      .toList();
  final screenshotRefs = relatedRows
      .map((row) => _asString(row['screenshotPath']))
      .where((path) => path.isNotEmpty)
      .toList();
  final coveragePass = missing.isEmpty;
  final rowPass = rowFailures.isEmpty;
  final domainPass = coveragePass && rowPass && visualFailures.isEmpty;
  final questions = <JsonMap>[
    _directAnswer(
      questionId: '$coverageRowId-coverage',
      scope: 'workflow-persona',
      question:
          'Does workflow `$workflowId` have complete entry/action/result screenshot coverage for persona `$persona`?',
      pass: coveragePass,
      score: coveragePass ? 90 : 30,
      evidenceUsed: _asStringList(coverage['screenRowIds']),
      why: coveragePass
          ? 'Entry, action, and result evidence exists for this workflow/persona row.'
          : 'Missing coverage: ${missing.join(', ')}.',
      requiredFix: coveragePass
          ? 'None.'
          : 'Capture the missing screenshot states and assign a specific persona/personaId.',
    ),
    _directAnswer(
      questionId: '$coverageRowId-domain-surface',
      scope: 'workflow-persona',
      question:
          'Is the primary UI for workflow `$workflowId` and persona `$persona` a domain-native product surface instead of a generic card/checklist/metadata screen?',
      pass: domainPass,
      score: domainPass ? 85 : 35,
      evidenceUsed: rowFailures.isEmpty
          ? _asStringList(coverage['screenRowIds'])
          : rowFailures,
      why: domainPass
          ? 'Screenshot pixel/layout inspection and row critique did not find generic primary-surface failures for this workflow/persona group.'
          : 'Rows still have unresolved visual/review/coverage failures: ${rowFailures.isEmpty ? missing.join(', ') : rowFailures.join(', ')}.',
      requiredFix: domainPass
          ? 'None.'
          : 'Replace or document the exact domain-native surface and recapture the affected workflow/persona rows.',
    ),
    _directAnswer(
      questionId: '$coverageRowId-visual-quality',
      scope: 'workflow-persona',
      question:
          'Does screenshot pixel/layout inspection show a modern, intentional, non-generic UI for workflow `$workflowId` and persona `$persona`?',
      pass: visualFailures.isEmpty && rowPass,
      score: visualFailures.isEmpty && rowPass ? 85 : 35,
      evidenceUsed: visualFailures.isEmpty
          ? _asStringList(coverage['screenRowIds'])
          : visualFailures,
      why: visualFailures.isEmpty && rowPass
          ? 'The screenshot visual inspection did not detect checklist modal, repeated-card shell, thin-content, weak-identity, or default-scaffold blockers.'
          : 'Screenshot visual inspection found production UX blockers in rows: ${visualFailures.isEmpty ? rowFailures.join(', ') : visualFailures.join(', ')}.',
      requiredFix: visualFailures.isEmpty && rowPass
          ? 'None.'
          : 'Replace checklist/repeated-card/thin-content/default-scaffold surfaces with richer domain-native UI, then recapture screenshots and rerun the visual inspection.',
    ),
    _directAnswer(
      questionId: '$coverageRowId-visible-text',
      scope: 'workflow-persona',
      question:
          'Does the review cite visible UI/text and a task-specific critique for workflow `$workflowId` and persona `$persona`?',
      pass: rowPass && textEvidence.isNotEmpty,
      score: rowPass && textEvidence.isNotEmpty ? 85 : 35,
      evidenceUsed: rowFailures.isEmpty
          ? _asStringList(coverage['screenRowIds'])
          : rowFailures,
      why: rowPass && textEvidence.isNotEmpty
          ? 'The scorecard cites visible text: ${textEvidence.join(' | ')}.'
          : 'Visible text or row-specific critique is missing or unsupported for this workflow/persona group.',
      requiredFix: rowPass && textEvidence.isNotEmpty
          ? 'None.'
          : 'Extract visible text from the screenshots and write a specific critique for each affected row.',
    ),
  ];
  final blocks = questions.any((question) => question['blocksPass'] == true);
  return <String, Object?>{
    'scorecardId': coverageRowId,
    'communityId': _asString(coverage['communityId']),
    'communityName': _asString(coverage['communityName']),
    'workflowId': workflowId,
    'persona': persona,
    'personaId': personaId,
    'status': blocks ? 'fail' : 'pass',
    'blocksPass': blocks,
    'screenRowIds': _asStringList(coverage['screenRowIds']),
    'screenshotPaths': screenshotRefs,
    'targetProductionSurface': _targetProductionSurfaceForWorkflow(workflowId),
    'referencePatternsToCopy': _b25ReferencePatternsForWorkflow(workflowId),
    'referenceResearchQueries': _referenceResearchQueriesForWorkflow(
      workflowId,
    ),
    'questions': questions,
    'summary': blocks
        ? 'Workflow/persona review failed for `$workflowId` / `$persona`.'
        : 'Workflow/persona review passed for `$workflowId` / `$persona`.',
  };
}

List<JsonMap> _holisticAnswers(
  JsonMap review,
  List<JsonMap> workflowScorecards,
  List<JsonMap> screenRows,
) {
  final coverageSummary =
      (review['workflowPersonaCoverageSummary'] as JsonMap?) ??
      <String, Object?>{};
  final failingCoverage = _asInt(coverageSummary['failingCoverageRowCount']);
  final failingWorkflowScorecards = workflowScorecards
      .where((scorecard) => scorecard['blocksPass'] == true)
      .length;
  final rowCount = screenRows.length;
  final visibleTextUnsupported = screenRows.where((row) {
    final source = _asString(row['visibleTextExtractionSource']);
    return source.isNotEmpty &&
        source != 'screenshot-visible-text' &&
        source != 'ocr-visible-text';
  }).length;
  final visualFailureRows = screenRows.where((row) {
    final inspection = row['visualInspection'] as JsonMap?;
    return inspection != null && inspection['status'] == 'fail';
  }).length;
  return <JsonMap>[
    _directAnswer(
      questionId: 'b25-holistic-production-grade',
      scope: 'holistic',
      question:
          'Does the whole experience feel like a real production community app for the target users, not merely an implemented workflow harness?',
      pass:
          failingCoverage == 0 &&
          failingWorkflowScorecards == 0 &&
          visualFailureRows == 0,
      score:
          failingCoverage == 0 &&
              failingWorkflowScorecards == 0 &&
              visualFailureRows == 0
          ? 85
          : 35,
      evidenceUsed: <String>[
        'screenRows=$rowCount',
        'workflowPersonaCoverageFailures=$failingCoverage',
        'workflowPersonaScorecardFailures=$failingWorkflowScorecards',
        'visualInspectionFailures=$visualFailureRows',
      ],
      why:
          failingCoverage == 0 &&
              failingWorkflowScorecards == 0 &&
              visualFailureRows == 0
          ? 'Coverage, workflow/persona scorecards, and screenshot pixel/layout inspection provide no production-grade blockers.'
          : 'The review cannot claim production-grade UX while workflow/persona evidence or screenshot visual inspection is incomplete/failing.',
      requiredFix:
          failingCoverage == 0 &&
              failingWorkflowScorecards == 0 &&
              visualFailureRows == 0
          ? 'None.'
          : 'Complete workflow/persona coverage and remediate visual/layout scorecard failures before claiming production-grade UX.',
    ),
    _directAnswer(
      questionId: 'b25-holistic-modern-intentional',
      scope: 'holistic',
      question:
          'Is the UI modern, easy to use, easy to navigate, and visually appealing for the target persona?',
      pass:
          visibleTextUnsupported == 0 &&
          failingWorkflowScorecards == 0 &&
          visualFailureRows == 0,
      score:
          visibleTextUnsupported == 0 &&
              failingWorkflowScorecards == 0 &&
              visualFailureRows == 0
          ? 85
          : 40,
      evidenceUsed: <String>[
        'screenRows=$rowCount',
        'unsupportedVisibleTextRows=$visibleTextUnsupported',
        'visualInspectionFailures=$visualFailureRows',
      ],
      why: visibleTextUnsupported == 0 && visualFailureRows == 0
          ? 'Visible UI/text evidence and screenshot pixel/layout inspection support judging modern UI quality.'
          : '$visibleTextUnsupported rows use non-screen visible text sources and $visualFailureRows rows have visual/layout blockers, so the judge cannot make a reliable modern-UI claim.',
      requiredFix: visibleTextUnsupported == 0 && visualFailureRows == 0
          ? 'None.'
          : 'Use screenshot-derived visible text and fix detected checklist, repeated-card, thin-content, or weak-identity visual blockers before rerunning the judge.',
    ),
    _directAnswer(
      questionId: 'b25-holistic-community-ia',
      scope: 'holistic',
      question:
          'Is the overall information architecture organized around community content and real jobs-to-be-done instead of workflow lists or validation surfaces?',
      pass: failingWorkflowScorecards == 0 && visualFailureRows == 0,
      score: failingWorkflowScorecards == 0 && visualFailureRows == 0 ? 85 : 45,
      evidenceUsed: <String>[
        'workflowPersonaScorecardFailures=$failingWorkflowScorecards',
        'visualInspectionFailures=$visualFailureRows',
      ],
      why: failingWorkflowScorecards == 0 && visualFailureRows == 0
          ? 'Workflow/persona scorecards and visual inspection do not report generic workflow-list IA failures.'
          : 'Failing workflow/persona scorecards or visual blockers prevent a holistic community IA pass.',
      requiredFix: failingWorkflowScorecards == 0 && visualFailureRows == 0
          ? 'None.'
          : 'Replace generic workflow-list or validation surfaces with domain-native community sections and rerun scorecards.',
    ),
    _directAnswer(
      questionId: 'b25-holistic-layout-defects',
      scope: 'holistic',
      question:
          'Does the visible UI avoid blocking or major overlap, clipping, crowding, default-scaffold, repeated-card, checklist-modal, and thin-content defects?',
      pass:
          failingWorkflowScorecards == 0 &&
          visibleTextUnsupported == 0 &&
          visualFailureRows == 0,
      score:
          failingWorkflowScorecards == 0 &&
              visibleTextUnsupported == 0 &&
              visualFailureRows == 0
          ? 85
          : 45,
      evidenceUsed: <String>[
        'workflowPersonaScorecardFailures=$failingWorkflowScorecards',
        'unsupportedVisibleTextRows=$visibleTextUnsupported',
        'visualInspectionFailures=$visualFailureRows',
      ],
      why:
          failingWorkflowScorecards == 0 &&
              visibleTextUnsupported == 0 &&
              visualFailureRows == 0
          ? 'No major layout/content defects were detected by screenshot pixel/layout inspection or row-level critique.'
          : 'The judge cannot clear layout/content defects while row-level evidence remains incomplete, unsupported, or visually failing.',
      requiredFix:
          failingWorkflowScorecards == 0 &&
              visibleTextUnsupported == 0 &&
              visualFailureRows == 0
          ? 'None.'
          : 'Complete screenshot-backed review rows and remediate any row-level layout/content defects.',
    ),
  ];
}

JsonMap _directAnswer({
  required String questionId,
  required String scope,
  required String question,
  required bool pass,
  required int score,
  required List<String> evidenceUsed,
  required String why,
  required String requiredFix,
}) {
  return <String, Object?>{
    'questionId': questionId,
    'scope': scope,
    'question': question,
    'answer': pass ? 'yes' : 'no',
    'score': score,
    'verdict': pass ? 'pass' : 'fail',
    'blocksPass': !pass,
    'why': why,
    'requiredFix': requiredFix,
    'visibleEvidence': evidenceUsed,
    'evidenceUsed': evidenceUsed,
  };
}

List<JsonMap> _independentUxFindings(
  JsonMap review,
  List<JsonMap> screenRows,
  List<JsonMap> workflowScorecards,
  List<JsonMap> holisticAnswers,
) {
  final findings = _replaceGeneratedFindings(
    _asMapList(review['findings']),
    generatedBy: 'b25-independent-ux-judge',
  );
  final coverageSummary =
      (review['workflowPersonaCoverageSummary'] as JsonMap?) ??
      <String, Object?>{};
  final failingCoverage = _asInt(coverageSummary['failingCoverageRowCount']);
  if (failingCoverage > 0) {
    findings.add(<String, Object?>{
      'findingId': 'B25-WORKFLOW-PERSONA-COVERAGE-INCOMPLETE',
      'severity': 'major',
      'status': 'open',
      'title': 'Workflow/persona coverage is incomplete',
      'summary':
          '$failingCoverage workflow/persona rows lack specific persona or full entry/action/result evidence.',
      'requiredFix':
          'Capture full workflow/persona evidence before rerunning the independent UX judge.',
      'blocksPass': true,
      'generatedBy': 'b25-independent-ux-judge',
      'affectedCoverageRowIds': _asMapList(review['workflowPersonaCoverage'])
          .where((row) => _asString(row['status']) != 'pass')
          .map((row) => _asString(row['coverageRowId']))
          .toList(),
    });
  }
  final unsupportedVisibleTextRows = screenRows
      .where((row) {
        final ids = _asStringList(row['findingIds']);
        return ids.contains('B25-VISIBLE-TEXT-NOT-SCREEN-EXTRACTED') ||
            ids.contains('B25-VISIBLE-TEXT-MISSING');
      })
      .map(_rowId)
      .toList();
  if (unsupportedVisibleTextRows.isNotEmpty) {
    findings.add(<String, Object?>{
      'findingId': 'B25-SCREEN-SPECIFIC-CRITIQUE-INCOMPLETE',
      'severity': 'major',
      'status': 'open',
      'title': 'Screen-specific critique is not fully screenshot-backed',
      'summary':
          '${unsupportedVisibleTextRows.length} screen rows lack screenshot OCR/manual visible text and specific critique evidence.',
      'requiredFix':
          'Extract visible text from screenshots and write screen-specific critiques for affected rows.',
      'blocksPass': true,
      'generatedBy': 'b25-independent-ux-judge',
      'affectedScreenRowIds': unsupportedVisibleTextRows.take(50).toList(),
    });
  }
  final visualFailureRows = screenRows
      .where((row) {
        final ids = _asStringList(row['findingIds']);
        return ids.any(
          (id) =>
              id.startsWith('B25-CHECKLIST-MODAL') ||
              id.startsWith('B25-REPEATED-CARD') ||
              id.startsWith('B25-THIN-CONTENT') ||
              id.startsWith('B25-WEAK-VISUAL') ||
              id.startsWith('B25-DEFAULT-SCAFFOLD') ||
              id.startsWith('B25-VISUAL-INSPECTION'),
        );
      })
      .map(_rowId)
      .toList();
  if (visualFailureRows.isNotEmpty) {
    findings.add(<String, Object?>{
      'findingId': 'B25-VISUAL-UX-INSPECTION-FAILED',
      'severity': 'major',
      'status': 'open',
      'title':
          'Screenshot pixel/layout inspection found production UX blockers',
      'summary':
          '${visualFailureRows.length} screen rows visually resemble checklist modals, repeated-card shells, thin-content surfaces, weak identity, default scaffolds, or missing visual evidence.',
      'requiredFix':
          'Replace the affected screens with screenshot-proven domain-native surfaces and rerun the independent visual UX judge.',
      'blocksPass': true,
      'generatedBy': 'b25-independent-ux-judge',
      'affectedScreenRowIds': visualFailureRows.take(80).toList(),
    });
  }
  final failingScorecards = workflowScorecards
      .where((scorecard) => scorecard['blocksPass'] == true)
      .map((scorecard) => _asString(scorecard['scorecardId']))
      .toList();
  if (failingScorecards.isNotEmpty) {
    findings.add(<String, Object?>{
      'findingId': 'B25-WORKFLOW-PERSONA-UX-FAILED',
      'severity': 'major',
      'status': 'open',
      'title': 'Workflow/persona UX scorecards failed',
      'summary':
          '${failingScorecards.length} workflow/persona scorecards failed direct-question review.',
      'requiredFix':
          'Use the failed scorecards to remediate exact workflow/persona screens and recapture evidence.',
      'blocksPass': true,
      'generatedBy': 'b25-independent-ux-judge',
      'affectedScorecardIds': failingScorecards.take(50).toList(),
    });
  }
  final failingHolistic = holisticAnswers
      .where((answer) => answer['blocksPass'] == true)
      .map((answer) => _asString(answer['questionId']))
      .toList();
  if (failingHolistic.isNotEmpty) {
    findings.add(<String, Object?>{
      'findingId': 'B25-HOLISTIC-UX-FAILED',
      'severity': 'major',
      'status': 'open',
      'title': 'Holistic production UX review failed',
      'summary':
          'Holistic direct-question review failed: ${failingHolistic.join(', ')}.',
      'requiredFix':
          'Resolve coverage, screen critique, IA, and visual quality issues before rerunning holistic review.',
      'blocksPass': true,
      'generatedBy': 'b25-independent-ux-judge',
      'affectedQuestionIds': failingHolistic,
    });
  }
  return findings;
}

List<JsonMap> _replaceGeneratedFindings(
  List<JsonMap> findings, {
  required String generatedBy,
}) {
  final generatedIds = <String>{
    'B25-V4-REVIEW-PENDING',
    'B25-HOLISTIC-UNPROVEN',
    'B25-WORKFLOW-PERSONA-UNPROVEN',
    'B25-WORKFLOW-PERSONA-COVERAGE-INCOMPLETE',
    'B25-SCREEN-SPECIFIC-CRITIQUE-INCOMPLETE',
    'B25-VISUAL-UX-INSPECTION-FAILED',
    'B25-WORKFLOW-PERSONA-UX-FAILED',
    'B25-HOLISTIC-UX-FAILED',
    'B25-PERSONA-SCOPE-MISSING',
  };
  return findings
      .where((finding) {
        final id = _findingId(finding);
        if (generatedIds.contains(id)) {
          return false;
        }
        return _asString(finding['generatedBy']) != generatedBy;
      })
      .map(JsonMap.of)
      .toList();
}

String _coverageKey(String communityId, String workflowId, String personaId) {
  return '$communityId::$workflowId::$personaId';
}

JsonMap _remediationBatch({
  required String batchId,
  required String title,
  required String purpose,
  required List<JsonMap> tickets,
  required List<String> actions,
  bool includeEvidenceWorkItems = true,
  bool includeUiWorkItems = true,
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
  final likelyFiles = <String>{
    for (final ticket in tickets)
      ..._asStringList(ticket['likelyFilesOrWidgets']),
  }.toList();
  final referencePatterns = _dedupeReferencePatterns(<JsonMap>[
    for (final ticket in tickets) ..._asMapList(ticket['uxReferencePatterns']),
    for (final ticket in tickets)
      for (final item in _asMapList(ticket['evidenceRepairWorkItems']))
        ..._asMapList(item['referencePatternsToCopy']),
    for (final ticket in tickets)
      for (final item in _asMapList(ticket['uiRemediationWorkItems']))
        ..._asMapList(item['referencePatternsToCopy']),
  ]);
  final referenceResearchQueries = _uniqueStrings(<String>[
    for (final ticket in tickets)
      ..._asStringList(ticket['referenceResearchQueries']),
    for (final ticket in tickets)
      for (final item in _asMapList(ticket['evidenceRepairWorkItems']))
        ..._asStringList(item['referenceResearchQueries']),
    for (final ticket in tickets)
      for (final item in _asMapList(ticket['uiRemediationWorkItems']))
        ..._asStringList(item['referenceResearchQueries']),
  ]);
  final screenRowIds = <String>{
    for (final ticket in tickets)
      ..._asStringList(ticket['affectedScreenRowIds']),
  }.toList();
  final coverageRowIds = <String>{
    for (final ticket in tickets)
      ..._asStringList(ticket['affectedCoverageRowIds']),
  }.toList();
  final screenRowsById = <String, JsonMap>{
    for (final ticket in tickets)
      for (final row in _asMapList(ticket['affectedScreenRows']))
        _asString(row['screenRowId']): JsonMap.of(row),
  }..remove('');
  final coverageRowsById = <String, JsonMap>{
    for (final ticket in tickets)
      for (final row in _asMapList(ticket['affectedCoverageRows']))
        _asString(row['coverageRowId']): JsonMap.of(row),
  }..remove('');
  final scorecardsById = <String, JsonMap>{
    for (final ticket in tickets)
      for (final row in _asMapList(ticket['failingWorkflowPersonaScorecards']))
        _asString(row['scorecardId']): JsonMap.of(row),
  }..remove('');
  final concreteAcceptance = <String>{
    for (final ticket in tickets)
      ..._asStringList(ticket['concreteAcceptanceCriteria']),
  }.toList();
  final evidenceRepairWorkItems = includeEvidenceWorkItems
      ? _dedupeWorkItems(<JsonMap>[
          for (final ticket in tickets)
            ..._asMapList(ticket['evidenceRepairWorkItems']).map(JsonMap.of),
        ])
      : <JsonMap>[];
  final uiRemediationWorkItems = includeUiWorkItems
      ? _dedupeWorkItems(<JsonMap>[
          for (final ticket in tickets)
            ..._asMapList(ticket['uiRemediationWorkItems']).map(JsonMap.of),
        ])
      : <JsonMap>[];
  return <String, Object?>{
    'batchId': batchId,
    'status': 'open',
    'title': title,
    'purpose': purpose,
    'ticketIds': ticketIds,
    'tickets': tickets
        .map(
          (ticket) => <String, Object?>{
            'ticketId': _asString(ticket['ticketId']),
            'sourceCriterionId': _asString(ticket['sourceCriterionId']),
            'severity': _asString(ticket['severity']),
            'priority': _asString(ticket['priority']),
            'status': _asString(ticket['status']),
            'title': _asString(ticket['title']),
            'remediationMode': _asString(ticket['remediationMode']),
            'workerReadiness': _asString(ticket['workerReadiness']),
          },
        )
        .toList(),
    'workerActions': actions,
    'implementationGuidance': implementation,
    'likelyFilesOrWidgets': likelyFiles,
    'uxReferencePatterns': referencePatterns,
    'referenceResearchQueries': referenceResearchQueries,
    'affectedScreenRowIds': screenRowIds,
    'affectedCoverageRowIds': coverageRowIds,
    'affectedScreenRows': screenRowsById.values.toList(),
    'affectedCoverageRows': coverageRowsById.values.toList(),
    'failingWorkflowPersonaScorecards': scorecardsById.values.toList(),
    'evidenceRepairWorkItems': evidenceRepairWorkItems,
    'uiRemediationWorkItems': uiRemediationWorkItems,
    'evidenceToUpdate': evidence,
    'acceptanceChecks': acceptance,
    'concreteAcceptanceCriteria': concreteAcceptance,
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

JsonMap _b25WorkItemSummary(List<JsonMap> batches) {
  final evidenceItems = <String>{};
  final uiItems = <String>{};
  final communities = <String>{};
  final workflows = <String>{};
  final personas = <String>{};
  for (final batch in batches) {
    for (final item in _asMapList(batch['evidenceRepairWorkItems'])) {
      evidenceItems.add(_asString(item['workItemId']));
      communities.add(_asString(item['communityName']));
      workflows.add(_asString(item['workflowId']));
      personas.add(_asString(item['persona']));
    }
    for (final item in _asMapList(batch['uiRemediationWorkItems'])) {
      uiItems.add(_asString(item['workItemId']));
      communities.add(_asString(item['communityName']));
      workflows.add(_asString(item['workflowId']));
      personas.add(_asString(item['persona']));
    }
  }
  evidenceItems.remove('');
  uiItems.remove('');
  communities.remove('');
  workflows.remove('');
  personas.remove('');
  return <String, Object?>{
    'evidenceRepairWorkItemCount': evidenceItems.length,
    'uiRemediationWorkItemCount': uiItems.length,
    'communityCount': communities.length,
    'workflowCount': workflows.length,
    'personaCount': personas.length,
    'sequencing':
        'Evidence repair work items must be completed and rerun before matching UI remediation work items are assigned.',
  };
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
          _failOnVisualInspection(screenRows) ??
          _failOnWorkflowPersonaScorecards(evidence);
    case 'b25-c03-production-grade-experience':
    case 'b25-c04-modern-intentional-ui':
    case 'b25-c05-community-content-ia':
    case 'b25-c09-no-layout-production-defects':
      return _failOnVisualInspection(screenRows) ??
          _failOnDirectQuestionAnswers(
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
          _failOnVisualInspection(screenRows) ??
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

bool _isNonProductionEvidenceWorkflow(String workflowId) {
  final slug = _slug(workflowId);
  return slug == 'workflow-ui-evidence-harness' || slug == 'b12-harness';
}

String _personaForEvidence({
  required String workflowId,
  required String communityId,
  required String screenshotName,
}) {
  final fromScreenshot = _personaFromScreenshotName(screenshotName);
  if (_isSpecificPersona(fromScreenshot, _personaIdFromLabel(fromScreenshot))) {
    return fromScreenshot;
  }
  final lower = '${workflowId.toLowerCase()} ${communityId.toLowerCase()}';
  if (lower.contains('guardian') ||
      lower.contains('parent') ||
      lower.contains('minor') ||
      lower.contains('soccer-registration') ||
      lower.contains('practice') ||
      lower.contains('reminder')) {
    return 'guardian';
  }
  if (lower.contains('coach') || lower.contains('team-roster')) {
    return 'coach';
  }
  if (lower.contains('donor') || lower.contains('donation')) {
    return 'donor';
  }
  if (lower.contains('owner') ||
      lower.contains('committee') ||
      lower.contains('architectural') ||
      lower.contains('selection-publish') ||
      lower.contains('export') ||
      lower.contains('transfer') ||
      lower.contains('announcement')) {
    return 'owner';
  }
  if (lower.contains('admin')) {
    return 'admin';
  }
  if (lower.contains('organizer')) {
    return 'organizer';
  }
  return 'member';
}

String _personaIdForEvidence({
  required String persona,
  required String communityId,
}) {
  final personaSlug = _personaIdFromLabel(persona);
  if (personaSlug.isEmpty) {
    return '';
  }
  final communitySlug = _slug(communityId);
  if (communitySlug.isEmpty) {
    return personaSlug;
  }
  return '$communitySlug-$personaSlug';
}

String _personaIdFromLabel(String persona) {
  final slug = _slug(persona);
  if (slug.isEmpty ||
      slug == 'unknown' ||
      slug == 'persona-under-review' ||
      slug == 'persona' ||
      slug == 'user') {
    return '';
  }
  return slug;
}

bool _isSpecificPersona(String persona, String personaId) {
  if (personaId.isEmpty) {
    return false;
  }
  final slug = _slug(persona);
  return slug.isNotEmpty &&
      slug != 'unknown' &&
      slug != 'persona-under-review' &&
      slug != 'persona' &&
      slug != 'user';
}

bool _surfaceClassificationIsUnverified(
  String classification,
  String primarySurface,
) {
  final combined =
      '${classification.toLowerCase()} ${primarySurface.toLowerCase()}';
  if (combined.trim().isEmpty) {
    return true;
  }
  return combined.contains('pending') ||
      combined.contains('unverified') ||
      combined.contains('incomplete') ||
      combined.contains('unspecified') ||
      combined.contains('missing') ||
      combined.contains('generic-workflow-card') ||
      combined.contains('checklist-modal') ||
      combined.contains('metadata-page') ||
      combined.contains('global-workflow-list') ||
      combined.contains('repeated-card-shell');
}

String _initialB25SurfaceClassification({
  required String workflowId,
  required String visibleText,
}) {
  final targetSurface = _targetProductionSurfaceForWorkflow(workflowId);
  if (targetSurface.contains('explicit domain-native product surface')) {
    return 'surface-target-unspecified';
  }
  if (visibleText.trim().isEmpty) {
    return 'visible-text-missing';
  }
  if (_workflowIsSupportSurface(workflowId)) {
    return 'secondary-supporting-reviewed';
  }
  return 'domain-native-reviewed';
}

String _initialB25PrimarySurfaceType({
  required String workflowId,
  required String visibleText,
}) {
  final classification = _initialB25SurfaceClassification(
    workflowId: workflowId,
    visibleText: visibleText,
  );
  if (classification == 'domain-native-reviewed') {
    return 'domain-native';
  }
  if (classification == 'secondary-supporting-reviewed') {
    return 'secondary-supporting';
  }
  return 'unverified-primary-surface';
}

bool _workflowIsSupportSurface(String workflowId) {
  final id = workflowId.toLowerCase();
  return id.contains('persona-picker') ||
      id.contains('persona-role-inventory') ||
      id.contains('persona-aware-ux') ||
      id.contains('multi-persona-workflow-evidence');
}

String _screenTypeFromScreenshotName(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('start') ||
      lower.contains('picker') ||
      lower.contains('ready') ||
      lower.contains('active') ||
      lower.contains('selected')) {
    return 'entry';
  }
  if (lower.contains('action') ||
      lower.contains('dialog') ||
      lower.contains('actor') ||
      lower.contains('review')) {
    return 'action-or-review';
  }
  if (lower.contains('complete') ||
      lower.contains('received') ||
      lower.contains('selected') ||
      lower.contains('active')) {
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
  final holisticAnswers = _asMapList(review['holisticQuestionAnswers']);
  final workflowScorecards = _asMapList(review['workflowPersonaScorecards']);
  final failingWorkflowScorecards = workflowScorecards
      .where((scorecard) => scorecard['blocksPass'] == true)
      .length;
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
    ..writeln('Holistic direct-question answers: ${holisticAnswers.length}')
    ..writeln()
    ..writeln(
      'Workflow/persona scorecards: ${workflowScorecards.length} (${failingWorkflowScorecards} blocking)',
    )
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
    ..writeln('## Holistic Direct Questions')
    ..writeln()
    ..writeln('| Question | Verdict | Score | Why | Required fix |')
    ..writeln('| --- | --- | ---: | --- | --- |');
  if (holisticAnswers.isEmpty) {
    buffer.writeln(
      '| Missing | fail | 0 | No holistic answers present. | Run the independent UX judge. |',
    );
  } else {
    for (final answer in holisticAnswers) {
      buffer.writeln(
        '| ${_escape(_asString(answer['question']))} | `${_escape(_asString(answer['verdict']))}` | ${answer['score'] ?? 0} | ${_escape(_asString(answer['why']))} | ${_escape(_asString(answer['requiredFix']))} |',
      );
    }
  }
  buffer
    ..writeln()
    ..writeln('## Workflow/Persona Scorecards')
    ..writeln()
    ..writeln('| Scorecard | Status | Screens | Summary |')
    ..writeln('| --- | --- | ---: | --- |');
  if (workflowScorecards.isEmpty) {
    buffer.writeln('| Missing | fail | 0 | Run the independent UX judge. |');
  } else {
    for (final scorecard in workflowScorecards.take(80)) {
      buffer.writeln(
        '| `${_escape(_asString(scorecard['scorecardId']))}` | `${_escape(_asString(scorecard['status']))}` | ${_asStringList(scorecard['screenRowIds']).length} | ${_escape(_asString(scorecard['summary']))} |',
      );
    }
  }
  buffer
    ..writeln()
    ..writeln('## Review Note')
    ..writeln()
    ..writeln(
      'This file is generated from B25 evidence plus the independent UX judge output. The deterministic production UX judge validates this output and emits remediation tickets; the worker agent does not grade its own UI.',
    );
  return buffer.toString();
}

String _b25ScreenMatrixMarkdown(JsonMap review) {
  final rows = _asMapList(review['screenRows']);
  final buffer = StringBuffer()
    ..writeln('# B25 Product UX Screen Review Matrix')
    ..writeln()
    ..writeln(
      '| Row | Community | Persona | Workflow | Screen/state | Screenshot | Hash | Verdict | Visual inspection | Critique |',
    )
    ..writeln('| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |');
  for (final row in rows) {
    final inspection = row['visualInspection'] as JsonMap?;
    buffer.writeln(
      '| `${_escape(_asString(row['rowId']))}` | ${_escape(_asString(row['communityName']))} | ${_escape(_asString(row['persona']))} | `${_escape(_asString(row['workflowId']))}` | ${_escape(_asString(row['screenOrState']))} | ${_escape(_asString(row['screenshotPath']))} | `${_escape(_asString(row['screenshotHash']))}` | ${_escape(_asString(row['verdict']))} | ${_escape(_asString(inspection?['summary']))} | ${_escape(_asString(row['screenSpecificCritique']))} |',
    );
  }
  return buffer.toString();
}

String _b25VisualInspectionMarkdown(JsonMap review) {
  final rows = _asMapList(review['screenRows']);
  final summary = (review['visualInspectionSummary'] as JsonMap?) ?? {};
  final buffer = StringBuffer()
    ..writeln('# B25 Visual Inspection Audit')
    ..writeln()
    ..writeln('Status: `${_escape(_asString(summary['status']))}`')
    ..writeln()
    ..writeln(
      'Rows: ${_asInt(summary['screenRowCount'])}; failing: ${_asInt(summary['failingScreenRowCount'])}; passing: ${_asInt(summary['passedScreenRowCount'])}',
    )
    ..writeln()
    ..writeln(
      '| Row | Community | Persona | Workflow | Screenshot | Status | Findings | Summary |',
    )
    ..writeln('| --- | --- | --- | --- | --- | --- | --- | --- |');
  for (final row in rows.take(160)) {
    final inspection = row['visualInspection'] as JsonMap?;
    buffer.writeln(
      '| `${_escape(_rowId(row))}` | ${_escape(_asString(row['communityName'], fallback: _asString(row['communityId'])))} | ${_escape(_asString(row['persona']))} | `${_escape(_asString(row['workflowId']))}` | `${_escape(_asString(row['screenshotPath']))}` | `${_escape(_asString(inspection?['status']))}` | ${_escape(_asStringList(inspection?['findingIds']).join(', '))} | ${_escape(_asString(inspection?['summary']))} |',
    );
  }
  if (rows.length > 160) {
    buffer
      ..writeln()
      ..writeln('_Showing 160 of ${rows.length} screen rows._');
  }
  return buffer.toString();
}

String _b25WorkflowPersonaCoverageMarkdown(JsonMap review) {
  final summary = review['workflowPersonaCoverageSummary'] is JsonMap
      ? review['workflowPersonaCoverageSummary'] as JsonMap
      : <String, Object?>{};
  final rows = _asMapList(review['workflowPersonaCoverage']);
  final buffer = StringBuffer()
    ..writeln('# B25 Workflow/Persona Coverage Matrix')
    ..writeln()
    ..writeln('| Field | Value |')
    ..writeln('| --- | --- |')
    ..writeln('| Status | `${_escape(_asString(summary['status']))}` |')
    ..writeln(
      '| Coverage rows | ${summary['coverageRowCount'] ?? rows.length} |',
    )
    ..writeln(
      '| Failing rows | ${summary['failingCoverageRowCount'] ?? rows.where((row) => row['status'] != 'pass').length} |',
    )
    ..writeln()
    ..writeln(
      '| Coverage row | Status | Community | Workflow | Persona | Screens | Missing evidence | Required fix |',
    )
    ..writeln('| --- | --- | --- | --- | --- | --- | --- | --- |');
  for (final row in rows) {
    buffer.writeln(
      '| `${_escape(_asString(row['coverageRowId']))}` | `${_escape(_asString(row['status']))}` | ${_escape(_asString(row['communityName']))} | `${_escape(_asString(row['workflowId']))}` | ${_escape(_asString(row['persona']))} | ${_asStringList(row['screenRowIds']).length} | ${_escape(_asStringList(row['missingEvidence']).join('; '))} | ${_escape(_asString(row['requiredFix']))} |',
    );
  }
  return buffer.toString();
}

String _coverageCollectorUsage() {
  return '''
b25_workflow_persona_coverage_collector (B25)
Checks whether B25 evidence has explicit screenshot coverage for every workflow/persona combination before independent UX review.

Usage:
  dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input <independent-production-ux-review.json> --output <independent-production-ux-review.json> [--markdown-output <workflow-persona-coverage-matrix.md>]
''';
}

String _visualInspectionAuditorUsage() {
  return '''
b25_visual_inspection_auditor (B25)
Inspects screenshot pixels/layout for checklist-modal, repeated-card shell, thin-content, weak-identity, and missing-image failures before independent UX review.

Usage:
  dart run packages/tooling/loom_ux_judges/bin/b25_visual_inspection_auditor.dart --input <independent-production-ux-review.json> --output <independent-production-ux-review.json> [--markdown-output <b25-visual-inspection-audit.md>]
''';
}

String _independentUxJudgeUsage() {
  return '''
b25_independent_ux_judge (B25)
Consumes B25 screenshot evidence and workflow/persona coverage, inspects screenshot pixels/layout, then writes holistic direct-question answers, workflow/persona scorecards, screen-specific critiques, visual findings, and exact findings for the deterministic Production UX Judge.

Usage:
  dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input <independent-production-ux-review.json> --output <independent-production-ux-review.json> [--markdown-output <independent-production-ux-review.md>] [--matrix-output <product-ux-screen-review-matrix.md>]
''';
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
  final workItemSummary =
      plan['workItemSummary'] as JsonMap? ?? <String, Object?>{};
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
    ..writeln(
      '| Evidence repair work items | ${workItemSummary['evidenceRepairWorkItemCount'] ?? 0} |',
    )
    ..writeln(
      '| UI remediation work items | ${workItemSummary['uiRemediationWorkItemCount'] ?? 0} |',
    )
    ..writeln(
      '| Work item sequencing | ${_escape(_asString(workItemSummary['sequencing']))} |',
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
    final likelyFiles = _asStringList(batch['likelyFilesOrWidgets']);
    if (likelyFiles.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('### Likely Files / Widgets');
      for (final file in likelyFiles) {
        buffer.writeln('- `${_escape(file)}`');
      }
    }
    _writeReferencePatternsMarkdown(
      buffer,
      'UX Reference Patterns To Copy',
      _asMapList(batch['uxReferencePatterns']),
    );
    final referenceQueries = _asStringList(batch['referenceResearchQueries']);
    if (referenceQueries.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('### Reference Research Queries');
      for (final query in referenceQueries.take(20)) {
        buffer.writeln('- ${_escape(query)}');
      }
    }
    _writeWorkItemsMarkdown(
      buffer,
      'Evidence Repair Work Items',
      _asMapList(batch['evidenceRepairWorkItems']),
    );
    _writeWorkItemsMarkdown(
      buffer,
      'UI Remediation Work Items',
      _asMapList(batch['uiRemediationWorkItems']),
    );
    final coverageRows = _asMapList(batch['affectedCoverageRows']);
    if (coverageRows.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('### Affected Coverage Rows')
        ..writeln()
        ..writeln(
          'Showing ${coverageRows.take(30).length} of ${coverageRows.length} affected coverage rows.',
        )
        ..writeln()
        ..writeln(
          '| Coverage row | Community | Workflow | Persona | Missing evidence |',
        )
        ..writeln('| --- | --- | --- | --- | --- |');
      for (final row in coverageRows.take(30)) {
        buffer.writeln(
          '| `${_escape(_asString(row['coverageRowId']))}` | ${_escape(_asString(row['communityName']))} | `${_escape(_asString(row['workflowId']))}` | ${_escape(_asString(row['persona']))} | ${_escape(_asStringList(row['missingEvidence']).join('; '))} |',
        );
      }
    }
    final screenRows = _asMapList(batch['affectedScreenRows']);
    if (screenRows.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('### Affected Screen Rows')
        ..writeln()
        ..writeln(
          'Showing ${screenRows.take(30).length} of ${screenRows.length} affected screen rows.',
        )
        ..writeln()
        ..writeln(
          '| Screen row | Community | Workflow | Persona | State | Exact UX failure |',
        )
        ..writeln('| --- | --- | --- | --- | --- | --- |');
      for (final row in screenRows.take(30)) {
        buffer.writeln(
          '| `${_escape(_asString(row['screenRowId']))}` | ${_escape(_asString(row['communityName']))} | `${_escape(_asString(row['workflowId']))}` | ${_escape(_asString(row['persona']))} | ${_escape(_asString(row['screenState']))} | ${_escape(_asString(row['exactUxFailure']))} |',
        );
      }
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
    final concreteAcceptance = _asStringList(
      batch['concreteAcceptanceCriteria'],
    );
    if (concreteAcceptance.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('### Concrete Acceptance Criteria');
      for (final check in concreteAcceptance.take(40)) {
        buffer.writeln('- ${_escape(check)}');
      }
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
    final ticketContext = _b25TicketContext(
      evidence,
      criterion,
      relatedFindings,
    );
    final remediationMode = _b25RemediationMode(criterion, ticketContext);
    final ticketId =
        'B25-RT-${index.toString().padLeft(3, '0')}-${_slug(criterion.id)}';
    tickets.add(<String, Object?>{
      'ticketId': ticketId,
      'ticketSchemaVersion': 4,
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
      'remediationMode': remediationMode['mode'],
      'workerReadiness': remediationMode['workerReadiness'],
      'firstRequiredStep': remediationMode['firstRequiredStep'],
      'implementationBlockedBy': remediationMode['implementationBlockedBy'],
      'affectedScope': ticketContext['affectedScope'],
      'affectedCoverageRowIds': ticketContext['affectedCoverageRowIds'],
      'affectedScreenRowIds': ticketContext['affectedScreenRowIds'],
      'affectedCoverageRows': ticketContext['affectedCoverageRows'],
      'affectedScreenRows': ticketContext['affectedScreenRows'],
      'failingWorkflowPersonaScorecards':
          ticketContext['failingWorkflowPersonaScorecards'],
      'failingDirectQuestions': ticketContext['failingDirectQuestions'],
      'evidenceRepairWorkItems': ticketContext['evidenceRepairWorkItems'],
      'uiRemediationWorkItems': ticketContext['uiRemediationWorkItems'],
      'likelyFilesOrWidgets': ticketContext['likelyFilesOrWidgets'],
      'uxReferencePatterns': ticketContext['uxReferencePatterns'],
      'referenceResearchQueries': ticketContext['referenceResearchQueries'],
      'sourceResearchRequirement':
          'The independent UX review must attach internet or open-source pattern references before UI remediation. If live research is unavailable, use the bundled catalog entries and keep the research queries in the ticket so a reviewer can refresh them.',
      'concreteAcceptanceCriteria': ticketContext['concreteAcceptanceCriteria'],
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

JsonMap _b25TicketContext(
  JsonMap evidence,
  CriterionResult criterion,
  List<String> relatedFindingIds,
) {
  final screenRows = _asMapList(evidence['screenRows']);
  final coverageRows = _asMapList(evidence['workflowPersonaCoverage']);
  final scorecards = _asMapList(evidence['workflowPersonaScorecards']);
  final holisticAnswers = _asMapList(evidence['holisticQuestionAnswers']);
  final findings = _asMapList(evidence['findings']);
  final screenById = <String, JsonMap>{
    for (final row in screenRows) _rowId(row): row,
  };
  final coverageById = <String, JsonMap>{
    for (final row in coverageRows) _asString(row['coverageRowId']): row,
  };
  final scorecardById = <String, JsonMap>{
    for (final row in scorecards) _asString(row['scorecardId']): row,
  };
  final questionById = <String, JsonMap>{
    for (final row in holisticAnswers) _asString(row['questionId']): row,
  };
  final coverageIds = <String>{};
  final scorecardIds = <String>{};
  final screenIds = <String>{};
  final questionIds = <String>{};

  for (final finding in findings) {
    if (!relatedFindingIds.contains(_findingId(finding))) {
      continue;
    }
    coverageIds.addAll(_asStringList(finding['affectedCoverageRowIds']));
    scorecardIds.addAll(_asStringList(finding['affectedScorecardIds']));
    screenIds.addAll(_asStringList(finding['affectedScreenRowIds']));
    questionIds.addAll(_asStringList(finding['affectedQuestionIds']));
  }

  for (final token in criterion.evidenceUsed) {
    if (screenById.containsKey(token)) {
      screenIds.add(token);
      continue;
    }
    if (coverageById.containsKey(token)) {
      coverageIds.add(token);
      continue;
    }
    if (scorecardById.containsKey(token)) {
      scorecardIds.add(token);
      continue;
    }
    if (questionById.containsKey(token)) {
      questionIds.add(token);
      continue;
    }
    for (final scorecard in scorecards) {
      if (_workflowPersonaEvidenceKeys(scorecard).contains(token)) {
        scorecardIds.add(_asString(scorecard['scorecardId']));
      }
    }
    for (final coverage in coverageRows) {
      if (_workflowPersonaEvidenceKeys(coverage).contains(token)) {
        coverageIds.add(_asString(coverage['coverageRowId']));
      }
    }
  }

  if (criterion.scope == 'holistic') {
    questionIds.addAll(
      holisticAnswers
          .where((answer) => answer['blocksPass'] == true)
          .map((answer) => _asString(answer['questionId'])),
    );
    if (screenIds.isEmpty) {
      screenIds.addAll(
        screenRows
            .where((row) => _asString(row['verdict']) != 'pass')
            .map(_rowId),
      );
    }
  }

  if (criterion.scope == 'workflow-persona') {
    if (scorecardIds.isEmpty) {
      scorecardIds.addAll(
        scorecards
            .where((scorecard) => scorecard['blocksPass'] == true)
            .map((scorecard) => _asString(scorecard['scorecardId'])),
      );
    }
    for (final scorecardId in scorecardIds.toList()) {
      final scorecard = scorecardById[scorecardId];
      if (scorecard == null) {
        continue;
      }
      screenIds.addAll(_asStringList(scorecard['screenRowIds']));
      if (coverageById.containsKey(scorecardId)) {
        coverageIds.add(scorecardId);
      }
    }
  }

  if (criterion.id == 'b25-c01-no-blocker-major') {
    for (final finding in findings.where((finding) => !_isResolved(finding))) {
      coverageIds.addAll(_asStringList(finding['affectedCoverageRowIds']));
      scorecardIds.addAll(_asStringList(finding['affectedScorecardIds']));
      screenIds.addAll(_asStringList(finding['affectedScreenRowIds']));
      questionIds.addAll(_asStringList(finding['affectedQuestionIds']));
    }
    if (screenIds.isEmpty) {
      screenIds.addAll(
        screenRows
            .where((row) => _asString(row['verdict']) != 'pass')
            .map(_rowId),
      );
    }
  }

  for (final coverageId in coverageIds.toList()) {
    final coverage = coverageById[coverageId];
    if (coverage != null) {
      screenIds.addAll(_asStringList(coverage['screenRowIds']));
    }
  }
  for (final scorecardId in scorecardIds.toList()) {
    final scorecard = scorecardById[scorecardId];
    if (scorecard != null) {
      screenIds.addAll(_asStringList(scorecard['screenRowIds']));
    }
  }

  final affectedCoverageRows = coverageRows
      .where((row) => coverageIds.contains(_asString(row['coverageRowId'])))
      .map(_coverageTicketDetail)
      .toList();
  final affectedScreenRows = screenRows
      .where((row) => screenIds.contains(_rowId(row)))
      .map((row) => _screenRowTicketDetail(row, criterion.id))
      .toList();
  final failingScorecards = scorecards
      .where((row) => scorecardIds.contains(_asString(row['scorecardId'])))
      .map((row) => _scorecardTicketDetail(row, criterion.id))
      .toList();
  final failingQuestions = holisticAnswers
      .where((row) => questionIds.contains(_asString(row['questionId'])))
      .map(_directQuestionTicketDetail)
      .toList();
  final likelyFiles = <String>{
    ..._likelyFilesForB25Criterion(criterion.id),
    for (final row in affectedScreenRows)
      ..._asStringList(row['likelyFilesOrWidgets']),
  }.where((value) => value.isNotEmpty).toList();
  final workflowIds = <String>{
    for (final row in affectedScreenRows) _asString(row['workflowId']),
    for (final row in affectedCoverageRows) _asString(row['workflowId']),
    for (final row in failingScorecards) _asString(row['workflowId']),
  }..remove('');
  final uxReferencePatterns = _dedupeReferencePatterns(<JsonMap>[
    ..._b25CriterionReferencePatterns(criterion.id),
    for (final workflowId in workflowIds)
      ..._b25ReferencePatternsForWorkflow(workflowId),
  ]);
  final referenceResearchQueries = _uniqueStrings(<String>[
    ..._b25CriterionReferenceQueries(criterion.id),
    for (final workflowId in workflowIds)
      ..._referenceResearchQueriesForWorkflow(workflowId),
  ]);
  final concreteAcceptance = <String>{
    ..._acceptanceChecksForB25Criterion(criterion.id),
    for (final row in affectedScreenRows.take(12))
      ..._asStringList(row['acceptanceCriteria']),
    for (final row in affectedCoverageRows.take(12))
      ..._asStringList(row['acceptanceCriteria']),
  }.where((value) => value.isNotEmpty).toList();
  final evidenceRepairWorkItems = _b25WorkItems(
    stage: 'evidence-repair',
    criterionId: criterion.id,
    screenRows: affectedScreenRows,
    coverageRows: affectedCoverageRows,
    scorecards: failingScorecards,
  );
  final uiRemediationWorkItems = _b25WorkItems(
    stage: 'ui-remediation',
    criterionId: criterion.id,
    screenRows: affectedScreenRows,
    coverageRows: affectedCoverageRows,
    scorecards: failingScorecards,
  );

  return <String, Object?>{
    'affectedScope': _concreteAffectedScope(
      criterion,
      affectedScreenRows,
      affectedCoverageRows,
      failingScorecards,
      failingQuestions,
    ),
    'affectedCoverageRowIds': [
      for (final row in affectedCoverageRows) _asString(row['coverageRowId']),
    ],
    'affectedScreenRowIds': [
      for (final row in affectedScreenRows) _asString(row['screenRowId']),
    ],
    'affectedCoverageRows': affectedCoverageRows,
    'affectedScreenRows': affectedScreenRows,
    'failingWorkflowPersonaScorecards': failingScorecards,
    'failingDirectQuestions': failingQuestions,
    'evidenceRepairWorkItems': evidenceRepairWorkItems,
    'uiRemediationWorkItems': uiRemediationWorkItems,
    'likelyFilesOrWidgets': likelyFiles,
    'uxReferencePatterns': uxReferencePatterns,
    'referenceResearchQueries': referenceResearchQueries,
    'concreteAcceptanceCriteria': concreteAcceptance,
  };
}

Set<String> _workflowPersonaEvidenceKeys(JsonMap row) {
  final workflowId = _asString(row['workflowId']);
  final persona = _asString(row['persona']);
  final personaId = _asString(row['personaId']);
  return <String>{
    if (workflowId.isNotEmpty && persona.isNotEmpty) '$workflowId/$persona',
    if (workflowId.isNotEmpty && personaId.isNotEmpty) '$workflowId/$personaId',
    _asString(row['scorecardId']),
    _asString(row['coverageRowId']),
  }..removeWhere((value) => value.isEmpty);
}

JsonMap _b25RemediationMode(CriterionResult criterion, JsonMap ticketContext) {
  final evidenceItems = _asMapList(ticketContext['evidenceRepairWorkItems']);
  final uiItems = _asMapList(ticketContext['uiRemediationWorkItems']);
  if (criterion.id == 'b25-c01-no-blocker-major') {
    return <String, Object?>{
      'mode': 'closeout-after-all-remediation',
      'workerReadiness':
          'blocked until the evidence and UI remediation tickets are resolved',
      'firstRequiredStep':
          'Do not implement from this summary ticket directly; resolve the referenced evidence and UI tickets, then rerun the production UX judge.',
      'implementationBlockedBy': <String>[
        'Open blocker/major B25 tickets remain.',
        'The scorecard cannot close until those tickets rerun clean.',
      ],
    };
  }
  if (evidenceItems.isNotEmpty) {
    return <String, Object?>{
      'mode': uiItems.isEmpty
          ? 'evidence-repair-first'
          : 'evidence-repair-before-ui-remediation',
      'workerReadiness':
          'not ready for UI implementation until evidence repair work items are completed and the independent judge reruns',
      'firstRequiredStep':
          'Complete the evidenceRepairWorkItems: concrete persona/personaId, screenshot-derived visible text, screen-specific critique, coverage row proof, and workflow/persona scorecards.',
      'implementationBlockedBy': <String>[
        'Affected rows still use generic or missing persona data.',
        'Visible text is not proven from screenshot OCR/manual extraction.',
        'Screen-specific critiques are incomplete or reusable.',
        'Primary surface classification is incomplete or unverified.',
      ],
    };
  }
  if (uiItems.isNotEmpty) {
    return <String, Object?>{
      'mode': 'ui-remediation-ready',
      'workerReadiness':
          'ready for worker implementation using the uiRemediationWorkItems',
      'firstRequiredStep':
          'Implement the target production surfaces and content specified in uiRemediationWorkItems, then recapture screenshots.',
      'implementationBlockedBy': <String>[],
    };
  }
  return <String, Object?>{
    'mode': 'review-only',
    'workerReadiness':
        'no concrete implementation work item was generated; planner must inspect the direct-question failure before assigning a worker',
    'firstRequiredStep':
        'Review failing direct questions and add screen/workflow/persona-specific evidence before implementation.',
    'implementationBlockedBy': <String>[
      'The ticket lacks row-level implementation evidence.',
    ],
  };
}

List<JsonMap> _b25WorkItems({
  required String stage,
  required String criterionId,
  required List<JsonMap> screenRows,
  required List<JsonMap> coverageRows,
  required List<JsonMap> scorecards,
}) {
  if (criterionId == 'b25-c01-no-blocker-major') {
    return <JsonMap>[];
  }
  final includeUi = _isB25UiRemediationCriterion(criterionId);
  final includeEvidence =
      stage == 'evidence-repair' ||
      criterionId == 'b25-c08-visible-text-specific-critique';
  if (stage == 'ui-remediation' && !includeUi) {
    return <JsonMap>[];
  }
  if (stage == 'evidence-repair' && !includeEvidence) {
    return <JsonMap>[];
  }

  final itemsByKey = <String, JsonMap>{};
  JsonMap ensureItem({
    required String communityId,
    required String communityName,
    required String workflowId,
    required String persona,
    required String personaId,
  }) {
    final key = [
      communityId,
      workflowId,
      personaId.isNotEmpty ? personaId : persona,
      stage,
    ].join('::');
    return itemsByKey.putIfAbsent(key, () {
      final targetSurface = _targetProductionSurfaceForWorkflow(workflowId);
      return <String, Object?>{
        'workItemId':
            'b25-wi-${_slug(stage)}-${_slug(communityId.isNotEmpty ? communityId : communityName)}-${_slug(workflowId)}-${_slug(personaId.isNotEmpty ? personaId : persona)}',
        'stage': stage,
        'criterionId': criterionId,
        'communityId': communityId,
        'communityName': communityName,
        'workflowId': workflowId,
        'persona': persona,
        'personaId': personaId,
        'targetProductionSurface': targetSurface,
        'referencePatternsToCopy': _b25ReferencePatternsForWorkflow(workflowId),
        'referenceResearchQueries': _referenceResearchQueriesForWorkflow(
          workflowId,
        ),
        'uxReferenceChecklist': _uxReferenceChecklistForWorkflow(workflowId),
        'affectedScreenRowIds': <String>[],
        'affectedCoverageRowIds': <String>[],
        'affectedScorecardIds': <String>[],
        'screenshotPaths': <String>[],
        'screenshotHashes': <String>[],
        'visibleTextExcerpts': <String>[],
        'currentFailures': <String>[],
        'likelyFilesOrWidgets': <String>{}.toList(),
        'workerActions': stage == 'evidence-repair'
            ? _evidenceRepairWorkerActions(workflowId, persona, targetSurface)
            : _uiRemediationWorkerActions(workflowId, persona, targetSurface),
        'acceptanceCriteria': stage == 'evidence-repair'
            ? _evidenceRepairAcceptanceCriteria(workflowId, persona)
            : _uiRemediationAcceptanceCriteria(
                workflowId,
                persona,
                targetSurface,
              ),
        'blockedUntil': stage == 'ui-remediation'
            ? 'Evidence-repair work item for this community/workflow/persona has fresh screenshots, screenshot-derived visible text, a specific persona/personaId, and a non-boilerplate critique.'
            : '',
      };
    });
  }

  void addUnique(JsonMap item, String field, Iterable<String> values) {
    final current = <String>{
      ..._asStringList(item[field]),
      for (final value in values)
        if (value.trim().isNotEmpty) value.trim(),
    }.toList();
    item[field] = current;
  }

  for (final row in screenRows) {
    if (stage == 'evidence-repair' && !_screenDetailNeedsEvidenceRepair(row)) {
      continue;
    }
    final workflowId = _asString(row['workflowId']);
    final item = ensureItem(
      communityId: _asString(row['communityId']),
      communityName: _asString(row['communityName']),
      workflowId: workflowId,
      persona: _asString(row['persona']),
      personaId: _asString(row['personaId']),
    );
    addUnique(item, 'affectedScreenRowIds', [_asString(row['screenRowId'])]);
    addUnique(item, 'screenshotPaths', [_asString(row['screenshotPath'])]);
    addUnique(item, 'screenshotHashes', [_asString(row['screenshotHash'])]);
    addUnique(item, 'visibleTextExcerpts', [
      _asString(row['visibleTextExcerpt']),
    ]);
    addUnique(item, 'currentFailures', [_asString(row['exactUxFailure'])]);
    addUnique(
      item,
      'likelyFilesOrWidgets',
      _asStringList(row['likelyFilesOrWidgets']),
    );
    addUnique(
      item,
      'acceptanceCriteria',
      _asStringList(row['acceptanceCriteria']),
    );
  }

  for (final coverage in coverageRows) {
    final item = ensureItem(
      communityId: _asString(coverage['communityId']),
      communityName: _asString(coverage['communityName']),
      workflowId: _asString(coverage['workflowId']),
      persona: _asString(coverage['persona']),
      personaId: _asString(coverage['personaId']),
    );
    addUnique(item, 'affectedCoverageRowIds', [
      _asString(coverage['coverageRowId']),
    ]);
    addUnique(
      item,
      'affectedScreenRowIds',
      _asStringList(coverage['screenRowIds']),
    );
    addUnique(
      item,
      'screenshotPaths',
      _asStringList(coverage['screenshotPaths']),
    );
    addUnique(
      item,
      'currentFailures',
      _asStringList(coverage['missingEvidence']),
    );
    addUnique(
      item,
      'acceptanceCriteria',
      _asStringList(coverage['acceptanceCriteria']),
    );
  }

  for (final scorecard in scorecards) {
    final item = ensureItem(
      communityId: _asString(scorecard['communityId']),
      communityName: _asString(scorecard['communityName']),
      workflowId: _asString(scorecard['workflowId']),
      persona: _asString(scorecard['persona']),
      personaId: _asString(scorecard['personaId']),
    );
    addUnique(item, 'affectedScorecardIds', [
      _asString(scorecard['scorecardId']),
    ]);
    addUnique(
      item,
      'affectedScreenRowIds',
      _asStringList(scorecard['screenRowIds']),
    );
    addUnique(
      item,
      'screenshotPaths',
      _asStringList(scorecard['screenshotPaths']),
    );
    addUnique(item, 'currentFailures', [_asString(scorecard['summary'])]);
    addUnique(
      item,
      'acceptanceCriteria',
      _asStringList(scorecard['acceptanceCriteria']),
    );
  }

  return _dedupeWorkItems(itemsByKey.values.toList());
}

bool _isB25UiRemediationCriterion(String criterionId) {
  return <String>{
    'b25-c03-production-grade-experience',
    'b25-c04-modern-intentional-ui',
    'b25-c05-community-content-ia',
    'b25-c06-domain-native-primary-surfaces',
    'b25-c09-no-layout-production-defects',
  }.contains(criterionId);
}

bool _screenDetailNeedsEvidenceRepair(JsonMap row) {
  final persona = _asString(row['persona']);
  final personaId = _asString(row['personaId']);
  final source = _asString(row['visibleTextSource']).toLowerCase();
  final surface = _asString(row['currentSurfaceClassification']).toLowerCase();
  final primarySurface = _asString(
    row['currentPrimarySurfaceType'],
  ).toLowerCase();
  final critique = _asString(row['currentCritique']).toLowerCase();
  return !_isSpecificPersona(persona, personaId) ||
      !(source.contains('screenshot') ||
          source.contains('ocr') ||
          source.contains('manual')) ||
      surface.contains('incomplete') ||
      surface.contains('pending') ||
      primarySurface.contains('unverified') ||
      critique.isEmpty ||
      critique.contains('pending') ||
      critique.contains('does not identify');
}

List<JsonMap> _dedupeWorkItems(List<JsonMap> workItems) {
  final byId = <String, JsonMap>{};
  for (final item in workItems) {
    final id = _asString(item['workItemId']);
    if (id.isEmpty) {
      continue;
    }
    final existing = byId[id];
    if (existing == null) {
      byId[id] = item;
      continue;
    }
    for (final field in <String>[
      'affectedScreenRowIds',
      'affectedCoverageRowIds',
      'affectedScorecardIds',
      'screenshotPaths',
      'screenshotHashes',
      'visibleTextExcerpts',
      'currentFailures',
      'likelyFilesOrWidgets',
      'referenceResearchQueries',
      'uxReferenceChecklist',
      'acceptanceCriteria',
    ]) {
      existing[field] = _uniqueStrings(<String>[
        ..._asStringList(existing[field]),
        ..._asStringList(item[field]),
      ]);
    }
    existing['referencePatternsToCopy'] = _dedupeReferencePatterns(<JsonMap>[
      ..._asMapList(existing['referencePatternsToCopy']),
      ..._asMapList(item['referencePatternsToCopy']),
    ]);
  }
  return byId.values.toList();
}

List<String> _evidenceRepairWorkerActions(
  String workflowId,
  String persona,
  String targetSurface,
) {
  return <String>[
    'Replace generic persona `${persona.isEmpty ? 'persona-under-review' : persona}` with the concrete actor/receiver persona and personaId for `${workflowId}`.',
    'Verify entry, action/review, and result/receiver screenshots exist for `${workflowId}` and are tied to the concrete persona.',
    'Extract visible text from the listed screenshots or manually transcribe exactly what is visible.',
    'Write a non-reusable critique that names the visible UI, visible text, persona, user task, current failure, and target surface: ${targetSurface}.',
    'Rerun the workflow/persona coverage collector and independent UX judge before assigning UI implementation work.',
  ];
}

List<String> _uiRemediationWorkerActions(
  String workflowId,
  String persona,
  String targetSurface,
) {
  return <String>[
    'Replace the current primary surface for `${workflowId}` with ${targetSurface}.',
    'Build the entry, action/review, and result states for `${persona.isEmpty ? 'the target persona' : persona}` using domain content and semantic action labels.',
    'Remove workflow-harness, validation, metadata, checklist, or generic repeated-card language from the user-facing surface.',
    'Update widget/integration tests and B25 evidence expectations for the changed UI.',
    'Recapture screenshots and rerun the workflow/persona direct-question scorecard.',
  ];
}

List<String> _evidenceRepairAcceptanceCriteria(
  String workflowId,
  String persona,
) {
  return <String>[
    '`${workflowId}` has concrete persona/personaId coverage, not `persona-under-review`.',
    'Entry/action/result screenshot rows exist for `${workflowId}` and each row has screenshot path, hash, timestamp, device metadata, and app commit SHA.',
    'Visible text is screenshot-derived or manually transcribed from the screenshot for every affected row.',
    'Each affected row has a screen-specific critique that cannot be reused unchanged for another workflow.',
    'Workflow/persona coverage collector no longer flags missing persona or screenshot evidence for `${workflowId}`.',
  ];
}

List<String> _uiRemediationAcceptanceCriteria(
  String workflowId,
  String persona,
  String targetSurface,
) {
  return <String>[
    'The primary `${workflowId}` screen is ${targetSurface}, not a generic workflow card, metadata page, checklist modal, or validation surface.',
    'Visible content includes the real domain data, user goal, semantic action, validation/review state, and result/receipt/receiver state expected for `${persona.isEmpty ? 'the target persona' : persona}`.',
    'The workflow/persona direct-question scorecard passes for task clarity, domain-native surface, natural actions, and production-grade UI.',
    'Fresh screenshots prove the remediated entry/action/result states after the code change.',
  ];
}

JsonMap _concreteAffectedScope(
  CriterionResult criterion,
  List<JsonMap> screenRows,
  List<JsonMap> coverageRows,
  List<JsonMap> scorecards,
  List<JsonMap> directQuestions,
) {
  final communities = _uniqueStrings(<String>[
    for (final row in screenRows) _asString(row['communityName']),
    for (final row in coverageRows) _asString(row['communityName']),
    for (final row in scorecards) _asString(row['communityName']),
  ]);
  final personas = _uniqueStrings(<String>[
    for (final row in screenRows) _asString(row['persona']),
    for (final row in coverageRows) _asString(row['persona']),
    for (final row in scorecards) _asString(row['persona']),
  ]);
  final workflows = _uniqueStrings(<String>[
    for (final row in screenRows) _asString(row['workflowId']),
    for (final row in coverageRows) _asString(row['workflowId']),
    for (final row in scorecards) _asString(row['workflowId']),
  ]);
  final screenshots = _uniqueStrings(<String>[
    for (final row in screenRows) _asString(row['screenshotPath']),
    for (final row in coverageRows) ..._asStringList(row['screenshotPaths']),
  ]);
  return <String, Object?>{
    'scope': criterion.scope,
    'communities': communities.isEmpty
        ? <String>['all reviewed communities/test apps']
        : communities,
    'personas': personas.isEmpty
        ? <String>['all reviewed target personas']
        : personas,
    'workflows': workflows.isEmpty
        ? <String>['all primary reviewed workflows']
        : workflows,
    'screenRows': screenRows
        .map((row) => _asString(row['screenRowId']))
        .toList(),
    'coverageRows': coverageRows
        .map((row) => _asString(row['coverageRowId']))
        .toList(),
    'scorecards': scorecards
        .map((row) => _asString(row['scorecardId']))
        .toList(),
    'directQuestions': directQuestions
        .map((row) => _asString(row['questionId']))
        .toList(),
    'screenshots': screenshots,
  };
}

JsonMap _screenRowTicketDetail(JsonMap row, String criterionId) {
  final workflowId = _asString(row['workflowId']);
  final targetSurface = _targetProductionSurfaceForWorkflow(workflowId);
  return <String, Object?>{
    'screenRowId': _rowId(row),
    'communityId': _asString(row['communityId']),
    'communityName': _asString(row['communityName']),
    'workflowId': workflowId,
    'persona': _asString(row['persona']),
    'personaId': _asString(row['personaId']),
    'screenState': _asString(row['screenOrState']),
    'screenType': _asString(row['screenType']),
    'screenshotPath': _asString(row['screenshotPath']),
    'screenshotHash': _asString(row['screenshotHash']),
    'screenshotCapturedAt': _asString(row['screenshotCapturedAt']),
    'appCommitSha': _asString(row['appCommitSha']),
    'deviceMetadata': _asString(row['deviceMetadata']),
    'visibleTextExcerpt': _truncate(_asString(row['visibleTextExtract']), 280),
    'visibleTextSource': _asString(row['visibleTextExtractionSource']),
    'currentSurfaceClassification': _asString(row['uiPatternClassification']),
    'currentPrimarySurfaceType': _asString(row['primarySurfaceType']),
    'currentVerdict': _asString(row['verdict']),
    'currentSeverity': _asString(row['severity']),
    'currentCritique': _truncate(_asString(row['screenSpecificCritique']), 360),
    'exactUxFailure': _exactUxFailureForScreenRow(row, criterionId),
    'targetProductionSurface': targetSurface,
    'referencePatternsToCopy': _b25ReferencePatternsForWorkflow(workflowId),
    'referenceResearchQueries': _referenceResearchQueriesForWorkflow(
      workflowId,
    ),
    'uxReferenceChecklist': _uxReferenceChecklistForWorkflow(workflowId),
    'evidenceRepairNeeded': _screenDetailNeedsEvidenceRepair(<String, Object?>{
      'persona': _asString(row['persona']),
      'personaId': _asString(row['personaId']),
      'visibleTextSource': _asString(row['visibleTextExtractionSource']),
      'currentSurfaceClassification': _asString(row['uiPatternClassification']),
      'currentPrimarySurfaceType': _asString(row['primarySurfaceType']),
      'currentCritique': _asString(row['screenSpecificCritique']),
    }),
    'evidenceRepairActions': _evidenceRepairWorkerActions(
      workflowId,
      _asString(row['persona']),
      targetSurface,
    ),
    'uiRemediationActions': _uiRemediationWorkerActions(
      workflowId,
      _asString(row['persona']),
      targetSurface,
    ),
    'likelyFilesOrWidgets': _likelyFilesForB25Row(row, criterionId),
    'acceptanceCriteria': _screenRowAcceptanceCriteria(row, criterionId),
  };
}

JsonMap _coverageTicketDetail(JsonMap row) {
  final workflowId = _asString(row['workflowId']);
  return <String, Object?>{
    'coverageRowId': _asString(row['coverageRowId']),
    'status': _asString(row['status']),
    'communityId': _asString(row['communityId']),
    'communityName': _asString(row['communityName']),
    'workflowId': workflowId,
    'persona': _asString(row['persona']),
    'personaId': _asString(row['personaId']),
    'screenRowIds': _asStringList(row['screenRowIds']),
    'screenshotPaths': _asStringList(row['screenshotPaths']),
    'screenStates': _asStringList(row['screenStates']),
    'missingEvidence': _asStringList(row['missingEvidence']),
    'requiredFix': _asString(row['requiredFix']),
    'targetProductionSurface': _targetProductionSurfaceForWorkflow(workflowId),
    'referencePatternsToCopy': _b25ReferencePatternsForWorkflow(workflowId),
    'referenceResearchQueries': _referenceResearchQueriesForWorkflow(
      workflowId,
    ),
    'acceptanceCriteria': <String>[
      'Coverage row has a specific persona and personaId.',
      'Coverage row has entry, action/review, and result/receiver screenshots.',
      'Every listed screenshot path exists and has a fresh hash/timestamp/app commit SHA.',
      'The workflow/persona scorecard passes after rerun.',
    ],
  };
}

JsonMap _scorecardTicketDetail(JsonMap scorecard, String criterionId) {
  final workflowId = _asString(scorecard['workflowId']);
  final failingQuestions = _asMapList(scorecard['questions'])
      .where((question) => question['blocksPass'] == true)
      .map(_directQuestionTicketDetail)
      .toList();
  return <String, Object?>{
    'scorecardId': _asString(scorecard['scorecardId']),
    'status': _asString(scorecard['status']),
    'communityId': _asString(scorecard['communityId']),
    'communityName': _asString(scorecard['communityName']),
    'workflowId': workflowId,
    'persona': _asString(scorecard['persona']),
    'personaId': _asString(scorecard['personaId']),
    'screenRowIds': _asStringList(scorecard['screenRowIds']),
    'screenshotPaths': _asStringList(scorecard['screenshotPaths']),
    'summary': _asString(scorecard['summary']),
    'targetProductionSurface': _targetProductionSurfaceForWorkflow(workflowId),
    'referencePatternsToCopy': _b25ReferencePatternsForWorkflow(workflowId),
    'referenceResearchQueries': _referenceResearchQueriesForWorkflow(
      workflowId,
    ),
    'failingQuestions': failingQuestions,
    'acceptanceCriteria': <String>[
      'All direct questions in this workflow/persona scorecard pass.',
      'The primary surface is domain-native for `${workflowId}` and the target persona.',
      'Visible text and critique cite the actual screenshots for every screen row.',
      ..._screenRowAcceptanceCriteria(scorecard, criterionId),
    ],
  };
}

JsonMap _directQuestionTicketDetail(JsonMap question) {
  return <String, Object?>{
    'questionId': _asString(question['questionId']),
    'scope': _asString(question['scope']),
    'question': _asString(question['question']),
    'answer': _asString(question['answer']),
    'score': _asInt(question['score']),
    'verdict': _asString(question['verdict']),
    'why': _asString(question['why']),
    'requiredFix': _asString(question['requiredFix']),
    'evidenceUsed': _asStringList(question['evidenceUsed']),
    'visibleEvidence': _asStringList(question['visibleEvidence']),
  };
}

String _exactUxFailureForScreenRow(JsonMap row, String criterionId) {
  final failures = <String>[];
  final persona = _asString(row['persona']);
  final personaId = _asString(row['personaId']);
  if (!_isSpecificPersona(persona, personaId)) {
    failures.add(
      'Persona is generic or missing; the worker cannot know which role this screen serves.',
    );
  }
  final source = _asString(row['visibleTextExtractionSource']).toLowerCase();
  if (!(source.contains('screenshot') ||
      source.contains('ocr') ||
      source.contains('manual'))) {
    failures.add(
      'Visible text is not proven from screenshot OCR/manual extraction.',
    );
  }
  final classification = _asString(row['uiPatternClassification']);
  final primarySurface = _asString(row['primarySurfaceType']);
  if (classification.contains('incomplete') ||
      classification.contains('pending') ||
      primarySurface.contains('unverified')) {
    failures.add('Primary surface classification is incomplete or unverified.');
  }
  final critique = _asString(row['screenSpecificCritique']);
  if (critique.isEmpty ||
      critique.contains('does not identify') ||
      critique.contains('Pending')) {
    failures.add(
      'Screen-specific critique does not yet explain visible UI, persona, task, and remediation.',
    );
  }
  if (_asString(row['verdict']) != 'pass') {
    failures.add(
      'Current row verdict is `${_asString(row['verdict'])}` with severity `${_asString(row['severity'])}`.',
    );
  }
  if (criterionId == 'b25-c06-domain-native-primary-surfaces') {
    failures.add(
      'Ticket must prove the primary screen is a domain-native surface, not a generic card/checklist/metadata surface.',
    );
  }
  if (criterionId == 'b25-c08-visible-text-specific-critique') {
    failures.add(
      'Ticket must add screenshot-backed visible text and a non-reusable critique for this exact screen.',
    );
  }
  return failures.isEmpty
      ? 'No row-specific failure recorded.'
      : failures.join(' ');
}

List<String> _screenRowAcceptanceCriteria(JsonMap row, String criterionId) {
  final workflowId = _asString(row['workflowId']);
  final persona = _asString(row['persona'], fallback: 'target persona');
  return <String>[
    'Screen row `${_rowId(row)}` has a specific persona/personaId, not `persona-under-review`.',
    'Visible text for `${_rowId(row)}` is extracted from the screenshot or manually transcribed from the screenshot.',
    'Critique for `${_rowId(row)}` names visible UI elements, visible text, persona `${persona}`, workflow `${workflowId}`, and the exact product UX issue.',
    'Primary surface for `${workflowId}` is documented as `${_targetProductionSurfaceForWorkflow(workflowId)}` or another explicit domain-native surface.',
    'Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.',
    if (criterionId == 'b25-c06-domain-native-primary-surfaces')
      'The workflow/persona direct-question scorecard passes the domain-native primary surface question.',
    if (criterionId == 'b25-c08-visible-text-specific-critique')
      'The workflow/persona direct-question scorecard passes the visible-text and task-specific critique question.',
  ];
}

List<String> _likelyFilesForB25Row(JsonMap row, String criterionId) {
  return <String>{
    ..._likelyFilesForB25Criterion(criterionId),
    'app/apps/loom_communities_demo/lib/main.dart',
    'app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart',
    'app/apps/loom_communities_demo/integration_test/workflow_ui_evidence_test.dart',
    'app/apps/loom_communities_demo/test/workflow_ui_test_harness.dart',
    'docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json',
    'docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md',
  }.toList();
}

List<String> _likelyFilesForB25Criterion(String criterionId) {
  final common = <String>[
    'app/apps/loom_communities_demo/lib/main.dart',
    'app/apps/loom_communities_demo/test/b21_b25_production_ux_test.dart',
    'docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md',
    'docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json',
    'docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md',
  ];
  switch (criterionId) {
    case 'b25-c08-visible-text-specific-critique':
      return <String>[
        ...common,
        'app/packages/tooling/loom_ux_judges/lib/loom_ux_judges.dart',
        'docs/Build Plan V2/Evidence/B25/independent-production-ux-review.md',
      ];
    case 'b25-c01-no-blocker-major':
      return <String>[
        ...common,
        'docs/Build Plan V2/Evidence/B25/product-ux-remediation-loop.md',
        'docs/Build Plan V2/Build Tracker.md',
      ];
    default:
      return common;
  }
}

String _targetProductionSurfaceForWorkflow(String workflowId) {
  final id = workflowId.toLowerCase();
  if (id.contains('rsvp') ||
      id.contains('event') ||
      id.contains('practice') ||
      id.contains('photo-walk')) {
    return 'event detail with schedule, location, capacity/status, RSVP action, and result state';
  }
  if (id.contains('payment') ||
      id.contains('dues') ||
      id.contains('donation') ||
      id.contains('checkout') ||
      id.contains('receipt') ||
      id.contains('ad-off')) {
    return 'payment or donation flow with amount, payer context, receipt, entitlement/status, and audit trail';
  }
  if (id.contains('announcement') || id.contains('publish')) {
    return 'announcement feed/composer with audience, author, timestamp, body, and receiver state';
  }
  if (id.contains('message') ||
      id.contains('connection') ||
      id.contains('invite') ||
      id.contains('blocked')) {
    return 'inbox, message thread, connection card, invite, or block-state surface';
  }
  if (id.contains('export') ||
      id.contains('import') ||
      id.contains('transfer') ||
      id.contains('rollback') ||
      id.contains('schema')) {
    return 'export/import wizard with preview, redaction, checksum, transfer status, and rollback state';
  }
  if (id.contains('search') ||
      id.contains('digest') ||
      id.contains('citation')) {
    return 'search/AI answer surface with query, result, citation, source, and follow-up action';
  }
  if (id.contains('volunteer') || id.contains('signup')) {
    return 'volunteer signup surface with role, time, protected contact fields, and confirmation';
  }
  if (id.contains('plant-exchange')) {
    return 'plant exchange offer form and member marketplace surface with plant details, pickup timing, owner contact, and submitted offer state';
  }
  if (id.contains('care')) {
    return 'protected care request form and private response/status surface';
  }
  if (id.contains('minor-redaction')) {
    return 'protected youth roster/profile surface with minor-data redaction, guardian visibility, and coach-only detail state';
  }
  if (id.contains('reminder') || id.contains('notification')) {
    return 'notification inbox/detail surface with sender, audience, timestamp, message body, and receiver state';
  }
  if (id.contains('donor-visibility')) {
    return 'donor privacy preference surface with visibility choice, donation context, confirmation, and receipt visibility state';
  }
  if (id.contains('in-stream-ad')) {
    return 'community feed surface with clearly labeled in-stream ad placement, disclosure, content context, and no-blocking interaction state';
  }
  if (id.contains('top-banner-no-fill')) {
    return 'App Shell top banner ad slot no-fill surface with preserved layout, disclosure/reserved space, and no content overlap';
  }
  if (id.contains('sensitive-no-fill')) {
    return 'sensitive-context ad suppression surface with protected content visible and ad slot safely no-filled';
  }
  if (id.contains('persona-picker')) {
    return 'test-only persona switcher surface with active persona, role description, and return-to-workflow state';
  }
  if (id.contains('persona-role-inventory')) {
    return 'persona capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior';
  }
  if (id.contains('persona-aware-ux')) {
    return 'persona-aware community surface showing actor, receiver, read-only, disabled, or hidden workflow states for the active role';
  }
  if (id.contains('multi-persona-workflow-evidence')) {
    return 'multi-persona handoff evidence surface with actor-created state, persona switch, receiver state, and continuation action';
  }
  if (id.contains('architectural') ||
      id.contains('committee') ||
      id.contains('approval') ||
      id.contains('request')) {
    return 'request detail and admin review queue with submitted data, decision action, status, and notification';
  }
  if (id.contains('document')) {
    return 'document library/detail surface with title, audience, file metadata, and access state';
  }
  if (id.contains('facility') || id.contains('reservation')) {
    return 'facility detail/reservation flow with availability, payment/status, and confirmation';
  }
  if (id.contains('roster') || id.contains('team')) {
    return 'team roster/schedule surface with role-filtered member details and protected-data treatment';
  }
  if (id.contains('nomination') || id.contains('vote') || id.contains('book')) {
    return 'book club reading/voting surface with nominations, vote state, selected book, meeting context, and discussion';
  }
  if (id.contains('gear')) {
    return 'gear loan request surface with item, availability, borrower, status, and handoff details';
  }
  if (id.contains('critique')) {
    return 'critique submission/review surface with image/work title, comments, reviewer state, and result';
  }
  if (id.contains('match') || id.contains('chess')) {
    return 'match schedule/result surface with players, round, outcome, and next action';
  }
  return 'explicit domain-native product surface selected from the B21 production UX contract';
}

List<JsonMap> _b25CriterionReferencePatterns(String criterionId) {
  switch (criterionId) {
    case 'b25-c03-production-grade-experience':
    case 'b25-c04-modern-intentional-ui':
    case 'b25-c05-community-content-ia':
    case 'b25-c09-no-layout-production-defects':
      return _referencePatternsForType('modern-mobile-product');
    case 'b25-c06-domain-native-primary-surfaces':
      return _referencePatternsForType('domain-native-surface');
    case 'b25-c08-visible-text-specific-critique':
      return _referencePatternsForType('evidence-critique');
    default:
      return _referencePatternsForType('modern-mobile-product');
  }
}

List<String> _b25CriterionReferenceQueries(String criterionId) {
  switch (criterionId) {
    case 'b25-c04-modern-intentional-ui':
      return <String>[
        'modern mobile app information architecture visual hierarchy examples',
        'Material Design 3 mobile UI hierarchy navigation cards examples',
        'open source Flutter production app dashboard detail screen examples',
      ];
    case 'b25-c05-community-content-ia':
      return <String>[
        'community app home screen announcements events messages design examples',
        'open source Flutter community app home feed events messages UI',
      ];
    case 'b25-c06-domain-native-primary-surfaces':
      return <String>[
        'domain specific mobile workflow UI event RSVP donation message export examples',
        'open source Flutter event RSVP donation messaging workflow UI examples',
      ];
    default:
      return <String>[
        'production mobile UX review screenshot critique examples',
        'open source Flutter mobile app UX patterns GitHub',
      ];
  }
}

List<JsonMap> _b25ReferencePatternsForWorkflow(String workflowId) {
  final type = _referenceTypeForWorkflow(workflowId);
  return _dedupeReferencePatterns(<JsonMap>[
    ..._referencePatternsForType(type),
    ..._referencePatternsForType('modern-mobile-product').take(2),
  ]);
}

List<String> _referenceResearchQueriesForWorkflow(String workflowId) {
  final type = _referenceTypeForWorkflow(workflowId);
  final targetSurface = _targetProductionSurfaceForWorkflow(workflowId);
  return _uniqueStrings(<String>[
    'open source Flutter $type mobile UI example GitHub',
    '$targetSurface mobile UX pattern',
    'Material Design $targetSurface mobile pattern',
    if (type.contains('payment') || type.contains('form'))
      'government design system $targetSurface form review confirmation pattern',
  ]);
}

List<String> _uxReferenceChecklistForWorkflow(String workflowId) {
  final targetSurface = _targetProductionSurfaceForWorkflow(workflowId);
  return <String>[
    'Before coding, inspect the listed reference patterns and choose the closest pattern for `${workflowId}`.',
    'State which pattern is being copied or adapted and why it matches the target persona task.',
    'Build the primary surface as ${targetSurface}.',
    'Include realistic domain content, semantic action labels, validation/review state, and completion/result state from the chosen pattern.',
    'In the next evidence pass, critique the screen against the chosen reference pattern and explain remaining deviations.',
  ];
}

String _referenceTypeForWorkflow(String workflowId) {
  final id = workflowId.toLowerCase();
  if (id.contains('rsvp') ||
      id.contains('event') ||
      id.contains('practice') ||
      id.contains('photo-walk')) {
    return 'event-rsvp';
  }
  if (id.contains('payment') ||
      id.contains('dues') ||
      id.contains('donation') ||
      id.contains('checkout') ||
      id.contains('receipt') ||
      id.contains('ad-off')) {
    return 'payment-donation';
  }
  if (id.contains('announcement') || id.contains('publish')) {
    return 'announcement-feed';
  }
  if (id.contains('message') ||
      id.contains('connection') ||
      id.contains('invite') ||
      id.contains('blocked')) {
    return 'message-thread';
  }
  if (id.contains('export') ||
      id.contains('import') ||
      id.contains('transfer') ||
      id.contains('rollback') ||
      id.contains('schema')) {
    return 'export-wizard';
  }
  if (id.contains('search') ||
      id.contains('digest') ||
      id.contains('citation')) {
    return 'search-results';
  }
  if (id.contains('volunteer') ||
      id.contains('signup') ||
      id.contains('care') ||
      id.contains('request') ||
      id.contains('architectural') ||
      id.contains('committee') ||
      id.contains('approval') ||
      id.contains('critique')) {
    return 'form-review';
  }
  if (id.contains('document')) {
    return 'document-library';
  }
  if (id.contains('facility') || id.contains('reservation')) {
    return 'facility-reservation';
  }
  if (id.contains('roster') || id.contains('team')) {
    return 'roster-list';
  }
  if (id.contains('nomination') || id.contains('vote') || id.contains('book')) {
    return 'voting-selection';
  }
  if (id.contains('gear')) {
    return 'marketplace-request';
  }
  if (id.contains('match') || id.contains('chess')) {
    return 'match-result';
  }
  return 'domain-native-surface';
}

List<JsonMap> _referencePatternsForType(String type) {
  final common = <JsonMap>[
    _referencePattern(
      id: 'material-cards-lists',
      label: 'Material Design cards and lists',
      sourceType: 'design-system',
      sourceName: 'Material Design 3',
      url: 'https://m3.material.io/components/cards/overview',
      alsoSee: <String>['https://m3.material.io/components/lists/overview'],
      copy:
          'Use cards/lists only as scannable containers with clear hierarchy, content, metadata, and actions. Do not use repeated cards as the whole primary workflow.',
    ),
    _referencePattern(
      id: 'flutter-samples-reference',
      label: 'Flutter sample app implementation patterns',
      sourceType: 'open-source',
      sourceName: 'flutter/samples',
      url: 'https://github.com/flutter/samples',
      copy:
          'Copy the separation between app shell, route state, domain widgets, and testable UI states rather than hardcoding a single generic renderer.',
    ),
  ];
  switch (type) {
    case 'modern-mobile-product':
      return <JsonMap>[
        _referencePattern(
          id: 'material-navigation-ia',
          label: 'Material navigation and information architecture',
          sourceType: 'design-system',
          sourceName: 'Material Design 3',
          url: 'https://m3.material.io/components/navigation-drawer/overview',
          alsoSee: <String>[
            'https://m3.material.io/components/navigation-bar/overview',
          ],
          copy:
              'Organize screens by user jobs and destinations; keep primary actions visible and avoid exposing implementation taxonomy.',
        ),
        _referencePattern(
          id: 'apple-hig-navigation-content',
          label: 'Apple HIG navigation and content organization',
          sourceType: 'design-system',
          sourceName: 'Apple Human Interface Guidelines',
          url:
              'https://developer.apple.com/design/human-interface-guidelines/navigation',
          copy:
              'Make navigation predictable, content-centered, and appropriate for the user’s current task.',
        ),
        ...common,
      ];
    case 'domain-native-surface':
      return <JsonMap>[
        _referencePattern(
          id: 'material-detail-surfaces',
          label: 'Material detail surface composition',
          sourceType: 'design-system',
          sourceName: 'Material Design 3',
          url: 'https://m3.material.io/components/cards/overview',
          copy:
              'Build a domain detail page with primary content, metadata, status, and actions instead of a generic task card.',
        ),
        ...common,
      ];
    case 'event-rsvp':
      return <JsonMap>[
        _referencePattern(
          id: 'event-detail-rsvp',
          label: 'Event detail and RSVP flow',
          sourceType: 'pattern',
          sourceName: 'Material cards/lists/buttons',
          url: 'https://m3.material.io/components/cards/overview',
          alsoSee: <String>[
            'https://m3.material.io/components/buttons/overview',
            'https://m3.material.io/components/chips/overview',
          ],
          copy:
              'Copy an event detail layout: title, date/time, location, host, capacity/status chip, attendee context, RSVP action, and confirmation state.',
        ),
        ...common,
      ];
    case 'payment-donation':
      return <JsonMap>[
        _referencePattern(
          id: 'payment-review-confirm',
          label: 'Review-and-confirm payment flow',
          sourceType: 'design-system',
          sourceName: 'GOV.UK Design System',
          url: 'https://design-system.service.gov.uk/patterns/check-answers/',
          copy:
              'Use a review/confirmation step with amount, payer context, recipient, fees or entitlement, receipt, and audit trail.',
        ),
        _referencePattern(
          id: 'uswds-step-indicator',
          label: 'Multi-step payment/progress flow',
          sourceType: 'design-system',
          sourceName: 'U.S. Web Design System',
          url: 'https://designsystem.digital.gov/components/step-indicator/',
          copy:
              'Use explicit progress states for checkout, review, confirmation, receipt, and entitlement/status.',
        ),
        ...common,
      ];
    case 'announcement-feed':
      return <JsonMap>[
        _referencePattern(
          id: 'feed-composer-post',
          label: 'Feed item and composer pattern',
          sourceType: 'pattern',
          sourceName: 'Material cards/lists/text fields',
          url: 'https://m3.material.io/components/text-fields/overview',
          alsoSee: <String>[
            'https://m3.material.io/components/cards/overview',
            'https://m3.material.io/components/lists/overview',
          ],
          copy:
              'Copy a feed/composer structure: audience, author, timestamp, body, attachments/status, publish action, and receiver read state.',
        ),
        ...common,
      ];
    case 'message-thread':
      return <JsonMap>[
        _referencePattern(
          id: 'inbox-thread',
          label: 'Inbox and message thread pattern',
          sourceType: 'pattern',
          sourceName: 'Material lists/text fields',
          url: 'https://m3.material.io/components/lists/overview',
          alsoSee: <String>[
            'https://m3.material.io/components/text-fields/overview',
          ],
          copy:
              'Copy an inbox/thread structure: sender, timestamp, message preview/body, reply field, invite/block state, and read/received state.',
        ),
        ...common,
      ];
    case 'export-wizard':
      return <JsonMap>[
        _referencePattern(
          id: 'export-task-list',
          label: 'Task list and export wizard',
          sourceType: 'design-system',
          sourceName: 'GOV.UK Design System',
          url: 'https://design-system.service.gov.uk/components/task-list/',
          alsoSee: <String>[
            'https://design-system.service.gov.uk/patterns/check-answers/',
          ],
          copy:
              'Copy a wizard with steps, preview, redaction choices, checksum evidence, transfer status, and rollback confirmation.',
        ),
        ...common,
      ];
    case 'search-results':
      return <JsonMap>[
        _referencePattern(
          id: 'search-results-citations',
          label: 'Search and result list pattern',
          sourceType: 'design-system',
          sourceName: 'Material Design 3',
          url: 'https://m3.material.io/components/search/overview',
          alsoSee: <String>['https://m3.material.io/components/lists/overview'],
          copy:
              'Copy a search layout with query, filters, ranked results, citations/sources, empty/error states, and follow-up actions.',
        ),
        ...common,
      ];
    case 'form-review':
      return <JsonMap>[
        _referencePattern(
          id: 'form-error-review',
          label: 'Form validation and review pattern',
          sourceType: 'design-system',
          sourceName: 'U.S. Web Design System',
          url: 'https://designsystem.digital.gov/components/form/',
          alsoSee: <String>[
            'https://designsystem.digital.gov/components/alert/',
            'https://design-system.service.gov.uk/components/error-summary/',
          ],
          copy:
              'Copy a form flow with field labels, helper text, validation errors, review state, submit action, status, and protected-data treatment.',
        ),
        ...common,
      ];
    case 'document-library':
      return <JsonMap>[
        _referencePattern(
          id: 'document-library-detail',
          label: 'Document list/detail pattern',
          sourceType: 'pattern',
          sourceName: 'Material lists/cards',
          url: 'https://m3.material.io/components/lists/overview',
          copy:
              'Copy a document library with title, category, audience, file metadata, access state, download/view action, and empty/error states.',
        ),
        ...common,
      ];
    case 'facility-reservation':
      return <JsonMap>[
        _referencePattern(
          id: 'reservation-availability',
          label: 'Reservation detail and availability flow',
          sourceType: 'pattern',
          sourceName: 'Material cards/forms',
          url: 'https://m3.material.io/components/date-pickers/overview',
          alsoSee: <String>['https://m3.material.io/components/cards/overview'],
          copy:
              'Copy an availability/reservation flow with facility details, date/time, capacity/rules, payment/status when needed, and confirmation.',
        ),
        ...common,
      ];
    case 'roster-list':
      return <JsonMap>[
        _referencePattern(
          id: 'roster-table-list',
          label: 'Roster/list with protected details',
          sourceType: 'design-system',
          sourceName: 'Material Design 3',
          url: 'https://m3.material.io/components/data-tables/overview',
          alsoSee: <String>['https://m3.material.io/components/lists/overview'],
          copy:
              'Copy a roster with member names, roles, status, role-filtered fields, and clear protected-data redaction.',
        ),
        ...common,
      ];
    case 'voting-selection':
      return <JsonMap>[
        _referencePattern(
          id: 'selection-voting',
          label: 'Selection and voting pattern',
          sourceType: 'pattern',
          sourceName: 'Material chips/cards/buttons',
          url: 'https://m3.material.io/components/chips/overview',
          alsoSee: <String>['https://m3.material.io/components/cards/overview'],
          copy:
              'Copy a nomination/voting surface with choices, current vote state, deadline, selected result, and meeting/discussion context.',
        ),
        ...common,
      ];
    case 'marketplace-request':
      return <JsonMap>[
        _referencePattern(
          id: 'request-marketplace-item',
          label: 'Item request and handoff pattern',
          sourceType: 'pattern',
          sourceName: 'Material cards/forms',
          url: 'https://m3.material.io/components/cards/overview',
          alsoSee: <String>[
            'https://m3.material.io/components/text-fields/overview',
          ],
          copy:
              'Copy an item detail/request flow with item status, borrower/requester context, terms, handoff details, and confirmation.',
        ),
        ...common,
      ];
    case 'match-result':
      return <JsonMap>[
        _referencePattern(
          id: 'match-schedule-result',
          label: 'Match schedule and result pattern',
          sourceType: 'pattern',
          sourceName: 'Material lists/cards',
          url: 'https://m3.material.io/components/lists/overview',
          copy:
              'Copy a match surface with players, schedule/round, result entry, result state, and next action.',
        ),
        ...common,
      ];
    case 'evidence-critique':
      return <JsonMap>[
        _referencePattern(
          id: 'screenshot-first-critique',
          label: 'Screenshot-first critique method',
          sourceType: 'methodology',
          sourceName: 'B25 production UX gate',
          url: 'docs/Build Plan V2/Tools/b25-remediation-ticket-template.md',
          copy:
              'Critique must quote visible UI/text, name the persona and task, compare against the chosen reference pattern, and state the exact fix.',
        ),
        ...common,
      ];
    default:
      return common;
  }
}

JsonMap _referencePattern({
  required String id,
  required String label,
  required String sourceType,
  required String sourceName,
  required String url,
  required String copy,
  List<String> alsoSee = const <String>[],
}) {
  return <String, Object?>{
    'referenceId': id,
    'label': label,
    'sourceType': sourceType,
    'sourceName': sourceName,
    'url': url,
    'alsoSee': alsoSee,
    'whatToCopy': copy,
  };
}

List<JsonMap> _dedupeReferencePatterns(Iterable<JsonMap> patterns) {
  final byId = <String, JsonMap>{};
  for (final pattern in patterns) {
    final id = _asString(pattern['referenceId']);
    if (id.isEmpty) {
      continue;
    }
    byId[id] = JsonMap.of(pattern);
  }
  return byId.values.toList();
}

List<String> _uniqueStrings(Iterable<String> values) {
  return <String>{
    for (final value in values)
      if (value.trim().isNotEmpty) value.trim(),
  }.toList();
}

String _truncate(String value, int maxLength) {
  if (value.length <= maxLength) {
    return value;
  }
  return '${value.substring(0, maxLength - 3)}...';
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
      final holisticFindings = allBlockingFindingIds
          .where(
            (id) =>
                id == 'B25-HOLISTIC-UX-FAILED' ||
                id == 'B25-SCREEN-SPECIFIC-CRITIQUE-INCOMPLETE' ||
                id == 'B25-WORKFLOW-PERSONA-COVERAGE-INCOMPLETE',
          )
          .toList();
      return holisticFindings.isEmpty
          ? allBlockingFindingIds
          : holisticFindings;
    case 'b25-c06-domain-native-primary-surfaces':
    case 'b25-c08-visible-text-specific-critique':
      final workflowFindings = allBlockingFindingIds
          .where(
            (id) =>
                id == 'B25-WORKFLOW-PERSONA-UX-FAILED' ||
                id == 'B25-WORKFLOW-PERSONA-COVERAGE-INCOMPLETE' ||
                id == 'B25-SCREEN-SPECIFIC-CRITIQUE-INCOMPLETE',
          )
          .toList();
      return workflowFindings.isEmpty
          ? allBlockingFindingIds
          : workflowFindings;
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
    'dart run packages/tooling/loom_ux_judges/bin/b25_workflow_persona_coverage_collector.dart --input ../docs/Build\\ Plan\\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\\ Plan\\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\\ Plan\\ V2/Evidence/B25/workflow-persona-coverage-matrix.md',
    'dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\\ Plan\\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\\ Plan\\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\\ Plan\\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\\ Plan\\ V2/Evidence/B25/product-ux-screen-review-matrix.md',
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
    final source = _asString(row['visibleTextExtractionSource']);
    if (visibleText.trim().length < 8 ||
        critique.trim().length < 24 ||
        source == 'manual-visible-text-review') {
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

_DerivedFailure? _failOnVisualInspection(List<JsonMap> rows) {
  final failing = <String>[];
  for (final row in rows) {
    final inspection = row['visualInspection'] as JsonMap?;
    if (inspection == null) {
      failing.add('${_rowId(row)} missing-visual-inspection');
      continue;
    }
    if (inspection['status'] == 'fail') {
      final ids = _asStringList(inspection['findingIds']);
      failing.add('${_rowId(row)}${ids.isEmpty ? '' : ' ${ids.join('+')}'}');
    }
  }
  if (rows.isEmpty || failing.isNotEmpty) {
    return _DerivedFailure(
      score: rows.isEmpty ? 0 : 45,
      message: rows.isEmpty
          ? 'No screen rows were supplied for visual inspection.'
          : 'Rows with failed/missing screenshot visual inspection: ${failing.take(80).join(', ')}.',
      evidenceUsed: failing.take(80).toList(),
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
      ..writeln(
        '| Remediation mode | `${_escape(_asString(ticket['remediationMode']))}` |',
      )
      ..writeln(
        '| Worker readiness | ${_escape(_asString(ticket['workerReadiness']))} |',
      )
      ..writeln(
        '| First required step | ${_escape(_asString(ticket['firstRequiredStep']))} |',
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
    final sourceResearchRequirement = _asString(
      ticket['sourceResearchRequirement'],
    );
    if (sourceResearchRequirement.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('### Source Research Requirement')
        ..writeln()
        ..writeln(_escape(sourceResearchRequirement));
    }
    _writeReferencePatternsMarkdown(
      buffer,
      'UX Reference Patterns To Copy',
      _asMapList(ticket['uxReferencePatterns']),
    );
    final referenceQueries = _asStringList(ticket['referenceResearchQueries']);
    if (referenceQueries.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('### Reference Research Queries');
      for (final query in referenceQueries.take(20)) {
        buffer.writeln('- ${_escape(query)}');
      }
    }
    final blockedBy = _asStringList(ticket['implementationBlockedBy']);
    if (blockedBy.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('### Implementation Blocked By');
      for (final blocker in blockedBy) {
        buffer.writeln('- ${_escape(blocker)}');
      }
    }
    _writeWorkItemsMarkdown(
      buffer,
      'Evidence Repair Work Items',
      _asMapList(ticket['evidenceRepairWorkItems']),
    );
    _writeWorkItemsMarkdown(
      buffer,
      'UI Remediation Work Items',
      _asMapList(ticket['uiRemediationWorkItems']),
    );
    final coverageRows = _asMapList(ticket['affectedCoverageRows']);
    if (coverageRows.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('### Affected Workflow/Persona Coverage')
        ..writeln()
        ..writeln(
          'Showing ${coverageRows.take(40).length} of ${coverageRows.length} affected coverage rows. Full detail is in the JSON ticket.',
        )
        ..writeln()
        ..writeln(
          '| Coverage row | Status | Community | Workflow | Persona | Missing evidence | Screen rows | Target surface |',
        )
        ..writeln('| --- | --- | --- | --- | --- | --- | ---: | --- |');
      for (final row in coverageRows.take(40)) {
        buffer.writeln(
          '| `${_escape(_asString(row['coverageRowId']))}` | `${_escape(_asString(row['status']))}` | ${_escape(_asString(row['communityName']))} | `${_escape(_asString(row['workflowId']))}` | ${_escape(_asString(row['persona']))} | ${_escape(_asStringList(row['missingEvidence']).join('; '))} | ${_asStringList(row['screenRowIds']).length} | ${_escape(_asString(row['targetProductionSurface']))} |',
        );
      }
    }
    final screenRows = _asMapList(ticket['affectedScreenRows']);
    if (screenRows.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('### Affected Screen Rows')
        ..writeln()
        ..writeln(
          'Showing ${screenRows.take(40).length} of ${screenRows.length} affected screen rows. Full detail is in the JSON ticket.',
        )
        ..writeln()
        ..writeln(
          '| Screen row | Community | Workflow | Persona | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |',
        )
        ..writeln(
          '| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |',
        );
      for (final row in screenRows.take(40)) {
        buffer.writeln(
          '| `${_escape(_asString(row['screenRowId']))}` | ${_escape(_asString(row['communityName']))} | `${_escape(_asString(row['workflowId']))}` | ${_escape(_asString(row['persona']))} | ${_escape(_asString(row['screenState']))} | `${_escape(_asString(row['screenshotPath']))}` | `${_escape(_truncate(_asString(row['screenshotHash']), 16))}` | ${_escape(_asString(row['visibleTextExcerpt']))} | ${_escape(_asString(row['currentSurfaceClassification']))} / ${_escape(_asString(row['currentPrimarySurfaceType']))} | ${_escape(_asString(row['exactUxFailure']))} | ${_escape(_asString(row['targetProductionSurface']))} |',
        );
      }
    }
    final scorecards = _asMapList(ticket['failingWorkflowPersonaScorecards']);
    if (scorecards.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('### Failing Workflow/Persona Scorecards')
        ..writeln()
        ..writeln(
          'Showing ${scorecards.take(40).length} of ${scorecards.length} failing scorecards. Full detail is in the JSON ticket.',
        )
        ..writeln()
        ..writeln(
          '| Scorecard | Community | Workflow | Persona | Failed questions | Target surface |',
        )
        ..writeln('| --- | --- | --- | --- | ---: | --- |');
      for (final scorecard in scorecards.take(40)) {
        buffer.writeln(
          '| `${_escape(_asString(scorecard['scorecardId']))}` | ${_escape(_asString(scorecard['communityName']))} | `${_escape(_asString(scorecard['workflowId']))}` | ${_escape(_asString(scorecard['persona']))} | ${_asMapList(scorecard['failingQuestions']).length} | ${_escape(_asString(scorecard['targetProductionSurface']))} |',
        );
      }
    }
    final directQuestions = _asMapList(ticket['failingDirectQuestions']);
    if (directQuestions.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('### Failing Direct Questions')
        ..writeln()
        ..writeln('| Question | Scope | Score | Why | Required fix |')
        ..writeln('| --- | --- | ---: | --- | --- |');
      for (final question in directQuestions) {
        buffer.writeln(
          '| ${_escape(_asString(question['question']))} | ${_escape(_asString(question['scope']))} | ${question['score'] ?? 0} | ${_escape(_asString(question['why']))} | ${_escape(_asString(question['requiredFix']))} |',
        );
      }
    }
    final likelyFiles = _asStringList(ticket['likelyFilesOrWidgets']);
    if (likelyFiles.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('### Likely Files / Widgets');
      for (final file in likelyFiles) {
        buffer.writeln('- `${_escape(file)}`');
      }
    }
    final concreteAcceptance = _asStringList(
      ticket['concreteAcceptanceCriteria'],
    );
    if (concreteAcceptance.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('### Concrete Acceptance Criteria');
      for (final check in concreteAcceptance) {
        buffer.writeln('- ${_escape(check)}');
      }
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

void _writeWorkItemsMarkdown(
  StringBuffer buffer,
  String title,
  List<JsonMap> workItems,
) {
  if (workItems.isEmpty) {
    return;
  }
  buffer
    ..writeln()
    ..writeln('### ${_escape(title)}')
    ..writeln()
    ..writeln(
      'Showing ${workItems.take(30).length} of ${workItems.length} work items. Full detail is in the JSON artifact.',
    )
    ..writeln()
    ..writeln(
      '| Work item | Stage | Community | Workflow | Persona | Screens | Coverage | Target surface | Blocked until |',
    )
    ..writeln('| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |');
  for (final item in workItems.take(30)) {
    buffer.writeln(
      '| `${_escape(_asString(item['workItemId']))}` | `${_escape(_asString(item['stage']))}` | ${_escape(_asString(item['communityName']))} | `${_escape(_asString(item['workflowId']))}` | ${_escape(_asString(item['persona']))} | ${_asStringList(item['affectedScreenRowIds']).length} | ${_asStringList(item['affectedCoverageRowIds']).length} | ${_escape(_asString(item['targetProductionSurface']))} | ${_escape(_asString(item['blockedUntil']))} |',
    );
  }
  final referencePatterns = _dedupeReferencePatterns(<JsonMap>[
    for (final item in workItems.take(30))
      ..._asMapList(item['referencePatternsToCopy']),
  ]);
  _writeReferencePatternsMarkdown(
    buffer,
    '$title Reference Patterns',
    referencePatterns.take(12).toList(),
  );
}

void _writeReferencePatternsMarkdown(
  StringBuffer buffer,
  String title,
  List<JsonMap> patterns,
) {
  if (patterns.isEmpty) {
    return;
  }
  buffer
    ..writeln()
    ..writeln('### ${_escape(title)}')
    ..writeln()
    ..writeln('| Reference | Source | URL | What to copy |')
    ..writeln('| --- | --- | --- | --- |');
  for (final pattern in patterns) {
    final alsoSee = _asStringList(pattern['alsoSee']);
    final url = _asString(pattern['url']);
    final urlCell = alsoSee.isEmpty
        ? url
        : '$url<br>Also: ${alsoSee.take(2).join('<br>')}';
    buffer.writeln(
      '| ${_escape(_asString(pattern['label']))} | ${_escape(_asString(pattern['sourceName']))} / ${_escape(_asString(pattern['sourceType']))} | ${_escape(urlCell)} | ${_escape(_asString(pattern['whatToCopy']))} |',
    );
  }
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
        row['screenRowId'] ??
        row['coverageRowId'] ??
        row['scorecardId'] ??
        row['questionId'] ??
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
