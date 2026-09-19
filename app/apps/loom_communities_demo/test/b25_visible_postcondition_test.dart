import 'package:flutter_test/flutter_test.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

import 'b25_visible_postcondition.dart';

void main() {
  group('B25 visible alternate postconditions', () {
    test(
      'requires the rendered value of a changed key in the active context',
      () {
        final visibility = b25DataChangeVisibility(
          sourceInstanceData: <String, dynamic>{'issueLog': <Object?>[]},
          resultInstanceData: <String, dynamic>{
            'issueLog': <Object?>[
              <String, Object?>{'description': 'Front element scratched'},
            ],
          },
          instanceDataSchema: <String, InstanceDataField>{
            'issueLog': const InstanceDataField(
              type: 'list',
              labelTemplate: '{value.length} reported issues',
              displayContexts: <String>['tile'],
              hideWhenEmpty: true,
            ),
          },
          displayContext: 'tile',
        );
        final postcondition = B25VisiblePostcondition.sourceInstanceEffect(
          visibility,
        );

        expect(visibility.changedKeys, <String>['issueLog']);
        expect(visibility.renderableKeys, <String>['issueLog']);
        expect(visibility.renderedTextCandidatesByKey['issueLog'], <String>[
          '1 reported issues',
        ]);
        expect(
          postcondition.isSatisfiedBy(const <String>['1 reported issues']),
          isTrue,
        );
      },
    );

    test('uses the card display casing for identifier-like changed values', () {
      final visibility = b25DataChangeVisibility(
        sourceInstanceData: <String, dynamic>{'availabilityState': 'available'},
        resultInstanceData: <String, dynamic>{'availabilityState': 'requested'},
        instanceDataSchema: <String, InstanceDataField>{
          'availabilityState': const InstanceDataField(
            type: 'string',
            labelTemplate: 'Status: {value}',
            displayContexts: <String>['tile', 'detail'],
          ),
        },
        displayContext: 'tile',
      );
      final postcondition = B25VisiblePostcondition.sourceInstanceEffect(
        visibility,
      );

      expect(
        visibility.renderedTextCandidatesByKey['availabilityState'],
        <String>['Status: Requested'],
      );
      expect(
        postcondition.isSatisfiedBy(const <String>['Status: Requested']),
        isTrue,
      );
      expect(
        postcondition.isSatisfiedBy(const <String>[
          'Previously Status: Requested',
        ]),
        isFalse,
      );
    });

    test(
      'fails loudly when every changed key is excluded by display context',
      () {
        final visibility = b25DataChangeVisibility(
          sourceInstanceData: <String, dynamic>{'issueLog': <Object?>[]},
          resultInstanceData: <String, dynamic>{
            'issueLog': <Object?>[
              <String, Object?>{'description': 'Front element scratched'},
            ],
          },
          instanceDataSchema: <String, InstanceDataField>{
            'issueLog': const InstanceDataField(
              type: 'list',
              labelTemplate: '{value.length} reported issues',
              displayContexts: <String>['detail'],
              hideWhenEmpty: true,
            ),
          },
          displayContext: 'tile',
        );
        final postcondition = B25VisiblePostcondition.sourceInstanceEffect(
          visibility,
        );

        expect(visibility.changedKeys, <String>['issueLog']);
        expect(visibility.renderableKeys, isEmpty);
        expect(visibility.everyChangedKeyIsExcludedByDisplayContext, isTrue);
        expect(visibility.excludedDisplayContextsByKey, <String, List<String>>{
          'issueLog': <String>['detail'],
        });
        expect(
          postcondition.isSatisfiedBy(const <String>['1 reported issues']),
          isFalse,
        );
      },
    );

    test(
      'fails when the declared target-state label is absent from the viewport',
      () {
        final postcondition = B25VisiblePostcondition.stateChange(
          const <String>{'Critique withdrawn'},
        );

        expect(
          postcondition.isSatisfiedBy(const <String>['Submitted for critique']),
          isFalse,
        );
      },
    );

    test(
      'matches a state label rendered only through a labelTemplate-composed '
      'candidate',
      () {
        final candidates = b25StateLabelRenderCandidates(
          'Ownership transferred',
          <String, InstanceDataField>{
            'transferSummary': const InstanceDataField(
              type: 'text',
              labelTemplate: 'Transfer: {value}',
            ),
          },
        );
        final postcondition = B25VisiblePostcondition.stateChange(candidates);

        expect(
          postcondition.isSatisfiedBy(const <String>[
            'Transfer: Ownership transferred',
          ]),
          isTrue,
        );
      },
    );

    test(
      'does not treat a superstring decoy as a match for a '
      'labelTemplate-composed candidate',
      () {
        final candidates = b25StateLabelRenderCandidates(
          'Ownership transferred',
          <String, InstanceDataField>{
            'transferSummary': const InstanceDataField(
              type: 'text',
              labelTemplate: 'Transfer: {value}',
            ),
          },
        );
        final postcondition = B25VisiblePostcondition.stateChange(candidates);

        expect(
          postcondition.isSatisfiedBy(const <String>[
            'Transfer: Ownership transferred (pending review)',
          ]),
          isFalse,
          reason:
              'A superstring must not satisfy an exact-match postcondition '
              '-- product vocabulary collides on substrings, so loosening '
              'this to textContaining-style matching would reintroduce that '
              'hazard.',
        );
      },
    );
  });

  group('b25StateLabelRenderCandidates', () {
    test('always includes the bare state label', () {
      final candidates = b25StateLabelRenderCandidates(
        'Ownership transferred',
        <String, InstanceDataField>{},
      );

      expect(candidates, <String>{'Ownership transferred'});
    });

    test('composes the label through every declared labelTemplate', () {
      final candidates = b25StateLabelRenderCandidates(
        'Ownership transferred',
        <String, InstanceDataField>{
          'transferSummary': const InstanceDataField(
            type: 'text',
            labelTemplate: 'Transfer: {value}',
          ),
          'title': const InstanceDataField(
            type: 'text',
            labelTemplate: '{value}',
          ),
        },
      );

      expect(candidates, <String>{
        'Ownership transferred',
        'Transfer: Ownership transferred',
      });
    });

    test(
      'ignores a labelTemplate with no {value} placeholder and a '
      '{value.length} placeholder, since neither can carry the whole label',
      () {
        final candidates = b25StateLabelRenderCandidates(
          'Ownership transferred',
          <String, InstanceDataField>{
            'staticLabelField': const InstanceDataField(
              type: 'text',
              labelTemplate: 'Fixed caption',
            ),
            'queueField': const InstanceDataField(
              type: 'list',
              labelTemplate: 'Queue: {value.length}',
            ),
          },
        );

        expect(candidates, <String>{'Ownership transferred'});
      },
    );
  });
}
