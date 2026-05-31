class AdPreferences {
  const AdPreferences({
    required this.passportId,
    required this.personalizedAds,
    required this.updatedAt,
  });

  final String passportId;
  final bool personalizedAds;
  final DateTime updatedAt;
}
