part of '../loom_communities_app_shell.dart';

/// Full-screen sign-in / sign-up flow.  Loads the seeded demo accounts and
/// offers a simple form to create a new account for a chosen persona type.
class LoomAuthScreen extends StatefulWidget {
  const LoomAuthScreen({
    super.key,
    required this.authApi,
    required this.communityExtensionId,
    required this.onSignIn,
  });

  final LoomAuthApi authApi;
  final String communityExtensionId;
  final VoidCallback onSignIn;

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-in failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.people_alt_outlined, size: 64, color: colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  'Welcome to Loom',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
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
                const SizedBox(height: 32),
                if (_loading)
                  const CircularProgressIndicator()
                else if (_error != null)
                  Column(
                    children: [
                      Text(_error!, style: TextStyle(color: colorScheme.error)),
                      const SizedBox(height: 12),
                      ElevatedButton(
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
                    onSignIn: _signIn,
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  _SignUpForm(
                    authApi: widget.authApi,
                    communityExtensionId: widget.communityExtensionId,
                    onSignedUp: widget.onSignIn,
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
  const _AccountList({required this.accounts, required this.onSignIn});

  final List<LoomAccount> accounts;
  final Future<void> Function(String accountId) onSignIn;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<LoomAccount>>{};
    for (final account in accounts) {
      grouped.putIfAbsent(account.personaTypeId, () => []).add(account);
    }
    final sortedGroups = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

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
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          for (final account in group.value)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(account.displayName[0]),
                ),
                title: Text(account.displayName),
                subtitle: Text('ID: ${account.accountId}'),
                trailing: const Icon(Icons.login),
                onTap: () => onSignIn(account.accountId),
              ),
            ),
        ],
      ],
    );
  }

  String _personaLabelFor(String typeId) {
    switch (typeId) {
      case 'tabletop-organizer':
        return 'Organizers';
      case 'tabletop-member':
        return 'Members';
      default:
        return typeId;
    }
  }
}

class _SignUpForm extends StatefulWidget {
  const _SignUpForm({
    required this.authApi,
    required this.communityExtensionId,
    required this.onSignedUp,
  });

  final LoomAuthApi authApi;
  final String communityExtensionId;
  final VoidCallback onSignedUp;

  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  String _selectedType = 'tabletop-member';
  bool _submitting = false;

  final _availableTypes = const ['tabletop-member', 'tabletop-organizer'];

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await widget.authApi.signUp(
        communityExtensionId: widget.communityExtensionId,
        displayName: _displayNameController.text.trim(),
        personaTypeId: _selectedType,
      );
      widget.onSignedUp();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-up failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Create New Account',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextFormField(
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
            initialValue: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Persona type',
              border: OutlineInputBorder(),
            ),
            items: _availableTypes.map((type) {
              return DropdownMenuItem(value: type, child: Text(type));
            }).toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedType = value);
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: const Icon(Icons.person_add),
            label: Text(_submitting ? 'Creating...' : 'Sign Up'),
          ),
        ],
      ),
    );
  }
}
