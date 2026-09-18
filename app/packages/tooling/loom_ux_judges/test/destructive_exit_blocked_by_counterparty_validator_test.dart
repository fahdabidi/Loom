import 'dart:convert';
import 'dart:io';

import 'package:loom_ux_judges/src/validator/community_package_validator.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';
import 'package:loom_ux_judges/src/validator/workflow_validator.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

const _findingType = 'destructive_exit_blocked_by_counterparty';
const _workflowType = 'equipment-loan';
const _field = 'availabilityState';

/// A minimal loan-shaped fixture: one non-terminal state ("published") whose
/// real lifecycle lives in [_field], mirroring the archetype shape the
/// sibling `destructive_transition_ignores_availability_field` check already
/// documents -- an owner-only `delist` requires `availabilityState ==
/// "available"`, and a `take-loan`/`return-item` pair moves the field to and
/// from `"onLoan"`.
LoomWorkflowStateMachine _loanMachine({
  required bool clearingExclusiveToBorrower,
  bool addOwnerExitFromOnLoan = false,
  bool addNonExclusiveOverride = false,
}) => LoomWorkflowStateMachine.fromJson({
  'initialState': 'published',
  'states': {
    'published': {'label': 'Published'},
    'delisted': {'label': 'Delisted', 'isTerminal': true},
    if (addOwnerExitFromOnLoan)
      'delisted-pending-return': {
        'label': 'Delisted pending return',
        'isTerminal': true,
      },
  },
  'transitions': [
    {
      'id': 'take-loan',
      'label': 'Take loan',
      'from': ['published'],
      'to': null,
      'guard': {
        'allowedRoleIds': ['member'],
        'instanceDataEquals': {'key': _field, 'value': 'available'},
      },
      'effects': [
        {'op': 'set', 'key': _field, 'value': 'onLoan'},
      ],
    },
    {
      'id': 'return-item',
      'label': 'Return item',
      'from': ['published'],
      'to': null,
      'guard': {
        if (clearingExclusiveToBorrower)
          'actorEqualsField': {'key': 'borrowerFanId'}
        else
          'allowedRoleIds': ['member'],
        'instanceDataEquals': {'key': _field, 'value': 'onLoan'},
      },
      'effects': [
        {'op': 'set', 'key': _field, 'value': 'available'},
      ],
    },
    {
      'id': 'delist',
      'label': 'Delist',
      'from': ['published'],
      'to': 'delisted',
      'guard': {
        'actorEqualsField': {'key': 'ownerFanId'},
        'instanceDataEquals': {'key': _field, 'value': 'available'},
      },
    },
    if (addOwnerExitFromOnLoan)
      {
        'id': 'delist-while-on-loan',
        'label': 'Delist while on loan',
        'from': ['published'],
        'to': 'delisted-pending-return',
        'guard': {
          'actorEqualsField': {'key': 'ownerFanId'},
          'instanceDataEquals': {'key': _field, 'value': 'onLoan'},
        },
      },
    if (addNonExclusiveOverride)
      {
        'id': 'coordinator-override-return',
        'label': 'Coordinator return',
        'from': ['published'],
        'to': null,
        'guard': {
          'allowedRoleIds': ['coordinator'],
          'instanceDataEquals': {'key': _field, 'value': 'onLoan'},
        },
        'effects': [
          {'op': 'set', 'key': _field, 'value': 'available'},
        ],
      },
  ],
  'renderBindings': [
    {
      'states': ['published'],
      'audience': 'any',
      'tabId': 'marketplace',
      'cardSurfaceFamily': 'equipment-loan',
      'bindingKind': 'primary',
      'actions': [
        {
          'kind': 'create',
          'label': 'List item',
          'byRoleIds': ['member'],
          'scope': 'tab',
          'presentation': 'fab',
          'prefill': {'ownerFanId': r'$actor', _field: 'available'},
        },
      ],
    },
  ],
  'instanceDataSchema': {
    'ownerFanId': {'type': 'fanId'},
    'borrowerFanId': {'type': 'fanId?'},
    _field: {'type': 'text', 'writableBy': 'effect'},
  },
}, _workflowType);

