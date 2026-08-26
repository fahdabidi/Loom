import 'dart:io';

import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:test/test.dart';

void main() {
  test(
    'persistent SQLite upgrades the legacy creator column without losing rows',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'workflow-database-migration-',
      );
      final path = '${directory.path}/legacy.sqlite';
      final legacyDatabase = sqlite.sqlite3.open(path);
      try {
        _createLegacyWorkflowInstancesTable(legacyDatabase);
        legacyDatabase.execute('''
          INSERT INTO workflow_instances (
            instance_id, community_id, workflow_type, current_state,
            instance_data, created_at, updated_at, created_by_persona_id
          ) VALUES (
            'legacy-instance', 'legacy-community', 'legacy-workflow', 'draft',
            '{}', 101, 102, 'legacy-fan'
          )
        ''');
      } finally {
        legacyDatabase.dispose();
      }

      final database = WorkflowDatabase.file(path);
      try {
        await database.insertInstance(
          instanceId: 'new-instance',
          communityId: 'legacy-community',
          workflowType: 'legacy-workflow',
          currentState: 'draft',
          instanceData: const {},
          createdByFanId: 'new-fan',
        );

        final preserved = await database.readInstance('legacy-instance');
        expect(preserved, isNotNull);
        expect(preserved!.createdByFanId, 'legacy-fan');

        final inspectionDatabase = sqlite.sqlite3.open(path);
        try {
          final columns = inspectionDatabase
              .select('PRAGMA table_info(workflow_instances)')
              .map((row) => row['name'] as String)
              .toSet();
          expect(columns, contains('created_by_fan_id'));
          expect(columns, isNot(contains('created_by_persona_id')));
        } finally {
          inspectionDatabase.dispose();
        }
      } finally {
        database.close();
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      }
    },
  );

  test(
    'migration is idempotent and a fresh persistent SQLite database is current',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'workflow-database-migration-',
      );
      final path = '${directory.path}/fresh.sqlite';
      try {
        final firstOpen = WorkflowDatabase.file(path);
        await firstOpen.countInstances('fresh-community');
        firstOpen.close();

        final secondOpen = WorkflowDatabase.file(path);
        await secondOpen.countInstances('fresh-community');
        secondOpen.close();

        final inspectionDatabase = sqlite.sqlite3.open(path);
        try {
          final columns = inspectionDatabase
              .select('PRAGMA table_info(workflow_instances)')
              .map((row) => row['name'] as String)
              .toSet();
          expect(columns, contains('created_by_fan_id'));
          expect(columns, isNot(contains('created_by_persona_id')));
        } finally {
          inspectionDatabase.dispose();
        }
      } finally {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      }
    },
  );

  test(
    'persistent SQLite fails startup when both creator columns are present',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'workflow-database-migration-',
      );
      final path = '${directory.path}/ambiguous.sqlite';
      final ambiguousDatabase = sqlite.sqlite3.open(path);
      try {
        _createLegacyWorkflowInstancesTable(ambiguousDatabase);
        ambiguousDatabase.execute(
          'ALTER TABLE workflow_instances ADD COLUMN created_by_fan_id TEXT',
        );
      } finally {
        ambiguousDatabase.dispose();
      }

      final database = WorkflowDatabase.file(path);
      try {
        await expectLater(
          database.countInstances('ambiguous-community'),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('both created_by_persona_id and created_by_fan_id'),
            ),
          ),
        );
      } finally {
        database.close();
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      }
    },
  );
}

void _createLegacyWorkflowInstancesTable(sqlite.Database database) {
  database.execute('''
    CREATE TABLE workflow_instances (
      instance_id TEXT PRIMARY KEY,
      community_id TEXT NOT NULL,
      workflow_type TEXT NOT NULL,
      current_state TEXT NOT NULL,
      instance_data TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      created_by_persona_id TEXT NOT NULL
    )
  ''');
}
