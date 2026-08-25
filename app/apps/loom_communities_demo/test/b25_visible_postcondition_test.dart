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
        const postcondition = B25VisiblePostcondition.stateChange(
          'Critique withdrawn',
        );

        expect(
          postcondition.isSatisfiedBy(const <String>['Submitted for critique']),
          isFalse,
        );
      },
    );
  });
}
