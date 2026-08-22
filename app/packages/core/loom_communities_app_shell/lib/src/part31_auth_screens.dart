part of '../loom_communities_app_shell.dart';

/// Full-screen sign-in / sign-up flow.  Loads the seeded demo accounts and
/// offers a simple form to create a new account for a chosen persona type.
class LoomAuthScreen extends StatefulWidget {
  const LoomAuthScreen({
    super.key,
    required this.authApi,
    required this.communityExtensionId,
    required this.experience,
    required this.onSignIn,
    this.signedInAccountId,
  });

  final LoomAuthApi authApi;
  final String communityExtensionId;
  final LoomExperienceDefinition experience;
  final VoidCallback onSignIn;

  /// The account already signed in for this community, if any, resolved by
  /// the caller before this screen was reached (e.g. before pushing this as
  /// a new route, where an `ActiveIdentityScope` ancestor may not be in
  /// scope). Used by `_AccountList` to badge that account as "Signed in"
  /// even when no such ancestor is available.
  final String? signedInAccountId;

  @override
  State<LoomAuthScreen> createState() => _LoomAuthScreenState();
}

class _LoomAuthScreenState extends State<LoomAuthScreen> {
  List<LoomAccount>? _accounts;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await widget.authApi.listAccounts(
        communityExtensionId: widget.communityExtensionId,
      );
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _signIn(String accountId) async {
    try {
      await widget.authApi.signIn(accountId: accountId);
      widget.onSignIn();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sign-in failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final accent = Color(widget.experience.accentColor);
    final headerSurface = Color.alphaBlend(
      accent.withValues(alpha: 0.08),
      Colors.white,
    );
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: headerSurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.people_alt_outlined, size: 56, color: accent),
                      const SizedBox(height: 12),
                      Text(
                        'Welcome to Loom',
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose an account below or create a new one.',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                if (_loading)
                  const CircularProgressIndicator()
                else if (_error != null)
                  Column(
                    children: [
                      Text(_error!, style: TextStyle(color: colorScheme.error)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _loading = true;
                            _error = null;
                          });
                          _loadAccounts();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  )
                else ...[
                  _AccountList(
                    accounts: _accounts!,
                    experience: widget.experience,
                    onSignIn: _signIn,
                    signedInAccountId: widget.signedInAccountId,
                  ),
                  _PendingAndInvitesSurface(
                    authApi: widget.authApi,
                    communityExtensionId: widget.communityExtensionId,
                    experience: widget.experience,
                    accounts: _accounts!,
                    onAccountsChanged: _loadAccounts,
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  _SignUpForm(
                    authApi: widget.authApi,
                    communityExtensionId: widget.communityExtensionId,
                    experience: widget.experience,
                    onSignedUp: widget.onSignIn,
                    onAccountsChanged: _loadAccounts,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountList extends StatelessWidget {
  const _AccountList({
    required this.accounts,
    required this.experience,
    required this.onSignIn,
    this.signedInAccountId,
  });

  final List<LoomAccount> accounts;
  final LoomExperienceDefinition experience;
  final Future<void> Function(String accountId) onSignIn;

  /// The active account id, if known. Prefer this explicit value (resolved
  /// by the caller) over an `ActiveIdentityScope` lookup, since this widget
  /// is sometimes pushed onto a new route (e.g. "sign in as a specific
  /// person") that isn't a structural descendant of any
  /// `ActiveIdentityScope` ancestor.
  final String? signedInAccountId;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<LoomAccount>>{};
    for (final account in accounts) {
      grouped.putIfAbsent(account.roleId, () => []).add(account);
    }
    final sortedGroups = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final signedInAccountId =
        this.signedInAccountId ??
        ActiveIdentityScope.maybeOf(
          context,
        )?.authApi.currentSession?.account.accountId;

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final accent = Color(experience.accentColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Existing Accounts',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        for (final group in sortedGroups) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              _personaLabelFor(group.key),
              style: textTheme.labelSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          for (final account in group.value)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              color: account.status == MembershipStatus.active
                  ? null
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    account.displayName.isEmpty
                        ? '?'
                        : account.displayName[0].toUpperCase(),
                  ),
                ),
                title: Text(account.displayName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ID: ${account.accountId}'),
                    if (account.status != MembershipStatus.active)
                      Text(
                        _membershipStatusLabel(account.status),
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.65),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                trailing:
                    signedInAccountId != null &&
                        account.accountId == signedInAccountId
                    ? Chip(
                        label: const Text('Signed in'),
                        labelStyle: const TextStyle(fontSize: 13),
                        visualDensity: VisualDensity.compact,
                        avatar: Icon(
                          Icons.check_circle,
                          size: 15,
                          color: colorScheme.primary,
                        ),
                      )
                    : account.status == MembershipStatus.active
                    ? const Icon(Icons.login)
                    : Chip(
                        label: Text(_membershipStatusLabel(account.status)),
                        avatar: const Icon(Icons.hourglass_empty, size: 16),
                      ),
                onTap: account.status == MembershipStatus.active
                    ? () => onSignIn(account.accountId)
                    : null,
              ),
            ),
        ],
      ],
    );
  }

