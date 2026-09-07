import 'package:loom_ux_judges/loom_ux_judges.dart';
import 'package:test/test.dart';

void main() {
  group('B25 UI/Usability Score', () {
    test('a 7.9 score alone blocks an otherwise passing LLM review', () {
      final imported = buildB25LlmUxReviewImport(
        _reviewInput(),
        _freshLlmReview(_subScores(7.9)),
        llmReviewPath: 'test/fixtures/llm-review.json',
        runId: 'run-ui-usability-score',
      );

      final score = imported['uiUsabilityScore'] as Map<String, Object?>;
      expect(score['overallScore'], 7.9);
      expect(score['meetsThreshold'], isFalse);
      expect(imported['finalDecision'], 'fail');
      expect(imported['b25CanPass'], isFalse);
      expect(imported['findings'], isEmpty);
    });

    test('an 8.0 score alone permits an otherwise passing LLM review', () {
      final imported = buildB25LlmUxReviewImport(
        _reviewInput(),
        _freshLlmReview(_subScores(8.0)),
        llmReviewPath: 'test/fixtures/llm-review.json',
        runId: 'run-ui-usability-score',
      );

      final score = imported['uiUsabilityScore'] as Map<String, Object?>;
      expect(score['overallScore'], 8.0);
      expect(score['meetsThreshold'], isTrue);
      expect(imported['finalDecision'], 'pass');
      expect(imported['b25CanPass'], isTrue);
      expect(imported['findings'], isEmpty);
    });

    test(
      'a missing or incomplete score creates a visible blocking finding',
      () {
        final missing = buildB25LlmUxReviewImport(
          _reviewInput(),
          _freshLlmReview(null),
          llmReviewPath: 'test/fixtures/llm-review.json',
          runId: 'run-ui-usability-score',
        );
        final incomplete = buildB25LlmUxReviewImport(
          _reviewInput(),
          _freshLlmReview(_subScores(8.5).take(4).toList()),
          llmReviewPath: 'test/fixtures/llm-review.json',
          runId: 'run-ui-usability-score',
        );

        for (final imported in <Map<String, Object?>>[missing, incomplete]) {
          final score = imported['uiUsabilityScore'] as Map<String, Object?>;
          final findings = (imported['findings'] as List<Object?>)
              .whereType<Map<String, Object?>>();
          expect(score.containsKey('overallScore'), isFalse);
          expect(score['meetsThreshold'], isFalse);
          expect(imported['finalDecision'], 'fail');
          expect(imported['b25CanPass'], isFalse);
          expect(
            findings,
            anyElement(
              allOf(
                containsPair('findingId', 'B25-UI-USABILITY-SCORE-INCOMPLETE'),
                containsPair('blocksPass', true),
                containsPair(
                  'title',
                  'UI/Usability Score missing or incomplete',
                ),
              ),
            ),
          );
        }
      },
    );

    test('the supplied overallScore is ignored and recomputed', () {
      final imported = buildB25LlmUxReviewImport(
        _reviewInput(),
        _freshLlmReview(<Map<String, Object?>>[
          ..._subScores(8.0).take(4),
          <String, Object?>{
            'dimension': 'errorAndEdgeStateHandling',
            'score': 9.0,
            'evidence': 'Screen row event-detail shows a recoverable error.',
          },
        ], suppliedOverallScore: 10.0),
        llmReviewPath: 'test/fixtures/llm-review.json',
        runId: 'run-ui-usability-score',
      );

      final score = imported['uiUsabilityScore'] as Map<String, Object?>;
      expect(score['overallScore'], 8.2);
      expect(score['overallScore'], isNot(10.0));
      expect(score['meetsThreshold'], isTrue);
    });

    test('the independent builder applies the 7.9 and 8.0 threshold', () {
      final belowThreshold = buildB25IndependentUxReview(
        _independentReviewInput(_subScores(7.9)),
      );
      final atThreshold = buildB25IndependentUxReview(
        _independentReviewInput(_subScores(8.0)),
      );

      expect(belowThreshold['finalDecision'], 'fail');
      expect(belowThreshold['b25CanPass'], isFalse);
      expect(
        (belowThreshold['uiUsabilityScore']
            as Map<String, Object?>)['overallScore'],
        7.9,
      );
      expect(atThreshold['finalDecision'], 'pass');
      expect(atThreshold['b25CanPass'], isTrue);
      expect(
        (atThreshold['uiUsabilityScore']
            as Map<String, Object?>)['overallScore'],
        8.0,
      );
    });

    test('the independent builder uses the same incomplete-score block', () {
      final judged = buildB25IndependentUxReview(_independentReviewInput(null));

      final score = judged['uiUsabilityScore'] as Map<String, Object?>;
      final findings = (judged['findings'] as List<Object?>)
          .whereType<Map<String, Object?>>();
      expect(score.containsKey('overallScore'), isFalse);
      expect(score['meetsThreshold'], isFalse);
      expect(judged['finalDecision'], 'fail');
      expect(judged['b25CanPass'], isFalse);
      expect(
        findings,
        anyElement(
          containsPair('findingId', 'B25-UI-USABILITY-SCORE-INCOMPLETE'),
        ),
      );
    });
  });
}

