import 'package:flutter_test/flutter_test.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

import 'b25_remote_arrangement.dart';

void main() {
  group('B25 remote arrangement', () {
    test(
      'a later-state row is out of scope and the next row still runs',
      () {
        final attempted = <String>[];
        Object? caught;
        attempted.add('garden-export-custom-schemas');
        try {
          planB25RemoteArrangement(
            machine: _gardenExportCustomSchemasMachine(),
            // The real shipped seed ("fall-export-package") sits in "ready",
            // not the workflow's own initial state "scope-selection" -- a
            // later-state row, which this dispatch does not sequence.
            currentState: 'ready',
            roleId: 'garden-coordinator',
            actorFanId: 'fan-garden-coordinator-1',
            seedInstanceData: const {},
            candidateTransitions: const [],
            // This machine declares no transitions at all, so no primary
            // match can ever be found from the initial state regardless of
            // this predicate -- it genuinely is a later-state row.
            matchesPrimaryTerm: (_) => true,
          );
        } catch (error) {
          caught = error;
        }
        attempted.add('garden-volunteer-shift');

        expect(attempted, ['garden-export-custom-schemas', 'garden-volunteer-shift']);
        expect(caught, isA<B25ArrangementOutOfScopeFailure>());
        expect(
          (caught as B25ArrangementOutOfScopeFailure).reason,
          allOf(
            contains('garden-export-custom-schemas'),
            contains('not its initial state'),
            contains('later-state row'),
          ),
        );
      },
    );

    test(
      'a later-state seed whose primary action fires from the initial '
      'state is arranged there, not thrown as later-state (mosque-'
      'announcement: the seed sits at "sent" while send-announcement fires '
      'from "draft")',
      () {
        final machine = _mosqueAnnouncementLikeMachine();
        final plan = planB25RemoteArrangement(
          machine: machine,
          // The real shipped seed sits at a later state than the workflow's
          // own initial state -- the seed is a DATA authority, not a STATE
          // authority, and the row's real primary action fires from "draft"
          // regardless of where the seed happens to sit.
          currentState: 'sent',
          roleId: 'masjid-admin',
          actorFanId: 'fan-masjid-admin-1',
          seedInstanceData: const {
            'title': 'Friday reminder',
            'body': "Jumu'ah starts at 1pm.",
          },
          candidateTransitions: const [],
          matchesPrimaryTerm: (transition) =>
              transition.id == 'send-announcement',
        );

        expect(plan.arrangedState, 'draft');
        expect(plan.creationBinding.tabId, 'announcements');
        expect(plan.fieldValues, {
          'title': 'Friday reminder',
          'body': "Jumu'ah starts at 1pm.",
        });
        expect(plan.syntheticInstanceData['authorFanId'], 'fan-masjid-admin-1');
      },
    );

    test(
      'a creation role that excludes the acting role is out of scope '
      '(garden-volunteer-shift: coordinator creates, member signs up)',
      () {
        Object? caught;
        try {
          planB25RemoteArrangement(
            machine: _gardenVolunteerShiftMachine(),
            currentState: 'open',
            // The B25 row for this workflow acts as `garden-member` (sign
            // up); only `garden-coordinator` may create a shift.
            roleId: 'garden-member',
            actorFanId: 'fan-garden-member-1',
            seedInstanceData: const {'shiftTitle': 'Mulch delivery'},
            candidateTransitions: const [],
            matchesPrimaryTerm: (_) => true,
          );
          fail('expected B25ArrangementOutOfScopeFailure');
        } catch (error) {
          caught = error;
        }
        expect(caught, isA<B25ArrangementOutOfScopeFailure>());
        expect(
          (caught as B25ArrangementOutOfScopeFailure).reason,
          allOf(
            contains('garden-volunteer-shift'),
            contains('no create action'),
            contains('two-identity row'),
          ),
        );
      },
    );

    test(
      'a formula guard that denies a self-created instance is out of scope '
      '(garden-tool-loan: ownerFanId == \$actor is denied)',
      () {
        final machine = _gardenToolLoanMachine();
        final requestLoan = machine.transitions.singleWhere(
          (transition) => transition.id == 'request-loan',
        );
        Object? caught;
        try {
          planB25RemoteArrangement(
            machine: machine,
            currentState: 'published',
            roleId: 'garden-member',
            actorFanId: 'fan-garden-member-1',
            seedInstanceData: const {
              'title': 'Steel wheelbarrow',
              'toolDescription': 'Sturdy wheelbarrow for moving mulch.',
              'ownerContactInfo': 'Private club message to member Alex',
            },
            candidateTransitions: [requestLoan],
            matchesPrimaryTerm: (transition) => transition.id == 'request-loan',
          );
          fail('expected B25ArrangementOutOfScopeFailure');
        } catch (error) {
          caught = error;
        }
        expect(caught, isA<B25ArrangementOutOfScopeFailure>());
        expect(
          (caught as B25ArrangementOutOfScopeFailure).reason,
          allOf(
            contains('garden-tool-loan'),
            contains('request-loan'),
            contains('second, different identity'),
          ),
        );
      },
    );

    test(
      'a non-primary candidate with an unknown formula verdict must not '
      'rescue a genuinely denied primary match (garden-tool-loan sits '
      'beside an unrelated, formula-less leave-queue)',
      () {
        final machine = _gardenToolLoanWithUnrelatedQueueTransitionMachine();
        final requestLoan = machine.transitions.singleWhere(
          (transition) => transition.id == 'request-loan',
        );
        final leaveQueue = machine.transitions.singleWhere(
          (transition) => transition.id == 'leave-queue',
        );
        Object? caught;
        try {
          planB25RemoteArrangement(
            machine: machine,
            currentState: 'published',
            roleId: 'garden-member',
            actorFanId: 'fan-garden-member-1',
            seedInstanceData: const {
              'title': 'Steel wheelbarrow',
              'toolDescription': 'Sturdy wheelbarrow for moving mulch.',
            },
            // leave-queue has no `formula` guard at all, so its verdict is
            // FormulaGuardVerdict.unknown. Before this fix, running
            // `.every(denied)` over BOTH candidates meant unknown != denied
            // defeated the whole check, and a genuinely, permanently denied
            // request-loan was never caught.
            candidateTransitions: [requestLoan, leaveQueue],
            matchesPrimaryTerm: (transition) => transition.id == 'request-loan',
          );
          fail('expected B25ArrangementOutOfScopeFailure');
        } catch (error) {
          caught = error;
        }
        expect(caught, isA<B25ArrangementOutOfScopeFailure>());
        expect(
          (caught as B25ArrangementOutOfScopeFailure).reason,
          allOf(
            contains('garden-tool-loan'),
            contains('request-loan'),
            isNot(contains('leave-queue')),
          ),
        );
      },
    );

    test(
      'a required field of an unsupported type is out of scope '
      '(plant-exchange-submission: pickupDate is a date picker)',
      () {
        Object? caught;
        try {
          planB25RemoteArrangement(
            machine: _plantExchangeSubmissionMachine(),
            currentState: 'draft',
            roleId: 'garden-member',
            actorFanId: 'fan-garden-member-1',
            seedInstanceData: const {
              'plantVariety': 'Tomato seedlings',
              'pickupWindow': 'Saturday mornings',
            },
            candidateTransitions: const [],
            matchesPrimaryTerm: (_) => true,
          );
          fail('expected B25ArrangementOutOfScopeFailure');
        } catch (error) {
          caught = error;
        }
        expect(caught, isA<B25ArrangementOutOfScopeFailure>());
        expect(
          (caught as B25ArrangementOutOfScopeFailure).reason,
          allOf(
            contains('plant-exchange-submission'),
            contains('"pickupDate"'),
            contains('"date"'),
          ),
        );
      },
    );

    test(
      'a required field with no seed value is out of scope', () {
        Object? caught;
        try {
          planB25RemoteArrangement(
            machine: _syntheticSingleIdentityMachine(),
            currentState: 'published',
            roleId: 'garden-member',
            actorFanId: 'fan-garden-member-1',
            // Missing "itemDescription", which the schema requires.
            seedInstanceData: const {'title': 'Spare trowel'},
            candidateTransitions: const [],
            matchesPrimaryTerm: (_) => true,
          );
          fail('expected B25ArrangementOutOfScopeFailure');
        } catch (error) {
          caught = error;
        }
        expect(caught, isA<B25ArrangementOutOfScopeFailure>());
        expect(
          (caught as B25ArrangementOutOfScopeFailure).reason,
          allOf(contains('"itemDescription"'), contains('no value')),
        );
      },
    );

    test(
      'a true single-identity, initial-state, text-only row is in scope '
      '(and a primary match with an unknown formula verdict -- '
      'pause-listing has no `formula` clause -- does not throw)', () {
        final machine = _syntheticSingleIdentityMachine();
        final pauseListing = machine.transitions.singleWhere(
          (transition) => transition.id == 'pause-listing',
        );
        final plan = planB25RemoteArrangement(
          machine: machine,
          currentState: 'published',
          roleId: 'garden-member',
          actorFanId: 'fan-garden-member-1',
          seedInstanceData: const {
            'title': 'Spare trowel',
            'itemDescription': 'A well-used trowel, still sharp.',
          },
          candidateTransitions: [pauseListing],
          matchesPrimaryTerm: (transition) => transition.id == 'pause-listing',
        );

        expect(plan.arrangedState, 'published');
        expect(plan.creationBinding.tabId, 'marketplace');
        expect(plan.creationAction.kind, 'create');
        expect(plan.fieldValues, {
          'title': 'Spare trowel',
          'itemDescription': 'A well-used trowel, still sharp.',
        });
      },
    );
  });
}

