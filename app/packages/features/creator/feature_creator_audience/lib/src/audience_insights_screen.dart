import 'package:flutter/material.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_design_system/loom_design_system.dart';

class AudienceInsightsScreen extends StatefulWidget {
  const AudienceInsightsScreen({
    required this.creatorId,
    required this.onBack,
    this.passportId = 'passport_demo_fan',
    super.key,
  });

  final String creatorId;
  final String passportId;
  final VoidCallback onBack;

  @override
  State<AudienceInsightsScreen> createState() => _AudienceInsightsScreenState();
}

class _AudienceInsightsScreenState extends State<AudienceInsightsScreen> {
  late final CreatorAudienceApi _audienceApi;

  AudienceInsight? _insight;
  PermissionedInterestData? _permissionedData;
  String? _message;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _audienceApi = resolveCreatorAudienceApi();
    _load();
  }

  Future<void> _load() async {
    final insight = await _audienceApi.getAudienceInsights(
      creatorId: widget.creatorId,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _insight = insight;
      _loading = false;
    });
  }

  Future<void> _createGrantRequest() async {
    await _run(() async {
      final request = await _audienceApi.createDataGrantRequest(
        creatorId: widget.creatorId,
        passportId: widget.passportId,
        fields: const ['interest_categories', 'interest_tokens'],
        purpose: 'Audience fit and creator-owned sponsorship planning',
        retention: 'Demo session only',
        valueExchange: 'Better content fit plus visible fan access receipts.',
        idempotencyKey:
            'p7-studio-request-${DateTime.now().microsecondsSinceEpoch}',
      );
      _message = request.state == ConsentGrantState.denied
          ? 'Request auto-denied by fan category defaults.'
          : 'Grant request sent to the fan data dashboard.';
      await _loadWithoutSetState();
    });
  }

  Future<void> _queryData() async {
    await _run(() async {
      final data = await _audienceApi.queryPermissionedInterestData(
        creatorId: widget.creatorId,
        passportId: widget.passportId,
        purpose: 'Audience planning read',
        idempotencyKey:
            'p7-query-${widget.creatorId}-${DateTime.now().microsecondsSinceEpoch}',
      );
      _permissionedData = data;
      _message = data.fields.isEmpty
          ? 'No permissioned data returned; fan approval is required first.'
          : 'Approved audience fields returned and receipt emitted.';
      await _loadWithoutSetState();
    });
  }

  Future<void> _loadWithoutSetState() async {
    _insight = await _audienceApi.getAudienceInsights(
      creatorId: widget.creatorId,
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    await action();
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _insight == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final insight = _insight!;
    final data = _permissionedData;
    return ListView(
      key: const ValueKey('p7_audience_screen'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Audience',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_message != null)
          DataDashboardRow(
            key: data?.fields.isEmpty ?? false
                ? const ValueKey('p7_no_permission_state')
                : null,
            icon: data?.fields.isEmpty ?? false
                ? Icons.lock_outline_rounded
                : Icons.verified_rounded,
            title: _message!,
            subtitle:
                'Creator tools only show aggregate or fan-approved fields.',
          ),
        if (_message != null) const SizedBox(height: 12),
        KeyedSubtree(
          key: const ValueKey('p7_audience_insights'),
          child: AudiencePanel(
            approvedFanCount: insight.approvedFanCount,
            permissionStatus: insight.permissionStatus,
            topCategories: insight.topCategories,
            permissionedFields: data?.fields ?? const [],
            permissionedValues: data?.values ?? const {},
            onCreateRequest: _busy ? null : _createGrantRequest,
            onQueryData: _busy ? null : _queryData,
          ),
        ),
      ],
    );
  }
}
