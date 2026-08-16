import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

void main() {
  final environment = Platform.environment;
  const requiredVariables = {
    'LOOM_WORKFLOW_SERVICE_BEARER_TOKEN': 'a real fan JWT',
    'LOOM_WORKFLOW_SERVICE_COMMUNITY_ID': 'an installed live community id',
    'LOOM_WORKFLOW_SERVICE_WORKFLOW_TYPE': 'a creatable live workflow type',
    'LOOM_WORKFLOW_SERVICE_INITIAL_INSTANCE_DATA':
        'valid JSON for that workflow type',
  };
  final missing = requiredVariables.entries
      .where((entry) => environment[entry.key]?.isNotEmpty != true)
      .map((entry) => '${entry.key} (${entry.value})')
      .toList();
  final skipReason = missing.isEmpty
      ? false
      : 'Set ${missing.join(', ')} to run against the deployed k3s workflow '
            'service.';

  test(
    'deployed service createInstance is returned by queryInstances',
    () async {
      final initialData = jsonDecode(
        environment['LOOM_WORKFLOW_SERVICE_INITIAL_INSTANCE_DATA']!,
      );
      expect(
        initialData,
        isA<Map<String, dynamic>>(),
        reason:
            'LOOM_WORKFLOW_SERVICE_INITIAL_INSTANCE_DATA must be a JSON object.',
      );
      final client = http.Client();
      try {
        final api = RemoteWorkflowEngineApi(
          baseUri: Uri.parse(
            environment['LOOM_WORKFLOW_SERVICE_BASE_URI'] ??
                'http://127.0.0.1:18083',
          ),
          communityId: environment['LOOM_WORKFLOW_SERVICE_COMMUNITY_ID']!,
          bearerTokenProvider: () async =>
              environment['LOOM_WORKFLOW_SERVICE_BEARER_TOKEN']!,
          httpClient: client,
        );
        final instanceId = await api.createInstance(
          workflowType: environment['LOOM_WORKFLOW_SERVICE_WORKFLOW_TYPE']!,
          initialInstanceData: Map<String, dynamic>.from(initialData as Map),
          personaId: 'identity-comes-from-the-live-jwt',
        );
        WorkflowInstance? created;
        String? cursor;
        do {
          final page = await api.queryInstances(
            tabId: 'workflow-service',
            personaId: 'identity-comes-from-the-live-jwt',
            workflowType: environment['LOOM_WORKFLOW_SERVICE_WORKFLOW_TYPE'],
            limit: 100,
            cursor: cursor,
          );
          for (final instance in page.items) {
            if (instance.instanceId == instanceId) created = instance;
          }
          cursor = page.hasMore ? page.nextCursor : null;
        } while (created == null && cursor != null);

        expect(created, isNotNull);
        expect(
          created!.workflowType,
          environment['LOOM_WORKFLOW_SERVICE_WORKFLOW_TYPE'],
        );
        for (final entry in initialData.entries) {
          expect(created.instanceData, containsPair(entry.key, entry.value));
        }
      } finally {
        client.close();
      }
    },
    skip: skipReason,
  );
}
