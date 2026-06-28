class CommunityRegistrySeed {
  const CommunityRegistrySeed({
    required this.handle,
    required this.displayName,
    required this.logoAssetId,
    required this.cardImageAssetId,
    required this.extensionId,
    required this.packageId,
  });

  final String handle;
  final String displayName;
  final String logoAssetId;
  final String cardImageAssetId;
  final String extensionId;
  final String packageId;
}

const communityRegistrySeed = CommunityRegistrySeed(
  handle: 'book-club',
  displayName: 'Neighborhood Book Club',
  logoAssetId: 'asset_logo_book_club',
  cardImageAssetId: 'asset_card_book_club',
  extensionId: 'ext_book_club',
  packageId: 'pkg_book_club_1',
);

const communityRegistrySeedCommunityId = 'community_book_club';
