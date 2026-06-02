import 'package:flutter/material.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_design_system/loom_design_system.dart';

class DataRightsDashboardScreen extends StatefulWidget {
  const DataRightsDashboardScreen({
    required this.onBack,
    this.passportId = 'passport_demo_fan',
    this.creatorId = 'creator_solar_sarah',
    super.key,
  });

  final VoidCallback onBack;
  final String passportId;
  final String creatorId;

  @override
  State<DataRightsDashboardScreen> createState() =>
      _DataRightsDashboardScreenState();
}

class _DataRightsDashboardScreenState extends State<DataRightsDashboardScreen> {
  late final CreatorAudienceApi _audienceApi;
  late final FanPassportApi _passportApi;
  late final FanVaultApi _vaultApi;

  List<DataGrantRequest> _pendingRequests = const [];
  List<DataAccessReceipt> _receipts = const [];
  DataConsentGrant? _activeGrant;
  CategoryDefault? _categoryDefault;
  AdPreferences? _adPreferences;
  FollowView? _relationshipControl;
  TombstoneRequest? _tombstone;
  String? _message;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _audienceApi = resolveCreatorAudienceApi();
    _passportApi = resolveFanPassportApi();
    _vaultApi = resolveFanVaultApi();
    _load();
  }

  Future<void> _load() async {
    final seed = await _audienceApi.createDataGrantRequest(
      creatorId: widget.creatorId,
      passportId: widget.passportId,
      fields: const ['interest_categories', 'interest_tokens'],
      purpose: 'Audience fit and creator-owned sponsorship planning',
      retention: 'Demo session only',
      valueExchange: 'Show better posts and keep a visible access receipt.',
      idempotencyKey: 'p7-seed-${widget.creatorId}-${widget.passportId}',
    );
    final pending = await _audienceApi.pendingGrantRequests(widget.passportId);
    final receipts = await _audienceApi.dataAccessReceipts(widget.passportId);
    final adPreferences = await _vaultApi.getAdPreferences(widget.passportId);
    if (!mounted) {
      return;
    }
    setState(() {
      _pendingRequests =
          pending.isEmpty && seed.state == ConsentGrantState.pending
          ? [seed]
          : pending;
      _receipts = receipts;
      _adPreferences = adPreferences;
      _loading = false;
    });
  }

  Future<void> _approve(DataGrantRequest request) async {
    await _run(() async {
      final grant = await _passportApi.reviewDataGrantRequest(
        requestId: request.id,
        passportId: widget.passportId,
        state: ConsentGrantState.approved,
        approvedFields: request.fields,
        idempotencyKey: 'p7-approve-${request.id}',
      );
      _activeGrant = grant;
      _message = 'Approved full grant for ${grant.creatorName}.';
      await _refreshLists();
    });
  }

  Future<void> _narrow(DataGrantRequest request) async {
    await _run(() async {
      final grant = await _passportApi.reviewDataGrantRequest(
        requestId: request.id,
        passportId: widget.passportId,
        state: ConsentGrantState.approved,
        approvedFields: const ['interest_categories'],
        idempotencyKey: 'p7-narrow-${request.id}',
      );
      _activeGrant = grant;
      _message = 'Narrowed grant to interest_categories.';
      await _refreshLists();
    });
  }

  Future<void> _deny(DataGrantRequest request) async {
    await _run(() async {
      final grant = await _passportApi.reviewDataGrantRequest(
        requestId: request.id,
        passportId: widget.passportId,
        state: ConsentGrantState.denied,
        approvedFields: const [],
        idempotencyKey: 'p7-deny-${request.id}',
      );
      _activeGrant = grant;
      _message = 'Denied request from ${grant.creatorName}.';
      await _refreshLists();
    });
  }

  Future<void> _revoke() async {
    final grant = _activeGrant;
    if (grant == null) {
      return;
    }
    await _run(() async {
      _activeGrant = await _passportApi.revokeGrant(
        grantId: grant.id,
        idempotencyKey: 'p7-revoke-${grant.id}',
      );
      _message = 'Grant revoked.';
      await _refreshLists();
    });
  }

  Future<void> _setDefault(ConsentGrantState state) async {
    await _run(() async {
      _categoryDefault = await _passportApi.setCategoryDefault(
        passportId: widget.passportId,
        category: 'education',
        state: state,
        idempotencyKey: 'p7-default-${widget.passportId}-${state.name}',
      );
      _message = state == ConsentGrantState.denied
          ? 'Education creator requests now default to denied.'
          : 'Education creator requests now default to approved review.';
    });
  }

  Future<void> _toggleAds(bool value) async {
    await _run(() async {
      _adPreferences = await _vaultApi.putAdPreferences(
        passportId: widget.passportId,
        personalizedAds: value,
        idempotencyKey: 'p7-ads-${widget.passportId}-$value',
      );
      _message = value
          ? 'Personalized ad preference enabled.'
          : 'Personalized ad preference disabled.';
    });
  }

  Future<void> _revokeDirectContact() async {
    await _run(() async {
      _relationshipControl = await _passportApi.revokeDirectContact(
        passportId: widget.passportId,
        creatorId: widget.creatorId,
        idempotencyKey: 'p7-contact-${widget.passportId}-${widget.creatorId}',
      );
      _message = 'Direct contact revoked; relationship visibility is private.';
    });
  }

  Future<void> _requestTombstone() async {
    await _run(() async {
      _tombstone = await _passportApi.requestTombstone(
        passportId: widget.passportId,
        creatorId: widget.creatorId,
        idempotencyKey: 'p7-tombstone-${widget.passportId}-${widget.creatorId}',
      );
      _message = 'Tombstone requested for old relationship data.';
    });
  }

  Future<void> _refreshLists() async {
    _pendingRequests = await _audienceApi.pendingGrantRequests(
      widget.passportId,
    );
    _receipts = await _audienceApi.dataAccessReceipts(widget.passportId);
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final adPreferences = _adPreferences;
    return ListView(
      key: const ValueKey('p7_data_rights_screen'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        Row(
          children: [
            TextButton.icon(
              key: const ValueKey('p7_data_rights_back_button'),
              onPressed: widget.onBack,
              icon: const Icon(Icons.home_rounded),
              label: const Text('Return to Feed'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Data rights',
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
            icon: Icons.verified_rounded,
            title: _message!,
            subtitle: 'Fan-facing consent state updated in the local ledger.',
          ),
        if (_message != null) const SizedBox(height: 12),
        if (_activeGrant != null) ...[
          DataDashboardRow(
            key: const ValueKey('p7_revoke_grant_button'),
            icon: Icons.block_rounded,
            title: 'Revoke creator data access',
            subtitle: _activeGrant!.state == ConsentGrantState.revoked
                ? 'Grant is revoked and future data queries return no fields.'
                : 'Stop future access to the currently approved fields.',
            onTap: _activeGrant!.state == ConsentGrantState.revoked || _busy
                ? null
                : _revoke,
          ),
          const SizedBox(height: 12),
        ],
        DataDashboardRow(
          icon: Icons.ads_click_rounded,
          title: 'Personalized ads',
          subtitle: adPreferences?.personalizedAds ?? true
              ? 'Creator ad decisions can use approved preference signals.'
              : 'Preference signals are disabled for personalized ads.',
          trailing: Switch(
            value: adPreferences?.personalizedAds ?? true,
            onChanged: _busy ? null : _toggleAds,
          ),
        ),
        const SizedBox(height: 12),
        CategoryDefaultControl(
          category: 'Education',
          stateLabel: _categoryDefault == null
              ? 'Ask each time'
              : _stateLabel(_categoryDefault!.state),
          onAllow: () => _setDefault(ConsentGrantState.approved),
          onDeny: () => _setDefault(ConsentGrantState.denied),
        ),
        const SizedBox(height: 16),
        Text(
          'Creator data requests',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        if (_pendingRequests.isEmpty)
          const DataDashboardRow(
            key: ValueKey('p7_no_pending_requests'),
            icon: Icons.inbox_outlined,
            title: 'No pending grant requests',
            subtitle: 'Approved, denied, and revoked grants remain auditable.',
          )
        else
          for (final request in _pendingRequests) ...[
            ConsentGrantCard(
              key: ValueKey('p7_grant_request_${request.id}'),
              creatorName: request.creatorName,
              purpose: request.purpose,
              fields: request.fields,
              valueExchange: request.valueExchange,
              stateLabel: _stateLabel(request.state),
              onApprove: _busy ? null : () => _approve(request),
              onNarrow: _busy ? null : () => _narrow(request),
              onDeny: _busy ? null : () => _deny(request),
            ),
            const SizedBox(height: 12),
          ],
        if (_activeGrant != null) ...[
          const SizedBox(height: 4),
          ConsentGrantCard(
            key: const ValueKey('p7_active_grant_card'),
            creatorName: _activeGrant!.creatorName,
            purpose: _activeGrant!.purpose,
            fields: _activeGrant!.fields,
            valueExchange: _activeGrant!.valueExchange,
            stateLabel: _stateLabel(_activeGrant!.state),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 18),
        DataDashboardRow(
          key: const ValueKey('p7_relationship_private_button'),
          icon: Icons.mark_email_unread_outlined,
          title: 'Creator direct contact',
          subtitle: _relationshipControl == null
              ? 'Revoke direct-contact visibility for Solar Sarah.'
              : 'Direct contact private for ${_relationshipControl!.creatorDisplayName}.',
          onTap: _busy ? null : _revokeDirectContact,
          trailing: IconButton(
            tooltip: 'Revoke direct contact',
            onPressed: _busy ? null : _revokeDirectContact,
            icon: const Icon(Icons.lock_rounded),
          ),
        ),
        const SizedBox(height: 12),
        DataDashboardRow(
          key: const ValueKey('p7_tombstone_button'),
          icon: Icons.delete_sweep_outlined,
          title: 'Relationship tombstone',
          subtitle: _tombstone == null
              ? 'Request a tombstone for stale relationship data.'
              : 'Tombstone recorded for ${_tombstone!.creatorId}.',
          onTap: _busy ? null : _requestTombstone,
          trailing: IconButton(
            tooltip: 'Request tombstone',
            onPressed: _busy ? null : _requestTombstone,
            icon: const Icon(Icons.history_rounded),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Access receipts',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        if (_receipts.isEmpty)
          const DataDashboardRow(
            key: ValueKey('p7_no_data_access_receipts'),
            icon: Icons.receipt_long_outlined,
            title: 'No data accessed yet',
            subtitle: 'A receipt appears only when approved data is queried.',
          )
        else
          for (final receipt in _receipts)
            DataDashboardRow(
              key: ValueKey('p7_data_access_receipt_${receipt.id}'),
              icon: Icons.receipt_long_rounded,
              title: receipt.creatorName,
              subtitle:
                  '${receipt.purpose} · ${receipt.fields.map(_fieldLabel).join(', ')}',
            ),
      ],
    );
  }
}

String _stateLabel(ConsentGrantState state) {
  switch (state) {
    case ConsentGrantState.pending:
      return 'Pending';
    case ConsentGrantState.approved:
      return 'Approved';
    case ConsentGrantState.denied:
      return 'Denied';
    case ConsentGrantState.revoked:
      return 'Revoked';
  }
}

String _fieldLabel(String field) {
  switch (field) {
    case 'interest_categories':
      return 'Interest categories';
    case 'interest_tokens':
      return 'Interest tokens';
    default:
      return field.replaceAll('_', ' ');
  }
}
