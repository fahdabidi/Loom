class CommunityFoundationSeed {
  const CommunityFoundationSeed({
    required this.communityId,
    required this.ownerActorId,
    required this.memberPassportId,
  });

  final String communityId;
  final String ownerActorId;
  final String memberPassportId;
}

const communityFoundationSeed = CommunityFoundationSeed(
  communityId: 'community_book_club',
  ownerActorId: 'owner_ada',
  memberPassportId: 'passport_member_1',
);
