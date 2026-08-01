import 'workflow_engine_api.dart';

/// Delivers a workflow notification to a recipient.
///
/// The workflow engine only owns the delivery boundary. Implementations may
/// deliver locally, through a future backend, or through another host-owned
/// channel without changing workflow creation call sites.
abstract interface class NotificationDeliveryService {
  Future<void> deliver(WorkflowInstance notification);
}
