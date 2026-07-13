import 'package:loom_ux_judges/src/validator/workflow_validator.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

LoomWorkflowStateMachine _machine(Map<String, dynamic> schema) =>
    LoomWorkflowStateMachine.fromJson({
      'initialState': 'done',
      'states': {
        'done': {'label': 'Done', 'isTerminal': true},
      },
      'transitions': <Map<String, dynamic>>[],
      'instanceDataSchema': schema,
    }, 'formula-test');

void main() {
  group('V3 Milestone 1.1 formula validator checks', () {
    test('reports unknown field reference in formula', () {
      final report = WorkflowValidator().validate({
        'formula-test': _machine({
          'total': {'type': 'number', 'formula': 'missing + 1'},
        }),
      });
      expect(
        report.errors.map((finding) => finding.type),
        contains('unknown_formula_field'),
      );
    });

    test('reports unknown formula function', () {
      final report = WorkflowValidator().validate({
        'formula-test': _machine({
          'items': {'type': 'list'},
          'total': {'type': 'number', 'formula': 'inventedAggregate(items)'},
        }),
      });
      expect(
        report.errors.map((finding) => finding.type),
        contains('unknown_formula_function'),
      );
    });

    test('reports circular formula dependency', () {
      final report = WorkflowValidator().validate({
        'formula-test': _machine({
          'first': {'type': 'number', 'formula': 'second + 1'},
          'second': {'type': 'number', 'formula': 'first + 1'},
        }),
      });
      expect(
        report.errors.map((finding) => finding.type),
        contains('circular_formula_dependency'),
      );
    });
  });
}
