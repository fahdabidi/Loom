import 'dart:convert';
import 'dart:io';

import 'package:loom_ux_judges/src/validator/workflow_validator.dart';
import 'package:loom_workflow_engine/src/models/workflow_models.dart';
import 'package:test/test.dart';

/// Helper: build a LoomWorkflowStateMachine from compact inline maps.
LoomWorkflowStateMachine makeMachine({
  required String workflowType,
  required String initialState,
  required Map<String, Map<String, dynamic>> states,
  required List<Map<String, dynamic>> transitions,
  List<Map<String, dynamic>> renderBindings = const [],
  Map<String, Map<String, dynamic>> instanceDataSchema = const {},
}) {
  return LoomWorkflowStateMachine(
    workflowType: workflowType,
    initialState: initialState,
    states: states.map(
      (k, v) => MapEntry(k, LoomWorkflowState.fromJson(v)),
    ),
    transitions: transitions
        .map((t) => LoomWorkflowTransition.fromJson(t))
        .toList(),
    renderBindings: renderBindings
        .map((b) => RenderBinding.fromJson(b))
        .toList(),
    instanceDataSchema: instanceDataSchema.map(
      (k, v) => MapEntry(k, InstanceDataField.fromJson(v)),
    ),
  );
}

/// Strips // and /* */ comments from JSONC content, string-aware
/// (replicates the logic in the CLI's _stripComments).
String _stripJsoncComments(String content) {
  final buf = StringBuffer();
  var i = 0;
  var inString = false;
  const space = ' ';

  while (i < content.length) {
    if (inString && content[i] == '\\' && i + 1 < content.length) {
      buf.write(content[i]);
      i++;
      buf.write(content[i]);
      i++;
      continue;
    }

    if (content[i] == '"') {
      inString = !inString;
      buf.write(content[i]);
      i++;
      continue;
    }

    if (!inString &&
        i + 1 < content.length &&
        content[i] == '/' &&
        content[i + 1] == '*') {
      buf.write(space); buf.write(space);
      i += 2;
      while (i + 1 < content.length) {
        if (content[i] == '*' && content[i + 1] == '/') {
          buf.write(space); buf.write(space);
          i += 2;
          break;
        }
        buf.write(content[i] == '\n' ? '\n' : space);
        i++;
      }
      continue;
    }

    if (!inString &&
        i + 1 < content.length &&
        content[i] == '/' &&
        content[i + 1] == '/') {
      buf.write(space); buf.write(space);
      i += 2;
      while (i < content.length && content[i] != '\n') {
        buf.write(space);
        i++;
      }
      if (i < content.length && content[i] == '\n') {
        buf.write('\n');
        i++;
      }
      continue;
    }

    buf.write(content[i]);
    i++;
  }

  return buf.toString().trim();
}

class _FixtureBundle {
  const _FixtureBundle({required this.workflows, required this.personas});

  final Map<String, LoomWorkflowStateMachine> workflows;
  final Set<String> personas;
}

String _resolveMarketplaceFixturePath() {
  const relativePath =
      'docs/Build Plan V2/Loom Communities Workflow Engine V2/'
      'Loom_Communities_Workflow_Engine_Marketplace_Example.jsonc';

  var directory = Directory.current;
  for (var i = 0; i < 8; i++) {
    final candidate = File('${directory.path}/$relativePath');
    if (candidate.existsSync()) {
      return candidate.path;
    }

    final parent = directory.parent;
    if (parent.path == directory.path) break;
    directory = parent;
  }

  throw const FileSystemException('Fixture not found', relativePath);
}

/// Loads workflow definitions from a JSONC file at [path],
/// using the same parsing logic as the CLI.
_FixtureBundle _loadFixtureBundle(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw FileSystemException('Fixture not found', path);
  }
  final content = _stripJsoncComments(file.readAsStringSync());
  final json = jsonDecode(content) as Map<String, dynamic>;

  final personas = <String>{};
  if (json['personas'] is List<dynamic>) {
    for (final persona in (json['personas'] as List<dynamic>)) {
      if (persona is String && persona.isNotEmpty) {
        personas.add(persona);
      }
    }
  }

  final defs = json['workflowDefinitions'] as Map<String, dynamic>? ?? json;

  final workflows = defs.map((k, v) {
    final definition = v as Map<String, dynamic>;
    return MapEntry(
      k,
      LoomWorkflowStateMachine.fromJson(definition, k),
    );
  });

  return _FixtureBundle(workflows: workflows, personas: personas);
}

