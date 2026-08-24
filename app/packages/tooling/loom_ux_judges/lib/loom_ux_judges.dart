// ignore_for_file: prefer_const_constructors

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:loom_ux_judges/b25_product_doc_interaction_models.dart';

typedef JsonMap = Map<String, Object?>;

const fullB25EvidencePhases = <String>[
  'B12',
  'B13',
  'B14',
  'B15',
  'B16',
  'B17',
  'B18',
  'B19',
  'B20',
];

const fullB25MinimumScreenshotRows = 180;
const fullB25MinimumWorkflowManifests = 9;

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
        'Checks every workflow/role row has a production UX contract before implementation.',
    criteria: <CriterionDefinition>[
      CriterionDefinition(
        id: 'b21-c01-contract-rows-complete',
        title: 'Every workflow/role row has a production UX contract',
        requiredEvidenceFields: <String>['contractRows'],
        failureMessage: 'Contract rows are missing or incomplete.',
        requiredFix:
            'Add rows with workflowId, role, realUserGoal, domainSurface, inputs, validation, action, success state, receiver state, and screenshot plan.',
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
  'role-ux-judge': JudgeSpec(
    toolId: 'role-ux-judge',
    phase: 'B23',
    description:
        'Verifies actor, receiver, read-only, disabled, hidden, and unauthorized states from evidence.',
    criteria: <CriterionDefinition>[
      CriterionDefinition(
        id: 'b23-c01-role-state-coverage',
        title: 'Every role/workflow state has visible evidence',
        requiredEvidenceFields: <String>['roleRows'],
        failureMessage:
            'Role state evidence is missing for one or more actor/receiver/unauthorized rows.',
        requiredFix:
            'Capture each role state and record hidden, disabled, read-only, receiver, or actor behavior.',
      ),
      CriterionDefinition(
        id: 'b23-c02-unauthorized-behavior',
        title: 'Unauthorized roles cannot perform restricted workflows',
        requiredEvidenceFields: <String>['roleRows'],
        failureMessage:
            'Unauthorized behavior is missing or incorrectly passable.',
        requiredFix:
            'Implement and test hidden/disabled/read-only denial behavior for unauthorized roles.',
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
        id: 'b25-c02-community-product-docs-complete',
        title: 'Every community has a review-ready product experience doc',
        question:
            'Does every reviewed community/test app have a current, community-specific Product Docs V2 experience spec that defines the rich product experience before UX remediation is judged?',
        scope: 'product-spec',
        requiredEvidenceFields: <String>['productDocCoverage'],
        failureMessage:
            'Community-specific Product Docs V2 experience specs are missing, thin, placeholder-filled, or not linked to the reviewed screens.',
        requiredFix:
            'Create or update Product Docs V2 community experience specs before remediation continues, then judge screens against those specs.',
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
        id: 'b25-c14-llm-vision-ux-review',
        title: 'LLM vision UX judge has inspected screenshots semantically',
        question:
            'Has a fresh LLM vision UX Judge inspected the actual screenshots as product UI, answered direct UX questions from visible evidence, and found no blocker or major product-quality issues?',
        scope: 'llm-vision',
        requiredEvidenceFields: <String>['llmVisionReview'],
        failureMessage:
            'The evidence does not include a passing LLM vision UX review artifact grounded in screenshots.',
        requiredFix:
            'Run the B25 LLM Vision UX Judge Agent on the screenshot evidence, import its structured review, fix all blocker/major findings, and rerun B25.',
      ),
      CriterionDefinition(
        id: 'b25-c04-modern-intentional-ui',
        title: 'UI looks modern and intentionally designed',
        question:
            'Is the UI modern, easy to use, easy to navigate, and visually appealing for the target role?',
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
            'For every workflow and role, is the primary UI a domain-native product surface rather than a generic card, checklist modal, or metadata page?',
        scope: 'workflow-role',
        requiredEvidenceFields: <String>[
          'screenRows',
          'workflowRoleScorecards',
        ],
        failureMessage:
            'A primary workflow is still generic-card/checklist/modal/metadata-only.',
        requiredFix:
            'Replace primary generic surfaces with domain-native product surfaces.',
      ),
      CriterionDefinition(
        id: 'b25-c13-workflow-lifecycle-complete',
        title: 'Every primary workflow has complete lifecycle UX',
        question:
            'For every workflow and role, does the UI prove the full production interaction model: concrete object/context, decision information, semantically correct primary and alternate actions, persistent result state, and receiver/continuation state?',
        scope: 'workflow-role',
        requiredEvidenceFields: <String>[
          'screenRows',
          'workflowLifecycleScorecards',
        ],
        failureMessage:
            'One or more primary workflows are represented by incomplete action cards instead of full production interaction-model UX.',
        requiredFix:
            'Update product docs and UI so each affected workflow/role has a semantic interaction contract, visible decision context, correct primary and alternate actions, result state, receiver/continuation state, fresh screenshots, and passing interaction-model scorecards.',
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
        id: 'b25-c15-full-b25-capture-coverage',
        title: 'Canonical evidence uses full B12-B20 screenshot coverage',
        question:
            'Was this B25 review generated from commit-eligible full B12-B20 screenshot evidence, not from a targeted remediation precheck or stale partial aggregate?',
        scope: 'evidence',
        requiredEvidenceFields: <String>['reviewInputEvidence'],
        failureMessage:
            'The B25 review input does not prove full B12-B20 screenshot coverage.',
        requiredFix:
            'Run b25_capture_workflow_screenshots.dart in --mode full-b25, run b25_capture_coverage_gate.dart, then regenerate B25 evidence and judges from that full capture.',
      ),
      CriterionDefinition(
        id: 'b25-c16-app-shell-capability-utilization',
        title: 'App Shell capabilities are used where documented',
        question:
            'Do current screenshots prove role tabs, explicit and appropriate pinning policy, minimized/medium/expanded states, tap-to-expand behavior, community-list presentation states, renderer selection, and theme/customization tokens are used correctly where Product Docs or App Shell component docs require them?',
        scope: 'app-shell-capability',
        requiredEvidenceFields: <String>['appShellCapabilityReview'],
        failureMessage:
            'The evidence does not include a passing App Shell capability utilization review, or it shows missing shell customization/presentation proof.',
        requiredFix:
            'Update Product Docs and UI so app shell tabs, explicit per-tab pinning policy, presentation states, tap-to-expand behavior, community-list states, renderer selection, and theme/typography/density customization are screenshot-proven where required; rerun B25 and regenerate tickets.',
      ),
      CriterionDefinition(
        id: 'b25-c17-component-doc-freshness',
        title: 'LLM reread current component docs and recorded hashes',
        question:
            'Did the LLM reconciliation gate reread the current App Shell, tab renderer, and card-surface component docs this run, summarize their semantic implications, and record hashes/commit metadata that match the current repo?',
        scope: 'component-docs',
        requiredEvidenceFields: <String>['productDocWorkflowReconciliation'],
        failureMessage:
            'The evidence does not prove the LLM reread the current component docs or that its component-doc hashes/commit metadata match the current repo.',
        requiredFix:
            'Run b25_component_doc_context.dart, give that artifact plus the current component docs to the LLM reconciliation gate, regenerate productDocWorkflowReconciliation with reviewedComponentDocPaths, componentDocReview.docs, sha256 hashes, git last-commit SHAs, git status, reviewedThisRun=true, and semantic implications, then rerun production_ux_judge.dart.',
      ),
      CriterionDefinition(
        id: 'b25-c08-visible-text-specific-critique',
        title: 'Every row has visible text and screen-specific critique',
        question:
            'Does every holistic and workflow/role review answer cite visible UI/text and provide a critique specific to that screenshot and user task?',
        scope: 'workflow-role',
        requiredEvidenceFields: <String>[
          'screenRows',
          'workflowRoleScorecards',
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
            'Does the screen inventory cover every user-facing screen, state, dialog, card, feed item, form, confirmation, error, empty state, role variant, and action result?',
        scope: 'evidence',
        requiredEvidenceFields: <String>['screenRows'],
        failureMessage:
            'The evidence does not prove complete screen/state inventory coverage.',
        requiredFix:
            'Inventory every screen, dialog, card, feed item, form, state, role variant, and action result.',
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

void runB25ComponentDocContextCli(List<String> args) {
  if (args.contains('--help')) {
    stdout.writeln(_componentDocContextUsage());
    return;
  }
  final repoRootPath = _argValue(args, '--repo-root') ?? Directory.current.path;
  final outputPath = _argValue(args, '--output');
  final markdownPath = _argValue(args, '--markdown-output');
  final extraDocs = _argValues(args, '--extra-doc');
  final context = buildB25ComponentDocContext(
    repoRootPath: repoRootPath,
    extraDocPaths: extraDocs,
  );
  final encoded = const JsonEncoder.withIndent('  ').convert(context);
  if (outputPath == null) {
    stdout.writeln(encoded);
  } else {
    File(outputPath).writeAsStringSync('$encoded\n');
  }
  if (markdownPath != null) {
    File(markdownPath).writeAsStringSync(_componentDocContextMarkdown(context));
  }
  final docs = _asMapList(context['docs']);
  final missing = docs.where((doc) => doc['exists'] != true).length;
  stdout.writeln(
    'b25_component_doc_context: docs=${docs.length} missing=$missing output=${outputPath ?? 'stdout'}',
  );
  if (missing > 0) {
    exit(1);
  }
}

void runB25WorkflowRoleCoverageCollectorCli(List<String> args) {
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
  final enriched = buildB25WorkflowRoleCoverage(review);
  final encoded = const JsonEncoder.withIndent('  ').convert(enriched);
  File(outputPath).writeAsStringSync('$encoded\n');
  if (markdownPath != null) {
    File(
      markdownPath,
    ).writeAsStringSync(_b25WorkflowRoleCoverageMarkdown(enriched));
  }
  final summary = enriched['workflowRoleCoverageSummary'] as JsonMap;
  stdout.writeln(
    'b25_workflow_role_coverage_collector: status=${summary['status']} coverageRows=${summary['coverageRowCount']} failing=${summary['failingCoverageRowCount']}',
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
    'b25_independent_ux_judge: ${judged['finalDecision']} findings=${_asMapList(judged['findings']).length} workflowRoleScorecards=${_asMapList(judged['workflowRoleScorecards']).length}',
  );
  if (judged['finalDecision'] != 'pass') {
    exit(1);
  }
}

void runB25LlmUxReviewImporterCli(List<String> args) {
  if (args.contains('--help') || args.isEmpty) {
    stdout.writeln(_llmUxReviewImporterUsage());
    return;
  }
  final inputPath = _argValue(args, '--input');
  final llmReviewPath = _argValue(args, '--llm-review');
  final outputPath = _argValue(args, '--output');
  if (inputPath == null || llmReviewPath == null || outputPath == null) {
    stderr.writeln(
      'Missing required --input <json>, --llm-review <json>, or --output <json>',
    );
    stdout.writeln(_llmUxReviewImporterUsage());
    exit(64);
  }
  final markdownPath = _argValue(args, '--markdown-output');
  final matrixPath = _argValue(args, '--matrix-output');
  final imported = buildB25LlmUxReviewImport(
    _readJsonFile(inputPath),
    _readJsonFile(llmReviewPath),
    llmReviewPath: llmReviewPath,
    runId: _argValue(args, '--run-id'),
  );
  final encoded = const JsonEncoder.withIndent('  ').convert(imported);
  File(outputPath).writeAsStringSync('$encoded\n');
  if (markdownPath != null) {
    File(markdownPath).writeAsStringSync(_b25ReviewMarkdown(imported));
  }
  if (matrixPath != null) {
    File(matrixPath).writeAsStringSync(_b25ScreenMatrixMarkdown(imported));
  }
  final llmReview = imported['llmVisionReview'] as JsonMap;
  stdout.writeln(
    'b25_llm_ux_review_importer: status=${llmReview['status']} findings=${_asMapList(llmReview['findings']).length} screenReviews=${_asMapList(llmReview['screenReviews']).length}',
  );
  if (llmReview['status'] != 'pass') {
    exit(1);
  }
}

void runB25LlmReviewFreshnessGateCli(List<String> args) {
  if (args.contains('--help') || args.isEmpty) {
    stdout.writeln(_llmReviewFreshnessGateUsage());
    return;
  }
  final inputPath = _argValue(args, '--input');
  final llmReviewPath = _argValue(args, '--llm-review');
  if (inputPath == null || llmReviewPath == null) {
    stderr.writeln('Missing required --input <json> or --llm-review <json>');
    stdout.writeln(_llmReviewFreshnessGateUsage());
    exit(64);
  }
  final report = buildB25LlmReviewFreshnessGate(
    review: _readJsonFile(inputPath),
    llmReview: _readJsonFile(llmReviewPath),
    runId: _argValue(args, '--run-id'),
    llmReviewPath: llmReviewPath,
  );
  final outputPath = _argValue(args, '--output');
  if (outputPath != null) {
    final encoded = const JsonEncoder.withIndent('  ').convert(report);
    File(outputPath).writeAsStringSync('$encoded\n');
  }
  final markdownPath = _argValue(args, '--markdown-output');
  if (markdownPath != null) {
    File(
      markdownPath,
    ).writeAsStringSync(_b25LlmReviewFreshnessGateMarkdown(report));
  }
  stdout.writeln(
    'b25_llm_review_freshness_gate: status=${report['status']} problems=${_asStringList(report['problems']).length}',
  );
  if (report['status'] != 'pass') {
    exit(1);
  }
}

void runB25WorkflowLifecycleJudgeCli(List<String> args) {
  _runB25WorkflowInteractionModelJudgeCli(
    args,
    toolName: 'b25_workflow_lifecycle_judge',
    usage: _workflowLifecycleJudgeUsage(),
  );
}

void runB25WorkflowInteractionModelJudgeCli(List<String> args) {
  _runB25WorkflowInteractionModelJudgeCli(
    args,
    toolName: 'b25_workflow_interaction_model_judge',
    usage: _workflowInteractionModelJudgeUsage(),
  );
}

void _runB25WorkflowInteractionModelJudgeCli(
  List<String> args, {
  required String toolName,
  required String usage,
}) {
  if (args.contains('--help') || args.isEmpty) {
    stdout.writeln(usage);
    return;
  }
  final inputPath = _argValue(args, '--input');
  final outputPath = _argValue(args, '--output');
  if (inputPath == null || outputPath == null) {
    stderr.writeln('Missing required --input <json> or --output <json>');
    stdout.writeln(usage);
    exit(64);
  }
  final markdownPath = _argValue(args, '--markdown-output');
  final judged = buildB25WorkflowLifecycleReview(_readJsonFile(inputPath));
  final encoded = const JsonEncoder.withIndent('  ').convert(judged);
  File(outputPath).writeAsStringSync('$encoded\n');
  if (markdownPath != null) {
    File(markdownPath).writeAsStringSync(_b25WorkflowLifecycleMarkdown(judged));
  }
  final summary = judged['workflowLifecycleSummary'] as JsonMap;
  stdout.writeln(
    '$toolName: status=${summary['status']} scorecards=${summary['scorecardCount']} failing=${summary['failingScorecardCount']}',
  );
  if (summary['status'] == 'fail') {
    exit(1);
  }
}

void runB25CaptureCoverageGateCli(List<String> args) {
  if (args.contains('--help') || args.isEmpty) {
    stdout.writeln(_captureCoverageGateUsage());
    return;
  }
  final evidenceRootPath = _argValue(args, '--evidence-root');
  if (evidenceRootPath == null) {
    stderr.writeln('Missing required --evidence-root <dir>');
    stdout.writeln(_captureCoverageGateUsage());
    exit(64);
  }
  final report = buildB25CaptureCoverageReport(evidenceRootPath);
  final outputPath = _argValue(args, '--output');
  if (outputPath != null) {
    File(outputPath).writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(report)}\n',
    );
  }
  final status = _asString(report['status']);
  stdout.writeln(
    'b25_capture_coverage_gate: status=$status mode=${report['captureMode']} '
    'commitEligible=${report['commitEligible']} phases=${_asStringList(report['capturedPhases']).join(',')} '
    'screenshots=${report['screenshotCount']} workflows=${report['workflowCount']}',
  );
  if (status != 'pass') {
    for (final issue in _asStringList(report['issues'])) {
      stderr.writeln('b25_capture_coverage_gate: $issue');
    }
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

JsonMap buildB25CaptureCoverageReport(String evidenceRootPath) {
  final evidenceRoot = Directory(evidenceRootPath);
  final aggregate = File(
    '${evidenceRoot.path}/B20/all-workflow-ui-evidence.json',
  );
  if (!aggregate.existsSync()) {
    return <String, Object?>{
      'status': 'fail',
      'aggregatePath': aggregate.path,
      'captureMode': 'missing',
      'commitEligible': false,
      'fullB25Coverage': false,
      'expectedPhases': fullB25EvidencePhases,
      'capturedPhases': <String>[],
      'missingPhases': fullB25EvidencePhases,
      'workflowManifestCount': 0,
      'workflowCount': 0,
      'screenshotCount': 0,
      'issues': <String>[
        'Missing canonical B25 aggregate B20/all-workflow-ui-evidence.json. Run b25_capture_workflow_screenshots.dart in --mode full-b25.',
      ],
    };
  }
  final manifest = _readJsonFile(aggregate.path);
  return _b25CaptureCoverageReportFromAggregate(
    aggregatePath: aggregate.path,
    manifest: manifest,
  );
}

JsonMap _b25CaptureCoverageReportFromAggregate({
  required String aggregatePath,
  required JsonMap manifest,
}) {
  final phases = _asStringList(manifest['phases']);
  final expectedPhases = _asStringList(manifest['expectedPhases']).isEmpty
      ? fullB25EvidencePhases
      : _asStringList(manifest['expectedPhases']);
  final missingPhases = fullB25EvidencePhases
      .where((phase) => !phases.contains(phase))
      .toList(growable: false);
  final extraPhases = phases
      .where((phase) => !fullB25EvidencePhases.contains(phase))
      .toList(growable: false);
  final manifestPaths = _asStringList(
    manifest['workflowEvidenceManifestPaths'],
  );
  final missingManifestPaths = manifestPaths
      .where((path) => !File(_hostPath(path)).existsSync())
      .toList(growable: false);
  final workflowCount = _asInt(manifest['workflowCount']);
  final screenshotCount = _asInt(manifest['screenshotCount']);
  final issues = <String>[];
  final captureMode = _asString(manifest['captureMode']);
  final commitEligible = manifest['commitEligible'] == true;
  final fullCoverage = manifest['fullB25Coverage'] == true;

  if (captureMode != 'full-b25') {
    issues.add(
      'Canonical B25 aggregate captureMode must be full-b25; found "$captureMode". Targeted precheck artifacts cannot close B25.',
    );
  }
  if (!commitEligible) {
    issues.add('Canonical B25 aggregate is not marked commitEligible=true.');
  }
  if (!fullCoverage) {
    issues.add('Canonical B25 aggregate is not marked fullB25Coverage=true.');
  }
  if (!_sameStringList(phases, fullB25EvidencePhases)) {
    issues.add(
      'Canonical B25 aggregate phases must be exactly ${fullB25EvidencePhases.join(',')}; found ${phases.join(',')}.',
    );
  }
  if (!_sameStringList(expectedPhases, fullB25EvidencePhases)) {
    issues.add(
      'Canonical B25 aggregate expectedPhases must be ${fullB25EvidencePhases.join(',')}; found ${expectedPhases.join(',')}.',
    );
  }
  if (missingPhases.isNotEmpty) {
    issues.add(
      'Canonical B25 aggregate is missing phases: ${missingPhases.join(',')}.',
    );
  }
  if (extraPhases.isNotEmpty) {
    issues.add(
      'Canonical B25 aggregate contains unexpected phases: ${extraPhases.join(',')}.',
    );
  }
  if (manifestPaths.length < fullB25MinimumWorkflowManifests) {
    issues.add(
      'Canonical B25 aggregate has ${manifestPaths.length} workflow manifests; expected at least $fullB25MinimumWorkflowManifests.',
    );
  }
  if (missingManifestPaths.isNotEmpty) {
    issues.add(
      'Canonical B25 aggregate references missing workflow manifests: ${missingManifestPaths.take(5).join(', ')}.',
    );
  }
  if (screenshotCount < fullB25MinimumScreenshotRows) {
    issues.add(
      'Canonical B25 aggregate has $screenshotCount screenshots; expected at least $fullB25MinimumScreenshotRows.',
    );
  }
  if (workflowCount <= 0) {
    issues.add('Canonical B25 aggregate has no workflows.');
  }

  return <String, Object?>{
    'schemaVersion': 1,
    'status': issues.isEmpty ? 'pass' : 'fail',
    'aggregatePath': aggregatePath,
    'captureMode': captureMode,
    'commitEligible': commitEligible,
    'fullB25Coverage': fullCoverage,
    'expectedPhases': fullB25EvidencePhases,
    'capturedPhases': phases,
    'missingPhases': missingPhases,
    'unexpectedPhases': extraPhases,
    'workflowManifestCount': manifestPaths.length,
    'workflowCount': workflowCount,
    'screenshotCount': screenshotCount,
    'workflowEvidenceManifestPaths': manifestPaths,
    'missingWorkflowEvidenceManifestPaths': missingManifestPaths,
    'commandOutputPath': _asString(manifest['commandOutputPath']),
    'issues': issues,
  };
}

JsonMap buildB25ComponentDocContext({
  required String repoRootPath,
  List<String> extraDocPaths = const <String>[],
}) {
  final paths = <String>{
    ..._requiredComponentDocPaths,
    for (final path in extraDocPaths)
      _normalizeComponentDocPath(repoRootPath, path),
  }.where((path) => path.trim().isNotEmpty).toList()..sort();
  return <String, Object?>{
    'schemaVersion': 1,
    'toolId': 'b25-component-doc-context',
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'repoRootPath': _canonicalDirectoryPath(repoRootPath),
    'appCommitSha': _gitShortSha(repoRootPath),
    'docs': [
      for (final path in paths) _componentDocMetadata(repoRootPath, path),
    ],
  };
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
  final captureCoverage = buildB25CaptureCoverageReport(evidenceRoot.path);
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
        final role = _asString(
          workflow['role'],
          fallback: _roleForEvidence(
            workflowId: workflowId,
            communityId: communityId,
            screenshotName: screenshotName,
          ),
        );
        final cardSurfaceRegistryEntry =
            _b25CardSurfaceRegistryEntryForWorkflowId(workflowId);
        screenRows.add(<String, Object?>{
          'rowId': rowId,
          'communityId': communityId,
          'communityName': _asString(
            workflow['communityName'],
            fallback: _asString(workflow['appId']),
          ),
          'role': role,
          'fanId': _fanIdForEvidence(role: role, communityId: communityId),
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
          'cardSurfaceRegistryStatus': 'advisory-non-gating',
          'cardSurfaceFamily': cardSurfaceRegistryEntry['cardSurfaceFamily'],
          'cardSurfaceApiContract': cardSurfaceRegistryEntry['apiContract'],
          'cardSurfaceRequiredInteractions': _asStringList(
            cardSurfaceRegistryEntry['requiredInteractions'],
          ),
          'cardSurfacePrimaryActions': _asStringList(
            cardSurfaceRegistryEntry['primaryActions'],
          ),
          'cardSurfaceAlternateActions': _asStringList(
            cardSurfaceRegistryEntry['alternateActions'],
          ),
          'cardSurfaceRendererTarget':
              cardSurfaceRegistryEntry['rendererTarget'],
          'cardSurfaceFakeBackendSupport':
              cardSurfaceRegistryEntry['fakeBackendSupport'],
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
  final productDocCoverage = _productDocCoverageForB25(
    screenRows: screenRows,
    repoRootPath: repoRootPath,
  );
  final cardSurfaceRegistry = _b25CardSurfaceRegistryForRows(screenRows);
  final b25EvidenceCoverage = _b25EvidenceCoverageForManifests(
    evidenceRoot: evidenceRoot,
    manifests: manifests,
  );
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
      'captureCoverage': captureCoverage,
      'captureMode': _asString(captureCoverage['captureMode']),
      'commitEligible': captureCoverage['commitEligible'] == true,
      'fullB25Coverage': captureCoverage['fullB25Coverage'] == true,
      'expectedPhases': _asStringList(captureCoverage['expectedPhases']),
      'capturedPhases': _asStringList(captureCoverage['capturedPhases']),
      'missingPhases': _asStringList(captureCoverage['missingPhases']),
      'neverRunPhases': _asStringList(
        b25EvidenceCoverage['neverRunPhases'],
      ),
    },
    'b25EvidenceCoverage': b25EvidenceCoverage,
    'blueprintPath':
        'docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md',
    'screenMatrixPath':
        'docs/Build Plan V2/Evidence/B25/product-ux-screen-review-matrix.md',
    'remediationLoopPath':
        'docs/Build Plan V2/Evidence/B25/product-ux-remediation-loop.md',
    'blueprintCoverage': blueprintCoverage,
    'productDocCoverage': productDocCoverage,
    'cardSurfaceRegistrySummary': <String, Object?>{
      'status': 'advisory-non-gating',
      'rowCount': cardSurfaceRegistry.length,
      'note':
          'B25 records workflow-to-card-surface/API/renderer/fake-backend support for remediation context. This is not yet a pass/fail card-surface API coverage gate.',
    },
    'cardSurfaceRegistry': cardSurfaceRegistry,
    'screenRows': screenRows,
    'findings': <JsonMap>[
      <String, Object?>{
        'findingId': 'B25-V4-REVIEW-PENDING',
        'severity': 'major',
        'status': 'open',
        'title': 'B25 v4 independent UX review is pending',
        'summary':
            'Fresh screenshot metadata has been collected, but holistic direct-question review, workflow/role direct-question review, and screen-specific UX critique have not been completed.',
        'requiredFix':
            'Run the Production UX Judge Agent against the collected screenshots and fill holisticQuestionAnswers, workflowRoleScorecards, screen-specific critiques, findings, and remediation links.',
        'blocksPass': true,
      },
      if (_asString(captureCoverage['status']) != 'pass')
        <String, Object?>{
          'findingId': 'B25-FULL-COVERAGE-INCOMPLETE',
          'severity': 'critical-blocker',
          'status': 'open',
          'title': 'B25 full screenshot coverage is incomplete',
          'summary':
              'The current B25 review input is not based on a commit-eligible full B12-B20 capture. Targeted diagnostic captures cannot close B25.',
          'requiredFix':
              'Run b25_capture_workflow_screenshots.dart in --mode full-b25 for B12-B20, then run b25_capture_coverage_gate.dart before the evidence collector and judges.',
          'blocksPass': true,
          'generatedBy': 'b25-capture-coverage-gate',
          'issues': _asStringList(captureCoverage['issues']),
        },
    ],
    'holisticQuestionAnswers': <JsonMap>[],
    'workflowRoleScorecards': <JsonMap>[],
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
    'unresolvedBlockerFindings': <String>[
      if (_asString(captureCoverage['status']) != 'pass')
        'B25-FULL-COVERAGE-INCOMPLETE',
    ],
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
      batchId: 'B25-RB-000-product-experience-specs',
      title: 'Complete community product experience specs',
      purpose:
          'Backfill or update Product Docs V2 community-specific experience specs before UI remediation continues.',
      tickets: _ticketsForCriteria(tickets, <String>{
        'b25-c02-community-product-docs-complete',
      }),
      actions: <String>[
        'Create or update the affected community product experience docs.',
        'Define the product promise, roles/jobs, information architecture, home requirements, domain-native surfaces, workflow-to-surface mapping, role/state matrix, seed content, visual standard, and B25 review/remediation log.',
        'Do not assign UI implementation until productDocCoverage passes for the affected community.',
        'Rerun the evidence collector so B25 tickets and judge output reference the updated specs.',
      ],
      includeEvidenceWorkItems: false,
      includeUiWorkItems: false,
    ),
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
        'Fill workflow/role scorecards for every reviewed workflow/role pair.',
        'Resolve every evidenceRepairWorkItem before assigning UI implementation work for that same community/workflow/role.',
        'Keep reviewer context limited to screenshots, blueprint, evidence, and pass criteria.',
      ],
      includeProductDocWorkItems: false,
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
        'Start only after the matching evidenceRepairWorkItems have concrete roles, screenshot-derived visible text, and screen-specific critiques.',
        'Replace any primary global workflow lists, metadata pages, checklist modals, or repeated generic cards with domain-native surfaces.',
        'Rebuild primary homes and flows around community content and jobs-to-be-done.',
        'Improve hierarchy, spacing, typography, component quality, navigation clarity, and mobile layout.',
        'Update copy/content so visible UI speaks to the target role and task, not to validation mechanics.',
      ],
      includeProductDocWorkItems: false,
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
      'Product-spec work items must be completed and rerun before evidence repair or UI remediation work items for the same community are assigned.',
      'Evidence repair work items must be completed and rerun before UI remediation work items for the same community/workflow/role are assigned.',
      'UI remediation work must be scoped by community/workflow/role and target production surface, not by a broad global ticket summary.',
      'The independent judge must rerun after each batch that changes UI, evidence, or critique.',
      'No next UX feedback loop starts until the current remediation iteration is committed.',
    ],
  };
}

JsonMap buildB25WorkflowRoleCoverage(JsonMap review) {
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
    final role = _asString(row['role'], fallback: 'role-under-review');
    final fanId = _asString(row['fanId'], fallback: _fanIdFromRoleLabel(role));
    row['rowId'] = rowId;
    row['screenRowId'] = rowId;
    row['role'] = role;
    row['fanId'] = fanId;
    row['coverageRoleStatus'] = _isSpecificRole(role, fanId)
        ? 'specific-role'
        : 'role-missing-or-generic';
    enrichedRows.add(row);

    final key = [
      _asString(row['communityId'], fallback: 'unknown-community'),
      _asString(row['workflowId'], fallback: 'unknown-workflow'),
      fanId.isNotEmpty ? fanId : role,
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
    final role = _asString(first['role'], fallback: 'role-under-review');
    final fanId = _asString(first['fanId']);
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
      if (!_isSpecificRole(role, fanId)) 'specific role/fanId',
      if (!hasEntry) 'entry/start screenshot',
      if (!hasAction) 'action/review screenshot',
      if (!hasResult) 'result/receiver screenshot',
    ];
    final coverageRowId =
        'b25-wp-${coverageIndex.toString().padLeft(3, '0')}-${_slug(_asString(first['workflowId'], fallback: 'workflow'))}-${_slug(fanId.isNotEmpty ? fanId : role)}';
    coverageIndex += 1;
    coverageRows.add(<String, Object?>{
      'coverageRowId': coverageRowId,
      'status': missing.isEmpty ? 'pass' : 'fail',
      'communityId': _asString(first['communityId']),
      'communityName': _asString(first['communityName']),
      'workflowId': _asString(first['workflowId']),
      'role': role,
      'fanId': fanId,
      'screenRowIds': groupRows.map(_rowId).toList(),
      'screenshotPaths': groupRows
          .map((row) => _asString(row['screenshotPath']))
          .where((path) => path.isNotEmpty)
          .toList(),
      'screenStates': screenNames.toList()..sort(),
      'hasEntryScreenshot': hasEntry,
      'hasActionScreenshot': hasAction,
      'hasResultScreenshot': hasResult,
      'hasSpecificRole': _isSpecificRole(role, fanId),
      'missingEvidence': missing,
      'requiredFix': missing.isEmpty
          ? 'None.'
          : 'Capture or map the missing workflow/role evidence before independent UX judgment.',
    });
  }

  final failingCoverageRows = coverageRows
      .where((row) => _asString(row['status']) != 'pass')
      .toList();
  final findings = _replaceGeneratedFindings(
    _asMapList(review['findings']),
    generatedBy: 'b25-workflow-role-coverage-collector',
  );
  if (failingCoverageRows.isNotEmpty) {
    findings.add(<String, Object?>{
      'findingId': 'B25-WORKFLOW-ROLE-COVERAGE-INCOMPLETE',
      'severity': 'major',
      'status': 'open',
      'title': 'Workflow/role screenshot coverage is incomplete',
      'summary':
          '${failingCoverageRows.length} workflow/role coverage rows are missing specific roles or entry/action/result screenshot evidence.',
      'requiredFix':
          'Capture full workflow/role evidence before running the independent UX judge.',
      'blocksPass': true,
      'generatedBy': 'b25-workflow-role-coverage-collector',
      'affectedCoverageRowIds': failingCoverageRows
          .map((row) => _asString(row['coverageRowId']))
          .toList(),
    });
  }

  final result = JsonMap.of(review)
    ..['screenRows'] = enrichedRows
    ..['workflowRoleCoverage'] = coverageRows
    ..['workflowRoleCoverageSummary'] = <String, Object?>{
      'status': failingCoverageRows.isEmpty ? 'pass' : 'fail',
      'coverageRowCount': coverageRows.length,
      'failingCoverageRowCount': failingCoverageRows.length,
      'specificRoleRowCount': coverageRows
          .where((row) => row['hasSpecificRole'] == true)
          .length,
      'genericRoleRowCount': coverageRows
          .where((row) => row['hasSpecificRole'] != true)
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
  final withCoverage = withVisualAudit.containsKey('workflowRoleCoverage')
      ? JsonMap.of(withVisualAudit)
      : buildB25WorkflowRoleCoverage(withVisualAudit);
  final coverageRows = _asMapList(withCoverage['workflowRoleCoverage']);
  final coverageByKey = <String, JsonMap>{
    for (final row in coverageRows)
      _coverageKey(
        _asString(row['communityId']),
        _asString(row['workflowId']),
        _asString(row['fanId'], fallback: _asString(row['role'])),
      ): row,
  };
  final screenRows = <JsonMap>[];
  for (final row in _asMapList(withCoverage['screenRows'])) {
    final coverage =
        coverageByKey[_coverageKey(
          _asString(row['communityId']),
          _asString(row['workflowId']),
          _asString(row['fanId'], fallback: _asString(row['role'])),
        )];
    screenRows.add(_independentScreenReviewRow(row, coverage));
  }

  final workflowScorecards = coverageRows
      .map((coverage) => _workflowRoleScorecard(coverage, screenRows))
      .toList();
  final lifecycleScorecards = coverageRows
      .map((coverage) => _workflowLifecycleScorecard(coverage, screenRows))
      .toList();
  final holisticAnswers = _holisticAnswers(
    withCoverage,
    workflowScorecards,
    lifecycleScorecards,
    screenRows,
  );
  final findings = _independentUxFindings(
    withCoverage,
    screenRows,
    workflowScorecards,
    lifecycleScorecards,
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
      workflowScorecards.every(
        (scorecard) => scorecard['blocksPass'] != true,
      ) &&
      lifecycleScorecards.every((scorecard) => scorecard['blocksPass'] != true);

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
    ..['workflowRoleScorecards'] = workflowScorecards
    ..['workflowLifecycleScorecards'] = lifecycleScorecards
    ..['workflowLifecycleSummary'] = _workflowLifecycleSummary(
      lifecycleScorecards,
    )
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
          'b25_workflow_role_coverage_collector.dart',
          'b25_independent_ux_judge.dart',
        ],
        'commitSha': _asString(
          (withCoverage['reviewInputEvidence'] as JsonMap?)?['appCommitSha'],
        ),
      },
    ];
}

JsonMap buildB25WorkflowLifecycleReview(JsonMap review) {
  final screenRows = _asMapList(review['screenRows']);
  final coverageRows = _asMapList(review['workflowRoleCoverage']);
  final lifecycleScorecards = coverageRows
      .map((coverage) => _workflowLifecycleScorecard(coverage, screenRows))
      .toList();
  final findings = _workflowLifecycleFindings(review, lifecycleScorecards);
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
  final lifecyclePass =
      lifecycleScorecards.isNotEmpty &&
      lifecycleScorecards.every((scorecard) => scorecard['blocksPass'] != true);
  final canPass =
      lifecyclePass && unresolvedBlockers.isEmpty && unresolvedMajors.isEmpty;
  return JsonMap.of(review)
    ..['status'] = canPass
        ? 'workflow-lifecycle-pass'
        : 'workflow-lifecycle-fail'
    ..['finalDecision'] = canPass ? 'pass' : 'fail'
    ..['b25CanPass'] = canPass
    ..['requiresRemediation'] = !canPass
    ..['requiresRerun'] = !canPass
    ..['generatedAt'] = DateTime.now().toUtc().toIso8601String()
    ..['workflowLifecycleScorecards'] = lifecycleScorecards
    ..['workflowLifecycleSummary'] = _workflowLifecycleSummary(
      lifecycleScorecards,
    )
    ..['findings'] = findings
    ..['unresolvedBlockerFindings'] = unresolvedBlockers
    ..['unresolvedMajorFindings'] = unresolvedMajors;
}

List<String> _b25LlmReviewFreshnessProblems({
  required JsonMap review,
  required JsonMap llmReview,
  required String? runId,
  required List<String> currentScreenRowIds,
}) {
  final problems = <String>[];
  final expectedRunId = runId ?? _asString(review['currentReviewRunId']);
  final declaredRunId = _asString(
    llmReview['currentReviewRunId'] ??
        llmReview['reviewRunId'] ??
        llmReview['runId'],
  );
  if (expectedRunId.isNotEmpty && declaredRunId != expectedRunId) {
    problems.add(
      'currentReviewRunId must match the current B25 run ($expectedRunId), found `${declaredRunId.isEmpty ? 'missing' : declaredRunId}`.',
    );
  }

  final sourceReviewRunId = _asString(llmReview['sourceReviewRunId']);
  if (sourceReviewRunId.isNotEmpty) {
    problems.add(
      'sourceReviewRunId is present (`$sourceReviewRunId`); carried-forward LLM reviews cannot close B25.',
    );
  }
  if (llmReview['carriedForward'] == true ||
      llmReview['reusedPriorReview'] == true ||
      llmReview['usesPriorReview'] == true ||
      llmReview['carriedFromPriorReview'] == true) {
    problems.add(
      'LLM review declares prior-review reuse; B25 requires a fresh screenshot-specific review.',
    );
  }
  if (llmReview['freshReview'] != true &&
      llmReview['freshScreenshotReview'] != true) {
    problems.add(
      'freshReview=true is required to prove the LLM judge inspected the current screenshots.',
    );
  }

  final reviewInputEvidence = review['reviewInputEvidence'];
  final expectedCommit = reviewInputEvidence is JsonMap
      ? _asString(reviewInputEvidence['appCommitSha'])
      : '';
  final declaredCommit = _asString(
    llmReview['appCommitSha'] ?? llmReview['reviewedAppCommitSha'],
  );
  if (expectedCommit.isNotEmpty && declaredCommit != expectedCommit) {
    problems.add(
      'appCommitSha must match the reviewed app commit ($expectedCommit), found `${declaredCommit.isEmpty ? 'missing' : declaredCommit}`.',
    );
  }

  final currentRowSet = currentScreenRowIds
      .where((id) => id.trim().isNotEmpty)
      .toSet();
  final reviewedRowIds = _uniqueStrings(<String>[
    ..._asStringList(llmReview['reviewedScreenRowIds']),
    for (final screen in _asMapList(llmReview['screenReviews'])) ...[
      _asString(screen['screenRowId']),
      ..._asStringList(screen['affectedScreenRowIds']),
    ],
  ]).where((id) => id.trim().isNotEmpty).toList();
  if (reviewedRowIds.isEmpty) {
    problems.add(
      'reviewedScreenRowIds or screenReviews[].affectedScreenRowIds must identify the current screenshots reviewed by the LLM judge.',
    );
  } else {
    final invalidRows = reviewedRowIds
        .where((id) => !currentRowSet.contains(id))
        .toList();
    if (invalidRows.isNotEmpty) {
      problems.add(
        'LLM review references screen rows that are not in the current evidence: ${invalidRows.take(12).join(', ')}.',
      );
    }
  }

  final currentHashes = _asMapList(review['screenRows'])
      .map((row) => _asString(row['screenshotHash']))
      .where((hash) => hash.isNotEmpty)
      .toSet();
  final reviewedHashes = _uniqueStrings(<String>[
    ..._asStringList(llmReview['reviewedScreenshotHashes']),
    ..._asStringList(llmReview['screenshotHashes']),
    for (final screen in _asMapList(llmReview['screenReviews']))
      ..._asStringList(screen['screenshotHashes']),
    for (final screen in _asMapList(llmReview['screenReviews']))
      if (_asString(screen['screenshotHash']).isNotEmpty)
        _asString(screen['screenshotHash']),
  ]).where((hash) => hash.trim().isNotEmpty).toList();
  if (reviewedHashes.isEmpty) {
    problems.add(
      'reviewedScreenshotHashes are required so the LLM review is tied to the exact screenshots under review.',
    );
  } else if (currentHashes.isNotEmpty) {
    final invalidHashes = reviewedHashes
        .where((hash) => !currentHashes.contains(hash))
        .toList();
    if (invalidHashes.isNotEmpty) {
      problems.add(
        'LLM review references screenshot hashes that are not in the current evidence: ${invalidHashes.take(8).join(', ')}.',
      );
    }
  }

  return problems;
}

JsonMap buildB25LlmReviewFreshnessGate({
  required JsonMap review,
  required JsonMap llmReview,
  String? runId,
  String? llmReviewPath,
}) {
  final screenRows = _asMapList(review['screenRows']);
  final currentScreenRowIds = screenRows.map(_rowId).toList();
  final problems = _b25LlmReviewFreshnessProblems(
    review: review,
    llmReview: llmReview,
    runId: runId,
    currentScreenRowIds: currentScreenRowIds,
  );
  final expectedRunId = runId ?? _asString(review['currentReviewRunId']);
  final declaredRunId = _asString(
    llmReview['currentReviewRunId'] ??
        llmReview['reviewRunId'] ??
        llmReview['runId'],
  );
  final reviewInputEvidence = review['reviewInputEvidence'];
  final expectedCommit = reviewInputEvidence is JsonMap
      ? _asString(reviewInputEvidence['appCommitSha'])
      : '';
  final declaredCommit = _asString(
    llmReview['appCommitSha'] ?? llmReview['reviewedAppCommitSha'],
  );
  final reviewedRows = _uniqueStrings(<String>[
    ..._asStringList(llmReview['reviewedScreenRowIds']),
    for (final screen in _asMapList(llmReview['screenReviews'])) ...[
      _asString(screen['screenRowId']),
      ..._asStringList(screen['affectedScreenRowIds']),
    ],
  ]).where((id) => id.trim().isNotEmpty).toList();
  final reviewedHashes = _uniqueStrings(<String>[
    ..._asStringList(llmReview['reviewedScreenshotHashes']),
    ..._asStringList(llmReview['screenshotHashes']),
    for (final screen in _asMapList(llmReview['screenReviews']))
      ..._asStringList(screen['screenshotHashes']),
    for (final screen in _asMapList(llmReview['screenReviews']))
      if (_asString(screen['screenshotHash']).isNotEmpty)
        _asString(screen['screenshotHash']),
  ]).where((hash) => hash.trim().isNotEmpty).toList();

  return <String, Object?>{
    'schemaVersion': 1,
    'tool': 'b25_llm_review_freshness_gate',
    'status': problems.isEmpty ? 'pass' : 'fail',
    'llmReviewPath': llmReviewPath ?? '',
    'expectedReviewRunId': expectedRunId,
    'declaredReviewRunId': declaredRunId,
    'expectedAppCommitSha': expectedCommit,
    'declaredAppCommitSha': declaredCommit,
    'freshReview':
        llmReview['freshReview'] == true ||
        llmReview['freshScreenshotReview'] == true,
    'sourceReviewRunId': _asString(llmReview['sourceReviewRunId']),
    'carriedForward': llmReview['carriedForward'] == true,
    'reusedPriorReview': llmReview['reusedPriorReview'] == true,
    'currentScreenRowCount': currentScreenRowIds.length,
    'reviewedScreenRowCount': reviewedRows.length,
    'reviewedScreenshotHashCount': reviewedHashes.length,
    'reviewedScreenRowIds': reviewedRows,
    'reviewedScreenshotHashes': reviewedHashes,
    'requiredFields': <String>[
      'freshReview=true',
      'currentReviewRunId',
      'appCommitSha',
      'reviewedScreenRowIds',
      'reviewedScreenshotHashes',
    ],
    'disallowedFields': <String>[
      'sourceReviewRunId',
      'carriedForward=true',
      'reusedPriorReview=true',
      'usesPriorReview=true',
      'carriedFromPriorReview=true',
    ],
    'problems': problems,
  };
}

JsonMap buildB25LlmUxReviewImport(
  JsonMap review,
  JsonMap llmReview, {
  required String llmReviewPath,
  String? runId,
}) {
  final screenRows = _asMapList(review['screenRows']);
  final rowIds = screenRows.map(_rowId).toList();
  final freshnessProblems = _b25LlmReviewFreshnessProblems(
    review: review,
    llmReview: llmReview,
    runId: runId,
    currentScreenRowIds: rowIds,
  );
  final listedHolisticAnswers = _asMapList(
    llmReview['holisticQuestionAnswers'],
  );
  final llmHolisticAnswers = listedHolisticAnswers.isNotEmpty
      ? listedHolisticAnswers
      : _llmDirectQuestionAnswerList(
          llmReview['holisticDirectQuestionAnswers'],
        );
  final normalizedHolisticAnswers = llmHolisticAnswers.map((answer) {
    final affectedRows = _resolveB25ScreenRowIds(
      _asStringList(answer['affectedScreenRowIds']),
      rowIds,
    );
    final score = _asInt(answer['score']);
    final answerValue = _asString(answer['answer'] ?? answer['verdict']);
    return <String, Object?>{
      ...answer,
      'questionId': _asString(
        answer['questionId'],
        fallback: 'llm-${_slug(_asString(answer['question']))}',
      ),
      'scope': 'holistic',
      'answer': answerValue.isEmpty
          ? (score >= 80 ? 'yes' : 'no')
          : answerValue,
      'verdict':
          answerValue == 'no' ||
              answerValue == 'partial' ||
              answerValue == 'fail' ||
              score < 80
          ? 'fail'
          : 'pass',
      'score': score,
      'blocksPass':
          answer['blocksPass'] == true ||
          answerValue == 'no' ||
          answerValue == 'partial' ||
          answerValue == 'fail' ||
          score < 80,
      'visibleEvidence': _asStringList(answer['visibleEvidence']).isEmpty
          ? <String>[
              _asString(answer['visibleEvidence']),
            ].where((value) => value.trim().isNotEmpty).toList()
          : _asStringList(answer['visibleEvidence']),
      'affectedScreenRowIds': affectedRows,
      'evidenceUsed': affectedRows,
    };
  }).toList();
  final normalizedScreenReviews = _asMapList(llmReview['screenReviews']).map((
    row,
  ) {
    final affectedRows = _resolveB25ScreenRowIds(<String>[
      _asString(row['screenRowId']),
      ..._asStringList(row['affectedScreenRowIds']),
    ], rowIds);
    return <String, Object?>{
      ...row,
      'screenRowId': affectedRows.isEmpty
          ? _asString(row['screenRowId'])
          : affectedRows.first,
      'affectedScreenRowIds': affectedRows,
      'blocksPass':
          row['blocksPass'] == true ||
          _asString(row['verdict']) == 'fail' ||
          _isBlockingSeverity(row),
    };
  }).toList();
  final normalizedFindings = _asMapList(llmReview['findings']).map((finding) {
    final affectedRows = _resolveB25ScreenRowIds(
      _asStringList(finding['affectedScreenRowIds']),
      rowIds,
    );
    final severity = _asString(finding['severity'], fallback: 'major');
    return <String, Object?>{
      ...finding,
      'findingId': _asString(
        finding['findingId'],
        fallback: 'LLM-UX-${_slug(_asString(finding['title']))}',
      ),
      'source': 'llm-vision-ux-judge',
      'severity': severity,
      'status': _asString(finding['status'], fallback: 'open'),
      'resolved': finding['resolved'] == true,
      'blocksPass':
          finding['blocksPass'] == true ||
          _isBlockingSeverity(<String, Object?>{'severity': severity}),
      'affectedScreenRowIds': affectedRows,
      'requiredFix': _asString(
        finding['requiredFix'],
        fallback:
            'Remediate the visible product UX issue, recapture screenshots, and rerun the LLM vision UX review.',
      ),
      'description': _asString(
        finding['description'],
        fallback: _asString(finding['title']),
      ),
    };
  }).toList();
  final llmScreenReviewByRowId = <String, JsonMap>{
    for (final row in normalizedScreenReviews)
      for (final rowId in _asStringList(row['affectedScreenRowIds']))
        rowId: row,
  };
  final updatedScreenRows = screenRows.map((row) {
    final rowId = _rowId(row);
    final llmScreenReview = llmScreenReviewByRowId[rowId];
    if (llmScreenReview == null) {
      return row;
    }
    final llmBlocksPass = llmScreenReview['blocksPass'] == true;
    final llmCritique = _asString(llmScreenReview['critique']);
    final priorCritique = _asString(row['screenSpecificCritique']);
    return JsonMap.of(row)
      ..['llmVisionScreenReview'] = llmScreenReview
      ..['screenSpecificCritique'] =
          '$priorCritique LLM vision critique: $llmCritique'.trim()
      ..['productUxCritique'] =
          '${_asString(row['productUxCritique'])} LLM vision critique: $llmCritique'
              .trim()
      ..['verdict'] = llmBlocksPass ? 'fail' : _asString(row['verdict'])
      ..['severity'] = llmBlocksPass
          ? _asString(llmScreenReview['severity'], fallback: 'major')
          : _asString(row['severity'])
      ..['findingIds'] = _uniqueStrings(<String>[
        ..._asStringList(row['findingIds']),
        if (llmBlocksPass) 'B25-LLM-VISION-SCREEN-FAILED',
      ])
      ..['targetProductionSurface'] = _asString(
        llmScreenReview['targetProductionSurface'],
        fallback: _asString(row['targetProductionSurface']),
      );
  }).toList();
  final llmStatus = _asString(llmReview['status'], fallback: 'fail');
  final blockingLlmFindings = normalizedFindings
      .where((finding) => _isBlockingSeverity(finding) && !_isResolved(finding))
      .toList();
  final blockingLlmAnswers = normalizedHolisticAnswers
      .where((answer) => answer['blocksPass'] == true)
      .toList();
  final blockingLlmScreens = normalizedScreenReviews
      .where((screen) => screen['blocksPass'] == true)
      .toList();
  final llmCanPass =
      llmStatus == 'pass' &&
      freshnessProblems.isEmpty &&
      blockingLlmFindings.isEmpty &&
      blockingLlmAnswers.isEmpty &&
      blockingLlmScreens.isEmpty;
  final existingFindings = _asMapList(review['findings'])
      .where(
        (finding) =>
            _asString(finding['source']) != 'llm-vision-ux-judge' &&
            !_findingId(finding).startsWith('LLM-UX-'),
      )
      .toList();
  final freshnessFinding = freshnessProblems.isEmpty
      ? null
      : <String, Object?>{
          'findingId': 'B25-LLM-VISION-REVIEW-NOT-FRESH',
          'source': 'llm-vision-ux-judge',
          'severity': 'major',
          'status': 'open',
          'resolved': false,
          'blocksPass': true,
          'title': 'LLM vision review is not fresh for this B25 pass',
          'description':
              'The imported LLM vision UX review does not prove that a fresh reviewer inspected the current screenshots for this run.',
          'requiredFix':
              'Run a new LLM Vision UX Judge pass against the current screenshot inventory. The artifact must declare freshReview=true, currentReviewRunId, appCommitSha, reviewedScreenRowIds, and reviewedScreenshotHashes, and must not carry sourceReviewRunId or reuse markers.',
          'freshnessProblems': freshnessProblems,
        };
  final combinedFindings = <JsonMap>[
    ...existingFindings,
    if (freshnessFinding != null) freshnessFinding,
    ...normalizedFindings,
  ];
  final unresolvedBlockers = combinedFindings
      .where(
        (finding) =>
            _normalizedSeverity(finding) == 'critical-blocker' &&
            !_isResolved(finding),
      )
      .map(_findingId)
      .where((id) => id.isNotEmpty)
      .toList();
  final unresolvedMajors = combinedFindings
      .where(
        (finding) =>
            _normalizedSeverity(finding) == 'major' && !_isResolved(finding),
      )
      .map(_findingId)
      .where((id) => id.isNotEmpty)
      .toList();
  final existingHolistic = _asMapList(review['holisticQuestionAnswers'])
      .where((answer) => !_asString(answer['questionId']).startsWith('llm-'))
      .toList();
  final priorWorkflowScorecards = _asMapList(review['workflowRoleScorecards']);
  final activeWorkflowScorecards = _workflowRoleScorecardsWithLlmReview(
    priorWorkflowScorecards,
    normalizedScreenReviews,
  );
  final reviewInputEvidence = _reviewInputEvidenceWithCaptureCoverage(
    review,
    llmReviewPath,
  );
  return JsonMap.of(review)
    ..['currentReviewRunId'] = runId ?? _asString(review['currentReviewRunId'])
    ..['status'] = llmCanPass
        ? 'llm-vision-review-pass'
        : 'llm-vision-review-fail'
    ..['finalDecision'] = llmCanPass ? 'pass' : 'fail'
    ..['b25CanPass'] = llmCanPass
    ..['requiresRemediation'] = !llmCanPass
    ..['requiresRerun'] = !llmCanPass
    ..['generatedAt'] = DateTime.now().toUtc().toIso8601String()
    ..['llmVisionReview'] = <String, Object?>{
      'schemaVersion': 1,
      'status': llmCanPass ? 'pass' : 'fail',
      'freshReview': freshnessProblems.isEmpty,
      'freshnessProblems': freshnessProblems,
      'currentReviewRunId': _asString(
        llmReview['currentReviewRunId'] ??
            llmReview['reviewRunId'] ??
            llmReview['runId'],
      ),
      'expectedReviewRunId': runId ?? _asString(review['currentReviewRunId']),
      'sourceReviewRunId': _asString(llmReview['sourceReviewRunId']),
      'carriedForward': llmReview['carriedForward'] == true,
      'reusedPriorReview': llmReview['reusedPriorReview'] == true,
      'appCommitSha': _asString(
        llmReview['appCommitSha'] ?? llmReview['reviewedAppCommitSha'],
      ),
      'reviewedScreenRowIds': _uniqueStrings(<String>[
        ..._asStringList(llmReview['reviewedScreenRowIds']),
        for (final screen in normalizedScreenReviews)
          ..._asStringList(screen['affectedScreenRowIds']),
      ]),
      'reviewedScreenshotHashes': _uniqueStrings(<String>[
        ..._asStringList(llmReview['reviewedScreenshotHashes']),
        ..._asStringList(llmReview['screenshotHashes']),
        for (final screen in normalizedScreenReviews)
          ..._asStringList(screen['screenshotHashes']),
        for (final screen in normalizedScreenReviews)
          if (_asString(screen['screenshotHash']).isNotEmpty)
            _asString(screen['screenshotHash']),
      ]),
      'reviewerType': _asString(
        llmReview['reviewerType'],
        fallback: 'llm-vision-ux-judge',
      ),
      'sourcePath': llmReviewPath,
      'importedAt': DateTime.now().toUtc().toIso8601String(),
      'summary': _asString(llmReview['summary']),
      'holisticQuestionAnswers': normalizedHolisticAnswers,
      'screenReviews': normalizedScreenReviews,
      'findings': normalizedFindings,
      'blockingFindingIds': [
        for (final finding in blockingLlmFindings) _findingId(finding),
      ],
      'blockingQuestionIds': [
        for (final answer in blockingLlmAnswers)
          _asString(answer['questionId']),
      ],
      'blockingScreenRowIds': _uniqueStrings([
        for (final screen in blockingLlmScreens)
          ..._asStringList(screen['affectedScreenRowIds']),
      ]),
    }
    ..['deterministicScaffoldHolisticQuestionAnswers'] = existingHolistic
    ..['holisticQuestionAnswers'] = normalizedHolisticAnswers
    ..['deterministicScaffoldWorkflowRoleScorecards'] = priorWorkflowScorecards
    ..['workflowRoleScorecards'] = activeWorkflowScorecards
    ..['reviewInputEvidence'] = reviewInputEvidence
    ..['screenRows'] = updatedScreenRows
    ..['findings'] = combinedFindings
    ..['unresolvedBlockerFindings'] = unresolvedBlockers
    ..['unresolvedMajorFindings'] = unresolvedMajors;
}

List<JsonMap> _llmDirectQuestionAnswerList(Object? value) {
  final listedAnswers = _asMapList(value);
  if (listedAnswers.isNotEmpty) {
    return listedAnswers;
  }
  if (value is! JsonMap) {
    return const <JsonMap>[];
  }
  return value.entries.where((entry) => entry.value is JsonMap).map((entry) {
    final answer = JsonMap.of(entry.value as JsonMap);
    return <String, Object?>{
      ...answer,
      'questionId': _asString(answer['questionId'], fallback: entry.key),
      'question': _asString(answer['question'], fallback: entry.key),
    };
  }).toList();
}

List<JsonMap> _workflowRoleScorecardsWithLlmReview(
  List<JsonMap> scorecards,
  List<JsonMap> screenReviews,
) {
  final screenReviewsByRowId = <String, JsonMap>{};
  for (final review in screenReviews) {
    for (final rowId in _asStringList(review['affectedScreenRowIds'])) {
      screenReviewsByRowId[rowId] = review;
    }
  }

  return scorecards.map((scorecard) {
    final rowIds = _asStringList(scorecard['screenRowIds']);
    final relatedReviews = [
      for (final rowId in rowIds)
        if (screenReviewsByRowId[rowId] != null) screenReviewsByRowId[rowId]!,
    ];
    if (relatedReviews.isEmpty) {
      return scorecard;
    }

    final blocksPass = relatedReviews.any(
      (review) =>
          review['blocksPass'] == true ||
          _asString(review['verdict']) == 'fail' ||
          _isBlockingSeverity(review),
    );
    final visibleObservations = _uniqueStrings([
      for (final review in relatedReviews)
        ..._asStringList(review['visibleObservations']),
    ]);
    final critiques = _uniqueStrings([
      for (final review in relatedReviews) _asString(review['critique']),
    ]).where((value) => value.trim().isNotEmpty).toList();
    final targetSurface = _asString(
      relatedReviews.first['targetProductionSurface'],
      fallback: _asString(scorecard['targetProductionSurface']),
    );
    final score = blocksPass ? 45 : 88;
    final workflowId = _asString(scorecard['workflowId']);
    final role = _asString(scorecard['role']);
    final affectedRows = _uniqueStrings([
      ...rowIds,
      for (final review in relatedReviews)
        ..._asStringList(review['affectedScreenRowIds']),
    ]);
    final why = blocksPass
        ? 'The imported LLM vision review found blocker/major issues for this workflow/role row: ${critiques.join(' ')}'
        : 'The imported LLM vision review inspected the fresh after-screenshots and passed this workflow/role row as `$targetSurface`. ${critiques.join(' ')}';

    JsonMap updateQuestion(JsonMap question) {
      return <String, Object?>{
        ...question,
        'answer': blocksPass ? 'no' : 'yes',
        'score': score,
        'verdict': blocksPass ? 'fail' : 'pass',
        'blocksPass': blocksPass,
        'why': why,
        'requiredFix': blocksPass
            ? 'Apply the LLM vision review fix, recapture fresh screenshots, and rerun B25.'
            : 'None.',
        'visibleEvidence': visibleObservations.isEmpty
            ? affectedRows
            : visibleObservations,
        'evidenceUsed': affectedRows,
      };
    }

    return <String, Object?>{
      ...scorecard,
      'status': blocksPass ? 'fail' : 'pass',
      'blocksPass': blocksPass,
      'targetProductionSurface': targetSurface,
      'llmVisionWorkflowReview': <String, Object?>{
        'status': blocksPass ? 'fail' : 'pass',
        'screenRowIds': affectedRows,
        'screenReviews': relatedReviews,
      },
      'semanticSurfaceProof': <String, Object?>{
        ...((scorecard['semanticSurfaceProof'] as JsonMap?) ??
            <String, Object?>{}),
        'status': blocksPass ? 'fail' : 'pass',
        'targetProductionSurface': targetSurface,
        'missingGroups': blocksPass
            ? _asStringList(
                (scorecard['semanticSurfaceProof']
                    as JsonMap?)?['missingGroups'],
              )
            : <String>[],
        'summary': blocksPass
            ? 'The imported LLM vision review still found this target surface incomplete for `$workflowId` / `$role`.'
            : 'The imported LLM vision review visually confirmed `$targetSurface` for `$workflowId` / `$role` from fresh after-screenshots.',
      },
      'questions': _asMapList(
        scorecard['questions'],
      ).map(updateQuestion).toList(),
      'summary': blocksPass
          ? 'Workflow/role review failed for `$workflowId` / `$role` after LLM vision import.'
          : 'Workflow/role review passed for `$workflowId` / `$role` after LLM vision import.',
    };
  }).toList();
}

JsonMap _reviewInputEvidenceWithCaptureCoverage(
  JsonMap review,
  String llmReviewPath,
) {
  final reviewInput = JsonMap.of(
    (review['reviewInputEvidence'] as JsonMap?) ?? <String, Object?>{},
  );
  final coverage = _readSiblingB25CaptureCoverage(llmReviewPath);
  if (coverage == null) {
    return reviewInput;
  }
  return reviewInput
    ..['captureCoverage'] = coverage
    ..['captureMode'] = _asString(coverage['captureMode'])
    ..['commitEligible'] = coverage['commitEligible'] == true
    ..['fullB25Coverage'] = coverage['fullB25Coverage'] == true
    ..['expectedPhases'] = _asStringList(coverage['expectedPhases'])
    ..['capturedPhases'] = _asStringList(coverage['capturedPhases'])
    ..['missingPhases'] = _asStringList(coverage['missingPhases'])
    ..['workflowManifestCount'] = _asInt(coverage['workflowManifestCount'])
    ..['screenshotCount'] = _asInt(coverage['screenshotCount'])
    ..['workflowEvidenceManifestPaths'] = _asStringList(
      coverage['workflowEvidenceManifestPaths'],
    );
}

JsonMap? _readSiblingB25CaptureCoverage(String llmReviewPath) {
  final llmFile = File(llmReviewPath);
  final candidates = <File>[
    File('${llmFile.parent.path}/b25-capture-coverage-report.json'),
    File(
      '${Directory.current.path}/../docs/Build Plan V2/Evidence/B25/b25-capture-coverage-report.json',
    ),
  ];
  for (final file in candidates) {
    if (!file.existsSync()) {
      continue;
    }
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is JsonMap) {
      return decoded;
    }
  }
  return null;
}

JsonMap _independentScreenReviewRow(JsonMap row, JsonMap? coverage) {
  final updated = JsonMap.of(row);
  final rowId = _rowId(row);
  final visibleText = _asString(row['visibleTextExtract']);
  final source = _asString(row['visibleTextExtractionSource']);
  final role = _asString(row['role'], fallback: 'role-under-review');
  final fanId = _asString(row['fanId']);
  final workflowId = _asString(row['workflowId']);
  final isSupportSurface = _workflowIsSupportSurface(workflowId);
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
    if (coverageMissing.isNotEmpty) 'B25-WORKFLOW-ROLE-COVERAGE-INCOMPLETE',
    if (!_isSpecificRole(role, fanId)) 'B25-ROLE-SCOPE-MISSING',
    if (visibleText.isEmpty) 'B25-VISIBLE-TEXT-MISSING',
    if (source != 'screenshot-visible-text' && source != 'ocr-visible-text')
      'B25-VISIBLE-TEXT-NOT-SCREEN-EXTRACTED',
    if (!isSupportSurface &&
        _surfaceClassificationIsUnverified(classification, primarySurface))
      'B25-DOMAIN-SURFACE-UNVERIFIED',
    ...visualFindingIds,
  }.toList();
  final critique = StringBuffer()
    ..write('Screen `$rowId` for workflow `$workflowId` ');
  if (_isSpecificRole(role, fanId)) {
    critique.write('and role `$role` ');
  } else {
    critique.write('does not identify a specific production role; ');
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
  if (!isSupportSurface &&
      _surfaceClassificationIsUnverified(classification, primarySurface)) {
    critique.write(
      ' The row still lacks screenshot-backed proof that the primary surface is domain-native; current classification is `${classification.isEmpty ? 'missing' : classification}` and primary surface is `${primarySurface.isEmpty ? 'missing' : primarySurface}`.',
    );
  } else if (isSupportSurface) {
    critique.write(
      ' This is support/capability evidence, so it is judged for App Shell capability proof rather than primary workflow domain-surface replacement.',
    );
  }
  final verdict = findingIds.isEmpty ? 'pass' : 'fail';
  updated
    ..['screenSpecificCritique'] = critique.toString()
    ..['productUxCritique'] = critique.toString()
    ..['uiPatternClassification'] = findingIds.isEmpty
        ? (isSupportSurface
              ? 'support-surface-reviewed'
              : 'domain-native-reviewed')
        : 'coverage-or-review-incomplete'
    ..['primarySurfaceType'] = findingIds.isEmpty
        ? (isSupportSurface ? 'app-shell-capability-surface' : 'domain-native')
        : 'unverified-primary-surface'
    ..['primary'] = !isSupportSurface
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

JsonMap _workflowRoleScorecard(JsonMap coverage, List<JsonMap> screenRows) {
  final coverageRowId = _asString(coverage['coverageRowId']);
  final workflowId = _asString(coverage['workflowId']);
  final role = _asString(coverage['role']);
  final fanId = _asString(coverage['fanId']);
  final isSupportSurface = _workflowIsSupportSurface(workflowId);
  final relatedRows = screenRows.where((row) {
    return _asString(row['workflowId']) == workflowId &&
        _asString(row['communityId']) == _asString(coverage['communityId']) &&
        (_asString(row['fanId']) == fanId || _asString(row['role']) == role);
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
  final semanticProof = _semanticSurfaceProofForWorkflow(
    workflowId: workflowId,
    visibleTextEvidence: relatedRows.map(
      (row) => _asString(row['visibleTextExtract']),
    ),
  );
  final semanticPass =
      semanticProof['status'] == 'pass' ||
      _workflowIsSupportSurface(workflowId);
  final screenshotRefs = relatedRows
      .map((row) => _asString(row['screenshotPath']))
      .where((path) => path.isNotEmpty)
      .toList();
  final coveragePass = missing.isEmpty;
  final rowPass = rowFailures.isEmpty;
  final domainPass =
      coveragePass &&
      rowPass &&
      visualFailures.isEmpty &&
      (isSupportSurface || semanticPass);
  final questions = <JsonMap>[
    _directAnswer(
      questionId: '$coverageRowId-coverage',
      scope: 'workflow-role',
      question:
          'Does workflow `$workflowId` have complete entry/action/result screenshot coverage for role `$role`?',
      pass: coveragePass,
      score: coveragePass ? 90 : 30,
      evidenceUsed: _asStringList(coverage['screenRowIds']),
      why: coveragePass
          ? 'Entry, action, and result evidence exists for this workflow/role row.'
          : 'Missing coverage: ${missing.join(', ')}.',
      requiredFix: coveragePass
          ? 'None.'
          : 'Capture the missing screenshot states and assign a specific role/fanId.',
    ),
    _directAnswer(
      questionId: '$coverageRowId-domain-surface',
      scope: 'workflow-role',
      question: isSupportSurface
          ? 'Does support workflow `$workflowId` prove the required App Shell capability evidence for role `$role` without visual blockers?'
          : 'Is the primary UI for workflow `$workflowId` and role `$role` a domain-native product surface instead of a generic card/checklist/metadata screen?',
      pass: domainPass,
      score: domainPass ? 85 : 35,
      evidenceUsed: rowFailures.isEmpty
          ? _asStringList(coverage['screenRowIds'])
          : rowFailures,
      why: domainPass
          ? (isSupportSurface
                ? 'Screenshot evidence and visual inspection support this App Shell capability group.'
                : 'Screenshot pixel/layout inspection, row critique, and semantic surface proof all support this workflow/role group.')
          : 'Rows still have unresolved visual/review/coverage/semantic failures: ${_workflowRoleFailureSummary(missing, rowFailures, semanticProof)}.',
      requiredFix: domainPass
          ? 'None.'
          : (isSupportSurface
                ? 'Recapture the exact App Shell capability screenshots and resolve any visual or coverage blockers for this support workflow.'
                : 'Replace or document the exact domain-native surface and recapture the affected workflow/role rows.'),
    ),
    _directAnswer(
      questionId: '$coverageRowId-semantic-surface-proof',
      scope: 'workflow-role',
      question:
          'Does the after screenshot prove the requested target product surface for workflow `$workflowId` and role `$role` is actually present, with the required domain content and affordances?',
      pass: semanticPass,
      score: semanticPass ? 90 : 25,
      evidenceUsed: _asStringList(coverage['screenRowIds']),
      why: semanticPass
          ? _asString(semanticProof['summary'])
          : '${_asString(semanticProof['summary'])} Missing groups: ${_asStringList(semanticProof['missingGroups']).join(', ')}.',
      requiredFix: semanticPass
          ? 'None.'
          : 'Implement the requested target surface, recapture after screenshots, and show visible UI evidence for every missing group: ${_asStringList(semanticProof['missingGroups']).join(', ')}.',
    ),
    _directAnswer(
      questionId: '$coverageRowId-visual-quality',
      scope: 'workflow-role',
      question:
          'Does screenshot pixel/layout inspection show a modern, intentional, non-generic UI for workflow `$workflowId` and role `$role`?',
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
      scope: 'workflow-role',
      question:
          'Does the review cite visible UI/text and a task-specific critique for workflow `$workflowId` and role `$role`?',
      pass: rowPass && textEvidence.isNotEmpty,
      score: rowPass && textEvidence.isNotEmpty ? 85 : 35,
      evidenceUsed: rowFailures.isEmpty
          ? _asStringList(coverage['screenRowIds'])
          : rowFailures,
      why: rowPass && textEvidence.isNotEmpty
          ? 'The scorecard cites visible text: ${textEvidence.join(' | ')}.'
          : 'Visible text or row-specific critique is missing or unsupported for this workflow/role group.',
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
    'role': role,
    'fanId': fanId,
    'status': blocks ? 'fail' : 'pass',
    'blocksPass': blocks,
    'screenRowIds': _asStringList(coverage['screenRowIds']),
    'screenshotPaths': screenshotRefs,
    'targetProductionSurface': _targetProductionSurfaceForWorkflow(workflowId),
    'semanticSurfaceProof': semanticProof,
    'referencePatternsToCopy': _b25ReferencePatternsForWorkflow(workflowId),
    'referenceResearchQueries': _referenceResearchQueriesForWorkflow(
      workflowId,
    ),
    'questions': questions,
    'summary': blocks
        ? 'Workflow/role review failed for `$workflowId` / `$role`.'
        : 'Workflow/role review passed for `$workflowId` / `$role`.',
  };
}

JsonMap _workflowLifecycleScorecard(
  JsonMap coverage,
  List<JsonMap> screenRows,
) {
  final coverageRowId = _asString(coverage['coverageRowId']);
  final workflowId = _asString(coverage['workflowId']);
  final role = _asString(coverage['role']);
  final fanId = _asString(coverage['fanId']);
  final relatedRows = screenRows.where((row) {
    return _asString(row['workflowId']) == workflowId &&
        _asString(row['communityId']) == _asString(coverage['communityId']) &&
        (_asString(row['fanId']) == fanId || _asString(row['role']) == role);
  }).toList();
  final visibleTextEvidence = relatedRows
      .map((row) => _asString(row['visibleTextExtract']))
      .where((text) => text.isNotEmpty)
      .toList();
  final proof = _workflowLifecycleProofForWorkflow(
    communityId: _asString(coverage['communityId']),
    communityName: _asString(coverage['communityName']),
    workflowId: workflowId,
    role: role,
    visibleTextEvidence: visibleTextEvidence,
  );
  final supportSurface = _asStringList(
    proof['passedGroups'],
  ).contains('support-surface');
  final interactionModel = proof['semanticInteractionModel'] is JsonMap
      ? proof['semanticInteractionModel'] as JsonMap
      : <String, Object?>{};
  final coverageMissing = _asStringList(coverage['missingEvidence']);
  final proofPass = proof['status'] == 'pass';
  final coveragePass = coverageMissing.isEmpty;
  if (supportSurface) {
    final questions = <JsonMap>[
      _directAnswer(
        questionId: '$coverageRowId-lifecycle-support-surface',
        scope: 'workflow-lifecycle',
        question:
            'Is `$workflowId` a support/evidence surface where production workflow lifecycle proof is not required, and is its screenshot evidence still present?',
        pass: coveragePass,
        score: coveragePass ? 90 : 30,
        evidenceUsed: _asStringList(coverage['screenRowIds']),
        why: coveragePass
            ? 'This row is a support/evidence surface; lifecycle proof is not required and screenshot evidence is present.'
            : 'This row is a support/evidence surface, but required screenshot evidence is missing: ${coverageMissing.join(', ')}.',
        requiredFix: coveragePass
            ? 'None.'
            : 'Capture the missing support/evidence screenshots before closing B25.',
      ),
    ];
    return <String, Object?>{
      'scorecardId': '$coverageRowId-lifecycle',
      'coverageRowId': coverageRowId,
      'communityId': _asString(coverage['communityId']),
      'communityName': _asString(coverage['communityName']),
      'workflowId': workflowId,
      'role': role,
      'fanId': fanId,
      'status': coveragePass ? 'pass' : 'fail',
      'blocksPass': !coveragePass,
      'screenRowIds': _asStringList(coverage['screenRowIds']),
      'screenshotPaths': relatedRows
          .map((row) => _asString(row['screenshotPath']))
          .where((path) => path.isNotEmpty)
          .toList(),
      'targetProductionSurface': _targetProductionSurfaceForWorkflow(
        workflowId,
      ),
      'workflowLifecycleProof': proof,
      'semanticInteractionModel': interactionModel,
      'requiredLifecycleGroups': _asMapList(proof['requiredGroups']),
      'missingLifecycleGroups': _asStringList(proof['missingGroups']),
      'referencePatternsToCopy': _b25ReferencePatternsForWorkflow(workflowId),
      'referenceResearchQueries': _referenceResearchQueriesForWorkflow(
        workflowId,
      ),
      'questions': questions,
      'acceptanceCriteria': _workflowLifecycleAcceptanceCriteria(
        workflowId,
        role,
      ),
      'summary': coveragePass
          ? 'Support surface lifecycle review passed for `$workflowId` / `$role`.'
          : 'Support surface lifecycle review failed for `$workflowId` / `$role`: ${coverageMissing.join(', ')}.',
    };
  }
  final questions = <JsonMap>[
    _directAnswer(
      questionId: '$coverageRowId-lifecycle-object-context',
      scope: 'workflow-lifecycle',
      question:
          'Does workflow `$workflowId` for role `$role` show the concrete domain object and the information needed before the user decides?',
      pass: _lifecycleGroupsPassed(proof, <String>[
        'concrete object/context',
        'decision information',
      ]),
      score:
          _lifecycleGroupsPassed(proof, <String>[
            'concrete object/context',
            'decision information',
          ])
          ? 90
          : 30,
      evidenceUsed: _asStringList(coverage['screenRowIds']),
      why:
          _lifecycleGroupsPassed(proof, <String>[
            'concrete object/context',
            'decision information',
          ])
          ? 'Visible screenshots prove the user can identify what they are acting on and see enough domain data to decide.'
          : 'Visible screenshots do not prove the domain object/context and required decision information. Missing: ${_lifecycleMissingLabels(proof, <String>['concrete object/context', 'decision information']).join(', ')}.',
      requiredFix:
          _lifecycleGroupsPassed(proof, <String>[
            'concrete object/context',
            'decision information',
          ])
          ? 'None.'
          : 'Add visible domain data before the action: title/name, relevant dates/timing/amounts/audience/status/content, and the actor/receiver context needed for this workflow.',
    ),
    _directAnswer(
      questionId: '$coverageRowId-lifecycle-actions',
      scope: 'workflow-lifecycle',
      question:
          'Does workflow `$workflowId` for role `$role` provide production-grade action affordances, including primary action plus reject/decline/change/edit/undo/defer where the domain requires it?',
      pass: _lifecycleGroupsPassed(proof, <String>[
        'primary semantic action',
        'alternate/change/reject affordance',
      ]),
      score:
          _lifecycleGroupsPassed(proof, <String>[
            'primary semantic action',
            'alternate/change/reject affordance',
          ])
          ? 90
          : 25,
      evidenceUsed: _asStringList(coverage['screenRowIds']),
      why:
          _lifecycleGroupsPassed(proof, <String>[
            'primary semantic action',
            'alternate/change/reject affordance',
          ])
          ? 'Visible screenshots prove natural primary and alternate/change/reject affordances.'
          : 'Visible screenshots do not prove full action affordances. Missing: ${_lifecycleMissingLabels(proof, <String>['primary semantic action', 'alternate/change/reject affordance']).join(', ')}.',
      requiredFix:
          _lifecycleGroupsPassed(proof, <String>[
            'primary semantic action',
            'alternate/change/reject affordance',
          ])
          ? 'None.'
          : 'Replace accept/cancel-only workflow cards with domain actions. Add reject/decline/not attending/change response/edit/undo/defer/withdraw or an explicit domain-specific alternative when the user needs a real choice.',
    ),
    _directAnswer(
      questionId: '$coverageRowId-lifecycle-interaction-model',
      scope: 'workflow-lifecycle',
      question:
          'Does workflow `$workflowId` for role `$role` implement the right semantic interaction model for the user decision, rather than a generic accept/cancel or submit/cancel action?',
      pass: _lifecycleGroupsPassed(proof, <String>[
        'semantic interaction model',
      ]),
      score:
          _lifecycleGroupsPassed(proof, <String>['semantic interaction model'])
          ? 90
          : 20,
      evidenceUsed: _asStringList(coverage['screenRowIds']),
      why: _lifecycleGroupsPassed(proof, <String>['semantic interaction model'])
          ? 'Visible screenshots prove the domain-specific decision and correct action set for this workflow/role.'
          : _asString(interactionModel['why']).isNotEmpty
          ? _asString(interactionModel['why'])
          : 'Visible screenshots do not prove that the correct semantic actions for this workflow/role are implemented.',
      requiredFix: _asString(interactionModel['requiredFix']).isNotEmpty
          ? _asString(interactionModel['requiredFix'])
          : 'Update the product doc workflow lifecycle and UI so the visible screen provides the correct domain decision, primary action, alternate/change/reject path, result state, and receiver/continuation path.',
    ),
    _directAnswer(
      questionId: '$coverageRowId-lifecycle-result-state',
      scope: 'workflow-lifecycle',
      question:
          'After the action in `$workflowId`, does the UI show a persistent result state and receiver/continuation state that a real user can understand later?',
      pass: _lifecycleGroupsPassed(proof, <String>[
        'persistent result state',
        'receiver/continuation state',
      ]),
      score:
          _lifecycleGroupsPassed(proof, <String>[
            'persistent result state',
            'receiver/continuation state',
          ])
          ? 90
          : 30,
      evidenceUsed: _asStringList(coverage['screenRowIds']),
      why:
          _lifecycleGroupsPassed(proof, <String>[
            'persistent result state',
            'receiver/continuation state',
          ])
          ? 'Visible screenshots prove the workflow has a durable result and receiver/continuation state.'
          : 'Visible screenshots do not prove the durable result and receiver/continuation state. Missing: ${_lifecycleMissingLabels(proof, <String>['persistent result state', 'receiver/continuation state']).join(', ')}.',
      requiredFix:
          _lifecycleGroupsPassed(proof, <String>[
            'persistent result state',
            'receiver/continuation state',
          ])
          ? 'None.'
          : 'Add completion/result/receipt/history state and, for multi-role or broadcast workflows, the receiver/read/continuation state visible to the next role.',
    ),
    _directAnswer(
      questionId: '$coverageRowId-lifecycle-coverage',
      scope: 'workflow-lifecycle',
      question:
          'Does lifecycle evidence for `$workflowId` include entry, action/review, and result/receiver screenshots for role `$role`?',
      pass: coveragePass,
      score: coveragePass ? 90 : 30,
      evidenceUsed: _asStringList(coverage['screenRowIds']),
      why: coveragePass
          ? 'Entry/action/result lifecycle screenshot coverage exists for this workflow/role.'
          : 'Missing lifecycle coverage: ${coverageMissing.join(', ')}.',
      requiredFix: coveragePass
          ? 'None.'
          : 'Capture the missing lifecycle screenshots after the UI is updated.',
    ),
  ];
  final blocks =
      !proofPass ||
      !coveragePass ||
      questions.any((question) => question['blocksPass'] == true);
  return <String, Object?>{
    'scorecardId': '$coverageRowId-lifecycle',
    'coverageRowId': coverageRowId,
    'communityId': _asString(coverage['communityId']),
    'communityName': _asString(coverage['communityName']),
    'workflowId': workflowId,
    'role': role,
    'fanId': fanId,
    'status': blocks ? 'fail' : 'pass',
    'blocksPass': blocks,
    'screenRowIds': _asStringList(coverage['screenRowIds']),
    'screenshotPaths': relatedRows
        .map((row) => _asString(row['screenshotPath']))
        .where((path) => path.isNotEmpty)
        .toList(),
    'targetProductionSurface': _targetProductionSurfaceForWorkflow(workflowId),
    'workflowLifecycleProof': proof,
    'semanticInteractionModel': interactionModel,
    'requiredLifecycleGroups': _asMapList(proof['requiredGroups']),
    'missingLifecycleGroups': _asStringList(proof['missingGroups']),
    'referencePatternsToCopy': _b25ReferencePatternsForWorkflow(workflowId),
    'referenceResearchQueries': _referenceResearchQueriesForWorkflow(
      workflowId,
    ),
    'questions': questions,
    'acceptanceCriteria': _workflowLifecycleAcceptanceCriteria(
      workflowId,
      role,
    ),
    'summary': blocks
        ? 'Workflow lifecycle review failed for `$workflowId` / `$role`: ${_asStringList(proof['missingGroups']).join(', ')}.'
        : 'Workflow lifecycle review passed for `$workflowId` / `$role`.',
  };
}

String _workflowRoleFailureSummary(
  List<String> missing,
  List<String> rowFailures,
  JsonMap semanticProof,
) {
  final parts = <String>[];
  if (missing.isNotEmpty) {
    parts.add('missing coverage: ${missing.join(', ')}');
  }
  if (rowFailures.isNotEmpty) {
    parts.add('row failures: ${rowFailures.join(', ')}');
  }
  if (semanticProof['status'] == 'fail') {
    final missingGroups = _asStringList(semanticProof['missingGroups']);
    parts.add(
      'semantic surface proof missing: ${missingGroups.isEmpty ? 'target-surface evidence' : missingGroups.join(', ')}',
    );
  }
  return parts.isEmpty ? 'unknown failure' : parts.join('; ');
}

JsonMap _semanticSurfaceProofForWorkflow({
  required String workflowId,
  required Iterable<String> visibleTextEvidence,
}) {
  final targetSurface = _targetProductionSurfaceForWorkflow(workflowId);
  final text = visibleTextEvidence.join(' | ').toLowerCase();
  final groups = _semanticRequirementGroupsForWorkflow(workflowId);
  if (_workflowIsSupportSurface(workflowId)) {
    return <String, Object?>{
      'status': 'pass',
      'targetProductionSurface': targetSurface,
      'requiredGroups': <JsonMap>[],
      'passedGroups': <String>['support-surface'],
      'missingGroups': <String>[],
      'visibleEvidenceExcerpt': _truncate(text, 700),
      'summary':
          'Support surface workflow; semantic production-surface proof is not required.',
    };
  }
  if (groups.isEmpty) {
    return <String, Object?>{
      'status': 'fail',
      'targetProductionSurface': targetSurface,
      'requiredGroups': <JsonMap>[],
      'passedGroups': <String>[],
      'missingGroups': <String>['specific target product surface'],
      'visibleEvidenceExcerpt': _truncate(text, 700),
      'summary':
          'The target production surface is not specific enough to prove from screenshots.',
    };
  }

  final passed = <String>[];
  final missing = <String>[];
  for (final group in groups) {
    final label = _asString(group['label']);
    final terms = _asStringList(group['terms']);
    if (_containsAnyTerm(text, terms)) {
      passed.add(label);
    } else {
      missing.add(label);
    }
  }

  return <String, Object?>{
    'status': missing.isEmpty ? 'pass' : 'fail',
    'targetProductionSurface': targetSurface,
    'requiredGroups': groups,
    'passedGroups': passed,
    'missingGroups': missing,
    'visibleEvidenceExcerpt': _truncate(text, 700),
    'summary': missing.isEmpty
        ? 'After-screenshot visible text proves the target surface: $targetSurface.'
        : 'After-screenshot visible text does not yet prove the target surface: $targetSurface.',
  };
}

JsonMap _workflowLifecycleProofForWorkflow({
  required String communityId,
  required String communityName,
  required String workflowId,
  required String role,
  required Iterable<String> visibleTextEvidence,
}) {
  final targetSurface = _targetProductionSurfaceForWorkflow(workflowId);
  final text = visibleTextEvidence.join(' | ').toLowerCase();
  final requiredGroups = _workflowLifecycleRequirementGroupsForWorkflow(
    workflowId,
  );
  if (_workflowIsSupportSurface(workflowId)) {
    return <String, Object?>{
      'status': 'pass',
      'targetProductionSurface': targetSurface,
      'role': role,
      'requiredGroups': <JsonMap>[],
      'passedGroups': <String>['support-surface'],
      'missingGroups': <String>[],
      'visibleEvidenceExcerpt': _truncate(text, 900),
      'summary':
          'Support surface workflow; production workflow lifecycle proof is not required.',
    };
  }
  final interactionModel = _semanticInteractionModelForWorkflow(
    communityId: communityId,
    communityName: communityName,
    workflowId: workflowId,
    role: role,
    visibleText: text,
  );
  final fullRequiredGroups = <JsonMap>[
    ...requiredGroups,
    _semanticInteractionModelRequirementGroup(interactionModel),
  ];
  final passed = <String>[];
  final missing = <String>[];
  for (final group in requiredGroups) {
    final label = _asString(group['label']);
    final terms = _asStringList(group['terms']);
    if (_containsAnyTerm(text, terms)) {
      passed.add(label);
    } else {
      missing.add(label);
    }
  }
  if (_asString(interactionModel['status']) == 'pass') {
    passed.add('semantic interaction model');
  } else {
    missing.add('semantic interaction model');
  }
  return <String, Object?>{
    'status': missing.isEmpty ? 'pass' : 'fail',
    'targetProductionSurface': targetSurface,
    'role': role,
    'requiredGroups': fullRequiredGroups,
    'passedGroups': passed,
    'missingGroups': missing,
    'semanticInteractionModel': interactionModel,
    'visibleEvidenceExcerpt': _truncate(text, 900),
    'summary': missing.isEmpty
        ? 'Screenshots prove the full production interaction model for `$workflowId`: context, decision data, correct actions, result state, and receiver/continuation state.'
        : 'Screenshots do not prove the full production interaction model for `$workflowId`. Missing lifecycle groups: ${missing.join(', ')}.',
  };
}

bool _lifecycleGroupsPassed(JsonMap proof, List<String> groupLabels) {
  final passed = _asStringList(proof['passedGroups']).toSet();
  return groupLabels.every(passed.contains);
}

List<String> _lifecycleMissingLabels(JsonMap proof, List<String> groupLabels) {
  final missing = _asStringList(proof['missingGroups']).toSet();
  return groupLabels.where(missing.contains).toList();
}

List<String> _workflowLifecycleAcceptanceCriteria(
  String workflowId,
  String role,
) {
  return <String>[
    'The `${workflowId}` screenshots show the concrete domain object/context for `${role}`.',
    'The user can see enough domain-specific decision information before acting.',
    'The UI provides semantic primary action and the needed alternate/change/reject/defer path; `Cancel` alone cannot stand in for a real decline/reject/change response.',
    'The semantic interaction model names the correct user decision and the right domain actions for `${workflowId}`; generic accept/cancel or submit/cancel actions do not satisfy this criterion.',
    'The post-action screen shows a persistent result/receipt/status state that can be understood later.',
    'The receiver/read-only/continuation state is visible where another role or later state is part of the workflow.',
    'The workflow lifecycle scorecard passes with no missing lifecycle groups.',
  ];
}

JsonMap _workflowLifecycleSummary(List<JsonMap> scorecards) {
  final failing = scorecards
      .where((scorecard) => scorecard['blocksPass'] == true)
      .toList();
  final missingGroups = <String>{};
  for (final scorecard in failing) {
    missingGroups.addAll(_asStringList(scorecard['missingLifecycleGroups']));
  }
  return <String, Object?>{
    'status': scorecards.isNotEmpty && failing.isEmpty ? 'pass' : 'fail',
    'scorecardCount': scorecards.length,
    'failingScorecardCount': failing.length,
    'failingScorecardIds': failing
        .map((scorecard) => _asString(scorecard['scorecardId']))
        .where((id) => id.isNotEmpty)
        .toList(),
    'missingLifecycleGroups': missingGroups.toList()..sort(),
  };
}

JsonMap _semanticInteractionModelRequirementGroup(JsonMap interactionModel) {
  return <String, Object?>{
    'label': 'semantic interaction model',
    'decision': _asString(interactionModel['expectedDecision']),
    'requiredPrimaryActions': _asStringList(
      interactionModel['requiredPrimaryActions'],
    ),
    'requiredAlternateActions': _asStringList(
      interactionModel['requiredAlternateActions'],
    ),
    'disallowedGenericSubstitutes': _asStringList(
      interactionModel['disallowedGenericSubstitutes'],
    ),
  };
}

JsonMap _semanticInteractionModelForWorkflow({
  required String communityId,
  required String communityName,
  required String workflowId,
  required String role,
  required String visibleText,
}) {
  final model = _expectedSemanticInteractionModel(
    communityId: communityId,
    communityName: communityName,
    workflowId: workflowId,
    role: role,
  );
  final primaryActions = _asStringList(model['requiredPrimaryActions']);
  final alternateActions = _asStringList(model['requiredAlternateActions']);
  final genericSubstitutes = _asStringList(
    model['disallowedGenericSubstitutes'],
  );
  final alternateMatches = _matchTermsOnWordBoundaries(
    visibleText,
    alternateActions,
  );
  final visibleAlternate = _matchesToSortedTerms(alternateMatches);
  final visiblePrimary = _matchesToSortedTerms(
    _matchTermsOnWordBoundaries(
      visibleText,
      primaryActions,
      excludedSpans: alternateMatches.map((match) => match.span).toList(),
    ),
  );
  final visibleGenericSubstitutes = _matchingTerms(
    visibleText,
    genericSubstitutes,
  );
  final missing = <String>[];
  if (visiblePrimary.isEmpty) {
    missing.add('domain-specific primary action');
  }
  if (visibleAlternate.isEmpty) {
    missing.add('domain-specific alternate/change/reject action');
  }
  final wrongSubstitutes = <String>[];
  if (visibleGenericSubstitutes.isNotEmpty &&
      (visiblePrimary.isEmpty || visibleAlternate.isEmpty)) {
    wrongSubstitutes.addAll(visibleGenericSubstitutes);
  }
  final status = missing.isEmpty && wrongSubstitutes.isEmpty ? 'pass' : 'fail';
  return <String, Object?>{
    'status': status,
    'communityId': communityId,
    'communityName': communityName,
    'workflowId': workflowId,
    'role': role,
    'productDocPath': _asString(model['productDocPath']),
    'expectedDecision': _asString(model['expectedDecision']),
    'requiredPrimaryActions': primaryActions,
    'requiredAlternateActions': alternateActions,
    'disallowedGenericSubstitutes': genericSubstitutes,
    'visiblePrimaryActions': visiblePrimary,
    'visibleAlternateActions': visibleAlternate,
    'visibleGenericSubstitutes': visibleGenericSubstitutes,
    'missingActions': missing,
    'wrongGenericSubstitutes': wrongSubstitutes.toSet().toList()..sort(),
    'resultAndReceiverState': _asString(model['resultAndReceiverState']),
    'alternateRequirementNote': _asString(model['alternateRequirementNote']),
    'productDocRequirement': _asString(model['productDocPath']),
    'why': status == 'pass'
        ? 'Visible screenshots match `${_asString(model['productDocPath'])}` and show the expected decision and domain-specific action set: ${_asString(model['expectedDecision'])}.'
        : 'The screenshots do not prove the product-doc interaction model for `${communityName.isEmpty ? communityId : communityName}` / `${workflowId}` / `${role}` from `${_asString(model['productDocPath'])}`. Missing actions: ${missing.isEmpty ? 'none' : missing.join(', ')}. Generic substitutes present: ${wrongSubstitutes.isEmpty ? 'none' : wrongSubstitutes.toSet().join(', ')}.${_asString(model['alternateRequirementNote']).isEmpty ? '' : ' The product-doc alternate cell declares `${_asString(model['alternateRequirementNote'])}`, so the row cannot satisfy the non-happy-path bar as written.'}',
    'requiredFix': status == 'pass'
        ? 'None.'
        : _asString(model['alternateRequirementNote']).isNotEmpty
        ? 'Report the product-contract gap: the B25 row declares no alternate/change/reject action. Do not substitute a generic action. After the product requirement is resolved outside this ticket, implement and recapture the documented domain action.'
        : 'Implement the visible domain-specific primary action and alternate/change/reject path listed by the owning community product doc, recapture fresh screenshots, and rerun the interaction-model judge.',
  };
}

final B25ProductDocInteractionCatalog _b25ProductDocInteractionCatalog =
    B25ProductDocInteractionCatalog.fromRepositoryRoot(
      locateB25RepositoryRoot(),
    );

JsonMap _expectedSemanticInteractionModel({
  required String communityId,
  required String communityName,
  required String workflowId,
  required String role,
}) {
  final model = _b25ProductDocInteractionCatalog.requireModel(
    communityId: communityId,
    communityName: communityName,
    workflowId: workflowId,
    role: role,
  );
  return <String, Object?>{
    ...model.toJson(),
    'disallowedGenericSubstitutes': b25DisallowedGenericSubstitutes,
  };
}

bool _isAdSurfaceWorkflow(String id) {
  final lower = id.toLowerCase();
  return lower.contains('no-fill') ||
      lower.contains('banner') ||
      lower.contains('sponsor') ||
      lower.contains('in-stream-ad') ||
      lower.contains('-ad-') ||
      lower.endsWith('-ad');
}

List<String> _matchingTerms(String text, Iterable<String> terms) {
  return _matchesToSortedTerms(_matchTermsOnWordBoundaries(text, terms));
}

List<String> _matchesToSortedTerms(Iterable<_TermMatch> matches) {
  return matches.map((match) => match.term).toSet().toList()..sort();
}

class _TextSpan {
  const _TextSpan(this.start, this.end);

  final int start;
  final int end;

  bool contains(_TextSpan other) => start <= other.start && other.end <= end;
}

class _TermMatch {
  const _TermMatch({required this.term, required this.span});

  final String term;
  final _TextSpan span;
}

bool _isWordCharacter(String codeUnit) {
  final code = codeUnit.codeUnitAt(0);
  return (code >= 0x30 && code <= 0x39) ||
      (code >= 0x41 && code <= 0x5a) ||
      (code >= 0x61 && code <= 0x7a);
}

bool _isWordBoundaryStart(String text, int index) {
  if (index == 0) return true;
  return !_isWordCharacter(text[index - 1]);
}

bool _isWordBoundaryEnd(String text, int end) {
  if (end >= text.length) return true;
  return !_isWordCharacter(text[end]);
}

List<_TermMatch> _matchTermsOnWordBoundaries(
  String text,
  Iterable<String> terms, {
  Iterable<_TextSpan> excludedSpans = const [],
}) {
  final lower = text.toLowerCase();
  final excluded = excludedSpans.toList();
  final matches = <_TermMatch>[];
  for (final term in terms) {
    final needle = term.toLowerCase();
    if (needle.isEmpty) continue;
    var searchFrom = 0;
    while (searchFrom <= lower.length) {
      final index = lower.indexOf(needle, searchFrom);
      if (index < 0) break;
      final start = index;
      final end = index + needle.length;
      final boundaryOk = _isWordBoundaryStart(lower, start) &&
          _isWordBoundaryEnd(lower, end);
      final span = _TextSpan(start, end);
      if (boundaryOk &&
          !excluded.any((excludedSpan) => excludedSpan.contains(span))) {
        matches.add(_TermMatch(term: term, span: span));
      }
      searchFrom = end;
    }
  }
  return matches;
}

List<JsonMap> _workflowLifecycleRequirementGroupsForWorkflow(
  String workflowId,
) {
  final id = workflowId.toLowerCase();
  final groups = <JsonMap>[
    _semanticGroup('concrete object/context', _lifecycleContextTerms(id)),
    _semanticGroup('decision information', _lifecycleDecisionTerms(id)),
    _semanticGroup('primary semantic action', _lifecyclePrimaryActionTerms(id)),
    _semanticGroup(
      'alternate/change/reject affordance',
      _lifecycleAlternateActionTerms(id),
    ),
    _semanticGroup('persistent result state', _lifecycleResultTerms(id)),
    _semanticGroup(
      'receiver/continuation state',
      _lifecycleReceiverStateTerms(id),
    ),
  ];
  return groups;
}

List<String> _lifecycleContextTerms(String id) {
  if (id.contains('announcement') || id.contains('publish')) {
    return <String>['announcement', 'notice', 'update', 'message'];
  }
  if (id.contains('rsvp') ||
      id.contains('event') ||
      id.contains('practice') ||
      id.contains('photo-walk')) {
    return <String>['event', 'practice', 'photo walk', 'meeting', 'game'];
  }
  if (id.contains('payment') ||
      id.contains('dues') ||
      id.contains('donation') ||
      id.contains('checkout') ||
      id.contains('receipt') ||
      id.contains('ad-off')) {
    return <String>['donation', 'dues', 'payment', 'checkout', 'subscription'];
  }
  if (id.contains('document')) {
    return <String>['document', 'file', 'pdf', 'packet'];
  }
  if (id.contains('search') || id.contains('digest') || id.contains('answer')) {
    return <String>['query', 'answer', 'citation', 'source', 'digest'];
  }
  if (_isAdSurfaceWorkflow(id)) {
    return <String>['ad', 'banner', 'sponsor', 'slot', 'no-fill'];
  }
  if (id.contains('architectural') ||
      id.contains('approval') ||
      id.contains('request') ||
      id.contains('care')) {
    return <String>['request', 'case', 'application', 'care'];
  }
  if (id.contains('gear')) {
    return <String>['gear', 'camera', 'lens', 'loan', 'item'];
  }
  if (id.contains('plant-exchange')) {
    return <String>['plant', 'seedling', 'exchange', 'offer'];
  }
  if (id.contains('critique')) {
    return <String>['photo', 'image', 'critique', 'work'];
  }
  if (id.contains('match') || id.contains('chess')) {
    return <String>['match', 'game', 'round', 'chess'];
  }
  if (id.contains('message') ||
      id.contains('connection') ||
      id.contains('invite') ||
      id.contains('blocked')) {
    return <String>['message', 'thread', 'connection', 'invite'];
  }
  if (id.contains('export') ||
      id.contains('transfer') ||
      id.contains('import')) {
    return <String>['export', 'transfer', 'data', 'migration'];
  }
  return <String>['details', 'item', 'record', 'community'];
}

List<String> _lifecycleDecisionTerms(String id) {
  if (id.contains('announcement') || id.contains('publish')) {
    return <String>[
      'audience',
      'members',
      'body',
      'sender',
      'from',
      'delivery',
      'today',
      'preview',
    ];
  }
  if (id.contains('rsvp') ||
      id.contains('event') ||
      id.contains('practice') ||
      id.contains('photo-walk')) {
    return <String>[
      'date',
      'time',
      'location',
      'venue',
      'field',
      'capacity',
      'spots',
      'attending',
    ];
  }
  if (id.contains('payment') ||
      id.contains('dues') ||
      id.contains('donation') ||
      id.contains('checkout') ||
      id.contains('receipt') ||
      id.contains('ad-off')) {
    return <String>['amount', r'$', 'fund', 'total', 'receipt', 'visibility'];
  }
  if (id.contains('document')) {
    return <String>['title', 'file', 'updated', 'access', 'members', 'pdf'];
  }
  if (id.contains('search') || id.contains('digest') || id.contains('answer')) {
    return <String>['query', 'summary', 'citation', 'source', 'visible'];
  }
  if (_isAdSurfaceWorkflow(id)) {
    return <String>[
      'sponsor',
      'disclosure',
      'reason',
      'reserved',
      'no fill',
      'no-fill',
    ];
  }
  if (id.contains('architectural') ||
      id.contains('approval') ||
      id.contains('request')) {
    return <String>['details', 'status', 'review', 'decision', 'pending'];
  }
  if (id.contains('care')) {
    return <String>['need', 'private', 'protected', 'details', 'status'];
  }
  if (id.contains('gear')) {
    return <String>['available', 'borrower', 'due', 'pickup', 'return'];
  }
  if (id.contains('plant-exchange')) {
    return <String>['variety', 'pickup', 'time', 'contact', 'available'];
  }
  if (id.contains('critique')) {
    return <String>['title', 'reviewer', 'comment', 'submitted', 'image'];
  }
  if (id.contains('match') || id.contains('chess')) {
    return <String>['player', 'opponent', 'white', 'black', 'result'];
  }
  if (id.contains('message') ||
      id.contains('connection') ||
      id.contains('invite') ||
      id.contains('blocked')) {
    return <String>['from', 'to', 'recipient', 'message', 'note'];
  }
  if (id.contains('export') ||
      id.contains('transfer') ||
      id.contains('import')) {
    return <String>['scope', 'selected', 'preview', 'redaction', 'checksum'];
  }
  return <String>['status', 'details', 'review', 'selected'];
}

List<String> _lifecyclePrimaryActionTerms(String id) {
  if (id.contains('announcement') || id.contains('publish')) {
    return <String>['publish', 'send', 'post', 'schedule'];
  }
  if (id.contains('rsvp') || id.contains('event') || id.contains('practice')) {
    return <String>['rsvp', 'join', 'attend', 'reserve', 'confirm'];
  }
  if (id.contains('donation') ||
      id.contains('dues') ||
      id.contains('payment')) {
    return <String>['pay', 'donate', 'checkout', 'give'];
  }
  if (id.contains('document')) {
    return <String>['open', 'download', 'read', 'acknowledge'];
  }
  if (id.contains('search') || id.contains('digest') || id.contains('answer')) {
    return <String>['save', 'open sources', 'share', 'ask follow-up'];
  }
  if (_isAdSurfaceWorkflow(id)) {
    return <String>['review', 'open sponsor', 'inspect', 'reserve'];
  }
  if (id.contains('request') || id.contains('approval')) {
    return <String>['submit', 'approve', 'review', 'send'];
  }
  if (id.contains('gear') || id.contains('plant-exchange')) {
    return <String>['request', 'claim', 'offer', 'reserve', 'submit'];
  }
  if (id.contains('critique')) {
    return <String>['submit', 'review', 'comment'];
  }
  if (id.contains('blocked')) {
    return <String>['review', 'confirm', 'block', 'keep blocked'];
  }
  if (id.contains('match') || id.contains('chess')) {
    return <String>['record', 'submit', 'save'];
  }
  if (id.contains('message') ||
      id.contains('connection') ||
      id.contains('invite') ||
      id.contains('blocked')) {
    return <String>['send', 'reply', 'accept', 'invite'];
  }
  if (id.contains('export') ||
      id.contains('transfer') ||
      id.contains('import')) {
    return <String>['export', 'download', 'transfer', 'start'];
  }
  return <String>['submit', 'save', 'send', 'confirm'];
}

List<String> _lifecycleAlternateActionTerms(String id) {
  if (id.contains('announcement') || id.contains('publish')) {
    return <String>['edit', 'preview', 'schedule', 'draft', 'cancel'];
  }
  if (id.contains('rsvp') ||
      id.contains('event') ||
      id.contains('practice') ||
      id.contains('photo-walk')) {
    return <String>[
      'decline',
      'not attending',
      'maybe',
      'change response',
      'edit response',
      'cancel rsvp',
    ];
  }
  if (id.contains('payment') ||
      id.contains('dues') ||
      id.contains('donation') ||
      id.contains('checkout') ||
      id.contains('ad-off')) {
    return <String>['change', 'edit', 'cancel', 'refund', 'manage'];
  }
  if (id.contains('document')) {
    return <String>['share', 'save', 'download', 'close', 'back'];
  }
  if (id.contains('search') || id.contains('digest') || id.contains('answer')) {
    return <String>[
      'ask follow-up',
      'refine query',
      'change query',
      'open sources',
      'share answer',
    ];
  }
  if (_isAdSurfaceWorkflow(id)) {
    return <String>[
      'dismiss',
      'report',
      'manage',
      'refresh slot',
      'no-fill reason',
      'hide explanation',
    ];
  }
  if (id.contains('architectural') ||
      id.contains('approval') ||
      id.contains('request')) {
    return <String>['reject', 'revise', 'request changes', 'withdraw', 'edit'];
  }
  if (id.contains('care')) {
    return <String>['edit', 'withdraw', 'privacy', 'close', 'update'];
  }
  if (id.contains('gear')) {
    return <String>['deny', 'cancel', 'change', 'return', 'extend'];
  }
  if (id.contains('plant-exchange')) {
    return <String>['edit', 'cancel', 'mark claimed', 'unavailable'];
  }
  if (id.contains('critique')) {
    return <String>['edit', 'withdraw', 'resubmit', 'request changes'];
  }
  if (id.contains('blocked')) {
    return <String>['unblock', 'appeal', 'cancel invite', 'archive'];
  }
  if (id.contains('match') || id.contains('chess')) {
    return <String>['edit', 'undo', 'correct', 'dispute'];
  }
  if (id.contains('message') ||
      id.contains('connection') ||
      id.contains('invite') ||
      id.contains('blocked')) {
    return <String>['decline', 'block', 'mute', 'archive', 'cancel'];
  }
  if (id.contains('export') ||
      id.contains('transfer') ||
      id.contains('import')) {
    return <String>['cancel', 'rollback', 'retry', 'change scope'];
  }
  return <String>['cancel', 'edit', 'change', 'undo', 'reject'];
}

List<String> _lifecycleResultTerms(String id) {
  if (id.contains('announcement') || id.contains('publish')) {
    return <String>['sent', 'posted', 'published', 'delivered', 'received'];
  }
  if (id.contains('rsvp') || id.contains('event') || id.contains('practice')) {
    return <String>['confirmed', 'attending', 'reserved', 'not attending'];
  }
  if (id.contains('payment') ||
      id.contains('donation') ||
      id.contains('dues')) {
    return <String>['paid', 'receipt', 'confirmed', 'history', 'successful'];
  }
  if (id.contains('document')) {
    return <String>['read', 'downloaded', 'acknowledged', 'viewed'];
  }
  if (id.contains('search') || id.contains('digest') || id.contains('answer')) {
    return <String>['saved', 'shared', 'visible', 'citation', 'follow-up'];
  }
  if (_isAdSurfaceWorkflow(id)) {
    return <String>[
      'recorded',
      'no fill',
      'no-fill',
      'impression',
      'suppressed',
    ];
  }
  if (id.contains('request') || id.contains('approval')) {
    return <String>['approved', 'rejected', 'submitted', 'pending', 'status'];
  }
  if (id.contains('gear') || id.contains('plant-exchange')) {
    return <String>['requested', 'claimed', 'reserved', 'available', 'due'];
  }
  if (id.contains('critique')) {
    return <String>['submitted', 'reviewed', 'result', 'comment'];
  }
  if (id.contains('match') || id.contains('chess')) {
    return <String>['recorded', 'result', 'outcome', 'saved'];
  }
  if (id.contains('message') ||
      id.contains('connection') ||
      id.contains('invite') ||
      id.contains('blocked')) {
    return <String>['sent', 'received', 'accepted', 'blocked', 'connected'];
  }
  if (id.contains('export') ||
      id.contains('transfer') ||
      id.contains('import')) {
    return <String>['downloaded', 'complete', 'verified', 'status'];
  }
  return <String>['complete', 'confirmed', 'submitted', 'status'];
}

List<String> _lifecycleReceiverStateTerms(String id) {
  if (id.contains('announcement') || id.contains('publish')) {
    return <String>['inbox', 'notification', 'member', 'read', 'received'];
  }
  if (id.contains('rsvp') || id.contains('event') || id.contains('practice')) {
    return <String>['calendar', 'roster', 'attendee', 'member', 'waitlist'];
  }
  if (id.contains('payment') ||
      id.contains('donation') ||
      id.contains('dues')) {
    return <String>['receipt', 'history', 'donor', 'member', 'account'];
  }
  if (id.contains('document')) {
    return <String>['members', 'access', 'read-only', 'viewer', 'download'];
  }
  if (id.contains('search') || id.contains('digest') || id.contains('answer')) {
    return <String>['member', 'discussion', 'source', 'citation', 'share'];
  }
  if (_isAdSurfaceWorkflow(id)) {
    return <String>[
      'member',
      'layout',
      'slot',
      'audit',
      'disclosure',
      'suppression',
    ];
  }
  if (id.contains('request') || id.contains('approval')) {
    return <String>['notification', 'owner', 'reviewer', 'committee', 'status'];
  }
  if (id.contains('gear') || id.contains('plant-exchange')) {
    return <String>['owner', 'borrower', 'contact', 'pickup', 'handoff'];
  }
  if (id.contains('critique')) {
    return <String>['reviewer', 'comment', 'member', 'feedback'];
  }
  if (id.contains('match') || id.contains('chess')) {
    return <String>['opponent', 'standings', 'next', 'pairing'];
  }
  if (id.contains('message') ||
      id.contains('connection') ||
      id.contains('invite') ||
      id.contains('blocked')) {
    return <String>['recipient', 'thread', 'inbox', 'connection'];
  }
  if (id.contains('export') ||
      id.contains('transfer') ||
      id.contains('import')) {
    return <String>['provider', 'destination', 'rollback', 'audit'];
  }
  return <String>['receiver', 'history', 'next', 'status'];
}

bool _containsAnyTerm(String text, List<String> terms) {
  return terms.any((term) => text.contains(term.toLowerCase()));
}

JsonMap _semanticGroup(String label, List<String> terms) {
  return <String, Object?>{'label': label, 'terms': terms};
}

List<JsonMap> _semanticRequirementGroupsForWorkflow(String workflowId) {
  final id = workflowId.toLowerCase();
  if (id.contains('announcement') || id.contains('publish')) {
    return <JsonMap>[
      _semanticGroup('audience or recipient group', <String>[
        'audience',
        'members',
        'selected audience',
        'recipient',
      ]),
      _semanticGroup('author or sender attribution', <String>[
        'author',
        'sender',
        'from',
        'posted by',
        'sent by',
      ]),
      _semanticGroup('message body or announcement content', <String>[
        'message',
        'body',
        'announcement',
        'notice',
        'update',
      ]),
      _semanticGroup('timestamp or delivery timing', <String>[
        'timestamp',
        'time',
        'today',
        'date',
        'delivery',
      ]),
      _semanticGroup('receiver inbox/feed state', <String>[
        'receiver',
        'inbox',
        'notification',
        'read',
        'posted',
      ]),
      _semanticGroup('natural publish or send action', <String>[
        'publish',
        'send',
        'posted',
        'sent',
      ]),
    ];
  }
  if (id.contains('reminder') || id.contains('notification')) {
    return <JsonMap>[
      _semanticGroup('sender or recipient group', <String>[
        'sender',
        'from',
        'audience',
        'members',
        'recipient',
      ]),
      _semanticGroup('notification message body', <String>[
        'message',
        'body',
        'notice',
        'notification',
      ]),
      _semanticGroup('timestamp or delivery timing', <String>[
        'timestamp',
        'time',
        'today',
        'date',
        'delivery',
      ]),
      _semanticGroup('receiver inbox/feed state', <String>[
        'receiver',
        'inbox',
        'notification',
        'read',
        'received',
      ]),
    ];
  }
  if (id.contains('rsvp') ||
      id.contains('event') ||
      id.contains('practice') ||
      id.contains('photo-walk')) {
    return <JsonMap>[
      _semanticGroup('event title or purpose', <String>[
        'event',
        'practice',
        'photo walk',
        'meeting',
      ]),
      _semanticGroup('schedule or date/time', <String>[
        'schedule',
        'date',
        'time',
        'today',
        'tomorrow',
      ]),
      _semanticGroup('location or venue', <String>[
        'location',
        'venue',
        'field',
        'room',
        'park',
      ]),
      _semanticGroup('capacity or attendance status', <String>[
        'capacity',
        'spots',
        'attending',
        'rsvp',
        'confirmed',
      ]),
      _semanticGroup('RSVP action or result', <String>[
        'rsvp',
        'reserve',
        'join',
        'confirmed',
        'ticket',
      ]),
    ];
  }
  if (id.contains('minor-redaction') || id.contains('redaction')) {
    return <JsonMap>[
      _semanticGroup('protected youth or minor profile', <String>[
        'minor',
        'youth',
        'player',
        'profile',
      ]),
      _semanticGroup('redaction or privacy state', <String>[
        'redaction',
        'redacted',
        'protected',
        'privacy',
      ]),
      _semanticGroup('guardian or coach visibility', <String>[
        'guardian',
        'coach',
        'visibility',
        'coach-only',
      ]),
      _semanticGroup('roster or profile details', <String>[
        'roster',
        'profile',
        'details',
        'member',
      ]),
    ];
  }
  if (id.contains('payment') ||
      id.contains('dues') ||
      id.contains('donation') ||
      id.contains('checkout') ||
      id.contains('receipt') ||
      id.contains('ad-off')) {
    return <JsonMap>[
      _semanticGroup('amount or price', <String>[
        'amount',
        r'$',
        'total',
        'dues',
        'donation',
      ]),
      _semanticGroup('payer or donor context', <String>[
        'payer',
        'donor',
        'member',
        'account',
      ]),
      _semanticGroup('payment or donate action', <String>[
        'pay',
        'donate',
        'checkout',
        'subscribe',
      ]),
      _semanticGroup('receipt or confirmation', <String>[
        'receipt',
        'confirmation',
        'confirmed',
        'paid',
      ]),
      _semanticGroup('status or audit trail', <String>[
        'status',
        'audit',
        'settlement',
        'history',
      ]),
    ];
  }
  if (id.contains('message') ||
      id.contains('connection') ||
      id.contains('invite') ||
      id.contains('blocked')) {
    return <JsonMap>[
      _semanticGroup('conversation or connection subject', <String>[
        'message',
        'thread',
        'connection',
        'invite',
      ]),
      _semanticGroup('sender or recipient context', <String>[
        'from',
        'to',
        'sender',
        'recipient',
        'member',
      ]),
      _semanticGroup('message body or invitation content', <String>[
        'body',
        'message',
        'note',
        'invitation',
      ]),
      _semanticGroup('action or state', <String>[
        'send',
        'accept',
        'block',
        'sent',
        'received',
      ]),
    ];
  }
  if (id.contains('export') ||
      id.contains('import') ||
      id.contains('transfer') ||
      id.contains('rollback') ||
      id.contains('schema')) {
    return <JsonMap>[
      _semanticGroup('scope or selected data', <String>[
        'scope',
        'selected',
        'data',
        'schema',
      ]),
      _semanticGroup('preview or redaction', <String>[
        'preview',
        'redaction',
        'redacted',
        'protected',
      ]),
      _semanticGroup('checksum or verification', <String>[
        'checksum',
        'verify',
        'verified',
        'validation',
      ]),
      _semanticGroup('transfer/export action or status', <String>[
        'export',
        'transfer',
        'download',
        'status',
      ]),
    ];
  }
  if (id.contains('search') ||
      id.contains('digest') ||
      id.contains('citation')) {
    return <JsonMap>[
      _semanticGroup('query or search input', <String>[
        'query',
        'search',
        'question',
        'ask',
      ]),
      _semanticGroup('answer or result', <String>[
        'answer',
        'result',
        'found',
        'digest',
      ]),
      _semanticGroup('citation or source', <String>[
        'citation',
        'source',
        'reference',
        'cited',
      ]),
    ];
  }
  if (id.contains('volunteer') || id.contains('signup')) {
    return <JsonMap>[
      _semanticGroup('volunteer role or task', <String>[
        'volunteer',
        'role',
        'task',
        'serve',
      ]),
      _semanticGroup('time or shift', <String>[
        'time',
        'shift',
        'date',
        'slot',
      ]),
      _semanticGroup('contact or protected fields', <String>[
        'contact',
        'phone',
        'protected',
        'private',
      ]),
      _semanticGroup('signup confirmation', <String>[
        'sign up',
        'signup',
        'confirmed',
        'submitted',
      ]),
    ];
  }
  if (id.contains('plant-exchange')) {
    return <JsonMap>[
      _semanticGroup('plant details', <String>['plant', 'variety', 'seedling']),
      _semanticGroup('pickup timing', <String>['pickup', 'time', 'date']),
      _semanticGroup('owner contact', <String>['contact', 'owner', 'member']),
      _semanticGroup('offer/submitted state', <String>[
        'offer',
        'available',
        'submitted',
      ]),
    ];
  }
  if (id.contains('care')) {
    return <JsonMap>[
      _semanticGroup('care request details', <String>[
        'care',
        'request',
        'need',
        'details',
      ]),
      _semanticGroup('privacy/protection indicator', <String>[
        'private',
        'protected',
        'confidential',
      ]),
      _semanticGroup('response or status', <String>[
        'response',
        'status',
        'review',
        'submitted',
      ]),
    ];
  }
  if (id.contains('donor-visibility')) {
    return <JsonMap>[
      _semanticGroup('visibility choice', <String>[
        'visibility',
        'private',
        'public',
        'anonymous',
      ]),
      _semanticGroup('donation context', <String>['donation', 'donor', 'gift']),
      _semanticGroup('receipt visibility state', <String>[
        'receipt',
        'visible',
        'hidden',
        'confirmation',
      ]),
    ];
  }
  if (id.contains('in-stream-ad') ||
      id.contains('top-banner-no-fill') ||
      id.contains('sensitive-no-fill')) {
    return <JsonMap>[
      _semanticGroup('ad or sponsor context', <String>[
        'ad',
        'sponsored',
        'sponsor',
        'no sponsored',
      ]),
      _semanticGroup('disclosure or no-fill state', <String>[
        'disclosure',
        'sponsored',
        'no-fill',
        'no sponsored',
      ]),
    ];
  }
  if (id.contains('architectural') ||
      id.contains('committee') ||
      id.contains('approval') ||
      id.contains('request')) {
    return <JsonMap>[
      _semanticGroup('request details', <String>['request', 'details', 'case']),
      _semanticGroup('decision action', <String>[
        'approve',
        'reject',
        'decision',
      ]),
      _semanticGroup('status or notification', <String>[
        'status',
        'notification',
        'pending',
      ]),
    ];
  }
  if (id.contains('document')) {
    return <JsonMap>[
      _semanticGroup('document title', <String>['document', 'title', 'file']),
      _semanticGroup('audience or access state', <String>[
        'audience',
        'access',
        'members',
      ]),
      _semanticGroup('file metadata', <String>['file', 'pdf', 'updated']),
    ];
  }
  if (id.contains('facility') || id.contains('reservation')) {
    return <JsonMap>[
      _semanticGroup('facility details', <String>['facility', 'room', 'space']),
      _semanticGroup('availability', <String>[
        'availability',
        'available',
        'reserved',
      ]),
      _semanticGroup('reservation confirmation', <String>[
        'reservation',
        'confirmation',
        'confirmed',
      ]),
    ];
  }
  if (id.contains('roster') || id.contains('team')) {
    return <JsonMap>[
      _semanticGroup('team or roster context', <String>['team', 'roster']),
      _semanticGroup('member details', <String>[
        'member',
        'player',
        'guardian',
      ]),
      _semanticGroup('schedule or protected state', <String>[
        'schedule',
        'protected',
        'privacy',
      ]),
    ];
  }
  if (id.contains('nomination') || id.contains('vote') || id.contains('book')) {
    return <JsonMap>[
      _semanticGroup('book or nomination', <String>[
        'book',
        'nomination',
        'title',
      ]),
      _semanticGroup('vote or selected state', <String>[
        'vote',
        'selected',
        'winning',
      ]),
      _semanticGroup('meeting or discussion context', <String>[
        'meeting',
        'discussion',
        'club',
      ]),
    ];
  }
  if (id.contains('gear')) {
    return <JsonMap>[
      _semanticGroup('gear item', <String>['gear', 'item', 'lens', 'camera']),
      _semanticGroup('availability or borrower', <String>[
        'available',
        'borrower',
        'loan',
      ]),
      _semanticGroup('handoff or status', <String>['handoff', 'status', 'due']),
    ];
  }
  if (id.contains('critique')) {
    return <JsonMap>[
      _semanticGroup('work or image title', <String>[
        'image',
        'photo',
        'work',
        'title',
      ]),
      _semanticGroup('comments or reviewer state', <String>[
        'comment',
        'reviewer',
        'critique',
      ]),
      _semanticGroup('result', <String>['result', 'submitted', 'reviewed']),
    ];
  }
  if (id.contains('match') || id.contains('chess')) {
    return <JsonMap>[
      _semanticGroup('match context', <String>['match', 'game', 'round']),
      _semanticGroup('players', <String>[
        'player',
        'opponent',
        'white',
        'black',
      ]),
      _semanticGroup('outcome or next action', <String>[
        'result',
        'outcome',
        'record',
        'next',
      ]),
    ];
  }
  return <JsonMap>[];
}

List<JsonMap> _holisticAnswers(
  JsonMap review,
  List<JsonMap> workflowScorecards,
  List<JsonMap> lifecycleScorecards,
  List<JsonMap> screenRows,
) {
  final coverageSummary =
      (review['workflowRoleCoverageSummary'] as JsonMap?) ??
      <String, Object?>{};
  final failingCoverage = _asInt(coverageSummary['failingCoverageRowCount']);
  final failingWorkflowScorecards = workflowScorecards
      .where((scorecard) => scorecard['blocksPass'] == true)
      .length;
  final failingLifecycleScorecards = lifecycleScorecards
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
          failingLifecycleScorecards == 0 &&
          visualFailureRows == 0,
      score:
          failingCoverage == 0 &&
              failingWorkflowScorecards == 0 &&
              failingLifecycleScorecards == 0 &&
              visualFailureRows == 0
          ? 85
          : 35,
      evidenceUsed: <String>[
        'screenRows=$rowCount',
        'workflowRoleCoverageFailures=$failingCoverage',
        'workflowRoleScorecardFailures=$failingWorkflowScorecards',
        'workflowLifecycleScorecardFailures=$failingLifecycleScorecards',
        'visualInspectionFailures=$visualFailureRows',
      ],
      why:
          failingCoverage == 0 &&
              failingWorkflowScorecards == 0 &&
              failingLifecycleScorecards == 0 &&
              visualFailureRows == 0
          ? 'Coverage, workflow/role scorecards, lifecycle scorecards, and screenshot pixel/layout inspection provide no production-grade blockers.'
          : 'The review cannot claim production-grade UX while workflow/role lifecycle evidence, direct-question evidence, or screenshot visual inspection is incomplete/failing.',
      requiredFix:
          failingCoverage == 0 &&
              failingWorkflowScorecards == 0 &&
              failingLifecycleScorecards == 0 &&
              visualFailureRows == 0
          ? 'None.'
          : 'Complete workflow/role coverage, lifecycle scorecards, and remediate visual/layout failures before claiming production-grade UX.',
    ),
    _directAnswer(
      questionId: 'b25-holistic-modern-intentional',
      scope: 'holistic',
      question:
          'Is the UI modern, easy to use, easy to navigate, and visually appealing for the target role?',
      pass:
          visibleTextUnsupported == 0 &&
          failingWorkflowScorecards == 0 &&
          failingLifecycleScorecards == 0 &&
          visualFailureRows == 0,
      score:
          visibleTextUnsupported == 0 &&
              failingWorkflowScorecards == 0 &&
              failingLifecycleScorecards == 0 &&
              visualFailureRows == 0
          ? 85
          : 40,
      evidenceUsed: <String>[
        'screenRows=$rowCount',
        'unsupportedVisibleTextRows=$visibleTextUnsupported',
        'workflowLifecycleScorecardFailures=$failingLifecycleScorecards',
        'visualInspectionFailures=$visualFailureRows',
      ],
      why:
          visibleTextUnsupported == 0 &&
              failingLifecycleScorecards == 0 &&
              visualFailureRows == 0
          ? 'Visible UI/text evidence, lifecycle scorecards, and screenshot pixel/layout inspection support judging modern UI quality.'
          : '$visibleTextUnsupported rows use non-screen visible text sources, $failingLifecycleScorecards lifecycle scorecards fail, and $visualFailureRows rows have visual/layout blockers, so the judge cannot make a reliable modern-UI claim.',
      requiredFix:
          visibleTextUnsupported == 0 &&
              failingLifecycleScorecards == 0 &&
              visualFailureRows == 0
          ? 'None.'
          : 'Use screenshot-derived visible text, fix incomplete workflow lifecycles, and fix detected checklist, repeated-card, thin-content, or weak-identity visual blockers before rerunning the judge.',
    ),
    _directAnswer(
      questionId: 'b25-holistic-community-ia',
      scope: 'holistic',
      question:
          'Is the overall information architecture organized around community content and real jobs-to-be-done instead of workflow lists or validation surfaces?',
      pass:
          failingWorkflowScorecards == 0 &&
          failingLifecycleScorecards == 0 &&
          visualFailureRows == 0,
      score:
          failingWorkflowScorecards == 0 &&
              failingLifecycleScorecards == 0 &&
              visualFailureRows == 0
          ? 85
          : 45,
      evidenceUsed: <String>[
        'workflowRoleScorecardFailures=$failingWorkflowScorecards',
        'workflowLifecycleScorecardFailures=$failingLifecycleScorecards',
        'visualInspectionFailures=$visualFailureRows',
      ],
      why:
          failingWorkflowScorecards == 0 &&
              failingLifecycleScorecards == 0 &&
              visualFailureRows == 0
          ? 'Workflow/role scorecards, lifecycle scorecards, and visual inspection do not report generic workflow-list IA failures.'
          : 'Failing workflow/role lifecycle scorecards or visual blockers prevent a holistic community IA pass.',
      requiredFix:
          failingWorkflowScorecards == 0 &&
              failingLifecycleScorecards == 0 &&
              visualFailureRows == 0
          ? 'None.'
          : 'Replace incomplete workflow-card UX with lifecycle-complete domain-native community sections and rerun scorecards.',
    ),
    _directAnswer(
      questionId: 'b25-holistic-layout-defects',
      scope: 'holistic',
      question:
          'Does the visible UI avoid blocking or major overlap, clipping, crowding, default-scaffold, repeated-card, checklist-modal, and thin-content defects?',
      pass:
          failingWorkflowScorecards == 0 &&
          failingLifecycleScorecards == 0 &&
          visibleTextUnsupported == 0 &&
          visualFailureRows == 0,
      score:
          failingWorkflowScorecards == 0 &&
              failingLifecycleScorecards == 0 &&
              visibleTextUnsupported == 0 &&
              visualFailureRows == 0
          ? 85
          : 45,
      evidenceUsed: <String>[
        'workflowRoleScorecardFailures=$failingWorkflowScorecards',
        'workflowLifecycleScorecardFailures=$failingLifecycleScorecards',
        'unsupportedVisibleTextRows=$visibleTextUnsupported',
        'visualInspectionFailures=$visualFailureRows',
      ],
      why:
          failingWorkflowScorecards == 0 &&
              failingLifecycleScorecards == 0 &&
              visibleTextUnsupported == 0 &&
              visualFailureRows == 0
          ? 'No major layout/content defects were detected by screenshot pixel/layout inspection or row-level critique.'
          : 'The judge cannot clear layout/content defects while row-level evidence remains incomplete, unsupported, or visually failing.',
      requiredFix:
          failingWorkflowScorecards == 0 &&
              failingLifecycleScorecards == 0 &&
              visibleTextUnsupported == 0 &&
              visualFailureRows == 0
          ? 'None.'
          : 'Complete screenshot-backed review rows, fix incomplete workflow lifecycles, and remediate any row-level layout/content defects.',
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
  List<JsonMap> lifecycleScorecards,
  List<JsonMap> holisticAnswers,
) {
  final findings = _replaceGeneratedFindings(
    _asMapList(review['findings']),
    generatedBy: 'b25-independent-ux-judge',
  );
  final coverageSummary =
      (review['workflowRoleCoverageSummary'] as JsonMap?) ??
      <String, Object?>{};
  final failingCoverage = _asInt(coverageSummary['failingCoverageRowCount']);
  final productDocCoverage = _asMapList(review['productDocCoverage']);
  final failingProductDocs = productDocCoverage
      .where((row) => _asString(row['status']) != 'pass')
      .toList();
  if (productDocCoverage.isEmpty || failingProductDocs.isNotEmpty) {
    findings.add(<String, Object?>{
      'findingId': 'B25-COMMUNITY-PRODUCT-DOCS-INCOMPLETE',
      'severity': 'major',
      'status': 'open',
      'title': 'Community product experience docs are incomplete',
      'summary': productDocCoverage.isEmpty
          ? 'No community-specific Product Docs V2 experience specs were supplied for the reviewed screen rows.'
          : '${failingProductDocs.length} community-specific Product Docs V2 experience specs are missing, thin, or not review-ready.',
      'requiredFix':
          'Create or update each affected community product experience doc before UI remediation continues, then rerun B25 so screenshots are judged against those specs.',
      'blocksPass': true,
      'generatedBy': 'b25-independent-ux-judge',
      'affectedProductDocIds': failingProductDocs
          .map((row) => _asString(row['productDocId']))
          .where((id) => id.isNotEmpty)
          .toList(),
    });
  }
  if (failingCoverage > 0) {
    findings.add(<String, Object?>{
      'findingId': 'B25-WORKFLOW-ROLE-COVERAGE-INCOMPLETE',
      'severity': 'major',
      'status': 'open',
      'title': 'Workflow/role coverage is incomplete',
      'summary':
          '$failingCoverage workflow/role rows lack specific role or full entry/action/result evidence.',
      'requiredFix':
          'Capture full workflow/role evidence before rerunning the independent UX judge.',
      'blocksPass': true,
      'generatedBy': 'b25-independent-ux-judge',
      'affectedCoverageRowIds': _asMapList(review['workflowRoleCoverage'])
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
      'findingId': 'B25-WORKFLOW-ROLE-UX-FAILED',
      'severity': 'major',
      'status': 'open',
      'title': 'Workflow/role UX scorecards failed',
      'summary':
          '${failingScorecards.length} workflow/role scorecards failed direct-question review.',
      'requiredFix':
          'Use the failed scorecards to remediate exact workflow/role screens and recapture evidence.',
      'blocksPass': true,
      'generatedBy': 'b25-independent-ux-judge',
      'affectedScorecardIds': failingScorecards.take(50).toList(),
    });
  }
  final failingLifecycleScorecards = lifecycleScorecards
      .where((scorecard) => scorecard['blocksPass'] == true)
      .map((scorecard) => _asString(scorecard['scorecardId']))
      .toList();
  if (failingLifecycleScorecards.isNotEmpty) {
    findings.add(<String, Object?>{
      'findingId': 'B25-WORKFLOW-LIFECYCLE-INCOMPLETE',
      'severity': 'major',
      'status': 'open',
      'title': 'Workflow lifecycle UX is incomplete',
      'summary':
          '${failingLifecycleScorecards.length} workflow/role lifecycle scorecards failed. The UI is still proving action-card completion rather than full production workflow lifecycles.',
      'requiredFix':
          'Use the failed lifecycle scorecards to add concrete objects, decision information, semantic primary and alternate actions, persistent result state, and receiver/continuation state before recapturing evidence.',
      'blocksPass': true,
      'generatedBy': 'b25-independent-ux-judge',
      'affectedLifecycleScorecardIds': failingLifecycleScorecards
          .take(80)
          .toList(),
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

List<JsonMap> _workflowLifecycleFindings(
  JsonMap review,
  List<JsonMap> lifecycleScorecards,
) {
  final findings = _replaceGeneratedFindings(
    _asMapList(review['findings']),
    generatedBy: 'b25-workflow-lifecycle-judge',
  );
  final failingLifecycleScorecards = lifecycleScorecards
      .where((scorecard) => scorecard['blocksPass'] == true)
      .map((scorecard) => _asString(scorecard['scorecardId']))
      .where((id) => id.isNotEmpty)
      .toList();
  if (lifecycleScorecards.isEmpty || failingLifecycleScorecards.isNotEmpty) {
    findings.add(<String, Object?>{
      'findingId': 'B25-WORKFLOW-LIFECYCLE-INCOMPLETE',
      'severity': 'major',
      'status': 'open',
      'title': 'Workflow lifecycle UX is incomplete',
      'summary': lifecycleScorecards.isEmpty
          ? 'No workflow lifecycle scorecards were generated; B25 cannot prove production workflow UX.'
          : '${failingLifecycleScorecards.length} workflow/role lifecycle scorecards failed. The UI is still proving action-card completion rather than full production workflow lifecycles.',
      'requiredFix':
          'Use the failed lifecycle scorecards to add concrete objects, decision information, semantic primary and alternate actions, persistent result state, and receiver/continuation state before recapturing evidence.',
      'blocksPass': true,
      'generatedBy': 'b25-workflow-lifecycle-judge',
      'affectedLifecycleScorecardIds': failingLifecycleScorecards
          .take(80)
          .toList(),
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
    'B25-WORKFLOW-ROLE-UNPROVEN',
    'B25-WORKFLOW-ROLE-COVERAGE-INCOMPLETE',
    'B25-SCREEN-SPECIFIC-CRITIQUE-INCOMPLETE',
    'B25-VISUAL-UX-INSPECTION-FAILED',
    'B25-WORKFLOW-ROLE-UX-FAILED',
    'B25-WORKFLOW-LIFECYCLE-INCOMPLETE',
    'B25-HOLISTIC-UX-FAILED',
    'B25-ROLE-SCOPE-MISSING',
    'B25-COMMUNITY-PRODUCT-DOCS-INCOMPLETE',
    'B25-FULL-COVERAGE-INCOMPLETE',
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

String _coverageKey(String communityId, String workflowId, String fanId) {
  return '$communityId::$workflowId::$fanId';
}

JsonMap _remediationBatch({
  required String batchId,
  required String title,
  required String purpose,
  required List<JsonMap> tickets,
  required List<String> actions,
  bool includeProductDocWorkItems = true,
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
  final productDocIds = <String>{
    for (final ticket in tickets)
      ..._asStringList(ticket['affectedProductDocIds']),
  }.toList();
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
  final productDocsById = <String, JsonMap>{
    for (final ticket in tickets)
      for (final row in _asMapList(ticket['affectedProductDocs']))
        _asString(row['productDocId']): JsonMap.of(row),
  }..remove('');
  final scorecardsById = <String, JsonMap>{
    for (final ticket in tickets)
      for (final row in _asMapList(ticket['failingWorkflowRoleScorecards']))
        _asString(row['scorecardId']): JsonMap.of(row),
  }..remove('');
  final lifecycleScorecardsById = <String, JsonMap>{
    for (final ticket in tickets)
      for (final row in _asMapList(
        ticket['failingWorkflowLifecycleScorecards'],
      ))
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
  final productDocRepairWorkItems = includeProductDocWorkItems
      ? _dedupeWorkItems(<JsonMap>[
          for (final ticket in tickets)
            ..._asMapList(ticket['productDocRepairWorkItems']).map(JsonMap.of),
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
    'affectedProductDocIds': productDocIds,
    'affectedScreenRows': screenRowsById.values.toList(),
    'affectedCoverageRows': coverageRowsById.values.toList(),
    'affectedProductDocs': productDocsById.values.toList(),
    'failingWorkflowRoleScorecards': scorecardsById.values.toList(),
    'failingWorkflowLifecycleScorecards': lifecycleScorecardsById.values
        .toList(),
    'evidenceRepairWorkItems': evidenceRepairWorkItems,
    'productDocRepairWorkItems': productDocRepairWorkItems,
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
  final productDocItems = <String>{};
  final evidenceItems = <String>{};
  final uiItems = <String>{};
  final communities = <String>{};
  final workflows = <String>{};
  final roles = <String>{};
  for (final batch in batches) {
    for (final item in _asMapList(batch['productDocRepairWorkItems'])) {
      productDocItems.add(_asString(item['workItemId']));
      communities.add(_asString(item['communityName']));
    }
    for (final item in _asMapList(batch['evidenceRepairWorkItems'])) {
      evidenceItems.add(_asString(item['workItemId']));
      communities.add(_asString(item['communityName']));
      workflows.add(_asString(item['workflowId']));
      roles.add(_asString(item['role']));
    }
    for (final item in _asMapList(batch['uiRemediationWorkItems'])) {
      uiItems.add(_asString(item['workItemId']));
      communities.add(_asString(item['communityName']));
      workflows.add(_asString(item['workflowId']));
      roles.add(_asString(item['role']));
    }
  }
  productDocItems.remove('');
  evidenceItems.remove('');
  uiItems.remove('');
  communities.remove('');
  workflows.remove('');
  roles.remove('');
  return <String, Object?>{
    'productDocRepairWorkItemCount': productDocItems.length,
    'evidenceRepairWorkItemCount': evidenceItems.length,
    'uiRemediationWorkItemCount': uiItems.length,
    'communityCount': communities.length,
    'workflowCount': workflows.length,
    'roleCount': roles.length,
    'sequencing':
        'Product-spec work items must close first, then evidence repair work items, then matching UI remediation work items.',
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
    case 'b25-c02-community-product-docs-complete':
      return _failOnProductDocCoverage(evidence);
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
          _failOnWorkflowRoleScorecards(evidence);
    case 'b25-c13-workflow-lifecycle-complete':
      return _failOnWorkflowLifecycleScorecards(evidence);
    case 'b25-c14-llm-vision-ux-review':
      return _failOnLlmVisionReview(evidence);
    case 'b25-c03-production-grade-experience':
    case 'b25-c04-modern-intentional-ui':
    case 'b25-c05-community-content-ia':
    case 'b25-c09-no-layout-production-defects':
      return _failOnVisualInspection(screenRows) ??
          _failOnDirectQuestionAnswers(
            _asMapList(evidence['holisticQuestionAnswers']),
            requiredScope: 'holistic',
          );
    case 'b23-c01-role-state-coverage':
    case 'b23-c02-unauthorized-behavior':
      final rows = _asMapList(evidence['roleRows']);
      if (rows.isEmpty || rows.any((row) => row['verdict'] == 'fail')) {
        return _DerivedFailure(
          score: 50,
          message: 'Role rows are empty or include failed role-state evidence.',
        );
      }
      break;
    case 'b24-c01-screenshot-integrity':
    case 'b25-c07-screenshot-freshness':
      return _failOnScreenshotIntegrity(screenRows, basePath);
    case 'b25-c15-full-b25-capture-coverage':
      return _failOnFullB25CaptureCoverage(evidence);
    case 'b25-c16-app-shell-capability-utilization':
      return _failOnAppShellCapabilityReview(evidence);
    case 'b25-c17-component-doc-freshness':
      return _failOnComponentDocFreshnessReview(evidence, basePath);
    case 'b24-c02-visible-text-and-copy-audit':
    case 'b25-c08-visible-text-specific-critique':
      return _failOnVisibleTextOrBoilerplate(screenRows) ??
          _failOnVisualInspection(screenRows) ??
          _failOnWorkflowRoleScorecards(evidence);
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

_DerivedFailure? _failOnFullB25CaptureCoverage(JsonMap evidence) {
  final reviewInput = evidence['reviewInputEvidence'] as JsonMap?;
  if (reviewInput == null) {
    return _DerivedFailure(
      score: 0,
      message:
          'reviewInputEvidence is missing; B25 cannot prove full B12-B20 screenshot coverage.',
    );
  }
  final coverage = reviewInput['captureCoverage'] as JsonMap?;
  final capturedPhases = _asStringList(reviewInput['capturedPhases']);
  final missingPhases = _asStringList(reviewInput['missingPhases']);
  final workflowManifestCount = _asInt(reviewInput['workflowManifestCount']);
  final screenshotCount = _asInt(reviewInput['screenshotCount']);
  final issues = <String>[
    if (coverage != null) ..._asStringList(coverage['issues']),
  ];
  if (coverage == null) {
    issues.add(
      'reviewInputEvidence.captureCoverage is missing. Run b25_capture_coverage_gate.dart and regenerate B25 evidence.',
    );
  }
  if (_asString(reviewInput['captureMode']) != 'full-b25') {
    issues.add(
      'reviewInputEvidence.captureMode must be full-b25; found "${_asString(reviewInput['captureMode'])}".',
    );
  }
  if (reviewInput['commitEligible'] != true) {
    issues.add('reviewInputEvidence.commitEligible must be true.');
  }
  if (reviewInput['fullB25Coverage'] != true) {
    issues.add('reviewInputEvidence.fullB25Coverage must be true.');
  }
  if (!_sameStringList(capturedPhases, fullB25EvidencePhases)) {
    issues.add(
      'Captured phases must be exactly ${fullB25EvidencePhases.join(',')}; found ${capturedPhases.join(',')}.',
    );
  }
  if (missingPhases.isNotEmpty) {
    issues.add('Missing phases: ${missingPhases.join(',')}.');
  }
  if (workflowManifestCount < fullB25MinimumWorkflowManifests) {
    issues.add(
      'workflowManifestCount=$workflowManifestCount; expected at least $fullB25MinimumWorkflowManifests.',
    );
  }
  if (screenshotCount < fullB25MinimumScreenshotRows) {
    issues.add(
      'screenshotCount=$screenshotCount; expected at least $fullB25MinimumScreenshotRows.',
    );
  }
  if (issues.isNotEmpty) {
    return _DerivedFailure(
      score: 0,
      message:
          'B25 evidence is not based on commit-eligible full B12-B20 capture: ${issues.join(' ')}',
      evidenceUsed: <String>[
        'captureMode=${_asString(reviewInput['captureMode'])}',
        'commitEligible=${reviewInput['commitEligible']}',
        'fullB25Coverage=${reviewInput['fullB25Coverage']}',
        'capturedPhases=${capturedPhases.join(',')}',
        'missingPhases=${missingPhases.join(',')}',
        'workflowManifestCount=$workflowManifestCount',
        'screenshotCount=$screenshotCount',
      ],
    );
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

  // Disk manifests are the source of truth for what has actually been captured.
  // Each phase writes its own `*/workflow-ui-evidence.json`, so evidence must
  // accumulate across partial runs instead of being defined by whichever
  // aggregate a later `flutter drive` invocation happened to overwrite.
  final pathSet = <String>{};
  if (evidenceRoot.existsSync()) {
    for (final entity in evidenceRoot.listSync(recursive: true)) {
      if (entity is File &&
          entity.uri.pathSegments.last == 'workflow-ui-evidence.json') {
        pathSet.add(entity.absolute.path);
      }
    }
  }

  // Union the on-disk manifests with a canonical aggregate's manifest list so
  // an authoritative full sweep never loses a phase that was banked earlier.
  if (aggregate.existsSync()) {
    final manifest = _readJsonFile(aggregate.path);
    for (final path in _asStringList(
      manifest['workflowEvidenceManifestPaths'],
    )) {
      pathSet.add(_hostPath(path));
    }
  }

  // Carry forward any manifest paths recorded by a prior review that are still
  // present on disk but were not rediscovered above.
  for (final path in _asStringList(
    (priorReview?['reviewInputEvidence']
        as JsonMap?)?['workflowEvidenceManifestPaths'],
  )) {
    pathSet.add(_hostPath(path));
  }

  final paths = pathSet
      .where((path) => File(path).existsSync())
      .toList(growable: false)
    ..sort();
  return paths;
}

JsonMap _b25EvidenceCoverageForManifests({
  required Directory evidenceRoot,
  required List<String> manifests,
}) {
  final phaseByManifest = <String, Set<String>>{
    for (final phase in fullB25EvidencePhases) phase: <String>{},
  };
  final perPhase = <String, JsonMap>{};
  var totalWorkflows = 0;
  var totalScreenshots = 0;
  for (final manifestPath in manifests) {
    final manifest = _readJsonFile(manifestPath);
    final phase = _asString(manifest['phase']);
    if (phase.isEmpty) {
      continue;
    }
    final workflows = _asMapList(manifest['workflows']);
    var screenshots = 0;
    for (final workflow in workflows) {
      screenshots += _asStringList(workflow['screenshotPaths']).length;
    }
    totalWorkflows += workflows.length;
    totalScreenshots += screenshots;
    phaseByManifest[phase]?.add(manifestPath);
    final previous = perPhase[phase] ?? <String, Object?>{
      'workflowCount': 0,
      'screenshotCount': 0,
      'manifestCount': 0,
    };
    perPhase[phase] = <String, Object?>{
      'workflowCount': _asInt(previous['workflowCount']) + workflows.length,
      'screenshotCount': _asInt(previous['screenshotCount']) + screenshots,
      'manifestCount': _asInt(previous['manifestCount']) + 1,
    };
  }
  final capturedPhases = phaseByManifest.entries
      .where((entry) => entry.value.isNotEmpty)
      .map((entry) => entry.key)
      .toList(growable: false);
  final neverRunPhases = fullB25EvidencePhases
      .where((phase) => phaseByManifest[phase]!.isEmpty)
      .toList(growable: false);
  return <String, Object?>{
    'evidenceRoot': evidenceRoot.path,
    'capturedPhases': capturedPhases,
    'neverRunPhases': neverRunPhases,
    'workflowCount': totalWorkflows,
    'screenshotCount': totalScreenshots,
    'manifestCount': manifests.length,
    'perPhase': <String, JsonMap>{
      for (final phase in fullB25EvidencePhases)
        phase: perPhase[phase] ?? <String, Object?>{
          'workflowCount': 0,
          'screenshotCount': 0,
          'manifestCount': 0,
        },
    },
  };
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

String _canonicalDirectoryPath(String path) {
  final directory = Directory(_hostPath(path));
  try {
    return directory.resolveSymbolicLinksSync();
  } catch (_) {
    return directory.absolute.path;
  }
}

String _gitLastCommitShaForPath(String repoRootPath, String repoRelativePath) {
  final result = Process.runSync('git', <String>[
    '-C',
    _hostPath(repoRootPath),
    'log',
    '-1',
    '--format=%H',
    '--',
    repoRelativePath,
  ], runInShell: true);
  if (result.exitCode == 0) {
    return result.stdout.toString().trim();
  }
  return 'unknown';
}

String _gitStatusForPath(String repoRootPath, String repoRelativePath) {
  final result = Process.runSync('git', <String>[
    '-C',
    _hostPath(repoRootPath),
    'status',
    '--short',
    '--',
    repoRelativePath,
  ], runInShell: true);
  if (result.exitCode != 0) {
    return 'unknown';
  }
  final status = result.stdout.toString().trim();
  return status.isEmpty ? 'clean' : status;
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

JsonMap _componentDocMetadata(String repoRootPath, String path) {
  final normalizedPath = _normalizeComponentDocPath(repoRootPath, path);
  final resolved = _resolveRepoPath(repoRootPath, normalizedPath);
  final file = File(_hostPath(resolved));
  final exists = file.existsSync();
  return <String, Object?>{
    'path': normalizedPath,
    'exists': exists,
    'sha256': exists ? _fileSha256(file.path) : '',
    'gitLastCommitSha': _gitLastCommitShaForPath(repoRootPath, normalizedPath),
    'gitStatus': _gitStatusForPath(repoRootPath, normalizedPath),
    'reviewedThisRunRequired': true,
    'semanticReviewRequired': true,
  };
}

String _resolveRepoPath(String repoRootPath, String path) {
  final direct = File(_hostPath(path));
  if (direct.existsSync()) {
    return direct.path;
  }
  return '${_hostPath(repoRootPath)}/$path';
}

String _normalizeComponentDocPath(String repoRootPath, String path) {
  var normalized = path.trim().replaceAll(r'\', '/');
  while (normalized.startsWith('./')) {
    normalized = normalized.substring(2);
  }
  if (normalized.startsWith(
    '.agents/skills/using-loom-to-build-an-extension/',
  )) {
    normalized = normalized.replaceFirst(
      '.agents/skills/using-loom-to-build-an-extension/',
      'docs/Build Plan V2/Skill/',
    );
  }
  if (normalized.startsWith('components/card-surfaces/')) {
    normalized = 'docs/Build Plan V2/Skill/$normalized';
  }
  final hostPath = _hostPath(normalized);
  if (RegExp(r'^/|^[A-Za-z]:[\\/]').hasMatch(hostPath)) {
    normalized = _relativePath(hostPath, repoRootPath);
  }
  return normalized.replaceAll(r'\', '/');
}

bool _shaMatches(String reviewed, String current) {
  if (reviewed.isEmpty || current.isEmpty) {
    return false;
  }
  return reviewed == current ||
      reviewed.startsWith(current) ||
      current.startsWith(reviewed);
}

String _roleFromScreenshotName(String name) {
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
  return 'role-under-review';
}

bool _isNonProductionEvidenceWorkflow(String workflowId) {
  final slug = _slug(workflowId);
  return slug == 'workflow-ui-evidence-harness' || slug == 'b12-harness';
}

String _roleForEvidence({
  required String workflowId,
  required String communityId,
  required String screenshotName,
}) {
  final fromScreenshot = _roleFromScreenshotName(screenshotName);
  if (_isSpecificRole(fromScreenshot, _fanIdFromRoleLabel(fromScreenshot))) {
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

String _fanIdForEvidence({required String role, required String communityId}) {
  final roleSlug = _fanIdFromRoleLabel(role);
  if (roleSlug.isEmpty) {
    return '';
  }
  final communitySlug = _slug(communityId);
  if (communitySlug.isEmpty) {
    return roleSlug;
  }
  return '$communitySlug-$roleSlug';
}

String _fanIdFromRoleLabel(String role) {
  final slug = _slug(role);
  if (slug.isEmpty ||
      slug == 'unknown' ||
      slug == 'role-under-review' ||
      slug == 'role' ||
      slug == 'user') {
    return '';
  }
  return slug;
}

bool _isSpecificRole(String role, String fanId) {
  if (fanId.isEmpty) {
    return false;
  }
  final slug = _slug(role);
  return slug.isNotEmpty &&
      slug != 'unknown' &&
      slug != 'role-under-review' &&
      slug != 'role' &&
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
  return id.contains('actor-identity-inventory') ||
      id.contains('app-shell-capability-evidence');
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
    return 'role-picker';
  }
  return 'screen-state';
}

String _slug(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

List<JsonMap> _productDocCoverageForB25({
  required List<JsonMap> screenRows,
  required String repoRootPath,
}) {
  final byCommunity = <String, JsonMap>{};
  for (final row in screenRows) {
    final communityName = _asString(
      row['communityName'],
      fallback: _asString(row['communityId'], fallback: 'unknown-community'),
    );
    final key = _slug(communityName);
    if (key.isEmpty) {
      continue;
    }
    byCommunity.putIfAbsent(
      key,
      () => <String, Object?>{
        'communityId': _asString(row['communityId']),
        'communityName': communityName,
        'screenRowIds': <String>[],
        'workflowIds': <String>[],
        'roles': <String>[],
      },
    );
    (byCommunity[key]!['screenRowIds'] as List<String>).add(_rowId(row));
    final workflowIds = byCommunity[key]!['workflowIds'] as List<String>;
    final workflowId = _asString(row['workflowId']);
    if (workflowId.isNotEmpty && !workflowIds.contains(workflowId)) {
      workflowIds.add(workflowId);
    }
    final roles = byCommunity[key]!['roles'] as List<String>;
    final role = _asString(row['role']);
    if (role.isNotEmpty && !roles.contains(role)) {
      roles.add(role);
    }
  }

  final docRoot = '$repoRootPath/docs/Product Docs V2/Community Examples'
      .replaceAll(r'\', '/');
  final rows = <JsonMap>[];
  final requiredSections = _requiredB25ProductDocSections();
  for (final community in byCommunity.values) {
    final communityName = _asString(community['communityName']);
    final docSlug = _communityProductDocSlug(communityName);
    final fileName = '$docSlug-product-experience.md';
    final file = File('$docRoot/$fileName');
    final exists = file.existsSync();
    final content = exists ? file.readAsStringSync() : '';
    final missingSections = exists
        ? requiredSections
              .where((section) => !content.contains(section))
              .toList()
        : requiredSections;
    final wordCount = content
        .split(RegExp(r'\s+'))
        .where((token) => token.trim().isNotEmpty)
        .length;
    final containsPlaceholders = RegExp(r'<[^>]+>').hasMatch(content);
    final mentionsCommunity = communityName.isEmpty
        ? true
        : content.toLowerCase().contains(communityName.toLowerCase());
    final hasWorkflowMapping =
        content.contains('## 6. Workflow-To-Surface Mapping') &&
        content.contains('| Workflow |');
    final hasDomainSurfaceSpec =
        content.contains('## 5. Domain-Native Product Surfaces') &&
        content.contains('| Surface |');
    final hasReviewLog =
        content.contains('## 10. Review And Remediation Log') &&
        content.toLowerCase().contains('b25');
    final failures = <String>[
      if (!exists) 'missing-doc',
      if (missingSections.isNotEmpty)
        'missing-sections: ${missingSections.join(', ')}',
      if (containsPlaceholders) 'placeholder-text-present',
      if (wordCount < 250) 'doc-too-thin: $wordCount words',
      if (!mentionsCommunity) 'community-name-not-mentioned',
      if (!hasWorkflowMapping) 'workflow-to-surface-map-missing',
      if (!hasDomainSurfaceSpec) 'domain-native-surface-spec-missing',
      if (!hasReviewLog) 'b25-review-remediation-log-missing',
    ];
    final status = failures.isEmpty ? 'pass' : 'fail';
    rows.add(<String, Object?>{
      'productDocId': 'product-doc-$docSlug',
      'communityId': community['communityId'],
      'communityName': communityName,
      'docPath': _relativePath(file.path, repoRootPath),
      'expectedDocPath': 'docs/Product Docs V2/Community Examples/$fileName',
      'exists': exists,
      'status': status,
      'docHash': exists ? _fileSha256(file.path) : '',
      'lastModifiedAt': exists
          ? file.lastModifiedSync().toUtc().toIso8601String()
          : '',
      'screenRowIds': _asStringList(community['screenRowIds']).toSet().toList(),
      'workflowIds': _asStringList(community['workflowIds']).toSet().toList(),
      'roles': _asStringList(community['roles']).toSet().toList(),
      'requiredSections': requiredSections,
      'missingSections': missingSections,
      'wordCount': wordCount,
      'containsPlaceholders': containsPlaceholders,
      'mentionsCommunityName': mentionsCommunity,
      'hasWorkflowToSurfaceMap': hasWorkflowMapping,
      'hasDomainNativeSurfaceSpec': hasDomainSurfaceSpec,
      'hasB25ReviewLog': hasReviewLog,
      'requiredFix': failures.isEmpty
          ? 'Use this product experience doc as the source of truth for B25 screenshot review.'
          : 'Create or update $fileName with the full community product experience template before UI remediation continues: ${failures.join('; ')}.',
      'gapClassification': failures.isEmpty
          ? 'none'
          : 'community-product-spec-gap',
    });
  }
  rows.sort(
    (a, b) =>
        _asString(a['communityName']).compareTo(_asString(b['communityName'])),
  );
  return rows;
}

String _communityProductDocSlug(String communityName) {
  final slug = _slug(communityName);
  return <String, String>{
        'ad-free-community': 'ad-off',
        'data-portability-community': 'export-and-migration',
        'loom-communities': 'loom-communities-shell',
        'member-social-space': 'platform-social',
        'role-role-inventory': 'role-role-inventory',
      }[slug] ??
      slug;
}

List<String> _requiredB25ProductDocSections() {
  return <String>[
    '## 1. Community Identity And Promise',
    '## 2. Per'
        'sonas, Roles, And Jobs',
    '## 3. Information Architecture',
    '## 4. Home Screen Requirements',
    '## 5. Domain-Native Product Surfaces',
    '## 6. Workflow-To-Surface Mapping',
    '## 7. Role And State Matrix',
    '## 8. Content And Seed Data Requirements',
    '## 9. Visual And Interaction Standard',
    '## 10. Review And Remediation Log',
  ];
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
      'workflowRolePass': false,
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
  final workflowRole = _asMapList(judge['workflowRoleCriteria']);
  return <String, Object?>{
    'status': _asString(judge['status']),
    'totalCriteria': criteria.length,
    'passedCriteria': criteria.length - failed.length,
    'failedCriteria': failed.length,
    'blockingCriterionFailures': failed.length,
    'holisticPass':
        holistic.isNotEmpty &&
        holistic.every((row) => row['blocksPass'] != true),
    'workflowRolePass':
        workflowRole.isNotEmpty &&
        workflowRole.every((row) => row['blocksPass'] != true),
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
      '| Workflow/role direct-question pass | `${judge['workflowRolePass']}` |',
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
  final productDocCoverage = _asMapList(review['productDocCoverage']);
  final holisticAnswers = _asMapList(review['holisticQuestionAnswers']);
  final workflowScorecards = _asMapList(review['workflowRoleScorecards']);
  final lifecycleScorecards = _asMapList(review['workflowLifecycleScorecards']);
  final failingWorkflowScorecards = workflowScorecards
      .where((scorecard) => scorecard['blocksPass'] == true)
      .length;
  final failingLifecycleScorecards = lifecycleScorecards
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
      'Workflow/role scorecards: ${workflowScorecards.length} (${failingWorkflowScorecards} blocking)',
    )
    ..writeln()
    ..writeln(
      'Workflow lifecycle scorecards: ${lifecycleScorecards.length} (${failingLifecycleScorecards} blocking)',
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
    ..writeln('## Community Product Experience Docs')
    ..writeln()
    ..writeln(
      '| Product doc | Community | Status | Path | Missing sections | Required fix |',
    )
    ..writeln('| --- | --- | --- | --- | --- | --- |');
  if (productDocCoverage.isEmpty) {
    buffer.writeln(
      '| Missing | all reviewed communities | fail | n/a | all | Run the evidence collector with Product Docs V2 community experience specs present. |',
    );
  } else {
    for (final row in productDocCoverage) {
      buffer.writeln(
        '| `${_escape(_asString(row['productDocId']))}` | ${_escape(_asString(row['communityName']))} | `${_escape(_asString(row['status']))}` | `${_escape(_asString(row['docPath']))}` | ${_escape(_asStringList(row['missingSections']).join('; '))} | ${_escape(_asString(row['requiredFix']))} |',
      );
    }
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
    ..writeln('## Workflow/Role Scorecards')
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
    ..writeln('## Workflow Lifecycle Scorecards')
    ..writeln()
    ..writeln(
      '| Lifecycle scorecard | Status | Missing lifecycle groups | Summary |',
    )
    ..writeln('| --- | --- | --- | --- |');
  if (lifecycleScorecards.isEmpty) {
    buffer.writeln(
      '| Missing | fail | all | Run the workflow lifecycle judge. |',
    );
  } else {
    for (final scorecard in lifecycleScorecards.take(80)) {
      buffer.writeln(
        '| `${_escape(_asString(scorecard['scorecardId']))}` | `${_escape(_asString(scorecard['status']))}` | ${_escape(_asStringList(scorecard['missingLifecycleGroups']).join('; '))} | ${_escape(_asString(scorecard['summary']))} |',
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

String _b25LlmReviewFreshnessGateMarkdown(JsonMap report) {
  final problems = _asStringList(report['problems']);
  final buffer = StringBuffer()
    ..writeln('# B25 LLM Review Freshness Gate')
    ..writeln()
    ..writeln('| Field | Value |')
    ..writeln('| --- | --- |')
    ..writeln('| Status | `${_escape(_asString(report['status']))}` |')
    ..writeln(
      '| LLM review path | `${_escape(_asString(report['llmReviewPath']))}` |',
    )
    ..writeln(
      '| Expected run | `${_escape(_asString(report['expectedReviewRunId']))}` |',
    )
    ..writeln(
      '| Declared run | `${_escape(_asString(report['declaredReviewRunId']))}` |',
    )
    ..writeln(
      '| Expected app commit | `${_escape(_asString(report['expectedAppCommitSha']))}` |',
    )
    ..writeln(
      '| Declared app commit | `${_escape(_asString(report['declaredAppCommitSha']))}` |',
    )
    ..writeln('| Fresh review flag | `${report['freshReview'] == true}` |')
    ..writeln(
      '| Source review run | `${_escape(_asString(report['sourceReviewRunId']))}` |',
    )
    ..writeln('| Carried forward | `${report['carriedForward'] == true}` |')
    ..writeln(
      '| Reused prior review | `${report['reusedPriorReview'] == true}` |',
    )
    ..writeln('| Current screen rows | `${report['currentScreenRowCount']}` |')
    ..writeln(
      '| Reviewed screen rows | `${report['reviewedScreenRowCount']}` |',
    )
    ..writeln(
      '| Reviewed screenshot hashes | `${report['reviewedScreenshotHashCount']}` |',
    )
    ..writeln()
    ..writeln('## Problems');
  if (problems.isEmpty) {
    buffer.writeln();
    buffer.writeln('- None.');
  } else {
    buffer.writeln();
    for (final problem in problems) {
      buffer.writeln('- ${_escape(problem)}');
    }
  }
  buffer
    ..writeln()
    ..writeln('## Required Freshness Fields')
    ..writeln()
    ..writeln(
      '- ${_asStringList(report['requiredFields']).map(_escape).join('\n- ')}',
    )
    ..writeln()
    ..writeln('## Disallowed Prior-Review Fields')
    ..writeln()
    ..writeln(
      '- ${_asStringList(report['disallowedFields']).map(_escape).join('\n- ')}',
    );
  return buffer.toString();
}

String _b25ScreenMatrixMarkdown(JsonMap review) {
  final rows = _asMapList(review['screenRows']);
  final buffer = StringBuffer()
    ..writeln('# B25 Product UX Screen Review Matrix')
    ..writeln()
    ..writeln(
      '| Row | Community | Role | Workflow | Screen/state | Screenshot | Hash | Verdict | Visual inspection | Critique |',
    )
    ..writeln('| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |');
  for (final row in rows) {
    final inspection = row['visualInspection'] as JsonMap?;
    buffer.writeln(
      '| `${_escape(_asString(row['rowId']))}` | ${_escape(_asString(row['communityName']))} | ${_escape(_asString(row['role']))} | `${_escape(_asString(row['workflowId']))}` | ${_escape(_asString(row['screenOrState']))} | ${_escape(_asString(row['screenshotPath']))} | `${_escape(_asString(row['screenshotHash']))}` | ${_escape(_asString(row['verdict']))} | ${_escape(_asString(inspection?['summary']))} | ${_escape(_asString(row['screenSpecificCritique']))} |',
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
      '| Row | Community | Role | Workflow | Screenshot | Status | Findings | Summary |',
    )
    ..writeln('| --- | --- | --- | --- | --- | --- | --- | --- |');
  for (final row in rows.take(160)) {
    final inspection = row['visualInspection'] as JsonMap?;
    buffer.writeln(
      '| `${_escape(_rowId(row))}` | ${_escape(_asString(row['communityName'], fallback: _asString(row['communityId'])))} | ${_escape(_asString(row['role']))} | `${_escape(_asString(row['workflowId']))}` | `${_escape(_asString(row['screenshotPath']))}` | `${_escape(_asString(inspection?['status']))}` | ${_escape(_asStringList(inspection?['findingIds']).join(', '))} | ${_escape(_asString(inspection?['summary']))} |',
    );
  }
  if (rows.length > 160) {
    buffer
      ..writeln()
      ..writeln('_Showing 160 of ${rows.length} screen rows._');
  }
  return buffer.toString();
}

String _b25WorkflowRoleCoverageMarkdown(JsonMap review) {
  final summary = review['workflowRoleCoverageSummary'] is JsonMap
      ? review['workflowRoleCoverageSummary'] as JsonMap
      : <String, Object?>{};
  final rows = _asMapList(review['workflowRoleCoverage']);
  final buffer = StringBuffer()
    ..writeln('# B25 Workflow/Role Coverage Matrix')
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
      '| Coverage row | Status | Community | Workflow | Role | Screens | Missing evidence | Required fix |',
    )
    ..writeln('| --- | --- | --- | --- | --- | --- | --- | --- |');
  for (final row in rows) {
    buffer.writeln(
      '| `${_escape(_asString(row['coverageRowId']))}` | `${_escape(_asString(row['status']))}` | ${_escape(_asString(row['communityName']))} | `${_escape(_asString(row['workflowId']))}` | ${_escape(_asString(row['role']))} | ${_asStringList(row['screenRowIds']).length} | ${_escape(_asStringList(row['missingEvidence']).join('; '))} | ${_escape(_asString(row['requiredFix']))} |',
    );
  }
  return buffer.toString();
}

String _b25WorkflowLifecycleMarkdown(JsonMap review) {
  final summary = review['workflowLifecycleSummary'] is JsonMap
      ? review['workflowLifecycleSummary'] as JsonMap
      : <String, Object?>{};
  final rows = _asMapList(review['workflowLifecycleScorecards']);
  final buffer = StringBuffer()
    ..writeln('# B25 Workflow Lifecycle Scorecards')
    ..writeln()
    ..writeln('| Field | Value |')
    ..writeln('| --- | --- |')
    ..writeln('| Status | `${_escape(_asString(summary['status']))}` |')
    ..writeln('| Scorecards | ${summary['scorecardCount'] ?? rows.length} |')
    ..writeln(
      '| Failing scorecards | ${summary['failingScorecardCount'] ?? rows.where((row) => row['status'] != 'pass').length} |',
    )
    ..writeln(
      '| Missing lifecycle groups | ${_escape(_asStringList(summary['missingLifecycleGroups']).join('; '))} |',
    )
    ..writeln()
    ..writeln(
      '| Scorecard | Status | Community | Workflow | Role | Missing lifecycle groups | Target surface |',
    )
    ..writeln('| --- | --- | --- | --- | --- | --- | --- |');
  if (rows.isEmpty) {
    buffer.writeln(
      '| Missing | `fail` | all | all | all | all | Run `b25_workflow_interaction_model_judge.dart`. |',
    );
  } else {
    for (final row in rows) {
      buffer.writeln(
        '| `${_escape(_asString(row['scorecardId']))}` | `${_escape(_asString(row['status']))}` | ${_escape(_asString(row['communityName']))} | `${_escape(_asString(row['workflowId']))}` | ${_escape(_asString(row['role']))} | ${_escape(_asStringList(row['missingLifecycleGroups']).join('; '))} | ${_escape(_asString(row['targetProductionSurface']))} |',
      );
    }
  }
  return buffer.toString();
}

String _componentDocContextMarkdown(JsonMap context) {
  final docs = _asMapList(context['docs']);
  final buffer = StringBuffer()
    ..writeln('# B25 Component Doc Context')
    ..writeln()
    ..writeln('| Field | Value |')
    ..writeln('| --- | --- |')
    ..writeln(
      '| Generated at | `${_escape(_asString(context['generatedAt']))}` |',
    )
    ..writeln(
      '| App commit | `${_escape(_asString(context['appCommitSha']))}` |',
    )
    ..writeln('| Docs | ${docs.length} |')
    ..writeln()
    ..writeln('| Path | Exists | SHA-256 | Git last commit | Git status |')
    ..writeln('| --- | --- | --- | --- | --- |');
  for (final doc in docs) {
    buffer.writeln(
      '| `${_escape(_asString(doc['path']))}` | `${doc['exists'] == true}` | `${_escape(_asString(doc['sha256']))}` | `${_escape(_asString(doc['gitLastCommitSha']))}` | `${_escape(_asString(doc['gitStatus']))}` |',
    );
  }
  return buffer.toString();
}

String _coverageCollectorUsage() {
  return '''
b25_workflow_role_coverage_collector (B25)
Checks whether B25 evidence has explicit screenshot coverage for every workflow/role combination before independent UX review.

Usage:
  dart run packages/tooling/loom_ux_judges/bin/b25_workflow_role_coverage_collector.dart --input <independent-production-ux-review.json> --output <independent-production-ux-review.json> [--markdown-output <workflow-role-coverage-matrix.md>]
''';
}

String _workflowLifecycleJudgeUsage() {
  return '''
b25_workflow_lifecycle_judge (B25)
Compatibility alias for b25_workflow_interaction_model_judge. Scores every workflow/role row against the production semantic interaction model: expected decision, concrete object/context, decision information, primary action, alternate/change/reject affordance, persistent result state, and receiver/continuation state.

Usage:
  dart run packages/tooling/loom_ux_judges/bin/b25_workflow_lifecycle_judge.dart --input <independent-production-ux-review.json> --output <independent-production-ux-review.json> [--markdown-output <b25-workflow-lifecycle-scorecards.md>]
''';
}

String _workflowInteractionModelJudgeUsage() {
  return '''
b25_workflow_interaction_model_judge (B25)
Scores every workflow/role row against the production semantic interaction model: expected decision, required primary actions, required alternate/change/reject actions, disallowed generic substitutes, persistent result state, and receiver/continuation state. Uses screenshot-derived evidence; source files or worker responses cannot close this gate.

Usage:
  dart run packages/tooling/loom_ux_judges/bin/b25_workflow_interaction_model_judge.dart --input <independent-production-ux-review.json> --output <independent-production-ux-review.json> [--markdown-output <b25-workflow-lifecycle-scorecards.md>]
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
Consumes B25 screenshot evidence and workflow/role coverage, inspects screenshot pixels/layout, then writes holistic direct-question answers, workflow/role scorecards, screen-specific critiques, visual findings, and exact findings for the deterministic Production UX Judge.

Usage:
  dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input <independent-production-ux-review.json> --output <independent-production-ux-review.json> [--markdown-output <independent-production-ux-review.md>] [--matrix-output <product-ux-screen-review-matrix.md>]
''';
}

String _llmUxReviewImporterUsage() {
  return '''
b25_llm_ux_review_importer (B25)
Imports a fresh LLM vision UX Judge review into B25 schema v4 evidence. This is the semantic product-quality review artifact; deterministic judges only validate and ticket it.

Usage:
  dart run packages/tooling/loom_ux_judges/bin/b25_llm_ux_review_importer.dart --input <independent-production-ux-review.json> --llm-review <llm-review.json> --output <independent-production-ux-review.json> [--run-id <b25-v4-pass-N>] [--markdown-output <independent-production-ux-review.md>] [--matrix-output <product-ux-screen-review-matrix.md>]
''';
}

String _llmReviewFreshnessGateUsage() {
  return '''
b25_llm_review_freshness_gate (B25)
Fails when an LLM Vision UX Judge review is missing current-run freshness proof, reuses a prior review, references old screenshot rows/hashes, or does not match the current app commit. Run this before importing the LLM review.

Usage:
  dart run packages/tooling/loom_ux_judges/bin/b25_llm_review_freshness_gate.dart --input <independent-production-ux-review.json> --llm-review <llm-review.json> [--run-id <b25-v4-pass-N>] [--output <b25-llm-review-freshness-gate.json>] [--markdown-output <b25-llm-review-freshness-gate.md>]
''';
}

String _componentDocContextUsage() {
  return '''
b25_component_doc_context (B25)
Writes the current component-doc metadata the LLM Product Docs reconciliation gate must review every run: path, SHA-256, git last-commit SHA, git status, and semantic-review requirement flags.

Usage:
  dart run packages/tooling/loom_ux_judges/bin/b25_component_doc_context.dart --repo-root <repo-root> [--extra-doc <docs/Build Plan V2/Skill/components/card-surfaces/<surface>.md>] [--output <b25-component-doc-context.json>] [--markdown-output <b25-component-doc-context.md>]
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

String _captureCoverageGateUsage() {
  return '''
b25_capture_coverage_gate (B25)
Validates that canonical B25 evidence was produced from a commit-eligible full B12-B20 screenshot capture. Targeted remediation prechecks cannot pass this gate.

Usage:
  dart run packages/tooling/loom_ux_judges/bin/b25_capture_coverage_gate.dart --evidence-root <docs/Build Plan V2/Evidence> [--output <coverage-report.json>]
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
      '| Product spec work items | ${workItemSummary['productDocRepairWorkItemCount'] ?? 0} |',
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
      'Product Spec Repair Work Items',
      _asMapList(batch['productDocRepairWorkItems']),
    );
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
    final productDocs = _asMapList(batch['affectedProductDocs']);
    if (productDocs.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('### Affected Product Experience Docs')
        ..writeln()
        ..writeln(
          'Showing ${productDocs.take(30).length} of ${productDocs.length} affected product docs.',
        )
        ..writeln()
        ..writeln(
          '| Product doc | Community | Status | Path | Missing sections |',
        )
        ..writeln('| --- | --- | --- | --- | --- |');
      for (final row in productDocs.take(30)) {
        buffer.writeln(
          '| `${_escape(_asString(row['productDocId']))}` | ${_escape(_asString(row['communityName']))} | `${_escape(_asString(row['status']))}` | `${_escape(_asString(row['docPath']))}` | ${_escape(_asStringList(row['missingSections']).join('; '))} |',
        );
      }
    }
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
          '| Coverage row | Community | Workflow | Role | Missing evidence |',
        )
        ..writeln('| --- | --- | --- | --- | --- |');
      for (final row in coverageRows.take(30)) {
        buffer.writeln(
          '| `${_escape(_asString(row['coverageRowId']))}` | ${_escape(_asString(row['communityName']))} | `${_escape(_asString(row['workflowId']))}` | ${_escape(_asString(row['role']))} | ${_escape(_asStringList(row['missingEvidence']).join('; '))} |',
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
          '| Screen row | Community | Workflow | Role | State | Exact UX failure |',
        )
        ..writeln('| --- | --- | --- | --- | --- | --- |');
      for (final row in screenRows.take(30)) {
        buffer.writeln(
          '| `${_escape(_asString(row['screenRowId']))}` | ${_escape(_asString(row['communityName']))} | `${_escape(_asString(row['workflowId']))}` | ${_escape(_asString(row['role']))} | ${_escape(_asString(row['screenState']))} | ${_escape(_asString(row['exactUxFailure']))} |',
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
    'workflowRoleScorecards': _asMapList(evidence['workflowRoleScorecards']),
    'workflowLifecycleScorecards': _asMapList(
      evidence['workflowLifecycleScorecards'],
    ),
    'workflowRoleCriteria': criteria
        .where((criterion) => criterion.scope == 'workflow-role')
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
    if (criterion.id == 'b25-c16-app-shell-capability-utilization') {
      final appShellTickets = _b25AppShellCapabilityTickets(
        evidence: evidence,
        criterion: criterion,
        allBlockingFindingIds: allBlockingFindingIds,
        startIndex: index,
      );
      tickets.addAll(appShellTickets);
      index += appShellTickets.length;
      continue;
    }
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
      'affectedProductDocIds': ticketContext['affectedProductDocIds'],
      'affectedScreenRowIds': ticketContext['affectedScreenRowIds'],
      'affectedLifecycleScorecardIds':
          ticketContext['affectedLifecycleScorecardIds'],
      'affectedCoverageRows': ticketContext['affectedCoverageRows'],
      'affectedProductDocs': ticketContext['affectedProductDocs'],
      'affectedScreenRows': ticketContext['affectedScreenRows'],
      'failingWorkflowRoleScorecards':
          ticketContext['failingWorkflowRoleScorecards'],
      'failingWorkflowLifecycleScorecards':
          ticketContext['failingWorkflowLifecycleScorecards'],
      'failingDirectQuestions': ticketContext['failingDirectQuestions'],
      'evidenceRepairWorkItems': ticketContext['evidenceRepairWorkItems'],
      'productDocRepairWorkItems': ticketContext['productDocRepairWorkItems'],
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

List<JsonMap> _b25AppShellCapabilityTickets({
  required JsonMap evidence,
  required CriterionResult criterion,
  required List<String> allBlockingFindingIds,
  required int startIndex,
}) {
  final findings = _appShellCapabilityBlockingFindings(evidence);
  final relatedFindings = findings
      .map(_findingId)
      .where((id) => id.isNotEmpty)
      .toList();
  final ids = relatedFindings.isEmpty
      ? _relatedB25FindingIds(criterion, allBlockingFindingIds)
      : relatedFindings;
  final ticketFindingRows = findings.isEmpty
      ? <JsonMap>[
          <String, Object?>{
            'findingId': 'B25-APP-SHELL-CAPABILITY-REVIEW',
            'gapType': 'app-shell-capability-gap',
            'title': criterion.title,
            'summary': criterion.why,
            'requiredFix': criterion.requiredFix,
          },
        ]
      : findings;
  final tickets = <JsonMap>[];
  var index = startIndex;
  for (final finding in ticketFindingRows) {
    final findingId = _findingId(finding).isEmpty
        ? _asString(finding['findingId'], fallback: 'B25-APP-SHELL')
        : _findingId(finding);
    final related = ids.contains(findingId) ? <String>[findingId] : ids;
    final ticketContext = _b25TicketContext(evidence, criterion, related);
    final remediationMode = _b25RemediationMode(criterion, ticketContext);
    final gapType = _asString(
      finding['gapType'],
      fallback: 'app-shell-capability-gap',
    );
    final ticketId =
        'B25-RT-${index.toString().padLeft(3, '0')}-${_slug(gapType)}';
    tickets.add(<String, Object?>{
      'ticketId': ticketId,
      'ticketSchemaVersion': 4,
      'phase': 'B25',
      'reviewRunId': _asString(
        evidence['currentReviewRunId'],
        fallback: 'unknown-review-run',
      ),
      'status': 'open',
      'severity': _asString(finding['severity'], fallback: 'major'),
      'priority': 'P1',
      'sourceCriterionId': criterion.id,
      'sourceCapability': gapType,
      'tabId': _asString(finding['tabId']),
      'tabLabel': _asString(finding['tabLabel']),
      'rendererContractId': _asString(finding['rendererContractId']),
      'targetRendererContract': _asString(finding['rendererContractId']),
      'cardSurfaceFamily': _asString(finding['cardSurfaceFamily']),
      'missingTabNativeEvidence':
          gapType == 'app-shell-tab-renderer-contract-gap'
          ? <String>[
              'Missing screenshot-backed direct-question review for `${_asString(finding['rendererContractId'])}`.',
              'Missing proof that the tab looks and behaves like `${_asString(finding['tabLabel'])}` rather than a generic workflow-card list.',
            ]
          : <String>[],
      'interactionEvidenceRequired':
          gapType == 'app-shell-interaction-transition-gap'
          ? <String>[
              'Capture before/tap/after screenshots with distinct hashes.',
              'Record visible state changes and the resulting status, receipt, undo/change, or receiver state.',
              'Do not close from source code or worker claims alone.',
            ]
          : <String>[],
      'llmReviewDefect': gapType == 'app-shell-review-depth-gap'
          ? 'The review has pass flags but lacks screenshot-specific visible text, critique, hashes, or direct answers.'
          : '',
      'requiredScreenshotsToRecapture': _asStringList(
        finding['affectedScreenRowIds'],
      ),
      'affectedScreenshotPaths': _asStringList(
        finding['affectedScreenshotPaths'],
      ),
      'affectedScreenshotHashes': _asStringList(
        finding['affectedScreenshotHashes'],
      ),
      'visibleTextExcerpt': _asString(finding['visibleTextExcerpt']),
      'sourceFindingIds': related,
      'title': _appShellCapabilityTicketTitle(finding, criterion),
      'directQuestion': _appShellCapabilityDirectQuestion(gapType),
      'whyItFailed': _asString(finding['summary'], fallback: criterion.why),
      'requiredOutcome': _asString(
        finding['requiredFix'],
        fallback: criterion.requiredFix,
      ),
      'remediationMode': remediationMode['mode'],
      'workerReadiness': remediationMode['workerReadiness'],
      'firstRequiredStep': remediationMode['firstRequiredStep'],
      'implementationBlockedBy': remediationMode['implementationBlockedBy'],
      'affectedScope': ticketContext['affectedScope'],
      'affectedCoverageRowIds': ticketContext['affectedCoverageRowIds'],
      'affectedProductDocIds': ticketContext['affectedProductDocIds'],
      'affectedScreenRowIds': ticketContext['affectedScreenRowIds'],
      'affectedLifecycleScorecardIds':
          ticketContext['affectedLifecycleScorecardIds'],
      'affectedCoverageRows': ticketContext['affectedCoverageRows'],
      'affectedProductDocs': ticketContext['affectedProductDocs'],
      'affectedScreenRows': ticketContext['affectedScreenRows'],
      'failingWorkflowRoleScorecards':
          ticketContext['failingWorkflowRoleScorecards'],
      'failingWorkflowLifecycleScorecards':
          ticketContext['failingWorkflowLifecycleScorecards'],
      'failingDirectQuestions': ticketContext['failingDirectQuestions'],
      'evidenceRepairWorkItems': ticketContext['evidenceRepairWorkItems'],
      'productDocRepairWorkItems': ticketContext['productDocRepairWorkItems'],
      'uiRemediationWorkItems': ticketContext['uiRemediationWorkItems'],
      'likelyFilesOrWidgets': ticketContext['likelyFilesOrWidgets'],
      'uxReferencePatterns': ticketContext['uxReferencePatterns'],
      'referenceResearchQueries': ticketContext['referenceResearchQueries'],
      'sourceResearchRequirement':
          'The independent UX review must attach internet or open-source pattern references before UI remediation. If live research is unavailable, use the bundled catalog entries and keep the research queries in the ticket so a reviewer can refresh them.',
      'concreteAcceptanceCriteria': <String>[
        ..._appShellCapabilityAcceptanceChecks(gapType),
        ..._asStringList(ticketContext['concreteAcceptanceCriteria']),
      ],
      'problemStatement': _appShellCapabilityProblemStatement(
        finding,
        criterion,
      ),
      'rootCauseHypothesis': _rootCauseForB25Criterion(criterion.id),
      'targetExperience': _appShellCapabilityTargetExperience(gapType),
      'uxPrinciples': _uxPrinciplesForB25Criterion(criterion.id),
      'concreteImprovements': _appShellCapabilityImprovements(gapType),
      'implementationGuidance': _appShellCapabilityImplementationGuidance(
        gapType,
      ),
      'contentGuidance': _contentGuidanceForB25Criterion(criterion.id),
      'visualGuidance': _visualGuidanceForB25Criterion(criterion.id),
      'affectedEvidence': _affectedEvidenceForB25Criterion(criterion.id),
      'evidenceToCollect': _evidenceToCollectForB25Criterion(criterion.id),
      'acceptanceChecks': <String>[
        ..._appShellCapabilityAcceptanceChecks(gapType),
        ..._acceptanceChecksForB25Criterion(criterion.id),
      ],
      'rerunCommands': _b25RerunCommands(),
      'nonGoals': _nonGoalsForB25Criterion(criterion.id),
      'commitBoundary':
          'Commit this remediation iteration, refreshed evidence, scorecards, tickets, and tracker updates before starting the next UX feedback loop.',
    });
    index += 1;
  }
  return tickets;
}

String _appShellCapabilityTicketTitle(
  JsonMap finding,
  CriterionResult criterion,
) {
  final title = _asString(finding['title']);
  if (title.isNotEmpty) {
    return title;
  }
  final gapType = _asString(finding['gapType']);
  return '${criterion.title}: ${_appShellCapabilityLabel(gapType)}';
}

String _appShellCapabilityLabel(String gapType) {
  switch (gapType) {
    case 'app-shell-tabs-gap':
      return 'role tab model';
    case 'app-shell-pinning-gap':
      return 'role/tab pinning policy';
    case 'app-shell-presentation-state-gap':
      return 'surface presentation states';
    case 'app-shell-community-card-state-gap':
      return 'main community-list card states';
    case 'app-shell-customization-gap':
      return 'theme and customization tokens';
    case 'app-shell-renderer-selection-gap':
      return 'renderer selection by card-surface family';
    case 'app-shell-tab-renderer-contract-gap':
      return 'tab-native renderer contract proof';
    case 'app-shell-interaction-transition-gap':
      return 'button and interaction transition proof';
    case 'app-shell-review-depth-gap':
      return 'screenshot-specific app shell critique depth';
    default:
      return 'app shell capability';
  }
}

String _appShellCapabilityDirectQuestion(String gapType) {
  switch (gapType) {
    case 'app-shell-tabs-gap':
      return 'Do screenshots prove the role sees the right Home, Messages/Communication, and custom tabs for their job-to-be-done?';
    case 'app-shell-pinning-gap':
      return 'Is the pinning policy explicit and appropriate for this role/tab, with screenshots proving pinned surfaces only where the spec declares them?';
    case 'app-shell-presentation-state-gap':
      return 'Do screenshots prove minimized off-focus surfaces, the medium in-focus surface, and tap-to-expand behavior for the same workflow/role?';
    case 'app-shell-community-card-state-gap':
      return 'Does the main Loom Communities list show modern community launch cards with minimized/medium states, theme customization, and tap-to-open behavior?';
    case 'app-shell-customization-gap':
      return 'Do screenshots prove the community theme, typography, color, density, and component customization tokens are applied consistently?';
    case 'app-shell-renderer-selection-gap':
      return 'Does the visible screen prove the App Shell selected the correct domain renderer for the card-surface family instead of a generic fallback?';
    case 'app-shell-tab-renderer-contract-gap':
      return 'Does each dedicated tab visibly use its tab-native renderer contract, such as calendar/agenda, inbox/thread, marketplace browse/listing, documents library/detail, or workflow-status timeline?';
    case 'app-shell-interaction-transition-gap':
      return 'Do screenshots prove actionable controls were tapped and caused the correct visible state transition, including change/undo/result states where the workflow requires them?';
    case 'app-shell-review-depth-gap':
      return 'Does the App Shell capability review cite visible screenshot text, screenshot hashes, tab/renderer-specific critique, and direct answers rather than pass flags alone?';
    default:
      return 'Do current screenshots prove the required App Shell capability is visible, appropriate, and usable for the role/task?';
  }
}

String _appShellCapabilityProblemStatement(
  JsonMap finding,
  CriterionResult criterion,
) {
  final summary = _asString(finding['summary']);
  if (summary.isNotEmpty) {
    return summary;
  }
  return _problemStatementForB25Criterion(criterion.id);
}

String _appShellCapabilityTargetExperience(String gapType) {
  switch (gapType) {
    case 'app-shell-tabs-gap':
      return 'Each role sees a tab model that matches their community jobs. Home and Messages/Communication are always available, and optional tabs are named, ordered, and scoped to the role.';
    case 'app-shell-pinning-gap':
      return 'Every role/tab has an explicit pinning policy. Tabs that need persistent context keep the declared surface visible; tabs that do not need pins explicitly declare none with rationale.';
    case 'app-shell-presentation-state-gap':
      return 'Cards behave like a modern focused surface stack: the first visible item is medium, off-focus items are minimized, and tapping expands the selected product surface.';
    case 'app-shell-community-card-state-gap':
      return 'The main community picker uses branded launch cards with clear hierarchy, minimized/medium focus states, and tap-to-open behavior instead of a flat generic list.';
    case 'app-shell-customization-gap':
      return 'Community theme, typography, density, colors, and component treatments are applied consistently without sacrificing readability or touch targets.';
    case 'app-shell-renderer-selection-gap':
      return 'Each workflow uses the renderer that matches its card-surface family and product task, with visible UI differences that prove it is not a generic fallback.';
    case 'app-shell-tab-renderer-contract-gap':
      return 'Calendar, Messages, Marketplace, Documents, and Workflow Status tabs each render a recognizably native product interface for their category instead of reusing a generic card stack.';
    case 'app-shell-interaction-transition-gap':
      return 'Every important button and action proves a real interaction: the before screenshot, tapped/review state, and after screenshot show a changed status, result, receipt, or editable/undoable continuation.';
    case 'app-shell-review-depth-gap':
      return 'The App Shell review is a real visual critique: it cites screenshot-visible evidence, answers direct questions per tab/renderer, and fails weak or generic UI even when source flags say a feature exists.';
    default:
      return _targetExperienceForB25Criterion(
        'b25-c16-app-shell-capability-utilization',
      );
  }
}

List<String> _appShellCapabilityImprovements(String gapType) {
  switch (gapType) {
    case 'app-shell-pinning-gap':
      return <String>[
        'Update the community product experience doc Section 3.1 with a per-role/per-tab pinning policy.',
        'Use `pinnedSurfaces: none` with a rationale where no pinned surface makes sense; do not add pins just to satisfy the gate.',
        'When a tab declares pinned surfaces, implement and screenshot-proof that the declared surface remains visible while other tab surfaces scroll or change focus.',
        'Remove or revise any pin that is irrelevant to the tab job-to-be-done.',
      ];
    case 'app-shell-presentation-state-gap':
      return <String>[
        'Implement or expose minimized, medium/in-focus, and expanded states for the affected surface.',
        'Capture before/after screenshots that show the same workflow/role in minimized, medium, and expanded states.',
        'Ensure the expanded state is a richer product surface, not only a larger copy of the same generic card.',
      ];
    case 'app-shell-community-card-state-gap':
      return <String>[
        'Add main community selection evidence to B25 coverage.',
        'Show one in-focus medium community launch card and off-focus minimized community cards.',
        'Apply community-specific theme/typography tokens to launch cards while preserving readability and tap targets.',
      ];
    case 'app-shell-renderer-selection-gap':
      return <String>[
        'Map the workflow to the correct card-surface family and renderer target.',
        'Replace any generic fallback renderer with the domain renderer or screenshot-visible renderer evidence.',
        'Update the product doc and B25 evidence so the reviewer can see why the renderer matches the task.',
      ];
    case 'app-shell-tabs-gap':
      return <String>[
        'Declare role-specific tabs in the community product experience doc.',
        'Keep Home and Messages/Communication available for every role.',
        'Recapture screenshots showing tab labels, order, role visibility, selected state, and destination content.',
      ];
    case 'app-shell-tab-renderer-contract-gap':
      return <String>[
        'Create or update `tabRendererResults[]` in the B25 review for each required renderer contract: CalendarTabSurface, MessagesTabSurface, MarketplaceTabSurface, DocumentsTabSurface, and WorkflowStatusSurface.',
        'For Calendar, show a date strip/week/month or agenda plus event detail and RSVP/change-response state.',
        'For Messages, show inbox/thread/composer/unread or invite state, not an informational card.',
        'For Marketplace, show browse/search/filter/listing/detail/current-holder/queue or list-item actions.',
        'For Documents, show library/category/detail plus embedded or external-open state.',
        'For Workflow Status, show a timeline/current step/reviewer/comment/document/payment/action surface.',
      ];
    case 'app-shell-interaction-transition-gap':
      return <String>[
        'Extend capture automation to tap every important primary and alternate action in the reviewed workflows.',
        'Record before, action/review, and after screenshots with distinct hashes and visible state changes.',
        'For change/undo/edit paths, capture the later state proving the user can revise the prior response.',
      ];
    case 'app-shell-review-depth-gap':
      return <String>[
        'Replace pass-flag-only App Shell review rows with screenshot-specific critique.',
        'Each row must quote visible text, cite screenshot hashes, name the tab/renderer contract, and answer whether the UI behaves like that product surface.',
        'Do not reuse a generic rationale across unrelated tabs or communities.',
      ];
    case 'app-shell-customization-gap':
      return <String>[
        'Declare theme, typography, density, color, button, badge, and field customization tokens.',
        'Apply those tokens through the central App Shell model instead of one-off widget styling.',
        'Recapture screenshots proving the community-specific styling is visible and usable.',
      ];
    default:
      return _improvementsForB25Criterion(
        'b25-c16-app-shell-capability-utilization',
      );
  }
}

List<String> _appShellCapabilityImplementationGuidance(String gapType) {
  final shared = <String>[
    'Use `CommunityAppShellCustomizationSpec`, `LoomAppShellTabSpec`, and `LoomThemeCustomizationTokens` in `apps/loom_communities_demo/lib/main.dart`.',
    'Implement the capability centrally in the App Shell model, not as a one-off workflow widget hack.',
    'Recapture screenshots after implementation; source code alone cannot close this ticket.',
  ];
  switch (gapType) {
    case 'app-shell-pinning-gap':
      return <String>[
        ...shared,
        'Treat pinning as policy-driven: require proof only for role/tabs that declare pinned surfaces.',
        'For tabs with no useful pinned surface, document `pinnedSurfaces: none` and the rationale in the community product doc.',
        'Do not fail a Home tab simply because it has no pinned surface when the product spec explains that Home is a broad overview.',
      ];
    case 'app-shell-presentation-state-gap':
      return <String>[
        ...shared,
        'Verify scroll-driven focus sets the active surface to medium and off-focus surfaces to minimized.',
        'Verify tapping a medium or minimized surface expands it and tapping collapse returns it to the focused stack.',
      ];
    case 'app-shell-community-card-state-gap':
      return <String>[
        ...shared,
        'Extend B25 evidence to include the main Loom Communities selection screen.',
        'Prove community card focus states and tap-to-open behavior from screenshots, not only widget tests.',
      ];
    case 'app-shell-renderer-selection-gap':
      return <String>[
        ...shared,
        'Make renderer selection inspectable through card-surface family, renderer target, visible domain layout, and B25 evidence rows.',
        'If a renderer is intentionally shared, the screenshot must still prove the domain-specific content and layout for that card-surface family.',
      ];
    case 'app-shell-tab-renderer-contract-gap':
      return <String>[
        ...shared,
        'Represent tab-native renderer proof as data in `appShellCapabilityReview.tabRendererResults[]` so the production judge can validate it without trusting prose.',
        'Use the renderer contracts in `docs/Build Plan V2/Skill/components/card-surfaces/tab-renderer-contracts.md` and the mirrored Skill doc when choosing the target UI.',
      ];
    case 'app-shell-interaction-transition-gap':
      return <String>[
        ...shared,
        'Update workflow capture helpers so important buttons are actually tapped and the resulting UI state is captured.',
        'Do not make UI conform to old test keys; update the evidence automation to follow the production interaction model.',
      ];
    case 'app-shell-review-depth-gap':
      return <String>[
        ...shared,
        'Regenerate the App Shell review from screenshots and visible text, not from implementation declarations.',
        'Make weak LLM reviews fail by leaving `status=fail` until visual critique is screen-specific.',
      ];
    default:
      return <String>[
        ...shared,
        ..._implementationGuidanceForB25Criterion(
          'b25-c16-app-shell-capability-utilization',
        ),
      ];
  }
}

List<String> _appShellCapabilityAcceptanceChecks(String gapType) {
  switch (gapType) {
    case 'app-shell-pinning-gap':
      return <String>[
        'Every reviewed role/tab has `pinningPolicy` recorded as either `none` with rationale or a concrete list of pinned surface IDs.',
        'Tabs with `pinningPolicy=none` pass without pinned screenshots when the rationale matches the tab job-to-be-done.',
        'Tabs with declared pinned surfaces have after-screenshots proving the pinned surface remains visible and relevant.',
        '`appShellCapabilityReview.communityResults[]` does not fail pinning merely because a tab appropriately declares no pinned surface.',
      ];
    case 'app-shell-presentation-state-gap':
      return <String>[
        'After-screenshots show minimized, medium/in-focus, and expanded states for the affected workflow/role.',
        'The expanded screenshot shows a richer product surface or action detail than the minimized state.',
        'The affected `appShellCapabilityReview.communityResults[]` row has `presentationStatesPass=true`.',
      ];
    case 'app-shell-community-card-state-gap':
      return <String>[
        'B25 evidence includes the main Loom Communities selection screen.',
        'Screenshots prove a medium in-focus launch card, minimized off-focus cards, and tap-to-open behavior.',
        'Community launch cards visibly use community theme/typography tokens.',
      ];
    case 'app-shell-renderer-selection-gap':
      return <String>[
        'The affected workflow has a documented card-surface family and renderer target.',
        'After-screenshots show the domain renderer output, not a generic fallback card.',
        '`appShellCapabilityReview.communityResults[]` has `rendererSelectionPass=true` for the affected row.',
      ];
    case 'app-shell-tabs-gap':
      return <String>[
        'Screenshots prove Home and Messages/Communication tabs are available.',
        'Custom role tabs are visible only where appropriate and route to relevant content.',
        '`appShellCapabilityReview.communityResults[]` has `tabsPass=true`.',
      ];
    case 'app-shell-tab-renderer-contract-gap':
      return <String>[
        '`appShellCapabilityReview.tabRendererResults[]` contains passing rows for CalendarTabSurface, MessagesTabSurface, MarketplaceTabSurface, DocumentsTabSurface, and WorkflowStatusSurface.',
        'Each renderer row has screenshot row IDs, screenshot hashes, visible text, direct-question answers, and a screen-specific critique.',
        'The screenshots visibly match the renderer contract and do not rely on generic workflow-card fallback UI.',
      ];
    case 'app-shell-interaction-transition-gap':
      return <String>[
        'Every important primary/alternate action has before/tap/after or entry/action/result screenshots with distinct hashes.',
        'The after screenshot visibly proves a changed state, status, receipt, result, undo/change path, or receiver state.',
        '`appShellCapabilityReview.interactionTransitionResults[]` or lifecycle scorecards pass without missing transition evidence.',
      ];
    case 'app-shell-review-depth-gap':
      return <String>[
        'Every App Shell review row includes visible text excerpts and screenshot hashes.',
        'Every App Shell review row has non-boilerplate critique naming the tab, renderer, visible UI, and product-quality decision.',
        'A pass verdict is not based only on feature flags, source-code declarations, or absence of deterministic pixel findings.',
      ];
    case 'app-shell-customization-gap':
      return <String>[
        'Screenshots prove community color, typography, density, and component tokens are applied consistently.',
        'Customization does not introduce clipping, low contrast, crowding, or touch-target regressions.',
        '`appShellCapabilityReview.communityResults[]` has `themeCustomizationPass=true`.',
      ];
    default:
      return <String>[
        '`appShellCapabilityReview.status` is `pass`.',
        '`appShellCapabilityReview.missingCapabilities` is empty.',
      ];
  }
}

JsonMap _b25TicketContext(
  JsonMap evidence,
  CriterionResult criterion,
  List<String> relatedFindingIds,
) {
  final screenRows = _asMapList(evidence['screenRows']);
  final coverageRows = _asMapList(evidence['workflowRoleCoverage']);
  final productDocCoverage = _asMapList(evidence['productDocCoverage']);
  final scorecards = _asMapList(evidence['workflowRoleScorecards']);
  final lifecycleScorecards = _asMapList(
    evidence['workflowLifecycleScorecards'],
  );
  final holisticAnswers = _asMapList(evidence['holisticQuestionAnswers']);
  final findings = _asMapList(evidence['findings']);
  final screenById = <String, JsonMap>{
    for (final row in screenRows) _rowId(row): row,
  };
  final coverageById = <String, JsonMap>{
    for (final row in coverageRows) _asString(row['coverageRowId']): row,
  };
  final productDocById = <String, JsonMap>{
    for (final row in productDocCoverage) _asString(row['productDocId']): row,
  };
  final scorecardById = <String, JsonMap>{
    for (final row in scorecards) _asString(row['scorecardId']): row,
  };
  final lifecycleScorecardById = <String, JsonMap>{
    for (final row in lifecycleScorecards) _asString(row['scorecardId']): row,
  };
  final questionById = <String, JsonMap>{
    for (final row in holisticAnswers) _asString(row['questionId']): row,
  };
  final coverageIds = <String>{};
  final productDocIds = <String>{};
  final scorecardIds = <String>{};
  final screenIds = <String>{};
  final questionIds = <String>{};
  final lifecycleScorecardIds = <String>{};

  for (final finding in findings) {
    if (!relatedFindingIds.contains(_findingId(finding))) {
      continue;
    }
    coverageIds.addAll(_asStringList(finding['affectedCoverageRowIds']));
    productDocIds.addAll(_asStringList(finding['affectedProductDocIds']));
    scorecardIds.addAll(_asStringList(finding['affectedScorecardIds']));
    lifecycleScorecardIds.addAll(
      _asStringList(finding['affectedLifecycleScorecardIds']),
    );
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
    if (productDocById.containsKey(token)) {
      productDocIds.add(token);
      continue;
    }
    if (scorecardById.containsKey(token)) {
      scorecardIds.add(token);
      continue;
    }
    if (lifecycleScorecardById.containsKey(token)) {
      lifecycleScorecardIds.add(token);
      continue;
    }
    if (questionById.containsKey(token)) {
      questionIds.add(token);
      continue;
    }
    for (final scorecard in scorecards) {
      if (_workflowRoleEvidenceKeys(scorecard).contains(token)) {
        scorecardIds.add(_asString(scorecard['scorecardId']));
      }
    }
    for (final scorecard in lifecycleScorecards) {
      if (_workflowRoleEvidenceKeys(scorecard).contains(token)) {
        lifecycleScorecardIds.add(_asString(scorecard['scorecardId']));
      }
    }
    for (final coverage in coverageRows) {
      if (_workflowRoleEvidenceKeys(coverage).contains(token)) {
        coverageIds.add(_asString(coverage['coverageRowId']));
      }
    }
  }

  if (criterion.id != 'b25-c13-workflow-lifecycle-complete') {
    lifecycleScorecardIds.clear();
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

  if (criterion.id == 'b25-c02-community-product-docs-complete' ||
      criterion.scope == 'product-spec') {
    productDocIds.addAll(
      productDocCoverage
          .where((row) => _asString(row['status']) != 'pass')
          .map((row) => _asString(row['productDocId'])),
    );
  }

  if (criterion.scope == 'workflow-role') {
    if (scorecardIds.isEmpty) {
      scorecardIds.addAll(
        scorecards
            .where((scorecard) => scorecard['blocksPass'] == true)
            .map((scorecard) => _asString(scorecard['scorecardId'])),
      );
    }
    if (criterion.id == 'b25-c13-workflow-lifecycle-complete' &&
        lifecycleScorecardIds.isEmpty) {
      lifecycleScorecardIds.addAll(
        lifecycleScorecards
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
    for (final scorecardId in lifecycleScorecardIds.toList()) {
      final scorecard = lifecycleScorecardById[scorecardId];
      if (scorecard == null) {
        continue;
      }
      screenIds.addAll(_asStringList(scorecard['screenRowIds']));
      final coverageRowId = _asString(scorecard['coverageRowId']);
      if (coverageById.containsKey(coverageRowId)) {
        coverageIds.add(coverageRowId);
      }
    }
  }

  if (criterion.id == 'b25-c01-no-blocker-major') {
    for (final finding in findings.where((finding) => !_isResolved(finding))) {
      coverageIds.addAll(_asStringList(finding['affectedCoverageRowIds']));
      productDocIds.addAll(_asStringList(finding['affectedProductDocIds']));
      scorecardIds.addAll(_asStringList(finding['affectedScorecardIds']));
      lifecycleScorecardIds.addAll(
        _asStringList(finding['affectedLifecycleScorecardIds']),
      );
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
  for (final scorecardId in lifecycleScorecardIds.toList()) {
    final scorecard = lifecycleScorecardById[scorecardId];
    if (scorecard != null) {
      screenIds.addAll(_asStringList(scorecard['screenRowIds']));
    }
  }

  final affectedCoverageRows = coverageRows
      .where((row) => coverageIds.contains(_asString(row['coverageRowId'])))
      .map(_coverageTicketDetail)
      .toList();
  final affectedProductDocs = productDocCoverage
      .where((row) => productDocIds.contains(_asString(row['productDocId'])))
      .map(_productDocTicketDetail)
      .toList();
  final affectedScreenRows = screenRows
      .where((row) => screenIds.contains(_rowId(row)))
      .map((row) => _screenRowTicketDetail(row, criterion.id))
      .toList();
  final failingScorecards = scorecards
      .where((row) => scorecardIds.contains(_asString(row['scorecardId'])))
      .map((row) => _scorecardTicketDetail(row, criterion.id))
      .toList();
  final failingLifecycleScorecards =
      criterion.id == 'b25-c13-workflow-lifecycle-complete'
      ? lifecycleScorecards
            .where(
              (row) =>
                  lifecycleScorecardIds.contains(_asString(row['scorecardId'])),
            )
            .map((row) => _lifecycleScorecardTicketDetail(row, criterion.id))
            .toList()
      : <JsonMap>[];
  final failingQuestions = holisticAnswers
      .where((row) => questionIds.contains(_asString(row['questionId'])))
      .map(_directQuestionTicketDetail)
      .toList();
  final likelyFiles = <String>{
    ..._likelyFilesForB25Criterion(criterion.id),
    for (final row in affectedProductDocs) _asString(row['docPath']),
    for (final row in affectedScreenRows)
      ..._asStringList(row['likelyFilesOrWidgets']),
  }.where((value) => value.isNotEmpty).toList();
  final workflowIds = <String>{
    for (final row in affectedScreenRows) _asString(row['workflowId']),
    for (final row in affectedCoverageRows) _asString(row['workflowId']),
    for (final row in failingScorecards) _asString(row['workflowId']),
    for (final row in failingLifecycleScorecards) _asString(row['workflowId']),
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
    for (final row in affectedProductDocs)
      '`${_asString(row['docPath'])}` exists, has all ten B25 community product experience sections, contains no placeholders, and maps workflows to domain-native surfaces.',
    for (final row in affectedScreenRows.take(12))
      ..._asStringList(row['acceptanceCriteria']),
    for (final row in affectedCoverageRows.take(12))
      ..._asStringList(row['acceptanceCriteria']),
    for (final row in failingLifecycleScorecards.take(12))
      ..._asStringList(row['acceptanceCriteria']),
  }.where((value) => value.isNotEmpty).toList();
  final lifecycleAndRoleScorecards = <JsonMap>[
    ...failingScorecards,
    ...failingLifecycleScorecards,
  ];
  final evidenceRepairWorkItems = _b25WorkItems(
    stage: 'evidence-repair',
    criterionId: criterion.id,
    screenRows: affectedScreenRows,
    coverageRows: affectedCoverageRows,
    scorecards: lifecycleAndRoleScorecards,
  );
  final uiRemediationWorkItems = _b25WorkItems(
    stage: 'ui-remediation',
    criterionId: criterion.id,
    screenRows: affectedScreenRows,
    coverageRows: affectedCoverageRows,
    scorecards: lifecycleAndRoleScorecards,
  );
  final productDocRepairWorkItems = <JsonMap>[
    ..._b25ProductDocWorkItems(
      criterionId: criterion.id,
      productDocs: affectedProductDocs,
    ),
    if (criterion.id == 'b25-c13-workflow-lifecycle-complete')
      ..._b25InteractionModelProductDocWorkItems(
        criterionId: criterion.id,
        lifecycleScorecards: failingLifecycleScorecards,
      ),
  ];

  return <String, Object?>{
    'affectedScope': _concreteAffectedScope(
      criterion,
      affectedScreenRows,
      affectedCoverageRows,
      failingScorecards,
      failingQuestions,
      affectedProductDocs,
    ),
    'affectedCoverageRowIds': [
      for (final row in affectedCoverageRows) _asString(row['coverageRowId']),
    ],
    'affectedScreenRowIds': [
      for (final row in affectedScreenRows) _asString(row['screenRowId']),
    ],
    'affectedProductDocIds': [
      for (final row in affectedProductDocs) _asString(row['productDocId']),
    ],
    'affectedLifecycleScorecardIds': [
      for (final row in failingLifecycleScorecards)
        _asString(row['scorecardId']),
    ],
    'affectedCoverageRows': affectedCoverageRows,
    'affectedProductDocs': affectedProductDocs,
    'affectedScreenRows': affectedScreenRows,
    'failingWorkflowRoleScorecards': failingScorecards,
    'failingWorkflowLifecycleScorecards': failingLifecycleScorecards,
    'failingDirectQuestions': failingQuestions,
    'evidenceRepairWorkItems': evidenceRepairWorkItems,
    'productDocRepairWorkItems': productDocRepairWorkItems,
    'uiRemediationWorkItems': uiRemediationWorkItems,
    'likelyFilesOrWidgets': likelyFiles,
    'uxReferencePatterns': uxReferencePatterns,
    'referenceResearchQueries': referenceResearchQueries,
    'concreteAcceptanceCriteria': concreteAcceptance,
  };
}

Set<String> _workflowRoleEvidenceKeys(JsonMap row) {
  final workflowId = _asString(row['workflowId']);
  final role = _asString(row['role']);
  final fanId = _asString(row['fanId']);
  return <String>{
    if (workflowId.isNotEmpty && role.isNotEmpty) '$workflowId/$role',
    if (workflowId.isNotEmpty && fanId.isNotEmpty) '$workflowId/$fanId',
    _asString(row['scorecardId']),
    _asString(row['coverageRowId']),
  }..removeWhere((value) => value.isEmpty);
}

JsonMap _b25RemediationMode(CriterionResult criterion, JsonMap ticketContext) {
  final evidenceItems = _asMapList(ticketContext['evidenceRepairWorkItems']);
  final productDocItems = _asMapList(
    ticketContext['productDocRepairWorkItems'],
  );
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
  if (productDocItems.isNotEmpty ||
      criterion.id == 'b25-c02-community-product-docs-complete' ||
      criterion.scope == 'product-spec') {
    return <String, Object?>{
      'mode': 'product-spec-update-before-ui-remediation',
      'workerReadiness':
          'ready for product documentation update; UI remediation is blocked until the community product experience spec is complete',
      'firstRequiredStep':
          'Complete productDocRepairWorkItems so each affected community has a review-ready Product Docs V2 experience spec with domain-native surfaces and workflow-to-surface mapping.',
      'implementationBlockedBy': <String>[
        'The judge cannot verify production-grade UX without a community-specific product experience spec.',
        'UI workers need the spec to know the rich product surface they are supposed to build.',
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
          'Complete the evidenceRepairWorkItems: concrete role/fanId, screenshot-derived visible text, screen-specific critique, coverage row proof, and workflow/role scorecards.',
      'implementationBlockedBy': <String>[
        'Affected rows still use generic or missing role data.',
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
        'Review failing direct questions and add screen/workflow/role-specific evidence before implementation.',
    'implementationBlockedBy': <String>[
      'The ticket lacks row-level implementation evidence.',
    ],
  };
}

List<JsonMap> _b25ProductDocWorkItems({
  required String criterionId,
  required List<JsonMap> productDocs,
}) {
  if (productDocs.isEmpty &&
      criterionId != 'b25-c02-community-product-docs-complete') {
    return <JsonMap>[];
  }
  return productDocs.map((doc) {
    final communityName = _asString(doc['communityName']);
    final docPath = _asString(
      doc['docPath'],
      fallback: _asString(doc['expectedDocPath']),
    );
    return <String, Object?>{
      'workItemId':
          'b25-wi-product-spec-${_slug(communityName.isNotEmpty ? communityName : docPath)}',
      'stage': 'product-spec-update',
      'criterionId': criterionId,
      'communityId': _asString(doc['communityId']),
      'communityName': communityName,
      'productDocId': _asString(doc['productDocId']),
      'docPath': docPath,
      'expectedDocPath': _asString(doc['expectedDocPath']),
      'workflowId': 'community-product-experience',
      'role': 'product-experience-steward',
      'targetProductionSurface':
          'review-ready community product experience spec',
      'blockedUntil': 'productDocCoverage status is pass',
      'affectedScreenRowIds': _asStringList(doc['screenRowIds']),
      'affectedCoverageRowIds': <String>[],
      'missingSections': _asStringList(doc['missingSections']),
      'currentFailures': <String>[
        if (doc['exists'] != true) 'doc is missing',
        if (_asStringList(doc['missingSections']).isNotEmpty)
          'required sections missing: ${_asStringList(doc['missingSections']).join(', ')}',
        if (doc['containsPlaceholders'] == true) 'placeholder text remains',
        if (_asInt(doc['wordCount']) < 250) 'doc is too thin',
        if (doc['hasWorkflowToSurfaceMap'] != true)
          'workflow-to-surface map missing',
        if (doc['hasDomainNativeSurfaceSpec'] != true)
          'domain-native product surface spec missing',
        if (doc['hasB25ReviewLog'] != true)
          'B25 review/remediation log missing',
      ],
      'requiredUpdate':
          'Write the rich product experience for $communityName before UI work: product promise, roles/jobs, information architecture, home requirements, domain-native surfaces, workflow-to-surface mapping, role/state matrix, seed content, visual standard, and B25 review log.',
      'acceptanceCriteria': _asStringList(doc['acceptanceCriteria']),
      'followOnStep':
          'After this doc passes productDocCoverage, rerun B25 evidence collection and let UI remediation tickets reference the completed spec.',
    };
  }).toList();
}

List<JsonMap> _b25InteractionModelProductDocWorkItems({
  required String criterionId,
  required List<JsonMap> lifecycleScorecards,
}) {
  if (lifecycleScorecards.isEmpty) {
    return <JsonMap>[];
  }
  final byCommunity = <String, List<JsonMap>>{};
  for (final scorecard in lifecycleScorecards) {
    final key = _asString(scorecard['communityName']).isNotEmpty
        ? _asString(scorecard['communityName'])
        : _asString(scorecard['communityId'], fallback: 'unknown-community');
    byCommunity.putIfAbsent(key, () => <JsonMap>[]).add(scorecard);
  }
  final items = <JsonMap>[];
  for (final entry in byCommunity.entries) {
    final communityName = entry.key;
    final scorecards = entry.value;
    final workflows = _uniqueStrings([
      for (final row in scorecards) _asString(row['workflowId']),
    ]).where((id) => id.isNotEmpty).toList();
    final screenRows = _uniqueStrings([
      for (final row in scorecards) ..._asStringList(row['screenRowIds']),
    ]);
    final coverageRows = _uniqueStrings([
      for (final row in scorecards) _asString(row['coverageRowId']),
    ]).where((id) => id.isNotEmpty).toList();
    final missingActions = _uniqueStrings([
      for (final row in scorecards) ..._asStringList(row['missingActions']),
    ]);
    final wrongSubstitutes = _uniqueStrings([
      for (final row in scorecards)
        ..._asStringList(row['wrongGenericSubstitutes']),
    ]);
    final docSlug = _communityProductDocSlug(communityName);
    final docPath =
        'docs/Product Docs V2/Community Examples/$docSlug-product-experience.md';
    items.add(<String, Object?>{
      'workItemId': 'b25-wi-product-spec-interaction-model-$docSlug',
      'stage': 'product-spec-update',
      'criterionId': criterionId,
      'communityId': _asString(scorecards.first['communityId']),
      'communityName': communityName,
      'productDocId': 'product-doc-$docSlug-interaction-model',
      'docPath': docPath,
      'expectedDocPath': docPath,
      'workflowId': workflows.take(8).join(', '),
      'workflowIds': workflows,
      'role': 'product-experience-steward',
      'targetProductionSurface':
          'community product experience spec with semantic interaction models',
      'blockedUntil':
          'the product doc defines expected decision, required actions, result state, and receiver/continuation state for each failing workflow',
      'affectedScreenRowIds': screenRows,
      'affectedCoverageRowIds': coverageRows,
      'affectedLifecycleScorecardIds': [
        for (final row in scorecards) _asString(row['scorecardId']),
      ],
      'missingActions': missingActions,
      'wrongGenericSubstitutes': wrongSubstitutes,
      'currentFailures': <String>[
        '${workflows.length} workflows have incomplete semantic interaction models.',
        if (missingActions.isNotEmpty)
          'missing actions: ${missingActions.join(', ')}',
        if (wrongSubstitutes.isNotEmpty)
          'generic substitutes present: ${wrongSubstitutes.join(', ')}',
      ],
      'requiredUpdate':
          'Update $docPath so each failing workflow documents the real user decision, required context fields, primary domain action, alternate/change/reject path, persistent result state, receiver/continuation state, and screenshot evidence plan before UI remediation starts.',
      'workerActions': <String>[
        'Open or create `$docPath` using the community product experience template.',
        'For each failing workflow ID, add a semantic interaction-model row with expected decision, required decision data, primary action, alternate/change/reject action, result state, receiver/continuation state, and evidence IDs.',
        'Replace generic accept/cancel or submit/cancel workflow language with domain-specific actions from the failing scorecards.',
        'Mark the doc update in the B25 review/remediation log before assigning UI implementation work.',
      ],
      'acceptanceCriteria': <String>[
        '`$docPath` exists or is updated for `$communityName`.',
        'Every failing workflow ID is represented in the workflow-to-surface and interaction-model sections.',
        'Each workflow row states required primary and alternate/change/reject actions.',
        'The doc no longer leaves the interaction model for these workflows ambiguous.',
        'After UI remediation, fresh screenshots prove the documented actions and states.',
      ],
      'followOnStep':
          'After the product doc is updated, use the UI remediation work items to implement the documented interaction models, then recapture screenshots and rerun B25.',
    });
  }
  return items;
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
    required String role,
    required String fanId,
  }) {
    final key = [
      communityId,
      workflowId,
      fanId.isNotEmpty ? fanId : role,
      stage,
    ].join('::');
    return itemsByKey.putIfAbsent(key, () {
      final targetSurface = _targetProductionSurfaceForWorkflow(workflowId);
      return <String, Object?>{
        'workItemId':
            'b25-wi-${_slug(stage)}-${_slug(communityId.isNotEmpty ? communityId : communityName)}-${_slug(workflowId)}-${_slug(fanId.isNotEmpty ? fanId : role)}',
        'stage': stage,
        'criterionId': criterionId,
        'communityId': communityId,
        'communityName': communityName,
        'workflowId': workflowId,
        'role': role,
        'fanId': fanId,
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
            ? _evidenceRepairWorkerActions(workflowId, role, targetSurface)
            : _uiRemediationWorkerActions(workflowId, role, targetSurface),
        'acceptanceCriteria': stage == 'evidence-repair'
            ? _evidenceRepairAcceptanceCriteria(workflowId, role)
            : _uiRemediationAcceptanceCriteria(workflowId, role, targetSurface),
        'blockedUntil': stage == 'ui-remediation'
            ? 'Evidence-repair work item for this community/workflow/role has fresh screenshots, screenshot-derived visible text, a specific role/fanId, and a non-boilerplate critique.'
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
      role: _asString(row['role']),
      fanId: _asString(row['fanId']),
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
      role: _asString(coverage['role']),
      fanId: _asString(coverage['fanId']),
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
      role: _asString(scorecard['role']),
      fanId: _asString(scorecard['fanId']),
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
    'b25-c13-workflow-lifecycle-complete',
    'b25-c09-no-layout-production-defects',
  }.contains(criterionId);
}

bool _screenDetailNeedsEvidenceRepair(JsonMap row) {
  final role = _asString(row['role']);
  final fanId = _asString(row['fanId']);
  final source = _asString(row['visibleTextSource']).toLowerCase();
  final surface = _asString(row['currentSurfaceClassification']).toLowerCase();
  final primarySurface = _asString(
    row['currentPrimarySurfaceType'],
  ).toLowerCase();
  final critique = _asString(row['currentCritique']).toLowerCase();
  return !_isSpecificRole(role, fanId) ||
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
  String role,
  String targetSurface,
) {
  return <String>[
    'Replace generic role `${role.isEmpty ? 'role-under-review' : role}` with the concrete actor/receiver role and fanId for `${workflowId}`.',
    'Verify entry, action/review, and result/receiver screenshots exist for `${workflowId}` and are tied to the concrete role.',
    'Extract visible text from the listed screenshots or manually transcribe exactly what is visible.',
    'Write a non-reusable critique that names the visible UI, visible text, role, user task, current failure, and target surface: ${targetSurface}.',
    'Rerun the workflow/role coverage collector and independent UX judge before assigning UI implementation work.',
  ];
}

List<String> _uiRemediationWorkerActions(
  String workflowId,
  String role,
  String targetSurface,
) {
  return <String>[
    'Replace the current primary surface for `${workflowId}` with ${targetSurface}.',
    'Build the entry, action/review, and result states for `${role.isEmpty ? 'the target role' : role}` using domain content and semantic action labels.',
    'Remove workflow-harness, validation, metadata, checklist, or generic repeated-card language from the user-facing surface.',
    'Update widget/integration tests and B25 evidence expectations for the changed UI.',
    'Recapture screenshots and rerun the workflow/role direct-question scorecard.',
  ];
}

List<String> _evidenceRepairAcceptanceCriteria(String workflowId, String role) {
  return <String>[
    '`${workflowId}` has concrete role/fanId coverage, not `role-under-review`.',
    'Entry/action/result screenshot rows exist for `${workflowId}` and each row has screenshot path, hash, timestamp, device metadata, and app commit SHA.',
    'Visible text is screenshot-derived or manually transcribed from the screenshot for every affected row.',
    'Each affected row has a screen-specific critique that cannot be reused unchanged for another workflow.',
    'Workflow/role coverage collector no longer flags missing role or screenshot evidence for `${workflowId}`.',
  ];
}

List<String> _uiRemediationAcceptanceCriteria(
  String workflowId,
  String role,
  String targetSurface,
) {
  return <String>[
    'The primary `${workflowId}` screen is ${targetSurface}, not a generic workflow card, metadata page, checklist modal, or validation surface.',
    'Visible content includes the real domain data, user goal, semantic action, validation/review state, and result/receipt/receiver state expected for `${role.isEmpty ? 'the target role' : role}`.',
    'The workflow/role direct-question scorecard passes for task clarity, domain-native surface, natural actions, and production-grade UI.',
    'Fresh screenshots prove the remediated entry/action/result states after the code change.',
  ];
}

JsonMap _concreteAffectedScope(
  CriterionResult criterion,
  List<JsonMap> screenRows,
  List<JsonMap> coverageRows,
  List<JsonMap> scorecards,
  List<JsonMap> directQuestions,
  List<JsonMap> productDocs,
) {
  final communities = _uniqueStrings(<String>[
    for (final row in screenRows) _asString(row['communityName']),
    for (final row in coverageRows) _asString(row['communityName']),
    for (final row in scorecards) _asString(row['communityName']),
    for (final row in productDocs) _asString(row['communityName']),
  ]);
  final roles = _uniqueStrings(<String>[
    for (final row in screenRows) _asString(row['role']),
    for (final row in coverageRows) _asString(row['role']),
    for (final row in scorecards) _asString(row['role']),
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
  final productDocPaths = _uniqueStrings(<String>[
    for (final row in productDocs) _asString(row['docPath']),
  ]);
  return <String, Object?>{
    'scope': criterion.scope,
    'communities': communities.isEmpty
        ? <String>['all reviewed communities/test apps']
        : communities,
    'roles': roles.isEmpty ? <String>['all reviewed target roles'] : roles,
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
    'productDocs': productDocPaths,
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
    'role': _asString(row['role']),
    'fanId': _asString(row['fanId']),
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
      'role': _asString(row['role']),
      'fanId': _asString(row['fanId']),
      'visibleTextSource': _asString(row['visibleTextExtractionSource']),
      'currentSurfaceClassification': _asString(row['uiPatternClassification']),
      'currentPrimarySurfaceType': _asString(row['primarySurfaceType']),
      'currentCritique': _asString(row['screenSpecificCritique']),
    }),
    'evidenceRepairActions': _evidenceRepairWorkerActions(
      workflowId,
      _asString(row['role']),
      targetSurface,
    ),
    'uiRemediationActions': _uiRemediationWorkerActions(
      workflowId,
      _asString(row['role']),
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
    'role': _asString(row['role']),
    'fanId': _asString(row['fanId']),
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
      'Coverage row has a specific role and fanId.',
      'Coverage row has entry, action/review, and result/receiver screenshots.',
      'Every listed screenshot path exists and has a fresh hash/timestamp/app commit SHA.',
      'The workflow/role scorecard passes after rerun.',
    ],
  };
}

JsonMap _productDocTicketDetail(JsonMap row) {
  return <String, Object?>{
    'productDocId': _asString(row['productDocId']),
    'status': _asString(row['status']),
    'communityId': _asString(row['communityId']),
    'communityName': _asString(row['communityName']),
    'docPath': _asString(row['docPath']),
    'expectedDocPath': _asString(row['expectedDocPath']),
    'exists': row['exists'] == true,
    'docHash': _asString(row['docHash']),
    'lastModifiedAt': _asString(row['lastModifiedAt']),
    'screenRowIds': _asStringList(row['screenRowIds']),
    'workflowIds': _asStringList(row['workflowIds']),
    'roles': _asStringList(row['roles']),
    'missingSections': _asStringList(row['missingSections']),
    'wordCount': _asInt(row['wordCount']),
    'containsPlaceholders': row['containsPlaceholders'] == true,
    'hasWorkflowToSurfaceMap': row['hasWorkflowToSurfaceMap'] == true,
    'hasDomainNativeSurfaceSpec': row['hasDomainNativeSurfaceSpec'] == true,
    'hasB25ReviewLog': row['hasB25ReviewLog'] == true,
    'requiredFix': _asString(row['requiredFix']),
    'acceptanceCriteria': <String>[
      'Product doc exists at `${_asString(row['expectedDocPath'])}`.',
      'All ten B25 community product experience sections are present.',
      'The doc contains no angle-bracket placeholders and is not thin.',
      'The doc maps workflows to domain-native product surfaces before UI remediation starts.',
      'The B25 review/remediation log names how the current screenshots will be judged against this spec.',
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
    'role': _asString(scorecard['role']),
    'fanId': _asString(scorecard['fanId']),
    'screenRowIds': _asStringList(scorecard['screenRowIds']),
    'screenshotPaths': _asStringList(scorecard['screenshotPaths']),
    'summary': _asString(scorecard['summary']),
    'targetProductionSurface': _targetProductionSurfaceForWorkflow(workflowId),
    'semanticSurfaceProof': scorecard['semanticSurfaceProof'],
    'referencePatternsToCopy': _b25ReferencePatternsForWorkflow(workflowId),
    'referenceResearchQueries': _referenceResearchQueriesForWorkflow(
      workflowId,
    ),
    'failingQuestions': failingQuestions,
    'acceptanceCriteria': <String>[
      'All direct questions in this workflow/role scorecard pass.',
      'The primary surface is domain-native for `${workflowId}` and the target role.',
      'The semantic surface proof passes: after-screenshot visible text demonstrates the required target-surface elements, not just absence of generic-card findings.',
      'Visible text and critique cite the actual screenshots for every screen row.',
      ..._screenRowAcceptanceCriteria(scorecard, criterionId),
    ],
  };
}

JsonMap _lifecycleScorecardTicketDetail(JsonMap scorecard, String criterionId) {
  final workflowId = _asString(scorecard['workflowId']);
  final proof = scorecard['workflowLifecycleProof'] as JsonMap?;
  final interactionFromScorecard = scorecard['semanticInteractionModel'];
  final interactionFromProof = proof == null
      ? null
      : proof['semanticInteractionModel'];
  final interactionModel = interactionFromScorecard is JsonMap
      ? interactionFromScorecard
      : interactionFromProof is JsonMap
      ? interactionFromProof
      : <String, Object?>{};
  final missingGroups = _asStringList(
    scorecard['missingLifecycleGroups'] ?? proof?['missingGroups'],
  );
  final failingQuestions = _asMapList(scorecard['questions'])
      .where((question) => question['blocksPass'] == true)
      .map(_directQuestionTicketDetail)
      .toList();
  return <String, Object?>{
    'scorecardId': _asString(scorecard['scorecardId']),
    'coverageRowId': _asString(scorecard['coverageRowId']),
    'status': _asString(scorecard['status']),
    'communityId': _asString(scorecard['communityId']),
    'communityName': _asString(scorecard['communityName']),
    'workflowId': workflowId,
    'role': _asString(scorecard['role']),
    'fanId': _asString(scorecard['fanId']),
    'screenRowIds': _asStringList(scorecard['screenRowIds']),
    'screenshotPaths': _asStringList(scorecard['screenshotPaths']),
    'summary': _asString(scorecard['summary']),
    'targetProductionSurface': _targetProductionSurfaceForWorkflow(workflowId),
    'workflowLifecycleProof': proof,
    'semanticInteractionModel': interactionModel,
    'expectedDecision': _asString(interactionModel['expectedDecision']),
    'requiredPrimaryActions': _asStringList(
      interactionModel['requiredPrimaryActions'],
    ),
    'requiredAlternateActions': _asStringList(
      interactionModel['requiredAlternateActions'],
    ),
    'visiblePrimaryActions': _asStringList(
      interactionModel['visiblePrimaryActions'],
    ),
    'visibleAlternateActions': _asStringList(
      interactionModel['visibleAlternateActions'],
    ),
    'missingActions': _asStringList(interactionModel['missingActions']),
    'wrongGenericSubstitutes': _asStringList(
      interactionModel['wrongGenericSubstitutes'],
    ),
    'missingLifecycleGroups': missingGroups,
    'requiredLifecycleGroups': _asMapList(scorecard['requiredLifecycleGroups']),
    'referencePatternsToCopy': _b25ReferencePatternsForWorkflow(workflowId),
    'referenceResearchQueries': _referenceResearchQueriesForWorkflow(
      workflowId,
    ),
    'failingQuestions': failingQuestions,
    'acceptanceCriteria': <String>[
      'All lifecycle direct questions in this workflow/role scorecard pass.',
      'The UI visibly proves the concrete object/context, decision information, primary action, alternate/change/reject affordance, persistent result state, and receiver/continuation state.',
      'The semantic interaction model passes: expected decision, required primary actions, and required alternate/change/reject actions are visible in fresh after screenshots.',
      'Missing lifecycle groups are resolved: ${missingGroups.isEmpty ? 'none' : missingGroups.join(', ')}.',
      'Fresh after screenshots prove the lifecycle and interaction model; implementation notes, code diffs, or ticket responses alone cannot close this ticket.',
      ..._workflowLifecycleAcceptanceCriteria(
        workflowId,
        _asString(scorecard['role']),
      ),
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
  final llmScreenReview = row['llmVisionScreenReview'];
  if (llmScreenReview is JsonMap) {
    final critique = _asString(llmScreenReview['critique']);
    final requiredFix = _asString(llmScreenReview['requiredFix']);
    if (critique.isNotEmpty) {
      failures.add('LLM vision critique: $critique');
    }
    if (requiredFix.isNotEmpty) {
      failures.add('LLM required fix: $requiredFix');
    }
  }
  final role = _asString(row['role']);
  final fanId = _asString(row['fanId']);
  if (!_isSpecificRole(role, fanId)) {
    failures.add(
      'Role is generic or missing; the worker cannot know which role this screen serves.',
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
      'Screen-specific critique does not yet explain visible UI, role, task, and remediation.',
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
  final role = _asString(row['role'], fallback: 'target role');
  return <String>[
    'Screen row `${_rowId(row)}` has a specific role/fanId, not `role-under-review`.',
    'Visible text for `${_rowId(row)}` is extracted from the screenshot or manually transcribed from the screenshot.',
    'Critique for `${_rowId(row)}` names visible UI elements, visible text, role `${role}`, workflow `${workflowId}`, and the exact product UX issue.',
    'Primary surface for `${workflowId}` is documented as `${_targetProductionSurfaceForWorkflow(workflowId)}` or another explicit domain-native surface.',
    'After-screenshot visible text proves every required semantic surface group for `${workflowId}`.',
    'Fresh screenshot path/hash/timestamp/app commit SHA are recorded after the fix.',
    if (criterionId == 'b25-c06-domain-native-primary-surfaces')
      'The workflow/role direct-question scorecard passes the domain-native primary surface question.',
    if (criterionId == 'b25-c13-workflow-lifecycle-complete')
      'The workflow lifecycle scorecard passes with no missing object/context, decision information, action affordance, result state, or receiver/continuation groups.',
    if (criterionId == 'b25-c08-visible-text-specific-critique')
      'The workflow/role direct-question scorecard passes the visible-text and task-specific critique question.',
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
    case 'b25-c02-community-product-docs-complete':
      return <String>[
        ...common,
        'docs/Product Docs V2/Community Examples/',
        'docs/Build Plan V2/Skill/references/community-product-experience-template.md',
        'app/packages/tooling/loom_ux_judges/lib/loom_ux_judges.dart',
      ];
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
  if (id.contains('wf_demo-app-persona-picker')) {
    return 'test-only role switcher surface with active role, role description, and return-to-workflow state';
  }
  if (id.contains('actor-identity-inventory')) {
    return 'role capability matrix surface with roles, allowed actions, receiver states, and denied/hidden behavior';
  }
  if (id.contains('wf_community-persona-aware-ux')) {
    return 'role-aware community surface showing actor, receiver, read-only, disabled, or hidden workflow states for the active role';
  }
  if (id.contains('wf_multi-persona-workflow-evidence')) {
    return 'multi-role handoff evidence surface with actor-created state, role switch, receiver state, and continuation action';
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

List<JsonMap> _b25CardSurfaceRegistryForRows(List<JsonMap> screenRows) {
  final rowsByWorkflow = <String, JsonMap>{};
  final rowIdsByWorkflow = <String, Set<String>>{};
  final communitiesByWorkflow = <String, Set<String>>{};
  for (final row in screenRows) {
    final workflowId = _asString(row['workflowId']);
    if (workflowId.isEmpty) {
      continue;
    }
    rowsByWorkflow.putIfAbsent(
      workflowId,
      () => _b25CardSurfaceRegistryEntryForWorkflowId(workflowId),
    );
    rowIdsByWorkflow
        .putIfAbsent(workflowId, () => <String>{})
        .add(_asString(row['rowId']));
    communitiesByWorkflow
        .putIfAbsent(workflowId, () => <String>{})
        .add(_asString(row['communityId']));
  }
  return [
    for (final entry in rowsByWorkflow.entries)
      <String, Object?>{
        ...entry.value,
        'screenRowIds': (rowIdsByWorkflow[entry.key] ?? <String>{}).toList()
          ..sort(),
        'communityIds':
            (communitiesByWorkflow[entry.key] ?? <String>{}).toList()..sort(),
      },
  ]..sort(
    (left, right) =>
        _asString(left['workflowId']).compareTo(_asString(right['workflowId'])),
  );
}

JsonMap _b25CardSurfaceRegistryEntryForWorkflowId(String workflowId) {
  final id = workflowId.toLowerCase();
  if (id.contains('announcement') ||
      id.contains('publish') ||
      id.contains('notification')) {
    return _b25SurfaceSpec(
      workflowId: workflowId,
      cardSurfaceFamily: 'announcement',
      apiContract: 'CommunityAnnouncementApi',
      requiredInteractions: const [
        'createDraft',
        'updateDraft',
        'previewAnnouncement',
        'scheduleAnnouncement',
        'publishAnnouncement',
        'cancelScheduledAnnouncement',
        'updatePublishedAnnouncement',
        'unpublishAnnouncement',
        'deliveryStatus',
        'readReceipts',
        'revisionHistory',
      ],
      primaryActions: const ['Save draft', 'Preview', 'Publish', 'Schedule'],
      alternateActions: const ['Edit published update', 'Unpublish'],
    );
  }
  if (id.contains('ad-off') ||
      id.contains('payment') ||
      id.contains('donation') ||
      id.contains('dues') ||
      id.contains('checkout')) {
    return _b25SurfaceSpec(
      workflowId: workflowId,
      cardSurfaceFamily: 'payment',
      apiContract: 'CommunityPaymentSurfaceApi',
      requiredInteractions: const [
        'createPaymentIntent',
        'confirmPayment',
        'recordFailure',
        'retryPayment',
        'refund',
        'createRecurringPlan',
        'manageRecurringPlan',
        'setDonorVisibility',
        'getReceipt',
        'getEntitlement',
        'settlementStatus',
      ],
      primaryActions: const ['Pay', 'Confirm', 'Manage subscription'],
      alternateActions: const ['Retry', 'Refund', 'Open receipt'],
    );
  }
  if (id.contains('rsvp') ||
      id.contains('event') ||
      id.contains('practice') ||
      id.contains('schedule') ||
      id.contains('photo-walk')) {
    return _b25SurfaceSpec(
      workflowId: workflowId,
      cardSurfaceFamily: 'event-rsvp',
      apiContract: 'CommunityEventRsvpApi',
      requiredInteractions: const [
        'getEventDetail',
        'respondGoingMaybeNo',
        'changeRsvp',
        'cancelRsvp',
        'joinWaitlist',
        'listAttendees',
        'updateCapacity',
        'sendReminder',
        'calendarState',
        'cancelOrReschedule',
      ],
      primaryActions: const ['Going', 'Maybe', 'Not going'],
      alternateActions: const ['Change response', 'Cancel RSVP'],
    );
  }
  if (id.contains('volunteer') || id.contains('shift')) {
    return _b25SurfaceSpec(
      workflowId: workflowId,
      cardSurfaceFamily: 'volunteer',
      apiContract: 'CommunityVolunteerApi',
      requiredInteractions: const [
        'listShifts',
        'signup',
        'updateAvailability',
        'cancelSignup',
        'joinWaitlist',
        'listVolunteers',
        'volunteerSummary',
        'assignCoordinator',
        'checkInVolunteer',
        'markNoShow',
        'protectedContactReveal',
      ],
      primaryActions: const ['Sign up', 'Edit availability', 'Check in'],
      alternateActions: const ['Cancel signup', 'View volunteers'],
    );
  }
  if (id.contains('plant') || id.contains('exchange')) {
    return _b25SurfaceSpec(
      workflowId: workflowId,
      cardSurfaceFamily: 'exchange',
      apiContract: 'CommunityExchangeApi',
      requiredInteractions: const [
        'createOffer',
        'updateOffer',
        'cancelOffer',
        'claimOffer',
        'cancelClaim',
        'markUnavailable',
        'schedulePickup',
        'handoffComplete',
        'listClaims',
        'privacyScopedContact',
      ],
      primaryActions: const ['Offer item', 'Claim', 'Schedule pickup'],
      alternateActions: const ['Edit offer', 'Cancel claim'],
    );
  }
  if (id.contains('equipment') ||
      id.contains('gear') ||
      id.contains('loan') ||
      id.contains('racquet')) {
    return _b25SurfaceSpec(
      workflowId: workflowId,
      cardSurfaceFamily: 'equipment-loan',
      apiContract: 'CommunityEquipmentLoanApi',
      requiredInteractions: const [
        'offerEquipment',
        'requestLoan',
        'approveLoan',
        'declineLoan',
        'schedulePickup',
        'checkOut',
        'returnItem',
        'cancelLoan',
        'listAvailability',
        'privacyScopedContact',
      ],
      primaryActions: const ['Offer equipment', 'Request loan', 'Check out'],
      alternateActions: const ['Return item', 'Cancel loan'],
    );
  }
  if (id.contains('nomination')) {
    return _b25SurfaceSpec(
      workflowId: workflowId,
      cardSurfaceFamily: 'nomination',
      apiContract: 'CommunityNominationApi',
      requiredInteractions: const [
        'createNomination',
        'updateNomination',
        'withdrawNomination',
        'listNominations',
        'detectDuplicate',
        'checkEligibility',
        'linkToBallot',
        'nominationStatus',
      ],
      primaryActions: const ['Nominate', 'Edit nomination'],
      alternateActions: const ['Withdraw nomination'],
    );
  }
  if (id.contains('vote') || id.contains('ballot') || id.contains('poll')) {
    return _b25SurfaceSpec(
      workflowId: workflowId,
      cardSurfaceFamily: 'vote',
      apiContract: 'CommunityVoteApi',
      requiredInteractions: const [
        'openBallot',
        'castVote',
        'changeVote',
        'clearVote',
        'getVoteState',
        'getResults',
        'publishSelection',
        'auditVote',
      ],
      primaryActions: const ['Vote', 'Change vote'],
      alternateActions: const ['Clear vote', 'View results'],
    );
  }
  if (id.contains('message') ||
      id.contains('discussion') ||
      id.contains('thread')) {
    return _b25SurfaceSpec(
      workflowId: workflowId,
      cardSurfaceFamily: 'thread',
      apiContract: 'CommunityThreadApi',
      requiredInteractions: const [
        'createThread',
        'reply',
        'editMessage',
        'deleteMessage',
        'markRead',
        'listUnread',
        'muteThread',
        'archiveThread',
        'attachMedia',
        'mentionMember',
      ],
      primaryActions: const ['Reply', 'Mark read'],
      alternateActions: const ['Edit', 'Mute', 'Archive'],
    );
  }
  if (id.contains('care')) {
    return _b25SurfaceSpec(
      workflowId: workflowId,
      cardSurfaceFamily: 'care-request',
      apiContract: 'CommunityCareRequestApi',
      requiredInteractions: const [
        'createRequest',
        'updateRequest',
        'withdrawRequest',
        'assignCareTeam',
        'reviewRequest',
        'requestChanges',
        'resolveRequest',
        'neutralNotification',
        'readPublicSummary',
        'readProtectedDetails',
        'redactedAudit',
      ],
      primaryActions: const ['Request care', 'Assign care team', 'Resolve'],
      alternateActions: const ['Update request', 'Withdraw'],
    );
  }
  if (id.contains('approval') ||
      id.contains('decision') ||
      id.contains('architectural') ||
      id.contains('request')) {
    return _b25SurfaceSpec(
      workflowId: workflowId,
      cardSurfaceFamily: 'approval',
      apiContract: 'CommunityApprovalApi',
      requiredInteractions: const [
        'submitRequest',
        'assignReviewer',
        'approve',
        'reject',
        'requestChanges',
        'comment',
        'statusHistory',
        'reopen',
        'appeal',
        'notifyRequester',
      ],
      primaryActions: const ['Approve', 'Reject', 'Request changes'],
      alternateActions: const ['Comment', 'Reopen', 'Appeal'],
    );
  }
  if (id.contains('document') ||
      id.contains('facility') ||
      id.contains('reservation') ||
      id.contains('roster')) {
    return _b25SurfaceSpec(
      workflowId: workflowId,
      cardSurfaceFamily: 'operations',
      apiContract: 'CommunityOperationsSurfaceApi',
      requiredInteractions: const [
        'listDocuments',
        'openDocument',
        'downloadDocument',
        'acknowledgeDocument',
        'requestAccess',
        'documentVersions',
        'reserveFacility',
        'updateReservation',
        'cancelReservation',
        'resolveConflict',
        'getRoster',
        'updateRosterMember',
        'rosterHistory',
      ],
      primaryActions: const ['Open', 'Reserve', 'Acknowledge'],
      alternateActions: const ['Cancel reservation', 'Request access'],
    );
  }
  if (id.contains('search') ||
      id.contains('digest') ||
      id.contains('citation')) {
    return _b25SurfaceSpec(
      workflowId: workflowId,
      cardSurfaceFamily: 'knowledge',
      apiContract: 'CommunityKnowledgeSurfaceApi',
      requiredInteractions: const [
        'search',
        'answerQuestion',
        'listCitations',
        'openCitation',
        'saveDigest',
        'shareDigest',
        'refreshIndex',
        'staleCitationCheck',
        'visibilityDecision',
      ],
      primaryActions: const ['Search', 'Open citation', 'Save digest'],
      alternateActions: const ['Share', 'Refresh index'],
    );
  }
  if (id.contains('export') ||
      id.contains('import') ||
      id.contains('transfer') ||
      id.contains('redaction') ||
      id.contains('rollback') ||
      id.contains('checksum')) {
    return _b25SurfaceSpec(
      workflowId: workflowId,
      cardSurfaceFamily: 'portability',
      apiContract: 'CommunityPortabilitySurfaceApi',
      requiredInteractions: const [
        'createExportPlan',
        'previewRedaction',
        'generateExport',
        'downloadExport',
        'verifyChecksum',
        'cancelExport',
        'retryExport',
        'startTransfer',
        'verifyTransfer',
        'rollbackTransfer',
        'auditTrail',
      ],
      primaryActions: const ['Generate export', 'Download', 'Start transfer'],
      alternateActions: const ['Preview redaction', 'Cancel', 'Retry'],
    );
  }
  if (id.contains('invite') ||
      id.contains('connection') ||
      id.contains('social')) {
    return _b25SurfaceSpec(
      workflowId: workflowId,
      cardSurfaceFamily: 'social',
      apiContract: 'CommunitySocialSurfaceApi',
      requiredInteractions: const [
        'sendInvite',
        'acceptInvite',
        'declineInvite',
        'cancelInvite',
        'block',
        'unblock',
        'mute',
        'archive',
        'connectionStatus',
        'createThread',
        'reply',
        'markRead',
      ],
      primaryActions: const ['Invite', 'Accept', 'Reply'],
      alternateActions: const ['Decline', 'Block', 'Mute'],
    );
  }
  if (_isAdSurfaceWorkflow(id) || id.contains('sponsor')) {
    return _b25SurfaceSpec(
      workflowId: workflowId,
      cardSurfaceFamily: 'ad',
      apiContract: 'CommunityAdSurfaceApi',
      requiredInteractions: const [
        'requestAdDecision',
        'recordImpression',
        'recordClick',
        'recordNoFill',
        'getNoFillReason',
        'getDisclosure',
        'getAdOffEntitlement',
        'suppressAds',
        'restoreAds',
        'receiptEvidence',
      ],
      primaryActions: const ['Open sponsor', 'Turn off ads'],
      alternateActions: const ['Restore ads', 'View disclosure'],
    );
  }
  return _b25SurfaceSpec(
    workflowId: workflowId,
    cardSurfaceFamily: 'form',
    apiContract: 'CommunityFormSurfaceApi',
    requiredInteractions: const [
      'loadForm',
      'validateDraft',
      'saveDraft',
      'submitForm',
      'updateSubmission',
      'withdrawSubmission',
      'routeProtectedFields',
      'reviewSubmission',
      'exportSubmission',
    ],
    primaryActions: const ['Save draft', 'Submit', 'Update'],
    alternateActions: const ['Withdraw', 'Review'],
  );
}

JsonMap _b25SurfaceSpec({
  required String workflowId,
  required String cardSurfaceFamily,
  required String apiContract,
  required List<String> requiredInteractions,
  required List<String> primaryActions,
  required List<String> alternateActions,
}) {
  return <String, Object?>{
    'workflowId': workflowId,
    'registryStatus': 'advisory-non-gating',
    'cardSurfaceFamily': cardSurfaceFamily,
    'apiContract': apiContract,
    'requiredInteractions': requiredInteractions,
    'primaryActions': primaryActions,
    'alternateActions': alternateActions,
    'rendererTarget':
        'Demo App renderer selected by workflow ID and surface family',
    'fakeBackendSupport':
        'LocalInAppBackend imports the initialization package, stores workflow state, records role-specific receipts, and exposes surface state to the Demo App.',
  };
}

List<JsonMap> _b25CriterionReferencePatterns(String criterionId) {
  switch (criterionId) {
    case 'b25-c02-community-product-docs-complete':
      return _referencePatternsForType('modern-mobile-product');
    case 'b25-c03-production-grade-experience':
    case 'b25-c04-modern-intentional-ui':
    case 'b25-c05-community-content-ia':
    case 'b25-c09-no-layout-production-defects':
      return _referencePatternsForType('modern-mobile-product');
    case 'b25-c06-domain-native-primary-surfaces':
    case 'b25-c13-workflow-lifecycle-complete':
      return _referencePatternsForType('domain-native-surface');
    case 'b25-c08-visible-text-specific-critique':
      return _referencePatternsForType('evidence-critique');
    default:
      return _referencePatternsForType('modern-mobile-product');
  }
}

List<String> _b25CriterionReferenceQueries(String criterionId) {
  switch (criterionId) {
    case 'b25-c02-community-product-docs-complete':
      return <String>[
        'community app product requirements roles jobs to be done template',
        'mobile community app information architecture announcements events messages examples',
        'product experience specification domain native surfaces workflow mapping examples',
      ];
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
    case 'b25-c13-workflow-lifecycle-complete':
      return <String>[
        'mobile app workflow lifecycle UI states primary secondary actions examples',
        'event RSVP decline change response mobile UI pattern',
        'mobile form review confirmation receipt receiver state UX examples',
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
    'State which pattern is being copied or adapted and why it matches the target role task.',
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
              'Critique must quote visible UI/text, name the role and task, compare against the chosen reference pattern, and state the exact fix.',
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

bool _sameStringList(List<String> actual, List<String> expected) {
  if (actual.length != expected.length) {
    return false;
  }
  for (var index = 0; index < expected.length; index += 1) {
    if (actual[index] != expected[index]) {
      return false;
    }
  }
  return true;
}

List<String> _resolveB25ScreenRowIds(
  Iterable<String> references,
  List<String> rowIds,
) {
  final resolved = <String>{};
  for (final raw in references) {
    final value = raw.trim();
    if (value.isEmpty) {
      continue;
    }
    if (rowIds.contains(value)) {
      resolved.add(value);
      continue;
    }
    final prefixMatches = rowIds.where(
      (rowId) => rowId.startsWith('$value-') || rowId.startsWith(value),
    );
    resolved.addAll(prefixMatches);
  }
  return resolved.toList();
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
    case 'b25-c02-community-product-docs-complete':
      return 'B25 is trying to judge production UX without a complete community-specific product experience spec for every reviewed community/test app.';
    case 'b25-c03-production-grade-experience':
      return 'The evidence does not prove that target users experience the app as a real production community product rather than a workflow validation harness.';
    case 'b25-c04-modern-intentional-ui':
      return 'The evidence does not prove that the UI is modern, visually intentional, easy to navigate, and appealing for the target roles.';
    case 'b25-c05-community-content-ia':
      return 'The evidence does not prove that primary screens are organized around community content and jobs-to-be-done instead of workflow lists or validation surfaces.';
    case 'b25-c06-domain-native-primary-surfaces':
      return 'The evidence does not prove that each primary workflow/role UI is a domain-native product surface rather than a generic card, checklist modal, or metadata page.';
    case 'b25-c13-workflow-lifecycle-complete':
      return 'The evidence does not prove that each workflow/role UI implements the full production lifecycle. Cards may expose a single accept/cancel action without the decision context, alternate choices, result state, or receiver/continuation state real users need.';
    case 'b25-c14-llm-vision-ux-review':
      return 'The current B25 pass lacks a passing fresh-context LLM vision UX judgment, or that judgment found major product-quality issues in the screenshots.';
    case 'b25-c15-full-b25-capture-coverage':
      return 'The current B25 evidence was not generated from a commit-eligible full B12-B20 screenshot capture, so the pass may be judging only a targeted remediation subset.';
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
    case 'b25-c02-community-product-docs-complete':
      return 'The desired product experience was described only through workflows/screenshots after implementation, so the UI worker lacked a rich community product target to build against.';
    case 'b25-c03-production-grade-experience':
      return 'The pass has evidence capture, but not a completed independent product-quality judgment grounded in screenshots.';
    case 'b25-c04-modern-intentional-ui':
      return 'The pass lacks screenshot-backed judgment of hierarchy, spacing, navigation clarity, component polish, and visual identity.';
    case 'b25-c05-community-content-ia':
      return 'The app may still be organized around implementation/workflow concepts instead of the mental model and daily jobs of community users.';
    case 'b25-c06-domain-native-primary-surfaces':
      return 'Primary workflow surfaces may still rely on generic repeated cards or validation-state UI instead of task-specific product screens.';
    case 'b25-c13-workflow-lifecycle-complete':
      return 'The product experience was modeled as completed workflows rather than lifecycle-complete user tasks, so the UI can appear polished while still missing required fields, negative/change actions, and durable post-action states.';
    case 'b25-c14-llm-vision-ux-review':
      return 'The previous B25 gate let deterministic absence-of-known-defects stand in for semantic visual/product review. The visible screenshots still need a fresh LLM judge to inspect pixels, layout, content, and product fit.';
    case 'b25-c15-full-b25-capture-coverage':
      return 'The screenshot capture pipeline allowed a targeted phase recapture to become the aggregate artifact consumed by B25, so downstream collectors could narrow the review without an explicit full-coverage failure.';
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
    case 'b25-c02-community-product-docs-complete':
      return 'Each reviewed community should have a Product Docs V2 experience spec that defines the product promise, roles/jobs, IA, home experience, domain-native surfaces, workflow mappings, role states, seed content, visual standard, and B25 review log before UI remediation starts.';
    case 'b25-c03-production-grade-experience':
      return 'A target user should immediately understand the community, see relevant content, and complete meaningful tasks without recognizing the app as a test harness.';
    case 'b25-c04-modern-intentional-ui':
      return 'Screens should feel intentionally designed, polished, readable, well-spaced, navigable, and visually coherent on the reviewed device.';
    case 'b25-c05-community-content-ia':
      return 'The home and primary flows should lead with community-specific sections, content, and jobs-to-be-done rather than implementation categories.';
    case 'b25-c06-domain-native-primary-surfaces':
      return 'Each primary workflow should use the product surface a real app would use for that job, such as an event detail, feed item, donation flow, care form, review queue, thread, receipt, search result, export wizard, or transfer status screen.';
    case 'b25-c13-workflow-lifecycle-complete':
      return 'Each workflow/role surface should show the concrete object, decision information, natural primary and alternate actions, persistent result/receipt/status, and receiver/continuation state expected in a production app.';
    case 'b25-c14-llm-vision-ux-review':
      return 'A fresh LLM vision UX judge should be able to inspect the screenshots and state, from visible UI evidence, that the experience is modern, domain-native, and production-grade with no unresolved blocker or major findings.';
    case 'b25-c15-full-b25-capture-coverage':
      return 'Every committed B25 pass must start from a canonical full B12-B20 capture, validated by `b25_capture_coverage_gate.dart`, with targeted captures kept as non-committable precheck diagnostics only.';
    case 'b25-c08-visible-text-specific-critique':
      return 'Every row should tell a worker exactly what was visible, why it did or did not work for the role/task, and what must change.';
    case 'b25-c09-no-layout-production-defects':
      return 'The reviewed UI should have no major overlap, clipping, crowding, default scaffold feel, repeated-card primary UX, checklist-modal primary UX, or thin placeholder content.';
    case 'b25-c01-no-blocker-major':
    default:
      return 'The next B25 pass should show zero unresolved blocker/major findings and a scorecard that can close the phase.';
  }
}

List<String> _uxPrinciplesForB25Criterion(String criterionId) {
  switch (criterionId) {
    case 'b25-c02-community-product-docs-complete':
      return <String>[
        'Define the target product before judging screenshots.',
        'Make UI remediation traceable to community-specific roles, jobs-to-be-done, and domain-native surfaces.',
        'Do not let workflow implementation evidence substitute for product experience requirements.',
      ];
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
    case 'b25-c13-workflow-lifecycle-complete':
      return <String>[
        'Workflows are product lifecycles, not one-shot checklist actions',
        'Users need enough information to decide before acting',
        'Production affordances include alternate choices, change/revoke paths, and clear result states when the domain requires them',
        'Receiver and continuation states are first-class UX, not hidden backend assertions',
      ];
    case 'b25-c14-llm-vision-ux-review':
      return <String>[
        'Semantic product-quality judgment must come from screenshot inspection, not deterministic keyword absence',
        'A production UX pass needs visible proof that screens feel modern, domain-native, and useful to the target role',
        'LLM reviewer findings are blocking inputs to the normal B25 ticket and remediation loop',
      ];
    case 'b25-c15-full-b25-capture-coverage':
      return <String>[
        'Canonical review evidence must be complete before subjective judgment starts',
        'Targeted recaptures are useful diagnostics but cannot close a production UX phase',
        'Every new or improved screen must be reflected in a full capture before an iteration commit',
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
    case 'b25-c02-community-product-docs-complete':
      final productDocFindings = allBlockingFindingIds
          .where((id) => id == 'B25-COMMUNITY-PRODUCT-DOCS-INCOMPLETE')
          .toList();
      return productDocFindings.isEmpty
          ? allBlockingFindingIds
          : productDocFindings;
    case 'b25-c15-full-b25-capture-coverage':
      final fullCoverageFindings = allBlockingFindingIds
          .where((id) => id == 'B25-FULL-COVERAGE-INCOMPLETE')
          .toList();
      return fullCoverageFindings.isEmpty
          ? allBlockingFindingIds
          : fullCoverageFindings;
    case 'b25-c16-app-shell-capability-utilization':
      final appShellFindings = allBlockingFindingIds
          .where(
            (id) =>
                id.startsWith('B25-APP-SHELL-') ||
                id.startsWith('LLM-B25-APP-SHELL-') ||
                id.startsWith('LLM-B25-WR-APP-SHELL-'),
          )
          .toList();
      return appShellFindings.isEmpty
          ? allBlockingFindingIds
          : appShellFindings;
    case 'b25-c03-production-grade-experience':
    case 'b25-c04-modern-intentional-ui':
    case 'b25-c05-community-content-ia':
    case 'b25-c09-no-layout-production-defects':
      final holisticFindings = allBlockingFindingIds
          .where(
            (id) =>
                id == 'B25-HOLISTIC-UX-FAILED' ||
                id == 'B25-SCREEN-SPECIFIC-CRITIQUE-INCOMPLETE' ||
                id == 'B25-WORKFLOW-ROLE-COVERAGE-INCOMPLETE',
          )
          .toList();
      return holisticFindings.isEmpty
          ? allBlockingFindingIds
          : holisticFindings;
    case 'b25-c06-domain-native-primary-surfaces':
    case 'b25-c13-workflow-lifecycle-complete':
    case 'b25-c08-visible-text-specific-critique':
    case 'b25-c14-llm-vision-ux-review':
      final workflowFindings = allBlockingFindingIds
          .where(
            (id) =>
                id.startsWith('LLM-UX-') ||
                id == 'B25-WORKFLOW-ROLE-UX-FAILED' ||
                id == 'B25-WORKFLOW-LIFECYCLE-INCOMPLETE' ||
                id == 'B25-WORKFLOW-ROLE-COVERAGE-INCOMPLETE' ||
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
    case 'b25-c02-community-product-docs-complete':
      return <String>[
        'Create or update one community product experience doc per reviewed community/test app under `docs/Product Docs V2/Community Examples/`.',
        'Use all ten B25 community product experience sections and remove placeholders or thin generic copy.',
        'Map each workflow/role to a domain-native product surface and B25 acceptance evidence before assigning UI remediation.',
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
        'Review every primary workflow/role row and classify the visible UI as domain-native, secondary-supporting, or generic.',
        'Replace primary generic cards, checklist modals, metadata pages, or repeated card shells with domain-specific product surfaces.',
        'Create workflow/role scorecards proving each primary workflow surface is domain-native for its target role.',
      ];
    case 'b25-c13-workflow-lifecycle-complete':
      return <String>[
        'For every failed lifecycle scorecard, add the missing lifecycle groups named in the ticket.',
        'Update the community product doc workflow section first when the correct lifecycle is ambiguous.',
        'Replace accept/cancel-only cards with product surfaces that include decision data, primary action, alternate/change/reject path, persistent result, and receiver/continuation state.',
        'Recapture entry/action/result/receiver screenshots and rerun the lifecycle judge.',
      ];
    case 'b25-c14-llm-vision-ux-review':
      return <String>[
        'Use the LLM vision judge screen reviews as the source of truth for what visually failed.',
        'Replace any screenshot-identified workflow/test-harness surfaces with domain-native product surfaces.',
        'Fix all LLM-UX blocker/major findings, recapture screenshots, import a new LLM review artifact, and rerun the production judge.',
      ];
    case 'b25-c15-full-b25-capture-coverage':
      return <String>[
        'Run `b25_capture_workflow_screenshots.dart --mode full-b25` so B12-B20 are all refreshed in the canonical aggregate.',
        'Run `b25_capture_coverage_gate.dart` and keep its report with the pass evidence.',
        'Do not commit a B25 pass based on `--mode targeted-precheck` output; rerun the collector and judges from the full aggregate.',
      ];
    case 'b25-c16-app-shell-capability-utilization':
      return <String>[
        'Do not close the ticket from source-code intent alone; require after-screenshots proving the App Shell capability is actually visible and usable.',
        'Do not treat bottom tabs, pinning policy, or minimized cards as present unless the relevant role/workflow screenshot or product doc proves them.',
        'Do not require pinned surfaces for every tab; require an explicit `none` policy with rationale when pinning is not useful.',
        'Do not accept a generic card list when Product Docs or the App Shell component doc require tabs, declared pinned surfaces, presentation states, renderer selection, or theme/customization proof.',
      ];
    case 'b25-c08-visible-text-specific-critique':
      return <String>[
        'Extract visible text for every reviewed screenshot row.',
        'Write a non-boilerplate critique for every row that names visible UI elements, visible text, the role, and the user task.',
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
    case 'b25-c02-community-product-docs-complete':
      return <String>[
        'docs/Product Docs V2/Community Examples/<community>-product-experience.md',
        'independent-production-ux-review.json productDocCoverage',
        'independent-production-ux-review.md community product experience docs table',
        'production-ux-criteria-scorecard.json/.md',
      ];
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
        'independent-production-ux-review.json workflowRoleScorecards',
        'independent-production-ux-review.json screenRows',
        'product-ux-screen-review-matrix.md every workflow/role row',
        'production-ux-criteria-scorecard.json/.md',
      ];
    case 'b25-c13-workflow-lifecycle-complete':
      return <String>[
        'independent-production-ux-review.json workflowLifecycleScorecards',
        'independent-production-ux-review.json screenRows',
        'b25-workflow-lifecycle-scorecards.md',
        'production-ux-criteria-scorecard.json/.md',
      ];
    case 'b25-c14-llm-vision-ux-review':
      return <String>[
        'independent-production-ux-review.json llmVisionReview',
        'independent-production-ux-review.json findings from source=llm-vision-ux-judge',
        'product-ux-screen-review-matrix.md affected screen rows',
        'production-ux-criteria-scorecard.json/.md',
      ];
    case 'b25-c15-full-b25-capture-coverage':
      return <String>[
        'B20/all-workflow-ui-evidence.json',
        'b25-capture-coverage-report.json',
        'independent-production-ux-review.json reviewInputEvidence.captureCoverage',
        'production-ux-criteria-scorecard.json/.md',
      ];
    case 'b25-c16-app-shell-capability-utilization':
      return <String>[
        'independent-production-ux-review.json appShellCapabilityReview',
        'llm-product-doc-workflow-reconciliation-<run-id>.json appShellCapabilityReview',
        'llm-product-doc-workflow-reconciliation-<run-id>.json reviewedComponentDocPaths and componentDocReview.docs',
        'docs/Product Docs V2/Community Examples/<community>-product-experience.md Section 3.1',
        'docs/Build Plan V2/Skill/components/card-surfaces/app-shell-navigation-theming.md',
        'docs/Build Plan V2/Skill/components/card-surfaces/tab-renderer-contracts.md',
        'product-ux-screen-review-matrix.md affected screen rows and screenshots',
        'production-ux-criteria-scorecard.json/.md',
      ];
    case 'b25-c17-component-doc-freshness':
      return <String>[
        'b25-component-doc-context-<run-id>.json/.md',
        'llm-product-doc-workflow-reconciliation-<run-id>.json reviewedComponentDocPaths',
        'llm-product-doc-workflow-reconciliation-<run-id>.json componentDocReview.docs',
        'docs/Build Plan V2/Skill/components/card-surfaces/README.md',
        'docs/Build Plan V2/Skill/components/card-surfaces/app-shell-navigation-theming.md',
        'docs/Build Plan V2/Skill/components/card-surfaces/tab-renderer-contracts.md',
        'git log -1 --format=%H -- <component-doc-path>',
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
    case 'b25-c02-community-product-docs-complete':
      return <String>[
        'Product doc coverage rows for every reviewed community/test app.',
        'Updated Product Docs V2 community experience docs with hashes, paths, required sections, and no placeholders.',
        'B25 review/remediation log entries showing the current screenshots will be judged against each product spec.',
      ];
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
        'Use B21 production UX contracts to choose the target surface type for each workflow/role pair.',
        'Update screenshot evidence manifests so each replaced surface is captured at entry, action, and result states.',
      ];
    case 'b25-c13-workflow-lifecycle-complete':
      return <String>[
        'Inspect workflow surface builders and identify where current UI collapses lifecycle into a single action card.',
        'For each failed lifecycle scorecard, implement missing object/context, decision data, primary and alternate actions, result/receipt/status, and receiver/continuation state.',
        'Update product docs, seed data, widget tests, and B25 evidence expectations so the lifecycle is documented and screenshot-proven.',
      ];
    case 'b25-c14-llm-vision-ux-review':
      return <String>[
        'Treat the imported LLM vision review as the independent semantic critique.',
        'Prioritize screen rows and workflows named in `llmVisionReview.findings` and `llmVisionReview.screenReviews`.',
        'Do not close the ticket until a fresh LLM vision review over after-screenshots passes.',
      ];
    case 'b25-c15-full-b25-capture-coverage':
      return <String>[
        'Treat this as evidence-pipeline repair, not UI remediation.',
        'Use `--mode targeted-precheck` only for local diagnostics during a pass; it must not rewrite `B20/all-workflow-ui-evidence.json`.',
        'Before the iteration commit, rerun the full capture and ensure `reviewInputEvidence.fullB25Coverage=true` and `commitEligible=true`.',
      ];
    case 'b25-c16-app-shell-capability-utilization':
      return <String>[
        'Inspect `apps/loom_communities_demo/lib/main.dart` for `CommunityAppShellCustomizationSpec`, role tab specs, pinned surface specs, presentation-state routing, renderer selection, and theme/typography/density tokens.',
        'Update the community product experience doc Section 3.1 when the intended tab/pinning/presentation/customization model is missing or vague.',
        'Implement the missing App Shell capability in the central shell model, not as a one-off workflow hack.',
        'Recapture screenshots proving Home and Messages/Communication tabs, custom role tabs, declared pinned surfaces, minimized/medium/expanded states, tap-to-expand, community-list states, renderer selection, and theme/customization tokens where required.',
      ];
    case 'b25-c17-component-doc-freshness':
      return <String>[
        'Run `b25_component_doc_context.dart` before the LLM reconciliation pass and provide its JSON to the LLM.',
        'Regenerate `productDocWorkflowReconciliation` so `componentDocReview.docs[]` includes path, sha256, gitLastCommitSha, gitStatus, reviewedThisRun=true, semanticSummary, and semanticImplicationsForCommunities for each required component doc.',
        'If a component doc changed since the prior B25 pass, ensure the LLM explains the semantic delta and records required community/product-doc/UI updates.',
        'Rerun `production_ux_judge.dart` so the current repo hashes and git metadata are checked against the LLM artifact.',
      ];
    case 'b25-c08-visible-text-specific-critique':
      return <String>[
        'Update the B25 judge/review artifact, not only app UI code.',
        'Fill `screenRows[].visibleTextExtract`, `screenRows[].screenSpecificCritique`, `holisticQuestionAnswers`, and `workflowRoleScorecards` with screenshot-specific content.',
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
    case 'b25-c13-workflow-lifecycle-complete':
    case 'b25-c14-llm-vision-ux-review':
    case 'b25-c16-app-shell-capability-utilization':
    case 'b25-c17-component-doc-freshness':
      return <String>[
        'Write copy that matches the task: RSVP, donate, publish, approve, submit, review, search, export, transfer, invite, or reply.',
        'Each primary surface should include the domain data a user needs to decide and act.',
        'Use explicit alternate action copy such as Decline, Request changes, Change response, Edit, Withdraw, Cancel RSVP, Archive, Retry, Roll back, or Manage where the lifecycle requires it.',
        'Use result copy that persists: Sent, Posted, Confirmed, Paid, Receipt ready, Submitted, Approved, Rejected, Claimed, Returned, Read, or equivalent domain state.',
      ];
    case 'b25-c08-visible-text-specific-critique':
      return <String>[
        'Quote or summarize visible labels, headings, section names, action text, and result copy in the critique.',
        'Explain why that visible content does or does not support the role and task.',
      ];
    default:
      return <String>[
        'Replace placeholder, framework, workflow, evidence, or metadata language with user-facing product copy.',
        'Use content that helps the target role understand status, options, consequences, and next steps.',
      ];
  }
}

List<String> _visualGuidanceForB25Criterion(String criterionId) {
  switch (criterionId) {
    case 'b25-c04-modern-intentional-ui':
    case 'b25-c14-llm-vision-ux-review':
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
    case 'b25-c02-community-product-docs-complete':
      return <String>[
        'Product doc coverage rows for every reviewed community/test app.',
        'Updated Product Docs V2 community experience docs with hashes, paths, required sections, and no placeholders.',
        'B25 review/remediation log entries showing the current screenshots will be judged against each product spec.',
      ];
    case 'b25-c17-component-doc-freshness':
      return <String>[
        'b25-component-doc-context-<run-id>.json and .md generated from the current repo.',
        'productDocWorkflowReconciliation.componentDocReview.docs[] with current path/hash/git metadata and semantic review fields.',
        'If component docs changed, semantic delta and required community/tab/surface updates in the reconciliation markdown.',
      ];
    case 'b25-c03-production-grade-experience':
    case 'b25-c04-modern-intentional-ui':
    case 'b25-c05-community-content-ia':
    case 'b25-c09-no-layout-production-defects':
    case 'b25-c14-llm-vision-ux-review':
      return <String>[
        'Fresh holistic screenshots for primary homes, navigation, representative detail surfaces, and representative completion/result states.',
        '`holisticQuestionAnswers` with visible evidence, score, pass/fail answer, and specific rationale.',
        '`llmVisionReview` imported from a fresh LLM vision UX judge run against the after screenshots.',
        'Updated `production-ux-criteria-scorecard.json/.md` showing the criterion passes.',
      ];
    case 'b25-c15-full-b25-capture-coverage':
      return <String>[
        '`B20/all-workflow-ui-evidence.json` with `captureMode=full-b25`, `fullB25Coverage=true`, and `commitEligible=true`.',
        '`b25-capture-coverage-report.json` with `status=pass`.',
        '`independent-production-ux-review.json reviewInputEvidence` showing all B12-B20 phases, at least nine workflow manifests, and fresh screenshot count above the threshold.',
      ];
    case 'b25-c06-domain-native-primary-surfaces':
      return <String>[
        'Fresh screenshots for every primary workflow/role surface that was replaced or reviewed.',
        '`workflowRoleScorecards` with task-specific domain-native surface judgments.',
        'Screen matrix rows showing `primarySurfaceType` or classification is not generic for primary workflows.',
      ];
    case 'b25-c13-workflow-lifecycle-complete':
      return <String>[
        'Fresh entry/action/result/receiver screenshots for every remediated workflow/role lifecycle.',
        '`workflowLifecycleScorecards` showing every required lifecycle group passes.',
        'Visible text excerpts proving object/context, decision information, primary action, alternate/change/reject affordance, persistent result state, and receiver/continuation state.',
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
    case 'b25-c02-community-product-docs-complete':
      return <String>[
        'Do not use screenshots alone as the source of truth for desired product experience.',
        'Do not proceed to UI remediation when a reviewed community has no product experience spec.',
        'Do not satisfy this criterion with a generic template that could apply unchanged to another community.',
      ];
    case 'b25-c03-production-grade-experience':
    case 'b25-c04-modern-intentional-ui':
    case 'b25-c05-community-content-ia':
    case 'b25-c09-no-layout-production-defects':
      return <String>[
        'Holistic direct-question answers are present, screenshot-backed, non-boilerplate, and pass.',
        ...shared,
      ];
    case 'b25-c06-domain-native-primary-surfaces':
    case 'b25-c13-workflow-lifecycle-complete':
    case 'b25-c08-visible-text-specific-critique':
      return <String>[
        'Every workflow/role scorecard is present, screenshot-backed, non-boilerplate, and pass.',
        if (criterionId == 'b25-c13-workflow-lifecycle-complete')
          'Every workflow lifecycle scorecard is present, screenshot-backed, and pass with no missing lifecycle groups.',
        ...shared,
      ];
    case 'b25-c01-no-blocker-major':
      return <String>[
        'Unresolved blocker and major finding counts are both zero.',
        ...shared,
      ];
    case 'b25-c15-full-b25-capture-coverage':
      return <String>[
        '`b25_capture_coverage_gate.dart` exits 0.',
        '`reviewInputEvidence.captureMode` is `full-b25`.',
        '`reviewInputEvidence.commitEligible` and `reviewInputEvidence.fullB25Coverage` are both true.',
        '`reviewInputEvidence.capturedPhases` is exactly B12,B13,B14,B15,B16,B17,B18,B19,B20.',
        '`reviewInputEvidence.screenshotCount` is at least $fullB25MinimumScreenshotRows and generated from the current app commit.',
      ];
    case 'b25-c16-app-shell-capability-utilization':
      return <String>[
        '`appShellCapabilityReview.status` is `pass`.',
        '`appShellCapabilityReview.missingCapabilities` is empty.',
        'Every `appShellCapabilityReview.communityResults[]` row has passing tabs, explicit and appropriate pinning policy, presentation states, community-list states, theme customization, and renderer-selection checks where applicable.',
        'After-screenshots prove the shell capability in the affected community/role/workflow, not only source-code declarations.',
        ...shared,
      ];
    case 'b25-c17-component-doc-freshness':
      return <String>[
        '`b25_component_doc_context.dart` generated current hashes and git metadata for required component docs.',
        '`productDocWorkflowReconciliation.reviewedComponentDocPaths` includes README, app-shell-navigation-theming, and tab-renderer-contracts.',
        '`componentDocReview.docs[]` has matching `sha256`, `gitLastCommitSha`, `gitStatus`, `reviewedThisRun=true`, `semanticSummary`, and `semanticImplicationsForCommunities` for each required doc.',
        '`production_ux_judge.dart` has no blocking failure for b25-c17.',
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
    'dart run packages/tooling/loom_ux_judges/bin/b25_capture_workflow_screenshots.dart --mode full-b25 --device emulator-5554 --evidence-root ../docs/Build\\ Plan\\ V2/Evidence',
    'dart run packages/tooling/loom_ux_judges/bin/b25_capture_coverage_gate.dart --evidence-root ../docs/Build\\ Plan\\ V2/Evidence --output ../docs/Build\\ Plan\\ V2/Evidence/B25/b25-capture-coverage-report.json',
    'dart run packages/tooling/loom_ux_judges/bin/b25_evidence_collector.dart --evidence-root ../docs/Build\\ Plan\\ V2/Evidence --repo-root .. --run-id <next-run-id> --prior-review ../docs/Build\\ Plan\\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\\ Plan\\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\\ Plan\\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\\ Plan\\ V2/Evidence/B25/product-ux-screen-review-matrix.md',
    'dart run packages/tooling/loom_ux_judges/bin/b25_workflow_role_coverage_collector.dart --input ../docs/Build\\ Plan\\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\\ Plan\\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\\ Plan\\ V2/Evidence/B25/workflow-role-coverage-matrix.md',
    'dart run packages/tooling/loom_ux_judges/bin/b25_independent_ux_judge.dart --input ../docs/Build\\ Plan\\ V2/Evidence/B25/independent-production-ux-review.json --output ../docs/Build\\ Plan\\ V2/Evidence/B25/independent-production-ux-review.json --markdown-output ../docs/Build\\ Plan\\ V2/Evidence/B25/independent-production-ux-review.md --matrix-output ../docs/Build\\ Plan\\ V2/Evidence/B25/product-ux-screen-review-matrix.md',
    'dart run packages/tooling/loom_ux_judges/bin/b25_component_doc_context.dart --repo-root .. --output ../docs/Build\\ Plan\\ V2/Evidence/B25/b25-component-doc-context-<next-run-id>.json --markdown-output ../docs/Build\\ Plan\\ V2/Evidence/B25/b25-component-doc-context-<next-run-id>.md',
    'dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input ../docs/Build\\ Plan\\ V2/Evidence/B25/independent-production-ux-review.json --base .. --output ../docs/Build\\ Plan\\ V2/Evidence/B25/production-ux-criteria-scorecard.json --markdown-output ../docs/Build\\ Plan\\ V2/Evidence/B25/production-ux-criteria-scorecard.md --tickets-output ../docs/Build\\ Plan\\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.json --tickets-markdown-output ../docs/Build\\ Plan\\ V2/Evidence/B25/b25-remediation-tickets-<next-run-id>.md',
    'dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review ../docs/Build\\ Plan\\ V2/Evidence/B25/independent-production-ux-review.json --judge ../docs/Build\\ Plan\\ V2/Evidence/B25/production-ux-criteria-scorecard.json --previous ../docs/Build\\ Plan\\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --output ../docs/Build\\ Plan\\ V2/Evidence/B25/b25-iteration-scorecard-latest.json --markdown-output ../docs/Build\\ Plan\\ V2/Evidence/B25/b25-iteration-scorecard-latest.md',
  ];
}

String _questionFor(CriterionDefinition definition) {
  return definition.question ?? definition.title;
}

_DerivedFailure? _failOnProductDocCoverage(JsonMap evidence) {
  final coverage = _asMapList(evidence['productDocCoverage']);
  if (coverage.isEmpty) {
    return _DerivedFailure(
      score: 0,
      message:
          'No productDocCoverage rows were supplied; B25 cannot judge production UX without community-specific Product Docs V2 experience specs.',
    );
  }
  final failing = coverage
      .where((row) => _asString(row['status']) != 'pass')
      .toList();
  if (failing.isNotEmpty) {
    return _DerivedFailure(
      score: 45,
      message:
          'Community product experience docs are missing or not review-ready: ${failing.map((row) => _asString(row['productDocId'], fallback: _asString(row['communityName']))).join(', ')}.',
      evidenceUsed: failing
          .map((row) => _asString(row['productDocId']))
          .where((id) => id.isNotEmpty)
          .toList(),
    );
  }
  return null;
}

const List<String> _requiredComponentDocPaths = <String>[
  'docs/Build Plan V2/Skill/components/card-surfaces/README.md',
  'docs/Build Plan V2/Skill/components/card-surfaces/app-shell-navigation-theming.md',
  'docs/Build Plan V2/Skill/components/card-surfaces/tab-renderer-contracts.md',
];

_DerivedFailure? _failOnComponentDocFreshnessReview(
  JsonMap evidence,
  String basePath,
) {
  final reconciliation =
      evidence['productDocWorkflowReconciliation'] as JsonMap?;
  if (reconciliation == null || reconciliation.isEmpty) {
    return _DerivedFailure(
      score: 0,
      message:
          'No productDocWorkflowReconciliation artifact was supplied; B25 cannot prove the LLM reread current component docs.',
    );
  }
  final contextSource =
      evidence['componentDocContext'] ??
      reconciliation['componentDocContext'] ??
      reconciliation['componentDocMetadata'];
  final contextRows = contextSource is JsonMap
      ? _asMapList(contextSource['docs'])
      : _asMapList(contextSource);
  final reviewRows = _componentDocReviewRows(reconciliation);
  final reviewedPaths = <String>{
    for (final path in _asStringList(
      reconciliation['reviewedComponentDocPaths'],
    ))
      _normalizeComponentDocPath(basePath, path),
    for (final row in reviewRows)
      _normalizeComponentDocPath(
        basePath,
        _asString(row['path'] ?? row['componentDocPath']),
      ),
  }..remove('');
  final reviewByPath = <String, JsonMap>{
    for (final row in reviewRows)
      _normalizeComponentDocPath(
        basePath,
        _asString(row['path'] ?? row['componentDocPath']),
      ): row,
  }..remove('');
  final contextByPath = <String, JsonMap>{
    for (final row in contextRows)
      _normalizeComponentDocPath(
        basePath,
        _asString(row['path'] ?? row['componentDocPath']),
      ): row,
  }..remove('');

  final failures = <String>[];
  final evidenceUsed = <String>[];
  for (final requiredPath in _requiredComponentDocPaths) {
    final normalizedPath = _normalizeComponentDocPath(basePath, requiredPath);
    final resolved = _resolveRepoPath(basePath, normalizedPath);
    final file = File(_hostPath(resolved));
    if (!file.existsSync()) {
      failures.add('$normalizedPath is missing from disk.');
      continue;
    }
    final currentHash = _fileSha256(file.path);
    final currentLastCommit = _gitLastCommitShaForPath(
      basePath,
      normalizedPath,
    );
    final currentGitStatus = _gitStatusForPath(basePath, normalizedPath);
    final row = reviewByPath[normalizedPath];
    final contextRow = contextByPath[normalizedPath];
    final reviewed = reviewedPaths.contains(normalizedPath);
    evidenceUsed.add(normalizedPath);
    if (!reviewed || row == null) {
      failures.add('$normalizedPath was not reviewed by the LLM this run.');
      continue;
    }
    final reviewedThisRun = row['reviewedThisRun'] == true;
    if (!reviewedThisRun) {
      failures.add('$normalizedPath does not declare reviewedThisRun=true.');
    }
    final reviewedHash = _asString(
      row['sha256'] ?? row['contentSha256'] ?? row['fileSha256'] ?? row['hash'],
    );
    if (reviewedHash.isEmpty || reviewedHash != currentHash) {
      failures.add(
        '$normalizedPath hash mismatch: reviewed=$reviewedHash current=$currentHash.',
      );
    }
    final contextHash = _asString(
      contextRow?['sha256'] ??
          contextRow?['contentSha256'] ??
          contextRow?['fileSha256'] ??
          contextRow?['hash'],
    );
    if (contextRow != null &&
        contextHash.isNotEmpty &&
        contextHash != currentHash) {
      failures.add(
        '$normalizedPath component context hash mismatch: context=$contextHash current=$currentHash.',
      );
    }
    final reviewedLastCommit = _asString(
      row['gitLastCommitSha'] ??
          row['lastCommitSha'] ??
          row['lastModifiedCommitSha'],
    );
    if (!_shaMatches(reviewedLastCommit, currentLastCommit)) {
      failures.add(
        '$normalizedPath git last-commit mismatch: reviewed=$reviewedLastCommit current=$currentLastCommit.',
      );
    }
    final contextLastCommit = _asString(
      contextRow?['gitLastCommitSha'] ??
          contextRow?['lastCommitSha'] ??
          contextRow?['lastModifiedCommitSha'],
    );
    if (contextRow != null &&
        contextLastCommit.isNotEmpty &&
        !_shaMatches(contextLastCommit, currentLastCommit)) {
      failures.add(
        '$normalizedPath component context last-commit mismatch: context=$contextLastCommit current=$currentLastCommit.',
      );
    }
    final reviewedStatus = _asString(row['gitStatus']);
    if (reviewedStatus.isEmpty || reviewedStatus != currentGitStatus) {
      failures.add(
        '$normalizedPath git status mismatch: reviewed=$reviewedStatus current=$currentGitStatus.',
      );
    }
    final contextStatus = _asString(contextRow?['gitStatus']);
    if (contextRow != null &&
        contextStatus.isNotEmpty &&
        contextStatus != currentGitStatus) {
      failures.add(
        '$normalizedPath component context git status mismatch: context=$contextStatus current=$currentGitStatus.',
      );
    }
    final semanticSummary = _asString(
      row['semanticSummary'] ??
          row['semanticReviewSummary'] ??
          row['whatChangedSemantically'],
    );
    final semanticImplications = _asString(
      row['semanticImplicationsForCommunities'] ??
          row['semanticImplications'] ??
          row['communityUpdateImplications'],
    );
    if (semanticSummary.trim().length < 24) {
      failures.add('$normalizedPath lacks a substantive semantic summary.');
    }
    if (semanticImplications.trim().length < 24) {
      failures.add(
        '$normalizedPath lacks substantive semantic implications for community/tab/surface mapping.',
      );
    }
    final changedSincePriorRun =
        row['changedSincePriorRun'] == true ||
        row['hashChangedSincePriorRun'] == true ||
        row['docChangedSincePriorRun'] == true;
    if (changedSincePriorRun) {
      final delta = _asString(
        row['semanticDeltaSincePriorRun'] ??
            row['semanticChangeSummary'] ??
            row['requiredCommunityUpdates'],
      );
      if (delta.trim().length < 24) {
        failures.add(
          '$normalizedPath changed since the prior run but lacks a semantic delta/update summary.',
        );
      }
    }
  }
  final reviewStatus = _asString(
    reconciliation['componentDocReviewStatus'] ??
        (reconciliation['componentDocReview'] as JsonMap?)?['status'],
  );
  if (reviewStatus.isNotEmpty && reviewStatus != 'pass') {
    failures.add('componentDocReviewStatus is `$reviewStatus`, not pass.');
  }
  if (failures.isNotEmpty) {
    return _DerivedFailure(
      score: 20,
      message:
          'Component doc freshness/semantic review failed: ${failures.take(20).join(' ')}',
      evidenceUsed: evidenceUsed,
    );
  }
  return null;
}

List<JsonMap> _componentDocReviewRows(JsonMap reconciliation) {
  final rows = <JsonMap>[
    ..._asMapList(reconciliation['componentDocReviews']),
    ..._asMapList(reconciliation['reviewedComponentDocs']),
    ..._asMapList(reconciliation['componentDocReviewRows']),
  ];
  final componentDocReview = reconciliation['componentDocReview'];
  if (componentDocReview is JsonMap) {
    rows
      ..addAll(_asMapList(componentDocReview['docs']))
      ..addAll(_asMapList(componentDocReview['reviewedDocs']))
      ..addAll(_asMapList(componentDocReview['componentDocs']));
  }
  if (rows.isNotEmpty) {
    return rows;
  }

  final hashMap = <String, String>{};
  final hashes = reconciliation['reviewedComponentDocHashes'];
  if (hashes is JsonMap) {
    for (final entry in hashes.entries) {
      hashMap[_asString(entry.key)] = _asString(entry.value);
    }
  }
  final commitMap = <String, String>{};
  final commits = reconciliation['reviewedComponentDocGitLastCommitShas'];
  if (commits is JsonMap) {
    for (final entry in commits.entries) {
      commitMap[_asString(entry.key)] = _asString(entry.value);
    }
  }
  final statusMap = <String, String>{};
  final statuses = reconciliation['reviewedComponentDocGitStatuses'];
  if (statuses is JsonMap) {
    for (final entry in statuses.entries) {
      statusMap[_asString(entry.key)] = _asString(entry.value);
    }
  }
  return [
    for (final path in _asStringList(
      reconciliation['reviewedComponentDocPaths'],
    ))
      <String, Object?>{
        'path': path,
        'sha256': hashMap[path],
        'gitLastCommitSha': commitMap[path],
        'gitStatus': statusMap[path],
        'reviewedThisRun': reconciliation['reviewedComponentDocsThisRun'],
        'semanticSummary': '',
        'semanticImplicationsForCommunities': '',
      },
  ];
}

_DerivedFailure? _failOnAppShellCapabilityReview(JsonMap evidence) {
  final review =
      (evidence['appShellCapabilityReview'] as JsonMap?) ??
      ((evidence['productDocWorkflowReconciliation']
              as JsonMap?)?['appShellCapabilityReview']
          as JsonMap?);
  if (review == null || review.isEmpty) {
    return _DerivedFailure(
      score: 0,
      message:
          'No appShellCapabilityReview was supplied. B25 cannot prove the UI uses role tabs, pinned surfaces, minimized/medium/expanded states, tap-to-expand behavior, community-card presentation states, renderer selection, or theme/customization tokens.',
    );
  }
  final status = _asString(review['status']);
  final missingCapabilities = _asStringList(review['missingCapabilities']);
  final findings = _appShellCapabilityBlockingFindings(evidence);
  final communityResults = _asMapList(review['communityResults']);
  final failingCommunities = <String>[];
  for (final row in communityResults) {
    final failedChecks = _failedAppShellCapabilityChecks(row);
    if (_asString(row['status']) == 'fail' || failedChecks.isNotEmpty) {
      final community = _asString(row['communityName'], fallback: 'community');
      final role = _asString(row['role']);
      failingCommunities.add(
        role.isEmpty
            ? '$community (${failedChecks.join(',')})'
            : '$community/$role (${failedChecks.join(',')})',
      );
    }
  }
  final blockingFindings = findings
      .map(_findingId)
      .where((id) => id.isNotEmpty)
      .toList();
  if (status != 'pass' ||
      missingCapabilities.isNotEmpty ||
      blockingFindings.isNotEmpty ||
      failingCommunities.isNotEmpty) {
    return _DerivedFailure(
      score: 35,
      message:
          'App Shell capability utilization review failed. missingCapabilities=${missingCapabilities.join(', ')} failingCommunities=${failingCommunities.join('; ')} blockingFindings=${blockingFindings.join(', ')}.',
      evidenceUsed: <String>[
        ...missingCapabilities,
        ...failingCommunities,
        ...blockingFindings,
      ],
    );
  }
  return null;
}

List<String> _failedAppShellCapabilityChecks(JsonMap row) {
  final failed = <String>[];
  if (row['tabsPass'] != true) {
    failed.add('tabsPass');
  }
  if (_pinningPolicyFails(row)) {
    failed.add('pinningPolicyPass');
  }
  if (row['presentationStatesPass'] != true) {
    failed.add('presentationStatesPass');
  }
  if (row['mainCommunityCardStatesPass'] != true) {
    failed.add('mainCommunityCardStatesPass');
  }
  if (row['themeCustomizationPass'] != true) {
    failed.add('themeCustomizationPass');
  }
  if (row['rendererSelectionPass'] != true) {
    failed.add('rendererSelectionPass');
  }
  return failed;
}

bool _pinningPolicyFails(JsonMap row) {
  if (row['pinningPolicyPass'] == false) {
    return true;
  }
  final policy = _asString(row['pinningPolicy']);
  final rationale = _asString(row['pinningPolicyRationale']);
  final declaredPinnedIds = <String>{
    ..._asStringList(row['declaredPinnedSurfaceIds']),
    ..._asStringList(row['pinnedSurfaceIds']),
    ..._asStringList(row['pinnedWorkflowIds']),
  };
  final expectsPinned =
      row['pinnedSurfacesExpected'] == true ||
      row['pinnedSurfacesRequired'] == true ||
      declaredPinnedIds.isNotEmpty;
  if (expectsPinned) {
    return row['pinnedSurfacesPass'] != true;
  }
  final explicitlyNone =
      policy == 'none' ||
      policy == 'none-declared' ||
      policy == 'none-declared-for-tab' ||
      policy == 'none-declared-for-home' ||
      policy == 'none-with-rationale';
  if (explicitlyNone) {
    return rationale.trim().length < 12;
  }
  if (policy.isEmpty && row['pinnedSurfacesPass'] != true) {
    return true;
  }
  return false;
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
    final visibleEvidenceList = _asStringList(answer['visibleEvidence']);
    final visibleEvidence = visibleEvidenceList.isNotEmpty
        ? visibleEvidenceList.join(' ')
        : _asString(
            answer['visibleEvidence'] ??
                answer['evidence'] ??
                answer['visibleText'],
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

_DerivedFailure? _failOnLlmVisionReview(JsonMap evidence) {
  final review = evidence['llmVisionReview'];
  if (review is! JsonMap || review.isEmpty) {
    return _DerivedFailure(
      score: 0,
      message:
          'No LLM vision UX review artifact was imported. B25 cannot rely on deterministic keyword/pixel heuristics for semantic product-quality judgment.',
    );
  }
  final findings = _asMapList(review['findings']);
  final holisticAnswers = _asMapList(review['holisticQuestionAnswers']);
  final screenReviews = _asMapList(review['screenReviews']);
  final freshnessProblems = _b25LlmReviewFreshnessProblems(
    review: evidence,
    llmReview: review,
    runId: _asString(evidence['currentReviewRunId']),
    currentScreenRowIds: [
      for (final row in _asMapList(evidence['screenRows'])) _rowId(row),
    ],
  );
  if (freshnessProblems.isNotEmpty) {
    return _DerivedFailure(
      score: 0,
      message:
          'The LLM vision UX review is not fresh for this B25 pass: ${freshnessProblems.join(' ')}',
      evidenceUsed: freshnessProblems,
    );
  }
  final blockingFindings = findings
      .where((finding) => _isBlockingSeverity(finding) && !_isResolved(finding))
      .map(_findingId)
      .where((id) => id.isNotEmpty)
      .toList();
  final blockingQuestions = holisticAnswers
      .where(
        (answer) =>
            answer['blocksPass'] == true || _asInt(answer['score']) < 80,
      )
      .map((answer) => _asString(answer['questionId']))
      .where((id) => id.isNotEmpty)
      .toList();
  final blockingScreens = screenReviews
      .where(
        (row) =>
            row['blocksPass'] == true ||
            _asString(row['verdict']) == 'fail' ||
            _isBlockingSeverity(row),
      )
      .map((row) => _asString(row['screenRowId']))
      .where((id) => id.isNotEmpty)
      .toList();
  if (_asString(review['status']) != 'pass' ||
      blockingFindings.isNotEmpty ||
      blockingQuestions.isNotEmpty ||
      blockingScreens.isNotEmpty) {
    return _DerivedFailure(
      score: 35,
      message:
          'The LLM vision UX review failed from screenshot inspection. blockingFindings=${blockingFindings.join(', ')} blockingQuestions=${blockingQuestions.join(', ')} blockingScreens=${blockingScreens.join(', ')}.',
      evidenceUsed: <String>[
        ...blockingFindings,
        ...blockingQuestions,
        ...blockingScreens,
      ],
    );
  }
  if (holisticAnswers.isEmpty || screenReviews.isEmpty) {
    return _DerivedFailure(
      score: 0,
      message:
          'The LLM vision UX review is missing holistic answers or screen reviews.',
    );
  }
  final qualityProblems = _llmVisionReviewQualityProblems(
    llmReview: review,
    evidence: evidence,
  );
  if (qualityProblems.isNotEmpty) {
    return _DerivedFailure(
      score: 20,
      message:
          'The LLM vision UX review is too shallow to prove production UX quality: ${qualityProblems.take(80).join('; ')}.',
      evidenceUsed: qualityProblems.take(80).toList(),
    );
  }
  return null;
}

List<JsonMap> _appShellCapabilityBlockingFindings(JsonMap evidence) {
  final review =
      (evidence['appShellCapabilityReview'] as JsonMap?) ??
      ((evidence['productDocWorkflowReconciliation']
              as JsonMap?)?['appShellCapabilityReview']
          as JsonMap?) ??
      const <String, Object?>{};
  if (review.isEmpty) {
    return <JsonMap>[];
  }
  final findings = <JsonMap>[
    for (final finding in _asMapList(review['findings']))
      if (_isBlockingSeverity(finding) && !_isResolved(finding))
        JsonMap.of(finding),
  ];

  final communityResults = _asMapList(review['communityResults']);
  if (communityResults.isEmpty) {
    findings.add(
      _appShellCapabilityFinding(
        gapType: 'app-shell-tabs-gap',
        findingId: 'B25-APP-SHELL-NO-COMMUNITY-RESULTS',
        title: 'App Shell review has no community/role results',
        summary:
            'The App Shell capability review did not include community/role rows, so B25 cannot prove tabs, pinning, presentation states, renderer selection, or customization from screenshots.',
        requiredFix:
            'Regenerate the App Shell capability review with one row per reviewed community/role or per tab-renderer contract, including screenshot rows and hashes.',
      ),
    );
  }

  for (final row in communityResults) {
    final failed = _failedAppShellCapabilityChecks(row);
    if (failed.isEmpty && _asString(row['status']) != 'fail') {
      continue;
    }
    for (final check in failed.isEmpty ? <String>['status'] : failed) {
      findings.add(
        _appShellCapabilityFinding(
          gapType: _gapTypeForAppShellCheck(check),
          findingId:
              'B25-APP-SHELL-${_slug(_asString(row['communityName'], fallback: 'community'))}-${_slug(_asString(row['role'], fallback: 'role'))}-${_slug(check)}',
          title: 'App Shell capability failed: $check',
          summary:
              'Community `${_asString(row['communityName'], fallback: 'community')}` role `${_asString(row['role'], fallback: 'role')}` does not prove `$check` from screenshot evidence.',
          requiredFix:
              'Update the product doc or UI, recapture after-screenshots, and regenerate appShellCapabilityReview so `$check` passes from visible evidence.',
          row: row,
        ),
      );
    }
  }

  findings.addAll(_missingTabRendererContractFindings(evidence, review));
  findings.addAll(_missingInteractionTransitionFindings(evidence, review));
  findings.addAll(_weakAppShellReviewEvidenceFindings(review));
  return findings;
}

String _gapTypeForAppShellCheck(String check) {
  switch (check) {
    case 'tabsPass':
      return 'app-shell-tabs-gap';
    case 'pinningPolicyPass':
      return 'app-shell-pinning-gap';
    case 'presentationStatesPass':
      return 'app-shell-presentation-state-gap';
    case 'mainCommunityCardStatesPass':
      return 'app-shell-community-card-state-gap';
    case 'themeCustomizationPass':
      return 'app-shell-customization-gap';
    case 'rendererSelectionPass':
      return 'app-shell-renderer-selection-gap';
    default:
      return 'app-shell-capability-gap';
  }
}

JsonMap _appShellCapabilityFinding({
  required String gapType,
  required String findingId,
  required String title,
  required String summary,
  required String requiredFix,
  JsonMap? row,
  String? rendererContractId,
  String? tabId,
  String? tabLabel,
  String? cardSurfaceFamily,
  List<JsonMap> screenRows = const <JsonMap>[],
}) {
  final affectedRows = screenRows.isEmpty && row != null
      ? _asStringList(row['affectedScreenRowIds'])
      : screenRows.map(_rowId).where((id) => id.isNotEmpty).toList();
  return <String, Object?>{
    'findingId': findingId,
    'source': 'b25-app-shell-capability-review',
    'severity': 'major',
    'status': 'open',
    'resolved': false,
    'blocksPass': true,
    'gapType': gapType,
    'title': title,
    'summary': summary,
    'requiredFix': requiredFix,
    'communityName': _asString(row?['communityName']),
    'role': _asString(row?['role']),
    'tabId': tabId ?? _asString(row?['tabId']),
    'tabLabel': tabLabel ?? _asString(row?['tabLabel']),
    'rendererContractId':
        rendererContractId ?? _asString(row?['rendererContractId']),
    'cardSurfaceFamily':
        cardSurfaceFamily ?? _asString(row?['cardSurfaceFamily']),
    'affectedScreenRowIds': affectedRows,
    'affectedScreenshotPaths': screenRows.isEmpty && row != null
        ? _asStringList(row['affectedScreenshotPaths'])
        : [
            for (final screenRow in screenRows)
              _asString(screenRow['screenshotPath']),
          ].where((path) => path.isNotEmpty).toList(),
    'affectedScreenshotHashes': screenRows.isEmpty && row != null
        ? _asStringList(row['affectedScreenshotHashes'])
        : [
            for (final screenRow in screenRows)
              _asString(screenRow['screenshotHash']),
          ].where((hash) => hash.isNotEmpty).toList(),
    'visibleTextExcerpt': screenRows.isEmpty
        ? _asString(row?['visibleTextExcerpt'])
        : _truncate(
            screenRows
                .map((screenRow) => _asString(screenRow['visibleTextExtract']))
                .where((text) => text.isNotEmpty)
                .join(' | '),
            420,
          ),
  };
}

List<JsonMap> _missingTabRendererContractFindings(
  JsonMap evidence,
  JsonMap review,
) {
  final rendererRows = _asMapList(
    review['tabRendererResults'] ??
        review['rendererContractResults'] ??
        review['tabNativeRendererResults'],
  );
  final byContract = <String, JsonMap>{
    for (final row in rendererRows)
      _asString(
        row['rendererContractId'] ?? row['contractId'] ?? row['renderer'],
      ): row,
  }..remove('');
  final findings = <JsonMap>[];
  for (final contract in _requiredTabRendererContracts) {
    final row = byContract[contract];
    final relatedRows = _screenRowsForRendererContract(evidence, contract);
    final hasScreenshotProof =
        row != null &&
        (_asStringList(row['affectedScreenRowIds']).isNotEmpty ||
            _asStringList(row['screenshotHashes']).isNotEmpty ||
            _asStringList(row['affectedScreenshotHashes']).isNotEmpty);
    final statusPass =
        row != null &&
        _asString(row['status'], fallback: _asString(row['verdict'])) ==
            'pass' &&
        row['blocksPass'] != true;
    final visibleProof = _visibleEvidenceText(row ?? const <String, Object?>{});
    if (!statusPass || !hasScreenshotProof || visibleProof.length < 24) {
      findings.add(
        _appShellCapabilityFinding(
          gapType: 'app-shell-tab-renderer-contract-gap',
          findingId: 'B25-APP-SHELL-${_slug(contract)}-MISSING-PROOF',
          title: '$contract is not proven by screenshot-backed review',
          summary:
              '$contract must be reviewed as a tab-native renderer from current screenshots. The review must answer whether the tab looks and behaves like the expected product surface, not a generic workflow-card list.',
          requiredFix:
              'Add a tabRendererResults row for `$contract` with status=pass only after screenshots prove the tab-native UI, visible content, interaction states, and direct-question critique. If it fails, keep this as an implementation ticket.',
          row: row,
          rendererContractId: contract,
          tabId: _tabIdForRendererContract(contract),
          tabLabel: _tabLabelForRendererContract(contract),
          cardSurfaceFamily: _cardSurfaceFamilyForRendererContract(contract),
          screenRows: relatedRows,
        ),
      );
    }
  }
  return findings;
}

List<JsonMap> _missingInteractionTransitionFindings(
  JsonMap evidence,
  JsonMap review,
) {
  final interactionRows = _asMapList(
    review['interactionTransitionResults'] ??
        review['buttonInteractionResults'] ??
        review['interactionEvidenceResults'],
  );
  if (interactionRows.isNotEmpty) {
    return [
      for (final row in interactionRows)
        if (_asString(row['status'], fallback: _asString(row['verdict'])) !=
                'pass' ||
            row['blocksPass'] == true ||
            _asStringList(row['beforeScreenRowIds']).isEmpty ||
            _asStringList(row['afterScreenRowIds']).isEmpty)
          _appShellCapabilityFinding(
            gapType: 'app-shell-interaction-transition-gap',
            findingId:
                'B25-APP-SHELL-INTERACTION-${_slug(_asString(row['interactionId'], fallback: _rowId(row)))}',
            title: 'Interaction transition evidence failed',
            summary:
                'Interaction `${_asString(row['interactionId'], fallback: _rowId(row))}` does not prove a tapped control caused the expected visible state transition.',
            requiredFix:
                'Capture before/tap/after screenshots for this interaction and record the visible state change, including the user-facing result and undo/change path when applicable.',
            row: row,
          ),
    ];
  }
  final scorecards = _asMapList(evidence['workflowLifecycleScorecards']);
  final screenRowsById = <String, JsonMap>{
    for (final row in _asMapList(evidence['screenRows'])) _rowId(row): row,
  }..remove('');
  final failing = <JsonMap>[];
  for (final scorecard in scorecards) {
    final rowIds = _asStringList(scorecard['screenRowIds']);
    final rows = [
      for (final id in rowIds)
        if (screenRowsById[id] != null) screenRowsById[id]!,
    ];
    final screenTypes = rows
        .map((row) => _asString(row['screenType'] ?? row['screenOrState']))
        .join(' ')
        .toLowerCase();
    final hashes = <String>{
      for (final row in rows) _asString(row['screenshotHash']),
    }..remove('');
    final hasEntry =
        screenTypes.contains('entry') || screenTypes.contains('start');
    final hasAction =
        screenTypes.contains('action') ||
        screenTypes.contains('review') ||
        screenTypes.contains('tap');
    final hasResult =
        screenTypes.contains('result') ||
        screenTypes.contains('complete') ||
        screenTypes.contains('receiver');
    if (!hasEntry || !hasAction || !hasResult || hashes.length < 2) {
      failing.add(scorecard);
    }
  }
  if (failing.isEmpty) {
    return <JsonMap>[];
  }
  return <JsonMap>[
    _appShellCapabilityFinding(
      gapType: 'app-shell-interaction-transition-gap',
      findingId: 'B25-APP-SHELL-INTERACTION-TRANSITIONS-MISSING',
      title: 'Interaction transitions are not fully screenshot-proven',
      summary:
          '${failing.length} workflow lifecycle scorecards do not prove entry, tapped/review action, and changed result states from distinct screenshots.',
      requiredFix:
          'Extend B25 capture so each actionable control has before/tap/after or entry/action/result evidence with distinct screenshot hashes and visible state changes; rerun the interaction-model judge and LLM vision review.',
    ),
  ];
}

List<JsonMap> _weakAppShellReviewEvidenceFindings(JsonMap review) {
  final findings = <JsonMap>[];
  for (final row in _asMapList(review['communityResults'])) {
    final visible = _visibleEvidenceText(row);
    final screenshotRows = _asStringList(row['affectedScreenRowIds']);
    final screenshotHashes = <String>{
      ..._asStringList(row['affectedScreenshotHashes']),
      ..._asStringList(row['screenshotHashes']),
    }..remove('');
    if (visible.length < 24 ||
        screenshotRows.isEmpty ||
        screenshotHashes.isEmpty) {
      findings.add(
        _appShellCapabilityFinding(
          gapType: 'app-shell-review-depth-gap',
          findingId:
              'B25-APP-SHELL-REVIEW-DEPTH-${_slug(_asString(row['communityName'], fallback: 'community'))}-${_slug(_asString(row['role'], fallback: 'role'))}',
          title:
              'App Shell capability review lacks visible screenshot critique',
          summary:
              'The App Shell review row has pass flags, but lacks enough visible text, screenshot hashes, or screen-specific critique to prove the shell capabilities were visually inspected.',
          requiredFix:
              'Regenerate the App Shell capability review with visible text excerpts, screenshot hashes, tab/renderer-specific critiques, and direct answers for the reviewed community/role.',
          row: row,
        ),
      );
    }
  }
  return findings;
}

const List<String> _requiredTabRendererContracts = <String>[
  'CalendarTabSurface',
  'MessagesTabSurface',
  'MarketplaceTabSurface',
  'DocumentsTabSurface',
  'WorkflowStatusSurface',
];

String _tabIdForRendererContract(String contract) {
  switch (contract) {
    case 'CalendarTabSurface':
      return 'calendar';
    case 'MessagesTabSurface':
      return 'messages';
    case 'MarketplaceTabSurface':
      return 'marketplace';
    case 'DocumentsTabSurface':
      return 'documents';
    case 'WorkflowStatusSurface':
      return 'workflow-status';
    default:
      return _slug(contract);
  }
}

String _tabLabelForRendererContract(String contract) {
  switch (contract) {
    case 'CalendarTabSurface':
      return 'Calendar';
    case 'MessagesTabSurface':
      return 'Messages';
    case 'MarketplaceTabSurface':
      return 'Marketplace';
    case 'DocumentsTabSurface':
      return 'Documents';
    case 'WorkflowStatusSurface':
      return 'Status';
    default:
      return contract;
  }
}

String _cardSurfaceFamilyForRendererContract(String contract) {
  switch (contract) {
    case 'CalendarTabSurface':
      return 'calendar,event-rsvp,member-meetup';
    case 'MessagesTabSurface':
      return 'discussion-message,messaging-connections,notification-inbox';
    case 'MarketplaceTabSurface':
      return 'equipment-loan,plant-exchange';
    case 'DocumentsTabSurface':
      return 'documents,external-document-link,portability';
    case 'WorkflowStatusSurface':
      return 'workflow-status,approval-request,custom-form-submission';
    default:
      return '';
  }
}

List<JsonMap> _screenRowsForRendererContract(
  JsonMap evidence,
  String contract,
) {
  final rows = _asMapList(evidence['screenRows']);
  bool matches(JsonMap row) {
    final text = _asString(row['visibleTextExtract']).toLowerCase();
    final family = _asString(row['cardSurfaceFamily']).toLowerCase();
    final workflow = _asString(row['workflowId']).toLowerCase();
    switch (contract) {
      case 'CalendarTabSurface':
        return text.contains('calendar') ||
            family.contains('event') ||
            workflow.contains('event') ||
            workflow.contains('rsvp') ||
            workflow.contains('schedule');
      case 'MessagesTabSurface':
        return text.contains('messages') ||
            text.contains('thread') ||
            text.contains('inbox') ||
            family.contains('thread') ||
            family.contains('social') ||
            workflow.contains('message') ||
            workflow.contains('connection');
      case 'MarketplaceTabSurface':
        return text.contains('marketplace') ||
            text.contains('loan') ||
            text.contains('borrow') ||
            text.contains('giveaway') ||
            family.contains('equipment') ||
            family.contains('exchange') ||
            workflow.contains('gear') ||
            workflow.contains('plant');
      case 'DocumentsTabSurface':
        return text.contains('documents') ||
            text.contains('receipt') ||
            text.contains('export') ||
            family.contains('operations') ||
            family.contains('portability') ||
            workflow.contains('document') ||
            workflow.contains('export');
      case 'WorkflowStatusSurface':
        return text.contains('status') ||
            text.contains('review') ||
            text.contains('approval') ||
            text.contains('request changes') ||
            family.contains('approval') ||
            workflow.contains('approval') ||
            workflow.contains('request') ||
            workflow.contains('form');
      default:
        return false;
    }
  }

  return rows.where(matches).take(24).toList();
}

List<String> _llmVisionReviewQualityProblems({
  required JsonMap llmReview,
  required JsonMap evidence,
}) {
  final problems = <String>[];
  final currentRows = _asMapList(evidence['screenRows']);
  final currentRowIds = <String>{for (final row in currentRows) _rowId(row)}
    ..remove('');
  final screenReviews = _asMapList(llmReview['screenReviews']);
  final reviewedRows = <String>{
    for (final review in screenReviews)
      ..._asStringList(review['affectedScreenRowIds']),
    for (final review in screenReviews) _asString(review['screenRowId']),
  }..remove('');
  final unreviewedRows = currentRowIds.difference(reviewedRows);
  if (unreviewedRows.isNotEmpty) {
    problems.add(
      'screenReviews do not cover ${unreviewedRows.length} current screen rows (${unreviewedRows.take(8).join(', ')})',
    );
  }

  final holisticAnswers = _asMapList(
    llmReview['holisticQuestionAnswers'] ??
        llmReview['holisticDirectQuestionAnswers'],
  );
  if (holisticAnswers.isEmpty) {
    problems.add('holistic direct-question answers are missing');
  }
  for (final answer in holisticAnswers) {
    final questionId = _asString(
      answer['questionId'],
      fallback: _rowId(answer),
    );
    final critique = _asString(
      answer['critique'] ?? answer['why'] ?? answer['rationale'],
    );
    final visible = _visibleEvidenceText(answer);
    if (visible.length < 24) {
      problems.add('$questionId has no concrete visible screenshot evidence');
    }
    if (_isWeakLlmCritique(critique)) {
      problems.add('$questionId has boilerplate or non-visual rationale');
    }
  }

  for (final review in screenReviews) {
    final rowId = _asString(review['screenRowId'], fallback: _rowId(review));
    final critique = _asString(review['critique'] ?? review['why']);
    final visible = _visibleEvidenceText(review);
    final directQuestions = _asMapList(
      review['directQuestionAnswers'] ??
          review['directQuestions'] ??
          review['questions'],
    );
    if (visible.length < 24) {
      problems.add('$rowId has empty or weak visibleEvidence');
    }
    if (_isWeakLlmCritique(critique)) {
      problems.add('$rowId has boilerplate critique');
    }
    if (directQuestions.isEmpty) {
      problems.add('$rowId has no screen-level direct-question answers');
    } else {
      final weakQuestions = directQuestions.where((question) {
        final q = _asString(question['question']);
        final qVisible = _visibleEvidenceText(question);
        final qWhy = _asString(
          question['why'] ?? question['critique'] ?? question['rationale'],
        );
        return q.isEmpty || qVisible.length < 16 || _isWeakLlmCritique(qWhy);
      }).length;
      if (weakQuestions > 0) {
        problems.add('$rowId has $weakQuestions weak direct-question answers');
      }
    }
  }
  return problems;
}

String _visibleEvidenceText(JsonMap row) {
  final values = <String>[
    ..._asStringList(row['visibleEvidence']),
    ..._asStringList(row['visibleObservations']),
    _asString(row['visibleText']),
    _asString(row['visibleTextExcerpt']),
    _asString(row['evidence']),
  ];
  return values
      .where((value) => value.trim().isNotEmpty)
      .join(' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

bool _isWeakLlmCritique(String value) {
  final critique = value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  if (critique.length < 80) {
    return true;
  }
  final weakPhrases = <String>[
    'no imported blocking visual finding',
    'passing lifecycle/product-surface scaffold',
    'fresh screenshot row',
    'was reviewed for',
    'visible text includes: .',
    'no deterministic pixel/layout blocker',
    'acceptable for b25 because',
    'scorecards are green',
    'no row-level coverage or critique failures were found',
  ];
  final weakPhraseCount = weakPhrases
      .where((phrase) => critique.contains(phrase))
      .length;
  if (weakPhraseCount >= 2) {
    return true;
  }
  return false;
}

_DerivedFailure? _failOnWorkflowRoleScorecards(JsonMap evidence) {
  final scorecards = _asMapList(evidence['workflowRoleScorecards']);
  if (scorecards.isEmpty) {
    return _DerivedFailure(
      score: 0,
      message: 'No workflow/role direct-question scorecards were supplied.',
    );
  }
  final failing = <String>[];
  for (final scorecard in scorecards) {
    final workflowId = _asString(scorecard['workflowId']);
    final role = _asString(scorecard['role']);
    final questions = _asMapList(scorecard['questions']);
    if (workflowId.isEmpty || role.isEmpty || questions.isEmpty) {
      failing.add(_rowId(scorecard));
      continue;
    }
    final questionFailure = _failOnDirectQuestionAnswers(
      questions,
      requiredScope: 'workflow/role $workflowId/$role',
    );
    if (questionFailure != null) {
      failing.add('$workflowId/$role');
    }
  }
  if (failing.isNotEmpty) {
    return _DerivedFailure(
      score: 55,
      message:
          'Workflow/role direct-question scorecards have missing or blocking answers: ${failing.join(', ')}.',
      evidenceUsed: failing,
    );
  }
  return null;
}

_DerivedFailure? _failOnWorkflowLifecycleScorecards(JsonMap evidence) {
  final scorecards = _asMapList(evidence['workflowLifecycleScorecards']);
  if (scorecards.isEmpty) {
    return _DerivedFailure(
      score: 0,
      message:
          'No semantic workflow interaction-model scorecards were supplied. Run b25_workflow_interaction_model_judge.dart before production_ux_judge.dart.',
    );
  }
  final failing = <String>[];
  final missingGroups = <String>{};
  for (final scorecard in scorecards) {
    final scorecardId = _asString(scorecard['scorecardId']);
    final proof = scorecard['workflowLifecycleProof'] as JsonMap?;
    final missing = _asStringList(
      scorecard['missingLifecycleGroups'] ?? proof?['missingGroups'],
    );
    if (scorecard['blocksPass'] == true ||
        _asString(scorecard['status']) != 'pass' ||
        _asString(proof?['status']) == 'fail' ||
        missing.isNotEmpty) {
      failing.add(scorecardId.isEmpty ? _rowId(scorecard) : scorecardId);
      missingGroups.addAll(missing);
    }
  }
  if (failing.isNotEmpty) {
    return _DerivedFailure(
      score: 45,
      message:
          'Workflow lifecycle scorecards are incomplete for ${failing.join(', ')}. Missing lifecycle groups: ${missingGroups.join(', ')}.',
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
    final workflowRoleFailure = _failOnWorkflowRoleScorecards(evidence);
    if (workflowRoleFailure != null) {
      errors.add(
        'workflow/role direct-question pass: ${workflowRoleFailure.message}',
      );
    }
    final workflowLifecycleFailure = _failOnWorkflowLifecycleScorecards(
      evidence,
    );
    if (workflowLifecycleFailure != null) {
      errors.add(
        'workflow lifecycle pass: ${workflowLifecycleFailure.message}',
      );
    }
    final productDocFailure = _failOnProductDocCoverage(evidence);
    if (productDocFailure != null) {
      errors.add('community product docs: ${productDocFailure.message}');
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
      'Product Spec Repair Work Items',
      _asMapList(ticket['productDocRepairWorkItems']),
    );
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
    final productDocs = _asMapList(ticket['affectedProductDocs']);
    if (productDocs.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('### Affected Product Experience Docs')
        ..writeln()
        ..writeln(
          '| Product doc | Status | Community | Path | Missing sections | Required fix |',
        )
        ..writeln('| --- | --- | --- | --- | --- | --- |');
      for (final row in productDocs.take(40)) {
        buffer.writeln(
          '| `${_escape(_asString(row['productDocId']))}` | `${_escape(_asString(row['status']))}` | ${_escape(_asString(row['communityName']))} | `${_escape(_asString(row['docPath']))}` | ${_escape(_asStringList(row['missingSections']).join('; '))} | ${_escape(_asString(row['requiredFix']))} |',
        );
      }
    }
    final coverageRows = _asMapList(ticket['affectedCoverageRows']);
    if (coverageRows.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('### Affected Workflow/Role Coverage')
        ..writeln()
        ..writeln(
          'Showing ${coverageRows.take(40).length} of ${coverageRows.length} affected coverage rows. Full detail is in the JSON ticket.',
        )
        ..writeln()
        ..writeln(
          '| Coverage row | Status | Community | Workflow | Role | Missing evidence | Screen rows | Target surface |',
        )
        ..writeln('| --- | --- | --- | --- | --- | --- | ---: | --- |');
      for (final row in coverageRows.take(40)) {
        buffer.writeln(
          '| `${_escape(_asString(row['coverageRowId']))}` | `${_escape(_asString(row['status']))}` | ${_escape(_asString(row['communityName']))} | `${_escape(_asString(row['workflowId']))}` | ${_escape(_asString(row['role']))} | ${_escape(_asStringList(row['missingEvidence']).join('; '))} | ${_asStringList(row['screenRowIds']).length} | ${_escape(_asString(row['targetProductionSurface']))} |',
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
          '| Screen row | Community | Workflow | Role | State | Screenshot | Hash | Visible text | Current surface | Exact UX failure | Target surface |',
        )
        ..writeln(
          '| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |',
        );
      for (final row in screenRows.take(40)) {
        buffer.writeln(
          '| `${_escape(_asString(row['screenRowId']))}` | ${_escape(_asString(row['communityName']))} | `${_escape(_asString(row['workflowId']))}` | ${_escape(_asString(row['role']))} | ${_escape(_asString(row['screenState']))} | `${_escape(_asString(row['screenshotPath']))}` | `${_escape(_truncate(_asString(row['screenshotHash']), 16))}` | ${_escape(_asString(row['visibleTextExcerpt']))} | ${_escape(_asString(row['currentSurfaceClassification']))} / ${_escape(_asString(row['currentPrimarySurfaceType']))} | ${_escape(_asString(row['exactUxFailure']))} | ${_escape(_asString(row['targetProductionSurface']))} |',
        );
      }
    }
    final scorecards = _asMapList(ticket['failingWorkflowRoleScorecards']);
    if (scorecards.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('### Failing Workflow/Role Scorecards')
        ..writeln()
        ..writeln(
          'Showing ${scorecards.take(40).length} of ${scorecards.length} failing scorecards. Full detail is in the JSON ticket.',
        )
        ..writeln()
        ..writeln(
          '| Scorecard | Community | Workflow | Role | Failed questions | Target surface |',
        )
        ..writeln('| --- | --- | --- | --- | ---: | --- |');
      for (final scorecard in scorecards.take(40)) {
        buffer.writeln(
          '| `${_escape(_asString(scorecard['scorecardId']))}` | ${_escape(_asString(scorecard['communityName']))} | `${_escape(_asString(scorecard['workflowId']))}` | ${_escape(_asString(scorecard['role']))} | ${_asMapList(scorecard['failingQuestions']).length} | ${_escape(_asString(scorecard['targetProductionSurface']))} |',
        );
      }
    }
    final lifecycleScorecards = _asMapList(
      ticket['failingWorkflowLifecycleScorecards'],
    );
    if (lifecycleScorecards.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(
          '### Failing Workflow Lifecycle / Interaction Model Scorecards',
        )
        ..writeln()
        ..writeln(
          'Showing ${lifecycleScorecards.take(40).length} of ${lifecycleScorecards.length} failing lifecycle scorecards. Full semantic interaction-model detail is in the JSON ticket.',
        )
        ..writeln()
        ..writeln(
          '| Scorecard | Community | Workflow | Role | Expected decision | Missing lifecycle groups | Missing actions | Wrong generic substitutes | Target surface |',
        )
        ..writeln('| --- | --- | --- | --- | --- | --- | --- | --- | --- |');
      for (final scorecard in lifecycleScorecards.take(40)) {
        buffer.writeln(
          '| `${_escape(_asString(scorecard['scorecardId']))}` | ${_escape(_asString(scorecard['communityName']))} | `${_escape(_asString(scorecard['workflowId']))}` | ${_escape(_asString(scorecard['role']))} | ${_escape(_asString(scorecard['expectedDecision']))} | ${_escape(_asStringList(scorecard['missingLifecycleGroups']).join('; '))} | ${_escape(_asStringList(scorecard['missingActions']).join('; '))} | ${_escape(_asStringList(scorecard['wrongGenericSubstitutes']).join('; '))} | ${_escape(_asString(scorecard['targetProductionSurface']))} |',
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
      '| Work item | Stage | Community | Workflow | Role | Screens | Coverage | Target surface | Blocked until |',
    )
    ..writeln('| --- | --- | --- | --- | --- | ---: | ---: | --- | --- |');
  for (final item in workItems.take(30)) {
    buffer.writeln(
      '| `${_escape(_asString(item['workItemId']))}` | `${_escape(_asString(item['stage']))}` | ${_escape(_asString(item['communityName']))} | `${_escape(_asString(item['workflowId']))}` | ${_escape(_asString(item['role']))} | ${_asStringList(item['affectedScreenRowIds']).length} | ${_asStringList(item['affectedCoverageRowIds']).length} | ${_escape(_asString(item['targetProductionSurface']))} | ${_escape(_asString(item['blockedUntil']))} |',
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

List<String> _argValues(List<String> args, String name) {
  final values = <String>[];
  for (var i = 0; i < args.length; i += 1) {
    if (args[i] == name && i + 1 < args.length) {
      values.add(args[i + 1]);
    }
  }
  return values;
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
        row['fanId'] ??
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
