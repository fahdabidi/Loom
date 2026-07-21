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
    ValidationReport actionReport(
      List<Map<String, dynamic>> actions, {
      List<Map<String, dynamic>> transitions = const [
        {
          'id': 'approve',
          'label': 'Approve',
          'from': ['start'],
          'to': 'done',
          'inputs': {
            'note': {'type': 'text'},
          },
        },
      ],
      Map<String, LoomWorkflowStateMachine>? additionalWorkflows,
    }) {
      final machine = _machine(
        'test',
        transitions: transitions,
        renderBindings: [
          {
            'states': ['start'],
            'role': 'any',
            'tabId': 'home',
            'cardSurfaceFamily': 'default',
            'bindingKind': 'primary',
            'actions': actions,
          },
        ],
      );
      return _validateWorkflows({'test': machine, ...?additionalWorkflows});
    }

    void actionRule(
      String type,
      Map<String, dynamic> invalid,
      Map<String, dynamic> valid, {
      List<Map<String, dynamic>> transitions = const [
        {
          'id': 'approve',
          'label': 'Approve',
          'from': ['start'],
          'to': 'done',
          'inputs': {
            'note': {'type': 'text'},
          },
        },
      ],
      Map<String, LoomWorkflowStateMachine>? additionalWorkflows,
    }) {
      test('$type: flags invalid action', () {
        expect(
          _hasError(actionReport([invalid], transitions: transitions, additionalWorkflows: additionalWorkflows), type),
          isTrue,
        );
      });
      test('$type: valid action passes', () {
        expect(
          actionReport([valid], transitions: transitions, additionalWorkflows: additionalWorkflows)
              .errors
              .where((finding) => finding.type == type),
          isEmpty,
        );
      });
    }

    // CALR.4c: complete grammar-v2 actions[] validation rules.
    actionRule('unknown_action_kind', {'kind': 'archive'}, {'kind': 'create'});
    actionRule(
      'unknown_action_scope',
      {'kind': 'create', 'scope': 'card'},
      {'kind': 'create', 'scope': 'instance'},
    );
    actionRule(
      'unknown_action_presentation',
      {'kind': 'create', 'presentation': 'menu'},
      {'kind': 'create', 'presentation': 'fab'},
    );
    actionRule(
      'tab_action_cannot_be_button',
      {'kind': 'create', 'scope': 'tab', 'presentation': 'button'},
      {'kind': 'create', 'scope': 'instance', 'presentation': 'button'},
    );

    final targetWorkflow = _machine(
      'target',
      transitions: const [
        {'id': 'go', 'label': 'Go', 'from': ['start'], 'to': 'done'},
      ],
    );
    actionRule(
      'dangling_action_workflow_type',
      {'kind': 'create', 'workflowType': 'missing'},
      {'kind': 'create', 'workflowType': 'target'},
      additionalWorkflows: {'target': targetWorkflow},
    );
    actionRule(
      'create_action_cannot_set_inputs',
      {
        'kind': 'create',
        'inputs': {'note': 'not allowed'},
      },
      {'kind': 'create', 'prefill': const <String, dynamic>{}},
    );
    actionRule(
      'dangling_action_transition_id',
      {'kind': 'transition', 'transitionId': 'missing'},
      {'kind': 'transition', 'transitionId': 'approve'},
    );
    actionRule(
      'transition_action_cannot_be_tab_scoped',
      {'kind': 'transition', 'transitionId': 'approve', 'scope': 'tab'},
      {'kind': 'transition', 'transitionId': 'approve', 'scope': 'instance'},
    );
    actionRule(
      'transition_action_cannot_set_workflow_type',
      {'kind': 'transition', 'transitionId': 'approve', 'workflowType': 'test'},
      {'kind': 'transition', 'transitionId': 'approve'},
    );
    actionRule(
      'transition_action_cannot_set_prefill',
      {'kind': 'transition', 'transitionId': 'approve', 'prefill': const <String, dynamic>{}},
      {'kind': 'transition', 'transitionId': 'approve', 'inputs': const <String, dynamic>{}},
    );
    actionRule(
      'transition_action_cannot_set_by_persona_ids',
      {
        'kind': 'transition',
        'transitionId': 'approve',
        'byPersonaIds': ['member'],
      },
      {'kind': 'transition', 'transitionId': 'approve'},
    );
    actionRule(
      'unknown_action_input_reference',
      {
        'kind': 'transition',
        'transitionId': 'approve',
        'inputs': {'missing': 'value'},
      },
      {
        'kind': 'transition',
        'transitionId': 'approve',
        'inputs': {'note': 'value'},
      },
    );
    test('duplicate_action_transition_id: flags duplicate transition actions', () {
      expect(
        _hasError(
          actionReport([
            {'kind': 'transition', 'transitionId': 'approve'},
            {'kind': 'transition', 'transitionId': 'approve'},
          ]),
          'duplicate_action_transition_id',
        ),
        isTrue,
      );
    });
    test('duplicate_action_transition_id: distinct transition actions pass', () {
      expect(
        actionReport(
          [
            {'kind': 'transition', 'transitionId': 'approve'},
            {'kind': 'transition', 'transitionId': 'reject'},
          ],
          transitions: const [
            {'id': 'approve', 'label': 'Approve', 'from': ['start'], 'to': 'done'},
            {'id': 'reject', 'label': 'Reject', 'from': ['start'], 'to': 'done'},
          ],
        ).errors.where((finding) => finding.type == 'duplicate_action_transition_id'),
        isEmpty,
      );
    });

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
    // 4. create-action byPersonaIds dangling persona (uses
    //    dangling_allowed_persona_id)
    // ---------------------------------------------------------------
    test('dangling_allowed_persona_id: flags unknown persona in create action', () {
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
            'actions': [
              {
                'kind': 'create',
                'byPersonaIds': ['ghost-persona'],
                'label': 'Create',
              },
            ],
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
            'actions': [
              {
                'kind': 'create',
                'byPersonaIds': ['real-persona'],
                'label': 'Create',
              },
            ],
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
    // 5. create-action prefill field checks
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
            'actions': [
              {
                'kind': 'create',
                'byPersonaIds': ['real-persona'],
                'label': 'Create',
                'prefill': {'notInSchema': 'value'},
              },
            ],
          },
        ],
        schema: {
          'title': {'type': 'text', 'writableBy': 'formEntry'},
        },
      );

      final report = _validateWorkflows({'test': machine});
      expect(_hasError(report, 'dangling_instance_data_key'), isTrue);
    });

    test('create prefill uses the workflowType override schema', () {
      final source = _machine(
        'tournament-event',
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
            'actions': [
              {
                'kind': 'create',
                'workflowType': 'tournament-ballot',
                'label': 'Create ballot for this tournament',
                'prefill': {'eventId': '{context.id}'},
              },
            ],
          },
        ],
        schema: {
          'title': {'type': 'text', 'writableBy': 'formEntry'},
        },
      );
      final target = _machine(
        'tournament-ballot',
        transitions: [
          {
            'id': 'go',
            'label': 'Go',
            'from': ['start'],
            'to': 'done',
          },
        ],
        schema: {
          'eventId': {'type': 'text', 'writableBy': 'formEntry'},
        },
      );

      final report = _validateWorkflows({
        'tournament-event': source,
        'tournament-ballot': target,
      });

      expect(
        report.errors.where((f) =>
            f.type == 'dangling_instance_data_key' &&
            f.location.endsWith('actions/prefill/eventId')),
        isEmpty,
      );
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
            'actions': [
              {
                'kind': 'create',
                'byPersonaIds': ['real-persona'],
                'label': 'Create',
                'prefill': {'total': '42'},
              },
            ],
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
            'actions': [
              {
                'kind': 'create',
                'byPersonaIds': ['real-persona'],
                'label': 'Create',
                'prefill': {'ballots': '[]'},
              },
            ],
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
    // 6. context_reference_outside_instance_action
    // ---------------------------------------------------------------
    test('context_reference_outside_instance_action: flags {context.x} in effect', () {
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
        _hasError(report, 'context_reference_outside_instance_action'),
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
        'context_reference_outside_instance_action',
        'invalid_source_query_syntax',
        'dangling_source_query_workflow_type',
        'unknown_action_kind',
        'unknown_action_scope',
        'unknown_action_presentation',
        'tab_action_cannot_be_button',
        'dangling_action_workflow_type',
        'create_action_cannot_set_inputs',
        'dangling_action_transition_id',
        'transition_action_cannot_be_tab_scoped',
        'transition_action_cannot_set_workflow_type',
        'transition_action_cannot_set_prefill',
        'transition_action_cannot_set_by_persona_ids',
        'unknown_action_input_reference',
        'duplicate_action_transition_id',
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
