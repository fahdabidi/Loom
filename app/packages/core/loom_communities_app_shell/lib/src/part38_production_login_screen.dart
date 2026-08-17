part of '../loom_communities_app_shell.dart';

enum _ProductionLoginState {
  completingRedirect,
  ready,
  startingRedirect,
  success,
  authError,
  unsupported,
}

/// Signs a person in through the configured real identity provider.
///
/// The screen completes an authorization callback when it first loads, or
/// starts an OAuth2 Authorization Code + PKCE redirect from its primary
/// action. It never uses the test-credentials bypass or the local demo-account
/// API.
class LoomProductionLoginScreen extends StatefulWidget {
  const LoomProductionLoginScreen({
    super.key,
    required this.session,
    this.onLoginSucceeded,
  });

  final LoomAuthSession session;
  final VoidCallback? onLoginSucceeded;

  @override
  State<LoomProductionLoginScreen> createState() =>
      _LoomProductionLoginScreenState();
}

class _LoomProductionLoginScreenState extends State<LoomProductionLoginScreen> {
  _ProductionLoginState _state = _ProductionLoginState.completingRedirect;
  String? _authErrorMessage;

  @override
  void initState() {
    super.initState();
    _completeRedirect();
  }

  Future<void> _completeRedirect() async {
    try {
      final completed = await widget.session.completeInteractiveLogin();
      if (!mounted) return;
      setState(() {
        _state = completed
            ? _ProductionLoginState.success
            : _ProductionLoginState.ready;
      });
      if (completed) widget.onLoginSucceeded?.call();
    } on UnsupportedError {
      _showUnsupportedPlatform();
    } on LoomAuthSessionException catch (error) {
      _showAuthError(error.message);
    } catch (error) {
      _showAuthError(error.toString());
    }
  }

  Future<void> _beginLogin() async {
    setState(() {
      _state = _ProductionLoginState.startingRedirect;
      _authErrorMessage = null;
    });
    try {
      await widget.session.loginInteractively();
    } on UnsupportedError {
      _showUnsupportedPlatform();
    } on LoomAuthSessionException catch (error) {
      _showAuthError(error.message);
    } catch (error) {
      _showAuthError(error.toString());
    }
  }

  void _showUnsupportedPlatform() {
    if (!mounted) return;
    setState(() {
      _state = _ProductionLoginState.unsupported;
      _authErrorMessage = null;
    });
  }

  void _showAuthError(String message) {
    if (!mounted) return;
    setState(() {
      _state = _ProductionLoginState.authError;
      _authErrorMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Secure Loom sign-in')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _icon,
                        size: 56,
                        color: _state == _ProductionLoginState.authError
                            ? colorScheme.error
                            : colorScheme.primary,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _title,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _body,
                        style: textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      if (_state == _ProductionLoginState.completingRedirect ||
                          _state == _ProductionLoginState.startingRedirect) ...[
                        const SizedBox(height: 24),
                        const CircularProgressIndicator(),
                      ],
                      if (_state == _ProductionLoginState.ready ||
                          _state == _ProductionLoginState.authError) ...[
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          key: const ValueKey('production-login-button'),
                          onPressed: _beginLogin,
                          icon: const Icon(Icons.open_in_browser),
                          label: Text(
                            _state == _ProductionLoginState.authError
                                ? 'Try secure sign-in again'
                                : 'Continue to secure sign-in',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData get _icon => switch (_state) {
    _ProductionLoginState.completingRedirect => Icons.verified_user_outlined,
    _ProductionLoginState.ready => Icons.lock_outline,
    _ProductionLoginState.startingRedirect => Icons.open_in_browser,
    _ProductionLoginState.success => Icons.check_circle_outline,
    _ProductionLoginState.authError => Icons.error_outline,
    _ProductionLoginState.unsupported => Icons.devices_other_outlined,
  };

  String get _title => switch (_state) {
    _ProductionLoginState.completingRedirect => 'Finishing secure sign-in',
    _ProductionLoginState.ready => 'Sign in to Loom',
    _ProductionLoginState.startingRedirect => 'Opening secure sign-in',
    _ProductionLoginState.success => 'You’re signed in',
    _ProductionLoginState.authError => 'We couldn’t sign you in',
    _ProductionLoginState.unsupported =>
      'Secure sign-in is not supported on this platform yet',
  };

  String get _body => switch (_state) {
    _ProductionLoginState.completingRedirect =>
      'Checking for a completed response from the identity provider.',
    _ProductionLoginState.ready =>
      'Continue to your organization’s secure sign-in page. You’ll return '
          'here after your identity is confirmed.',
    _ProductionLoginState.startingRedirect =>
      'Taking you to the identity provider. Keep this page open while the '
          'secure redirect begins.',
    _ProductionLoginState.success =>
      'Your secure Loom session is ready. You can return to the community.',
    _ProductionLoginState.authError =>
      _authErrorMessage ?? 'The identity provider could not complete sign-in.',
    _ProductionLoginState.unsupported =>
      'Interactive identity-provider sign-in is currently available only in '
          'Loom on the web.',
  };
}
