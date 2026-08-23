import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart'
    show currentCommunitySpecVersion;

const _fixtureRelative =
    'docs/references/communities/Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc';
const _fridayInstanceId = 'event-friday-game-night';

File _fixtureFile() {
  var directory = Directory.current;
  for (var i = 0; i < 8; i++) {
    final candidate = File('${directory.path}/$_fixtureRelative');
    if (candidate.existsSync()) return candidate;
    directory = directory.parent;
  }
  throw StateError('Could not find frozen Tabletop fixture');
}

class _InstalledFixture {
  const _InstalledFixture(this.community, this.temp);

  final LocalInstalledCommunity community;
  final Directory temp;

  Future<void> dispose() => temp.delete(recursive: true);
}

Future<_InstalledFixture> _installFrozenTabletop({
  String? extensionIdSuffix,
}) async {
  final source =
      jsonDecode(stripJsonComments(_fixtureFile().readAsStringSync()))
          as Map<String, dynamic>;
  // `_EngineNativeCommunityStore._stores` caches one engine per extensionId
  // for the lifetime of the isolate -- multiple testWidgets blocks in this
  // same file otherwise share that cached engine across tests. Reusing a
  // warm engine across a Flutter *test* zone boundary (as opposed to across
  // widget rebuilds within one test) leaves a `Future` whose completion
  // callbacks never fire in the new test's zone -- confirmed directly by
  // instrumenting `_EngineNativeCommunityStore.ensureReady()`: the exact
  // same, already-completed `_ready` future is returned, but `.then()`
  // callbacks registered on it from the second `testWidgets` block never
  // resolve, hanging `_refreshCommunityEntryGate` on the
  // `community-entry-checking` spinner forever. This is a `flutter_test`
  // FakeAsync-zone artifact of the static `_stores` cache surviving across
  // tests, not a production bug (a direct, non-widget-tree call to
  // `workflowEngineForExtensionId` after two full mount/unmount cycles
  // resolves instantly). Giving a test its own suffixed extensionId
  // isolates it from any engine state left over by an earlier test in this
  // file, avoiding the zone boundary entirely.
  if (extensionIdSuffix != null) {
    source['extensionId'] = '${source['extensionId']}-$extensionIdSuffix';
    if (source['communityId'] is String) {
      source['communityId'] = '${source['communityId']}-$extensionIdSuffix';
    }
  }
  final extensionId = source['extensionId'] as String;
  final temp = await Directory.systemTemp.createTemp('loom-calr4b-');
  try {
    final init = File('${temp.path}/tabletop.loom-init.zip');
    final extension = File('${temp.path}/tabletop.loom-extension.zip');
    await init.writeAsString(jsonEncode(source));
    await extension.writeAsString(
      jsonEncode(<String, Object?>{
        'specVersion': currentCommunitySpecVersion,
        'extensionId': extensionId,
        'displayName': source['displayName'],
        'version': '1.0.0',
        'mode': 'local-demo',
        'permissions': <String>[],
      }),
    );
    return _InstalledFixture(
      LocalInAppBackend()
          .installLocalPackagePairFromFiles(
            extensionPackagePath: extension.path,
            initializationPackagePath: init.path,
          )
          .community,
      temp,
    );
  } catch (_) {
    await temp.delete(recursive: true);
    rethrow;
  }
}

Widget _app(_InstalledFixture fixture, {LoomAuthApi? authApi}) => MaterialApp(
  home: LocalExtensionScreen(
    community: fixture.community,
    seedDataFiles: const [],
    authApi: authApi,
  ),
);

/// Builds an auth provider with the same seeded demo accounts
/// `LocalAuthApi`'s default constructor seeds under the frozen fixture's
/// original extension id, but associated with [extensionId] instead. Used
/// so a suffixed-extensionId fixture (see `_installFrozenTabletop`'s
/// `extensionIdSuffix`) still has its usual "Priya N." / "Casey M." demo
/// accounts to sign in as.
Future<LoomAuthApi> _authApiWithTabletopAccountsFor(String extensionId) async {
  const originalExtensionId = 'ext_verify_tabletop_club';
  final defaultAccounts = await LocalAuthApi().listAccounts(
    communityExtensionId: originalExtensionId,
  );
  return LocalAuthApi()..seedAccounts(extensionId, defaultAccounts);
}