/// Mirrors `garden-tool-loan` from the shipped Garden Club package
/// (`docs/references/communities/Loom_Communities_Workflow_Engine_GardenClub_Example.jsonc`):
/// a member lists a tool, then a DIFFERENT member requests to borrow it --
/// `request-loan`'s formula denies the owner claiming their own listing.
LoomWorkflowStateMachine _gardenToolLoanMachine() =>
    LoomWorkflowStateMachine.fromJson(<String, dynamic>{
      'initialState': 'published',
      'states': <String, dynamic>{
        'published': <String, dynamic>{
          'label': 'Listed for loan',
          'editableFields': <String>['title', 'toolDescription'],
        },
      },
      'transitions': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'request-loan',
          'label': 'Request loan',
          'from': <String>['published'],
          'to': null,
          'guard': <String, dynamic>{
            'allowedRoleIds': <String>['garden-member'],
            'instanceDataEquals': <String, dynamic>{
              'key': 'availabilityState',
              'value': 'available',
            },
            'formula': 'if(ownerFanId == \$actor, false, true)',
          },
        },
      ],
      'renderBindings': <Map<String, dynamic>>[
        <String, dynamic>{
          'states': <String>['published'],
          'audience': 'any',
          'tabId': 'marketplace',
          'cardSurfaceFamily': 'equipment-loan',
          'bindingKind': 'primary',
          'actions': <Map<String, dynamic>>[
            <String, dynamic>{
              'kind': 'create',
              'label': 'List a garden tool',
              'byRoleIds': <String>['garden-member', 'garden-coordinator'],
              'prefill': <String, dynamic>{
                'ownerFanId': '\$actor',
                'availabilityState': 'available',
              },
            },
          ],
        },
      ],
      'instanceDataSchema': <String, dynamic>{
        'title': <String, dynamic>{
          'type': 'text',
          'required': true,
          'writableBy': 'formEntry',
        },
        'toolDescription': <String, dynamic>{
          'type': 'textarea',
          'required': true,
          'writableBy': 'formEntry',
        },
        'ownerFanId': <String, dynamic>{
          'type': 'fanId',
          'required': true,
          'writableBy': 'platform',
        },
      },
    }, 'garden-tool-loan');

