import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_local_store/loom_local_store.dart' show DemoLocalStore;

class CampaignFake implements CampaignApi {
  CampaignFake(this._store, {this.latency = const Duration(milliseconds: 120)});

  final DemoLocalStore _store;
  final Duration latency;
  final Map<String, Campaign> _campaignsByKey = {};
  final Map<String, Campaign> _campaignsById = {};
  final Map<String, CampaignEntry> _entriesByKey = {};
  final Map<String, Reward> _rewardsByKey = {};

  @override
  Future<Campaign> createCampaign({
    required String creatorId,
    required String title,
    required String description,
    required String rewardLabel,
    required DateTime endsAt,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final existing = _campaignsByKey[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final creator = (await _store.creators()).where(
      (item) => item.id == creatorId,
    );
    final campaign = Campaign(
      id: 'camp_${_slug(creatorId)}_${_campaignsByKey.length + 1}',
      creatorId: creatorId,
      creatorName: creator.isEmpty ? 'Solar Sarah' : creator.first.displayName,
      title: title,
      description: description,
      rewardLabel: rewardLabel,
      entryCount: 0,
      createdAt: _now(),
      endsAt: endsAt,
    );
    _campaignsByKey[idempotencyKey] = campaign;
    _campaignsById[campaign.id] = campaign;
    return campaign;
  }

  @override
  Future<Campaign?> getCampaign(String campaignId) async {
    await Future<void>.delayed(latency);
    return _campaignsById[campaignId];
  }

  @override
  Future<List<Campaign>> listActiveCampaigns() async {
    await Future<void>.delayed(latency);
    if (_campaignsById.isEmpty) {
      await createCampaign(
        creatorId: 'creator_solar_sarah',
        title: 'Clean Energy Setup Giveaway',
        description:
            'Enter for a creator-approved home energy starter kit with public reward receipts.',
        rewardLabel: 'Home energy kit',
        endsAt: _now().add(const Duration(days: 14)),
        idempotencyKey: 'p8-default-campaign',
      );
    }
    return _campaignsById.values.toList(growable: false);
  }

  @override
  Future<CampaignEntry> participate({
    required String campaignId,
    required String passportId,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final existing = _entriesByKey[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final campaign = _campaignsById[campaignId];
    if (campaign == null) {
      throw StateError('No campaign exists for $campaignId');
    }
    final entry = CampaignEntry(
      id: 'entry_${_slug(campaignId)}_${_entriesByKey.length + 1}',
      campaignId: campaignId,
      passportId: passportId,
      status: 'entered',
      createdAt: _now(),
    );
    _entriesByKey[idempotencyKey] = entry;
    _campaignsById[campaignId] = Campaign(
      id: campaign.id,
      creatorId: campaign.creatorId,
      creatorName: campaign.creatorName,
      title: campaign.title,
      description: campaign.description,
      rewardLabel: campaign.rewardLabel,
      entryCount: campaign.entryCount + 1,
      createdAt: campaign.createdAt,
      endsAt: campaign.endsAt,
    );
    return entry;
  }

  @override
  Future<Reward> issueReward({
    required String campaignId,
    required String entryId,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final existing = _rewardsByKey[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final campaign = _campaignsById[campaignId];
    if (campaign == null) {
      throw StateError('No campaign exists for $campaignId');
    }
    CampaignEntry? entry;
    for (final candidate in _entriesByKey.values) {
      if (candidate.id == entryId) {
        entry = candidate;
        break;
      }
    }
    if (entry == null) {
      throw StateError('No campaign entry exists for $entryId');
    }
    final reward = Reward(
      id: 'reward_${_slug(entryId)}',
      campaignId: campaignId,
      entryId: entryId,
      passportId: entry.passportId,
      label: campaign.rewardLabel,
      status: 'issued',
      issuedAt: _now(),
    );
    _rewardsByKey[idempotencyKey] = reward;
    return reward;
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
