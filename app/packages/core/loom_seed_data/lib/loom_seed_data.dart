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
  ],
  managedHostingProvider: 'Loom Managed Hosting',
);
