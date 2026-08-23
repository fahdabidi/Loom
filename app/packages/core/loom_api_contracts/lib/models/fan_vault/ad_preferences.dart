class AdPreferences {
  const AdPreferences({
    required this.passportId,
    required this.interestBasedAds,
    required this.updatedAt,
  });

  final String passportId;
  final bool interestBasedAds;
  final DateTime updatedAt;
}