/// Same shape as [_gardenToolLoanMachine], plus an unrelated `leave-queue`
/// transition that declares no `formula` guard at all -- its verdict is
/// [FormulaGuardVerdict.unknown], never denied. Exists to prove the
/// all-denied check is scoped to primary-matching candidates: before this
/// fix, `candidateTransitions.every(denied)` over BOTH transitions together
/// was defeated by `leave-queue`'s unknown verdict, masking the fact that
/// `request-loan` -- the row's real primary action -- is genuinely,
/// permanently denied.
LoomWorkflowStateMachine _gardenToolLoanWithUnrelatedQueueTransitionMachine() =>
    LoomWorkflowStateMachine.fromJson(<String, dynamic>{
      'initialState': 'published',
      'states': <String, dynamic>{
        'published': <String, dynamic>{
          'label': 'Listed for loan',
          'editableFields': <String>['title', 'toolDescription'],
        },
      },
      'transitions': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'request-loan',
          'label': 'Request loan',
          'from': <String>['published'],
          'to': null,
          'guard': <String, dynamic>{
            'allowedRoleIds': <String>['garden-member'],
            'formula': 'if(ownerFanId == \$actor, false, true)',
          },
        },
        <String, dynamic>{
          'id': 'leave-queue',
          'label': 'Leave waitlist',
          'from': <String>['published'],
          'to': null,
          'guard': <String, dynamic>{
            'allowedRoleIds': <String>['garden-member'],
          },
        },
      ],
      'renderBindings': <Map<String, dynamic>>[
        <String, dynamic>{
          'states': <String>['published'],
          'audience': 'any',
          'tabId': 'marketplace',
          'cardSurfaceFamily': 'equipment-loan',
          'bindingKind': 'primary',
          'actions': <Map<String, dynamic>>[
            <String, dynamic>{
              'kind': 'create',
              'label': 'List a garden tool',
              'byRoleIds': <String>['garden-member'],
              'prefill': <String, dynamic>{
                'ownerFanId': '\$actor',
                'availabilityState': 'available',
              },
            },
          ],
        },
      ],
      'instanceDataSchema': <String, dynamic>{
        'title': <String, dynamic>{
          'type': 'text',
          'required': true,
          'writableBy': 'formEntry',
        },
        'toolDescription': <String, dynamic>{
          'type': 'textarea',
          'required': true,
          'writableBy': 'formEntry',
        },
      },
    }, 'garden-tool-loan');

