import 'package:loom_ux_judges/loom_ux_judges.dart';
import 'package:test/test.dart';

void main() {
  test('a community row with tabsPass true passes unchanged', () {
    final result = _judge(_passingReview());

    expect(result.criteria.single.verdict, 'pass');
  });

  test('a community row with tabsPass false is an explicit failure', () {
    final review = _passingReview();
    final row = _communityRow(review);
    row['tabsPass'] = false;

    final result = _judge(review);
    final criterion = result.criteria.single;
    final ticket = _ticketForCapability(result, 'app-shell-tabs-gap');

    expect(criterion.verdict, 'fail');
    expect(
      criterion.why,
      contains(
        'The review explicitly reports failed capabilities: Loom Test/member (tabsPass).',
      ),
    );
    expect(
      criterion.why,
      contains(
        'did not report these capabilities in the documented shape: none',
      ),
    );
    expect(
      ticket['whyItFailed'],
      contains('explicitly reports `tabsPass=false`'),
    );
    expect(ticket['whyItFailed'], contains('capability failure'));
  });

  test(
    'a string tabs field is absent/malformed evidence, not a capability failure',
    () {
      final review = _passingReview();
      _communityRow(review)
        ..remove('tabsPass')
        ..['tabs'] = 'pass';

      final result = _judge(review);
      final criterion = result.criteria.single;
      final ticket = _ticketForCapability(
        result,
        'app-shell-review-schema-gap',
      );

      expect(criterion.verdict, 'fail');
      expect(
        criterion.why,
        contains(
          'The review did not report these capabilities in the documented shape: Loom Test/member (tabsPass).',
        ),
      );
      expect(ticket['title'], contains('absent or wrong-typed: tabsPass'));
      expect(
        ticket['whyItFailed'],
        contains('expected boolean key `tabsPass` is absent'),
      );
      expect(ticket['whyItFailed'], contains('`tabs`'));
      expect(ticket['whyItFailed'], contains('not a capability failure'));
    },
  );

  test(
    'rendererContract does not match the documented rendererContractId key',
    () {
      final review = _passingReview();
      final calendarRow = _rendererRow(review, 'CalendarTabSurface');
      calendarRow['rendererContract'] = calendarRow['rendererContractId'];
      calendarRow.remove('rendererContractId');

      final result = _judge(review);
      final criterion = result.criteria.single;
      final ticket = _ticketForRenderer(result, 'CalendarTabSurface');

      expect(criterion.verdict, 'fail');
      expect(
        criterion.why,
        contains('Renderer contracts with no matching review row:'),
      );
      expect(
        ticket['title'],
        contains('no matching renderer-contract review row'),
      );
      expect(ticket['whyItFailed'], contains('`rendererContract`'));
      expect(ticket['whyItFailed'], contains('no matching row'));
      expect(
        (ticket['sourceFindingIds'] as List<Object?>).join(' '),
        isNot(contains('MISSING-PROOF')),
      );
    },
  );

  test(
    'a matched renderer row with affectedScreenRowIds is proven unchanged',
    () {
      final review = _passingReview();
      final calendarRow = _rendererRow(review, 'CalendarTabSurface');

      final result = _judge(review);

      expect(calendarRow['affectedScreenRowIds'], isNotEmpty);
      expect(result.criteria.single.verdict, 'pass');
    },
  );
}

JudgeResult _judge(Map<String, Object?> review) {
  final c16 = specs['production-ux-judge']!.criteria.singleWhere(
    (definition) => definition.id == 'b25-c16-app-shell-capability-utilization',
  );
  return judgeEvidence(
    JudgeSpec(
      toolId: 'production-ux-judge',
      phase: 'test',
      description: 'Focused app-shell capability review fixture.',
      criteria: <CriterionDefinition>[c16],
    ),
    <String, Object?>{'appShellCapabilityReview': review},
    basePath: '.',
  );
}

Map<String, Object?> _passingReview() {
  const contracts = <String>[
    'CalendarTabSurface',
    'MessagesTabSurface',
    'MarketplaceTabSurface',
    'DocumentsTabSurface',
    'WorkflowStatusSurface',
  ];
  return <String, Object?>{
    'status': 'pass',
    'missingCapabilities': <String>[],
    'communityResults': <Map<String, Object?>>[
      <String, Object?>{
        'communityName': 'Loom Test',
        'role': 'member',
        'status': 'pass',
        'tabsPass': true,
        'pinningPolicy': 'none',
        'pinningPolicyRationale':
            'Home remains an overview for this member role.',
        'pinningPolicyPass': true,
        'pinnedSurfacesExpected': false,
        'pinnedSurfacesPass': true,
        'presentationStatesPass': true,
        'mainCommunityCardStatesPass': true,
        'themeCustomizationPass': true,
        'rendererSelectionPass': true,
        'affectedScreenRowIds': <String>['shell-home'],
        'affectedScreenshotHashes': <String>['shell-home-hash'],
        'visibleTextExcerpt':
            'Home shows a focused community card with expanded member content.',
      },
    ],
    'tabRendererResults': <Map<String, Object?>>[
      for (final contract in contracts)
        <String, Object?>{
          'rendererContractId': contract,
          'status': 'pass',
          'blocksPass': false,
          'affectedScreenRowIds': <String>['${contract}_screen'],
          'affectedScreenshotHashes': <String>['${contract}_hash'],
          'visibleEvidence': <String>[
            '$contract visibly renders its dedicated tab-native product surface.',
          ],
          'visibleTextExcerpt':
              '$contract exposes product content, controls, and state from the current screenshot.',
        },
    ],
  };
}

Map<String, Object?> _communityRow(Map<String, Object?> review) =>
    (review['communityResults'] as List<Map<String, Object?>>).single;

Map<String, Object?> _rendererRow(
  Map<String, Object?> review,
  String contract,
) => (review['tabRendererResults'] as List<Map<String, Object?>>).singleWhere(
  (row) => row['rendererContractId'] == contract,
);

Map<String, Object?> _ticketForCapability(
  JudgeResult result,
  String capability,
) => _tickets(
  result,
).singleWhere((ticket) => ticket['sourceCapability'] == capability);

Map<String, Object?> _ticketForRenderer(JudgeResult result, String contract) =>
    _tickets(
      result,
    ).singleWhere((ticket) => ticket['rendererContractId'] == contract);

List<Map<String, Object?>> _tickets(JudgeResult result) =>
    ((result.extra['remediationTickets'] as List<Object?>?) ??
            const <Object?>[])
        .cast<Map<String, Object?>>();