void main() {
  group('Validator — stuck states', () {
    test('flags a non-terminal state with zero outgoing transitions', () {
      final stuck = makeMachine(
        workflowType: 'stuck-test',
        initialState: 'start',
        states: {
          'start': {'label': 'Start', 'isTerminal': false},
          'stuck': {'label': 'Stuck', 'isTerminal': false},
          'end': {'label': 'End', 'isTerminal': true},
        },
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['start'],
            'to': 'stuck',
          },
        ],
      );

      final report = WorkflowValidator().validate({'stuck-test': stuck});
      expect(report.passed, isFalse);
      expect(
        report.errors.any((f) =>
            f.type == 'stuck_state' && f.location.contains('stuck')),
        isTrue,
        reason: 'Expected a stuck_state error naming "stuck"',
      );
    });

    test('passes when every non-terminal state has at least one outgoing transition', () {
      final machine = makeMachine(
        workflowType: 'clean',
        initialState: 'a',
        states: {
          'a': {'label': 'A', 'isTerminal': false},
          'b': {'label': 'B', 'isTerminal': true},
        },
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['a'],
            'to': 'b',
          },
        ],
      );

      final report = WorkflowValidator().validate({'clean': machine});
      expect(report.errors.where((f) => f.type == 'stuck_state'), isEmpty);
    });

    test('regression guard: marketplace "queued" state bug', () {
      final machine = makeMachine(
        workflowType: 'buggy',
        initialState: 'available',
        states: {
          'available': {'label': 'Available', 'isTerminal': false},
          'onLoan': {'label': 'On loan', 'isTerminal': false},
          'queued': {'label': 'Queue open', 'isTerminal': false},
        },
        transitions: [
          {
            'id': 'borrow',
            'label': 'Borrow',
            'from': ['available'],
            'to': 'onLoan',
          },
          {
            'id': 'return',
            'label': 'Return',
            'from': ['onLoan'],
            'to': 'available',
          },
        ],
      );

      final report = WorkflowValidator().validate({'buggy': machine});
      expect(report.passed, isFalse);
      expect(
        report.errors.any((f) =>
            f.type == 'stuck_state' && f.location.contains('queued')),
        isTrue,
        reason: 'Expected a stuck_state error naming "queued" — '
            'this is the regression guard for the original marketplace bug',
      );
    });
  });

  group('Validator — unreachable states', () {
    test('flags a state that is never targeted by any transition', () {
      final machine = makeMachine(
        workflowType: 'unreachable-test',
        initialState: 'a',
        states: {
          'a': {'label': 'A'},
          'b': {'label': 'B'},
          'orphan': {'label': 'Orphan'},
        },
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['a'],
            'to': 'b',
          },
        ],
      );

      final report = WorkflowValidator().validate({'unreachable-test': machine});
      expect(report.passed, isFalse);
      expect(
        report.errors.any((f) =>
            f.type == 'unreachable_state' && f.location.contains('orphan')),
        isTrue,
        reason: 'Expected an unreachable_state error naming "orphan"',
      );
    });

    test('passes when all states are reachable from initialState', () {
      final machine = makeMachine(
        workflowType: 'connected',
        initialState: 'a',
        states: {
          'a': {'label': 'A'},
          'b': {'label': 'B'},
          'c': {'label': 'C'},
        },
        transitions: [
          {
            'id': 'a2b',
            'label': 'A to B',
            'from': ['a'],
            'to': 'b',
          },
          {
            'id': 'b2c',
            'label': 'B to C',
            'from': ['b'],
            'to': 'c',
          },
        ],
      );

      final report = WorkflowValidator().validate({'connected': machine});
      expect(report.errors.where((f) => f.type == 'unreachable_state'), isEmpty);
    });
  });

  group('Validator — dangling references', () {
    test('flags dangling requiresWorkflowsComplete target', () {
      final machine = makeMachine(
        workflowType: 'dangling-dep-test',
        initialState: 'a',
        states: {
          'a': {'label': 'A'},
          'b': {'label': 'B'},
        },
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['a'],
            'to': 'b',
            'guard': {
              'requiresWorkflowsComplete': ['non-existent-workflow'],
            },
          },
        ],
      );

      final report = WorkflowValidator().validate({'dangling-dep-test': machine});
      expect(report.passed, isFalse);
      expect(
        report.errors.any((f) =>
            f.type == 'dangling_requires_workflows_complete' &&
            f.message.contains('non-existent-workflow')),
        isTrue,
      );
    });

    test('warns on dangling linkedWorkflowId', () {
      final machine = makeMachine(
        workflowType: 'dangling-link-test',
        initialState: 'a',
        states: {
          'a': {'label': 'A'},
          'b': {'label': 'B'},
        },
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['a'],
            'to': 'b',
            'linkedWorkflowId': 'non-existent-link',
          },
        ],
      );

      final report = WorkflowValidator().validate({'dangling-link-test': machine});
      expect(report.warnings.any((f) =>
          f.type == 'dangling_linked_workflow_id' &&
          f.message.contains('non-existent-link')), isTrue);
    });

    test('validates allowedPersonaIds against the supplied persona registry', () {
      final a = makeMachine(
        workflowType: 'persona-source',
        initialState: 'start',
        states: {
          'start': {'label': 'Start'},
          'end': {'label': 'End', 'isTerminal': true},
        },
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['start'],
            'to': 'end',
            'guard': {'allowedPersonaIds': ['known-user', 'typo-user']},
          },
        ],
      );

      final b = makeMachine(
        workflowType: 'bad-persona',
        initialState: 'start',
        states: {
          'start': {'label': 'Start'},
          'end': {'label': 'End', 'isTerminal': true},
        },
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['start'],
            'to': 'end',
            'guard': {
              'allowedPersonaIds': ['known-user'],
            },
          },
        ],
      );

      final c = makeMachine(
        workflowType: 'bad-persona-dup',
        initialState: 'start',
        states: {
          'start': {'label': 'Start'},
          'end': {'label': 'End', 'isTerminal': true},
        },
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['start'],
            'to': 'end',
            'guard': {
              'allowedPersonaIds': ['typo-user'],
            },
          },
        ],
      );

      final report = WorkflowValidator(
        knownPersonaIds: {'known-user'},
      ).validate({
        'persona-source': a,
        'bad-persona': b,
        'bad-persona-dup': c,
      });

      final warnings = report.warnings
          .where((f) => f.type == 'dangling_allowed_persona_id')
          .toList();

      expect(
        warnings.length,
        equals(2),
        reason: 'The same typo repeated in two workflows should produce two warnings',
      );
      expect(
        warnings.any((f) => f.message.contains('known-user')),
        isFalse,
        reason: 'A valid persona ID in the supplied registry should not be flagged',
      );
      expect(
        report.warnings.any((f) =>
            f.type == 'dangling_allowed_persona_id' &&
            f.message.contains('typo-user')),
        isTrue,
        reason: 'Expected dangling_allowed_persona_id warnings for typo-user',
      );
    });

    test('flags a missing allowedPersonaIds entry', () {
      final machine = makeMachine(
        workflowType: 'bad-allowed-persona',
        initialState: 'start',
        states: {
          'start': {'label': 'Start'},
          'end': {'label': 'End', 'isTerminal': true},
        },
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['start'],
            'to': 'end',
            'guard': {
              'allowedPersonaIds': ['unknown-user'],
            },
          },
        ],
      );

      final report = WorkflowValidator(knownPersonaIds: {'known-user'}).validate({
        'bad-allowed-persona': machine,
      });
      expect(
        report.warnings.any((f) =>
            f.type == 'dangling_allowed_persona_id' &&
            f.message.contains('unknown-user')),
        isTrue,
        reason: 'Expected a dangling_allowed_persona_id warning for unknown-user',
      );
    });

    test('flags dangling instanceDataSchema key in guard', () {
      final machine = makeMachine(
        workflowType: 'bad-guard-key',
        initialState: 'a',
        states: {
          'a': {'label': 'A'},
          'b': {'label': 'B'},
        },
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['a'],
            'to': 'b',
            'guard': {
              'actorInList': {'key': 'missingKey', 'present': false},
            },
          },
        ],
        instanceDataSchema: {
          'someField': {'type': 'text', 'writableBy': 'formEntry'},
        },
      );

      final report = WorkflowValidator().validate({'bad-guard-key': machine});
      expect(report.passed, isFalse);
      expect(
        report.errors.any((f) =>
            f.type == 'dangling_instance_data_key' &&
            f.message.contains('missingKey')),
        isTrue,
      );
    });

    test('flags dangling instanceDataSchema key in effect', () {
      final machine = makeMachine(
        workflowType: 'bad-effect-key',
        initialState: 'a',
        states: {
          'a': {'label': 'A'},
          'b': {'label': 'B'},
        },
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['a'],
            'to': 'b',
            'effects': [
              {'op': 'set', 'key': 'missingEffectKey', 'value': 'x'},
            ],
          },
        ],
        instanceDataSchema: {
          'someField': {'type': 'text', 'writableBy': 'formEntry'},
        },
      );

      final report = WorkflowValidator().validate({'bad-effect-key': machine});
      expect(report.passed, isFalse);
      expect(
        report.errors.any((f) =>
            f.type == 'dangling_instance_data_key' &&
            f.message.contains('missingEffectKey')),
        isTrue,
      );
    });
  });

  group('Validator — dependency cycles', () {
    test('detects a simple A→B→A cycle', () {
      final a = makeMachine(
        workflowType: 'cycle-a',
        initialState: 'start',
        states: {
          'start': {'label': 'Start'},
          'end': {'label': 'End', 'isTerminal': true},
        },
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['start'],
            'to': 'end',
            'guard': {
              'requiresWorkflowsComplete': ['cycle-b'],
            },
          },
        ],
      );

      final b = makeMachine(
        workflowType: 'cycle-b',
        initialState: 'init',
        states: {
          'init': {'label': 'Init'},
          'done': {'label': 'Done', 'isTerminal': true},
        },
        transitions: [
          {
            'id': 'proceed',
            'label': 'Proceed',
            'from': ['init'],
            'to': 'done',
            'guard': {
              'requiresWorkflowsComplete': ['cycle-a'],
            },
          },
        ],
      );

      final report = WorkflowValidator().validate({'cycle-a': a, 'cycle-b': b});
      expect(report.passed, isFalse);
      expect(
        report.errors.any((f) => f.type == 'dependency_cycle'),
        isTrue,
        reason: 'Expected a dependency_cycle error for the A→B→A cycle',
      );
    });

    test('detects a marketplace-to-giving cross-workflow cycle', () {
      final marketplace = makeMachine(
        workflowType: 'equipment-loan',
        initialState: 'published',
        states: {
          'published': {'label': 'Published'},
        },
        transitions: [
          {
            'id': 'borrow',
            'label': 'Request loan',
            'from': ['published'],
            'to': null,
            'guard': {
              'requiresWorkflowsComplete': ['tabletop-club-dues-payment'],
            },
          },
        ],
      );

      final giving = makeMachine(
        workflowType: 'tabletop-club-dues-payment',
        initialState: 'unpaid',
        states: {
          'unpaid': {'label': 'Dues pending'},
          'paid': {'label': 'Dues current', 'isTerminal': true},
        },
        transitions: [
          {
            'id': 'pay',
            'label': 'Pay dues',
            'from': ['unpaid'],
            'to': 'paid',
            'guard': {
              'requiresWorkflowsComplete': ['equipment-loan'],
            },
          },
        ],
      );

      final report = WorkflowValidator().validate({
        'equipment-loan': marketplace,
        'tabletop-club-dues-payment': giving,
      });

      expect(report.passed, isFalse);
      expect(report.errors.any((f) => f.type == 'dependency_cycle'), isTrue);
    });

    test('passes for a linear dependency chain with no cycle', () {
      final a = makeMachine(
        workflowType: 'linear-a',
        initialState: 'start',
        states: {
          'start': {'label': 'Start'},
          'end': {'label': 'End', 'isTerminal': true},
        },
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['start'],
            'to': 'end',
            'guard': {
              'requiresWorkflowsComplete': ['linear-b'],
            },
          },
        ],
      );

      final b = makeMachine(
        workflowType: 'linear-b',
        initialState: 'init',
        states: {
          'init': {'label': 'Init'},
          'done': {'label': 'Done', 'isTerminal': true},
        },
        transitions: [
          {
            'id': 'proceed',
            'label': 'Proceed',
            'from': ['init'],
            'to': 'done',
            'guard': {
              'requiresWorkflowsComplete': ['linear-c'],
            },
          },
        ],
      );

      final c = makeMachine(
        workflowType: 'linear-c',
        initialState: 'base',
        states: {
          'base': {'label': 'Base'},
          'final': {'label': 'Final', 'isTerminal': true},
        },
        transitions: [
          {
            'id': 'end',
            'label': 'End',
            'from': ['base'],
            'to': 'final',
          },
        ],
      );

      final report = WorkflowValidator().validate({
        'linear-a': a,
        'linear-b': b,
        'linear-c': c,
      });
      expect(report.errors.where((f) => f.type == 'dependency_cycle'), isEmpty);
    });
  });

  group('Validator — missing labels', () {
    test('flags a transition with an empty label', () {
      final machine = makeMachine(
        workflowType: 'no-label-test',
        initialState: 'a',
        states: {
          'a': {'label': 'A'},
          'b': {'label': 'B', 'isTerminal': true},
        },
        transitions: [
          {
            'id': 'go',
            'label': '',
            'from': ['a'],
            'to': 'b',
          },
        ],
      );

      final report = WorkflowValidator().validate({'no-label-test': machine});
      expect(report.passed, isFalse);
      expect(
        report.errors.any((f) =>
            f.type == 'missing_label' && f.message.contains('"go"')),
        isTrue,
      );
    });

    test('passes when all transitions have labels', () {
      final machine = makeMachine(
        workflowType: 'labeled',
        initialState: 'a',
        states: {
          'a': {'label': 'A'},
          'b': {'label': 'B', 'isTerminal': true},
        },
        transitions: [
          {
            'id': 'go',
            'label': 'Go to B',
            'from': ['a'],
            'to': 'b',
          },
        ],
      );

      final report = WorkflowValidator().validate({'labeled': machine});
      expect(report.errors.where((f) => f.type == 'missing_label'), isEmpty);
    });
  });

  group('Validator — binding cap', () {
    test('warns when renderBindings exceed 32', () {
      final bindings = <Map<String, dynamic>>[];
      for (var i = 0; i < 33; i++) {
        bindings.add({
          'states': ['a'],
          'role': 'any',
          'tabId': 'tab$i',
          'cardSurfaceFamily': 'family$i',
          'bindingKind': 'primary',
        });
      }

      final machine = makeMachine(
        workflowType: 'too-many-bindings',
        initialState: 'a',
        states: {
          'a': {'label': 'A'},
        },
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['a'],
            'to': 'a',
          },
        ],
        renderBindings: bindings,
      );

      final report = WorkflowValidator().validate({'too-many-bindings': machine});
      expect(
        report.warnings.any((f) =>
            f.type == 'binding_cap_exceeded' && f.message.contains('33')),
        isTrue,
        reason: 'Expected a warning about 33 bindings exceeding the 32 cap',
      );
    });

    test('warns when distinct roles exceed 16', () {
      final bindings = <Map<String, dynamic>>[];
      for (var i = 0; i < 17; i++) {
        bindings.add({
          'states': ['a'],
          'role': 'role$i',
          'tabId': 'tab$i',
          'cardSurfaceFamily': 'family$i',
          'bindingKind': 'primary',
        });
      }

      final machine = makeMachine(
        workflowType: 'too-many-roles',
        initialState: 'a',
        states: {
          'a': {'label': 'A'},
        },
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['a'],
            'to': 'a',
          },
        ],
        renderBindings: bindings,
      );

      final report = WorkflowValidator().validate({'too-many-roles': machine});
      expect(
        report.warnings.any((f) =>
            f.type == 'binding_cap_exceeded' && f.message.contains('17')),
        isTrue,
        reason: 'Expected a warning about 17 distinct roles exceeding the 16 cap',
      );
    });
  });

  group('Validator — editableFields references', () {
    test('flags an effect-only field in editableFields', () {
      final machine = makeMachine(
        workflowType: 'effect-in-editable',
        initialState: 'a',
        states: {
          'a': {
            'label': 'A',
            'editableFields': ['effectOnly'],
          },
          'b': {'label': 'B', 'isTerminal': true},
        },
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['a'],
            'to': 'b',
          },
        ],
        instanceDataSchema: {
          'effectOnly': {'type': 'text', 'writableBy': 'effect'},
          'userField': {'type': 'text', 'writableBy': 'formEntry'},
        },
      );

      final report = WorkflowValidator().validate({'effect-in-editable': machine});
      expect(report.passed, isFalse);
      expect(
        report.errors.any((f) =>
            f.type == 'effect_field_in_editable_fields' &&
            f.message.contains('effectOnly')),
        isTrue,
      );
    });

    test('passes when editableFields only reference formEntry fields', () {
      final machine = makeMachine(
        workflowType: 'clean-editable',
        initialState: 'a',
        states: {
          'a': {
            'label': 'A',
            'editableFields': ['userField'],
          },
          'b': {'label': 'B', 'isTerminal': true},
        },
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['a'],
            'to': 'b',
          },
        ],
        instanceDataSchema: {
          'userField': {'type': 'text', 'writableBy': 'formEntry'},
        },
      );

      final report = WorkflowValidator().validate({'clean-editable': machine});
      expect(report.errors.where(
          (f) => f.type == 'effect_field_in_editable_fields'), isEmpty);
    });

    test('flags editableFields referencing a missing schema key', () {
      final machine = makeMachine(
        workflowType: 'missing-editable-key',
        initialState: 'a',
        states: {
          'a': {
            'label': 'A',
            'editableFields': ['nonExistent'],
          },
          'b': {'label': 'B', 'isTerminal': true},
        },
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['a'],
            'to': 'b',
          },
        ],
        instanceDataSchema: {},
      );

      final report = WorkflowValidator().validate({'missing-editable-key': machine});
      expect(report.passed, isFalse);
      expect(
        report.errors.any((f) =>
            f.type == 'dangling_instance_data_key' &&
            f.message.contains('nonExistent')),
        isTrue,
      );
    });
  });

  group('Validator — action-button-row slot', () {
    test('flags a primary binding whose template lacks WorkflowActionButtonRow', () {
      final machine = makeMachine(
        workflowType: 'missing-slot',
        initialState: 'a',
        states: {
          'a': {'label': 'A'},
          'b': {'label': 'B', 'isTerminal': true},
        },
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['a'],
            'to': 'b',
          },
        ],
        renderBindings: [
          {
            'states': ['a'],
            'role': 'any',
            'tabId': 'tab1',
            'cardSurfaceFamily': 'bad-template',
            'bindingKind': 'primary',
          },
        ],
      );

      final templates = <String, Map<String, dynamic>>{
        'bad-template': {
          'slots': ['SomeOtherSlot'],
        },
      };

      final validator = WorkflowValidator(templates: templates);
      final report = validator.validate({'missing-slot': machine});
      expect(report.passed, isFalse);
      expect(
        report.errors.any((f) => f.type == 'missing_action_button_row'),
        isTrue,
        reason: 'Expected a missing_action_button_row error',
      );
    });

    test('passes when template includes WorkflowActionButtonRow', () {
      final machine = makeMachine(
        workflowType: 'has-slot',
        initialState: 'a',
        states: {
          'a': {'label': 'A'},
          'b': {'label': 'B', 'isTerminal': true},
        },
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['a'],
            'to': 'b',
          },
        ],
        renderBindings: [
          {
            'states': ['a'],
            'role': 'any',
            'tabId': 'tab1',
            'cardSurfaceFamily': 'good-template',
            'bindingKind': 'primary',
          },
        ],
      );

      final templates = <String, Map<String, dynamic>>{
        'good-template': {
          'slots': ['WorkflowActionButtonRow', 'FactPillRow'],
        },
      };

      final validator = WorkflowValidator(templates: templates);
      final report = validator.validate({'has-slot': machine});
      expect(
        report.errors.where((f) => f.type == 'missing_action_button_row'),
        isEmpty,
      );
    });

    test('does not flag summary bindings (only primary)', () {
      final machine = makeMachine(
        workflowType: 'summary-binding',
        initialState: 'a',
        states: {
          'a': {'label': 'A'},
          'b': {'label': 'B', 'isTerminal': true},
        },
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['a'],
            'to': 'b',
          },
        ],
        renderBindings: [
          {
            'states': ['a'],
            'role': 'actor',
            'tabId': 'tab1',
            'cardSurfaceFamily': 'bad-template',
            'bindingKind': 'summary',
          },
        ],
      );

      final templates = <String, Map<String, dynamic>>{
        'bad-template': {
          'slots': ['SomeOtherSlot'],
        },
      };

      final validator = WorkflowValidator(templates: templates);
      final report = validator.validate({'summary-binding': machine});
      expect(
        report.errors.where((f) => f.type == 'missing_action_button_row'),
        isEmpty,
        reason: 'Summary bindings should not be checked for the slot',
      );
    });
  });

  group('Validator — sortable column without backing field', () {
    test('flags a sortable column over a non-sortable field', () {
      final machine = makeMachine(
        workflowType: 'sortable-mismatch',
        initialState: 'a',
        states: {
          'a': {'label': 'A'},
          'b': {'label': 'B', 'isTerminal': true},
        },
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['a'],
            'to': 'b',
          },
        ],
        instanceDataSchema: {
          'title': {
            'type': 'text',
            'writableBy': 'formEntry',
            'sortable': false,
          },
        },
      );

      final tableConfigs = <String, Map<String, dynamic>>{
        'sortable-mismatch': {
          'columns': [
            {'key': 'title', 'sortable': true},
          ],
        },
      };

      final validator = WorkflowValidator(tableArchetypeConfigs: tableConfigs);
      final report = validator.validate({'sortable-mismatch': machine});
      expect(report.passed, isFalse);
      expect(
        report.errors.any(
            (f) => f.type == 'sortable_column_without_backing_field'),
        isTrue,
      );
    });

    test('passes when sortable column has backing sortable:true field', () {
      final machine = makeMachine(
        workflowType: 'sortable-ok',
        initialState: 'a',
        states: {
          'a': {'label': 'A'},
          'b': {'label': 'B', 'isTerminal': true},
        },
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['a'],
            'to': 'b',
          },
        ],
        instanceDataSchema: {
          'title': {
            'type': 'text',
            'writableBy': 'formEntry',
            'sortable': true,
          },
        },
      );

      final tableConfigs = <String, Map<String, dynamic>>{
        'sortable-ok': {
          'columns': [
            {'key': 'title', 'sortable': true},
          ],
        },
      };

      final validator = WorkflowValidator(tableArchetypeConfigs: tableConfigs);
      final report = validator.validate({'sortable-ok': machine});
      expect(
        report.errors
            .where((f) => f.type == 'sortable_column_without_backing_field'),
        isEmpty,
      );
    });
  });

  group('Validator — green path with real marketplace fixture', () {
    test('the actual .jsonc fixture parses and passes with zero findings', () {
      final fixturePath = _resolveMarketplaceFixturePath();
      final fixture = _loadFixtureBundle(fixturePath);
      expect(fixture.workflows.length, greaterThanOrEqualTo(2),
          reason: 'Fixture should contain at least equipment-loan and '
              'equipment-giveaway definitions');

      final report = WorkflowValidator(
        knownPersonaIds: fixture.personas,
      ).validate(fixture.workflows);
      expect(report.findings, isEmpty,
          reason: 'Real fixture should pass with zero findings.'
      );
    });
  });

  group('Validator — HOA documents fixture', () {
    test('the HOA documentLibrary fixture parses and passes with zero findings', () {
      final file = File(
        '../docs/Build Plan V2/Loom Communities Workflow Engine V2/'
        'Loom_Communities_Workflow_Engine_HOA_Documents_Example.jsonc',
      );
      final fallbackFile = File(
        '../../../../docs/Build Plan V2/Loom Communities Workflow Engine V2/'
        'Loom_Communities_Workflow_Engine_HOA_Documents_Example.jsonc',
      );
      final fixtureFile = file.existsSync() ? file : fallbackFile;
      final json = jsonDecode(_stripJsoncComments(fixtureFile.readAsStringSync()))
          as Map<String, dynamic>;
      final definitions = json['workflowDefinitions'] as Map<String, dynamic>;
      final machines = definitions.map(
        (key, value) => MapEntry(
          key,
          LoomWorkflowStateMachine.fromJson(value as Map<String, dynamic>, key),
        ),
      );
      final templates = (json['templates'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as Map<String, dynamic>),
      );
      final personaIds = (json['personaIds'] as List).cast<String>();

      final report = WorkflowValidator(
        templates: templates,
        knownPersonaIds: personaIds.toSet(),
      ).validate(machines);

      expect(report.errors, isEmpty);
      expect(report.warnings, isEmpty);
      expect(report.passed, isTrue);
    });
  });

  group('Validator - HOA architectural request fixture', () {
    test('the HOA request fixture parses and passes with zero findings', () {
      final file = File(
        '../docs/Build Plan V2/Loom Communities Workflow Engine V2/'
        'Loom_Communities_Workflow_Engine_HOA_Architectural_Request_Example.jsonc',
      );
      final fallbackFile = File(
        '../../../../docs/Build Plan V2/Loom Communities Workflow Engine V2/'
        'Loom_Communities_Workflow_Engine_HOA_Architectural_Request_Example.jsonc',
      );
      final fixtureFile = file.existsSync() ? file : fallbackFile;
      final json = jsonDecode(_stripJsoncComments(fixtureFile.readAsStringSync()))
          as Map<String, dynamic>;
      final definitions = json['workflowDefinitions'] as Map<String, dynamic>;
      final machines = definitions.map(
        (key, value) => MapEntry(
          key,
          LoomWorkflowStateMachine.fromJson(value as Map<String, dynamic>, key),
        ),
      );
      final templates = (json['templates'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as Map<String, dynamic>),
      );
      final personaIds = (json['personaIds'] as List).cast<String>();

      final report = WorkflowValidator(
        templates: templates,
        knownPersonaIds: personaIds.toSet(),
      ).validate(machines);

      expect(report.errors, isEmpty);
      expect(report.warnings, isEmpty);
      expect(report.passed, isTrue);
      expect(
        machines['cedar-commons-architectural-request']!
            .renderBindings
            .where((binding) => binding.role == 'receiver')
            .length,
        greaterThanOrEqualTo(2),
        reason: 'Fixture must declare reviewer dashboard and timeline bindings.',
      );
    });
  });

  group('Validator - HOA dues payment fixture', () {
    test('the HOA dues fixture reuses paymentCheckout and passes cleanly', () {
      final file = File(
        '../docs/Build Plan V2/Loom Communities Workflow Engine V2/'
        'Loom_Communities_Workflow_Engine_HOA_Dues_Payment_Example.jsonc',
      );
      final fallbackFile = File(
        '../../../../docs/Build Plan V2/Loom Communities Workflow Engine V2/'
        'Loom_Communities_Workflow_Engine_HOA_Dues_Payment_Example.jsonc',
      );
      final fixtureFile = file.existsSync() ? file : fallbackFile;
      final json = jsonDecode(_stripJsoncComments(fixtureFile.readAsStringSync()))
          as Map<String, dynamic>;
      final definitions = json['workflowDefinitions'] as Map<String, dynamic>;
      final machines = definitions.map(
        (key, value) => MapEntry(
          key,
          LoomWorkflowStateMachine.fromJson(value as Map<String, dynamic>, key),
        ),
      );
      final templates = (json['templates'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as Map<String, dynamic>),
      );
      final personaIds = (json['personas'] as List).cast<String>();

      expect(
        (templates['paymentCheckout']!['slots'] as List).cast<String>(),
        equals(['WorkflowFactPillRow', 'WorkflowActionButtonRow']),
        reason: 'HOA dues must reuse the Phase 3 paymentCheckout slot shape.',
      );

      final report = WorkflowValidator(
        templates: templates,
        knownPersonaIds: personaIds.toSet(),
      ).validate(machines);

      expect(report.errors, isEmpty);
      expect(report.warnings, isEmpty);
      expect(report.passed, isTrue);
    });
  });

  group('Validator - Garden Club migration fixture', () {
    test('the Garden Club Phase 5 fixture parses and passes cleanly', () {
      final file = File(
        '../docs/Build Plan V2/Loom Communities Workflow Engine V2/'
        'Loom_Communities_Workflow_Engine_GardenClub_Example.jsonc',
      );
      final fallbackFile = File(
        '../../../../docs/Build Plan V2/Loom Communities Workflow Engine V2/'
        'Loom_Communities_Workflow_Engine_GardenClub_Example.jsonc',
      );
      final fixtureFile = file.existsSync() ? file : fallbackFile;
      final json = jsonDecode(_stripJsoncComments(fixtureFile.readAsStringSync()))
          as Map<String, dynamic>;
      final definitions = json['workflowDefinitions'] as Map<String, dynamic>;
      final machines = definitions.map(
        (key, value) => MapEntry(
          key,
          LoomWorkflowStateMachine.fromJson(value as Map<String, dynamic>, key),
        ),
      );
      final templates = (json['templates'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as Map<String, dynamic>),
      );
      final personaIds = (json['personas'] as List).cast<String>();

      expect(machines.keys, contains('garden-event-rsvp'));
      expect(machines.keys, contains('garden-tool-loan'));
      expect(machines.keys, contains('plant-exchange-submission'));
      expect(machines.keys, contains('garden-volunteer-shift'));
      expect(machines.keys, contains('garden-export-custom-schemas'));

      final report = WorkflowValidator(
        templates: templates,
        knownPersonaIds: personaIds.toSet(),
      ).validate(machines);

      expect(report.errors, isEmpty);
      expect(report.warnings, isEmpty);
      expect(report.passed, isTrue);
    });
  });

  group('Validator - Camera Club migration fixture', () {
    test('the Camera Club Phase 5 fixture parses and passes cleanly', () {
      final file = File(
        '../docs/Build Plan V2/Loom Communities Workflow Engine V2/'
        'Loom_Communities_Workflow_Engine_CameraClub_Example.jsonc',
      );
      final fallbackFile = File(
        '../../../../docs/Build Plan V2/Loom Communities Workflow Engine V2/'
        'Loom_Communities_Workflow_Engine_CameraClub_Example.jsonc',
      );
      final fixtureFile = file.existsSync() ? file : fallbackFile;
      final json = jsonDecode(_stripJsoncComments(fixtureFile.readAsStringSync()))
          as Map<String, dynamic>;
      final definitions = json['workflowDefinitions'] as Map<String, dynamic>;
      final machines = definitions.map(
        (key, value) => MapEntry(
          key,
          LoomWorkflowStateMachine.fromJson(value as Map<String, dynamic>, key),
        ),
      );
      final templates = (json['templates'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as Map<String, dynamic>),
      );
      final personaIds = (json['personas'] as List).cast<String>();

      expect(machines.keys, contains('photo-walk-rsvp'));
      expect(machines.keys, contains('critique-submission'));
      expect(machines.keys, contains('gear-loan-request'));
      expect(machines.keys, contains('camera-validation-report'));

      final report = WorkflowValidator(
        templates: templates,
        knownPersonaIds: personaIds.toSet(),
      ).validate(machines);

      expect(report.errors, isEmpty);
      expect(report.warnings, isEmpty);
      expect(report.passed, isTrue);
    });
  });

  group('Validator - Book Club migration fixture', () {
    test('the Book Club Phase 5 fixture parses and passes cleanly', () {
      final file = File(
        '../docs/Build Plan V2/Loom Communities Workflow Engine V2/'
        'Loom_Communities_Workflow_Engine_BookClub_Example.jsonc',
      );
      final fallbackFile = File(
        '../../../../docs/Build Plan V2/Loom Communities Workflow Engine V2/'
        'Loom_Communities_Workflow_Engine_BookClub_Example.jsonc',
      );
      final fixtureFile = file.existsSync() ? file : fallbackFile;
      final json = jsonDecode(_stripJsoncComments(fixtureFile.readAsStringSync()))
          as Map<String, dynamic>;
      final definitions = json['workflowDefinitions'] as Map<String, dynamic>;
      final machines = definitions.map(
        (key, value) => MapEntry(
          key,
          LoomWorkflowStateMachine.fromJson(value as Map<String, dynamic>, key),
        ),
      );
      final templates = (json['templates'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as Map<String, dynamic>),
      );
      final personaIds = (json['personas'] as List).cast<String>();

      expect(machines.keys, contains('book-nomination'));
      expect(machines.keys, contains('book-vote'));
      expect(machines.keys, contains('book-library-item'));
      expect(machines.keys, contains('book-search-ai-digest'));
      expect(templates.keys, contains('votePoll'));
      expect(templates.keys, contains('searchAiAnswer'));

      final report = WorkflowValidator(
        templates: templates,
        knownPersonaIds: personaIds.toSet(),
      ).validate(machines);

      expect(report.errors, isEmpty);
      expect(report.warnings, isEmpty);
      expect(report.passed, isTrue);
    });
  });

  group('Validator - Chess Club migration fixture', () {
    test('the Chess Club Phase 5 fixture parses and passes cleanly', () {
      final file = File(
        '../docs/Build Plan V2/Loom Communities Workflow Engine V2/'
        'Loom_Communities_Workflow_Engine_ChessClub_Example.jsonc',
      );
      final fallbackFile = File(
        '../../../../docs/Build Plan V2/Loom Communities Workflow Engine V2/'
        'Loom_Communities_Workflow_Engine_ChessClub_Example.jsonc',
      );
      final fixtureFile = file.existsSync() ? file : fallbackFile;
      final json = jsonDecode(_stripJsoncComments(fixtureFile.readAsStringSync()))
          as Map<String, dynamic>;
      final definitions = json['workflowDefinitions'] as Map<String, dynamic>;
      final machines = definitions.map(
        (key, value) => MapEntry(
          key,
          LoomWorkflowStateMachine.fromJson(value as Map<String, dynamic>, key),
        ),
      );
      final templates = (json['templates'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as Map<String, dynamic>),
      );
      final personaIds = (json['personas'] as List).cast<String>();

      expect(machines.keys, contains('chess-match-meetup'));
      expect(machines.keys, contains('chess-match-result'));
      expect(machines.keys, contains('chess-rankings-table'));
      expect(templates['table']!['rankingMode'], isTrue);
      expect(
        machines['chess-match-result']!.transitions.any((transition) =>
            transition.id == 'submit-result' &&
            transition.effects.any((effect) => effect.key == 'rankingRows')),
        isTrue,
      );

      final report = WorkflowValidator(
        templates: templates,
        tableArchetypeConfigs: {'chess-rankings-table': templates['table']!},
        knownPersonaIds: personaIds.toSet(),
      ).validate(machines);

      expect(report.errors, isEmpty);
      expect(report.warnings, isEmpty);
      expect(report.passed, isTrue);
    });
  });
}
