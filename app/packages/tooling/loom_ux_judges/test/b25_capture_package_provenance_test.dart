import 'dart:convert';

import 'package:loom_ux_judges/b25_capture_package_provenance.dart';
import 'package:loom_ux_judges/src/community_package_provenance.dart';
import 'package:test/test.dart';

void main() {
  test(
    'a manifest written today carries a provenance identifier per community',
    () {
      final phaseManifest = <String, dynamic>{
        'phase': 'B15',
        'workflows': <Object?>[
          <String, Object?>{
            'communityId': 'community_camera_club',
            'communityName': 'Camera Club',
            'workflowId': 'photo-walk-rsvp',
          },
          <String, Object?>{
            'communityId': 'community_chess_club',
            'communityName': 'Chess Club',
            'workflowId': 'chess-club-night',
          },
          <String, Object?>{
            'communityId': 'community_platform_social',
            'communityName': 'Member Social Space',
            'appId': 'ext_member_social_space',
            'workflowId': 'platform-messages-entry',
          },
        ],
      };

      recordB25CapturePackageProvenance(
        manifest: phaseManifest,
        provenanceIndex: _provenanceIndex(),
      );

      final written = B25CaptureManifest.fromJson(
        jsonDecode(jsonEncode(phaseManifest)),
      );
      expect(written.communities, hasLength(3));
      expect(
        _communityNamed(written, 'Camera Club').packageProvenance?.entry.sha256,
        'camera-v1',
      );
      expect(
        _communityNamed(written, 'Camera Club').packageProvenance?.packageName,
        'CameraClub.jsonc',
      );
      expect(
        _communityNamed(written, 'Chess Club').packageProvenance?.entry.sha256,
        'chess-v1',
      );
      expect(
        _communityNamed(
          written,
          'Member Social Space',
        ).packageProvenance?.entry.sha256,
        'social-v1',
        reason:
            'The capture appId must join the provenance entry even when '
            'the demo catalog uses different communityId and displayName values.',
      );
    },
  );

  test(
    'unchanged current provenance reports no stale captured communities',
    () {
      final captureManifest = _capturedManifest();
      final comparisons = compareB25CaptureManifestProvenance(
        captureManifest: captureManifest,
        currentProvenance: _currentProvenance(),
      );

      expect(
        comparisons.map((comparison) => comparison.status),
        everyElement(CaptureProvenanceStatus.current),
      );
      expect(
        staleCapturedCommunities(
          captureManifest: captureManifest,
          currentProvenance: _currentProvenance(),
        ),
        isEmpty,
      );
    },
  );

  test(
    'a changed community reports exactly that captured community as stale',
    () {
      final current = _currentProvenance(camera: _entry(sha256: 'camera-v2'));

      final stale = staleCapturedCommunities(
        captureManifest: _capturedManifest(),
        currentProvenance: current,
      );

      expect(stale, hasLength(1));
      expect(stale.single.community.reportName, 'Camera Club');
      expect(stale.single.status, CaptureProvenanceStatus.stale);
    },
  );

  test('a legacy manifest without provenance loads and reports unknown', () {
    final legacy = B25CaptureManifest.fromJson(<Object?>[
      <String, Object?>{
        'communityName': 'Camera Club',
        'slug': 'camera-club',
        'phase': 'B15',
        'runId': 'legacy-camera-1',
        'dir': '/evidence/camera-club',
        'screenshotCount': 12,
      },
    ]);

    final comparison = compareB25CaptureManifestProvenance(
      captureManifest: legacy,
      currentProvenance: _currentProvenance(),
    ).single;

    expect(legacy.communities.single.packageProvenance, isNull);
    expect(legacy.communities.single.phases, <String>['B15']);
    expect(comparison.status, CaptureProvenanceStatus.unknown);
    expect(comparison.status, isNot(CaptureProvenanceStatus.current));
    expect(comparison.status, isNot(CaptureProvenanceStatus.stale));
  });
}

B25CaptureManifest _capturedManifest() {
  final manifest = <String, dynamic>{
    'phase': 'B15',
    'workflows': <Object?>[
      <String, Object?>{
        'communityId': 'community_camera_club',
        'communityName': 'Camera Club',
      },
      <String, Object?>{
        'communityId': 'community_chess_club',
        'communityName': 'Chess Club',
      },
    ],
  };
  recordB25CapturePackageProvenance(
    manifest: manifest,
    provenanceIndex: _provenanceIndex(),
  );
  return B25CaptureManifest.fromJson(manifest);
}

B25CapturedCommunity _communityNamed(
  B25CaptureManifest manifest,
  String communityName,
) => manifest.communities.singleWhere(
  (community) => community.communityName == communityName,
);

CommunityPackageProvenanceIndex _provenanceIndex() =>
    CommunityPackageProvenanceIndex(<CommunityPackageProvenanceRecord>[
      CommunityPackageProvenanceRecord(
        communityId: 'community_camera_club',
        communityName: 'Camera Club',
        extensionId: 'ext_camera_club',
        packageName: 'CameraClub.jsonc',
        entry: _entry(sha256: 'camera-v1'),
      ),
      CommunityPackageProvenanceRecord(
        communityId: 'community_chess_club',
        communityName: 'Chess Club',
        extensionId: 'ext_chess_club',
        packageName: 'ChessClub.jsonc',
        entry: _entry(sha256: 'chess-v1'),
      ),
      CommunityPackageProvenanceRecord(
        communityId: 'community_member_social_space',
        communityName: 'Platform Social',
        extensionId: 'ext_member_social_space',
        packageName: 'MemberSocialSpace.jsonc',
        entry: _entry(sha256: 'social-v1'),
      ),
    ]);

CommunityPackageProvenanceManifest _currentProvenance({
  CommunityPackageProvenanceEntry? camera,
}) => CommunityPackageProvenanceManifest(
  comment: const <String>[],
  algorithm: 'sha-256',
  packages: <String, CommunityPackageProvenanceEntry>{
    'CameraClub.jsonc': camera ?? _entry(sha256: 'camera-v1'),
    'ChessClub.jsonc': _entry(sha256: 'chess-v1'),
  },
);

CommunityPackageProvenanceEntry _entry({required String sha256}) =>
    CommunityPackageProvenanceEntry(
      sha256: sha256,
      bytes: 42,
      authoredBy: communityPackageAuthoringSkill,
      lastCommit: 'abc1234',
      lastCommitDate: '2026-08-31',
      lastCommitSubject: 'test provenance',
    );
