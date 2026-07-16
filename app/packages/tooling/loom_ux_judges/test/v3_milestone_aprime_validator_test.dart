import 'dart:convert';
import 'dart:io';

import 'package:loom_ux_judges/src/validator/workflow_validator.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

LoomWorkflowStateMachine _machine(
  String workflowType, {
  Map<String, dynamic> schema = const {},
  Map<String, dynamic> guard = const {},
  List<Map<String, dynamic>> effects = const [],
  List<Map<String, dynamic>> renderBindings = const [],
  required List<Map<String, dynamic>> transitions,
}) {
  final txs = transitions.map((t) {
    final merged = <String, dynamic>{
      'id': 'go',
      'label': 'Go',
      'from': ['start'],
      'to': 'done',
      ...t,
    };
    return merged;
  }).toList();

  return LoomWorkflowStateMachine.fromJson({
    'initialState': 'start',
    'states': {
      'start': {'label': 'Start'},
      'done': {'label': 'Done', 'isTerminal': true},
    },
    'transitions': txs,
    'instanceDataSchema': schema,
    if (renderBindings.isNotEmpty) 'renderBindings': renderBindings,
  }, workflowType);
}

ValidationReport _validateWorkflows(
  Map<String, LoomWorkflowStateMachine> workflows, {
  Set<String>? knownPersonaIds,
}) {
  return WorkflowValidator(knownPersonaIds: knownPersonaIds)
      .validate(workflows);
}

bool _hasError(ValidationReport report, String type) =>
    report.errors.any((f) => f.type == type);

bool _hasWarning(ValidationReport report, String type) =>
    report.warnings.any((f) => f.type == type);

