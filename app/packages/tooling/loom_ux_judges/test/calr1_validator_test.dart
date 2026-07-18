import 'package:loom_ux_judges/src/validator/workflow_validator.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

LoomWorkflowStateMachine _machine(String type, Map<String, dynamic> json) =>
    LoomWorkflowStateMachine.fromJson(json, type);

void main() {
  test('validates relatedAggregate, responseTable, and filterableFacets', () {
    final response = _machine('response', {
      'initialState': 'pending',
      'states': {
        'pending': {'label': 'Pending'},
        'going': {'label': 'Going'},
      },
      'transitions': <Map<String, dynamic>>[],
      'instanceDataSchema': {
        'eventId': {'type': 'text'},
      },
    });
    final event = _machine('event', {
      'initialState': 'open',
      'states': {
        'open': {'label': 'Open'},
      },
      'transitions': [
        {
          'id': 'go',
          'label': 'Go',
          'from': ['open'],
          'to': 'open',
          'guard': {
            'relatedAggregate': {
              'workflowType': 'missing',
              'filter': {'notAField': 'x'},
              'op': 'count',
              'comparator': '<',
              'compareTo': 2,
            },
          },
        },
      ],
      'instanceDataSchema': {
        'capacity': {'type': 'number'},
        'computed': {'type': 'number', 'formula': 'capacity'},
        'plain': {'type': 'text'},
      },
      'renderBindings': [
        {
          'states': ['open'],
          'role': 'any',
          'tabId': 'calendar',
          'cardSurfaceFamily': 'event-rsvp',
          'bindingKind': 'summary',
          'responseTable': {
            'workflowType': 'response',
            'eventField': 'missingField',
            'pendingStates': ['notAState'],
          },
          'filterableFacets': [
            {'field': 'plain', 'label': 'Plain'},
            {'field': 'computed', 'label': 'Computed'},
          ],
        },
      ],
    });
    final report = WorkflowValidator().validate({
      'event': event,
      'response': response,
    });
    expect(
      report.errors.map((finding) => finding.type),
      containsAll([
        'dangling_related_aggregate_workflow_type',
        'unknown_response_table_field',
        'unknown_response_table_state',
        'dangling_filterable_facet_field',
      ]),
    );
  });
}
