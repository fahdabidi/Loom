import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../test_driver/workflow_ui_evidence_writer.dart';

void main() {
  group('WorkflowUiEvidenceWriter traversal honesty', () {
    late Directory evidenceRoot;

    setUp(() {
      evidenceRoot = Directory.systemTemp.createTempSync(
        'workflow_ui_evidence_writer_test_',
      );
    });

    tearDown(() {
      if (evidenceRoot.existsSync()) {
        evidenceRoot.deleteSync(recursive: true);
      }
    });

    Future<Map<String, dynamic>> writeAndReadAggregate(
      Map<String, dynamic> data,
    ) async {
      final writer = WorkflowUiEvidenceWriter(
        evidenceRoot: evidenceRoot,
        commandOutputPath: '${evidenceRoot.path}/command-output.log',
      );
      await writer.writeEvidence(data);
      final aggregateFile = File(
        '${evidenceRoot.path}/B20/all-workflow-ui-evidence.json',
      );
      expect(aggregateFile.existsSync(), isTrue);
      return jsonDecode(aggregateFile.readAsStringSync())
          as Map<String, dynamic>;
    }

    test(
      'an aborted run (b25TraversalFinalised omitted) does not report a '
      'complete traversal count, even though the communities it did record '
      'were all complete',
      () async {
        final aggregate = await writeAndReadAggregate({
          'requestedPhases': ['B16'],
          'workflowEvidence': <Map<String, Object?>>[],
          // Two communities finished and were recorded before the run died;
          // a third community's row was mid-flight when it aborted and so
          // was never recorded at all -- this is exactly the shape a
          // `return` (rather than `return await`) cleanup race leaves
          // behind.
          'b25CommunityTraversals': [
            {
              'phase': 'B16',
              'communityId': 'garden-club',
              'communityName': 'Garden Club',
              'extensionId': 'ext_garden_club',
              'traversalStatus': 'completely_traversed',
              'lastRowWalked': 'garden-tool-loan/member',
            },
            {
              'phase': 'B16',
              'communityId': 'book-club',
              'communityName': 'Book Club',
              'extensionId': 'ext_neighborhood_book_club',
              'traversalStatus': 'completely_traversed',
              'lastRowWalked': 'book-vote/member',
            },
          ],
          // Deliberately omitted: the real walkthrough only ever sets this
          // to true from the finalisation step that an abort never reaches.
          // 'b25TraversalFinalised': absent,
          'walkthroughStatus': 'running',
        });

        final summary =
            aggregate['b25CommunityTraversalSummary'] as Map<String, dynamic>;
        expect(
          summary['finalised'],
          isFalse,
          reason:
              'The run never reached its own finalisation, so this summary '
              'must say so explicitly rather than silently defaulting to '
              'looking complete.',
        );
        // The raw counts stay available for debugging -- they are real,
        // just not a complete picture of the run.
        expect(summary['recordedCommunities'], 2);
        expect(summary['completelyTraversedCommunities'], 2);
        expect(summary['incompletelyTraversedCommunities'], 0);

        // Independently of the traversal summary, an aborted run must never
        // read as an overall pass.
        expect(aggregate['walkthroughStatus'], 'fail');
        expect(aggregate['completionGateEligible'], isFalse);
      },
    );

    test(
      'a run that reaches finalisation with zero incomplete communities '
      'reports a genuine complete count',
      () async {
        final aggregate = await writeAndReadAggregate({
          'requestedPhases': ['B16'],
          'workflowEvidence': <Map<String, Object?>>[],
          'b25CommunityTraversals': [
            {
              'phase': 'B16',
              'communityId': 'garden-club',
              'communityName': 'Garden Club',
              'extensionId': 'ext_garden_club',
              'traversalStatus': 'completely_traversed',
              'lastRowWalked': 'garden-tool-loan/member',
            },
          ],
          'b25TraversalFinalised': true,
          'walkthroughStatus': 'pass',
        });

        final summary =
            aggregate['b25CommunityTraversalSummary'] as Map<String, dynamic>;
        expect(summary['finalised'], isTrue);
        expect(summary['recordedCommunities'], 1);
        expect(summary['completelyTraversedCommunities'], 1);
        expect(summary['incompletelyTraversedCommunities'], 0);
      },
    );

    test(
      'a finalised run with an incomplete community is still marked '
      'finalised, distinct from an aborted one',
      () async {
        final aggregate = await writeAndReadAggregate({
          'requestedPhases': ['B16'],
          'workflowEvidence': <Map<String, Object?>>[],
          'b25CommunityTraversals': [
            {
              'phase': 'B16',
              'communityId': 'garden-club',
              'communityName': 'Garden Club',
              'extensionId': 'ext_garden_club',
              'traversalStatus': 'incompletely_traversed',
              'lastRowWalked': 'garden-tool-loan/member',
              'reason': 'B25 final cleanup failed.',
            },
          ],
          'b25TraversalFinalised': true,
          'walkthroughStatus': 'fail',
        });

        final summary =
            aggregate['b25CommunityTraversalSummary'] as Map<String, dynamic>;
        expect(summary['finalised'], isTrue);
        expect(summary['incompletelyTraversedCommunities'], 1);
      },
    );
  });
}