/// Mirrors `mosque-announcement`'s shape: its only shipped seed sits at
/// "sent", a later state than the workflow's own initial state "draft", yet
/// the row's real primary action (`send-announcement`) fires from "draft".
/// Exists to prove a later-state seed is arranged at the initial state
/// rather than thrown as out of scope, whenever a primary match genuinely
/// fires from there.
LoomWorkflowStateMachine _mosqueAnnouncementLikeMachine() =>
    LoomWorkflowStateMachine.fromJson(<String, dynamic>{
      'initialState': 'draft',
      'states': <String, dynamic>{
        'draft': <String, dynamic>{
          'label': 'Draft',
          'editableFields': <String>['title', 'body'],
        },
        'sent': <String, dynamic>{'label': 'Sent'},
      },
      'transitions': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'send-announcement',
          'label': 'Send announcement',
          'from': <String>['draft'],
          'to': 'sent',
          'guard': <String, dynamic>{
            'allowedRoleIds': <String>['masjid-admin'],
          },
        },
      ],
      'renderBindings': <Map<String, dynamic>>[
        <String, dynamic>{
          'states': <String>['draft'],
          'audience': 'any',
          'tabId': 'announcements',
          'cardSurfaceFamily': 'formEntry',
          'bindingKind': 'primary',
          'actions': <Map<String, dynamic>>[
            <String, dynamic>{
              'kind': 'create',
              'label': 'Draft an announcement',
              'byRoleIds': <String>['masjid-admin'],
              'prefill': <String, dynamic>{'authorFanId': '\$actor'},
            },
          ],
        },
      ],
      'instanceDataSchema': <String, dynamic>{
        'title': <String, dynamic>{
          'type': 'text',
          'required': true,
          'writableBy': 'formEntry',
        },
        'body': <String, dynamic>{
          'type': 'textarea',
          'required': true,
          'writableBy': 'formEntry',
        },
      },
    }, 'mosque-announcement-like');

/// Mirrors `garden-volunteer-shift`: only `garden-coordinator` may create a
/// shift, but the B25 row proves `garden-member`'s "sign up" transition.
LoomWorkflowStateMachine _gardenVolunteerShiftMachine() =>
    LoomWorkflowStateMachine.fromJson(<String, dynamic>{
      'initialState': 'open',
      'states': <String, dynamic>{
        'open': <String, dynamic>{
          'label': 'Open for sign-up',
          'editableFields': <String>['shiftTitle'],
        },
      },
      'transitions': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'sign-up',
          'label': 'Sign up',
          'from': <String>['open'],
          'to': null,
          'guard': <String, dynamic>{
            'allowedRoleIds': <String>['garden-member'],
          },
        },
      ],
      'renderBindings': <Map<String, dynamic>>[
        <String, dynamic>{
          'states': <String>['open'],
          'audience': 'any',
          'tabId': 'organize',
          'cardSurfaceFamily': 'formEntry',
          'bindingKind': 'primary',
          'actions': <Map<String, dynamic>>[
            <String, dynamic>{
              'kind': 'create',
              'label': 'New volunteer shift',
              'byRoleIds': <String>['garden-coordinator'],
              'prefill': <String, dynamic>{'coordinatorFanId': '\$actor'},
            },
          ],
        },
      ],
      'instanceDataSchema': <String, dynamic>{
        'shiftTitle': <String, dynamic>{
          'type': 'text',
          'required': true,
          'writableBy': 'formEntry',
        },
      },
    }, 'garden-volunteer-shift');

