import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:loom_seed_data/loom_seed_data.dart';

part 'loom_local_store.g.dart';

class Creators extends Table {
  TextColumn get id => text()();
  TextColumn get handle => text()();
  TextColumn get displayName => text()();
  TextColumn get vertical => text()();
  TextColumn get avatarRef => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ContentItems extends Table {
  TextColumn get id => text()();
  TextColumn get creatorId => text().references(Creators, #id)();
  TextColumn get contentType => text()();
  TextColumn get title => text()();
  TextColumn get summary => text()();
  TextColumn get thumbnailRef => text()();
  DateTimeColumn get createdAt => dateTime()();
  RealColumn get perfVelocity => real()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ContentManifests extends Table {
  TextColumn get id => text()();
  TextColumn get channelId => text()();
  TextColumn get contentType => text()();
  TextColumn get title => text()();
  TextColumn get summary => text()();
  TextColumn get accessMode => text()();
  TextColumn get monetizationMode => text()();
  TextColumn get thumbnailRef => text()();
  IntColumn get schemaVersion => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class MonetizationManifests extends Table {
  TextColumn get channelId => text()();
  BoolColumn get membershipsEnabled => boolean()();
  TextColumn get memberOnlyContentIdsJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {channelId};
}

class CreatorAdPolicies extends Table {
  TextColumn get channelId => text()();
  TextColumn get allowedCategoriesJson => text()();
  TextColumn get blockedCategoriesJson => text()();
  TextColumn get formatsJson => text()();
  TextColumn get surfacesJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {channelId};
}

class MembershipTiers extends Table {
  TextColumn get id => text()();
  TextColumn get channelId => text()();
  TextColumn get name => text()();
  IntColumn get monthlyPriceCents => integer()();
  TextColumn get benefitsJson => text()();
  TextColumn get entitlementCode => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AiContentPolicies extends Table {
  TextColumn get channelId => text()();
  BoolColumn get archiveQaEnabled => boolean()();
  BoolColumn get summariesEnabled => boolean()();
  BoolColumn get citationRequired => boolean()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {channelId};
}

class Transcripts extends Table {
  TextColumn get contentId => text().references(ContentItems, #id)();
  TextColumn get segmentsJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {contentId};
}

class AiSessions extends Table {
  TextColumn get id => text()();
  TextColumn get passportId => text().references(FanPassports, #id)();
  TextColumn get creatorId => text().references(Creators, #id)();
  TextColumn get question => text()();
  TextColumn get answer => text()();
  TextColumn get citationContentIdsJson => text()();
  TextColumn get memoryPolicy => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ImportJobs extends Table {
  TextColumn get id => text()();
  TextColumn get channelId => text()();
  TextColumn get sourcePlatform => text()();
  TextColumn get state => text()();
  IntColumn get pollCount => integer()();
  TextColumn get itemsJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ExternalContentRefs extends Table {
  TextColumn get id => text()();
  TextColumn get jobId => text()();
  TextColumn get channelId => text()();
  TextColumn get sourcePlatform => text()();
  TextColumn get externalId => text()();
  TextColumn get contentId => text()();
  TextColumn get title => text()();
  TextColumn get summary => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ContentPerf extends Table {
  TextColumn get contentId => text()();
  RealColumn get velocity => real()();
  RealColumn get completionRate => real()();
  IntColumn get saves => integer()();
  IntColumn get shares => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {contentId};
}

class EntitlementDefinitions extends Table {
  TextColumn get id => text()();
  TextColumn get channelId => text()();
  TextColumn get tierId => text()();
  TextColumn get code => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Wallets extends Table {
  TextColumn get passportId => text().references(FanPassports, #id)();
  TextColumn get currency => text()();
  IntColumn get simulatedBalanceCents => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {passportId};
}

class PaymentIntents extends Table {
  TextColumn get id => text()();
  TextColumn get passportId => text().references(FanPassports, #id)();
  TextColumn get kind => text()();
  TextColumn get creatorId => text().nullable()();
  TextColumn get creatorName => text().nullable()();
  TextColumn get tierId => text().nullable()();
  TextColumn get tierName => text().nullable()();
  IntColumn get amountCents => integer()();
  TextColumn get currency => text()();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get confirmedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class EntitlementGrants extends Table {
  TextColumn get id => text()();
  TextColumn get passportId => text().references(FanPassports, #id)();
  TextColumn get code => text()();
  TextColumn get creatorId => text().nullable()();
  TextColumn get sourcePaymentIntentId => text()();
  BoolColumn get active => boolean()();
  DateTimeColumn get grantedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Subscriptions extends Table {
  TextColumn get id => text()();
  TextColumn get passportId => text().references(FanPassports, #id)();
  TextColumn get creatorId => text()();
  TextColumn get creatorName => text()();
  TextColumn get tierId => text()();
  TextColumn get tierName => text()();
  IntColumn get monthlyPriceCents => integer()();
  BoolColumn get active => boolean()();
  DateTimeColumn get startedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SettlementRuns extends Table {
  TextColumn get id => text()();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class PayoutStatements extends Table {
  TextColumn get id => text()();
  TextColumn get runId => text()();
  TextColumn get creatorId => text()();
  TextColumn get creatorName => text()();
  IntColumn get totalCents => integer()();
  TextColumn get bySourceJson => text()();
  TextColumn get byIntentJson => text()();
  TextColumn get recentReceiptsJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AllocationStatements extends Table {
  TextColumn get id => text()();
  TextColumn get passportId => text().references(FanPassports, #id)();
  IntColumn get totalCents => integer()();
  TextColumn get allocationsJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class FanPassports extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text()();
  TextColumn get activePersonaId => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Personas extends Table {
  TextColumn get id => text()();
  TextColumn get passportId => text().references(FanPassports, #id)();
  TextColumn get label => text()();
  BoolColumn get isActive => boolean()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Follows extends Table {
  TextColumn get id => text()();
  TextColumn get passportId => text().references(FanPassports, #id)();
  TextColumn get creatorId => text().references(Creators, #id)();
  TextColumn get visibility => text()();
  BoolColumn get blocked => boolean()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ConsentGrants extends Table {
  TextColumn get id => text()();
  TextColumn get passportId => text().references(FanPassports, #id)();
  TextColumn get grantType => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AudienceGrantRequests extends Table {
  TextColumn get id => text()();
  TextColumn get creatorId => text().references(Creators, #id)();
  TextColumn get creatorName => text()();
  TextColumn get passportId => text().references(FanPassports, #id)();
  TextColumn get fieldsJson => text()();
  TextColumn get purpose => text()();
  TextColumn get retention => text()();
  TextColumn get valueExchange => text()();
  TextColumn get state => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class DataConsentGrants extends Table {
  TextColumn get id => text()();
  TextColumn get requestId => text().references(AudienceGrantRequests, #id)();
  TextColumn get passportId => text().references(FanPassports, #id)();
  TextColumn get creatorId => text().references(Creators, #id)();
  TextColumn get creatorName => text()();
  TextColumn get fieldsJson => text()();
  TextColumn get purpose => text()();
  TextColumn get retention => text()();
  TextColumn get valueExchange => text()();
  TextColumn get state => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CategoryDefaults extends Table {
  TextColumn get id => text()();
  TextColumn get passportId => text().references(FanPassports, #id)();
  TextColumn get category => text()();
  TextColumn get state => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class DataAccessReceipts extends Table {
  TextColumn get id => text()();
  TextColumn get passportId => text().references(FanPassports, #id)();
  TextColumn get creatorId => text().references(Creators, #id)();
  TextColumn get creatorName => text()();
  TextColumn get grantId => text().references(DataConsentGrants, #id)();
  TextColumn get fieldsJson => text()();
  TextColumn get purpose => text()();
  DateTimeColumn get accessedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Tombstones extends Table {
  TextColumn get id => text()();
  TextColumn get passportId => text().references(FanPassports, #id)();
  TextColumn get creatorId => text().references(Creators, #id)();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class InterestTaxonomy extends Table {
  TextColumn get id => text()();
  TextColumn get label => text()();
  TextColumn get category => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class FanInterestProfiles extends Table {
  TextColumn get passportId => text().references(FanPassports, #id)();
  TextColumn get interestIdsJson => text()();
  TextColumn get dislikedInterestIdsJson => text()();
  TextColumn get dislikedCreatorIdsJson => text()();
  TextColumn get mutedProviderIdsJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {passportId};
}

class FanRankingPreferences extends Table {
  TextColumn get passportId => text().references(FanPassports, #id)();
  BoolColumn get summaryFirst => boolean()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {passportId};
}

class PlatformIntents extends Table {
  TextColumn get id => text()();
  TextColumn get label => text()();
  TextColumn get description => text()();
  TextColumn get interestIdsJson => text()();
  IntColumn get displayOrder => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SessionIntents extends Table {
  TextColumn get id => text()();
  TextColumn get passportId => text().references(FanPassports, #id)();
  TextColumn get platformIntentId => text().references(PlatformIntents, #id)();
  TextColumn get selectedInterestIdsJson => text()();
  BoolColumn get active => boolean()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class FanFeedback extends Table {
  TextColumn get id => text()();
  TextColumn get sessionIntentId => text().references(SessionIntents, #id)();
  TextColumn get passportId => text().references(FanPassports, #id)();
  TextColumn get contentId => text().references(ContentItems, #id)();
  TextColumn get creatorId => text().references(Creators, #id)();
  TextColumn get action => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ExternalProviderCandidates extends Table {
  TextColumn get id => text()();
  TextColumn get providerId => text()();
  TextColumn get providerLabel => text()();
  TextColumn get contentId => text().references(ContentItems, #id)();
  TextColumn get interestIdsJson => text()();
  RealColumn get score => real()();
  TextColumn get reason => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SearchIndexEntries extends Table {
  TextColumn get contentId => text().references(ContentItems, #id)();
  TextColumn get creatorId => text().references(Creators, #id)();
  TextColumn get creatorName => text()();
  TextColumn get title => text()();
  TextColumn get summary => text()();
  TextColumn get contentType => text()();
  TextColumn get thumbnailRef => text()();
  TextColumn get searchText => text()();
  TextColumn get interestIdsJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {contentId};
}

class AdInventory extends Table {
  TextColumn get id => text()();
  TextColumn get brandName => text()();
  TextColumn get category => text()();
  TextColumn get format => text()();
  TextColumn get surfacesJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class PlaybackTokens extends Table {
  TextColumn get id => text()();
  TextColumn get passportId => text().references(FanPassports, #id)();
  TextColumn get contentId => text().references(ContentItems, #id)();
  TextColumn get token => text()();
  TextColumn get adPlanJson => text()();
  BoolColumn get completed => boolean()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Receipts extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get passportId => text().references(FanPassports, #id)();
  TextColumn get contentId => text().references(ContentItems, #id)();
  TextColumn get authorizationId => text()();
  TextColumn get summary => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AdPreferences extends Table {
  TextColumn get passportId => text().references(FanPassports, #id)();
  BoolColumn get personalizedAds => boolean()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {passportId};
}

class CreatorChannels extends Table {
  TextColumn get id => text()();
  TextColumn get ownerPassportId => text()();
  TextColumn get displayName => text()();
  TextColumn get handle => text()();
  TextColumn get vertical => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ChannelManifests extends Table {
  TextColumn get channelId => text().references(CreatorChannels, #id)();
  TextColumn get displayName => text()();
  TextColumn get handle => text()();
  TextColumn get description => text()();
  TextColumn get category => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {channelId};
}

class HostingContracts extends Table {
  TextColumn get id => text()();
  TextColumn get channelId => text().references(CreatorChannels, #id)();
  TextColumn get provider => text()();
  TextColumn get status => text()();
  TextColumn get termsVersion => text()();
  DateTimeColumn get acceptedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class IdempotencyRecords extends Table {
  TextColumn get key => text()();
  TextColumn get targetType => text()();
  TextColumn get targetId => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

class KvMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    Creators,
    ContentItems,
    ContentManifests,
    MonetizationManifests,
    CreatorAdPolicies,
    MembershipTiers,
    AiContentPolicies,
    Transcripts,
    AiSessions,
    ImportJobs,
    ExternalContentRefs,
    ContentPerf,
    EntitlementDefinitions,
    Wallets,
    PaymentIntents,
    EntitlementGrants,
    Subscriptions,
    SettlementRuns,
    PayoutStatements,
    AllocationStatements,
    FanPassports,
    Personas,
    Follows,
    ConsentGrants,
    AudienceGrantRequests,
    DataConsentGrants,
    CategoryDefaults,
    DataAccessReceipts,
    Tombstones,
    InterestTaxonomy,
    FanInterestProfiles,
    FanRankingPreferences,
    PlatformIntents,
    SessionIntents,
    FanFeedback,
    ExternalProviderCandidates,
    SearchIndexEntries,
    AdInventory,
    PlaybackTokens,
    Receipts,
    AdPreferences,
    CreatorChannels,
    ChannelManifests,
    HostingContracts,
    IdempotencyRecords,
    KvMeta,
  ],
)
class LoomDatabase extends _$LoomDatabase {
  LoomDatabase(super.executor);

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(fanPassports);
        await m.createTable(personas);
        await m.createTable(follows);
        await m.createTable(consentGrants);
        await m.createTable(interestTaxonomy);
        await m.createTable(fanInterestProfiles);
        await m.createTable(adPreferences);
        await m.createTable(creatorChannels);
        await m.createTable(channelManifests);
        await m.createTable(hostingContracts);
        await m.createTable(idempotencyRecords);
      }
      if (from < 3) {
        await m.createTable(contentManifests);
        await m.createTable(monetizationManifests);
        await m.createTable(creatorAdPolicies);
        await m.createTable(membershipTiers);
        await m.createTable(aiContentPolicies);
        await m.createTable(importJobs);
        await m.createTable(externalContentRefs);
        await m.createTable(contentPerf);
        await m.createTable(entitlementDefinitions);
      }
      if (from < 4) {
        await m.createTable(platformIntents);
        await m.createTable(sessionIntents);
        await m.createTable(fanFeedback);
        await m.createTable(externalProviderCandidates);
        await m.createTable(searchIndexEntries);
      }
      if (from < 5) {
        await m.createTable(adInventory);
        await m.createTable(playbackTokens);
        await m.createTable(receipts);
      }
      if (from < 6) {
        await m.createTable(transcripts);
        await m.createTable(aiSessions);
        await m.createTable(fanRankingPreferences);
      }
      if (from < 7) {
        await m.createTable(wallets);
        await m.createTable(paymentIntents);
        await m.createTable(entitlementGrants);
        await m.createTable(subscriptions);
        await m.createTable(settlementRuns);
        await m.createTable(payoutStatements);
        await m.createTable(allocationStatements);
      }
      if (from < 8) {
        await m.createTable(audienceGrantRequests);
        await m.createTable(dataConsentGrants);
        await m.createTable(categoryDefaults);
        await m.createTable(dataAccessReceipts);
        await m.createTable(tombstones);
      }
    },
  );
}

class CreatorRecord {
  const CreatorRecord({
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

class ContentRecord {
  const ContentRecord({
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

class FanPassportRecord {
  const FanPassportRecord({
    required this.id,
    required this.displayName,
    required this.activePersonaId,
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final String activePersonaId;
  final DateTime createdAt;
}

class PersonaRecord {
  const PersonaRecord({
    required this.id,
    required this.passportId,
    required this.label,
    required this.isActive,
  });

  final String id;
  final String passportId;
  final String label;
  final bool isActive;
}

class FollowRecord {
  const FollowRecord({
    required this.id,
    required this.passportId,
    required this.creatorId,
    required this.creatorDisplayName,
    required this.visibility,
    required this.blocked,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String passportId;
  final String creatorId;
  final String creatorDisplayName;
  final String visibility;
  final bool blocked;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class ConsentGrantRecord {
  const ConsentGrantRecord({
    required this.id,
    required this.passportId,
    required this.grantType,
    required this.createdAt,
  });

  final String id;
  final String passportId;
  final String grantType;
  final DateTime createdAt;
}

class DataGrantRequestRecord {
  const DataGrantRequestRecord({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    required this.passportId,
    required this.fields,
    required this.purpose,
    required this.retention,
    required this.valueExchange,
    required this.state,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String creatorId;
  final String creatorName;
  final String passportId;
  final List<String> fields;
  final String purpose;
  final String retention;
  final String valueExchange;
  final String state;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class DataConsentGrantRecord {
  const DataConsentGrantRecord({
    required this.id,
    required this.requestId,
    required this.passportId,
    required this.creatorId,
    required this.creatorName,
    required this.fields,
    required this.purpose,
    required this.retention,
    required this.valueExchange,
    required this.state,
    required this.updatedAt,
  });

  final String id;
  final String requestId;
  final String passportId;
  final String creatorId;
  final String creatorName;
  final List<String> fields;
  final String purpose;
  final String retention;
  final String valueExchange;
  final String state;
  final DateTime updatedAt;
}

class CategoryDefaultRecord {
  const CategoryDefaultRecord({
    required this.id,
    required this.passportId,
    required this.category,
    required this.state,
    required this.updatedAt,
  });

  final String id;
  final String passportId;
  final String category;
  final String state;
  final DateTime updatedAt;
}

class DataAccessReceiptRecord {
  const DataAccessReceiptRecord({
    required this.id,
    required this.passportId,
    required this.creatorId,
    required this.creatorName,
    required this.grantId,
    required this.fields,
    required this.purpose,
    required this.accessedAt,
  });

  final String id;
  final String passportId;
  final String creatorId;
  final String creatorName;
  final String grantId;
  final List<String> fields;
  final String purpose;
  final DateTime accessedAt;
}

class TombstoneRequestRecord {
  const TombstoneRequestRecord({
    required this.id,
    required this.passportId,
    required this.creatorId,
    required this.createdAt,
  });

  final String id;
  final String passportId;
  final String creatorId;
  final DateTime createdAt;
}

class PermissionedInterestDataRecord {
  const PermissionedInterestDataRecord({
    required this.creatorId,
    required this.passportId,
    required this.fields,
    required this.values,
    required this.receipt,
  });

  final String creatorId;
  final String passportId;
  final List<String> fields;
  final Map<String, List<String>> values;
  final DataAccessReceiptRecord receipt;
}

class AudienceInsightRecord {
  const AudienceInsightRecord({
    required this.creatorId,
    required this.approvedFanCount,
    required this.topCategories,
    required this.permissionStatus,
    required this.updatedAt,
  });

  final String creatorId;
  final int approvedFanCount;
  final List<String> topCategories;
  final String permissionStatus;
  final DateTime updatedAt;
}

class InterestTokenRecord {
  const InterestTokenRecord({
    required this.id,
    required this.label,
    required this.category,
  });

  final String id;
  final String label;
  final String category;
}

class InterestProfileRecord {
  const InterestProfileRecord({
    required this.passportId,
    required this.interests,
    required this.dislikedInterestIds,
    required this.dislikedCreatorIds,
    required this.mutedProviderIds,
    required this.updatedAt,
  });

  final String passportId;
  final List<InterestTokenRecord> interests;
  final List<String> dislikedInterestIds;
  final List<String> dislikedCreatorIds;
  final List<String> mutedProviderIds;
  final DateTime updatedAt;
}

class AdPreferencesRecord {
  const AdPreferencesRecord({
    required this.passportId,
    required this.personalizedAds,
    required this.updatedAt,
  });

  final String passportId;
  final bool personalizedAds;
  final DateTime updatedAt;
}

class CreatorChannelRecord {
  const CreatorChannelRecord({
    required this.id,
    required this.ownerPassportId,
    required this.displayName,
    required this.handle,
    required this.vertical,
    required this.createdAt,
  });

  final String id;
  final String ownerPassportId;
  final String displayName;
  final String handle;
  final String vertical;
  final DateTime createdAt;
}

class CreatorChannelManifestRecord {
  const CreatorChannelManifestRecord({
    required this.channelId,
    required this.displayName,
    required this.handle,
    required this.description,
    required this.category,
    required this.createdAt,
  });

  final String channelId;
  final String displayName;
  final String handle;
  final String description;
  final String category;
  final DateTime createdAt;
}

class HostingContractRecord {
  const HostingContractRecord({
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

class ContentManifestRecord {
  const ContentManifestRecord({
    required this.id,
    required this.channelId,
    required this.contentType,
    required this.title,
    required this.summary,
    required this.accessMode,
    required this.monetizationMode,
    required this.thumbnailRef,
    required this.schemaVersion,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String channelId;
  final String contentType;
  final String title;
  final String summary;
  final String accessMode;
  final String monetizationMode;
  final String thumbnailRef;
  final int schemaVersion;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class MonetizationManifestRecord {
  const MonetizationManifestRecord({
    required this.channelId,
    required this.membershipsEnabled,
    required this.memberOnlyContentIds,
    required this.updatedAt,
  });

  final String channelId;
  final bool membershipsEnabled;
  final List<String> memberOnlyContentIds;
  final DateTime updatedAt;
}

class CreatorAdPolicyRecord {
  const CreatorAdPolicyRecord({
    required this.channelId,
    required this.allowedCategories,
    required this.blockedCategories,
    required this.formats,
    required this.surfaces,
    required this.updatedAt,
  });

  final String channelId;
  final List<String> allowedCategories;
  final List<String> blockedCategories;
  final List<String> formats;
  final List<String> surfaces;
  final DateTime updatedAt;
}

class MembershipTierRecord {
  const MembershipTierRecord({
    required this.id,
    required this.channelId,
    required this.name,
    required this.monthlyPriceCents,
    required this.benefits,
    required this.entitlementCode,
    required this.createdAt,
  });

  final String id;
  final String channelId;
  final String name;
  final int monthlyPriceCents;
  final List<String> benefits;
  final String entitlementCode;
  final DateTime createdAt;
}

class AiContentPolicyRecord {
  const AiContentPolicyRecord({
    required this.channelId,
    required this.archiveQaEnabled,
    required this.summariesEnabled,
    required this.citationRequired,
    required this.updatedAt,
  });

  final String channelId;
  final bool archiveQaEnabled;
  final bool summariesEnabled;
  final bool citationRequired;
  final DateTime updatedAt;
}

class TranscriptSegmentRecord {
  const TranscriptSegmentRecord({required this.startLabel, required this.text});

  final String startLabel;
  final String text;
}

class TranscriptRecord {
  const TranscriptRecord({
    required this.contentId,
    required this.segments,
    required this.updatedAt,
  });

  final String contentId;
  final List<TranscriptSegmentRecord> segments;
  final DateTime updatedAt;
}

class AiSessionRecord {
  const AiSessionRecord({
    required this.id,
    required this.passportId,
    required this.creatorId,
    required this.question,
    required this.answer,
    required this.citationContentIds,
    required this.memoryPolicy,
    required this.createdAt,
  });

  final String id;
  final String passportId;
  final String creatorId;
  final String question;
  final String answer;
  final List<String> citationContentIds;
  final String memoryPolicy;
  final DateTime createdAt;
}

class RankPreferenceRecord {
  const RankPreferenceRecord({
    required this.passportId,
    required this.summaryFirst,
    required this.updatedAt,
  });

  final String passportId;
  final bool summaryFirst;
  final DateTime updatedAt;
}

class ExternalContentRefRecord {
  const ExternalContentRefRecord({
    required this.id,
    required this.jobId,
    required this.channelId,
    required this.sourcePlatform,
    required this.externalId,
    required this.contentId,
    required this.title,
    required this.summary,
    required this.createdAt,
  });

  final String id;
  final String jobId;
  final String channelId;
  final String sourcePlatform;
  final String externalId;
  final String contentId;
  final String title;
  final String summary;
  final DateTime createdAt;
}

class ImportJobRecord {
  const ImportJobRecord({
    required this.id,
    required this.channelId,
    required this.sourcePlatform,
    required this.state,
    required this.references,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String channelId;
  final String sourcePlatform;
  final String state;
  final List<ExternalContentRefRecord> references;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class ContentPerformanceRecord {
  const ContentPerformanceRecord({
    required this.contentId,
    required this.velocity,
    required this.completionRate,
    required this.saves,
    required this.shares,
    required this.updatedAt,
  });

  final String contentId;
  final double velocity;
  final double completionRate;
  final int saves;
  final int shares;
  final DateTime updatedAt;
}

class PlatformIntentRecord {
  const PlatformIntentRecord({
    required this.id,
    required this.label,
    required this.description,
    required this.interestIds,
    required this.displayOrder,
  });

  final String id;
  final String label;
  final String description;
  final List<String> interestIds;
  final int displayOrder;
}

class SessionIntentRecord {
  const SessionIntentRecord({
    required this.id,
    required this.passportId,
    required this.platformIntentId,
    required this.selectedInterestIds,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String passportId;
  final String platformIntentId;
  final List<String> selectedInterestIds;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class FanFeedbackRecord {
  const FanFeedbackRecord({
    required this.id,
    required this.sessionIntentId,
    required this.passportId,
    required this.contentId,
    required this.creatorId,
    required this.action,
    required this.createdAt,
  });

  final String id;
  final String sessionIntentId;
  final String passportId;
  final String contentId;
  final String creatorId;
  final String action;
  final DateTime createdAt;
}

class ExternalProviderCandidateRecord {
  const ExternalProviderCandidateRecord({
    required this.id,
    required this.providerId,
    required this.providerLabel,
    required this.contentId,
    required this.interestIds,
    required this.score,
    required this.reason,
    required this.updatedAt,
  });

  final String id;
  final String providerId;
  final String providerLabel;
  final String contentId;
  final List<String> interestIds;
  final double score;
  final String reason;
  final DateTime updatedAt;
}

class SearchIndexEntryRecord {
  const SearchIndexEntryRecord({
    required this.contentId,
    required this.creatorId,
    required this.creatorName,
    required this.title,
    required this.summary,
    required this.contentType,
    required this.thumbnailRef,
    required this.searchText,
    required this.interestIds,
    required this.updatedAt,
  });

  final String contentId;
  final String creatorId;
  final String creatorName;
  final String title;
  final String summary;
  final String contentType;
  final String thumbnailRef;
  final String searchText;
  final List<String> interestIds;
  final DateTime updatedAt;
}

class AdInventoryRecord {
  const AdInventoryRecord({
    required this.id,
    required this.brandName,
    required this.category,
    required this.format,
    required this.surfaces,
    required this.updatedAt,
  });

  final String id;
  final String brandName;
  final String category;
  final String format;
  final List<String> surfaces;
  final DateTime updatedAt;
}

class PlaybackTokenRecord {
  const PlaybackTokenRecord({
    required this.id,
    required this.passportId,
    required this.contentId,
    required this.token,
    required this.adPlan,
    required this.completed,
    required this.createdAt,
    required this.expiresAt,
  });

  final String id;
  final String passportId;
  final String contentId;
  final String token;
  final Map<String, Object?> adPlan;
  final bool completed;
  final DateTime createdAt;
  final DateTime expiresAt;
}

class ReceiptRecord {
  const ReceiptRecord({
    required this.id,
    required this.type,
    required this.passportId,
    required this.contentId,
    required this.authorizationId,
    required this.summary,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String passportId;
  final String contentId;
  final String authorizationId;
  final String summary;
  final DateTime createdAt;
}

class EntitlementDefinitionRecord {
  const EntitlementDefinitionRecord({
    required this.id,
    required this.channelId,
    required this.tierId,
    required this.code,
    required this.createdAt,
  });

  final String id;
  final String channelId;
  final String tierId;
  final String code;
  final DateTime createdAt;
}

class WalletRecord {
  const WalletRecord({
    required this.passportId,
    required this.currency,
    required this.simulatedBalanceCents,
    required this.hasNoAdsPremium,
    required this.subscriptions,
    required this.updatedAt,
  });

  final String passportId;
  final String currency;
  final int simulatedBalanceCents;
  final bool hasNoAdsPremium;
  final List<SubscriptionRecord> subscriptions;
  final DateTime updatedAt;
}

class PaymentIntentRecord {
  const PaymentIntentRecord({
    required this.id,
    required this.passportId,
    required this.kind,
    required this.amountCents,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.creatorId,
    this.creatorName,
    this.tierId,
    this.tierName,
    this.confirmedAt,
  });

  final String id;
  final String passportId;
  final String kind;
  final String? creatorId;
  final String? creatorName;
  final String? tierId;
  final String? tierName;
  final int amountCents;
  final String currency;
  final String status;
  final DateTime createdAt;
  final DateTime? confirmedAt;
}

class SubscriptionRecord {
  const SubscriptionRecord({
    required this.id,
    required this.passportId,
    required this.creatorId,
    required this.creatorName,
    required this.tierId,
    required this.tierName,
    required this.monthlyPriceCents,
    required this.active,
    required this.startedAt,
  });

  final String id;
  final String passportId;
  final String creatorId;
  final String creatorName;
  final String tierId;
  final String tierName;
  final int monthlyPriceCents;
  final bool active;
  final DateTime startedAt;
}

class EntitlementGrantRecord {
  const EntitlementGrantRecord({
    required this.id,
    required this.passportId,
    required this.code,
    required this.sourcePaymentIntentId,
    required this.active,
    required this.grantedAt,
    this.creatorId,
  });

  final String id;
  final String passportId;
  final String code;
  final String? creatorId;
  final String sourcePaymentIntentId;
  final bool active;
  final DateTime grantedAt;
}

class RevenueBreakdownRecord {
  const RevenueBreakdownRecord({
    required this.label,
    required this.amountCents,
  });

  final String label;
  final int amountCents;
}

class AllocationLineRecord {
  const AllocationLineRecord({
    required this.creatorId,
    required this.creatorName,
    required this.amountCents,
    required this.reason,
  });

  final String creatorId;
  final String creatorName;
  final int amountCents;
  final String reason;
}

class CreatorPayoutStatementRecord {
  const CreatorPayoutStatementRecord({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    required this.totalCents,
    required this.bySource,
    required this.byIntent,
    required this.recentReceipts,
    required this.updatedAt,
  });

  final String id;
  final String creatorId;
  final String creatorName;
  final int totalCents;
  final List<RevenueBreakdownRecord> bySource;
  final List<RevenueBreakdownRecord> byIntent;
  final List<ReceiptRecord> recentReceipts;
  final DateTime updatedAt;
}

class FanAllocationStatementRecord {
  const FanAllocationStatementRecord({
    required this.id,
    required this.passportId,
    required this.totalCents,
    required this.allocations,
    required this.updatedAt,
  });

  final String id;
  final String passportId;
  final int totalCents;
  final List<AllocationLineRecord> allocations;
  final DateTime updatedAt;
}

class DemoLocalStore {
  DemoLocalStore._(this._db);

  final LoomDatabase _db;

  static Future<DemoLocalStore> open({
    required File databaseFile,
    SeedWorld? seed,
  }) async {
    final store = DemoLocalStore._(LoomDatabase(NativeDatabase(databaseFile)));
    await store.resetDemo(seed: seed);
    return store;
  }

  static Future<DemoLocalStore> seeded({SeedWorld? seed}) async {
    final store = DemoLocalStore._(LoomDatabase(NativeDatabase.memory()));
    await store.resetDemo(seed: seed);
    return store;
  }

  Future<void> close() => _db.close();

  Future<void> resetDemo({SeedWorld? seed}) async {
    final world = seed ?? seedV1;

    await _db.transaction(() async {
      await _db.delete(_db.allocationStatements).go();
      await _db.delete(_db.payoutStatements).go();
      await _db.delete(_db.settlementRuns).go();
      await _db.delete(_db.entitlementGrants).go();
      await _db.delete(_db.subscriptions).go();
      await _db.delete(_db.paymentIntents).go();
      await _db.delete(_db.wallets).go();
      await _db.delete(_db.receipts).go();
      await _db.delete(_db.playbackTokens).go();
      await _db.delete(_db.adInventory).go();
      await _db.delete(_db.aiSessions).go();
      await _db.delete(_db.transcripts).go();
      await _db.delete(_db.fanFeedback).go();
      await _db.delete(_db.sessionIntents).go();
      await _db.delete(_db.externalProviderCandidates).go();
      await _db.delete(_db.searchIndexEntries).go();
      await _db.delete(_db.platformIntents).go();
      await _db.delete(_db.entitlementDefinitions).go();
      await _db.delete(_db.contentPerf).go();
      await _db.delete(_db.externalContentRefs).go();
      await _db.delete(_db.importJobs).go();
      await _db.delete(_db.aiContentPolicies).go();
      await _db.delete(_db.membershipTiers).go();
      await _db.delete(_db.creatorAdPolicies).go();
      await _db.delete(_db.monetizationManifests).go();
      await _db.delete(_db.contentManifests).go();
      await _db.delete(_db.hostingContracts).go();
      await _db.delete(_db.channelManifests).go();
      await _db.delete(_db.creatorChannels).go();
      await _db.delete(_db.adPreferences).go();
      await _db.delete(_db.fanRankingPreferences).go();
      await _db.delete(_db.fanInterestProfiles).go();
      await _db.delete(_db.interestTaxonomy).go();
      await _db.delete(_db.dataAccessReceipts).go();
      await _db.delete(_db.dataConsentGrants).go();
      await _db.delete(_db.audienceGrantRequests).go();
      await _db.delete(_db.categoryDefaults).go();
      await _db.delete(_db.tombstones).go();
      await _db.delete(_db.consentGrants).go();
      await _db.delete(_db.follows).go();
      await _db.delete(_db.personas).go();
      await _db.delete(_db.fanPassports).go();
      await _db.delete(_db.idempotencyRecords).go();
      await _db.delete(_db.contentItems).go();
      await _db.delete(_db.creators).go();
      await _db.delete(_db.kvMeta).go();

      await _db.batch((batch) {
        batch.insertAll(
          _db.creators,
          world.creators.map(
            (creator) => CreatorsCompanion.insert(
              id: creator.id,
              handle: creator.handle,
              displayName: creator.displayName,
              vertical: creator.vertical,
              avatarRef: creator.avatarRef,
            ),
          ),
        );

        batch.insertAll(
          _db.contentItems,
          world.content.map(
            (content) => ContentItemsCompanion.insert(
              id: content.id,
              creatorId: content.creatorId,
              contentType: content.contentType,
              title: content.title,
              summary: content.summary,
              thumbnailRef: content.thumbnailRef,
              createdAt: content.createdAt,
              perfVelocity: content.perfVelocity,
            ),
          ),
        );

        batch.insertAll(
          _db.interestTaxonomy,
          world.interestTaxonomy.map(
            (token) => InterestTaxonomyCompanion.insert(
              id: token.id,
              label: token.label,
              category: token.category,
            ),
          ),
        );

        batch.insertAll(_db.fanPassports, [
          FanPassportsCompanion.insert(
            id: 'passport_demo_fan',
            displayName: 'Demo Fan',
            activePersonaId: 'persona_passport-demo-fan',
            createdAt: _now(),
          ),
        ]);

        batch.insertAll(_db.personas, [
          PersonasCompanion.insert(
            id: 'persona_passport-demo-fan',
            passportId: 'passport_demo_fan',
            label: 'Everyday fan',
            isActive: true,
          ),
        ]);

        batch.insertAll(_db.fanInterestProfiles, [
          FanInterestProfilesCompanion.insert(
            passportId: 'passport_demo_fan',
            interestIdsJson: jsonEncode([
              'home_energy',
              'solar_storage',
              'creator_tools',
            ]),
            dislikedInterestIdsJson: '[]',
            dislikedCreatorIdsJson: '[]',
            mutedProviderIdsJson: '[]',
            updatedAt: _now(),
          ),
        ]);

        batch.insertAll(_db.adPreferences, [
          AdPreferencesCompanion.insert(
            passportId: 'passport_demo_fan',
            personalizedAds: false,
            updatedAt: _now(),
          ),
        ]);

        batch.insertAll(_db.fanRankingPreferences, [
          FanRankingPreferencesCompanion.insert(
            passportId: 'passport_demo_fan',
            summaryFirst: false,
            updatedAt: _now(),
          ),
        ]);

        batch.insertAll(_db.wallets, [
          WalletsCompanion.insert(
            passportId: 'passport_demo_fan',
            currency: 'USD',
            simulatedBalanceCents: 50000,
            updatedAt: _now(),
          ),
        ]);

        batch.insertAll(_db.receipts, [
          ReceiptsCompanion.insert(
            id: 'receipt_seed_membership_creator-solar-sarah',
            type: 'membership',
            passportId: 'passport_demo_fan',
            contentId: 'content_solar_001',
            authorizationId: 'seed_revenue_creator_solar_sarah',
            summary:
                'Historical membership support for Solar Sarah from Learn intent.',
            createdAt: _now().subtract(const Duration(days: 7)),
          ),
          ReceiptsCompanion.insert(
            id: 'receipt_seed_premium_no_ad',
            type: 'premiumNoAd',
            passportId: 'passport_demo_fan',
            contentId: 'content_solar_002',
            authorizationId: 'seed_revenue_no_ad_pool',
            summary:
                'Historical premium no-ad pool allocation across creator watch time.',
            createdAt: _now().subtract(const Duration(days: 5)),
          ),
        ]);

        batch.insertAll(
          _db.creatorAdPolicies,
          world.creators.map((creator) {
            final allowed = _defaultAdCategoriesForCreator(creator.id);
            return CreatorAdPoliciesCompanion.insert(
              channelId: creator.id,
              allowedCategoriesJson: jsonEncode(allowed),
              blockedCategoriesJson: jsonEncode(['gambling']),
              formatsJson: jsonEncode(['pre_roll', 'sponsor_card']),
              surfacesJson: jsonEncode(['watch', 'post_detail']),
              updatedAt: _now(),
            );
          }),
        );

        batch.insertAll(
          _db.platformIntents,
          _platformIntentSeeds.map(
            (intent) => PlatformIntentsCompanion.insert(
              id: intent.id,
              label: intent.label,
              description: intent.description,
              interestIdsJson: jsonEncode(intent.interestIds),
              displayOrder: intent.displayOrder,
            ),
          ),
        );

        batch.insertAll(
          _db.externalProviderCandidates,
          world.content.map((content) {
            final interestIds = _interestIdsForCreatorId(content.creatorId);
            return ExternalProviderCandidatesCompanion.insert(
              id: 'candidate_${content.id}',
              providerId: 'loom_bridge',
              providerLabel: 'Loom import bridge',
              contentId: content.id,
              interestIdsJson: jsonEncode(interestIds),
              score: content.perfVelocity,
              reason: 'Seeded from cross-platform activity and creator fit.',
              updatedAt: _now(),
            );
          }),
        );

        batch.insertAll(
          _db.transcripts,
          world.content.map(
            (content) => TranscriptsCompanion.insert(
              contentId: content.id,
              segmentsJson: jsonEncode(_transcriptSegmentsForContent(content)),
              updatedAt: _now(),
            ),
          ),
        );

        batch.insertAll(
          _db.searchIndexEntries,
          world.content.map((content) {
            final creator = world.creators.firstWhere(
              (candidate) => candidate.id == content.creatorId,
            );
            return SearchIndexEntriesCompanion.insert(
              contentId: content.id,
              creatorId: content.creatorId,
              creatorName: creator.displayName,
              title: content.title,
              summary: content.summary,
              contentType: content.contentType,
              thumbnailRef: content.thumbnailRef,
              searchText: _searchTextForContent(
                content.title,
                content.summary,
                creator.displayName,
                creator.vertical,
              ),
              interestIdsJson: jsonEncode(
                _interestIdsForCreatorId(content.creatorId),
              ),
              updatedAt: _now(),
            );
          }),
        );

        batch.insertAll(
          _db.adInventory,
          _adInventorySeeds.map(
            (ad) => AdInventoryCompanion.insert(
              id: ad.id,
              brandName: ad.brandName,
              category: ad.category,
              format: ad.format,
              surfacesJson: jsonEncode(ad.surfaces),
              updatedAt: _now(),
            ),
          ),
        );

        batch.insertAll(_db.kvMeta, [
          KvMetaCompanion.insert(key: 'seedVersion', value: 'v1'),
          KvMetaCompanion.insert(key: 'storage', value: 'drift-sqlite'),
          KvMetaCompanion.insert(
            key: 'managedHostingProvider',
            value: world.managedHostingProvider,
          ),
        ]);
      });
    });
  }

  Future<CreatorRecord?> creatorById(String id) async {
    final row = await (_db.select(
      _db.creators,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapCreator(row);
  }

  Future<List<CreatorRecord>> creators() async {
    final rows = await (_db.select(
      _db.creators,
    )..orderBy([(tbl) => OrderingTerm.asc(tbl.displayName)])).get();
    return rows.map(_mapCreator).toList(growable: false);
  }

  Future<ContentRecord?> contentById(String id) async {
    final row = await (_db.select(
      _db.contentItems,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapContent(row);
  }

  Future<List<ContentRecord>> publicCatalog() async {
    final rows =
        await (_db.select(_db.contentItems)..orderBy([
              (tbl) => OrderingTerm.desc(tbl.perfVelocity),
              (tbl) => OrderingTerm.desc(tbl.createdAt),
            ]))
            .get();
    return rows.map(_mapContent).toList(growable: false);
  }

  Future<List<ContentRecord>> publicCatalogForCreator(String creatorId) async {
    final rows =
        await (_db.select(_db.contentItems)
              ..where((tbl) => tbl.creatorId.equals(creatorId))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
            .get();

    return rows.map(_mapContent).toList(growable: false);
  }

  Future<List<TranscriptRecord>> transcriptsForCreator(String creatorId) async {
    final content = await publicCatalogForCreator(creatorId);
    if (content.isEmpty) {
      return const [];
    }
    final contentIds = content.map((item) => item.id).toSet();
    final rows = await _db.select(_db.transcripts).get();
    return rows
        .where((row) => contentIds.contains(row.contentId))
        .map(_mapTranscript)
        .toList(growable: false);
  }

  Future<AiSessionRecord> createAiSession({
    required String passportId,
    required String creatorId,
    required String question,
    required String answer,
    required List<String> citationContentIds,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(idempotencyKey, 'ai_session');
    if (existing != null) {
      final session = await aiSession(existing);
      if (session != null) {
        return session;
      }
    }

    await ensureDemoPassport(passportId: passportId);
    final id = 'ai_${_slug(idempotencyKey)}';
    await _db
        .into(_db.aiSessions)
        .insertOnConflictUpdate(
          AiSessionsCompanion.insert(
            id: id,
            passportId: passportId,
            creatorId: creatorId,
            question: question,
            answer: answer,
            citationContentIdsJson: jsonEncode(citationContentIds),
            memoryPolicy: 'session_only',
            createdAt: _now(),
          ),
        );
    await _saveIdempotency(idempotencyKey, 'ai_session', id);
    return (await aiSession(id))!;
  }

  Future<AiSessionRecord?> aiSession(String id) async {
    final row = await (_db.select(
      _db.aiSessions,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapAiSession(row);
  }

  Future<String?> metaValue(String key) async {
    final row = await (_db.select(
      _db.kvMeta,
    )..where((tbl) => tbl.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<FanPassportRecord> createPassport({
    required String displayName,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(idempotencyKey, 'fan_passport');
    if (existing != null) {
      final passport = await fanPassportById(existing);
      if (passport != null) {
        return passport;
      }
    }

    final id = 'passport_${_slug(idempotencyKey)}';
    final personaId = 'persona_${_slug(idempotencyKey)}';
    final now = _now();

    await _db.transaction(() async {
      await _db
          .into(_db.fanPassports)
          .insertOnConflictUpdate(
            FanPassportsCompanion.insert(
              id: id,
              displayName: displayName,
              activePersonaId: personaId,
              createdAt: now,
            ),
          );
      await _db
          .into(_db.personas)
          .insertOnConflictUpdate(
            PersonasCompanion.insert(
              id: personaId,
              passportId: id,
              label: 'Everyday fan',
              isActive: true,
            ),
          );
      await _ensureInterestProfile(id);
      await _ensureAdPreferences(id);
      await _saveIdempotency(idempotencyKey, 'fan_passport', id);
    });

    return (await fanPassportById(id))!;
  }

  Future<FanPassportRecord?> fanPassportById(String id) async {
    final row = await (_db.select(
      _db.fanPassports,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapPassport(row);
  }

  Future<FanPassportRecord> ensureDemoPassport({
    String passportId = 'passport_demo_fan',
  }) async {
    final existing = await fanPassportById(passportId);
    if (existing != null) {
      return existing;
    }

    final personaId = 'persona_${_slug(passportId)}';
    final now = _now();
    await _db.transaction(() async {
      await _db
          .into(_db.fanPassports)
          .insertOnConflictUpdate(
            FanPassportsCompanion.insert(
              id: passportId,
              displayName: 'Demo Fan',
              activePersonaId: personaId,
              createdAt: now,
            ),
          );
      await _db
          .into(_db.personas)
          .insertOnConflictUpdate(
            PersonasCompanion.insert(
              id: personaId,
              passportId: passportId,
              label: 'Everyday fan',
              isActive: true,
            ),
          );
      await _ensureInterestProfile(passportId);
      await _ensureAdPreferences(passportId);
    });
    return (await fanPassportById(passportId))!;
  }

  Future<PersonaRecord> setPersona({
    required String passportId,
    required String label,
    required String idempotencyKey,
  }) async {
    final passport = await fanPassportById(passportId);
    if (passport == null) {
      throw StateError('No fan passport exists for $passportId');
    }

    final existing = await _idempotentTarget(idempotencyKey, 'persona');
    if (existing != null) {
      final row = await (_db.select(
        _db.personas,
      )..where((tbl) => tbl.id.equals(existing))).getSingleOrNull();
      if (row != null) {
        return _mapPersona(row);
      }
    }

    final id = 'persona_${_slug(idempotencyKey)}';
    await _db.transaction(() async {
      await (_db.update(_db.personas)
            ..where((tbl) => tbl.passportId.equals(passportId)))
          .write(const PersonasCompanion(isActive: Value(false)));
      await _db
          .into(_db.personas)
          .insertOnConflictUpdate(
            PersonasCompanion.insert(
              id: id,
              passportId: passportId,
              label: label,
              isActive: true,
            ),
          );
      await (_db.update(_db.fanPassports)
            ..where((tbl) => tbl.id.equals(passportId)))
          .write(FanPassportsCompanion(activePersonaId: Value(id)));
      await _saveIdempotency(idempotencyKey, 'persona', id);
    });

    final row = await (_db.select(
      _db.personas,
    )..where((tbl) => tbl.id.equals(id))).getSingle();
    return _mapPersona(row);
  }

  Future<ConsentGrantRecord> createConsentGrant({
    required String passportId,
    required String grantType,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(idempotencyKey, 'consent_grant');
    if (existing != null) {
      final row = await (_db.select(
        _db.consentGrants,
      )..where((tbl) => tbl.id.equals(existing))).getSingleOrNull();
      if (row != null) {
        return _mapConsent(row);
      }
    }

    final id = 'consent_${_slug(idempotencyKey)}';
    await _db
        .into(_db.consentGrants)
        .insertOnConflictUpdate(
          ConsentGrantsCompanion.insert(
            id: id,
            passportId: passportId,
            grantType: grantType,
            createdAt: _now(),
          ),
        );
    await _saveIdempotency(idempotencyKey, 'consent_grant', id);

    final row = await (_db.select(
      _db.consentGrants,
    )..where((tbl) => tbl.id.equals(id))).getSingle();
    return _mapConsent(row);
  }

  Future<DataGrantRequestRecord> createDataGrantRequest({
    required String creatorId,
    required String passportId,
    required List<String> fields,
    required String purpose,
    required String retention,
    required String valueExchange,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'data_grant_request',
    );
    if (existing != null) {
      final request = await dataGrantRequestById(existing);
      if (request != null) {
        return request;
      }
    }

    await ensureDemoPassport(passportId: passportId);
    final creator = await creatorById(creatorId);
    final now = _now();
    final id = 'data_request_${_slug(idempotencyKey)}';
    final defaultState = await categoryDefaultState(
      passportId: passportId,
      category: creator?.vertical ?? 'creator',
    );
    final state = defaultState == 'denied' ? 'denied' : 'pending';
    await _db
        .into(_db.audienceGrantRequests)
        .insertOnConflictUpdate(
          AudienceGrantRequestsCompanion.insert(
            id: id,
            creatorId: creatorId,
            creatorName: creator?.displayName ?? creatorId,
            passportId: passportId,
            fieldsJson: jsonEncode(fields),
            purpose: purpose,
            retention: retention,
            valueExchange: valueExchange,
            state: state,
            createdAt: now,
            updatedAt: now,
          ),
        );
    await _saveIdempotency(idempotencyKey, 'data_grant_request', id);
    return (await dataGrantRequestById(id))!;
  }

  Future<DataGrantRequestRecord?> dataGrantRequestById(String id) async {
    final row = await (_db.select(
      _db.audienceGrantRequests,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapDataGrantRequest(row);
  }

  Future<List<DataGrantRequestRecord>> pendingGrantRequests(
    String passportId,
  ) async {
    final rows =
        await (_db.select(_db.audienceGrantRequests)
              ..where((tbl) => tbl.passportId.equals(passportId))
              ..where((tbl) => tbl.state.equals('pending'))
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
            .get();
    return rows.map(_mapDataGrantRequest).toList(growable: false);
  }

  Future<DataConsentGrantRecord> reviewDataGrantRequest({
    required String requestId,
    required String passportId,
    required String state,
    required List<String> approvedFields,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(idempotencyKey, 'data_grant');
    if (existing != null) {
      final grant = await dataConsentGrantById(existing);
      if (grant != null) {
        return grant;
      }
    }

    final request = await dataGrantRequestById(requestId);
    if (request == null) {
      throw StateError('No data grant request exists for $requestId');
    }
    final allowedFields = request.fields.toSet();
    final fields = state == 'approved'
        ? approvedFields
              .where((field) => allowedFields.contains(field))
              .toList(growable: false)
        : const <String>[];
    final id = 'data_grant_${_slug(requestId)}_${_slug(passportId)}';
    final now = _now();
    await _db.transaction(() async {
      await _db
          .into(_db.dataConsentGrants)
          .insertOnConflictUpdate(
            DataConsentGrantsCompanion.insert(
              id: id,
              requestId: requestId,
              passportId: passportId,
              creatorId: request.creatorId,
              creatorName: request.creatorName,
              fieldsJson: jsonEncode(fields),
              purpose: request.purpose,
              retention: request.retention,
              valueExchange: request.valueExchange,
              state: state,
              updatedAt: now,
            ),
          );
      await (_db.update(
        _db.audienceGrantRequests,
      )..where((tbl) => tbl.id.equals(requestId))).write(
        AudienceGrantRequestsCompanion(
          state: Value(state),
          updatedAt: Value(now),
        ),
      );
      await _saveIdempotency(idempotencyKey, 'data_grant', id);
    });
    return (await dataConsentGrantById(id))!;
  }

  Future<DataConsentGrantRecord?> dataConsentGrantById(String id) async {
    final row = await (_db.select(
      _db.dataConsentGrants,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapDataConsentGrant(row);
  }

  Future<DataConsentGrantRecord> narrowDataGrant({
    required String grantId,
    required List<String> approvedFields,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(idempotencyKey, 'data_grant');
    if (existing != null) {
      final grant = await dataConsentGrantById(existing);
      if (grant != null) {
        return grant;
      }
    }
    final grant = await dataConsentGrantById(grantId);
    if (grant == null) {
      throw StateError('No data consent grant exists for $grantId');
    }
    final narrowed = approvedFields
        .where((field) => grant.fields.contains(field))
        .toList(growable: false);
    await (_db.update(
      _db.dataConsentGrants,
    )..where((tbl) => tbl.id.equals(grantId))).write(
      DataConsentGrantsCompanion(
        fieldsJson: Value(jsonEncode(narrowed)),
        state: const Value('approved'),
        updatedAt: Value(_now()),
      ),
    );
    await _saveIdempotency(idempotencyKey, 'data_grant', grantId);
    return (await dataConsentGrantById(grantId))!;
  }

  Future<DataConsentGrantRecord> revokeDataGrant({
    required String grantId,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(idempotencyKey, 'data_grant');
    if (existing != null) {
      final grant = await dataConsentGrantById(existing);
      if (grant != null) {
        return grant;
      }
    }
    await (_db.update(
      _db.dataConsentGrants,
    )..where((tbl) => tbl.id.equals(grantId))).write(
      DataConsentGrantsCompanion(
        state: const Value('revoked'),
        updatedAt: Value(_now()),
      ),
    );
    await _saveIdempotency(idempotencyKey, 'data_grant', grantId);
    return (await dataConsentGrantById(grantId))!;
  }

  Future<CategoryDefaultRecord> setCategoryDefault({
    required String passportId,
    required String category,
    required String state,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'category_default',
    );
    if (existing != null) {
      final row = await (_db.select(
        _db.categoryDefaults,
      )..where((tbl) => tbl.id.equals(existing))).getSingleOrNull();
      if (row != null) {
        return _mapCategoryDefault(row);
      }
    }
    await ensureDemoPassport(passportId: passportId);
    final id = 'category_default_${_slug(passportId)}_${_slug(category)}';
    await _db
        .into(_db.categoryDefaults)
        .insertOnConflictUpdate(
          CategoryDefaultsCompanion.insert(
            id: id,
            passportId: passportId,
            category: category,
            state: state,
            updatedAt: _now(),
          ),
        );
    await _saveIdempotency(idempotencyKey, 'category_default', id);
    final row = await (_db.select(
      _db.categoryDefaults,
    )..where((tbl) => tbl.id.equals(id))).getSingle();
    return _mapCategoryDefault(row);
  }

  Future<String?> categoryDefaultState({
    required String passportId,
    required String category,
  }) async {
    final row =
        await (_db.select(_db.categoryDefaults)
              ..where((tbl) => tbl.passportId.equals(passportId))
              ..where((tbl) => tbl.category.equals(category)))
            .getSingleOrNull();
    return row?.state;
  }

  Future<TombstoneRequestRecord> requestTombstone({
    required String passportId,
    required String creatorId,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(idempotencyKey, 'tombstone');
    if (existing != null) {
      final row = await (_db.select(
        _db.tombstones,
      )..where((tbl) => tbl.id.equals(existing))).getSingleOrNull();
      if (row != null) {
        return _mapTombstone(row);
      }
    }
    await ensureDemoPassport(passportId: passportId);
    final id = 'tombstone_${_slug(passportId)}_${_slug(creatorId)}';
    await _db
        .into(_db.tombstones)
        .insertOnConflictUpdate(
          TombstonesCompanion.insert(
            id: id,
            passportId: passportId,
            creatorId: creatorId,
            createdAt: _now(),
          ),
        );
    await _saveIdempotency(idempotencyKey, 'tombstone', id);
    return _mapTombstone(
      await (_db.select(
        _db.tombstones,
      )..where((tbl) => tbl.id.equals(id))).getSingle(),
    );
  }

  Future<PermissionedInterestDataRecord> queryPermissionedInterestData({
    required String creatorId,
    required String passportId,
    required String purpose,
    required String idempotencyKey,
  }) async {
    final rows =
        await (_db.select(_db.dataConsentGrants)
              ..where((tbl) => tbl.creatorId.equals(creatorId))
              ..where((tbl) => tbl.passportId.equals(passportId))
              ..where((tbl) => tbl.state.equals('approved'))
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAt)]))
            .get();
    if (rows.isEmpty) {
      return PermissionedInterestDataRecord(
        creatorId: creatorId,
        passportId: passportId,
        fields: const [],
        values: const {},
        receipt: DataAccessReceiptRecord(
          id: 'receipt_none_${_slug(passportId)}_${_slug(creatorId)}',
          passportId: passportId,
          creatorId: creatorId,
          creatorName: creatorId,
          grantId: 'none',
          fields: const [],
          purpose: purpose,
          accessedAt: _now(),
        ),
      );
    }
    final grant = _mapDataConsentGrant(rows.first);
    final profile = await interestProfile(passportId);
    final values = <String, List<String>>{};
    if (grant.fields.contains('interest_categories')) {
      values['interest_categories'] = profile.interests
          .map((interest) => interest.category)
          .toSet()
          .toList(growable: false);
    }
    if (grant.fields.contains('interest_tokens')) {
      values['interest_tokens'] = profile.interests
          .map((interest) => interest.label)
          .toList(growable: false);
    }
    final receipt = await _createDataAccessReceipt(
      passportId: passportId,
      creatorId: creatorId,
      creatorName: grant.creatorName,
      grantId: grant.id,
      fields: grant.fields,
      purpose: purpose,
      idempotencyKey: idempotencyKey,
    );
    return PermissionedInterestDataRecord(
      creatorId: creatorId,
      passportId: passportId,
      fields: grant.fields,
      values: values,
      receipt: receipt,
    );
  }

  Future<DataAccessReceiptRecord> _createDataAccessReceipt({
    required String passportId,
    required String creatorId,
    required String creatorName,
    required String grantId,
    required List<String> fields,
    required String purpose,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'data_access_receipt',
    );
    if (existing != null) {
      final row = await (_db.select(
        _db.dataAccessReceipts,
      )..where((tbl) => tbl.id.equals(existing))).getSingleOrNull();
      if (row != null) {
        return _mapDataAccessReceipt(row);
      }
    }
    final id = 'data_access_${_slug(idempotencyKey)}';
    await _db
        .into(_db.dataAccessReceipts)
        .insertOnConflictUpdate(
          DataAccessReceiptsCompanion.insert(
            id: id,
            passportId: passportId,
            creatorId: creatorId,
            creatorName: creatorName,
            grantId: grantId,
            fieldsJson: jsonEncode(fields),
            purpose: purpose,
            accessedAt: _now(),
          ),
        );
    await _saveIdempotency(idempotencyKey, 'data_access_receipt', id);
    final row = await (_db.select(
      _db.dataAccessReceipts,
    )..where((tbl) => tbl.id.equals(id))).getSingle();
    return _mapDataAccessReceipt(row);
  }

  Future<List<DataAccessReceiptRecord>> dataAccessReceiptsForPassport(
    String passportId,
  ) async {
    final rows =
        await (_db.select(_db.dataAccessReceipts)
              ..where((tbl) => tbl.passportId.equals(passportId))
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.accessedAt)]))
            .get();
    return rows.map(_mapDataAccessReceipt).toList(growable: false);
  }

  Future<AudienceInsightRecord> audienceInsight(String creatorId) async {
    final rows =
        await (_db.select(_db.dataConsentGrants)
              ..where((tbl) => tbl.creatorId.equals(creatorId))
              ..where((tbl) => tbl.state.equals('approved')))
            .get();
    final categories = <String>{};
    for (final row in rows) {
      final profile = await interestProfile(row.passportId);
      categories.addAll(profile.interests.map((interest) => interest.category));
    }
    return AudienceInsightRecord(
      creatorId: creatorId,
      approvedFanCount: rows.map((row) => row.passportId).toSet().length,
      topCategories: categories.take(4).toList(growable: false),
      permissionStatus: rows.isEmpty
          ? 'No approved grants'
          : 'Approved fields only',
      updatedAt: _now(),
    );
  }

  Future<List<InterestTokenRecord>> interestTaxonomy() async {
    final rows =
        await (_db.select(_db.interestTaxonomy)..orderBy([
              (tbl) => OrderingTerm.asc(tbl.category),
              (tbl) => OrderingTerm.asc(tbl.label),
            ]))
            .get();
    return rows.map(_mapInterestToken).toList(growable: false);
  }

  Future<InterestProfileRecord> interestProfile(String passportId) async {
    await _ensureInterestProfile(passportId);
    final row = await (_db.select(
      _db.fanInterestProfiles,
    )..where((tbl) => tbl.passportId.equals(passportId))).getSingle();
    return _mapInterestProfile(row);
  }

  Future<InterestProfileRecord> putInterests({
    required String passportId,
    required List<String> interestIds,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'interest_profile',
    );
    if (existing != null) {
      return interestProfile(existing);
    }

    await _ensureInterestProfile(passportId);
    await (_db.update(
      _db.fanInterestProfiles,
    )..where((tbl) => tbl.passportId.equals(passportId))).write(
      FanInterestProfilesCompanion(
        interestIdsJson: Value(jsonEncode(interestIds)),
        updatedAt: Value(_now()),
      ),
    );
    await _saveIdempotency(idempotencyKey, 'interest_profile', passportId);
    return interestProfile(passportId);
  }

  Future<InterestProfileRecord> putDislikes({
    required String passportId,
    required List<String> dislikedInterestIds,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'interest_profile',
    );
    if (existing != null) {
      return interestProfile(existing);
    }

    await _ensureInterestProfile(passportId);
    await (_db.update(
      _db.fanInterestProfiles,
    )..where((tbl) => tbl.passportId.equals(passportId))).write(
      FanInterestProfilesCompanion(
        dislikedInterestIdsJson: Value(jsonEncode(dislikedInterestIds)),
        updatedAt: Value(_now()),
      ),
    );
    await _saveIdempotency(idempotencyKey, 'interest_profile', passportId);
    return interestProfile(passportId);
  }

  Future<List<PlatformIntentRecord>> platformIntents() async {
    final rows = await (_db.select(
      _db.platformIntents,
    )..orderBy([(tbl) => OrderingTerm.asc(tbl.displayOrder)])).get();
    return rows.map(_mapPlatformIntent).toList(growable: false);
  }

  Future<PlatformIntentRecord?> platformIntentById(String id) async {
    final row = await (_db.select(
      _db.platformIntents,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapPlatformIntent(row);
  }

  Future<SessionIntentRecord> createSessionIntent({
    required String passportId,
    required String platformIntentId,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(idempotencyKey, 'session_intent');
    if (existing != null) {
      final session = await sessionIntentById(existing);
      if (session != null) {
        return session;
      }
    }

    await ensureDemoPassport(passportId: passportId);
    final intent = await platformIntentById(platformIntentId);
    if (intent == null) {
      throw StateError('No platform intent exists for $platformIntentId');
    }

    final id = 'session_${_slug(idempotencyKey)}';
    final now = _now();
    await _db.transaction(() async {
      await (_db.update(_db.sessionIntents)
            ..where((tbl) => tbl.passportId.equals(passportId)))
          .write(const SessionIntentsCompanion(active: Value(false)));
      await _db
          .into(_db.sessionIntents)
          .insertOnConflictUpdate(
            SessionIntentsCompanion.insert(
              id: id,
              passportId: passportId,
              platformIntentId: platformIntentId,
              selectedInterestIdsJson: jsonEncode(intent.interestIds),
              active: true,
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _saveIdempotency(idempotencyKey, 'session_intent', id);
    });
    return (await sessionIntentById(id))!;
  }

  Future<SessionIntentRecord?> sessionIntentById(String id) async {
    final row = await (_db.select(
      _db.sessionIntents,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapSessionIntent(row);
  }

  Future<SessionIntentRecord> switchSessionIntent({
    required String sessionIntentId,
    required String platformIntentId,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'session_intent_switch',
    );
    if (existing != null) {
      final session = await sessionIntentById(existing);
      if (session != null) {
        return session;
      }
    }

    final intent = await platformIntentById(platformIntentId);
    if (intent == null) {
      throw StateError('No platform intent exists for $platformIntentId');
    }

    await (_db.update(
      _db.sessionIntents,
    )..where((tbl) => tbl.id.equals(sessionIntentId))).write(
      SessionIntentsCompanion(
        platformIntentId: Value(platformIntentId),
        selectedInterestIdsJson: Value(jsonEncode(intent.interestIds)),
        active: const Value(true),
        updatedAt: Value(_now()),
      ),
    );
    await _saveIdempotency(
      idempotencyKey,
      'session_intent_switch',
      sessionIntentId,
    );
    return (await sessionIntentById(sessionIntentId))!;
  }

  Future<FanFeedbackRecord> recordFeedback({
    required String sessionIntentId,
    required String contentId,
    required String action,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(idempotencyKey, 'fan_feedback');
    if (existing != null) {
      final feedback = await feedbackById(existing);
      if (feedback != null) {
        return feedback;
      }
    }

    final session = await sessionIntentById(sessionIntentId);
    if (session == null) {
      throw StateError('No session intent exists for $sessionIntentId');
    }
    final content = await contentById(contentId);
    if (content == null) {
      throw StateError('No content exists for $contentId');
    }

    final id = 'feedback_${_slug(idempotencyKey)}';
    await _db.transaction(() async {
      await _db
          .into(_db.fanFeedback)
          .insertOnConflictUpdate(
            FanFeedbackCompanion.insert(
              id: id,
              sessionIntentId: sessionIntentId,
              passportId: session.passportId,
              contentId: contentId,
              creatorId: content.creatorId,
              action: action,
              createdAt: _now(),
            ),
          );
      await _applyFeedbackToProfile(
        passportId: session.passportId,
        creatorId: content.creatorId,
        action: action,
      );
      await _saveIdempotency(idempotencyKey, 'fan_feedback', id);
    });
    return (await feedbackById(id))!;
  }

  Future<FanFeedbackRecord?> feedbackById(String id) async {
    final row = await (_db.select(
      _db.fanFeedback,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapFanFeedback(row);
  }

  Future<List<FanFeedbackRecord>> feedbackForPassport(String passportId) async {
    final rows =
        await (_db.select(_db.fanFeedback)
              ..where((tbl) => tbl.passportId.equals(passportId))
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
            .get();
    return rows.map(_mapFanFeedback).toList(growable: false);
  }

  Future<List<ExternalProviderCandidateRecord>> externalCandidates({
    required List<String> interestIds,
    int limit = 8,
  }) async {
    final rows = await _db.select(_db.externalProviderCandidates).get();
    final ranked =
        rows
            .map(_mapExternalProviderCandidate)
            .where(
              (candidate) =>
                  interestIds.isEmpty ||
                  candidate.interestIds.any(interestIds.contains),
            )
            .toList()
          ..sort((a, b) => b.score.compareTo(a.score));
    return ranked.take(limit).toList(growable: false);
  }

  Future<List<SearchIndexEntryRecord>> searchIndex({
    required String query,
    int limit = 10,
    int offset = 0,
  }) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return const [];
    }

    final terms = normalized.split(RegExp(r'\s+'));
    final rows = await _db.select(_db.searchIndexEntries).get();
    final ranked =
        rows
            .map(_mapSearchIndexEntry)
            .where(
              (entry) => terms.every((term) => entry.searchText.contains(term)),
            )
            .toList()
          ..sort((a, b) => a.title.compareTo(b.title));
    return ranked.skip(offset).take(limit).toList(growable: false);
  }

  Future<AdPreferencesRecord> adPreferences(String passportId) async {
    await _ensureAdPreferences(passportId);
    final row = await (_db.select(
      _db.adPreferences,
    )..where((tbl) => tbl.passportId.equals(passportId))).getSingle();
    return AdPreferencesRecord(
      passportId: row.passportId,
      personalizedAds: row.personalizedAds,
      updatedAt: row.updatedAt,
    );
  }

  Future<AdPreferencesRecord> putAdPreferences({
    required String passportId,
    required bool personalizedAds,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(idempotencyKey, 'ad_preferences');
    if (existing != null) {
      return adPreferences(existing);
    }
    await ensureDemoPassport(passportId: passportId);
    await _db
        .into(_db.adPreferences)
        .insertOnConflictUpdate(
          AdPreferencesCompanion.insert(
            passportId: passportId,
            personalizedAds: personalizedAds,
            updatedAt: _now(),
          ),
        );
    await _saveIdempotency(idempotencyKey, 'ad_preferences', passportId);
    return adPreferences(passportId);
  }

  Future<RankPreferenceRecord> rankingPreference(String passportId) async {
    await _ensureRankingPreference(passportId);
    final row = await (_db.select(
      _db.fanRankingPreferences,
    )..where((tbl) => tbl.passportId.equals(passportId))).getSingle();
    return _mapRankPreference(row);
  }

  Future<RankPreferenceRecord> putRankingPreference({
    required String passportId,
    required bool summaryFirst,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'ranking_preference',
    );
    if (existing != null) {
      return rankingPreference(existing);
    }

    await _ensureRankingPreference(passportId);
    await (_db.update(
      _db.fanRankingPreferences,
    )..where((tbl) => tbl.passportId.equals(passportId))).write(
      FanRankingPreferencesCompanion(
        summaryFirst: Value(summaryFirst),
        updatedAt: Value(_now()),
      ),
    );
    await _saveIdempotency(idempotencyKey, 'ranking_preference', passportId);
    return rankingPreference(passportId);
  }

  Future<FollowRecord> createFollow({
    required String passportId,
    required String creatorId,
    required String visibility,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(idempotencyKey, 'follow');
    if (existing != null) {
      final follow = await followById(existing);
      if (follow != null) {
        return follow;
      }
    }

    final creator = await creatorById(creatorId);
    if (creator == null) {
      throw StateError('No creator exists for $creatorId');
    }

    final id = 'follow_${_slug(passportId)}_${_slug(creatorId)}';
    final now = _now();
    await _db
        .into(_db.follows)
        .insertOnConflictUpdate(
          FollowsCompanion.insert(
            id: id,
            passportId: passportId,
            creatorId: creatorId,
            visibility: visibility,
            blocked: false,
            createdAt: now,
            updatedAt: now,
          ),
        );
    await _saveIdempotency(idempotencyKey, 'follow', id);
    return (await followById(id))!;
  }

  Future<FollowRecord> setFollowVisibility({
    required String followId,
    required String visibility,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'follow_visibility',
    );
    if (existing != null) {
      final follow = await followById(existing);
      if (follow != null) {
        return follow;
      }
    }

    await (_db.update(
      _db.follows,
    )..where((tbl) => tbl.id.equals(followId))).write(
      FollowsCompanion(visibility: Value(visibility), updatedAt: Value(_now())),
    );
    await _saveIdempotency(idempotencyKey, 'follow_visibility', followId);
    return (await followById(followId))!;
  }

  Future<FollowRecord?> followById(String id) async {
    final follow = await (_db.select(
      _db.follows,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (follow == null) {
      return null;
    }
    final creator = await creatorById(follow.creatorId);
    return _mapFollow(follow, creatorDisplayName: creator?.displayName ?? '');
  }

  Future<List<FollowRecord>> followsForPassport(String passportId) async {
    final rows =
        await (_db.select(_db.follows)
              ..where((tbl) => tbl.passportId.equals(passportId))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
            .get();
    final records = <FollowRecord>[];
    for (final row in rows) {
      final creator = await creatorById(row.creatorId);
      records.add(
        _mapFollow(row, creatorDisplayName: creator?.displayName ?? ''),
      );
    }
    return records;
  }

  Future<FollowRecord?> followForPassportCreator({
    required String passportId,
    required String creatorId,
  }) async {
    final row =
        await (_db.select(_db.follows)..where(
              (tbl) =>
                  tbl.passportId.equals(passportId) &
                  tbl.creatorId.equals(creatorId),
            ))
            .getSingleOrNull();
    if (row == null) {
      return null;
    }
    final creator = await creatorById(row.creatorId);
    return _mapFollow(row, creatorDisplayName: creator?.displayName ?? '');
  }

  Future<FollowRecord?> unfollowCreator({
    required String passportId,
    required String creatorId,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(idempotencyKey, 'unfollow');
    if (existing != null) {
      return followById(existing);
    }

    final follow = await followForPassportCreator(
      passportId: passportId,
      creatorId: creatorId,
    );
    if (follow == null) {
      return null;
    }
    await (_db.delete(
      _db.follows,
    )..where((tbl) => tbl.id.equals(follow.id))).go();
    await _saveIdempotency(idempotencyKey, 'unfollow', follow.id);
    return null;
  }

  Future<FollowRecord> blockCreator({
    required String passportId,
    required String creatorId,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(idempotencyKey, 'block_creator');
    if (existing != null) {
      final follow = await followById(existing);
      if (follow != null) {
        return follow;
      }
    }

    await ensureDemoPassport(passportId: passportId);
    final follow =
        await followForPassportCreator(
          passportId: passportId,
          creatorId: creatorId,
        ) ??
        await createFollow(
          passportId: passportId,
          creatorId: creatorId,
          visibility: 'private',
          idempotencyKey: 'block-follow-$passportId-$creatorId',
        );
    await (_db.update(
      _db.follows,
    )..where((tbl) => tbl.id.equals(follow.id))).write(
      FollowsCompanion(blocked: const Value(true), updatedAt: Value(_now())),
    );
    await _applyFeedbackToProfile(
      passportId: passportId,
      creatorId: creatorId,
      action: 'block_creator',
    );
    await _saveIdempotency(idempotencyKey, 'block_creator', follow.id);
    return (await followById(follow.id))!;
  }

  Future<CreatorChannelRecord> createChannel({
    required String ownerPassportId,
    required String displayName,
    required String vertical,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(idempotencyKey, 'creator_channel');
    if (existing != null) {
      final channel = await creatorChannelById(existing);
      if (channel != null) {
        return channel;
      }
    }

    final id = 'channel_${_slug(idempotencyKey)}';
    await _db
        .into(_db.creatorChannels)
        .insertOnConflictUpdate(
          CreatorChannelsCompanion.insert(
            id: id,
            ownerPassportId: ownerPassportId,
            displayName: displayName,
            handle: '',
            vertical: vertical,
            createdAt: _now(),
          ),
        );
    await _db
        .into(_db.creators)
        .insertOnConflictUpdate(
          CreatorsCompanion.insert(
            id: id,
            handle: '',
            displayName: displayName,
            vertical: vertical,
            avatarRef: 'seed://avatars/$id',
          ),
        );
    await _saveIdempotency(idempotencyKey, 'creator_channel', id);
    return (await creatorChannelById(id))!;
  }

  Future<CreatorChannelRecord> bindHandle({
    required String channelId,
    required String handle,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(idempotencyKey, 'channel_handle');
    if (existing != null) {
      final channel = await creatorChannelById(existing);
      if (channel != null) {
        return channel;
      }
    }

    await (_db.update(
      _db.creatorChannels,
    )..where((tbl) => tbl.id.equals(channelId))).write(
      CreatorChannelsCompanion(handle: Value(_normalizeHandle(handle))),
    );
    await (_db.update(_db.creators)..where((tbl) => tbl.id.equals(channelId)))
        .write(CreatorsCompanion(handle: Value(_normalizeHandle(handle))));
    await _saveIdempotency(idempotencyKey, 'channel_handle', channelId);
    return (await creatorChannelById(channelId))!;
  }

  Future<CreatorChannelRecord?> creatorChannelById(String id) async {
    final row = await (_db.select(
      _db.creatorChannels,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapCreatorChannel(row);
  }

  Future<CreatorChannelManifestRecord> createChannelProfile({
    required String channelId,
    required String displayName,
    required String handle,
    required String description,
    required String category,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'channel_manifest',
    );
    if (existing != null) {
      final manifest = await channelManifest(existing);
      if (manifest != null) {
        return manifest;
      }
    }

    await _db
        .into(_db.channelManifests)
        .insertOnConflictUpdate(
          ChannelManifestsCompanion.insert(
            channelId: channelId,
            displayName: displayName,
            handle: _normalizeHandle(handle),
            description: description,
            category: category,
            createdAt: _now(),
          ),
        );
    await _ensureCreatorForChannel(
      channelId: channelId,
      displayName: displayName,
      handle: handle,
      vertical: category,
    );
    await _saveIdempotency(idempotencyKey, 'channel_manifest', channelId);
    return (await channelManifest(channelId))!;
  }

  Future<CreatorChannelManifestRecord?> channelManifest(
    String channelId,
  ) async {
    final row = await (_db.select(
      _db.channelManifests,
    )..where((tbl) => tbl.channelId.equals(channelId))).getSingleOrNull();
    return row == null ? null : _mapChannelManifest(row);
  }

  Future<HostingContractRecord> attachHostingContract({
    required String channelId,
    required String provider,
    required String termsVersion,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'hosting_contract',
    );
    if (existing != null) {
      final contract = await hostingContract(existing);
      if (contract != null) {
        return contract;
      }
    }

    final id = 'hosting_${_slug(channelId)}';
    await _db
        .into(_db.hostingContracts)
        .insertOnConflictUpdate(
          HostingContractsCompanion.insert(
            id: id,
            channelId: channelId,
            provider: provider,
            status: 'accepted',
            termsVersion: termsVersion,
            acceptedAt: _now(),
          ),
        );
    await _saveIdempotency(idempotencyKey, 'hosting_contract', id);
    return (await hostingContract(id))!;
  }

  Future<HostingContractRecord?> hostingContract(String id) async {
    final row = await (_db.select(
      _db.hostingContracts,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapHostingContract(row);
  }

  Future<ContentManifestRecord> publishContent({
    required String channelId,
    required String contentType,
    required String title,
    required String summary,
    required String thumbnailRef,
    required String accessMode,
    required String monetizationMode,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'content_manifest',
    );
    if (existing != null) {
      final manifest = await contentManifestById(existing);
      if (manifest != null) {
        return manifest;
      }
    }

    final channel = await creatorChannelById(channelId);
    await _ensureCreatorForChannel(
      channelId: channelId,
      displayName: channel?.displayName ?? 'Demo Creator',
      handle: channel?.handle ?? channelId,
      vertical: channel?.vertical ?? 'creator',
    );

    final id = 'content_${_slug(idempotencyKey)}';
    final existingManifest = await contentManifestById(id);
    final schemaVersion = (existingManifest?.schemaVersion ?? 0) + 1;
    final now = _now();
    await _db.transaction(() async {
      await _db
          .into(_db.contentItems)
          .insertOnConflictUpdate(
            ContentItemsCompanion.insert(
              id: id,
              creatorId: channelId,
              contentType: contentType,
              title: title,
              summary: summary,
              thumbnailRef: thumbnailRef,
              createdAt: now,
              perfVelocity: 0.54,
            ),
          );
      await _db
          .into(_db.contentManifests)
          .insertOnConflictUpdate(
            ContentManifestsCompanion.insert(
              id: id,
              channelId: channelId,
              contentType: contentType,
              title: title,
              summary: summary,
              accessMode: accessMode,
              monetizationMode: monetizationMode,
              thumbnailRef: thumbnailRef,
              schemaVersion: schemaVersion,
              createdAt: existingManifest?.createdAt ?? now,
              updatedAt: now,
            ),
          );
      await _db
          .into(_db.contentPerf)
          .insertOnConflictUpdate(
            ContentPerfCompanion.insert(
              contentId: id,
              velocity: 0.54,
              completionRate: 0.61,
              saves: 24,
              shares: 9,
              updatedAt: now,
            ),
          );
    });
    await _saveIdempotency(idempotencyKey, 'content_manifest', id);
    return (await contentManifestById(id))!;
  }

  Future<ContentManifestRecord?> contentManifestById(String id) async {
    final row = await (_db.select(
      _db.contentManifests,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapContentManifest(row);
  }

  Future<List<ContentManifestRecord>> contentManifests(String channelId) async {
    final rows =
        await (_db.select(_db.contentManifests)
              ..where((tbl) => tbl.channelId.equals(channelId))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
            .get();
    return rows.map(_mapContentManifest).toList(growable: false);
  }

  Future<MonetizationManifestRecord> updateMonetizationManifest({
    required String channelId,
    required bool membershipsEnabled,
    required List<String> memberOnlyContentIds,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'monetization_manifest',
    );
    if (existing != null) {
      final manifest = await monetizationManifest(existing);
      if (manifest != null) {
        return manifest;
      }
    }

    await _db
        .into(_db.monetizationManifests)
        .insertOnConflictUpdate(
          MonetizationManifestsCompanion.insert(
            channelId: channelId,
            membershipsEnabled: membershipsEnabled,
            memberOnlyContentIdsJson: jsonEncode(memberOnlyContentIds),
            updatedAt: _now(),
          ),
        );
    await _saveIdempotency(idempotencyKey, 'monetization_manifest', channelId);
    return (await monetizationManifest(channelId))!;
  }

  Future<MonetizationManifestRecord?> monetizationManifest(
    String channelId,
  ) async {
    final row = await (_db.select(
      _db.monetizationManifests,
    )..where((tbl) => tbl.channelId.equals(channelId))).getSingleOrNull();
    return row == null ? null : _mapMonetizationManifest(row);
  }

  Future<List<MembershipTierRecord>> defineMembershipTiers({
    required String channelId,
    required List<MembershipTierRecord> tiers,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'membership_tiers',
    );
    if (existing != null) {
      return membershipTiers(existing);
    }

    await _db.transaction(() async {
      await (_db.delete(
        _db.membershipTiers,
      )..where((tbl) => tbl.channelId.equals(channelId))).go();
      await _db.batch((batch) {
        batch.insertAll(
          _db.membershipTiers,
          tiers.map(
            (tier) => MembershipTiersCompanion.insert(
              id: tier.id,
              channelId: channelId,
              name: tier.name,
              monthlyPriceCents: tier.monthlyPriceCents,
              benefitsJson: jsonEncode(tier.benefits),
              entitlementCode: tier.entitlementCode,
              createdAt: tier.createdAt,
            ),
          ),
        );
      });
    });
    await _saveIdempotency(idempotencyKey, 'membership_tiers', channelId);
    return membershipTiers(channelId);
  }

  Future<List<MembershipTierRecord>> membershipTiers(String channelId) async {
    final rows =
        await (_db.select(_db.membershipTiers)
              ..where((tbl) => tbl.channelId.equals(channelId))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.monthlyPriceCents)]))
            .get();
    return rows.map(_mapMembershipTier).toList(growable: false);
  }

  Future<CreatorAdPolicyRecord> setCreatorAdPolicy({
    required String channelId,
    required List<String> allowedCategories,
    required List<String> blockedCategories,
    required List<String> formats,
    required List<String> surfaces,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'creator_ad_policy',
    );
    if (existing != null) {
      final policy = await creatorAdPolicy(existing);
      if (policy != null) {
        return policy;
      }
    }

    await _db
        .into(_db.creatorAdPolicies)
        .insertOnConflictUpdate(
          CreatorAdPoliciesCompanion.insert(
            channelId: channelId,
            allowedCategoriesJson: jsonEncode(allowedCategories),
            blockedCategoriesJson: jsonEncode(blockedCategories),
            formatsJson: jsonEncode(formats),
            surfacesJson: jsonEncode(surfaces),
            updatedAt: _now(),
          ),
        );
    await _saveIdempotency(idempotencyKey, 'creator_ad_policy', channelId);
    return (await creatorAdPolicy(channelId))!;
  }

  Future<CreatorAdPolicyRecord?> creatorAdPolicy(String channelId) async {
    final row = await (_db.select(
      _db.creatorAdPolicies,
    )..where((tbl) => tbl.channelId.equals(channelId))).getSingleOrNull();
    return row == null ? null : _mapCreatorAdPolicy(row);
  }

  Future<AiContentPolicyRecord> setAiContentPolicy({
    required String channelId,
    required bool archiveQaEnabled,
    required bool summariesEnabled,
    required bool citationRequired,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'ai_content_policy',
    );
    if (existing != null) {
      final policy = await aiContentPolicy(existing);
      if (policy != null) {
        return policy;
      }
    }

    await _db
        .into(_db.aiContentPolicies)
        .insertOnConflictUpdate(
          AiContentPoliciesCompanion.insert(
            channelId: channelId,
            archiveQaEnabled: archiveQaEnabled,
            summariesEnabled: summariesEnabled,
            citationRequired: citationRequired,
            updatedAt: _now(),
          ),
        );
    await _saveIdempotency(idempotencyKey, 'ai_content_policy', channelId);
    return (await aiContentPolicy(channelId))!;
  }

  Future<AiContentPolicyRecord?> aiContentPolicy(String channelId) async {
    final row = await (_db.select(
      _db.aiContentPolicies,
    )..where((tbl) => tbl.channelId.equals(channelId))).getSingleOrNull();
    return row == null ? null : _mapAiContentPolicy(row);
  }

  Future<ImportJobRecord> startImportJob({
    required String channelId,
    required String sourcePlatform,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(idempotencyKey, 'import_job');
    if (existing != null) {
      final job = await importJob(existing);
      if (job != null) {
        return job;
      }
    }

    final id = 'import_${_slug(idempotencyKey)}';
    final now = _now();
    await _db
        .into(_db.importJobs)
        .insertOnConflictUpdate(
          ImportJobsCompanion.insert(
            id: id,
            channelId: channelId,
            sourcePlatform: sourcePlatform,
            state: 'processing',
            pollCount: 0,
            itemsJson: jsonEncode(_sampleImportItems),
            createdAt: now,
            updatedAt: now,
          ),
        );
    await _saveIdempotency(idempotencyKey, 'import_job', id);
    return (await importJob(id))!;
  }

  Future<ImportJobRecord?> importJob(String id) async {
    final row = await (_db.select(
      _db.importJobs,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (row == null) {
      return null;
    }
    final refs =
        await (_db.select(_db.externalContentRefs)
              ..where((tbl) => tbl.jobId.equals(id))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
            .get();
    return _mapImportJob(
      row,
      refs.map(_mapExternalRef).toList(growable: false),
    );
  }

  Future<ImportJobRecord> advanceImportJob(String id) async {
    final row = await (_db.select(
      _db.importJobs,
    )..where((tbl) => tbl.id.equals(id))).getSingle();
    if (row.state == 'complete') {
      return (await importJob(id))!;
    }

    final now = _now();
    await _db.transaction(() async {
      await (_db.update(
        _db.importJobs,
      )..where((tbl) => tbl.id.equals(id))).write(
        ImportJobsCompanion(
          state: const Value('complete'),
          pollCount: Value(row.pollCount + 1),
          updatedAt: Value(now),
        ),
      );
      final items = _decodeImportItems(row.itemsJson);
      for (final item in items) {
        final contentId = 'external_${_slug(id)}_${_slug(item.externalId)}';
        await _ensureCreatorForChannel(
          channelId: row.channelId,
          displayName: 'Demo Creator',
          handle: row.channelId,
          vertical: 'creator',
        );
        await _db
            .into(_db.contentItems)
            .insertOnConflictUpdate(
              ContentItemsCompanion.insert(
                id: contentId,
                creatorId: row.channelId,
                contentType: item.contentType,
                title: item.title,
                summary: item.summary,
                thumbnailRef: item.thumbnailRef,
                createdAt: now,
                perfVelocity: 0.49,
              ),
            );
        await _db
            .into(_db.contentManifests)
            .insertOnConflictUpdate(
              ContentManifestsCompanion.insert(
                id: contentId,
                channelId: row.channelId,
                contentType: item.contentType,
                title: item.title,
                summary: item.summary,
                accessMode: 'public',
                monetizationMode: 'free',
                thumbnailRef: item.thumbnailRef,
                schemaVersion: 1,
                createdAt: now,
                updatedAt: now,
              ),
            );
        await _db
            .into(_db.externalContentRefs)
            .insertOnConflictUpdate(
              ExternalContentRefsCompanion.insert(
                id: 'xref_${_slug(id)}_${_slug(item.externalId)}',
                jobId: id,
                channelId: row.channelId,
                sourcePlatform: row.sourcePlatform,
                externalId: item.externalId,
                contentId: contentId,
                title: item.title,
                summary: item.summary,
                createdAt: now,
              ),
            );
      }
    });
    return (await importJob(id))!;
  }

  Future<List<EntitlementDefinitionRecord>> registerEntitlements({
    required String channelId,
    required List<MembershipTierRecord> tiers,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'entitlement_definitions',
    );
    if (existing != null) {
      return entitlementDefinitions(existing);
    }

    await _db.transaction(() async {
      await (_db.delete(
        _db.entitlementDefinitions,
      )..where((tbl) => tbl.channelId.equals(channelId))).go();
      await _db.batch((batch) {
        batch.insertAll(
          _db.entitlementDefinitions,
          tiers.map(
            (tier) => EntitlementDefinitionsCompanion.insert(
              id: 'ent_${_slug(tier.id)}',
              channelId: channelId,
              tierId: tier.id,
              code: tier.entitlementCode,
              createdAt: _now(),
            ),
          ),
        );
      });
    });
    await _saveIdempotency(
      idempotencyKey,
      'entitlement_definitions',
      channelId,
    );
    return entitlementDefinitions(channelId);
  }

  Future<List<EntitlementDefinitionRecord>> entitlementDefinitions(
    String channelId,
  ) async {
    final rows =
        await (_db.select(_db.entitlementDefinitions)
              ..where((tbl) => tbl.channelId.equals(channelId))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.code)]))
            .get();
    return rows.map(_mapEntitlementDefinition).toList(growable: false);
  }

  Future<WalletRecord> wallet(String passportId) async {
    await _ensureWallet(passportId);
    final row = await (_db.select(
      _db.wallets,
    )..where((tbl) => tbl.passportId.equals(passportId))).getSingle();
    final subscriptions = await subscriptionsForPassport(passportId);
    final entitlementCodes = await activeEntitlementCodes(passportId);
    return WalletRecord(
      passportId: row.passportId,
      currency: row.currency,
      simulatedBalanceCents: row.simulatedBalanceCents,
      hasNoAdsPremium: entitlementCodes.contains('premium_no_ads'),
      subscriptions: subscriptions,
      updatedAt: row.updatedAt,
    );
  }

  Future<PaymentIntentRecord> createPaymentIntent({
    required String passportId,
    required String kind,
    String? creatorId,
    String? tierId,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(idempotencyKey, 'payment_intent');
    if (existing != null) {
      final intent = await paymentIntentById(existing);
      if (intent != null) {
        return intent;
      }
    }

    await _ensureWallet(passportId);
    final now = _now();
    final id = 'pi_${_slug(idempotencyKey)}';
    String? resolvedCreatorId;
    String? resolvedCreatorName;
    String? resolvedTierId;
    String? resolvedTierName;
    var amountCents = 499;

    if (kind == 'creatorMembership') {
      resolvedCreatorId = creatorId ?? 'creator_solar_sarah';
      final creator = await creatorById(resolvedCreatorId);
      resolvedCreatorName = creator?.displayName ?? 'Solar Sarah';
      final tiers = await membershipTiers(resolvedCreatorId);
      MembershipTierRecord? tier;
      for (final candidate in tiers) {
        if (candidate.id == tierId) {
          tier = candidate;
          break;
        }
      }
      tier ??= tiers.isEmpty
          ? MembershipTierRecord(
              id: 'tier_solar_supporter',
              channelId: resolvedCreatorId,
              name: 'Solar Supporter',
              monthlyPriceCents: 799,
              benefits: const [
                'Member-only posts',
                'Early archive Q&A',
                'Supporter badge',
              ],
              entitlementCode: 'membership:creator_solar_sarah',
              createdAt: now,
            )
          : tiers.first;
      resolvedTierId = tier.id;
      resolvedTierName = tier.name;
      amountCents = tier.monthlyPriceCents;
    }

    await _db
        .into(_db.paymentIntents)
        .insertOnConflictUpdate(
          PaymentIntentsCompanion.insert(
            id: id,
            passportId: passportId,
            kind: kind,
            creatorId: Value(resolvedCreatorId),
            creatorName: Value(resolvedCreatorName),
            tierId: Value(resolvedTierId),
            tierName: Value(resolvedTierName),
            amountCents: amountCents,
            currency: 'USD',
            status: 'requiresConfirmation',
            createdAt: now,
          ),
        );
    await _saveIdempotency(idempotencyKey, 'payment_intent', id);
    return (await paymentIntentById(id))!;
  }

  Future<PaymentIntentRecord> confirmPaymentIntent({
    required String paymentIntentId,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'payment_confirmation',
    );
    if (existing != null) {
      return (await paymentIntentById(existing))!;
    }

    final intent = await paymentIntentById(paymentIntentId);
    if (intent == null) {
      throw StateError('No payment intent exists for $paymentIntentId');
    }
    if (intent.status == 'succeeded') {
      await _saveIdempotency(
        idempotencyKey,
        'payment_confirmation',
        paymentIntentId,
      );
      return intent;
    }

    final now = _now();
    await _db.transaction(() async {
      await (_db.update(
        _db.paymentIntents,
      )..where((tbl) => tbl.id.equals(paymentIntentId))).write(
        PaymentIntentsCompanion(
          status: const Value('succeeded'),
          confirmedAt: Value(now),
        ),
      );
      final walletRow = await (_db.select(
        _db.wallets,
      )..where((tbl) => tbl.passportId.equals(intent.passportId))).getSingle();
      await (_db.update(
        _db.wallets,
      )..where((tbl) => tbl.passportId.equals(intent.passportId))).write(
        WalletsCompanion(
          simulatedBalanceCents: Value(
            walletRow.simulatedBalanceCents - intent.amountCents,
          ),
          updatedAt: Value(now),
        ),
      );

      if (intent.kind == 'noAdsPremium') {
        await _insertEntitlementGrant(
          passportId: intent.passportId,
          code: 'premium_no_ads',
          sourcePaymentIntentId: intent.id,
          idempotencyKey: 'grant_${intent.id}_premium',
        );
      } else {
        final creatorId = intent.creatorId ?? 'creator_solar_sarah';
        final creatorName = intent.creatorName ?? 'Solar Sarah';
        final tierId = intent.tierId ?? 'tier_solar_supporter';
        final tierName = intent.tierName ?? 'Solar Supporter';
        await _insertEntitlementGrant(
          passportId: intent.passportId,
          code: 'membership:$creatorId',
          creatorId: creatorId,
          sourcePaymentIntentId: intent.id,
          idempotencyKey: 'grant_${intent.id}_membership',
        );
        await _db
            .into(_db.subscriptions)
            .insertOnConflictUpdate(
              SubscriptionsCompanion.insert(
                id: 'sub_${_slug(intent.passportId)}_${_slug(creatorId)}',
                passportId: intent.passportId,
                creatorId: creatorId,
                creatorName: creatorName,
                tierId: tierId,
                tierName: tierName,
                monthlyPriceCents: intent.amountCents,
                active: true,
                startedAt: now,
              ),
            );
      }

      final contentId = await _receiptContentIdForCreator(intent.creatorId);
      await _db.batch((batch) {
        batch.insertAllOnConflictUpdate(_db.receipts, [
          ReceiptsCompanion.insert(
            id: 'receipt_payment_${_slug(intent.id)}',
            type: 'payment',
            passportId: intent.passportId,
            contentId: contentId,
            authorizationId: intent.id,
            summary:
                'Simulated ${intent.kind == 'noAdsPremium' ? 'no-ad premium' : 'creator membership'} payment confirmed.',
            createdAt: now,
          ),
          ReceiptsCompanion.insert(
            id: intent.kind == 'noAdsPremium'
                ? 'receipt_no_ad_${_slug(intent.id)}'
                : 'receipt_membership_${_slug(intent.id)}',
            type: intent.kind == 'noAdsPremium' ? 'premiumNoAd' : 'membership',
            passportId: intent.passportId,
            contentId: contentId,
            authorizationId: intent.id,
            summary: intent.kind == 'noAdsPremium'
                ? 'Premium no-ad entitlement is active across eligible playback.'
                : 'Creator membership is active for ${intent.creatorName ?? 'the creator'}.',
            createdAt: now,
          ),
        ]);
      });
      await _saveIdempotency(
        idempotencyKey,
        'payment_confirmation',
        paymentIntentId,
      );
    });

    return (await paymentIntentById(paymentIntentId))!;
  }

  Future<PaymentIntentRecord?> paymentIntentById(String id) async {
    final row = await (_db.select(
      _db.paymentIntents,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapPaymentIntent(row);
  }

  Future<List<PaymentIntentRecord>> confirmedPaymentIntents({
    String? creatorId,
  }) async {
    final query = _db.select(_db.paymentIntents)
      ..where((tbl) => tbl.status.equals('succeeded'));
    if (creatorId != null) {
      query.where((tbl) => tbl.creatorId.equals(creatorId));
    }
    final rows = await query.get();
    return rows.map(_mapPaymentIntent).toList(growable: false);
  }

  Future<List<SubscriptionRecord>> subscriptionsForPassport(
    String passportId,
  ) async {
    final rows =
        await (_db.select(_db.subscriptions)
              ..where((tbl) => tbl.passportId.equals(passportId))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.creatorName)]))
            .get();
    return rows.map(_mapSubscription).toList(growable: false);
  }

  Future<EntitlementGrantRecord> grantEntitlement({
    required String passportId,
    required String code,
    required String sourcePaymentIntentId,
    required String idempotencyKey,
    String? creatorId,
  }) async {
    await _ensureWallet(passportId);
    return _insertEntitlementGrant(
      passportId: passportId,
      code: code,
      creatorId: creatorId,
      sourcePaymentIntentId: sourcePaymentIntentId,
      idempotencyKey: idempotencyKey,
    );
  }

  Future<EntitlementGrantRecord> _insertEntitlementGrant({
    required String passportId,
    required String code,
    required String sourcePaymentIntentId,
    required String idempotencyKey,
    String? creatorId,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'entitlement_grant',
    );
    if (existing != null) {
      final grant = await entitlementGrantById(existing);
      if (grant != null) {
        return grant;
      }
    }

    final id =
        'grant_${_slug(passportId)}_${_slug(code)}_${_slug(sourcePaymentIntentId)}';
    await _db
        .into(_db.entitlementGrants)
        .insertOnConflictUpdate(
          EntitlementGrantsCompanion.insert(
            id: id,
            passportId: passportId,
            code: code,
            creatorId: Value(creatorId),
            sourcePaymentIntentId: sourcePaymentIntentId,
            active: true,
            grantedAt: _now(),
          ),
        );
    await _saveIdempotency(idempotencyKey, 'entitlement_grant', id);
    return (await entitlementGrantById(id))!;
  }

  Future<EntitlementGrantRecord?> entitlementGrantById(String id) async {
    final row = await (_db.select(
      _db.entitlementGrants,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapEntitlementGrant(row);
  }

  Future<Set<String>> activeEntitlementCodes(String passportId) async {
    final rows =
        await (_db.select(_db.entitlementGrants)
              ..where((tbl) => tbl.passportId.equals(passportId))
              ..where((tbl) => tbl.active.equals(true)))
            .get();
    return rows.map((row) => row.code).toSet();
  }

  Future<List<EntitlementGrantRecord>> activeEntitlements({
    required String passportId,
    required List<String> codes,
  }) async {
    final rows =
        await (_db.select(_db.entitlementGrants)
              ..where((tbl) => tbl.passportId.equals(passportId))
              ..where((tbl) => tbl.active.equals(true)))
            .get();
    final allowed = codes.toSet();
    return rows
        .where((row) => allowed.contains(row.code))
        .map(_mapEntitlementGrant)
        .toList(growable: false);
  }

  Future<String> runSettlement({required String idempotencyKey}) async {
    final existing = await _idempotentTarget(idempotencyKey, 'settlement_run');
    if (existing != null) {
      return existing;
    }

    final runId = 'settlement_${_slug(idempotencyKey)}';
    final now = _now();
    await _db.transaction(() async {
      await _db
          .into(_db.settlementRuns)
          .insertOnConflictUpdate(
            SettlementRunsCompanion.insert(
              id: runId,
              status: 'complete',
              createdAt: now,
            ),
          );

      final creators = await this.creators();
      for (final creator in creators) {
        final statement = await _computeCreatorPayout(
          runId: runId,
          creator: creator,
        );
        await _db
            .into(_db.payoutStatements)
            .insertOnConflictUpdate(
              PayoutStatementsCompanion.insert(
                id: statement.id,
                runId: runId,
                creatorId: statement.creatorId,
                creatorName: statement.creatorName,
                totalCents: statement.totalCents,
                bySourceJson: jsonEncode(
                  statement.bySource.map(_breakdownToJson).toList(),
                ),
                byIntentJson: jsonEncode(
                  statement.byIntent.map(_breakdownToJson).toList(),
                ),
                recentReceiptsJson: jsonEncode(
                  statement.recentReceipts.map(_receiptToJson).toList(),
                ),
                updatedAt: statement.updatedAt,
              ),
            );
      }

      final passports = await _db.select(_db.fanPassports).get();
      for (final passport in passports) {
        final statement = await _computeAllocationStatement(passport.id);
        await _db
            .into(_db.allocationStatements)
            .insertOnConflictUpdate(
              AllocationStatementsCompanion.insert(
                id: statement.id,
                passportId: statement.passportId,
                totalCents: statement.totalCents,
                allocationsJson: jsonEncode(
                  statement.allocations.map(_allocationToJson).toList(),
                ),
                updatedAt: statement.updatedAt,
              ),
            );
      }
      await _saveIdempotency(idempotencyKey, 'settlement_run', runId);
    });
    return runId;
  }

  Future<CreatorPayoutStatementRecord> creatorPayoutStatement(
    String creatorId,
  ) async {
    final row =
        await (_db.select(_db.payoutStatements)
              ..where((tbl) => tbl.creatorId.equals(creatorId))
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAt)])
              ..limit(1))
            .getSingleOrNull();
    if (row != null) {
      return _mapPayoutStatement(row);
    }
    await runSettlement(idempotencyKey: 'auto_settlement_$creatorId');
    final fallback =
        await (_db.select(_db.payoutStatements)
              ..where((tbl) => tbl.creatorId.equals(creatorId))
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAt)])
              ..limit(1))
            .getSingleOrNull();
    if (fallback != null) {
      return _mapPayoutStatement(fallback);
    }
    final creator = await creatorById(creatorId);
    return CreatorPayoutStatementRecord(
      id: 'payout_empty_${_slug(creatorId)}',
      creatorId: creatorId,
      creatorName: creator?.displayName ?? creatorId,
      totalCents: 0,
      bySource: const [],
      byIntent: const [],
      recentReceipts: const [],
      updatedAt: _now(),
    );
  }

  Future<FanAllocationStatementRecord> allocationStatement(
    String passportId,
  ) async {
    final row =
        await (_db.select(_db.allocationStatements)
              ..where((tbl) => tbl.passportId.equals(passportId))
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAt)]))
            .getSingleOrNull();
    if (row != null) {
      return _mapAllocationStatement(row);
    }
    await runSettlement(idempotencyKey: 'auto_allocation_$passportId');
    final fallback =
        await (_db.select(_db.allocationStatements)
              ..where((tbl) => tbl.passportId.equals(passportId))
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAt)]))
            .getSingleOrNull();
    return fallback == null
        ? await _computeAllocationStatement(passportId)
        : _mapAllocationStatement(fallback);
  }

  Future<ContentPerformanceRecord> contentPerformance(String contentId) async {
    final row = await (_db.select(
      _db.contentPerf,
    )..where((tbl) => tbl.contentId.equals(contentId))).getSingleOrNull();
    if (row != null) {
      return _mapContentPerformance(row);
    }
    return ContentPerformanceRecord(
      contentId: contentId,
      velocity: 0.42,
      completionRate: 0.58,
      saves: 0,
      shares: 0,
      updatedAt: _now(),
    );
  }

  Future<List<AdInventoryRecord>> adInventory({
    required List<String> allowedCategories,
    required List<String> blockedCategories,
    String surface = 'watch',
  }) async {
    final rows = await _db.select(_db.adInventory).get();
    final allowed = allowedCategories.toSet();
    final blocked = blockedCategories.toSet();
    final ads =
        rows
            .map(_mapAdInventory)
            .where(
              (ad) =>
                  ad.surfaces.contains(surface) &&
                  (allowed.isEmpty || allowed.contains(ad.category)) &&
                  !blocked.contains(ad.category),
            )
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    return ads;
  }

  Future<PlaybackTokenRecord> createPlaybackToken({
    required String passportId,
    required String contentId,
    required Map<String, Object?> adPlan,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(idempotencyKey, 'playback_token');
    if (existing != null) {
      final token = await playbackToken(existing);
      if (token != null) {
        return token;
      }
    }

    await ensureDemoPassport(passportId: passportId);
    final id = 'playback_${_slug(idempotencyKey)}';
    final now = _now();
    await _db
        .into(_db.playbackTokens)
        .insertOnConflictUpdate(
          PlaybackTokensCompanion.insert(
            id: id,
            passportId: passportId,
            contentId: contentId,
            token: 'token_${_slug(id)}',
            adPlanJson: jsonEncode(adPlan),
            completed: false,
            createdAt: now,
            expiresAt: now.add(const Duration(hours: 2)),
          ),
        );
    await _saveIdempotency(idempotencyKey, 'playback_token', id);
    return (await playbackToken(id))!;
  }

  Future<PlaybackTokenRecord?> playbackToken(String id) async {
    final row = await (_db.select(
      _db.playbackTokens,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapPlaybackToken(row);
  }

  Future<List<ReceiptRecord>> completePlayback({
    required String authorizationId,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'playback_completion',
    );
    if (existing != null) {
      return receiptsForAuthorization(existing);
    }

    final token = await playbackToken(authorizationId);
    if (token == null) {
      throw StateError('No playback authorization exists for $authorizationId');
    }

    await _db.transaction(() async {
      await (_db.update(_db.playbackTokens)
            ..where((tbl) => tbl.id.equals(authorizationId)))
          .write(const PlaybackTokensCompanion(completed: Value(true)));
      final receipts = _receiptCompanionsForToken(token);
      await _db.batch((batch) {
        batch.insertAllOnConflictUpdate(_db.receipts, receipts);
      });
      await _saveIdempotency(
        idempotencyKey,
        'playback_completion',
        authorizationId,
      );
    });
    return receiptsForAuthorization(authorizationId);
  }

  Future<List<ReceiptRecord>> ingestReceipts({
    required List<ReceiptRecord> records,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(idempotencyKey, 'receipts');
    if (existing != null) {
      return receiptsForPassport(existing);
    }
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.receipts,
        records.map(
          (record) => ReceiptsCompanion.insert(
            id: record.id,
            type: record.type,
            passportId: record.passportId,
            contentId: record.contentId,
            authorizationId: record.authorizationId,
            summary: record.summary,
            createdAt: record.createdAt,
          ),
        ),
      );
    });
    if (records.isNotEmpty) {
      await _saveIdempotency(
        idempotencyKey,
        'receipts',
        records.first.passportId,
      );
    }
    return records;
  }

  Future<List<ReceiptRecord>> receiptsForAuthorization(
    String authorizationId,
  ) async {
    final rows =
        await (_db.select(_db.receipts)
              ..where((tbl) => tbl.authorizationId.equals(authorizationId))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.type)]))
            .get();
    return rows.map(_mapReceipt).toList(growable: false);
  }

  Future<List<ReceiptRecord>> receiptsForPassport(String passportId) async {
    final rows =
        await (_db.select(_db.receipts)
              ..where((tbl) => tbl.passportId.equals(passportId))
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
            .get();
    return rows.map(_mapReceipt).toList(growable: false);
  }

  Future<List<ReceiptRecord>> receiptsForContent(String contentId) async {
    final rows =
        await (_db.select(_db.receipts)
              ..where((tbl) => tbl.contentId.equals(contentId))
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
            .get();
    return rows.map(_mapReceipt).toList(growable: false);
  }

  Future<void> _ensureWallet(String passportId) async {
    await ensureDemoPassport(passportId: passportId);
    await _db
        .into(_db.wallets)
        .insert(
          WalletsCompanion.insert(
            passportId: passportId,
            currency: 'USD',
            simulatedBalanceCents: 50000,
            updatedAt: _now(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<String> _receiptContentIdForCreator(String? creatorId) async {
    if (creatorId != null) {
      final creatorContent =
          await (_db.select(_db.contentItems)
                ..where((tbl) => tbl.creatorId.equals(creatorId))
                ..limit(1))
              .getSingleOrNull();
      if (creatorContent != null) {
        return creatorContent.id;
      }
    }
    final first = await (_db.select(
      _db.contentItems,
    )..limit(1)).getSingleOrNull();
    return first?.id ?? 'content_solar_001';
  }

  Future<List<ReceiptRecord>> _receiptsForCreator(String creatorId) async {
    final contentRows = await (_db.select(
      _db.contentItems,
    )..where((tbl) => tbl.creatorId.equals(creatorId))).get();
    final contentIds = contentRows.map((row) => row.id).toSet();
    final rows = await (_db.select(
      _db.receipts,
    )..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)])).get();
    return rows
        .where((row) => contentIds.contains(row.contentId))
        .map(_mapReceipt)
        .toList(growable: false);
  }

  Future<CreatorPayoutStatementRecord> _computeCreatorPayout({
    required String runId,
    required CreatorRecord creator,
  }) async {
    final intents = await confirmedPaymentIntents(creatorId: creator.id);
    final membershipPayments = intents
        .where((intent) => intent.kind == 'creatorMembership')
        .fold<int>(0, (total, intent) => total + intent.amountCents);
    final receipts = await _receiptsForCreator(creator.id);
    final seededMembership =
        receipts.any(
          (receipt) =>
              receipt.id == 'receipt_seed_membership_creator-solar-sarah',
        )
        ? 799
        : 0;
    final noAdPool =
        creator.id == 'creator_solar_sarah' &&
            receipts.any((receipt) => receipt.type == 'premiumNoAd')
        ? 200
        : 0;
    final referralTotal =
        receipts.where((receipt) => receipt.type == 'referral').length * 350;
    final membershipTotal = membershipPayments + seededMembership;
    final total = membershipTotal + noAdPool + referralTotal;
    final bySource = [
      if (membershipTotal > 0)
        RevenueBreakdownRecord(
          label: 'Memberships',
          amountCents: membershipTotal,
        ),
      if (noAdPool > 0)
        RevenueBreakdownRecord(label: 'No-ad pool', amountCents: noAdPool),
      if (referralTotal > 0)
        RevenueBreakdownRecord(label: 'Referrals', amountCents: referralTotal),
    ];
    final byIntent = [
      if (membershipTotal > 0)
        RevenueBreakdownRecord(label: 'Support', amountCents: membershipTotal),
      if (noAdPool > 0)
        RevenueBreakdownRecord(label: 'Watch', amountCents: noAdPool),
      if (referralTotal > 0)
        RevenueBreakdownRecord(label: 'Discovery', amountCents: referralTotal),
    ];
    return CreatorPayoutStatementRecord(
      id: 'payout_${_slug(runId)}_${_slug(creator.id)}',
      creatorId: creator.id,
      creatorName: creator.displayName,
      totalCents: total,
      bySource: bySource,
      byIntent: byIntent,
      recentReceipts: receipts.take(6).toList(growable: false),
      updatedAt: _now(),
    );
  }

  Future<FanAllocationStatementRecord> _computeAllocationStatement(
    String passportId,
  ) async {
    await _ensureWallet(passportId);
    final subscriptions = await subscriptionsForPassport(passportId);
    final allocations = subscriptions
        .where((subscription) => subscription.active)
        .map(
          (subscription) => AllocationLineRecord(
            creatorId: subscription.creatorId,
            creatorName: subscription.creatorName,
            amountCents: subscription.monthlyPriceCents,
            reason:
                '${subscription.tierName} membership funds member posts, archive Q&A, and creator-owned hosting.',
          ),
        )
        .toList(growable: false);
    return FanAllocationStatementRecord(
      id: 'allocation_${_slug(passportId)}',
      passportId: passportId,
      totalCents: allocations.fold<int>(
        0,
        (total, line) => total + line.amountCents,
      ),
      allocations: allocations,
      updatedAt: _now(),
    );
  }

  Future<void> _ensureCreatorForChannel({
    required String channelId,
    required String displayName,
    required String handle,
    required String vertical,
  }) {
    return _db
        .into(_db.creators)
        .insertOnConflictUpdate(
          CreatorsCompanion.insert(
            id: channelId,
            handle: _normalizeHandle(handle),
            displayName: displayName,
            vertical: vertical,
            avatarRef: 'seed://avatars/$channelId',
          ),
        );
  }

  Future<void> _ensureInterestProfile(String passportId) async {
    await _db
        .into(_db.fanInterestProfiles)
        .insert(
          FanInterestProfilesCompanion.insert(
            passportId: passportId,
            interestIdsJson: '[]',
            dislikedInterestIdsJson: '[]',
            dislikedCreatorIdsJson: '[]',
            mutedProviderIdsJson: '[]',
            updatedAt: _now(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> _ensureAdPreferences(String passportId) async {
    await _db
        .into(_db.adPreferences)
        .insert(
          AdPreferencesCompanion.insert(
            passportId: passportId,
            personalizedAds: false,
            updatedAt: _now(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> _ensureRankingPreference(String passportId) async {
    await ensureDemoPassport(passportId: passportId);
    await _db
        .into(_db.fanRankingPreferences)
        .insert(
          FanRankingPreferencesCompanion.insert(
            passportId: passportId,
            summaryFirst: false,
            updatedAt: _now(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> _applyFeedbackToProfile({
    required String passportId,
    required String creatorId,
    required String action,
  }) async {
    await _ensureInterestProfile(passportId);
    final profile = await interestProfile(passportId);
    final dislikedCreatorIds = profile.dislikedCreatorIds.toSet();
    final mutedProviderIds = profile.mutedProviderIds.toSet();

    if (action == 'block_creator') {
      dislikedCreatorIds.add(creatorId);
    }
    if (action == 'mute_creator' || action == 'block_creator') {
      mutedProviderIds.add(creatorId);
    }

    await (_db.update(
      _db.fanInterestProfiles,
    )..where((tbl) => tbl.passportId.equals(passportId))).write(
      FanInterestProfilesCompanion(
        dislikedCreatorIdsJson: Value(jsonEncode(dislikedCreatorIds.toList())),
        mutedProviderIdsJson: Value(jsonEncode(mutedProviderIds.toList())),
        updatedAt: Value(_now()),
      ),
    );
  }

  Future<String?> _idempotentTarget(String key, String targetType) async {
    final row = await (_db.select(
      _db.idempotencyRecords,
    )..where((tbl) => tbl.key.equals(key))).getSingleOrNull();
    if (row == null || row.targetType != targetType) {
      return null;
    }
    return row.targetId;
  }

  Future<void> _saveIdempotency(
    String key,
    String targetType,
    String targetId,
  ) {
    return _db
        .into(_db.idempotencyRecords)
        .insertOnConflictUpdate(
          IdempotencyRecordsCompanion.insert(
            key: key,
            targetType: targetType,
            targetId: targetId,
          ),
        );
  }

  Future<InterestProfileRecord> _mapInterestProfile(
    FanInterestProfile row,
  ) async {
    final ids = _decodeStringList(row.interestIdsJson);
    final tokens = await interestTaxonomy();
    final selected = tokens
        .where((token) => ids.contains(token.id))
        .toList(growable: false);
    return InterestProfileRecord(
      passportId: row.passportId,
      interests: selected,
      dislikedInterestIds: _decodeStringList(row.dislikedInterestIdsJson),
      dislikedCreatorIds: _decodeStringList(row.dislikedCreatorIdsJson),
      mutedProviderIds: _decodeStringList(row.mutedProviderIdsJson),
      updatedAt: row.updatedAt,
    );
  }
}

CreatorRecord _mapCreator(Creator row) {
  return CreatorRecord(
    id: row.id,
    handle: row.handle,
    displayName: row.displayName,
    vertical: row.vertical,
    avatarRef: row.avatarRef,
  );
}

ContentRecord _mapContent(ContentItem row) {
  return ContentRecord(
    id: row.id,
    creatorId: row.creatorId,
    contentType: row.contentType,
    title: row.title,
    summary: row.summary,
    thumbnailRef: row.thumbnailRef,
    createdAt: row.createdAt,
    perfVelocity: row.perfVelocity,
  );
}

FanPassportRecord _mapPassport(FanPassport row) {
  return FanPassportRecord(
    id: row.id,
    displayName: row.displayName,
    activePersonaId: row.activePersonaId,
    createdAt: row.createdAt,
  );
}

PersonaRecord _mapPersona(Persona row) {
  return PersonaRecord(
    id: row.id,
    passportId: row.passportId,
    label: row.label,
    isActive: row.isActive,
  );
}

ConsentGrantRecord _mapConsent(ConsentGrant row) {
  return ConsentGrantRecord(
    id: row.id,
    passportId: row.passportId,
    grantType: row.grantType,
    createdAt: row.createdAt,
  );
}

DataGrantRequestRecord _mapDataGrantRequest(AudienceGrantRequest row) {
  return DataGrantRequestRecord(
    id: row.id,
    creatorId: row.creatorId,
    creatorName: row.creatorName,
    passportId: row.passportId,
    fields: _decodeStringList(row.fieldsJson),
    purpose: row.purpose,
    retention: row.retention,
    valueExchange: row.valueExchange,
    state: row.state,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

DataConsentGrantRecord _mapDataConsentGrant(DataConsentGrant row) {
  return DataConsentGrantRecord(
    id: row.id,
    requestId: row.requestId,
    passportId: row.passportId,
    creatorId: row.creatorId,
    creatorName: row.creatorName,
    fields: _decodeStringList(row.fieldsJson),
    purpose: row.purpose,
    retention: row.retention,
    valueExchange: row.valueExchange,
    state: row.state,
    updatedAt: row.updatedAt,
  );
}

CategoryDefaultRecord _mapCategoryDefault(CategoryDefault row) {
  return CategoryDefaultRecord(
    id: row.id,
    passportId: row.passportId,
    category: row.category,
    state: row.state,
    updatedAt: row.updatedAt,
  );
}

DataAccessReceiptRecord _mapDataAccessReceipt(DataAccessReceipt row) {
  return DataAccessReceiptRecord(
    id: row.id,
    passportId: row.passportId,
    creatorId: row.creatorId,
    creatorName: row.creatorName,
    grantId: row.grantId,
    fields: _decodeStringList(row.fieldsJson),
    purpose: row.purpose,
    accessedAt: row.accessedAt,
  );
}

TombstoneRequestRecord _mapTombstone(Tombstone row) {
  return TombstoneRequestRecord(
    id: row.id,
    passportId: row.passportId,
    creatorId: row.creatorId,
    createdAt: row.createdAt,
  );
}

InterestTokenRecord _mapInterestToken(InterestTaxonomyData row) {
  return InterestTokenRecord(
    id: row.id,
    label: row.label,
    category: row.category,
  );
}

FollowRecord _mapFollow(Follow row, {required String creatorDisplayName}) {
  return FollowRecord(
    id: row.id,
    passportId: row.passportId,
    creatorId: row.creatorId,
    creatorDisplayName: creatorDisplayName,
    visibility: row.visibility,
    blocked: row.blocked,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

CreatorChannelRecord _mapCreatorChannel(CreatorChannel row) {
  return CreatorChannelRecord(
    id: row.id,
    ownerPassportId: row.ownerPassportId,
    displayName: row.displayName,
    handle: row.handle,
    vertical: row.vertical,
    createdAt: row.createdAt,
  );
}

CreatorChannelManifestRecord _mapChannelManifest(ChannelManifest row) {
  return CreatorChannelManifestRecord(
    channelId: row.channelId,
    displayName: row.displayName,
    handle: row.handle,
    description: row.description,
    category: row.category,
    createdAt: row.createdAt,
  );
}

HostingContractRecord _mapHostingContract(HostingContract row) {
  return HostingContractRecord(
    id: row.id,
    channelId: row.channelId,
    provider: row.provider,
    status: row.status,
    termsVersion: row.termsVersion,
    acceptedAt: row.acceptedAt,
  );
}

ContentManifestRecord _mapContentManifest(ContentManifest row) {
  return ContentManifestRecord(
    id: row.id,
    channelId: row.channelId,
    contentType: row.contentType,
    title: row.title,
    summary: row.summary,
    accessMode: row.accessMode,
    monetizationMode: row.monetizationMode,
    thumbnailRef: row.thumbnailRef,
    schemaVersion: row.schemaVersion,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

MonetizationManifestRecord _mapMonetizationManifest(MonetizationManifest row) {
  return MonetizationManifestRecord(
    channelId: row.channelId,
    membershipsEnabled: row.membershipsEnabled,
    memberOnlyContentIds: _decodeStringList(row.memberOnlyContentIdsJson),
    updatedAt: row.updatedAt,
  );
}

CreatorAdPolicyRecord _mapCreatorAdPolicy(CreatorAdPolicy row) {
  return CreatorAdPolicyRecord(
    channelId: row.channelId,
    allowedCategories: _decodeStringList(row.allowedCategoriesJson),
    blockedCategories: _decodeStringList(row.blockedCategoriesJson),
    formats: _decodeStringList(row.formatsJson),
    surfaces: _decodeStringList(row.surfacesJson),
    updatedAt: row.updatedAt,
  );
}

MembershipTierRecord _mapMembershipTier(MembershipTier row) {
  return MembershipTierRecord(
    id: row.id,
    channelId: row.channelId,
    name: row.name,
    monthlyPriceCents: row.monthlyPriceCents,
    benefits: _decodeStringList(row.benefitsJson),
    entitlementCode: row.entitlementCode,
    createdAt: row.createdAt,
  );
}

AiContentPolicyRecord _mapAiContentPolicy(AiContentPolicy row) {
  return AiContentPolicyRecord(
    channelId: row.channelId,
    archiveQaEnabled: row.archiveQaEnabled,
    summariesEnabled: row.summariesEnabled,
    citationRequired: row.citationRequired,
    updatedAt: row.updatedAt,
  );
}

TranscriptRecord _mapTranscript(Transcript row) {
  return TranscriptRecord(
    contentId: row.contentId,
    segments: _decodeTranscriptSegments(row.segmentsJson),
    updatedAt: row.updatedAt,
  );
}

AiSessionRecord _mapAiSession(AiSession row) {
  return AiSessionRecord(
    id: row.id,
    passportId: row.passportId,
    creatorId: row.creatorId,
    question: row.question,
    answer: row.answer,
    citationContentIds: _decodeStringList(row.citationContentIdsJson),
    memoryPolicy: row.memoryPolicy,
    createdAt: row.createdAt,
  );
}

RankPreferenceRecord _mapRankPreference(FanRankingPreference row) {
  return RankPreferenceRecord(
    passportId: row.passportId,
    summaryFirst: row.summaryFirst,
    updatedAt: row.updatedAt,
  );
}

ImportJobRecord _mapImportJob(
  ImportJob row,
  List<ExternalContentRefRecord> references,
) {
  return ImportJobRecord(
    id: row.id,
    channelId: row.channelId,
    sourcePlatform: row.sourcePlatform,
    state: row.state,
    references: references,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

ExternalContentRefRecord _mapExternalRef(ExternalContentRef row) {
  return ExternalContentRefRecord(
    id: row.id,
    jobId: row.jobId,
    channelId: row.channelId,
    sourcePlatform: row.sourcePlatform,
    externalId: row.externalId,
    contentId: row.contentId,
    title: row.title,
    summary: row.summary,
    createdAt: row.createdAt,
  );
}

ContentPerformanceRecord _mapContentPerformance(ContentPerfData row) {
  return ContentPerformanceRecord(
    contentId: row.contentId,
    velocity: row.velocity,
    completionRate: row.completionRate,
    saves: row.saves,
    shares: row.shares,
    updatedAt: row.updatedAt,
  );
}

PlatformIntentRecord _mapPlatformIntent(PlatformIntent row) {
  return PlatformIntentRecord(
    id: row.id,
    label: row.label,
    description: row.description,
    interestIds: _decodeStringList(row.interestIdsJson),
    displayOrder: row.displayOrder,
  );
}

SessionIntentRecord _mapSessionIntent(SessionIntent row) {
  return SessionIntentRecord(
    id: row.id,
    passportId: row.passportId,
    platformIntentId: row.platformIntentId,
    selectedInterestIds: _decodeStringList(row.selectedInterestIdsJson),
    active: row.active,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

FanFeedbackRecord _mapFanFeedback(FanFeedbackData row) {
  return FanFeedbackRecord(
    id: row.id,
    sessionIntentId: row.sessionIntentId,
    passportId: row.passportId,
    contentId: row.contentId,
    creatorId: row.creatorId,
    action: row.action,
    createdAt: row.createdAt,
  );
}

ExternalProviderCandidateRecord _mapExternalProviderCandidate(
  ExternalProviderCandidate row,
) {
  return ExternalProviderCandidateRecord(
    id: row.id,
    providerId: row.providerId,
    providerLabel: row.providerLabel,
    contentId: row.contentId,
    interestIds: _decodeStringList(row.interestIdsJson),
    score: row.score,
    reason: row.reason,
    updatedAt: row.updatedAt,
  );
}

SearchIndexEntryRecord _mapSearchIndexEntry(SearchIndexEntry row) {
  return SearchIndexEntryRecord(
    contentId: row.contentId,
    creatorId: row.creatorId,
    creatorName: row.creatorName,
    title: row.title,
    summary: row.summary,
    contentType: row.contentType,
    thumbnailRef: row.thumbnailRef,
    searchText: row.searchText,
    interestIds: _decodeStringList(row.interestIdsJson),
    updatedAt: row.updatedAt,
  );
}

AdInventoryRecord _mapAdInventory(AdInventoryData row) {
  return AdInventoryRecord(
    id: row.id,
    brandName: row.brandName,
    category: row.category,
    format: row.format,
    surfaces: _decodeStringList(row.surfacesJson),
    updatedAt: row.updatedAt,
  );
}

PlaybackTokenRecord _mapPlaybackToken(PlaybackToken row) {
  return PlaybackTokenRecord(
    id: row.id,
    passportId: row.passportId,
    contentId: row.contentId,
    token: row.token,
    adPlan: _decodeStringMap(row.adPlanJson),
    completed: row.completed,
    createdAt: row.createdAt,
    expiresAt: row.expiresAt,
  );
}

ReceiptRecord _mapReceipt(Receipt row) {
  return ReceiptRecord(
    id: row.id,
    type: row.type,
    passportId: row.passportId,
    contentId: row.contentId,
    authorizationId: row.authorizationId,
    summary: row.summary,
    createdAt: row.createdAt,
  );
}

EntitlementDefinitionRecord _mapEntitlementDefinition(
  EntitlementDefinition row,
) {
  return EntitlementDefinitionRecord(
    id: row.id,
    channelId: row.channelId,
    tierId: row.tierId,
    code: row.code,
    createdAt: row.createdAt,
  );
}

PaymentIntentRecord _mapPaymentIntent(PaymentIntent row) {
  return PaymentIntentRecord(
    id: row.id,
    passportId: row.passportId,
    kind: row.kind,
    creatorId: row.creatorId,
    creatorName: row.creatorName,
    tierId: row.tierId,
    tierName: row.tierName,
    amountCents: row.amountCents,
    currency: row.currency,
    status: row.status,
    createdAt: row.createdAt,
    confirmedAt: row.confirmedAt,
  );
}

SubscriptionRecord _mapSubscription(Subscription row) {
  return SubscriptionRecord(
    id: row.id,
    passportId: row.passportId,
    creatorId: row.creatorId,
    creatorName: row.creatorName,
    tierId: row.tierId,
    tierName: row.tierName,
    monthlyPriceCents: row.monthlyPriceCents,
    active: row.active,
    startedAt: row.startedAt,
  );
}

EntitlementGrantRecord _mapEntitlementGrant(EntitlementGrant row) {
  return EntitlementGrantRecord(
    id: row.id,
    passportId: row.passportId,
    code: row.code,
    creatorId: row.creatorId,
    sourcePaymentIntentId: row.sourcePaymentIntentId,
    active: row.active,
    grantedAt: row.grantedAt,
  );
}

CreatorPayoutStatementRecord _mapPayoutStatement(PayoutStatement row) {
  return CreatorPayoutStatementRecord(
    id: row.id,
    creatorId: row.creatorId,
    creatorName: row.creatorName,
    totalCents: row.totalCents,
    bySource: _decodeBreakdowns(row.bySourceJson),
    byIntent: _decodeBreakdowns(row.byIntentJson),
    recentReceipts: _decodeReceiptRecords(row.recentReceiptsJson),
    updatedAt: row.updatedAt,
  );
}

FanAllocationStatementRecord _mapAllocationStatement(AllocationStatement row) {
  return FanAllocationStatementRecord(
    id: row.id,
    passportId: row.passportId,
    totalCents: row.totalCents,
    allocations: _decodeAllocations(row.allocationsJson),
    updatedAt: row.updatedAt,
  );
}

List<String> _decodeStringList(String value) {
  final decoded = jsonDecode(value);
  if (decoded is! List) {
    return const [];
  }
  return decoded.whereType<String>().toList(growable: false);
}

List<RevenueBreakdownRecord> _decodeBreakdowns(String value) {
  final decoded = jsonDecode(value);
  if (decoded is! List) {
    return const [];
  }
  return decoded
      .whereType<Map<String, Object?>>()
      .map(
        (item) => RevenueBreakdownRecord(
          label: '${item['label'] ?? ''}',
          amountCents: (item['amountCents'] as num?)?.toInt() ?? 0,
        ),
      )
      .where((item) => item.label.isNotEmpty)
      .toList(growable: false);
}

List<ReceiptRecord> _decodeReceiptRecords(String value) {
  final decoded = jsonDecode(value);
  if (decoded is! List) {
    return const [];
  }
  return decoded
      .whereType<Map<String, Object?>>()
      .map(_receiptFromJson)
      .toList(growable: false);
}

List<AllocationLineRecord> _decodeAllocations(String value) {
  final decoded = jsonDecode(value);
  if (decoded is! List) {
    return const [];
  }
  return decoded
      .whereType<Map<String, Object?>>()
      .map(
        (item) => AllocationLineRecord(
          creatorId: '${item['creatorId'] ?? ''}',
          creatorName: '${item['creatorName'] ?? ''}',
          amountCents: (item['amountCents'] as num?)?.toInt() ?? 0,
          reason: '${item['reason'] ?? ''}',
        ),
      )
      .where((item) => item.creatorId.isNotEmpty)
      .toList(growable: false);
}

Map<String, Object?> _breakdownToJson(RevenueBreakdownRecord record) {
  return {'label': record.label, 'amountCents': record.amountCents};
}

Map<String, Object?> _allocationToJson(AllocationLineRecord record) {
  return {
    'creatorId': record.creatorId,
    'creatorName': record.creatorName,
    'amountCents': record.amountCents,
    'reason': record.reason,
  };
}

Map<String, Object?> _receiptToJson(ReceiptRecord record) {
  return {
    'id': record.id,
    'type': record.type,
    'passportId': record.passportId,
    'contentId': record.contentId,
    'authorizationId': record.authorizationId,
    'summary': record.summary,
    'createdAt': record.createdAt.toIso8601String(),
  };
}

ReceiptRecord _receiptFromJson(Map<String, Object?> item) {
  return ReceiptRecord(
    id: '${item['id'] ?? ''}',
    type: '${item['type'] ?? 'payment'}',
    passportId: '${item['passportId'] ?? ''}',
    contentId: '${item['contentId'] ?? ''}',
    authorizationId: '${item['authorizationId'] ?? ''}',
    summary: '${item['summary'] ?? ''}',
    createdAt:
        DateTime.tryParse('${item['createdAt'] ?? ''}') ??
        DateTime.utc(2026, 5, 31, 12),
  );
}

Map<String, Object?> _decodeStringMap(String value) {
  final decoded = jsonDecode(value);
  if (decoded is! Map) {
    return const {};
  }
  return decoded.cast<String, Object?>();
}

List<TranscriptSegmentRecord> _decodeTranscriptSegments(String value) {
  final decoded = jsonDecode(value);
  if (decoded is! List) {
    return const [];
  }
  return decoded
      .whereType<Map<String, Object?>>()
      .map(
        (segment) => TranscriptSegmentRecord(
          startLabel: '${segment['startLabel'] ?? '00:00'}',
          text: '${segment['text'] ?? ''}',
        ),
      )
      .where((segment) => segment.text.isNotEmpty)
      .toList(growable: false);
}

List<ReceiptsCompanion> _receiptCompanionsForToken(PlaybackTokenRecord token) {
  final adPlan = token.adPlan;
  final hasAd = adPlan['hasAd'] == true;
  return [
    ReceiptsCompanion.insert(
      id: 'receipt_playback_${_slug(token.id)}',
      type: 'playback',
      passportId: token.passportId,
      contentId: token.contentId,
      authorizationId: token.id,
      summary: 'Playback completed for ${token.contentId}.',
      createdAt: _now(),
    ),
    if (hasAd)
      ReceiptsCompanion.insert(
        id: 'receipt_ad_${_slug(token.id)}',
        type: 'adImpression',
        passportId: token.passportId,
        contentId: token.contentId,
        authorizationId: token.id,
        summary:
            'Contextual ad impression: ${adPlan['brandName']} (${adPlan['category']}).',
        createdAt: _now(),
      ),
  ];
}

List<Map<String, String>> _transcriptSegmentsForContent(SeedContent content) {
  return [
    {
      'startLabel': '00:12',
      'text':
          '${content.title}: ${content.summary} This segment gives the practical setup and context.',
    },
    {
      'startLabel': content.contentType == 'video' ? '03:40' : 'section 2',
      'text':
          'Creator-approved source note for ${content.id}; useful for cited archive answers and summary-first relevance.',
    },
  ];
}

class _PlatformIntentSeed {
  const _PlatformIntentSeed({
    required this.id,
    required this.label,
    required this.description,
    required this.interestIds,
    required this.displayOrder,
  });

  final String id;
  final String label;
  final String description;
  final List<String> interestIds;
  final int displayOrder;
}

const _platformIntentSeeds = [
  _PlatformIntentSeed(
    id: 'intent_for_you',
    label: 'For you',
    description: 'Balanced creator-led recommendations with explainable fit.',
    interestIds: ['home_energy', 'fermentation', 'mobility'],
    displayOrder: 0,
  ),
  _PlatformIntentSeed(
    id: 'intent_learn',
    label: 'Learn',
    description: 'Useful how-to posts and videos with clear summaries first.',
    interestIds: ['solar_storage', 'food_safety', 'strength_basics'],
    displayOrder: 1,
  ),
  _PlatformIntentSeed(
    id: 'intent_trending',
    label: 'Trending',
    description: 'High-velocity posts with visible performance context.',
    interestIds: ['home_energy', 'food_safety', 'joint_friendly_cardio'],
    displayOrder: 2,
  ),
  _PlatformIntentSeed(
    id: 'intent_reset',
    label: 'Reset',
    description: 'A neutral exploration mode that ignores ad targeting.',
    interestIds: ['personal_finance', 'family_learning', 'creator_tools'],
    displayOrder: 3,
  ),
];

class _AdInventorySeed {
  const _AdInventorySeed({
    required this.id,
    required this.brandName,
    required this.category,
    required this.format,
    required this.surfaces,
  });

  final String id;
  final String brandName;
  final String category;
  final String format;
  final List<String> surfaces;
}

const _adInventorySeeds = [
  _AdInventorySeed(
    id: 'ad_home_001',
    brandName: 'Gridwise Home',
    category: 'home_energy',
    format: 'pre_roll',
    surfaces: ['watch'],
  ),
  _AdInventorySeed(
    id: 'ad_food_001',
    brandName: 'Ferment Supply Co',
    category: 'fermentation',
    format: 'sponsor_card',
    surfaces: ['watch', 'post_detail'],
  ),
  _AdInventorySeed(
    id: 'ad_motion_001',
    brandName: 'JointKind Studio',
    category: 'mobility',
    format: 'pre_roll',
    surfaces: ['watch'],
  ),
  _AdInventorySeed(
    id: 'ad_blocked_gambling',
    brandName: 'Blocked Odds',
    category: 'gambling',
    format: 'pre_roll',
    surfaces: ['watch'],
  ),
];

List<String> _interestIdsForCreatorId(String creatorId) {
  if (creatorId.contains('solar')) {
    return const ['home_energy', 'solar_storage', 'personal_finance'];
  }
  if (creatorId.contains('ferment')) {
    return const ['fermentation', 'food_safety', 'weeknight_cooking'];
  }
  if (creatorId.contains('motion')) {
    return const ['mobility', 'strength_basics', 'joint_friendly_cardio'];
  }
  return const ['creator_tools'];
}

List<String> _defaultAdCategoriesForCreator(String creatorId) {
  if (creatorId.contains('solar')) {
    return const ['home_energy', 'personal_finance'];
  }
  if (creatorId.contains('ferment')) {
    return const ['fermentation', 'food_safety'];
  }
  if (creatorId.contains('motion')) {
    return const ['mobility', 'joint_friendly_cardio'];
  }
  return const ['creator_tools'];
}

String _searchTextForContent(
  String title,
  String summary,
  String creatorName,
  String vertical,
) {
  return '$title $summary $creatorName $vertical'.toLowerCase();
}

List<_ImportItem> _decodeImportItems(String value) {
  final decoded = jsonDecode(value);
  if (decoded is! List) {
    return const [];
  }
  return decoded
      .whereType<Map<String, Object?>>()
      .map(
        (item) => _ImportItem(
          externalId: item['externalId']! as String,
          contentType: item['contentType']! as String,
          title: item['title']! as String,
          summary: item['summary']! as String,
          thumbnailRef: item['thumbnailRef']! as String,
        ),
      )
      .toList(growable: false);
}

const _sampleImportItems = [
  {
    'externalId': 'yt-thermal-001',
    'contentType': 'video',
    'title': 'Imported attic thermal scan',
    'summary':
        'A previously published scan showing where insulation gaps change winter heating costs.',
    'thumbnailRef': 'seed://imports/thermal-001',
  },
  {
    'externalId': 'yt-battery-002',
    'contentType': 'post',
    'title': 'Imported battery sizing notes',
    'summary':
        'A concise imported post comparing backup loads, peak draw, and usable storage.',
    'thumbnailRef': 'seed://imports/battery-002',
  },
];

class _ImportItem {
  const _ImportItem({
    required this.externalId,
    required this.contentType,
    required this.title,
    required this.summary,
    required this.thumbnailRef,
  });

  final String externalId;
  final String contentType;
  final String title;
  final String summary;
  final String thumbnailRef;
}

String _normalizeHandle(String handle) {
  return handle
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9-]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

String _slug(String value) {
  final slug = _normalizeHandle(value);
  return slug.isEmpty ? 'demo' : slug;
}

DateTime _now() => DateTime.utc(2026, 5, 31, 12);
