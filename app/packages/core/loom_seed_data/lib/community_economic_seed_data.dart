class CommunityEconomicSeed {
  const CommunityEconomicSeed({
    required this.adSlotTopBanner,
    required this.adSlotInStream,
    required this.sponsorName,
    required this.searchTitle,
    required this.searchBody,
  });

  final String adSlotTopBanner;
  final String adSlotInStream;
  final String sponsorName;
  final String searchTitle;
  final String searchBody;
}

const communityEconomicSeed = CommunityEconomicSeed(
  adSlotTopBanner: 'shell.top-banner',
  adSlotInStream: 'stream.inline',
  sponsorName: 'Local Bookseller',
  searchTitle: 'January Book Vote',
  searchBody: 'Members are voting on Parable of the Sower.',
);
