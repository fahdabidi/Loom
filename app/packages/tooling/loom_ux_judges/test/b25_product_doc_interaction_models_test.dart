import 'package:loom_ux_judges/b25_product_doc_interaction_models.dart';
import 'package:loom_ux_judges/loom_ux_judges.dart';
import 'package:test/test.dart';

void main() {
  late B25ProductDocInteractionCatalog catalog;

  setUpAll(() {
    catalog = B25ProductDocInteractionCatalog.fromRepositoryRoot(
      locateB25RepositoryRoot(),
    );
  });

  test('loads all 79 B25 rows from the ten owning product docs', () {
    expect(catalog.models, hasLength(79));
    expect(
      {
        for (final model in catalog.models)
          model.communityId: catalog.models
              .where((row) => row.communityId == model.communityId)
              .length,
      },
      equals(const <String, int>{
        'community_mosque': 15,
        'community_chess_club': 10,
        'community_book_club': 9,
        'community_export_migration': 9,
        'community_youth_soccer': 8,
        'community_platform_social': 8,
        'community_hoa': 7,
        'community_ad_off': 6,
        'community_garden_club': 4,
        'community_camera_club': 3,
      }),
    );
  });

  test('uses each comma-separated action cell as a synonym set', () {
    final model = catalog.requireModel(
      communityId: 'community_camera_club',
      communityName: 'Camera Club',
      workflowId: 'gear-loan-request',
      role: 'member',
    );

    expect(
      model.requiredPrimaryActions,
      equals(const <String>[
        'browse gear',
        'list gear',
        'request loan',
        'join waitlist',
        'claim giveaway',
        'schedule pickup',
      ]),
    );
    expect(
      model.requiredAlternateActions,
      containsAll(const <String>[
        'change request',
        'leave queue',
        'edit listing',
        'delist',
        'report damage',
        'return gear',
      ]),
    );
  });

  test('preserves explicit no-alternate product-doc cells as a loud gap', () {
    final model = catalog.requireModel(
      communityId: 'community_chess_club',
      communityName: 'Chess Club',
      workflowId: 'chess-club-night',
      role: 'organizer',
    );

    expect(model.requiredAlternateActions, isEmpty);
    expect(model.alternateRequirementNote, '(none — one-way notification)');
  });

  test('missing rows fail naming community, workflow, and document role', () {
    expect(
      () => catalog.requireModel(
        communityId: 'community_camera_club',
        communityName: 'Camera Club',
        workflowId: 'gear-loan-request',
        role: 'owner',
      ),
      throwsA(
        isA<StateError>()
            .having(
              (error) => error.message,
              'message',
              contains('Camera Club'),
            )
            .having(
              (error) => error.message,
              'message',
              contains('gear-loan-request'),
            )
            .having((error) => error.message, 'message', contains('owner')),
      ),
    );
  });

  test('canonical device asset round-trips without changing the doc rows', () {
    final decoded = B25ProductDocInteractionCatalog.fromAssetJson(
      catalog.toCanonicalAssetString(),
    );

    expect(decoded.toCanonicalAssetString(), catalog.toCanonicalAssetString());
  });

  test(
    'interaction judge uses the owning doc row and one synonym per list',
    () {
      final review = _singleWorkflowReview(
        visibleText:
            'Camera gear available from owner. Claim giveaway. Leave queue. '
            'Item claimed with pickup handoff and custody history.',
      );

      final judged = buildB25WorkflowLifecycleReview(review);
      final scorecard =
          (judged['workflowLifecycleScorecards'] as List<Object?>).single
              as Map<String, Object?>;
      final interactionModel =
          scorecard['semanticInteractionModel'] as Map<String, Object?>;

      expect(interactionModel['status'], 'pass');
      expect(interactionModel['productDocPath'], contains('camera-club'));
      expect(
        interactionModel['visiblePrimaryActions'],
        equals(const <String>['claim giveaway']),
      );
      expect(
        interactionModel['visibleAlternateActions'],
        equals(const <String>['leave queue']),
      );
    },
  );

  test('generic substitute still fails when a domain action is missing', () {
    final review = _singleWorkflowReview(
      visibleText:
          'Camera gear available from owner. Claim giveaway. Continue. '
          'Item claimed with pickup handoff and custody history.',
    );

    final judged = buildB25WorkflowLifecycleReview(review);
    final scorecard =
        (judged['workflowLifecycleScorecards'] as List<Object?>).single
            as Map<String, Object?>;
    final interactionModel =
        scorecard['semanticInteractionModel'] as Map<String, Object?>;

    expect(interactionModel['status'], 'fail');
    expect(
      interactionModel['missingActions'],
      contains('domain-specific alternate/change/reject action'),
    );
    expect(interactionModel['wrongGenericSubstitutes'], contains('continue'));
  });

  test('judge fails loudly instead of using a generic model', () {
    final review = _singleWorkflowReview(role: 'owner');

    expect(
      () => buildB25WorkflowLifecycleReview(review),
      throwsA(
        isA<StateError>()
            .having(
              (error) => error.message,
              'message',
              contains('Camera Club'),
            )
            .having(
              (error) => error.message,
              'message',
              contains('gear-loan-request'),
            )
            .having((error) => error.message, 'message', contains('owner')),
      ),
    );
  });
}

Map<String, Object?> _singleWorkflowReview({
  String role = 'member',
  String visibleText =
      'Camera gear available from owner. Claim giveaway. Leave queue. '
      'Item claimed with pickup handoff and custody history.',
}) {
  final fanId = 'community-camera-club-$role';
  return <String, Object?>{
    'screenRows': <Map<String, Object?>>[
      <String, Object?>{
        'rowId': 'camera-gear-result',
        'communityId': 'community_camera_club',
        'communityName': 'Camera Club',
        'workflowId': 'gear-loan-request',
        'role': role,
        'fanId': fanId,
        'visibleTextExtract': visibleText,
        'screenshotPath': 'camera-gear.png',
      },
    ],
    'workflowRoleCoverage': <Map<String, Object?>>[
      <String, Object?>{
        'coverageRowId': 'camera-gear-$role',
        'communityId': 'community_camera_club',
        'communityName': 'Camera Club',
        'workflowId': 'gear-loan-request',
        'role': role,
        'fanId': fanId,
        'screenRowIds': <String>['camera-gear-result'],
        'missingEvidence': <String>[],
      },
    ],
  };
}
