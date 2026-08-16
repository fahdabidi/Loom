import 'dart:async';

import 'package:shelf/shelf.dart';

/// The authenticated identity supplied to workflow guard evaluation.
///
/// Phase B.1 carries only the fan id. App Access role resolution is deliberately
/// left for B.3, where resolved role ids can be registered with the shared
/// engine without accepting role claims from an HTTP request.
class WorkflowRequestIdentity {
  final String fanId;

  const WorkflowRequestIdentity({required this.fanId});
}

/// Swappable boundary between HTTP authentication and workflow execution.
///
/// Production uses JWT validation while tests may continue to supply a focused
/// extractor or the isolated header adapter without changing workflow routing
/// or execution.
abstract interface class WorkflowIdentityExtractor {
  FutureOr<WorkflowRequestIdentity?> extract(Request request);
}

/// Temporary Phase B identity adapter.
///
/// The header is an isolated development seam, not an authentication scheme.
/// It exists only so the service can prove server-side enforcement before the
/// Phase C token issuer and resource-server validation are available.
class HeaderWorkflowIdentityExtractor implements WorkflowIdentityExtractor {
  static const defaultHeaderName = 'x-loom-fan-id';

  final String headerName;

  const HeaderWorkflowIdentityExtractor({this.headerName = defaultHeaderName});

  @override
  WorkflowRequestIdentity? extract(Request request) {
    final fanId = request.headers[headerName]?.trim();
    if (fanId == null || fanId.isEmpty) return null;
    return WorkflowRequestIdentity(fanId: fanId);
  }
}
