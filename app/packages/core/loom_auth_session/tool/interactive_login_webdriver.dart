import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:webdriver/async_io.dart' hide TimeoutException;

const _appUri = 'http://localhost:7357/';
const _webDriverUri = 'http://localhost:9515/';

Future<void> main() async {
  final driver = await createDriver(
    uri: Uri.parse(_webDriverUri),
    desired: {
      'browserName': 'chrome',
      'goog:chromeOptions': {
        'args': [
          '--headless=new',
          '--no-sandbox',
          '--disable-dev-shm-usage',
          '--window-size=1280,900',
        ],
      },
    },
    spec: WebDriverSpec.W3c,
  );

  try {
    await driver.get(_appUri);
    final trigger = await _waitForElement(
      driver,
      const By.cssSelector('[flt-semantics-identifier="loom-login-trigger"]'),
    );
    await trigger.click();

    await _waitUntil(() async {
      final uri = Uri.tryParse(await driver.currentUrl);
      return uri?.host == '192.168.56.10' &&
          uri!.path.contains('/realms/loom/');
    }, description: 'browser navigation to the hosted Keycloak login page');

    final username = await _keycloakElement(driver, 'username');
    final password = await _keycloakElement(driver, 'password');
    final submit = await _keycloakElement(driver, 'kc-login');
    stdout.writeln(
      'Confirmed rendered Keycloak selectors: '
      '#username, #password, #kc-login',
    );

    await username.sendKeys('test-fan-alice');
    await password.sendKeys('LoomTest123!');
    await submit.click();

    await _waitUntil(
      () async => (await driver.currentUrl).startsWith(_appUri),
      description: 'Keycloak redirect back to the Flutter Web harness',
    );
    final accessToken = await _waitForAccessToken(driver);
    final claims = _decodeJwtClaims(accessToken);
    if (claims['fanId'] != 'fan-test-alice') {
      throw StateError(
        'Expected fanId fan-test-alice, got ${claims['fanId']}.',
      );
    }
    stdout.writeln(
      'PASS: authorization-code + PKCE access token fanId='
      '${claims['fanId']}',
    );
  } finally {
    await driver.quit();
  }
}

Future<WebElement> _keycloakElement(WebDriver driver, String id) async {
  try {
    return await _waitForElement(driver, By.id(id));
  } on Object {
    stderr.writeln(
      'Rendered Keycloak DOM did not contain #$id. Page source follows:',
    );
    stderr.writeln(await driver.pageSource);
    rethrow;
  }
}

Future<WebElement> _waitForElement(
  WebDriver driver,
  By selector, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  WebElement? found;
  await _waitUntil(
    () async {
      try {
        found = await driver.findElement(selector);
        return true;
      } on NoSuchElementException {
        return false;
      }
    },
    description: 'element $selector',
    timeout: timeout,
  );
  return found!;
}

Future<String> _waitForAccessToken(WebDriver driver) async {
  String? token;
  await _waitUntil(() async {
    final value = await driver.execute(
      'return document.body.getAttribute("data-loom-access-token");',
      const [],
    );
    if (value is String && value.isNotEmpty) {
      token = value;
      return true;
    }
    return false;
  }, description: 'persisted access token from the returned app');
  return token!;
}

Future<void> _waitUntil(
  Future<bool> Function() predicate, {
  required String description,
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (await predicate()) return;
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
  throw TimeoutException('Timed out waiting for $description.', timeout);
}

Map<String, dynamic> _decodeJwtClaims(String token) {
  final parts = token.split('.');
  if (parts.length != 3) {
    throw const FormatException('Keycloak access token is not a compact JWT');
  }
  final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
  final decoded = jsonDecode(payload);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Keycloak JWT claims are not a JSON object');
  }
  return decoded;
}
