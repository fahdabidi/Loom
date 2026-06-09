class CommunityOpsSeed {
  const CommunityOpsSeed({
    required this.facilityId,
    required this.documentTitle,
    required this.importSourceKind,
    required this.targetProviderId,
    required this.policyVersion,
    required this.packageId,
  });

  final String facilityId;
  final String documentTitle;
  final String importSourceKind;
  final String targetProviderId;
  final String policyVersion;
  final String packageId;
}

const communityOpsSeed = CommunityOpsSeed(
  facilityId: 'clubhouse_room_a',
  documentTitle: 'Community Handbook',
  importSourceKind: 'csv',
  targetProviderId: 'provider_local_demo_next',
  policyVersion: 'policy-2026-06',
  packageId: 'pkg_book_club_1',
);
