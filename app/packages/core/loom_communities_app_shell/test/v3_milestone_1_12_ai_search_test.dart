import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';

const _memberId = 'tabletop-member';
const _firstQuery = 'When is game night?';
const _firstAnswer = 'Game night begins at 7 PM every Friday.';
const _firstCitation = 'Tabletop Club weekly schedule';
const _secondQuery = 'How do I borrow a game?';
const _secondAnswer =
    'Ask the librarian to check out an available game for one week.';
const _secondCitation = 'Tabletop Club lending policy';
const _unknownQuery = 'Where can I park?';

LocalInstalledCommunity _community() => const LocalInstalledCommunity(
  communityId: 'v3-ai-search-community',
  displayName: 'Tabletop Club',
  extensionId: 'v3-ai-search',
  logoAssetId: null,
  cardImageAssetId: null,
  heroImageAssetId: null,
  accentColor: '#4a3b2a',
  experienceConfiguration: {
    'workflows': [
      {
        'workflowId': 'tabletop-ai-search',
        'title': 'Tabletop Club knowledge search',
        'entryText': 'Ask a question about the club.',
        'actionText': 'Search club knowledge.',
        'resultText': 'A cited answer is ready when one is available.',
      },
    ],
    'personas': [
      {
        'personaId': _memberId,
        'label': 'Member',
        'roleLabel': 'Member',
        'description': 'Tabletop Club member',
      },
    ],
    'aiSearchAnswers': [
      {
        'query': _firstQuery,
        'answer': _firstAnswer,
        'citations': [_firstCitation],
      },
      {
        'query': _secondQuery,
        'answer': _secondAnswer,
        'citations': [_secondCitation],
      },
    ],
  },
);

Widget _host() => MaterialApp(
  home: LocalExtensionScreen(community: _community(), seedDataFiles: const []),
);

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 30; attempt += 1) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

Future<void> _submitQuery(WidgetTester tester, String query) async {
  final field = find.byKey(const ValueKey('ai-search-field'));
  await tester.enterText(field, query);
  await _tapVisible(tester, find.byKey(const ValueKey('ai-search-submit')));
  await tester.pump();
}

void main() {
  testWidgets('distinct seeded queries replace the cited AI search result', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('community-tab-search')),
    );
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('ai-search-field')),
    );

    await _submitQuery(tester, _firstQuery);
    expect(find.byKey(const ValueKey('ai-search-result')), findsOneWidget);
    expect(find.text(_firstAnswer), findsOneWidget);
    expect(find.text(_firstCitation), findsOneWidget);
    expect(find.text(_secondAnswer), findsNothing);

    await _submitQuery(tester, _secondQuery);
    expect(find.byKey(const ValueKey('ai-search-result')), findsOneWidget);
    expect(find.text(_secondAnswer), findsOneWidget);
    expect(find.text(_secondCitation), findsOneWidget);
    expect(find.text(_firstAnswer), findsNothing);
    expect(find.text(_firstCitation), findsNothing);
  });

  testWidgets('an unseeded query has a genuine no-citation result', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('community-tab-search')),
    );
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('ai-search-field')),
    );

    await _submitQuery(tester, _unknownQuery);

    expect(find.byKey(const ValueKey('ai-search-no-citation')), findsOneWidget);
    expect(
      find.text('No citation found for "$_unknownQuery".'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('ai-search-answer')), findsNothing);
  });
}
