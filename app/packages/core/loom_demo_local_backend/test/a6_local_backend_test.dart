import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_extension_package/loom_extension_package.dart';
import 'package:test/test.dart';

void main() {
  group('A6 local in-app backend validation tests', () {
    test('vt_demo-app_empty-community-state', () {
      final backend = LocalInAppBackend();

      expect(backend.listCommunities(), isEmpty);
    });

    test('vt_demo-app_local-file-load-extension', () {
      final backend = LocalInAppBackend()..loadExtensionPackage(_extension());

      expect(backend.isExtensionLoaded('ext_book_club'), isTrue);
    });

    test('vt_fake-backend_local-package-pair-validation', () {
      final backend = LocalInAppBackend();

      final invalid = backend.validateLocalPackagePair(
        extensionPackagePath: '/emulator/Download/book-club.zip',
        initializationPackagePath: '/emulator/Download/book-club.json',
      );
      final valid = backend.validateLocalPackagePair(
        extensionPackagePath: '/emulator/Download/book-club.loom-extension.zip',
        initializationPackagePath: '/emulator/Download/book-club.loom-init.zip',
      );

      expect(invalid.isValid, isFalse);
      expect(
        invalid.errors,
        contains('Extension package must end with .loom-extension.zip.'),
      );
      expect(
        invalid.errors,
        contains('Initialization package must end with .loom-init.zip.'),
      );
      expect(valid.isValid, isTrue);
    });

    test('vt_fake-backend_parse-arbitrary-local-package-pair', () {
      final backend = LocalInAppBackend();
      final fixture = _writeArbitraryPackagePair();

      final plan = backend.parseLocalPackagePair(
        extensionPackagePath: fixture.extensionPath,
        initializationPackagePath: fixture.initializationPath,
      );

      expect(plan.extensionPackage.extensionId, 'ext_garden_club');
      expect(plan.extensionPackage.displayName, 'Garden Club');
      expect(plan.extensionPackage.assetIds, contains('asset_card_garden'));
      expect(plan.initializationPackage.communityId, 'community_garden_club');
      expect(plan.initializationPackage.communityName, 'Garden Club');
      expect(plan.initializationPackage.cardAssetId, 'asset_card_garden');
      expect(plan.accentColor, '#3A7D44');
      expect(plan.logoAssetId, 'asset_logo_garden');
      expect(plan.heroImageAssetId, 'asset_hero_garden');
      expect(plan.appShellConfiguration['tabs'], isA<List<Object?>>());
    });

    test('vt_fake-backend_import-arbitrary-package-pair', () {
      final backend = LocalInAppBackend();
      final fixture = _writeArbitraryPackagePair();

      final report = backend.installLocalPackagePairFromFiles(
        extensionPackagePath: fixture.extensionPath,
        initializationPackagePath: fixture.initializationPath,
      );

      expect(report.created, isTrue);
      expect(report.community.communityId, 'community_garden_club');
      expect(report.community.displayName, 'Garden Club');
      expect(report.community.extensionId, 'ext_garden_club');
      expect(report.community.cardImageAssetId, 'asset_card_garden');
      expect(report.community.logoAssetId, 'asset_logo_garden');
      expect(report.community.heroImageAssetId, 'asset_hero_garden');
      expect(report.community.accentColor, '#3A7D44');
      expect(
        report.community.appShellConfiguration['tabs'],
        isA<List<Object?>>(),
      );
      expect(backend.isExtensionLoaded('ext_garden_club'), isTrue);
      expect(report.importedSeedFiles, contains('seed/events.json'));
    });

    test('vt_fake-backend_parse-arbitrary-zip-package-pair', () {
      final backend = LocalInAppBackend();
      final fixture = _writeArbitraryZipPackagePair();

      final report = backend.installLocalPackagePairFromFiles(
        extensionPackagePath: fixture.extensionPath,
        initializationPackagePath: fixture.initializationPath,
      );

      expect(report.created, isTrue);
      expect(report.community.communityId, 'community_camera_club');
      expect(report.community.displayName, 'Camera Club');
      expect(report.community.extensionId, 'ext_camera_club');
      expect(report.community.cardImageAssetId, 'seed/assets/camera-card.png');
      expect(report.community.logoAssetId, 'seed/assets/camera-logo.png');
      expect(report.community.heroImageAssetId, 'seed/assets/camera-hero.png');
      expect(backend.isExtensionLoaded('ext_camera_club'), isTrue);
    });

    test('vt_fake-backend_import-init-package', () {
      final backend = LocalInAppBackend()..loadExtensionPackage(_extension());
      final report = backend.importInitializationPackage(_initialization());

      expect(report.created, isTrue);
      expect(report.community.cardImageAssetId, 'asset_card_book_club');
    });

    test('vt_fake-backend_import-idempotent', () {
      final backend = LocalInAppBackend()..loadExtensionPackage(_extension());
      final first = backend.importInitializationPackage(_initialization());
      final second = backend.importInitializationPackage(_initialization());

      expect(first.created, isTrue);
      expect(second.created, isFalse);
      expect(backend.listCommunities(), hasLength(1));
    });

    test('vt_local-store_persist-reload', () {
      final backend = LocalInAppBackend()..loadExtensionPackage(_extension());
      backend.importInitializationPackage(_initialization());
      final reloaded = LocalInAppBackend(snapshot: backend.snapshot());

      expect(
        reloaded.listCommunities().single.communityId,
        'community_book_club',
      );
      expect(reloaded.isExtensionLoaded('ext_book_club'), isTrue);
    });

    test('ct_initialization-package__fake-backend_import', () {
      final backend = LocalInAppBackend()..loadExtensionPackage(_extension());
      final report = backend.importInitializationPackage(_initialization());

      expect(report.importedSeedFiles, contains('seed/community.json'));
    });

    test('ct_initialization-package__fake-backend_branding-import', () {
      final backend = LocalInAppBackend()..loadExtensionPackage(_extension());
      final report = backend.importInitializationPackage(
        _initialization(),
        logoAssetId: 'asset_logo_book_club',
        heroImageAssetId: 'asset_hero_book_club',
      );

      expect(report.community.logoAssetId, 'asset_logo_book_club');
      expect(report.community.heroImageAssetId, 'asset_hero_book_club');
    });

    test('ct_extension-package__demo-loader_validate-load', () {
      final backend = LocalInAppBackend()..loadExtensionPackage(_extension());

      expect(backend.isExtensionLoaded('ext_book_club'), isTrue);
    });

    test('ct_local-backend__community-card_branding-props', () {
      final backend = LocalInAppBackend()..loadExtensionPackage(_extension());
      final report = backend.importInitializationPackage(
        _initialization(),
        logoAssetId: 'asset_logo_book_club',
        heroImageAssetId: 'asset_hero_book_club',
      );

      expect(report.community.displayName, 'Neighborhood Book Club');
      expect(report.community.cardImageAssetId, 'asset_card_book_club');
      expect(report.community.accentColor, '#246B62');
    });
  });
}