Map<String, Object?> _reviewInput() => <String, Object?>{
  'currentReviewRunId': 'run-ui-usability-score',
  'reviewInputEvidence': <String, Object?>{'appCommitSha': 'commit-123'},
  'screenRows': <Object?>[
    <String, Object?>{
      'rowId': 'event-detail',
      'screenshotHash': 'screenshot-123',
    },
  ],
  'findings': <Object?>[],
  'holisticQuestionAnswers': <Object?>[],
  'workflowRoleScorecards': <Object?>[],
};

Map<String, Object?> _freshLlmReview(
  List<Map<String, Object?>>? subScores, {
  double? suppliedOverallScore,
}) {
  final review = <String, Object?>{
    'status': 'pass',
    'freshReview': true,
    'currentReviewRunId': 'run-ui-usability-score',
    'appCommitSha': 'commit-123',
    'reviewedScreenRowIds': <String>['event-detail'],
    'reviewedScreenshotHashes': <String>['screenshot-123'],
    'findings': <Object?>[],
    'holisticQuestionAnswers': <Object?>[],
    'screenReviews': <Object?>[],
  };
  if (subScores != null) {
    review['uiUsabilityScore'] = <String, Object?>{
      'subScores': subScores,
      if (suppliedOverallScore != null) 'overallScore': suppliedOverallScore,
    };
  }
  return review;
}

List<Map<String, Object?>> _subScores(double score) => <Map<String, Object?>>[
  <String, Object?>{
    'dimension': 'visualPolishAndNativeFidelity',
    'score': score,
    'evidence': 'Screen row event-detail uses a native event surface.',
  },
  <String, Object?>{
    'dimension': 'informationHierarchy',
    'score': score,
    'evidence': 'Screen row event-detail prioritizes the RSVP state.',
  },
  <String, Object?>{
    'dimension': 'interactionAffordanceClarity',
    'score': score,
    'evidence': 'Screen row event-detail exposes RSVP and cancel controls.',
  },
  <String, Object?>{
    'dimension': 'consistency',
    'score': score,
    'evidence': 'Screen row event-detail uses the community spacing system.',
  },
  <String, Object?>{
    'dimension': 'errorAndEdgeStateHandling',
    'score': score,
    'evidence': 'Screen row event-detail shows an actionable empty state.',
  },
];

Map<String, Object?> _independentReviewInput(
  List<Map<String, Object?>>? subScores,
) => <String, Object?>{
  'visualInspectionSummary': <String, Object?>{'status': 'pass'},
  'workflowRoleCoverage': <Object?>[],
  'workflowRoleCoverageSummary': <String, Object?>{
    'coverageRowCount': 0,
    'failingCoverageRowCount': 0,
  },
  'screenRows': <Object?>[],
  'productDocCoverage': <Object?>[
    <String, Object?>{'status': 'pass'},
  ],
  'findings': <Object?>[],
  'remediationIterations': <Object?>[],
  if (subScores != null)
    'uiUsabilityScore': <String, Object?>{'subScores': subScores},
};
