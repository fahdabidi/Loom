import 'package:loom_api_contracts/loom_api_contracts.dart';

class SponsorCampaignFake implements SponsorCampaignApi {
  SponsorCampaignFake({this.latency = const Duration(milliseconds: 120)});

  final Duration latency;
  final Map<String, SponsorProposal> _proposalsByKey = {};
  final Map<String, SponsorProposal> _proposalsById = {};
  final Map<String, FanDataGrantOffer> _offersByKey = {};
  final Map<String, FanDataGrantOffer> _offersById = {};

  @override
  Future<SponsorProposal> createProposal({
    required String sponsorName,
    required String creatorId,
    required String campaignId,
    required String title,
    required String valueExchange,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final existing = _proposalsByKey[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final proposal = SponsorProposal(
      id: 'proposal_${_slug(campaignId)}_${_proposalsByKey.length + 1}',
      sponsorName: sponsorName,
      creatorId: creatorId,
      campaignId: campaignId,
      title: title,
      valueExchange: valueExchange,
      createdAt: _now(),
    );
    _proposalsByKey[idempotencyKey] = proposal;
    _proposalsById[proposal.id] = proposal;
    return proposal;
  }

  @override
  Future<FanDataGrantOffer> attachFanDataGrantOffer({
    required String proposalId,
    required List<String> fields,
    required String purpose,
    required String valueExchange,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final existing = _offersByKey[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final proposal = _proposalsById[proposalId];
    if (proposal == null) {
      throw StateError('No sponsor proposal exists for $proposalId');
    }
    final offer = FanDataGrantOffer(
      id: 'offer_${_slug(proposalId)}_${_offersByKey.length + 1}',
      proposalId: proposal.id,
      campaignId: proposal.campaignId,
      creatorId: proposal.creatorId,
      sponsorName: proposal.sponsorName,
      fields: fields,
      purpose: purpose,
      valueExchange: valueExchange,
      createdAt: _now(),
    );
    _offersByKey[idempotencyKey] = offer;
    _offersById[offer.id] = offer;
    return offer;
  }

  @override
  Future<List<FanDataGrantOffer>> listOffersForCampaign(
    String campaignId,
  ) async {
    await Future<void>.delayed(latency);
    return _offersById.values
        .where((offer) => offer.campaignId == campaignId)
        .toList(growable: false);
  }
}

DateTime _now() => DateTime.now().toUtc();

String _slug(String value) {
  final cleaned = value
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp('^-+|-+\$'), '');
  return cleaned.isEmpty ? 'item' : cleaned;
}
