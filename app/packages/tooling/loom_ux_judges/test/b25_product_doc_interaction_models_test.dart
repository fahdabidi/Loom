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
    final syntheticMarkdown = '''
### B25 Semantic Interaction Models

| Workflow | ${['Per', 'sona'].join()} | Expected decision | Required primary actions | Required alternate/change/reject actions | Result and receiver state |
| --- | --- | --- | --- | --- | --- |
| synthetic-one-way-notification | member | Notify participants with no reversal path. | send notification, record send receipt | (none — one-way notification) | Fresh screenshots show the delivered notification and receiver state. |
''';
    final syntheticSource = const B25ProductCommunitySource(
      communityId: 'community_synthetic_fixture',
      communityName: 'Synthetic Fixture',
      extensionId: 'ext_synthetic_fixture',
      productDocPath: 'test/fixtures/synthetic-product-experience.md',
    );

    final model = parseB25ProductDocInteractionModels(
      syntheticSource,
      syntheticMarkdown,
    ).single;

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

  group('B25 primary/alternate negation matching', () {
    Map<String, Object?> gardenClubRsvpReview(String visibleText) {
      final fanId = 'community-garden-club-member';
      return <String, Object?>{
        'screenRows': <Map<String, Object?>>[
          <String, Object?>{
            'rowId': 'garden-event-rsvp-result',
            'communityId': 'community_garden_club',
            'communityName': 'Garden Club',
            'workflowId': 'garden-event-rsvp',
            'role': 'member',
            'fanId': fanId,
            'visibleTextExtract': visibleText,
            'screenshotPath': 'garden-event-rsvp.png',
          },
        ],
        'workflowRoleCoverage': <Map<String, Object?>>[
          <String, Object?>{
            'coverageRowId': 'garden-event-rsvp-member',
            'communityId': 'community_garden_club',
            'communityName': 'Garden Club',
            'workflowId': 'garden-event-rsvp',
            'role': 'member',
            'fanId': fanId,
            'screenRowIds': <String>['garden-event-rsvp-result'],
            'missingEvidence': <String>[],
          },
        ],
      };
    }

    Map<String, Object?> interactionModelFor(String visibleText) {
      final judged = buildB25WorkflowLifecycleReview(
        gardenClubRsvpReview(visibleText),
      );
      final scorecard =
          (judged['workflowLifecycleScorecards'] as List<Object?>).single
              as Map<String, Object?>;
      return scorecard['semanticInteractionModel'] as Map<String, Object?>;
    }

    test('"Not attending" does not satisfy primary "attend"', () {
      final model = interactionModelFor('Not attending');
      expect(
        model['visiblePrimaryActions'],
        isEmpty,
        reason: 'a negation must not count as the term it negates',
      );
      expect(model['visibleAlternateActions'], contains('not attending'));
      expect(model['status'], 'fail');
      expect(
        model['missingActions'],
        contains('domain-specific primary action'),
      );
    });

    test('"Cancel RSVP" does not satisfy primary "rsvp"', () {
      final model = interactionModelFor('Cancel RSVP');
      expect(
        model['visiblePrimaryActions'],
        isEmpty,
        reason: 'cancel rsvp is an alternate phrase, not a primary rsvp',
      );
      expect(model['visibleAlternateActions'], contains('cancel rsvp'));
      expect(model['status'], 'fail');
      expect(
        model['missingActions'],
        contains('domain-specific primary action'),
      );
    });

    test('"Going" satisfies primary "going"', () {
      final model = interactionModelFor('Going');
      expect(model['visiblePrimaryActions'], contains('going'));
      expect(model['status'], 'fail');
      expect(
        model['missingActions'],
        contains('domain-specific alternate/change/reject action'),
      );
    });

    test('decline-only screen fails instead of passing both bars', () {
      final model = interactionModelFor(
        'Not attending. Cancel RSVP. Change response.',
      );
      expect(model['visiblePrimaryActions'], isEmpty);
      expect(
        model['visibleAlternateActions'],
        contains('not attending'),
      );
      expect(model['visibleAlternateActions'], contains('cancel rsvp'));
      expect(model['status'], 'fail');
      expect(model['missingActions'], hasLength(1));
      expect(
        model['missingActions'],
        contains('domain-specific primary action'),
      );
    });

    test('a full happy-path plus alternate path still passes', () {
      final model = interactionModelFor(
        'Attend. Going. Not attending. Cancel RSVP.',
      );
      expect(model['visiblePrimaryActions'], contains('attend'));
      expect(model['visiblePrimaryActions'], contains('going'));
      expect(model['visibleAlternateActions'], contains('not attending'));
      expect(model['visibleAlternateActions'], contains('cancel rsvp'));
      expect(model['status'], 'pass');
    });
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