_PackagePairFixture _writeArbitraryZipPackagePair() {
  final tempDir = Directory.systemTemp.createTempSync('loom_arbitrary_zip_');
  final extensionFile = File('${tempDir.path}/camera-club.loom-extension.zip');
  final initializationFile = File('${tempDir.path}/camera-club.loom-init.zip');
  _writeStoredZip(
    extensionFile,
    LoomExtensionPackageFormat.extensionManifestFile,
    jsonEncode({
      'schemaVersion': 1,
      'mode': 'local-demo',
      'extensionId': 'ext_camera_club',
      'displayName': 'Camera Club',
      'version': '1.0.0',
      'permissions': ['content.publish', 'events.write'],
      'assets': {
        'cardImage': 'assets/brand/camera-card.png',
        'logo': 'assets/brand/camera-logo.png',
      },
    }),
  );
  _writeStoredZip(
    initializationFile,
    LoomExtensionPackageFormat.initializationManifestFile,
    jsonEncode({
      'schemaVersion': 1,
      'communityId': 'community_camera_club',
      'displayName': 'Camera Club',
      'extensionId': 'ext_camera_club',
      'seedDataFiles': ['seed/community.json'],
      'branding': {
        'cardImage': 'seed/assets/camera-card.png',
        'logo': 'seed/assets/camera-logo.png',
        'heroImage': 'seed/assets/camera-hero.png',
        'accentColor': '#465C7B',
      },
    }),
  );
  return _PackagePairFixture(
    extensionPath: extensionFile.path,
    initializationPath: initializationFile.path,
  );
}

