import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';

const _fixtureRelative =
    'docs/references/communities/Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc';

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

Future<_InstalledFixture> _install(
  String extensionId, {
  void Function(Map<String, dynamic> source)? mutate,
}) async {
  final source =
      jsonDecode(stripJsonComments(_fixtureFile().readAsStringSync()))
          as Map<String, dynamic>;
  source['extensionId'] = extensionId;
  mutate?.call(source);
  final temp = await Directory.systemTemp.createTemp('loom-calr4g-$extensionId-');
  final init = File('${temp.path}/tabletop.loom-init.zip');
  final extension = File('${temp.path}/tabletop.loom-extension.zip');
  await init.writeAsString(jsonEncode(source));
  await extension.writeAsString(
    jsonEncode(<String, Object?>{
      'schemaVersion': 1,
      'extensionId': extensionId,
      'displayName': source['displayName'],
      'version': '1.0.0',
      'mode': 'local-demo',
      'permissions': <String>[],
    }),
  );
  final community = LocalInAppBackend()
      .installLocalPackagePairFromFiles(
        extensionPackagePath: extension.path,
        initializationPackagePath: init.path,
      )
      .community;
  experienceForExtensionId(
    extensionId,
    displayName: community.displayName,
    experienceConfiguration: community.experienceConfiguration,
  );
  await workflowEngineForExtensionId(extensionId);
  return _InstalledFixture(community, temp);
}

Widget _app(_InstalledFixture installed) => MaterialApp(
  home: LocalExtensionScreen(community: installed.community, seedDataFiles: const []),
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

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

Future<void> _openCatanAsMember(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('persona-picker-button')));
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(const ValueKey('persona-option-tabletop-member')),
  );
  await tester.pumpAndSettle();
  final marketplace = find.byKey(const ValueKey('community-tab-marketplace'));
  await tester.ensureVisible(marketplace);
  await tester.tap(marketplace);
  await _settle(tester);
  final catan = find.byKey(const ValueKey('marketplace-listing-listing-catan'));
  expect(catan, findsOneWidget);
  final catanFacts = find.byKey(
    const ValueKey('equipment-loan-facts-listing-catan-tile'),
  );
  expect(catanFacts, findsOneWidget);
  await tester.ensureVisible(catanFacts);
  // The keyed listing is an actionable card: its centered hit point can land
  // on a member action instead of bubbling to the tile's detail InkWell. Tap
  // the non-interactive facts row so this helper proves the dialog path.
  await tester.tap(catanFacts);
  await _pumpUntil(
    tester,
    find.byKey(const ValueKey('marketplace-detail-dialog-listing-catan')),
  );
  await _pumpUntil(
    tester,
    find.byKey(const ValueKey('marketplace-action-join-queue')),
  );
}

void _allowBorrowWithoutDues(Map<String, dynamic> source) {
  final definitions =
      (source['experience'] as Map<String, dynamic>)['workflowDefinitions']
          as Map<String, dynamic>;
  final loan = Map<String, dynamic>.from(definitions['equipment-loan'] as Map);
  final transitions = List<dynamic>.from(loan['transitions'] as List);
  final borrow = Map<String, dynamic>.from(transitions.first as Map);
  final guard = Map<String, dynamic>.from(borrow['guard'] as Map)
    ..remove('requiresWorkflowsComplete');
  borrow['guard'] = guard;
  transitions[0] = borrow;
  loan['transitions'] = transitions;
  definitions['equipment-loan'] = loan;
}

void main() {
  testWidgets(
    'Marketplace presents borrow as a guarded FAB and keeps other transitions in the automatic row',
    (tester) async {
      final installed = await tester.runAsync(
        () => _install('calr4g-borrow-fab', mutate: _allowBorrowWithoutDues),
      );
      try {
        await tester.pumpWidget(_app(installed!));
        await _openCatanAsMember(tester);
        final catanDialog = find.byKey(
          const ValueKey('marketplace-detail-dialog-listing-catan'),
        );

        expect(
          find.descendant(
            of: catanDialog,
            matching: find.byKey(const ValueKey('marketplace-action-borrow')),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: catanDialog,
            matching: find.byKey(
              const ValueKey('marketplace-action-join-queue'),
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: catanDialog,
            matching: find.byKey(
              const ValueKey('marketplace-transition-fab-borrow'),
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: catanDialog, matching: find.text('Request loan')),
          findsOneWidget,
        );

        await tester.tap(
          find.descendant(
            of: catanDialog,
            matching: find.byKey(
              const ValueKey('marketplace-transition-fab-borrow'),
            ),
          ),
        );
        await _settle(tester);
        expect(
          find.descendant(of: catanDialog, matching: find.text('onLoan')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: catanDialog,
            matching: find.text('Holder: tabletop-member'),
          ),
          findsOneWidget,
        );
      } finally {
        await tester.runAsync(installed!.dispose);
      }
    },
  );

  testWidgets('Marketplace hides the contextual FAB when borrow is disallowed', (
    tester,
  ) async {
    final installed = await tester.runAsync(
      () => _install('calr4g-borrow-guard', mutate: (source) {
        _allowBorrowWithoutDues(source);
        final instances =
            (source['experience'] as Map<String, dynamic>)['workflowInstances']
                as List<dynamic>;
        final catanIndex = instances.indexWhere(
          (instance) => (instance as Map)['instanceId'] == 'listing-catan',
        );
        final catan = Map<String, dynamic>.from(instances[catanIndex] as Map);
        final data = Map<String, dynamic>.from(catan['instanceData'] as Map)
          ..['availabilityState'] = 'onLoan';
        catan['instanceData'] = data;
        instances[catanIndex] = catan;
      }),
    );
    try {
      await tester.pumpWidget(_app(installed!));
      await _openCatanAsMember(tester);
      final catanDialog = find.byKey(
        const ValueKey('marketplace-detail-dialog-listing-catan'),
      );
      expect(
        find.descendant(
          of: catanDialog,
          matching: find.byKey(
            const ValueKey('marketplace-transition-fab-borrow'),
          ),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: catanDialog,
          matching: find.byKey(const ValueKey('marketplace-action-join-queue')),
        ),
        findsOneWidget,
      );
    } finally {
      await tester.runAsync(installed!.dispose);
    }
  });
}
