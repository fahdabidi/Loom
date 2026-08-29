import 'dart:convert';
import 'dart:io';

import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:loom_workflow_service/src/definition_publisher.dart';
import 'package:test/test.dart';

void main() {
  late Directory assetsDirectory;

  setUp(() async {
    assetsDirectory = await Directory.systemTemp.createTemp(
      'loom_definition_publisher_test_',
    );
  });

  tearDown(() async {
    await assetsDirectory.delete(recursive: true);
  });

  test(
    'uses the package community id in reader-visible ids and round trips every workflow',
    () async {
      const communityId = 'community_from_package_body';
      final definitions = <String, Map<String, dynamic>>{
        'appointment': <String, dynamic>{'initialState': 'requested'},
        'intake': <String, dynamic>{'initialState': 'open'},
      };
      await _writePackage(
        assetsDirectory,
        fileName: 'verify_tabletop_club.jsonc',
        communityId: communityId,
        definitions: definitions,
      );

      final packages = await _readValidPackages(assetsDirectory);
      final database = WorkflowDatabase.memory();
      final report = await WorkflowDefinitionPublisher(
        database: database,
      ).publish(packages, write: true);

      expect(
        report.publications.map((publication) => publication.definitionId),
        unorderedEquals(<String>[
          '${communityId}_appointment',
          '${communityId}_intake',
        ]),
      );
      expect(
        await database.loadDefinitionJson('${communityId}_appointment'),
        isNotNull,
      );
      expect(
        await database.loadDefinitionJson('verify_tabletop_club_appointment'),
        isNull,
      );
      expect(
        await database.loadDefinitionsForCommunity(communityId),
        equals(definitions),
      );
      database.close();
    },
  );

  test(
    'repeated publishing updates existing definitions without extra rows',
    () async {
      const communityId = 'community_repeatable';
      await _writePackage(
        assetsDirectory,
        fileName: 'repeatable.jsonc',
        communityId: communityId,
        definitions: <String, Map<String, dynamic>>{
          'request': <String, dynamic>{'revision': 1},
        },
      );
      final database = WorkflowDatabase.memory();
      final publisher = WorkflowDefinitionPublisher(database: database);

      final first = await publisher.publish(
        await _readValidPackages(assetsDirectory),
        write: true,
      );
      final second = await publisher.publish(
        await _readValidPackages(assetsDirectory),
        write: true,
      );

      expect(
        first.publications.single.action,
        WorkflowDefinitionPublicationAction.insert,
      );
      expect(
        second.publications.single.action,
        WorkflowDefinitionPublicationAction.update,
      );
      expect(
        await database.loadDefinitionsForCommunity(communityId),
        hasLength(1),
      );

      await _writePackage(
        assetsDirectory,
        fileName: 'repeatable.jsonc',
        communityId: communityId,
        definitions: <String, Map<String, dynamic>>{
          'request': <String, dynamic>{'revision': 2},
        },
      );
      final third = await publisher.publish(
        await _readValidPackages(assetsDirectory),
        write: true,
      );

      expect(
        third.publications.single.action,
        WorkflowDefinitionPublicationAction.update,
      );
      expect(
        (await database.loadDefinitionsForCommunity(communityId))['request'],
        equals(<String, dynamic>{'revision': 2}),
      );
      expect(
        await database.loadDefinitionsForCommunity(communityId),
        hasLength(1),
      );
      database.close();
    },
  );

  test('names a malformed package instead of silently skipping it', () async {
    await File(
      '${assetsDirectory.path}/unreadable_body.jsonc',
    ).writeAsString('{"communityId": ');

    final result = await readCommunityWorkflowPackages(assetsDirectory);

    expect(result.packages, isEmpty);
    expect(result.errors, hasLength(1));
    expect(result.errors.single.fileName, 'unreadable_body.jsonc');
    expect(result.errors.single.reason, contains('invalid JSONC'));
  });

  test(
    'names a package with no workflows instead of treating it as empty',
    () async {
      await _writePackage(
        assetsDirectory,
        fileName: 'empty_workflows.jsonc',
        communityId: 'community_empty_workflows',
        definitions: const <String, Map<String, dynamic>>{},
      );

      final result = await readCommunityWorkflowPackages(assetsDirectory);

      expect(result.packages, isEmpty);
      expect(result.errors, hasLength(1));
      expect(result.errors.single.fileName, 'empty_workflows.jsonc');
      expect(result.errors.single.reason, contains('workflowDefinitions'));
    },
  );

  test('dry run reports planned writes and stores no definitions', () async {
    const communityId = 'community_dry_run';
    await _writePackage(
      assetsDirectory,
      fileName: 'dry_run.jsonc',
      communityId: communityId,
      definitions: <String, Map<String, dynamic>>{
        'request': <String, dynamic>{'initialState': 'draft'},
      },
    );
    final messages = <String>[];
    final database = WorkflowDatabase.memory();

    final report = await WorkflowDefinitionPublisher(
      database: database,
      report: messages.add,
    ).publish(await _readValidPackages(assetsDirectory));

    expect(report.wrote, isFalse);
    expect(
      report.publications.single.action,
      WorkflowDefinitionPublicationAction.insert,
    );
    expect(await database.loadDefinitionJson('${communityId}_request'), isNull);
    expect(messages.join('\n'), contains('DRY RUN'));
    expect(messages.join('\n'), contains('no definitions were written'));
    database.close();
  });
}

Future<List<CommunityWorkflowPackage>> _readValidPackages(
  Directory assetsDirectory,
) async {
  final result = await readCommunityWorkflowPackages(assetsDirectory);
  expect(result.errors, isEmpty);
  return result.packages;
}

Future<void> _writePackage(
  Directory directory, {
  required String fileName,
  required String communityId,
  required Map<String, Map<String, dynamic>> definitions,
}) {
  final definitionsJson = const JsonEncoder.withIndent(
    '  ',
  ).convert(definitions);
  return File('${directory.path}/$fileName').writeAsString('''
// The comment verifies this reader accepts the JSONC shipped by the app.
{
  "specVersion": $currentCommunitySpecVersion,
  "communityId": "$communityId",
  "sourceUrl": "https://communities.loom.example/packages/$fileName",
  "experience": {
    /* workflow definitions are authored by the community package */
    "workflowDefinitions": $definitionsJson
  }
}
''');
}