void _writeStoredZip(File file, String entryName, String content) {
  final nameBytes = utf8.encode(entryName);
  final contentBytes = utf8.encode(content);
  final crc = _crc32(contentBytes);
  final bytes = BytesBuilder();

  _writeU32(bytes, 0x04034b50);
  _writeU16(bytes, 20);
  _writeU16(bytes, 0);
  _writeU16(bytes, 0);
  _writeU16(bytes, 0);
  _writeU16(bytes, 0);
  _writeU32(bytes, crc);
  _writeU32(bytes, contentBytes.length);
  _writeU32(bytes, contentBytes.length);
  _writeU16(bytes, nameBytes.length);
  _writeU16(bytes, 0);
  bytes.add(nameBytes);
  bytes.add(contentBytes);

  final centralDirectoryOffset = bytes.length;
  _writeU32(bytes, 0x02014b50);
  _writeU16(bytes, 20);
  _writeU16(bytes, 20);
  _writeU16(bytes, 0);
  _writeU16(bytes, 0);
  _writeU16(bytes, 0);
  _writeU16(bytes, 0);
  _writeU32(bytes, crc);
  _writeU32(bytes, contentBytes.length);
  _writeU32(bytes, contentBytes.length);
  _writeU16(bytes, nameBytes.length);
  _writeU16(bytes, 0);
  _writeU16(bytes, 0);
  _writeU16(bytes, 0);
  _writeU16(bytes, 0);
  _writeU32(bytes, 0);
  _writeU32(bytes, 0);
  bytes.add(nameBytes);

  final centralDirectorySize = bytes.length - centralDirectoryOffset;
  _writeU32(bytes, 0x06054b50);
  _writeU16(bytes, 0);
  _writeU16(bytes, 0);
  _writeU16(bytes, 1);
  _writeU16(bytes, 1);
  _writeU32(bytes, centralDirectorySize);
  _writeU32(bytes, centralDirectoryOffset);
  _writeU16(bytes, 0);

  file.writeAsBytesSync(bytes.takeBytes());
}

void _writeU16(BytesBuilder bytes, int value) {
  bytes.add(
    Uint8List(2)..buffer.asByteData().setUint16(0, value, Endian.little),
  );
}

void _writeU32(BytesBuilder bytes, int value) {
  bytes.add(
    Uint8List(4)..buffer.asByteData().setUint32(0, value, Endian.little),
  );
}

int _crc32(List<int> bytes) {
  var crc = 0xffffffff;
  for (final byte in bytes) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit += 1) {
      crc = (crc & 1) == 1 ? 0xedb88320 ^ (crc >> 1) : crc >> 1;
    }
  }
  return (crc ^ 0xffffffff) & 0xffffffff;
}

_PackagePairFixture _writeArbitraryPackagePair() {
  final tempDir = Directory.systemTemp.createTempSync('loom_arbitrary_');
  final extensionFile = File('${tempDir.path}/garden-club.loom-extension.zip');
  final initializationFile = File('${tempDir.path}/garden-club.loom-init.zip');
  extensionFile.writeAsStringSync(
    jsonEncode({
      'schemaVersion': 1,
      'mode': 'local-demo',
      'extensionId': 'ext_garden_club',
      'displayName': 'Garden Club',
      'version': '1.0.0',
      'permissions': ['content.publish', 'events.write'],
      'assets': [
        {
          'assetId': 'asset_card_garden',
          'kind': 'cardImage',
          'path': 'assets/card.png',
        },
        {
          'assetId': 'asset_logo_garden',
          'kind': 'logo',
          'path': 'assets/logo.png',
        },
      ],
    }),
  );
  initializationFile.writeAsStringSync(
    jsonEncode({
      'schemaVersion': 1,
      'communityId': 'community_garden_club',
      'communityName': 'Garden Club',
      'extensionId': 'ext_garden_club',
      'seedDataFiles': ['seed/community.json', 'seed/events.json'],
      'cardAssetId': 'asset_card_garden',
      'logoAssetId': 'asset_logo_garden',
      'heroImageAssetId': 'asset_hero_garden',
      'accentColor': '#3A7D44',
      'appShell': {
        'tabs': [
          {
            'tabId': 'calendar',
            'label': 'Garden calendar',
            'icon': 'calendar',
            'rendererContractId': 'calendar-agenda-event-detail',
            'sectionTitles': ['Upcoming events'],
            'pinningPolicy': 'pin-first-critical-surface',
            'pinningPolicyRationale':
                'The next garden event is the most time-sensitive item.',
          },
        ],
      },
    }),
  );
  return _PackagePairFixture(
    extensionPath: extensionFile.path,
    initializationPath: initializationFile.path,
  );
}

class _PackagePairFixture {
  const _PackagePairFixture({
    required this.extensionPath,
    required this.initializationPath,
  });

  final String extensionPath;
  final String initializationPath;
}

LoomExtensionPackageSummary _extension() {
  return const LoomExtensionPackageSummary(
    extensionId: 'ext_book_club',
    displayName: 'Book Club',
    version: '1.0.0',
    permissions: ['content.publish'],
    assetIds: ['asset_card_book_club'],
  );
}

LoomInitializationPackageSummary _initialization() {
  return const LoomInitializationPackageSummary(
    communityId: 'community_book_club',
    communityName: 'Neighborhood Book Club',
    extensionId: 'ext_book_club',
    seedDataFiles: ['seed/community.json'],
    cardAssetId: 'asset_card_book_club',
  );
}