  String _personaLabelFor(String typeId) {
    final persona = personasForExtensionId(
      experience.extensionId,
      experience: experience,
    ).where((candidate) => candidate.roleId == typeId).firstOrNull;
    if (persona == null) return typeId;
    return '${persona.label} (${persona.roleLabel})';
  }
}

String _membershipStatusLabel(MembershipStatus status) {
  return switch (status) {
    MembershipStatus.active => 'Active',
    MembershipStatus.pendingApproval => 'Pending approval',
    MembershipStatus.invited => 'Invited',
  };
}

/// Membership administration stays in the auth flow so an admin can review
/// newly created accounts before handing off to the community experience.
/// Its visibility intentionally uses the same capability signal as the
/// generated Admin tab.
class _PendingAndInvitesSurface extends StatefulWidget {
  const _PendingAndInvitesSurface({
    required this.authApi,
    required this.communityExtensionId,
    required this.experience,
    required this.accounts,
    required this.onAccountsChanged,
  });

  final LoomAuthApi authApi;
  final String communityExtensionId;
  final LoomExperienceDefinition experience;
  final List<LoomAccount> accounts;
  final Future<void> Function() onAccountsChanged;

  @override
  State<_PendingAndInvitesSurface> createState() =>
      _PendingAndInvitesSurfaceState();
}

class _PendingAndInvitesSurfaceState extends State<_PendingAndInvitesSurface> {
  String? _selectedInviteRoleId;
  String? _issuedCode;
  String? _error;
  bool _issuing = false;

  List<LoomPersonaDefinition> get _invitePersonas =>
      personasForExtensionId(
            widget.experience.extensionId,
            experience: widget.experience,
          )
          .where(
            (persona) =>
                persona.accessMode == LoomPersonaAccessMode.requiresInvite,
          )
          .toList();

