import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'local delivery does not throw without a real platform channel',
    () async {
      final service = LocalNotificationDeliveryService();

      await expectLater(
        service.deliver(
          const WorkflowInstance(
            instanceId: 'notification-test-1',
            workflowType: 'notification',
            currentState: 'unread',
            instanceData: {
              'title': 'Test notification',
              'body': 'No platform channel is available in this test.',
            },
            createdByFanId: 'member',
          ),
        ),
        completes,
      );
    },
  );
}
