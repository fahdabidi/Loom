class SeedCreator {
  const SeedCreator({
    required this.id,
    required this.handle,
    required this.displayName,
    required this.vertical,
    required this.avatarRef,
  });

  final String id;
  final String handle;
  final String displayName;
  final String vertical;
  final String avatarRef;
}

class SeedContent {
  const SeedContent({
    required this.id,
    required this.creatorId,
    required this.contentType,
    required this.title,
    required this.summary,
    required this.thumbnailRef,
    required this.createdAt,
    required this.perfVelocity,
  });

  final String id;
  final String creatorId;
  final String contentType;
  final String title;
  final String summary;
  final String thumbnailRef;
  final DateTime createdAt;
  final double perfVelocity;
}

class SeedInterestToken {
  const SeedInterestToken({
    required this.id,
    required this.label,
    required this.category,
  });

  final String id;
  final String label;
  final String category;
}

class SeedWorld {
  const SeedWorld({
    required this.creators,
    required this.content,
    required this.interestTaxonomy,
    required this.managedHostingProvider,
  });

  final List<SeedCreator> creators;
  final List<SeedContent> content;
  final List<SeedInterestToken> interestTaxonomy;
  final String managedHostingProvider;
}

final SeedWorld seedV1 = SeedWorld(
  creators: const [
    SeedCreator(
      id: 'creator_solar_sarah',
      handle: 'solar-sarah',
      displayName: 'Solar Sarah',
      vertical: 'home-energy',
      avatarRef: 'seed://avatars/solar-sarah',
    ),
    SeedCreator(
      id: 'creator_city_ferments',
      handle: 'city-ferments',
      displayName: 'City Ferments',
      vertical: 'food',
      avatarRef: 'seed://avatars/city-ferments',
    ),
    SeedCreator(
      id: 'creator_motion_lab',
      handle: 'motion-lab',
      displayName: 'Motion Lab',
      vertical: 'fitness',
      avatarRef: 'seed://avatars/motion-lab',
    ),
    SeedCreator(
      id: 'creator_nova_clutch',
      handle: 'nova-clutch',
      displayName: 'NovaClutch',
      vertical: 'fps-esports',
      avatarRef: 'seed://avatars/nova-clutch',
    ),
    SeedCreator(
      id: 'creator_ember_hollow',
      handle: 'ember-hollow',
      displayName: 'EmberHollow',
      vertical: 'survival-builder',
      avatarRef: 'seed://avatars/ember-hollow',
    ),
    SeedCreator(
      id: 'creator_frame_by_frame',
      handle: 'frame-by-frame',
      displayName: 'FrameByFrame',
      vertical: 'speedrunning',
      avatarRef: 'seed://avatars/frame-by-frame',
    ),
    SeedCreator(
      id: 'creator_drift_and_chill',
      handle: 'drift-and-chill',
      displayName: 'DriftAndChill',
      vertical: 'variety-streaming',
      avatarRef: 'seed://avatars/drift-and-chill',
    ),
    SeedCreator(
      id: 'creator_iron_vael',
      handle: 'iron-vael',
      displayName: 'IronVael',
      vertical: 'mmo-rpg',
      avatarRef: 'seed://avatars/iron-vael',
    ),
  ],
  content: [
    SeedContent(
      id: 'content_solar_001',
      creatorId: 'creator_solar_sarah',
      contentType: 'video',
      title: 'Rooftop storage that actually pencils out',
      summary:
          'A practical walkthrough of battery sizing, outage coverage, and payback math for a small urban home.',
      thumbnailRef: 'seed://thumbs/solar-001',
      createdAt: DateTime.utc(2026, 5, 1),
      perfVelocity: 0.92,
    ),
    SeedContent(
      id: 'content_solar_002',
      creatorId: 'creator_solar_sarah',
      contentType: 'post',
      title: 'Five utility-bill fields worth tracking',
      summary:
          'How demand charges, time-of-use windows, net-metering credits, connection fees, and delivery charges affect solar ROI.',
      thumbnailRef: 'seed://thumbs/solar-002',
      createdAt: DateTime.utc(2026, 5, 2),
      perfVelocity: 0.81,
    ),
    SeedContent(
      id: 'content_solar_003',
      creatorId: 'creator_solar_sarah',
      contentType: 'video',
      title: 'Panel cleaning myths tested',
      summary:
          'A side-by-side seasonal test showing when rain is enough and when a cleaning plan changes output.',
      thumbnailRef: 'seed://thumbs/solar-003',
      createdAt: DateTime.utc(2026, 5, 3),
      perfVelocity: 0.74,
    ),
    SeedContent(
      id: 'content_solar_004',
      creatorId: 'creator_solar_sarah',
      contentType: 'post',
      title: 'Battery safety checks before summer',
      summary:
          'A homeowner checklist for ventilation, firmware, fire clearances, and installer documentation before peak heat.',
      thumbnailRef: 'seed://thumbs/solar-004',
      createdAt: DateTime.utc(2026, 5, 4),
      perfVelocity: 0.69,
    ),
    SeedContent(
      id: 'content_solar_005',
      creatorId: 'creator_solar_sarah',
      contentType: 'video',
      title: 'Solar quote red flags',
      summary:
          'Contract clauses and production assumptions that deserve a second look before signing an install agreement.',
      thumbnailRef: 'seed://thumbs/solar-005',
      createdAt: DateTime.utc(2026, 5, 5),
      perfVelocity: 0.77,
    ),
    SeedContent(
      id: 'content_ferment_001',
      creatorId: 'creator_city_ferments',
      contentType: 'video',
      title: 'Apartment kimchi without the drama',
      summary:
          'A compact fermentation setup that manages smell, brine levels, and storage in a shared kitchen.',
      thumbnailRef: 'seed://thumbs/ferment-001',
      createdAt: DateTime.utc(2026, 5, 1),
      perfVelocity: 0.85,
    ),
    SeedContent(
      id: 'content_ferment_002',
      creatorId: 'creator_city_ferments',
      contentType: 'post',
      title: 'Starter culture troubleshooting',
      summary:
          'How to diagnose sluggish ferments by temperature, salinity, water chemistry, and vessel choice.',
      thumbnailRef: 'seed://thumbs/ferment-002',
      createdAt: DateTime.utc(2026, 5, 2),
      perfVelocity: 0.73,
    ),
    SeedContent(
      id: 'content_ferment_003',
      creatorId: 'creator_city_ferments',
      contentType: 'video',
      title: 'Three hot sauces, one base mash',
      summary:
          'A batch workflow that branches one pepper mash into bright, smoky, and extra-hot finishing styles.',
      thumbnailRef: 'seed://thumbs/ferment-003',
      createdAt: DateTime.utc(2026, 5, 3),
      perfVelocity: 0.79,
    ),
    SeedContent(
      id: 'content_ferment_004',
      creatorId: 'creator_city_ferments',
      contentType: 'post',
      title: 'Fermentation labels that prevent waste',
      summary:
          'A simple label format for batch date, salt percentage, vessel, burp schedule, and tasting notes.',
      thumbnailRef: 'seed://thumbs/ferment-004',
      createdAt: DateTime.utc(2026, 5, 4),
      perfVelocity: 0.61,
    ),
    SeedContent(
      id: 'content_ferment_005',
      creatorId: 'creator_city_ferments',
      contentType: 'video',
      title: 'Safe mold calls for beginners',
      summary:
          'Visual cues for kahm yeast, surface mold, submerged vegetables, and when to discard a batch.',
      thumbnailRef: 'seed://thumbs/ferment-005',
      createdAt: DateTime.utc(2026, 5, 5),
      perfVelocity: 0.9,
    ),
    SeedContent(
      id: 'content_motion_001',
      creatorId: 'creator_motion_lab',
      contentType: 'video',
      title: 'Desk mobility in eight minutes',
      summary:
          'A short routine that opens hips, thoracic spine, wrists, and neck without leaving the office.',
      thumbnailRef: 'seed://thumbs/motion-001',
      createdAt: DateTime.utc(2026, 5, 1),
      perfVelocity: 0.88,
    ),
    SeedContent(
      id: 'content_motion_002',
      creatorId: 'creator_motion_lab',
      contentType: 'post',
      title: 'Progressions for your first pull-up',
      summary:
          'How to combine isometrics, controlled negatives, rows, and weekly volume without overuse.',
      thumbnailRef: 'seed://thumbs/motion-002',
      createdAt: DateTime.utc(2026, 5, 2),
      perfVelocity: 0.7,
    ),
    SeedContent(
      id: 'content_motion_003',
      creatorId: 'creator_motion_lab',
      contentType: 'video',
      title: 'Balance training after ankle sprains',
      summary:
          'Low-risk drills for rebuilding proprioception and confidence after the acute recovery window.',
      thumbnailRef: 'seed://thumbs/motion-003',
      createdAt: DateTime.utc(2026, 5, 3),
      perfVelocity: 0.76,
    ),
    SeedContent(
      id: 'content_motion_004',
      creatorId: 'creator_motion_lab',
      contentType: 'post',
      title: 'Warmups for heavy hinge days',
      summary:
          'A sequence for bracing, hamstrings, glutes, and loaded patterning before deadlifts or kettlebells.',
      thumbnailRef: 'seed://thumbs/motion-004',
      createdAt: DateTime.utc(2026, 5, 4),
      perfVelocity: 0.64,
    ),
    SeedContent(
      id: 'content_motion_005',
      creatorId: 'creator_motion_lab',
      contentType: 'video',
      title: 'Conditioning without joint flareups',
      summary:
          'A menu of intervals that bias bikes, sleds, carries, and tempo work over high-impact conditioning.',
      thumbnailRef: 'seed://thumbs/motion-005',
      createdAt: DateTime.utc(2026, 5, 5),
      perfVelocity: 0.71,
    ),
    SeedContent(
      id: 'content_nova_001',
      creatorId: 'creator_nova_clutch',
      contentType: 'video',
      title: 'Endgame retake drill under pressure',
      summary:
          'NovaClutch breaks down a tournament retake with comms timing, utility discipline, and clutch decision points.',
      thumbnailRef: 'seed://thumbs/nova-001',
      createdAt: DateTime.utc(2026, 5, 6),
      perfVelocity: 0.94,
    ),
    SeedContent(
      id: 'content_nova_002',
      creatorId: 'creator_nova_clutch',
      contentType: 'post',
      title: 'Three habits that win overtime',
      summary:
          'A concise overtime checklist for economy tracking, defender swaps, and late-round patience.',
      thumbnailRef: 'seed://thumbs/nova-002',
      createdAt: DateTime.utc(2026, 5, 7),
      perfVelocity: 0.83,
    ),
    SeedContent(
      id: 'content_ember_001',
      creatorId: 'creator_ember_hollow',
      contentType: 'video',
      title: 'Cozy base, hostile valley',
      summary:
          'EmberHollow tours a survival-builder base that blends warm interiors, lore rooms, and raid-safe resource loops.',
      thumbnailRef: 'seed://thumbs/ember-001',
      createdAt: DateTime.utc(2026, 5, 6),
      perfVelocity: 0.89,
    ),
    SeedContent(
      id: 'content_ember_002',
      creatorId: 'creator_ember_hollow',
      contentType: 'post',
      title: 'Lore prompts for community builds',
      summary:
          'A themed build prompt set for ruins, hearth rooms, watch posts, and seasonal settlement goals.',
      thumbnailRef: 'seed://thumbs/ember-002',
      createdAt: DateTime.utc(2026, 5, 7),
      perfVelocity: 0.78,
    ),
    SeedContent(
      id: 'content_frame_001',
      creatorId: 'creator_frame_by_frame',
      contentType: 'video',
      title: 'Hollowfall Any% split rescue',
      summary:
          'FrameByFrame reviews a failed split and shows the movement correction that kept the run alive.',
      thumbnailRef: 'seed://thumbs/frame-001',
      createdAt: DateTime.utc(2026, 5, 6),
      perfVelocity: 0.91,
    ),
    SeedContent(
      id: 'content_frame_002',
      creatorId: 'creator_frame_by_frame',
      contentType: 'post',
      title: 'Patch notes that matter to runners',
      summary:
          'A speedrunner-focused read of Hollowfall patch changes affecting route choice, boss timing, and reset risk.',
      thumbnailRef: 'seed://thumbs/frame-002',
      createdAt: DateTime.utc(2026, 5, 7),
      perfVelocity: 0.86,
    ),
    SeedContent(
      id: 'content_drift_001',
      creatorId: 'creator_drift_and_chill',
      contentType: 'video',
      title: 'Hollowfall chill queue highlights',
      summary:
          'DriftAndChill turns a variety-stream queue into low-pressure highlights, creator shoutouts, and fan prompts.',
      thumbnailRef: 'seed://thumbs/drift-001',
      createdAt: DateTime.utc(2026, 5, 6),
      perfVelocity: 0.84,
    ),
    SeedContent(
      id: 'content_drift_002',
      creatorId: 'creator_drift_and_chill',
      contentType: 'post',
      title: 'Stream night starter pack',
      summary:
          'A watch-party prep list covering chill goals, community polls, queue etiquette, and clip prompts.',
      thumbnailRef: 'seed://thumbs/drift-002',
      createdAt: DateTime.utc(2026, 5, 7),
      perfVelocity: 0.8,
    ),
    SeedContent(
      id: 'content_iron_001',
      creatorId: 'creator_iron_vael',
      contentType: 'video',
      title: 'Guild raid prep without burnout',
      summary:
          'IronVael lays out a calm raid-prep loop for builds, assignments, consumables, and post-run learning.',
      thumbnailRef: 'seed://thumbs/iron-001',
      createdAt: DateTime.utc(2026, 5, 6),
      perfVelocity: 0.88,
    ),
    SeedContent(
      id: 'content_iron_002',
      creatorId: 'creator_iron_vael',
      contentType: 'post',
      title: 'Role checklist for new guildmates',
      summary:
          'A new-player onboarding checklist for guild roles, callouts, loot expectations, and first-week goals.',
      thumbnailRef: 'seed://thumbs/iron-002',
      createdAt: DateTime.utc(2026, 5, 7),
      perfVelocity: 0.79,
    ),
  ],
  interestTaxonomy: const [
    SeedInterestToken(
      id: 'home_energy',
      label: 'Home energy',
      category: 'Sustainable living',
    ),
    SeedInterestToken(
      id: 'solar_storage',
      label: 'Solar storage',
      category: 'Sustainable living',
    ),
    SeedInterestToken(
      id: 'urban_gardening',
      label: 'Urban gardening',
      category: 'Sustainable living',
    ),
    SeedInterestToken(
      id: 'fermentation',
      label: 'Fermentation',
      category: 'Food craft',
    ),
    SeedInterestToken(
      id: 'weeknight_cooking',
      label: 'Weeknight cooking',
      category: 'Food craft',
    ),
    SeedInterestToken(
      id: 'food_safety',
      label: 'Food safety',
      category: 'Food craft',
    ),
    SeedInterestToken(id: 'mobility', label: 'Mobility', category: 'Movement'),
    SeedInterestToken(
      id: 'strength_basics',
      label: 'Strength basics',
      category: 'Movement',
    ),
    SeedInterestToken(
      id: 'joint_friendly_cardio',
      label: 'Joint-friendly cardio',
      category: 'Movement',
    ),
    SeedInterestToken(
      id: 'personal_finance',
      label: 'Personal finance',
      category: 'Life systems',
    ),
    SeedInterestToken(
      id: 'family_learning',
      label: 'Family learning',
      category: 'Life systems',
    ),
    SeedInterestToken(
      id: 'creator_tools',
      label: 'Creator tools',
      category: 'Life systems',
    ),
    SeedInterestToken(
      id: 'fps_esports',
      label: 'FPS esports',
      category: 'Gaming',
    ),
    SeedInterestToken(
      id: 'survival_builders',
      label: 'Survival builders',
      category: 'Gaming',
    ),
    SeedInterestToken(
      id: 'speedrunning',
      label: 'Speedrunning',
      category: 'Gaming',
    ),
    SeedInterestToken(
      id: 'variety_streams',
      label: 'Variety streams',
      category: 'Gaming',
    ),
    SeedInterestToken(id: 'mmo_rpg', label: 'MMO/RPG', category: 'Gaming'),
    SeedInterestToken(
      id: 'hollowfall',
      label: 'Hollowfall',
      category: 'Gaming',
    ),
  ],
  managedHostingProvider: 'Loom Managed Hosting',
);