/// Mirrors `garden-export-custom-schemas`'s `initialState`
/// ("scope-selection"). The shipped seed sits in "ready", a later state --
/// its field shapes are irrelevant to the out-of-scope test, so they are
/// omitted.
LoomWorkflowStateMachine _gardenExportCustomSchemasMachine() =>
    LoomWorkflowStateMachine.fromJson(<String, dynamic>{
      'initialState': 'scope-selection',
      'states': <String, dynamic>{
        'scope-selection': <String, dynamic>{'label': 'Selecting scope'},
        'ready': <String, dynamic>{'label': 'Ready for export'},
      },
      'transitions': <Map<String, dynamic>>[],
      'renderBindings': <Map<String, dynamic>>[],
      'instanceDataSchema': <String, dynamic>{},
    }, 'garden-export-custom-schemas');

/// Mirrors `plant-exchange-submission`'s `draft` state: a single-identity
/// row (the submitter later fires `submit-exchange` on their own draft) that
/// this dispatch still cannot arrange, because `pickupDate` is a date-picker
/// field.
LoomWorkflowStateMachine _plantExchangeSubmissionMachine() =>
    LoomWorkflowStateMachine.fromJson(<String, dynamic>{
      'initialState': 'draft',
      'states': <String, dynamic>{
        'draft': <String, dynamic>{
          'label': 'Draft',
          'editableFields': <String>[
            'plantVariety',
            'pickupWindow',
            'pickupDate',
          ],
        },
      },
      'transitions': <Map<String, dynamic>>[],
      'renderBindings': <Map<String, dynamic>>[
        <String, dynamic>{
          'states': <String>['draft'],
          'audience': 'any',
          'tabId': 'exchange',
          'cardSurfaceFamily': 'formEntry',
          'bindingKind': 'primary',
          'actions': <Map<String, dynamic>>[
            <String, dynamic>{
              'kind': 'create',
              'label': 'Offer or request a plant',
              'byRoleIds': <String>['garden-member'],
              'prefill': <String, dynamic>{'ownerFanId': '\$actor'},
            },
          ],
        },
      ],
      'instanceDataSchema': <String, dynamic>{
        'plantVariety': <String, dynamic>{
          'type': 'text',
          'required': true,
          'writableBy': 'formEntry',
        },
        'pickupWindow': <String, dynamic>{
          'type': 'text',
          'required': true,
          'writableBy': 'formEntry',
        },
        'pickupDate': <String, dynamic>{
          'type': 'date',
          'required': true,
          'writableBy': 'formEntry',
        },
        'ownerFanId': <String, dynamic>{
          'type': 'fanId',
          'required': true,
          'writableBy': 'platform',
        },
      },
    }, 'plant-exchange-submission');

/// A synthetic, text-only single-identity workflow shaped like
/// `garden-tool-giveaway` but without its `coordinatorFanId` field --
/// exactly the shape this dispatch's first increment can arrange. Used to
/// prove the positive case: nothing here is drawn from a shipped package.
LoomWorkflowStateMachine _syntheticSingleIdentityMachine() =>
    LoomWorkflowStateMachine.fromJson(<String, dynamic>{
      'initialState': 'published',
      'states': <String, dynamic>{
        'published': <String, dynamic>{
          'label': 'Available',
          'editableFields': <String>['title', 'itemDescription'],
        },
      },
      'transitions': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'pause-listing',
          'label': 'Pause listing',
          'from': <String>['published'],
          'to': null,
          'guard': <String, dynamic>{
            'actorEqualsField': <String, dynamic>{'key': 'ownerFanId'},
          },
        },
      ],
      'renderBindings': <Map<String, dynamic>>[
        <String, dynamic>{
          'states': <String>['published'],
          'audience': 'any',
          'tabId': 'marketplace',
          'cardSurfaceFamily': 'equipment-loan',
          'bindingKind': 'primary',
          'actions': <Map<String, dynamic>>[
            <String, dynamic>{
              'kind': 'create',
              'label': 'Give away a garden item',
              'byRoleIds': <String>['garden-member'],
              'prefill': <String, dynamic>{
                'ownerFanId': '\$actor',
                'availabilityState': 'available',
              },
            },
          ],
        },
      ],
      'instanceDataSchema': <String, dynamic>{
        'title': <String, dynamic>{
          'type': 'text',
          'required': true,
          'writableBy': 'formEntry',
        },
        'itemDescription': <String, dynamic>{
          'type': 'textarea',
          'required': true,
          'writableBy': 'formEntry',
        },
        'ownerFanId': <String, dynamic>{
          'type': 'fanId',
          'required': true,
          'writableBy': 'platform',
        },
      },
    }, 'garden-tool-giveaway-synthetic');
