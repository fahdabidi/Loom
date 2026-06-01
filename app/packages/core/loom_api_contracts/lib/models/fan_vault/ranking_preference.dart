class RankPreference {
  const RankPreference({
    required this.passportId,
    required this.summaryFirst,
    required this.updatedAt,
  });

  final String passportId;
  final bool summaryFirst;
  final DateTime updatedAt;
}