LocalInstalledCommunity _apartmentEventsCommunity() =>
    const LocalInstalledCommunity(
      communityId: 'apartment-events',
      displayName: 'Apartment Events',
      extensionId: 'authz-p1-apartment-events-ui',
      logoAssetId: null,
      cardImageAssetId: null,
      heroImageAssetId: null,
      accentColor: '#2f6f67',
      specVersion: currentCommunitySpecVersion,
      experienceConfiguration: <String, Object?>{
        'roles': <Object?>[
          <String, Object?>{
            'roleId': 'apartment-event-manager',
            'label': 'Event manager',
            'roleLabel': 'Manager',
            'description': 'Coordinates apartment events.',
          },
          <String, Object?>{
            'roleId': 'apartment-resident',
            'label': 'Resident',
            'roleLabel': 'Resident',
            'description': 'Attends apartment events.',
          },
          <String, Object?>{
            'roleId': 'facility-privileged-resident',
            'label': 'Facility resident',
            'roleLabel': 'Privileged resident',
            'description': 'Uses privileged facility access.',
          },
        ],
        'workflowDefinitions': <String, Object?>{
          'apartment-event-calendar': <String, Object?>{
            'initialState': 'open',
            'states': <String, Object?>{
              'open': <String, Object?>{'label': 'Apartment Events calendar'},
            },
            'transitions': <Object?>[],
            'renderBindings': <Object?>[
              <String, Object?>{
                'states': <String>['open'],
                'audience': 'any',
                'tabId': 'calendar',
                'cardSurfaceFamily': 'event-rsvp',
                'bindingKind': 'summary',
              },
            ],
            'instanceDataSchema': <String, Object?>{},
          },
        },
      },
    );

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _signInAs(WidgetTester tester, String displayName) async {
  // The entry gate briefly shows a "checking" spinner (neither the gate nor
  // signed-in content) while it resolves whether an account is already
  // active. Branching on the gate's presence before that resolves picks the
  // wrong branch below -- wait it out first.
  for (var attempt = 0; attempt < 40; attempt++) {
    if (find
        .byKey(const ValueKey('community-entry-checking'))
        .evaluate()
        .isEmpty) {
      break;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
  if (find
      .byKey(const ValueKey('community-entry-gate'))
      .evaluate()
      .isNotEmpty) {
    await _pumpUntil(tester, find.text(displayName));
    await tester.ensureVisible(find.text(displayName).first);
    await tester.pump();
    await tester.tap(find.text(displayName).first);
    await _pumpUntil(
      tester,
      find.byKey(const ValueKey('actor-identity-picker-button')),
    );
    await _settle(tester);
    return;
  }
  await tester.tap(find.byKey(const ValueKey('actor-identity-picker-button')));
  await _pumpUntil(
    tester,
    find.byKey(const ValueKey('actor-identity-sign-in-specific-person')),
  );
  await tester.ensureVisible(
    find.byKey(const ValueKey('actor-identity-sign-in-specific-person')),
  );
  await tester.pump();
  await tester.tap(
    find.byKey(const ValueKey('actor-identity-sign-in-specific-person')),
  );
  await _pumpUntil(tester, find.text(displayName));
  await tester.ensureVisible(find.text(displayName).first);
  await tester.pump();
  await tester.tap(find.text(displayName).first);
  await _pumpUntil(
    tester,
    find.byKey(const ValueKey('actor-identity-picker-button')),
  );
  await _settle(tester);
}

Future<void> _openSpecificPersonSignIn(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('actor-identity-picker-button')));
  await _pumpUntil(
    tester,
    find.byKey(const ValueKey('actor-identity-sign-in-specific-person')),
  );
  await tester.ensureVisible(
    find.byKey(const ValueKey('actor-identity-sign-in-specific-person')),
  );
  await tester.pump();
  await tester.tap(
    find.byKey(const ValueKey('actor-identity-sign-in-specific-person')),
  );
  await _pumpUntil(tester, find.text('Create New Account'));
}

Future<void> _openFridayDetail(WidgetTester tester) async {
  final calendarTab = find.byKey(const ValueKey('community-tab-calendar'));
  await _pumpUntil(tester, calendarTab);
  await tester.tap(calendarTab);
  final agenda = find.byKey(
    const ValueKey('engine-native-calendar-agenda-event-friday-game-night-0'),
  );
  await _pumpUntil(tester, agenda);
  await tester.ensureVisible(agenda);
  await tester.tap(agenda);
  await _pumpUntil(
    tester,
    find.byKey(const ValueKey('event-rsvp-card-$_fridayInstanceId')),
  );
  await _settle(tester);
}

InputChip _responseChip(WidgetTester tester, String transitionId) =>
    tester.widget<InputChip>(
      find.descendant(
        of: find.byKey(
          ValueKey('event-rsvp-$_fridayInstanceId-action-$transitionId'),
        ),
        matching: find.byType(InputChip),
      ),
    );

