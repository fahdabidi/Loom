class HostingContract {
  const HostingContract({
    required this.id,
    required this.channelId,
    required this.provider,
    required this.status,
    required this.termsVersion,
    required this.acceptedAt,
  });

  final String id;
  final String channelId;
  final String provider;
  final String status;
  final String termsVersion;
  final DateTime acceptedAt;
}
