import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'b25_product_doc_role_resolution.dart';
import 'b25_workflow_row_selection.dart';

void main() {
  group('B25 product-doc role resolution', () {
    test('an existing exact roleId remains unchanged', () {
      final resolution = resolveB25ProductDocRole(
        extensionId: 'ext_neighborhood_book_club',
        role: 'book-member',
        actorIdentities: _bookClubIdentities,
      );

      expect(resolution.roleIds, ['book-member']);
      expect(resolution.requiresTwoActorWalkthrough, isFalse);
    });

    test('exact labels resolve case-insensitively', () {
      expect(
        resolveB25ProductDocRole(
          extensionId: 'ext_neighborhood_book_club',
          role: 'member',
          actorIdentities: _bookClubIdentities,
        ).roleIds,
        ['book-member'],
      );
      expect(
        resolveB25ProductDocRole(
          extensionId: 'ext_mosque',
          role: 'masjid admin',
          actorIdentities: _mosqueIdentities,
        ).roleIds,
        ['owner'],
      );
    });

    test('a slash pair resolves both sides independently', () {
      final resolution = resolveB25ProductDocRole(
        extensionId: 'ext_mosque',
        role: 'community member / masjid admin',
        actorIdentities: _mosqueIdentities,
      );

      expect(resolution.roleIds, ['community-member', 'owner']);
      expect(resolution.requiresTwoActorWalkthrough, isTrue);
    });

    test(
      'the closed narrative qualifier set resolves, including a pair side',
      () {
        expect(b25DocumentedNarrativeQualifierPhrases, {
          'community member acting as donor',
          'community member recipient',
          'community member acting as payer',
        });
        for (final role in b25DocumentedNarrativeQualifierPhrases) {
          expect(
            resolveB25ProductDocRole(
              extensionId: 'ext_mosque',
              role: role,
              actorIdentities: _mosqueIdentities,
            ).roleIds,
            ['community-member'],
            reason: role,
          );
        }
        expect(
          resolveB25ProductDocRole(
            extensionId: 'ext_mosque',
            role: 'community member acting as payer / masjid admin',
            actorIdentities: _mosqueIdentities,
          ).roleIds,
          ['community-member', 'owner'],
        );
      },
    );

    test('qualifier-like prose outside the closed set fails loudly', () {
      expect(
        () => resolveB25ProductDocRole(
          extensionId: 'ext_mosque',
          role: 'community member seeking assistance',
          actorIdentities: _mosqueIdentities,
        ),
        throwsA(
          isA<B25ProductDocRoleResolutionFailure>().having(
            (error) => error.message,
            'message',
            allOf(
              contains(
                'B25 product-doc role `community member seeking assistance`',
              ),
              contains(
                'owner (Masjid Admin), community-member (Community Member)',
              ),
            ),
          ),
        ),
      );
    });

    test(
      'an ambiguous label fails with the named available-identities diagnostic',
      () {
        final ambiguousIdentities = <LoomActorIdentity>[
          _identity(roleId: 'member-a', label: 'Member'),
          _identity(roleId: 'member-b', label: 'Member'),
        ];

        expect(
          () => resolveB25ProductDocRole(
            extensionId: 'ext_ambiguous',
            role: 'member',
            actorIdentities: ambiguousIdentities,
          ),
          throwsA(
            isA<B25ProductDocRoleResolutionFailure>().having(
              (error) => error.message,
              'message',
              allOf(
                contains(
                  'Shipped package ext_ambiguous has no actor identity that can represent B25 product-doc role `member`.',
                ),
                contains(
                  'Available identities: member-a (Member), member-b (Member).',
                ),
                contains('Resolution is ambiguous'),
              ),
            ),
          ),
        );
      },
    );

    test(
      'Book Club owner remains an unresolvable product-doc/package mismatch',
      () {
        expect(
          () => resolveB25ProductDocRole(
            extensionId: 'ext_neighborhood_book_club',
            role: 'owner',
            actorIdentities: _bookClubIdentities,
          ),
          throwsA(
            isA<B25ProductDocRoleResolutionFailure>().having(
              (error) => error.message,
              'message',
              'Shipped package ext_neighborhood_book_club has no actor identity '
                  'that can represent B25 product-doc role `owner`. Available '
                  'identities: book-member (Member), book-organizer (Organizer).',
            ),
          ),
        );
      },
    );

    test('a one-actor walkthrough records a named compound-role outcome', () {
      final resolution = resolveB25ProductDocRole(
        extensionId: 'ext_mosque',
        role: 'masjid admin / community member',
        actorIdentities: _mosqueIdentities,
      );

      final selection = selectB25WorkflowRow(
        () => requireSingleActorIdentityB25Walkthrough(
          extensionId: 'ext_mosque',
          resolution: resolution,
        ),
      );

      expect(selection.selector, isNull);
      expect(selection.isBlockedBySelectorSetup, isTrue);
      expect(
        selection.blockedCause,
        B25CompoundRoleWalkthroughFailure.outcomeCause,
      );
      expect(
        selection.blockedReason,
        contains('instead of silently selecting the first actor identity'),
      );
    });
  });
}

final _mosqueIdentities = <LoomActorIdentity>[
  _identity(roleId: 'owner', label: 'Masjid Admin'),
  _identity(roleId: 'community-member', label: 'Community Member'),
];

final _bookClubIdentities = <LoomActorIdentity>[
  _identity(roleId: 'book-member', label: 'Member'),
  _identity(roleId: 'book-organizer', label: 'Organizer'),
];

LoomActorIdentity _identity({required String roleId, required String label}) =>
    LoomActorIdentity(
      fanId: '$roleId-fan',
      roleId: roleId,
      label: label,
      roleLabel: label,
      description: '$label description',
    );
