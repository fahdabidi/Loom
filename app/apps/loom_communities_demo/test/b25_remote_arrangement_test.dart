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
            creatorFanId: 'fan-garden-coordinator-1',
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
          creatorFanId: 'fan-masjid-admin-1',
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
        expect(plan.creatorRoleId, 'masjid-admin');
        expect(plan.fieldValues, {
          'title': 'Friday reminder',
          'body': "Jumu'ah starts at 1pm.",
        });
        expect(plan.syntheticInstanceData['authorFanId'], 'fan-masjid-admin-1');
      },
    );

    test(
      'a creation role that excludes the acting role is now in scope via a '
      'different creator (garden-volunteer-shift: coordinator creates, '
      'member signs up)',
      () {
        final plan = planB25RemoteArrangement(
          machine: _gardenVolunteerShiftMachine(),
          currentState: 'open',
          // The B25 row for this workflow acts as `garden-member` (sign
          // up); only `garden-coordinator` may create a shift, so the
          // creator must be a DIFFERENT fan, holding a DIFFERENT role.
          roleId: 'garden-member',
          creatorFanId: 'fan-garden-coordinator-1',
          actorFanId: 'fan-garden-member-1',
          seedInstanceData: const {'shiftTitle': 'Mulch delivery'},
          candidateTransitions: const [],
          matchesPrimaryTerm: (_) => true,
        );

        expect(plan.creatorRoleId, 'garden-coordinator');
        expect(plan.creationBinding.tabId, 'organize');
        expect(plan.arrangedState, 'open');
        expect(
          plan.syntheticInstanceData['coordinatorFanId'],
          'fan-garden-coordinator-1',
        );
        expect(plan.fieldValues, {'shiftTitle': 'Mulch delivery'});
      },
    );

    test(
      'a formula guard that denies a self-created instance is out of scope '
      'when the creator and actor are the same fan (garden-tool-loan: '
      'ownerFanId == \$actor is denied)',
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
            creatorFanId: 'fan-garden-member-1',
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
      'a formula guard denying self-creation is satisfied by a different '
      'creator holding the SAME role (garden-tool-loan: a different member '
      'lists the tool, the actor requests it)',
      () {
        final machine = _gardenToolLoanMachine();
        final requestLoan = machine.transitions.singleWhere(
          (transition) => transition.id == 'request-loan',
        );
        final plan = planB25RemoteArrangement(
          machine: machine,
          currentState: 'published',
          roleId: 'garden-member',
          creatorFanId: 'fan-garden-member-2',
          actorFanId: 'fan-garden-member-1',
          seedInstanceData: const {
            'title': 'Steel wheelbarrow',
            'toolDescription': 'Sturdy wheelbarrow for moving mulch.',
            'ownerContactInfo': 'Private club message to member Alex',
          },
          candidateTransitions: [requestLoan],
          matchesPrimaryTerm: (transition) => transition.id == 'request-loan',
        );

        expect(plan.creatorRoleId, 'garden-member');
        expect(plan.syntheticInstanceData['ownerFanId'], 'fan-garden-member-2');
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
            creatorFanId: 'fan-garden-member-1',
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
      'a required fanId field with no guard naming it is unconstrained and '
      'filled with the acting fan, never the seed (plant-exchange-'
      'submission: assignedCoordinatorFanId, mirroring the real, now-'
      'resolved garden-tool-loan/garden-tool-giveaway coordinatorFanId gap)',
      () {
        final plan = planB25RemoteArrangement(
          machine: _plantExchangeSubmissionMachine(),
          currentState: 'draft',
          roleId: 'garden-member',
          creatorFanId: 'fan-garden-member-1',
          actorFanId: 'fan-garden-member-1',
          seedInstanceData: const {
            'plantVariety': 'Tomato seedlings',
            'pickupWindow': 'Saturday mornings',
            // A demo-space, role-id-shaped value -- exactly the kind of
            // seed contamination this field type must never copy verbatim.
            'assignedCoordinatorFanId': 'garden-coordinator',
          },
          candidateTransitions: const [],
          matchesPrimaryTerm: (_) => true,
        );

        expect(plan.fanIdFields, {'assignedCoordinatorFanId'});
        expect(
          plan.fieldValues['assignedCoordinatorFanId'],
          'fan-garden-member-1',
        );
      },
    );

    test(
      'a required field of a type this dispatch still does not know how to '
      'fill stays out of scope (camera-club-like critique-submission: '
      'photoImage declares storage: "reference" -- typing the seed\'s '
      'reference string would mint an instance claiming an upload that '
      'never happened, so this type is deliberately excluded)',
      () {
        Object? caught;
        try {
          planB25RemoteArrangement(
            machine: _photoCritiqueSubmissionMachine(),
            currentState: 'draft',
            roleId: 'camera-member',
            creatorFanId: 'fan-camera-member-1',
            actorFanId: 'fan-camera-member-1',
            seedInstanceData: const {
              'critiqueNote': 'Great use of leading lines.',
              'photoImage': 'ref://uploads/photo-123.jpg',
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
            contains('photo-critique-submission'),
            contains('"photoImage"'),
            contains('"image"'),
          ),
        );
      },
    );

    test(
      'a required url field is now in scope and copies the seed verbatim '
      '(chess-rules-documents: documentUrl)',
      () {
        final plan = planB25RemoteArrangement(
          machine: _chessRulesDocumentMachine(),
          currentState: 'available',
          roleId: 'chess-organizer',
          creatorFanId: 'fan-chess-organizer-1',
          actorFanId: 'fan-chess-organizer-1',
          seedInstanceData: const {
            'documentTitle': 'Club rapid and ladder rules',
            'documentUrl': 'https://example.org/chess-club/rules/2026-2',
          },
          candidateTransitions: const [],
          matchesPrimaryTerm: (_) => true,
        );

        expect(plan.fieldValues, {
          'documentTitle': 'Club rapid and ladder rules',
          'documentUrl': 'https://example.org/chess-club/rules/2026-2',
        });
        expect(plan.dateTimeFields, isEmpty);
        expect(plan.boolFields, isEmpty);
        expect(plan.fanIdFields, isEmpty);
      },
    );

    test(
      'a required list field is now in scope and joins the seed\'s list '
      'with ", " for the generic creation card\'s own comma-split '
      'normalizer (chess-export-package: exportScope)',
      () {
        final plan = planB25RemoteArrangement(
          machine: _chessExportPackageMachine(),
          currentState: 'ready',
          roleId: 'chess-organizer',
          creatorFanId: 'fan-chess-organizer-1',
          actorFanId: 'fan-chess-organizer-1',
          seedInstanceData: const {
            'exportLabel': 'August ladder and match archive',
            'exportScope': [
              'match results',
              'ranking rows',
              'pairing history',
            ],
          },
          candidateTransitions: const [],
          matchesPrimaryTerm: (_) => true,
        );

        expect(plan.fieldValues, {
          'exportLabel': 'August ladder and match archive',
          'exportScope': 'match results, ranking rows, pairing history',
        });
      },
    );

    test(
      'a scalar fanId field guarded by actorEqualsField resolves to the '
      'ACTING fan, never a different member, even though the row is a '
      'two-identity row (hoa-owner-notification: recipientFanId -- board '
      'creates, the member marks their own notice read)',
      () {
        final machine = _hoaOwnerNotificationMachine();
        final markRead = machine.transitions.singleWhere(
          (transition) => transition.id == 'mark-notification-read',
        );
        final plan = planB25RemoteArrangement(
          machine: machine,
          currentState: 'sent',
          roleId: 'hoa-member',
          creatorFanId: 'fan-hoa-board-1',
          actorFanId: 'fan-hoa-member-1',
          seedInstanceData: const {
            'title': 'Landscaping notice',
            // A stale seed value from a different fan entirely -- proof
            // the plan never copies it for this field type.
            'recipientFanId': 'fan-hoa-member-9',
          },
          candidateTransitions: [markRead],
          matchesPrimaryTerm: (transition) =>
              transition.id == 'mark-notification-read',
        );

        expect(plan.fanIdFields, {'recipientFanId'});
        expect(plan.fieldValues['recipientFanId'], 'fan-hoa-member-1');
      },
    );

    test(
      'a fanId[] field guarded by actorInList(present: true) resolves to a '
      'set containing the ACTING fan, never the seed\'s legacy role-id-'
      'shaped values (chess-match-result: participantFanIds)',
      () {
        final machine = _chessMatchResultMachine();
        final submitResult = machine.transitions.singleWhere(
          (transition) => transition.id == 'submit-result',
        );
        final plan = planB25RemoteArrangement(
          machine: machine,
          currentState: 'draft',
          roleId: 'chess-member',
          creatorFanId: 'fan-chess-member-1',
          actorFanId: 'fan-chess-member-1',
          seedInstanceData: const {
            'resultTitle': 'Round 3',
            // Exactly the real, shipped contamination this field type has
            // suffered from an older picker: role ids, not fan ids.
            'participantFanIds': ['chess-member', 'chess-organizer'],
          },
          candidateTransitions: [submitResult],
          matchesPrimaryTerm: (transition) =>
              transition.id == 'submit-result',
        );

        expect(plan.fanIdFields, {'participantFanIds'});
        expect(plan.fieldValues['participantFanIds'], 'fan-chess-member-1');
      },
    );

    test(
      'a fanId field a formula guard names alongside \$actor cannot be '
      'resolved offline and is reported out of scope rather than guessed',
      () {
        final machine = _formulaGatedFanIdFieldMachine();
        final approve = machine.transitions.singleWhere(
          (transition) => transition.id == 'approve-request',
        );
        Object? caught;
        try {
          planB25RemoteArrangement(
            machine: machine,
            currentState: 'pending',
            roleId: 'garden-member',
            creatorFanId: 'fan-garden-member-1',
            actorFanId: 'fan-garden-member-1',
            seedInstanceData: const {'title': 'Fence repair'},
            candidateTransitions: [approve],
            matchesPrimaryTerm: (transition) =>
                transition.id == 'approve-request',
          );
          fail('expected B25ArrangementOutOfScopeFailure');
        } catch (error) {
          caught = error;
        }
        expect(caught, isA<B25ArrangementOutOfScopeFailure>());
        final failure = caught as B25ArrangementOutOfScopeFailure;
        expect(
          failure.category,
          B25ArrangementOutOfScopeCategory.fanIdFieldRequiresDifferentMember,
        );
        expect(
          failure.reason,
          allOf(contains('approve-request'), contains('"approverFanId"')),
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
            creatorFanId: 'fan-garden-member-1',
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
          creatorFanId: 'fan-garden-member-1',
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
        expect(plan.creatorRoleId, 'garden-member');
        expect(plan.fieldValues, {
          'title': 'Spare trowel',
          'itemDescription': 'A well-used trowel, still sharp.',
        });
        expect(plan.dateTimeFields, isEmpty);
        expect(plan.clockConstrainedFields, isEmpty);
      },
    );

    test(
      'an effect-born row with no creation binding for ANY role stays out '
      'of scope (garden-event-rsvp-response: created only by the event '
      'workflow\'s fan-out, never directly)',
      () {
        Object? caught;
        try {
          planB25RemoteArrangement(
            machine: _gardenEventRsvpResponseLikeMachine(),
            currentState: 'pending',
            roleId: 'garden-member',
            creatorFanId: 'fan-garden-member-1',
            actorFanId: 'fan-garden-member-1',
            seedInstanceData: const {},
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
            contains('garden-event-rsvp-response'),
            contains('effect-born'),
          ),
        );
      },
    );

    test(
      'date and time creation fields are now in scope and copy the seed '
      'when nothing clock-compares them (garden-volunteer-shift: '
      'shiftDate/shiftTime)',
      () {
        final plan = planB25RemoteArrangement(
          machine: _gardenVolunteerShiftWithDateTimeMachine(),
          currentState: 'open',
          roleId: 'garden-coordinator',
          creatorFanId: 'fan-garden-coordinator-1',
          actorFanId: 'fan-garden-coordinator-1',
          seedInstanceData: const {
            'shiftTitle': 'Mulch delivery',
            'shiftDate': '2026-03-14',
            'shiftTime': '09:00',
          },
          candidateTransitions: const [],
          matchesPrimaryTerm: (_) => true,
        );

        expect(plan.fieldValues, {
          'shiftTitle': 'Mulch delivery',
          'shiftDate': '2026-03-14',
          'shiftTime': '09:00',
        });
        expect(plan.dateTimeFields, {'shiftDate', 'shiftTime'});
        expect(plan.clockConstrainedFields, isEmpty);
      },
    );

    test(
      'a date field a guard clock-compares is flagged so the caller '
      'synthesizes a value relative to now instead of copying the stale '
      'seed (chess-match-meetup-like: expiresAt, isBefore(now(), '
      'expiresAt))',
      () {
        final machine = _clockConstrainedDateFieldMachine();
        final acceptMatch = machine.transitions.singleWhere(
          (transition) => transition.id == 'accept-match',
        );
        final plan = planB25RemoteArrangement(
          machine: machine,
          currentState: 'open',
          roleId: 'chess-member',
          creatorFanId: 'fan-chess-member-1',
          actorFanId: 'fan-chess-member-1',
          seedInstanceData: const {
            'opponentFanId': 'fan-chess-member-1',
            // A stale, already-past seed value -- exactly what must not be
            // submitted verbatim once a guard clock-compares it.
            'expiresAt': '2026-01-01',
          },
          // accept-match is not this row's primary action (matchesPrimaryTerm
          // below returns false for it), so it cannot trigger the all-denied
          // formula check -- this test isolates clock-constraint detection
          // from that separate check.
          candidateTransitions: [acceptMatch],
          matchesPrimaryTerm: (_) => false,
        );

        expect(plan.dateTimeFields, contains('expiresAt'));
        expect(plan.clockConstrainedFields, {'expiresAt'});
        // The plan still copies the seed's value -- deciding to synthesize a
        // future value instead is the caller's job, driven by membership in
        // clockConstrainedFields, not something the plan does itself.
        expect(plan.fieldValues['expiresAt'], '2026-01-01');
      },
    );

    test(
      'a declared visibility.readGuard that denies the acting fan is out '
      'of scope even though the formula guard and every field are '
      'satisfied',
      () {
        Object? caught;
        try {
          planB25RemoteArrangement(
            machine: _guardedVisibilityMachine(),
            currentState: 'published',
            roleId: 'garden-member',
            creatorFanId: 'fan-garden-member-2',
            actorFanId: 'fan-garden-member-1',
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
          allOf(contains('readGuard'), contains('cannot read the instance')),
        );
      },
    );

    test(
      'a role-gated readGuard that excludes the acting role is still out '
      'of scope for a two-identity row with no rescuing identity field '
      '(the still-refusing case, proving the fix did not become '
      'permissive)',
      () {
        Object? caught;
        try {
          planB25RemoteArrangement(
            machine: _roleGatedVisibilityMachine(),
            currentState: 'published',
            roleId: 'garden-member',
            creatorFanId: 'fan-garden-member-2',
            actorFanId: 'fan-garden-member-1',
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
          allOf(contains('readGuard'), contains('cannot read the instance')),
        );
      },
    );

    test(
      'a single-identity row is in scope even though its readGuard would '
      'deny a different actor -- the creator always reads their own '
      'instance (branch 1 of the three-way OR)',
      () {
        final plan = planB25RemoteArrangement(
          machine: _roleGatedVisibilityMachine(),
          currentState: 'published',
          roleId: 'garden-member',
          creatorFanId: 'fan-garden-member-1',
          actorFanId: 'fan-garden-member-1',
          seedInstanceData: const {'title': 'Spare trowel'},
          candidateTransitions: const [],
          matchesPrimaryTerm: (_) => true,
        );

        expect(plan.arrangedState, 'published');
      },
    );

    test(
      'a readGuard allowedRoleIds that DOES contain the acting role is in '
      'scope for a two-identity row -- the planner now passes its own '
      'roleId parameter into evaluateGuard instead of failing closed on an '
      'omitted role set (branch 3 of the three-way OR)',
      () {
        final plan = planB25RemoteArrangement(
          machine: _roleGatedVisibilityAdmittingMachine(),
          currentState: 'published',
          roleId: 'garden-member',
          creatorFanId: 'fan-garden-member-2',
          actorFanId: 'fan-garden-member-1',
          seedInstanceData: const {'title': 'Spare trowel'},
          candidateTransitions: const [],
          matchesPrimaryTerm: (_) => true,
        );

        expect(plan.arrangedState, 'published');
      },
    );

    test(
      'a parties archetype FIELD principal naming the actor is in scope '
      'for a two-identity row even though the readGuard alone would deny '
      'it (branch 2 of the three-way OR, field-principal shape)',
      () {
        final plan = planB25RemoteArrangement(
          machine: _partiesVisibilityMachine(),
          currentState: 'open',
          roleId: 'garden-member',
          creatorFanId: 'fan-garden-coordinator-1',
          actorFanId: 'fan-garden-member-1',
          seedInstanceData: const {
            'title': 'Spare trowel',
            // The field principal this archetype declares. Matches the
            // actor, so this is what must rescue the row -- the readGuard
            // (actorEqualsField unrelatedFanId, absent) denies on its own.
            'requesterFanId': 'fan-garden-member-1',
          },
          candidateTransitions: const [],
          matchesPrimaryTerm: (_) => true,
        );

        expect(plan.arrangedState, 'open');
      },
    );

    test(
      'a parties archetype ROLE principal naming the acting role is in '
      'scope for a two-identity row even though neither the readGuard nor '
      'the field principal admits it (branch 2 of the three-way OR, '
      'role-principal shape)',
      () {
        final plan = planB25RemoteArrangement(
          machine: _partiesVisibilityMachine(),
          currentState: 'open',
          roleId: 'garden-coordinator',
          creatorFanId: 'fan-garden-coordinator-2',
          actorFanId: 'fan-garden-coordinator-1',
          seedInstanceData: const {
            'title': 'Spare trowel',
            // Deliberately NOT the actor, so only the role principal
            // (declared as {"role": "garden-coordinator"}) can rescue this
            // row.
            'requesterFanId': 'fan-someone-else',
          },
          candidateTransitions: const [],
          matchesPrimaryTerm: (_) => true,
        );

        expect(plan.arrangedState, 'open');
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

/// Same shape as [_gardenVolunteerShiftMachine], plus real `shiftDate`
/// (`date`) and `shiftTime` (`time`) required creation fields, exactly as
/// the shipped package declares them -- neither is referenced by any
/// guard's `formula`, so neither is clock-constrained.
LoomWorkflowStateMachine _gardenVolunteerShiftWithDateTimeMachine() =>
    LoomWorkflowStateMachine.fromJson(<String, dynamic>{
      'initialState': 'open',
      'states': <String, dynamic>{
        'open': <String, dynamic>{
          'label': 'Open for sign-up',
          'editableFields': <String>['shiftTitle', 'shiftDate', 'shiftTime'],
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
        'shiftDate': <String, dynamic>{
          'type': 'date',
          'required': true,
          'writableBy': 'formEntry',
        },
        'shiftTime': <String, dynamic>{
          'type': 'time',
          'required': true,
          'writableBy': 'formEntry',
        },
      },
    }, 'garden-volunteer-shift');

/// Mirrors `chess-match-meetup`'s shape, cited in
/// `HARNESS-two-identity-arrangement-and-date-time-fields.md`: a required
/// `date` field named by an `accept-match` formula guard as
/// `isBefore(now(), expiresAt)`, which denies acceptance once `expiresAt` is
/// not strictly in the future.
LoomWorkflowStateMachine _clockConstrainedDateFieldMachine() =>
    LoomWorkflowStateMachine.fromJson(<String, dynamic>{
      'initialState': 'open',
      'states': <String, dynamic>{
        'open': <String, dynamic>{
          'label': 'Open',
          'editableFields': <String>['opponentFanId', 'expiresAt'],
        },
      },
      'transitions': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'accept-match',
          'label': 'Accept match',
          'from': <String>['open'],
          'to': null,
          'guard': <String, dynamic>{
            'allowedRoleIds': <String>['chess-member'],
            'formula': 'isBefore(now(), expiresAt)',
          },
        },
      ],
      'renderBindings': <Map<String, dynamic>>[
        <String, dynamic>{
          'states': <String>['open'],
          'audience': 'any',
          'tabId': 'matches',
          'cardSurfaceFamily': 'formEntry',
          'bindingKind': 'primary',
          'actions': <Map<String, dynamic>>[
            <String, dynamic>{
              'kind': 'create',
              'label': 'Propose a match',
              'byRoleIds': <String>['chess-member'],
              'prefill': <String, dynamic>{},
            },
          ],
        },
      ],
      'instanceDataSchema': <String, dynamic>{
        'opponentFanId': <String, dynamic>{
          'type': 'text',
          'required': true,
          'writableBy': 'formEntry',
        },
        'expiresAt': <String, dynamic>{
          'type': 'date',
          'required': true,
          'writableBy': 'formEntry',
        },
      },
    }, 'chess-match-meetup-like');

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

/// Mirrors `garden-event-rsvp-response`'s shape: `renderBindings` is
/// deliberately empty, because the response row is created only by the
/// parent event workflow's fan-out effect, never through a create binding
/// any role may use directly.
LoomWorkflowStateMachine _gardenEventRsvpResponseLikeMachine() =>
    LoomWorkflowStateMachine.fromJson(<String, dynamic>{
      'initialState': 'pending',
      'states': <String, dynamic>{
        'pending': <String, dynamic>{'label': 'No response yet'},
      },
      'transitions': <Map<String, dynamic>>[],
      'renderBindings': <Map<String, dynamic>>[],
      'instanceDataSchema': <String, dynamic>{
        'eventId': <String, dynamic>{'type': 'text', 'required': true},
        'fanId': <String, dynamic>{'type': 'fanId', 'required': true},
      },
    }, 'garden-event-rsvp-response');

/// Mirrors `plant-exchange-submission`'s `draft` state: a single-identity
/// row (the submitter later fires `submit-exchange` on their own draft)
/// whose `assignedCoordinatorFanId` is a `fanId` field with no guard naming
/// it anywhere -- the same shape as the real, shipped
/// `garden-tool-loan`/`garden-tool-giveaway` `coordinatorFanId` gap, now
/// resolved as unconstrained (filled with the acting fan).
LoomWorkflowStateMachine _plantExchangeSubmissionMachine() =>
    LoomWorkflowStateMachine.fromJson(<String, dynamic>{
      'initialState': 'draft',
      'states': <String, dynamic>{
        'draft': <String, dynamic>{
          'label': 'Draft',
          'editableFields': <String>[
            'plantVariety',
            'pickupWindow',
            'assignedCoordinatorFanId',
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
        'assignedCoordinatorFanId': <String, dynamic>{
          'type': 'fanId',
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

/// Mirrors `critique-submission`'s shape: `photoImage` declares
/// `storage: "reference"`, a type this dispatch deliberately still refuses
/// -- typing the seed's reference string would mint an instance claiming an
/// upload that was never performed, which is the placeholder shape this
/// project forbids outright.
LoomWorkflowStateMachine _photoCritiqueSubmissionMachine() =>
    LoomWorkflowStateMachine.fromJson(<String, dynamic>{
      'initialState': 'draft',
      'states': <String, dynamic>{
        'draft': <String, dynamic>{
          'label': 'Draft',
          'editableFields': <String>['critiqueNote', 'photoImage'],
        },
      },
      'transitions': <Map<String, dynamic>>[],
      'renderBindings': <Map<String, dynamic>>[
        <String, dynamic>{
          'states': <String>['draft'],
          'audience': 'any',
          'tabId': 'critiques',
          'cardSurfaceFamily': 'formEntry',
          'bindingKind': 'primary',
          'actions': <Map<String, dynamic>>[
            <String, dynamic>{
              'kind': 'create',
              'label': 'Submit a critique photo',
              'byRoleIds': <String>['camera-member'],
              'prefill': <String, dynamic>{},
            },
          ],
        },
      ],
      'instanceDataSchema': <String, dynamic>{
        'critiqueNote': <String, dynamic>{
          'type': 'text',
          'required': true,
          'writableBy': 'formEntry',
        },
        'photoImage': <String, dynamic>{
          'type': 'image',
          'required': true,
          'writableBy': 'formEntry',
          'storage': 'reference',
        },
      },
    }, 'photo-critique-submission');

/// Mirrors `chess-rules-documents`'s `available` state: a single-identity
/// row whose required `documentUrl` is a `url` field, filled with a plain
/// `TextField` exactly like `text`/`textarea`.
LoomWorkflowStateMachine _chessRulesDocumentMachine() =>
    LoomWorkflowStateMachine.fromJson(<String, dynamic>{
      'initialState': 'available',
      'states': <String, dynamic>{
        'available': <String, dynamic>{
          'label': 'Available',
          'editableFields': <String>['documentTitle', 'documentUrl'],
        },
      },
      'transitions': <Map<String, dynamic>>[],
      'renderBindings': <Map<String, dynamic>>[
        <String, dynamic>{
          'states': <String>['available'],
          'audience': 'any',
          'tabId': 'documents',
          'cardSurfaceFamily': 'formEntry',
          'bindingKind': 'primary',
          'actions': <Map<String, dynamic>>[
            <String, dynamic>{
              'kind': 'create',
              'label': 'Add a club document',
              'byRoleIds': <String>['chess-organizer'],
              'prefill': <String, dynamic>{},
            },
          ],
        },
      ],
      'instanceDataSchema': <String, dynamic>{
        'documentTitle': <String, dynamic>{
          'type': 'text',
          'required': true,
          'writableBy': 'formEntry',
        },
        'documentUrl': <String, dynamic>{
          'type': 'url',
          'required': true,
          'writableBy': 'formEntry',
        },
      },
    }, 'chess-rules-documents');

/// Mirrors `chess-export-package`'s `ready` state (its own `initialState`):
/// a single-identity row whose required `exportScope` is a `list` field,
/// joined with ", " for the generic creation card's own comma-split
/// normalizer.
LoomWorkflowStateMachine _chessExportPackageMachine() =>
    LoomWorkflowStateMachine.fromJson(<String, dynamic>{
      'initialState': 'ready',
      'states': <String, dynamic>{
        'ready': <String, dynamic>{
          'label': 'Ready for export',
          'editableFields': <String>['exportLabel', 'exportScope'],
        },
      },
      'transitions': <Map<String, dynamic>>[],
      'renderBindings': <Map<String, dynamic>>[
        <String, dynamic>{
          'states': <String>['ready'],
          'audience': 'any',
          'tabId': 'export',
          'cardSurfaceFamily': 'formEntry',
          'bindingKind': 'primary',
          'actions': <Map<String, dynamic>>[
            <String, dynamic>{
              'kind': 'create',
              'label': 'Prepare an export package',
              'byRoleIds': <String>['chess-organizer'],
              'prefill': <String, dynamic>{},
            },
          ],
        },
      ],
      'instanceDataSchema': <String, dynamic>{
        'exportLabel': <String, dynamic>{
          'type': 'text',
          'required': true,
          'writableBy': 'formEntry',
        },
        'exportScope': <String, dynamic>{
          'type': 'list',
          'required': true,
          'writableBy': 'formEntry',
        },
      },
    }, 'chess-export-package');

/// Mirrors `hoa-owner-notification`'s shape: only `hoa-board` may create,
/// while `mark-notification-read`'s guard requires the acting `hoa-member`
/// to equal `recipientFanId` -- a two-identity row whose own
/// `recipientFanId` resolves to the ACTING fan, not the creator.
LoomWorkflowStateMachine _hoaOwnerNotificationMachine() =>
    LoomWorkflowStateMachine.fromJson(<String, dynamic>{
      'initialState': 'sent',
      'states': <String, dynamic>{
        'sent': <String, dynamic>{
          'label': 'Sent',
          'editableFields': <String>['title', 'recipientFanId'],
        },
      },
      'transitions': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'mark-notification-read',
          'label': 'Mark read',
          'from': <String>['sent'],
          'to': null,
          'guard': <String, dynamic>{
            'allowedRoleIds': <String>['hoa-member'],
            'actorEqualsField': <String, dynamic>{'key': 'recipientFanId'},
          },
        },
      ],
      'renderBindings': <Map<String, dynamic>>[
        <String, dynamic>{
          'states': <String>['sent'],
          'audience': 'any',
          'tabId': 'admin',
          'cardSurfaceFamily': 'notificationInbox',
          'bindingKind': 'primary',
          'actions': <Map<String, dynamic>>[
            <String, dynamic>{
              'kind': 'create',
              'label': 'Send owner notice',
              'byRoleIds': <String>['hoa-board'],
              'prefill': <String, dynamic>{'senderFanId': '\$actor'},
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
        'recipientFanId': <String, dynamic>{
          'type': 'fanId',
          'required': true,
          'writableBy': 'formEntry',
        },
        'senderFanId': <String, dynamic>{
          'type': 'fanId',
          'required': true,
          'writableBy': 'platform',
        },
      },
    }, 'hoa-owner-notification');

/// Mirrors `chess-match-result`'s `draft` state: `participantFanIds` is a
/// required `fanId[]` field whose own create-action `prefill` already
/// seeds it with `["$actor"]`, and `submit-result`'s guard requires the
/// acting fan to be present in it (`actorInList`, `present: true`).
LoomWorkflowStateMachine _chessMatchResultMachine() =>
    LoomWorkflowStateMachine.fromJson(<String, dynamic>{
      'initialState': 'draft',
      'states': <String, dynamic>{
        'draft': <String, dynamic>{
          'label': 'Draft result',
          'editableFields': <String>['resultTitle', 'participantFanIds'],
        },
      },
      'transitions': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'submit-result',
          'label': 'Submit score',
          'from': <String>['draft'],
          'to': 'submitted',
          'guard': <String, dynamic>{
            'allowedRoleIds': <String>['chess-member'],
            'actorInList': <String, dynamic>{
              'key': 'participantFanIds',
              'present': true,
            },
          },
        },
      ],
      'renderBindings': <Map<String, dynamic>>[
        <String, dynamic>{
          'states': <String>['draft'],
          'audience': 'any',
          'tabId': 'matches',
          'cardSurfaceFamily': 'formEntry',
          'bindingKind': 'primary',
          'actions': <Map<String, dynamic>>[
            <String, dynamic>{
              'kind': 'create',
              'label': 'Record match',
              'byRoleIds': <String>['chess-member'],
              'prefill': <String, dynamic>{
                'participantFanIds': <String>['\$actor'],
              },
            },
          ],
        },
      ],
      'instanceDataSchema': <String, dynamic>{
        'resultTitle': <String, dynamic>{
          'type': 'text',
          'required': true,
          'writableBy': 'formEntry',
        },
        'participantFanIds': <String, dynamic>{
          'type': 'fanId[]',
          'required': true,
          'writableBy': 'formEntry',
        },
      },
    }, 'chess-match-result');

/// A synthetic workflow whose required `approverFanId` (`fanId`) is named
/// by a `formula` guard alongside `$actor` -- the shape this dispatch
/// cannot resolve offline, because the formula may deny the acting fan
/// outright and satisfying it would need a genuinely different real
/// member. Mirrors Garden's real `if(ownerFanId == $actor, false, true)`
/// shape on a field this dispatch would otherwise have to guess at.
LoomWorkflowStateMachine _formulaGatedFanIdFieldMachine() =>
    LoomWorkflowStateMachine.fromJson(<String, dynamic>{
      'initialState': 'pending',
      'states': <String, dynamic>{
        'pending': <String, dynamic>{
          'label': 'Pending',
          'editableFields': <String>['title', 'approverFanId'],
        },
      },
      'transitions': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'approve-request',
          'label': 'Approve',
          'from': <String>['pending'],
          'to': null,
          'guard': <String, dynamic>{
            'allowedRoleIds': <String>['garden-member'],
            'formula': 'if(approverFanId == \$actor, false, true)',
          },
        },
      ],
      'renderBindings': <Map<String, dynamic>>[
        <String, dynamic>{
          'states': <String>['pending'],
          'audience': 'any',
          'tabId': 'requests',
          'cardSurfaceFamily': 'formEntry',
          'bindingKind': 'primary',
          'actions': <Map<String, dynamic>>[
            <String, dynamic>{
              'kind': 'create',
              'label': 'Submit a request',
              'byRoleIds': <String>['garden-member'],
              'prefill': <String, dynamic>{},
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
        'approverFanId': <String, dynamic>{
          'type': 'fanId',
          'required': true,
          'writableBy': 'formEntry',
        },
      },
    }, 'formula-gated-fanid-field-synthetic');

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

/// A synthetic workflow declaring `visibility.default: "guarded"` with a
/// `readGuard` requiring the viewer to equal `ownerFanId`. Used to prove the
/// plan-time readGuard gate: the acting fan here is deliberately NOT the
/// instance's creator (`ownerFanId` resolves to the creator via `$actor`),
/// so the guard denies them even though every field and the formula guard
/// (there is none) are otherwise satisfied.
LoomWorkflowStateMachine _guardedVisibilityMachine() =>
    LoomWorkflowStateMachine.fromJson(<String, dynamic>{
      'initialState': 'published',
      'visibility': <String, dynamic>{
        'default': 'guarded',
        'readGuard': <String, dynamic>{
          'actorEqualsField': <String, dynamic>{'key': 'ownerFanId'},
        },
      },
      'states': <String, dynamic>{
        'published': <String, dynamic>{
          'label': 'Available',
          'editableFields': <String>['title'],
        },
      },
      'transitions': <Map<String, dynamic>>[],
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
              'label': 'List an item',
              'byRoleIds': <String>['garden-member'],
              'prefill': <String, dynamic>{'ownerFanId': '\$actor'},
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
        'ownerFanId': <String, dynamic>{
          'type': 'fanId',
          'required': true,
          'writableBy': 'platform',
        },
      },
    }, 'guarded-visibility-synthetic');

/// A synthetic workflow declaring `visibility.default: "guarded"` with a
/// ROLE-gated `readGuard` (`allowedRoleIds: ["garden-coordinator"]`) that
/// never admits `garden-member`. Its `cardSurfaceFamily` ("equipment-loan")
/// resolves to the `owner` archetype model, which contributes nothing
/// beyond the creator check -- so whether a `garden-member` row is in scope
/// depends entirely on whether the acting fan is also the creator (branch 1
/// of the three-way OR), never on the readGuard or the archetype.
LoomWorkflowStateMachine _roleGatedVisibilityMachine() =>
    LoomWorkflowStateMachine.fromJson(<String, dynamic>{
      'initialState': 'published',
      'visibility': <String, dynamic>{
        'default': 'guarded',
        'readGuard': <String, dynamic>{
          'allowedRoleIds': <String>['garden-coordinator'],
        },
      },
      'states': <String, dynamic>{
        'published': <String, dynamic>{
          'label': 'Available',
          'editableFields': <String>['title'],
        },
      },
      'transitions': <Map<String, dynamic>>[],
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
              'label': 'List an item',
              'byRoleIds': <String>['garden-member'],
              'prefill': <String, dynamic>{},
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
      },
    }, 'role-gated-visibility-synthetic');

/// Same shape as [_roleGatedVisibilityMachine], except its `readGuard`
/// names `garden-member` itself. Proves the planner now passes its own
/// `roleId` parameter into `evaluateGuard` rather than evaluating
/// `allowedRoleIds` with no role set at all, which fails closed regardless
/// of whether the acting role is actually allowed.
LoomWorkflowStateMachine _roleGatedVisibilityAdmittingMachine() =>
    LoomWorkflowStateMachine.fromJson(<String, dynamic>{
      'initialState': 'published',
      'visibility': <String, dynamic>{
        'default': 'guarded',
        'readGuard': <String, dynamic>{
          'allowedRoleIds': <String>['garden-member'],
        },
      },
      'states': <String, dynamic>{
        'published': <String, dynamic>{
          'label': 'Available',
          'editableFields': <String>['title'],
        },
      },
      'transitions': <Map<String, dynamic>>[],
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
              'label': 'List an item',
              'byRoleIds': <String>['garden-member'],
              'prefill': <String, dynamic>{},
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
      },
    }, 'role-gated-visibility-admitting-synthetic');

/// A synthetic workflow whose `cardSurfaceFamily` ("approvalQueueItem")
/// resolves to the `parties` archetype model, declaring both principal
/// shapes `visibility.fields.parties` supports: a field principal
/// (`requesterFanId`) and a role principal (`{"role": "garden-coordinator"}`).
/// Its own `readGuard` (`actorEqualsField: unrelatedFanId`, a field no seed
/// ever populates) always denies on its own, so either principal admitting
/// must be what rescues the row -- never the readGuard itself.
LoomWorkflowStateMachine _partiesVisibilityMachine() =>
    LoomWorkflowStateMachine.fromJson(<String, dynamic>{
      'initialState': 'open',
      'visibility': <String, dynamic>{
        'default': 'guarded',
        'readGuard': <String, dynamic>{
          'actorEqualsField': <String, dynamic>{'key': 'unrelatedFanId'},
        },
        'fields': <String, dynamic>{
          'parties': <dynamic>[
            'requesterFanId',
            <String, dynamic>{'role': 'garden-coordinator'},
          ],
        },
      },
      'states': <String, dynamic>{
        'open': <String, dynamic>{
          'label': 'Open',
          'editableFields': <String>['title'],
        },
      },
      'transitions': <Map<String, dynamic>>[],
      'renderBindings': <Map<String, dynamic>>[
        <String, dynamic>{
          'states': <String>['open'],
          'audience': 'any',
          'tabId': 'approvals',
          'cardSurfaceFamily': 'approvalQueueItem',
          'bindingKind': 'primary',
          'actions': <Map<String, dynamic>>[
            <String, dynamic>{
              'kind': 'create',
              'label': 'Submit request',
              'byRoleIds': <String>['garden-member', 'garden-coordinator'],
              'prefill': <String, dynamic>{},
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
      },
    }, 'parties-visibility-synthetic');