/// The "giveaway" shape: the counterparty's only transition off
/// `"available"` is atomic to a terminal state (no intermediate value of
/// [_field] is ever reachable), so there is nothing for the owner's `delist`
/// to be stranded behind.
LoomWorkflowStateMachine _giveawayMachine() =>
    LoomWorkflowStateMachine.fromJson({
      'initialState': 'published',
      'states': {
        'published': {'label': 'Published'},
        'delisted': {'label': 'Delisted', 'isTerminal': true},
        'given': {'label': 'Given away', 'isTerminal': true},
      },
      'transitions': [
        {
          'id': 'delist',
          'label': 'Delist',
          'from': ['published'],
          'to': 'delisted',
          'guard': {
            'actorEqualsField': {'key': 'ownerFanId'},
            'instanceDataEquals': {'key': _field, 'value': 'available'},
          },
        },
        {
          'id': 'claim-giveaway',
          'label': 'Claim',
          'from': ['published'],
          'to': 'given',
          'guard': {
            'allowedRoleIds': ['member'],
            'instanceDataEquals': {'key': _field, 'value': 'available'},
          },
          'effects': [
            {'op': 'set', 'key': _field, 'value': 'given'},
          ],
        },
      ],
      'renderBindings': [
        {
          'states': ['published'],
          'audience': 'any',
          'tabId': 'marketplace',
          'cardSurfaceFamily': 'equipment-loan',
          'bindingKind': 'primary',
          'actions': [
            {
              'kind': 'create',
              'label': 'List item',
              'byRoleIds': ['member'],
              'scope': 'tab',
              'presentation': 'fab',
              'prefill': {'ownerFanId': r'$actor', _field: 'available'},
            },
          ],
        },
      ],
      'instanceDataSchema': {
        'ownerFanId': {'type': 'fanId'},
        _field: {'type': 'text', 'writableBy': 'effect'},
      },
    }, _workflowType);

List<ValidationFinding> _findings(LoomWorkflowStateMachine machine) =>
    WorkflowValidator()
        .validate({_workflowType: machine})
        .findings
        .where((finding) => finding.type == _findingType)
        .toList(growable: false);

Directory _repositoryRoot() {
  var directory = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (Directory(
      '${directory.path}/docs/references/communities',
    ).existsSync()) {
      return directory;
    }
    final parent = directory.parent;
    if (parent.path == directory.path) break;
    directory = parent;
  }
  throw StateError(
    'Could not locate the repository root from ${Directory.current.path}.',
  );
}

List<File> _corpusFiles() {
  final directory = Directory(
    '${_repositoryRoot().path}/docs/references/communities',
  );
  return directory
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.jsonc'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

void main() {
  group('destructive_exit_blocked_by_counterparty', () {
    test('flags exactly one stranded value when the only clearing transition '
        'is exclusive to a different party', () {
      final findings = _findings(
        _loanMachine(clearingExclusiveToBorrower: true),
      );

      expect(findings, hasLength(1));
      final finding = findings.single;
      expect(finding.isWarning, isTrue);
      expect(finding.message, contains('ownerFanId'));
      expect(finding.message, contains(_field));
      expect(finding.message, contains('onLoan'));
      expect(finding.location, '$_workflowType/instanceDataSchema/$_field');
    });

    test('stays quiet when the clearing transition is role-guarded instead of '
        'exclusive to a different party', () {
      expect(
        _findings(_loanMachine(clearingExclusiveToBorrower: false)),
        isEmpty,
      );
    });

    test('stays quiet when the counterparty transition is atomic to a '
        'terminal state (the giveaway shape)', () {
      expect(_findings(_giveawayMachine()), isEmpty);
    });

    test('stays quiet when the owner has their own exit directly from the '
        'stranded value', () {
      expect(
        _findings(
          _loanMachine(
            clearingExclusiveToBorrower: true,
            addOwnerExitFromOnLoan: true,
          ),
        ),
        isEmpty,
      );
    });

    test('stays quiet when a non-exclusive coordinator override clears the '
        'stranded value', () {
      expect(
        _findings(
          _loanMachine(
            clearingExclusiveToBorrower: true,
            addNonExclusiveOverride: true,
          ),
        ),
        isEmpty,
      );
    });

    test('flags exactly garden-tool-loan across the shipped corpus', () {
      final flaggedByWorkflowType = <String, List<ValidationFinding>>{};
      for (final file in _corpusFiles()) {
        final decoded =
            jsonDecode(stripJsonComments(file.readAsStringSync()))
                as Map<String, dynamic>;
        final report = CommunityPackageValidator().validate(decoded);
        for (final finding in report.findings.where(
          (f) => f.type == _findingType,
        )) {
          final workflowType = finding.location.split('/').first;
          flaggedByWorkflowType
              .putIfAbsent(workflowType, () => [])
              .add(finding);
        }
      }

      expect(flaggedByWorkflowType.keys.toSet(), {'garden-tool-loan'});
      expect(flaggedByWorkflowType['book-shared-library-item'], isNull);
      expect(flaggedByWorkflowType['gear-loan-request'], isNull);
    });
  });
}