  bool get _canManageMemberships {
    final account = widget.authApi.currentSession?.account;
    return account != null &&
        account.status == MembershipStatus.active &&
        _personaCanAdministerAnyWorkflow(widget.experience, account.roleId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedInviteRoleId ??= _invitePersonas.firstOrNull?.roleId;
  }

  Future<void> _approve(LoomAccount account) async {
    try {
      await widget.authApi.approveAccount(accountId: account.accountId);
      await widget.onAccountsChanged();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Approval failed: $error')));
    }
  }

  Future<void> _issueInvite() async {
    final roleId = _selectedInviteRoleId;
    final issuer = widget.authApi.currentSession?.account.accountId;
    if (roleId == null || issuer == null) return;
    setState(() {
      _issuing = true;
      _error = null;
      _issuedCode = null;
    });
    try {
      final invite = await widget.authApi.issueInvite(
        roleId: roleId,
        issuedByAccountId: issuer,
      );
      if (!mounted) return;
      setState(() => _issuedCode = invite.code);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _issuing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_canManageMemberships) return const SizedBox.shrink();

    final pendingAccounts = widget.accounts
        .where((account) => account.status == MembershipStatus.pendingApproval)
        .toList();
    final invitePersonas = _invitePersonas;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      key: const ValueKey('pending-invites-surface'),
      margin: const EdgeInsets.only(top: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pending & Invites',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Review new membership requests and create invite codes for invite-only personas.',
            ),
            const SizedBox(height: 14),
            Text(
              'Pending approval',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            if (pendingAccounts.isEmpty)
              const Text('No accounts are waiting for approval.')
            else
              for (final account in pendingAccounts)
                ListTile(
                  key: ValueKey('pending-account-${account.accountId}'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.hourglass_top),
                  title: Text(account.displayName),
                  subtitle: Text(
                    '${_membershipStatusLabel(account.status)} · ${account.accountId}',
                  ),
                  trailing: TextButton.icon(
                    key: ValueKey('approve-account-${account.accountId}'),
                    onPressed: () => _approve(account),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                  ),
                ),
            const Divider(height: 28),
            Text(
              'Invite-only personas',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (invitePersonas.isEmpty)
              const Text('No invite-only personas are declared.')
            else ...[
              DropdownButtonFormField<String>(
                key: const ValueKey('issue-invite-persona-dropdown'),
                initialValue: _selectedInviteRoleId,
                decoration: const InputDecoration(
                  labelText: 'Persona type',
                  border: OutlineInputBorder(),
                ),
                items: invitePersonas.map((persona) {
                  return DropdownMenuItem(
                    key: ValueKey('issue-invite-persona-${persona.roleId}'),
                    value: persona.roleId,
                    child: Text(persona.label),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedInviteRoleId = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const ValueKey('issue-invite-button'),
                onPressed: _issuing ? null : _issueInvite,
                icon: const Icon(Icons.mail_outline),
                label: Text(_issuing ? 'Creating code...' : 'Issue invite'),
              ),
              if (_issuedCode != null) ...[
                const SizedBox(height: 12),
                DecoratedBox(
                  key: const ValueKey('issued-invite-code'),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Share this invite code'),
                        const SizedBox(height: 4),
                        SelectableText(
                          _issuedCode!,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SignUpForm extends StatefulWidget {
  const _SignUpForm({
    required this.authApi,
    required this.communityExtensionId,
    required this.experience,
    required this.onSignedUp,
    required this.onAccountsChanged,
  });

  final LoomAuthApi authApi;
  final String communityExtensionId;
  final LoomExperienceDefinition experience;
  final VoidCallback onSignedUp;
  final Future<void> Function() onAccountsChanged;

  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _inviteFormKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _inviteDisplayNameController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  late final List<LoomPersonaDefinition> _personas;
  late final List<LoomPersonaDefinition> _openPersonas;
  late final List<LoomPersonaDefinition> _invitePersonas;
  late String? _selectedType;
  late String? _selectedInviteType;
  bool _submitting = false;
  bool _redeeming = false;

  @override
  void initState() {
    super.initState();
    _personas = personasForExtensionId(
      widget.experience.extensionId,
      experience: widget.experience,
    );
    _openPersonas = _personas
        .where(
          (persona) =>
              persona.accessMode != LoomPersonaAccessMode.requiresInvite,
        )
        .toList();
    _invitePersonas = _personas
        .where(
          (persona) =>
              persona.accessMode == LoomPersonaAccessMode.requiresInvite,
        )
        .toList();
    _selectedType = _openPersonas.isEmpty ? null : _openPersonas.first.roleId;
    _selectedInviteType = _invitePersonas.isEmpty
        ? null
        : _invitePersonas.first.roleId;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _inviteDisplayNameController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final selectedType = _selectedType;
    if (selectedType == null) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final result = await widget.authApi.signUp(
        communityExtensionId: widget.communityExtensionId,
        displayName: _displayNameController.text.trim(),
        roleId: selectedType,
      );
      if (result is LoomPendingApprovalSignUpResult) {
        await widget.onAccountsChanged();
        if (!mounted) return;
        _displayNameController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your account was created and is waiting for community approval.',
            ),
          ),
        );
      } else {
        widget.onSignedUp();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sign-up failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _redeemInvite() async {
    if (!_inviteFormKey.currentState!.validate()) return;
    setState(() => _redeeming = true);
    try {
      await widget.authApi.redeemInvite(
        code: _inviteCodeController.text.trim(),
        displayName: _inviteDisplayNameController.text.trim(),
      );
      widget.onSignedUp();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Invite redemption failed: $e')));
    } finally {
      if (mounted) setState(() => _redeeming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accent = Color(widget.experience.accentColor);
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: accent,
      foregroundColor: Colors.white,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_openPersonas.isNotEmpty)
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create New Account',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('open-signup-display-name'),
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    hintText: 'e.g. Priya N.',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a display name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const ValueKey('open-signup-persona-dropdown'),
                  initialValue: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Persona type',
                    border: OutlineInputBorder(),
                  ),
                  items: _openPersonas.map((persona) {
                    return DropdownMenuItem(
                      key: ValueKey('open-signup-persona-${persona.roleId}'),
                      value: persona.roleId,
                      child: Text(persona.label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedType = value);
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  key: const ValueKey('open-signup-submit'),
                  style: buttonStyle,
                  onPressed: _submitting ? null : _submit,
                  icon: const Icon(Icons.person_add),
                  label: Text(_submitting ? 'Creating...' : 'Sign Up'),
                ),
              ],
            ),
          ),
        if (_openPersonas.isNotEmpty && _invitePersonas.isNotEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(),
          ),
        if (_invitePersonas.isNotEmpty) _buildInviteRedemption(textTheme),
        if (_openPersonas.isEmpty && _invitePersonas.isEmpty)
          const Text('No sign-up personas are available for this community.'),
      ],
    );
  }

  Widget _buildInviteRedemption(TextTheme textTheme) {
    final accent = Color(widget.experience.accentColor);
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: accent,
      foregroundColor: Colors.white,
    );
    return Form(
      key: _inviteFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Redeem an invite',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'This community uses invite-only membership for the persona selected below.',
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: const ValueKey('invite-redeem-persona-dropdown'),
            initialValue: _selectedInviteType,
            decoration: const InputDecoration(
              labelText: 'Invite-only persona',
              border: OutlineInputBorder(),
            ),
            items: _invitePersonas.map((persona) {
              return DropdownMenuItem(
                key: ValueKey('invite-redeem-persona-${persona.roleId}'),
                value: persona.roleId,
                child: Text(persona.label),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedInviteType = value);
              }
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('invite-redeem-display-name'),
            controller: _inviteDisplayNameController,
            decoration: const InputDecoration(
              labelText: 'Display name',
              hintText: 'e.g. Priya N.',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a display name';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('invite-code-field'),
            controller: _inviteCodeController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Invite code',
              hintText: 'LOOM-ABC234',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter an invite code';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            key: const ValueKey('redeem-invite-submit'),
            style: buttonStyle,
            onPressed: _redeeming ? null : _redeemInvite,
            icon: const Icon(Icons.redeem),
            label: Text(_redeeming ? 'Redeeming...' : 'Redeem invite'),
          ),
        ],
      ),
    );
  }
}
