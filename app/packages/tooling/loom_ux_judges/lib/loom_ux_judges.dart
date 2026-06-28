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
    File(markdownPath).writeAsStringSync(_b25IterationScorecardMarkdown(scorecard));
  }
  stdout.writeln(
    'b25_iteration_scorecard: ${scorecard['status']} remainingBlockingMajor=${(scorecard['convergence'] as JsonMap)['remainingBlockingMajor']}',
  );
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
      .where((field) => !_hasUsefulValue(evidence[field]))
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
        holistic.isNotEmpty && holistic.every((row) => row['blocksPass'] != true),
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
  return _asMapList(previousScorecard['blockingFindings'])
      .map(_findingId)
      .where((id) => id.isNotEmpty)
      .toSet();
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
    'requiredFix': _asString(finding['requiredFix'] ?? finding['recommendedFix']),
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
    ..writeln('| Review run | `${_escape(_asString(scorecard['reviewRunId']))}` |')
    ..writeln('| Status | `${_escape(_asString(scorecard['status']))}` |')
    ..writeln('| Final decision | `${_escape(_asString(scorecard['finalDecision']))}` |')
    ..writeln('| B25 can pass | `${scorecard['b25CanPass']}` |')
    ..writeln('| Remaining critical/blocker + major | ${convergence['remainingBlockingMajor']} |')
    ..writeln('| Resolved critical/blocker + major this pass | ${convergence['resolvedBlockingMajorThisPass']} |')
    ..writeln('| New critical/blocker + major this pass | ${convergence['newBlockingMajorThisPass']} |')
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
    ..writeln('| Criteria passed | ${judge['passedCriteria']} / ${judge['totalCriteria']} |')
    ..writeln('| Blocking criterion failures | ${judge['blockingCriterionFailures']} |')
    ..writeln('| Holistic direct-question pass | `${judge['holisticPass']}` |')
    ..writeln('| Workflow/persona direct-question pass | `${judge['workflowPersonaPass']}` |')
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

String _iterationScorecardUsage() {
  return '''
b25_iteration_scorecard (B25)
Summarizes one B25 review/remediation pass and tracks convergence.

Usage:
  dart run packages/tooling/loom_ux_judges/bin/b25_iteration_scorecard.dart --review <independent-production-ux-review.json> [--judge <production-ux-criteria-scorecard.json>] [--previous <previous-scorecard.json>] [--output <scorecard.json>] [--markdown-output <scorecard.md>]
''';
}

JsonMap _extraScorecards(
  JudgeSpec spec,
  JsonMap evidence,
  List<CriterionResult> criteria,
) {
  if (spec.toolId != 'production-ux-judge') {
    return <String, Object?>{};
  }
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
  };
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
  dart run packages/tooling/loom_ux_judges/bin/${spec.toolId.replaceAll('-', '_')}.dart --input <evidence.json> [--base <repo-root>] [--output <scorecard.json>] [--markdown-output <scorecard.md>]
''';
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