void main() {
  group('Phase A-prime validator checks', () {
    // ---------------------------------------------------------------
    // 1. unknown_input_type
    // ---------------------------------------------------------------
    test('unknown_input_type: flags unknown transition input type', () {
      final machine = _machine(
        'test',
        transitions: [
          {
            'inputs': {
              'choice': {'type': 'frobnicate', 'required': true},
            },
          },
        ],
      );
      final report = _validateWorkflows({'test': machine});
      expect(_hasError(report, 'unknown_input_type'), isTrue);
    });

    test('unknown_input_type: known types pass cleanly', () {
      final machine = _machine(
        'test',
        transitions: [
          {
            'inputs': {
              'choice': {'type': 'text', 'required': true},
              'count': {'type': 'number?'},
            },
          },
        ],
      );
      final report = _validateWorkflows({'test': machine});
      expect(
        report.errors.where((f) => f.type == 'unknown_input_type'),
        isEmpty,
      );
    });

    // ---------------------------------------------------------------
    // 2. unknown_input_reference
    // ---------------------------------------------------------------
    test('unknown_input_reference: flags {input.x} with no declared input', () {
      final machine = _machine(
        'test',
        transitions: [
          {
            'inputs': {
              'name': {'type': 'text'},
            },
            'effects': [
              {
                'op': 'set',
                'key': 'title',
                'value': '{input.missing}',
              },
            ],
          },
        ],
        schema: {
          'title': {'type': 'text', 'writableBy': 'effect'},
        },
      );
      final report = _validateWorkflows({'test': machine});
      expect(_hasError(report, 'unknown_input_reference'), isTrue);
    });

    test(
        'unknown_input_reference: {input.x} matching declared input passes',
        () {
      final machine = _machine(
        'test',
        transitions: [
          {
            'inputs': {
              'name': {'type': 'text'},
            },
            'effects': [
              {
                'op': 'set',
                'key': 'title',
                'value': '{input.name}',
              },
            ],
          },
        ],
        schema: {
          'title': {'type': 'text', 'writableBy': 'effect'},
        },
      );
      final report = _validateWorkflows({'test': machine});
      expect(
        report.errors.where((f) => f.type == 'unknown_input_reference'),
        isEmpty,
      );
    });

    test('unknown_input_reference: no inputs declared but effect uses {input.x}', () {
      final machine = _machine(
        'test',
        transitions: [
          {
            'effects': [
              {
                'op': 'set',
                'key': 'title',
                'value': '{input.anything}',
              },
            ],
          },
        ],
        schema: {
          'title': {'type': 'text', 'writableBy': 'effect'},
        },
      );
      final report = _validateWorkflows({'test': machine});
      expect(_hasError(report, 'unknown_input_reference'), isTrue);
    });

    // ---------------------------------------------------------------
    // 3. unknown_item_reference
    // ---------------------------------------------------------------
    test('unknown_item_reference: flags {item.x} not in target schema', () {
      final targetMachine = _machine(
        'target',
        transitions: [
          {
            'id': 'vote',
            'label': 'Vote',
            'from': ['start'],
            'to': 'done',
          },
        ],
        schema: {
          'choice': {'type': 'text'},
        },
      );

      final sourceMachine = _machine(
        'source',
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['start'],
            'to': 'done',
          },
        ],
        renderBindings: [
          {
            'states': ['start'],
            'role': 'any',
            'tabId': 'home',
            'cardSurfaceFamily': 'default',
            'bindingKind': 'primary',
            'repeater': {
              'source': 'query(target where choice == id)',
              'itemActions': [
                {
                  'transitionId': 'vote',
                  'inputs': {'choice': '{item.notAField}'},
                },
              ],
            },
          },
        ],
      );

      final report = _validateWorkflows({
        'source': sourceMachine,
        'target': targetMachine,
      });
      expect(_hasError(report, 'unknown_item_reference'), isTrue);
    });

    test('unknown_item_reference: valid {item.x} passes', () {
      final targetMachine = _machine(
        'target',
        transitions: [
          {
            'id': 'vote',
            'label': 'Vote',
            'from': ['start'],
            'to': 'done',
          },
        ],
        schema: {
          'choice': {'type': 'text'},
        },
      );

      final sourceMachine = _machine(
        'source',
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['start'],
            'to': 'done',
          },
        ],
        renderBindings: [
          {
            'states': ['start'],
            'role': 'any',
            'tabId': 'home',
            'cardSurfaceFamily': 'default',
            'bindingKind': 'primary',
            'repeater': {
              'source': 'query(target where choice == id)',
              'itemActions': [
                {
                  'transitionId': 'vote',
                  'inputs': {'choice': '{item.choice}'},
                },
              ],
            },
          },
        ],
      );

      final report = _validateWorkflows({
        'source': sourceMachine,
        'target': targetMachine,
      });
      expect(
        report.errors.where((f) => f.type == 'unknown_item_reference'),
        isEmpty,
      );
    });

    // ---------------------------------------------------------------
    // 4. creatable.byPersonaIds dangling persona (uses
    //    dangling_allowed_persona_id)
    // ---------------------------------------------------------------
    test('dangling_allowed_persona_id: flags unknown persona in creatable', () {
      final machine = _machine(
        'test',
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['start'],
            'to': 'done',
          },
        ],
        renderBindings: [
          {
            'states': ['start'],
            'role': 'any',
            'tabId': 'home',
            'cardSurfaceFamily': 'default',
            'bindingKind': 'primary',
            'creatable': {
              'byPersonaIds': ['ghost-persona'],
              'label': 'Create',
            },
          },
        ],
      );

      final report = _validateWorkflows(
        {'test': machine},
        knownPersonaIds: {'real-persona'},
      );
      expect(
        _hasWarning(report, 'dangling_allowed_persona_id'),
        isTrue,
      );
    });

    test('dangling_allowed_persona_id: known persona passes', () {
      final machine = _machine(
        'test',
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['start'],
            'to': 'done',
          },
        ],
        renderBindings: [
          {
            'states': ['start'],
            'role': 'any',
            'tabId': 'home',
            'cardSurfaceFamily': 'default',
            'bindingKind': 'primary',
            'creatable': {
              'byPersonaIds': ['real-persona'],
              'label': 'Create',
            },
          },
        ],
      );

      final report = _validateWorkflows(
        {'test': machine},
        knownPersonaIds: {'real-persona'},
      );
      expect(
        report.warnings
            .where((f) => f.type == 'dangling_allowed_persona_id'),
        isEmpty,
      );
    });

    // ---------------------------------------------------------------
    // 5. creatable.prefill field checks
    // ---------------------------------------------------------------
    test('dangling_instance_data_key: prefill key not in schema', () {
      final machine = _machine(
        'test',
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['start'],
            'to': 'done',
          },
        ],
        renderBindings: [
          {
            'states': ['start'],
            'role': 'any',
            'tabId': 'home',
            'cardSurfaceFamily': 'default',
            'bindingKind': 'primary',
            'creatable': {
              'byPersonaIds': ['real-persona'],
              'label': 'Create',
              'prefill': {'notInSchema': 'value'},
            },
          },
        ],
        schema: {
          'title': {'type': 'text', 'writableBy': 'formEntry'},
        },
      );

      final report = _validateWorkflows({'test': machine});
      expect(_hasError(report, 'dangling_instance_data_key'), isTrue);
    });

    test('computed_field_written_by_effect: prefill writes computed field', () {
      final machine = _machine(
        'test',
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['start'],
            'to': 'done',
          },
        ],
        renderBindings: [
          {
            'states': ['start'],
            'role': 'any',
            'tabId': 'home',
            'cardSurfaceFamily': 'default',
            'bindingKind': 'primary',
            'creatable': {
              'byPersonaIds': ['real-persona'],
              'label': 'Create',
              'prefill': {'total': '42'},
            },
          },
        ],
        schema: {
          'total': {'type': 'number', 'formula': '1 + 1'},
        },
      );

      final report = _validateWorkflows({'test': machine});
      expect(_hasError(report, 'computed_field_written_by_effect'), isTrue);
    });

    test('computed_field_written_by_effect: prefill writes source-backed field', () {
      final machine = _machine(
        'test',
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['start'],
            'to': 'done',
          },
        ],
        renderBindings: [
          {
            'states': ['start'],
            'role': 'any',
            'tabId': 'home',
            'cardSurfaceFamily': 'default',
            'bindingKind': 'primary',
            'creatable': {
              'byPersonaIds': ['real-persona'],
              'label': 'Create',
              'prefill': {'ballots': '[]'},
            },
          },
        ],
        schema: {
          'ballots': {
            'type': 'list',
            'source': 'query(target where ballotId == id)',
          },
        },
      );

      final report = _validateWorkflows({'test': machine});
      expect(_hasError(report, 'computed_field_written_by_effect'), isTrue);
    });

    // ---------------------------------------------------------------
    // 6. context_reference_outside_creatable
    // ---------------------------------------------------------------
    test('context_reference_outside_creatable: flags {context.x} in effect', () {
      final machine = _machine(
        'test',
        transitions: [
          {
            'effects': [
              {
                'op': 'set',
                'key': 'title',
                'value': '{context.viewerId}',
              },
            ],
          },
        ],
        schema: {
          'title': {'type': 'text', 'writableBy': 'effect'},
        },
      );
      final report = _validateWorkflows({'test': machine});
      expect(
        _hasError(report, 'context_reference_outside_creatable'),
        isTrue,
      );
    });

    // ---------------------------------------------------------------
    // 7. GAP-4 source query validation
    // ---------------------------------------------------------------
    test('invalid_source_query_syntax: malformed source query', () {
      final machine = _machine(
        'test',
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['start'],
            'to': 'done',
          },
        ],
        schema: {
          'ballots': {
            'type': 'list',
            'source': 'not a valid query',
          },
        },
      );
      final report = _validateWorkflows({'test': machine});
      expect(_hasError(report, 'invalid_source_query_syntax'), isTrue);
    });

    test('dangling_source_query_workflow_type: unknown workflowType', () {
      final machine = _machine(
        'test',
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['start'],
            'to': 'done',
          },
        ],
        schema: {
          'ballots': {
            'type': 'list',
            'source': 'query(nonexistent where field == id)',
          },
        },
      );
      final report = _validateWorkflows({'test': machine});
      expect(
        _hasError(report, 'dangling_source_query_workflow_type'),
        isTrue,
      );
    });

    test('source query: foreignField not in target schema', () {
      final target = _machine(
        'target',
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['start'],
            'to': 'done',
          },
        ],
        schema: {
          'realField': {'type': 'text'},
        },
      );

      final source = _machine(
        'source',
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['start'],
            'to': 'done',
          },
        ],
        schema: {
          'ballots': {
            'type': 'list',
            'source': 'query(target where missingField == id)',
          },
        },
      );

      final report = _validateWorkflows({
        'source': source,
        'target': target,
      });
      expect(_hasError(report, 'dangling_instance_data_key'), isTrue);
    });

    test('source query: localField not in own schema and not "id"', () {
      final target = _machine(
        'target',
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['start'],
            'to': 'done',
          },
        ],
        schema: {
          'realField': {'type': 'text'},
        },
      );

      final source = _machine(
        'source',
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['start'],
            'to': 'done',
          },
        ],
        schema: {
          'ballots': {
            'type': 'list',
            'source': 'query(target where realField == missingLocal)',
          },
        },
      );

      final report = _validateWorkflows({
        'source': source,
        'target': target,
      });
      expect(_hasError(report, 'dangling_instance_data_key'), isTrue);
    });

    test('source query: valid query with id as localField passes', () {
      final target = _machine(
        'target',
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['start'],
            'to': 'done',
          },
        ],
        schema: {
          'realField': {'type': 'text'},
        },
      );

      final source = _machine(
        'source',
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['start'],
            'to': 'done',
          },
        ],
        schema: {
          'ballots': {
            'type': 'list',
            'source': 'query(target where realField == id)',
          },
        },
      );

      final report = _validateWorkflows({
        'source': source,
        'target': target,
      });
      expect(
        report.errors.where((f) =>
            f.type == 'invalid_source_query_syntax' ||
            f.type == 'dangling_source_query_workflow_type' ||
            (f.type == 'dangling_instance_data_key' &&
                f.message.contains('source query'))),
        isEmpty,
      );
    });

    // ---------------------------------------------------------------
    // 8. Widen computed_field_written_by_effect for source-backed fields
    // ---------------------------------------------------------------
    test(
        'computed_field_written_by_effect: effect writes source-backed field',
        () {
      final machine = _machine(
        'test',
        transitions: [
          {
            'effects': [
              {
                'op': 'set',
                'key': 'ballots',
                'value': '[]',
              },
            ],
          },
        ],
        schema: {
          'ballots': {
            'type': 'list',
            'source': 'query(target where field == id)',
          },
        },
      );
      final report = _validateWorkflows({'test': machine});
      expect(_hasError(report, 'computed_field_written_by_effect'), isTrue);
    });

    test(
        'computed_field_written_by_effect: createInstance writes source-backed field',
        () {
      final target = _machine(
        'target',
        schema: {
          'ballots': {
            'type': 'list',
            'source': 'query(other where field == id)',
          },
        },
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['start'],
            'to': 'done',
          },
        ],
      );

      final source = _machine(
        'source',
        transitions: [
          {
            'effects': [
              {
                'op': 'createInstance',
                'workflowType': 'target',
                'fields': {'ballots': '[]'},
              },
            ],
          },
        ],
      );

      final report = _validateWorkflows({
        'source': source,
        'target': target,
      });
      expect(_hasError(report, 'computed_field_written_by_effect'), isTrue);
    });

    // ---------------------------------------------------------------
    // Helper: resolve the Tabletop Club fixture path by walking up
    // directories instead of using a fixed-depth relative path.
    // ---------------------------------------------------------------
    const _tabletopFixtureRelative =
        'docs/references/communities/Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc';

    File _resolveTabletopFixture() {
      var directory = Directory.current;
      for (var i = 0; i < 8; i++) {
        final candidate = File('${directory.path}/$_tabletopFixtureRelative');
        if (candidate.existsSync()) return candidate;
        final parent = directory.parent;
        if (parent.path == directory.path) break;
        directory = parent;
      }
      throw const FileSystemException('Fixture not found', _tabletopFixtureRelative);
    }

    // ---------------------------------------------------------------
    // Regression: frozen Tabletop Club JSON — zero new findings
    // ---------------------------------------------------------------
    test('frozen JSON: zero new findings against Tabletop Club example', () {
      // Read and strip JSONC comments
      final raw = _resolveTabletopFixture().readAsStringSync();
      final stripped = raw.replaceAll(RegExp(r'//[^\n]*'), '');
      final parsed = jsonDecode(stripped) as Map<String, dynamic>;

      final experience = parsed['experience'] as Map<String, dynamic>;
      final definitions =
          experience['workflowDefinitions'] as Map<String, dynamic>;

      final workflows = <String, LoomWorkflowStateMachine>{};
      for (final entry in definitions.entries) {
        workflows[entry.key] = LoomWorkflowStateMachine.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
          entry.key,
        );
      }

      final report = WorkflowValidator().validate(workflows);

      // Collect the finding types from the NEW checks only
      const newFindingTypes = {
        'unknown_input_type',
        'unknown_input_reference',
        'unknown_item_reference',
        'context_reference_outside_creatable',
        'invalid_source_query_syntax',
        'dangling_source_query_workflow_type',
      };

      final newFindings = report.findings
          .where((f) => newFindingTypes.contains(f.type))
          .toList();

      expect(
        newFindings,
        isEmpty,
        reason: 'New checks must not introduce false positives against '
            'the frozen Tabletop Club JSON. Got: ${newFindings.map((f) => '${f.type}: ${f.message}').join('\n')}',
      );
    });
  });
}
