@TestOn('browser')
import 'package:loom_auth_session/src/interactive_login_platform.dart';
import 'package:test/test.dart';

void main() {
  test('js_interop selects the existing web interactive login platform', () {
    expect(interactiveLoginPlatformKind, 'web');
  });
}