void main() {
  testWidgets(
    'individual account sign-in resolves Friday RSVP rows through the app shell',
    (tester) async {
      final fixture = (await tester.runAsync(_installFrozenTabletop))!;
      try {
        await tester.pumpWidget(_app(fixture));

        await _signInAs(tester, 'Priya N.');
        await _openFridayDetail(tester);

        expect(
          find.byKey(const ValueKey('event-rsvp-error-$_fridayInstanceId')),
          findsNothing,
        );
        expect(
          find.text('No response record is available for you for this event.'),
          findsNothing,
        );
        expect(_responseChip(tester, 'respond-going').selected, isTrue);

        await tester.ensureVisible(
          find.byKey(
            const ValueKey(
              'event-rsvp-$_fridayInstanceId-action-respond-maybe',
            ),
          ),
        );
        await tester.tap(
          find.byKey(
            const ValueKey(
              'event-rsvp-$_fridayInstanceId-action-respond-maybe',
            ),
          ),
        );
        await _settle(tester);
        expect(_responseChip(tester, 'respond-maybe').selected, isTrue);

        await _signInAs(tester, 'Casey M.');
        await _openFridayDetail(tester);

        expect(
          find.byKey(const ValueKey('event-rsvp-error-$_fridayInstanceId')),
          findsNothing,
        );
        expect(
          find.text('No response record is available for you for this event.'),
          findsNothing,
        );
        expect(_responseChip(tester, 'respond-going').selected, isTrue);
        expect(_responseChip(tester, 'respond-maybe').selected, isFalse);
      } finally {
        await tester.runAsync(fixture.dispose);
      }
    },
  );

  testWidgets(
    'sign-up actorIdentity options come from the open community declaration',
    (tester) async {
      final community = _apartmentEventsCommunity();
      await tester.pumpWidget(
        MaterialApp(
          home: LocalExtensionScreen(
            community: community,
            seedDataFiles: const [],
          ),
        ),
      );

      await _pumpUntil(tester, find.text('Create New Account'));

      final dropdown = tester.widget<DropdownButton<String>>(
        find.descendant(
          of: find.byType(DropdownButtonFormField<String>),
          matching: find.byType(DropdownButton<String>),
        ),
      );
      expect(dropdown.items!.map((item) => item.value).toList(), <String>[
        'apartment-event-manager',
        'apartment-resident',
        'facility-privileged-resident',
      ]);
      expect(
        dropdown.items!.map((item) => (item.child as Text).data).toList(),
        <String?>['Event manager', 'Resident', 'Facility resident'],
      );
      expect(find.text('tabletop-member'), findsNothing);
      expect(find.text('tabletop-organizer'), findsNothing);
    },
  );

  testWidgets(
    'active identity is visible in role picker, home, and account list',
    (tester) async {
      final fixture = (await tester.runAsync(
        () => _installFrozenTabletop(extensionIdSuffix: 'active-identity'),
      ))!;
      final authApi = await _authApiWithTabletopAccountsFor(
        fixture.community.extensionId,
      );
      try {
        await tester.pumpWidget(_app(fixture, authApi: authApi));

        await _signInAs(tester, 'Priya N.');
        expect(find.textContaining('Signed in as Priya N.'), findsOneWidget);

        await _openSpecificPersonSignIn(tester);

        final priyaTile = find.ancestor(
          of: find.text('Priya N.'),
          matching: find.byType(ListTile),
        );
        expect(priyaTile, findsOneWidget);
        expect(
          find.descendant(
            of: priyaTile,
            matching: find.widgetWithText(Chip, 'Signed in'),
          ),
          findsOneWidget,
        );

        final caseyTile = find.ancestor(
          of: find.text('Casey M.'),
          matching: find.byType(ListTile),
        );
        expect(
          find.descendant(
            of: caseyTile,
            matching: find.widgetWithText(Chip, 'Signed in'),
          ),
          findsNothing,
        );
        expect(
          find.descendant(of: caseyTile, matching: find.byIcon(Icons.login)),
          findsOneWidget,
        );

        // LoomAuthScreen has no back button (a separate, already-tracked UX
        // finding) -- pop the pushed route programmatically instead of
        // tapping a UI affordance that doesn't exist.
        Navigator.of(tester.element(find.byType(LoomAuthScreen))).pop();
        await tester.pumpAndSettle();
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('actor-identity-picker-button')),
        );

        await tester.tap(
          find.byKey(const ValueKey('actor-identity-picker-button')),
        );
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('actor-identity-picker-dialog')),
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('actor-identity-picker-dialog')),
            matching: find.text('Signed in as Priya N.'),
          ),
          findsOneWidget,
        );
      } finally {
        await tester.runAsync(fixture.dispose);
      }
    },
  );
}
