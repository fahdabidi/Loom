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

class ExportJobs extends Table {
  TextColumn get id => text()();
  TextColumn get creatorId => text()();
  TextColumn get state => text()();
  IntColumn get pollCount => integer()();
  TextColumn get bundleRef => text()();
  TextColumn get bundleJson => text()();
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

class FanSearchAgentConfigs extends Table {
  TextColumn get passportId => text().references(FanPassports, #id)();
  TextColumn get provider => text()();
  TextColumn get mcpEndpoint => text()();
  BoolColumn get connected => boolean()();
  BoolColumn get preferCreators => boolean()();
  BoolColumn get externalSourcesEnabled => boolean()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {passportId};
}

class ExternalSourceConnections extends Table {
  TextColumn get id => text()();
  TextColumn get passportId => text().references(FanPassports, #id)();
  TextColumn get sourceType => text()();
  BoolColumn get connected => boolean()();
  TextColumn get displayName => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
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

class CaptureLinks extends Table {
  TextColumn get token => text()();
  TextColumn get channelId => text().references(Creators, #id)();
  TextColumn get url => text()();
  TextColumn get channel => text()();
  TextColumn get qrPayload => text()();
  BoolColumn get starterPackEnabled => boolean()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {token};
}

class ReFollowEvents extends Table {
  TextColumn get id => text()();
  TextColumn get token => text().references(CaptureLinks, #token)();
  TextColumn get passportId => text().references(FanPassports, #id)();
  TextColumn get channelId => text().references(Creators, #id)();
  TextColumn get followId => text()();
  TextColumn get channel => text()();
  TextColumn get followState => text()();
  TextColumn get pairwiseCreatorFanId => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AnnouncementTemplates extends Table {
  TextColumn get templateId => text()();
  TextColumn get name => text()();
  TextColumn get channel => text()();
  TextColumn get body => text()();
  TextColumn get placeholdersJson => text()();
  BoolColumn get active => boolean()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {templateId};
}

class RenderedAnnouncements extends Table {
  TextColumn get announcementId => text()();
  TextColumn get channelId => text().references(Creators, #id)();
  TextColumn get templateId =>
      text().references(AnnouncementTemplates, #templateId)();
  TextColumn get channel => text()();
  TextColumn get renderedBody => text()();
  TextColumn get captureLinkUrl => text()();
  TextColumn get qrPayload => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {announcementId};
}

class LinkInBioPages extends Table {
  TextColumn get channelId => text().references(Creators, #id)();
  TextColumn get handle => text()();
  TextColumn get displayName => text()();
  TextColumn get avatarRef => text()();
  TextColumn get captureLinkUrl => text()();
  TextColumn get qrPayload => text()();
  TextColumn get externalLinksJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {channelId};
}

class StarterPacks extends Table {
  TextColumn get channelId => text().references(Creators, #id)();
  TextColumn get starterPackToken => text()();
  TextColumn get memberIdsJson => text()();
  TextColumn get defaultSelectedIdsJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {channelId};
}

class BulkFollowJobs extends Table {
  TextColumn get id => text()();
  TextColumn get channelId => text().references(Creators, #id)();
  TextColumn get passportId => text().references(FanPassports, #id)();
  TextColumn get followedIdsJson => text()();
  TextColumn get alreadyFollowingIdsJson => text()();
  BoolColumn get feedReady => boolean()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ExternalAccounts extends Table {
  TextColumn get linkId => text()();
  TextColumn get channelId => text().references(Creators, #id)();
  TextColumn get platform => text()();
  TextColumn get handle => text()();
  TextColumn get profileUrl => text().nullable()();
  TextColumn get verificationState => text()();
  TextColumn get provenance => text()();
  DateTimeColumn get linkedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {linkId};
}

class PublicMetadataImportJobs extends Table {
  TextColumn get jobId => text()();
  TextColumn get channelId => text().references(Creators, #id)();
  TextColumn get externalAccountLinkId =>
      text().references(ExternalAccounts, #linkId)();
  TextColumn get rightsBasis => text()();
  TextColumn get status => text()();
  IntColumn get importedCount => integer()();
  IntColumn get skippedCount => integer()();
  TextColumn get message => text().nullable()();
  IntColumn get pollCount => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {jobId};
}

class PublicImportedReferences extends Table {
  TextColumn get referenceId => text()();
  TextColumn get jobId => text().references(PublicMetadataImportJobs, #jobId)();
  TextColumn get channelId => text().references(Creators, #id)();
  TextColumn get platform => text()();
  TextColumn get externalId => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get thumbnailRef => text().nullable()();
  TextColumn get sourceUrl => text().nullable()();
  TextColumn get embedKind => text().nullable()();
  TextColumn get accurateMatchLabel => text().nullable()();
  TextColumn get sourceAttribution => text().nullable()();
  TextColumn get creatorNote => text().nullable()();
  DateTimeColumn get publishedAt => dateTime().nullable()();
  TextColumn get rightsBasis => text()();
  BoolColumn get searchIndexable => boolean()();
  BoolColumn get aiQueryable => boolean()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {referenceId};
}

class AiSearchRuns extends Table {
  TextColumn get runId => text()();
  TextColumn get passportId => text().references(FanPassports, #id)();
  TextColumn get query => text()();
  TextColumn get agentProvider => text()();
  TextColumn get resultRefsJson => text()();
  TextColumn get receiptId => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {runId};
}

class CrossPostJobs extends Table {
  TextColumn get crossPostId => text()();
  TextColumn get channelId => text().references(Creators, #id)();
  TextColumn get message => text()();
  TextColumn get targetLinkIdsJson => text()();
  TextColumn get targetsJson => text()();
  TextColumn get announcementId => text().nullable()();
  TextColumn get contentRef => text().nullable()();
  TextColumn get captureLinkUrl => text().nullable()();
  IntColumn get pollCount => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {crossPostId};
}

class AdDecisions extends Table {
  TextColumn get decisionId => text()();
  TextColumn get contentId => text().references(ContentItems, #id)();
  TextColumn get adsJson => text()();
  TextColumn get policyVersion => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {decisionId};
}

class AdImpressions extends Table {
  TextColumn get id => text()();
  TextColumn get decisionId => text().references(AdDecisions, #decisionId)();
  TextColumn get adId => text()();
  BoolColumn get completed => boolean()();
  TextColumn get receiptId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class PremiumNoAdEvents extends Table {
  TextColumn get id => text()();
  TextColumn get passportId => text().references(FanPassports, #id)();
  TextColumn get contentId => text().references(ContentItems, #id)();
  TextColumn get channelId => text().nullable()();
  TextColumn get sessionIntent => text().nullable()();
  TextColumn get receiptId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
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
    ExportJobs,
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
    FanSearchAgentConfigs,
    ExternalSourceConnections,
    PlatformIntents,
    SessionIntents,
    FanFeedback,
    ExternalProviderCandidates,
    SearchIndexEntries,
    AdInventory,
    PlaybackTokens,
    Receipts,
    AdPreferences,
    CaptureLinks,
    ReFollowEvents,
    AnnouncementTemplates,
    RenderedAnnouncements,
    LinkInBioPages,
    StarterPacks,
    BulkFollowJobs,
    ExternalAccounts,
    PublicMetadataImportJobs,
    PublicImportedReferences,
    AiSearchRuns,
    CrossPostJobs,
    AdDecisions,
    AdImpressions,
    PremiumNoAdEvents,
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
  int get schemaVersion => 11;

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
      if (from < 9) {
        await m.createTable(exportJobs);
      }
      if (from < 10) {
        await m.createTable(captureLinks);
        await m.createTable(reFollowEvents);
        await m.createTable(announcementTemplates);
        await m.createTable(renderedAnnouncements);
        await m.createTable(linkInBioPages);
        await m.createTable(starterPacks);
        await m.createTable(bulkFollowJobs);
        await m.createTable(externalAccounts);
        await m.createTable(publicMetadataImportJobs);
        await m.createTable(publicImportedReferences);
        await m.createTable(crossPostJobs);
        await m.createTable(adDecisions);
        await m.createTable(adImpressions);
        await m.createTable(premiumNoAdEvents);
      }
      if (from < 11) {
        await m.createTable(fanSearchAgentConfigs);
        await m.createTable(externalSourceConnections);
        await m.addColumn(
          publicImportedReferences,
          publicImportedReferences.embedKind,
        );
        await m.addColumn(
          publicImportedReferences,
          publicImportedReferences.accurateMatchLabel,
        );
        await m.addColumn(
          publicImportedReferences,
          publicImportedReferences.sourceAttribution,
        );
        await m.addColumn(
          publicImportedReferences,
          publicImportedReferences.creatorNote,
        );
        await m.createTable(aiSearchRuns);
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

class FanSearchAgentConfigRecord {
  const FanSearchAgentConfigRecord({
    required this.passportId,
    required this.provider,
    required this.mcpEndpoint,
    required this.connected,
    required this.preferCreators,
    required this.externalSourcesEnabled,
    required this.updatedAt,
  });

  final String passportId;
  final String provider;
  final String mcpEndpoint;
  final bool connected;
  final bool preferCreators;
  final bool externalSourcesEnabled;
  final DateTime updatedAt;
}

class ExternalSourceConnectionRecord {
  const ExternalSourceConnectionRecord({
    required this.id,
    required this.passportId,
    required this.sourceType,
    required this.connected,
    required this.displayName,
    required this.updatedAt,
  });

  final String id;
  final String passportId;
  final String sourceType;
  final bool connected;
  final String displayName;
  final DateTime updatedAt;
}

class AiSearchRunRecord {
  const AiSearchRunRecord({
    required this.runId,
    required this.passportId,
    required this.query,
    required this.agentProvider,
    required this.resultRefs,
    required this.receiptId,
    required this.createdAt,
  });

  final String runId;
  final String passportId;
  final String query;
  final String agentProvider;
  final List<String> resultRefs;
  final String receiptId;
  final DateTime createdAt;
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

class ExportJobRecord {
  const ExportJobRecord({
    required this.id,
    required this.creatorId,
    required this.state,
    required this.pollCount,
    required this.bundleRef,
    required this.bundleJson,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String creatorId;
  final String state;
  final int pollCount;
  final String bundleRef;
  final String bundleJson;
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

class CaptureLinkRecord {
  const CaptureLinkRecord({
    required this.token,
    required this.channelId,
    required this.url,
    required this.channel,
    required this.qrPayload,
    required this.starterPackEnabled,
    required this.createdAt,
    this.expiresAt,
  });

  final String token;
  final String channelId;
  final String url;
  final String channel;
  final String qrPayload;
  final bool starterPackEnabled;
  final DateTime createdAt;
  final DateTime? expiresAt;
}

class ReFollowEventRecord {
  const ReFollowEventRecord({
    required this.id,
    required this.token,
    required this.passportId,
    required this.channelId,
    required this.followId,
    required this.channel,
    required this.followState,
    required this.pairwiseCreatorFanId,
    required this.createdAt,
  });

  final String id;
  final String token;
  final String passportId;
  final String channelId;
  final String followId;
  final String channel;
  final String followState;
  final String pairwiseCreatorFanId;
  final DateTime createdAt;
}

class AnnouncementTemplateRecord {
  const AnnouncementTemplateRecord({
    required this.templateId,
    required this.name,
    required this.channel,
    required this.body,
    required this.placeholders,
  });

  final String templateId;
  final String name;
  final String channel;
  final String body;
  final List<String> placeholders;
}

class RenderedAnnouncementRecord {
  const RenderedAnnouncementRecord({
    required this.announcementId,
    required this.channelId,
    required this.channel,
    required this.renderedBody,
    required this.captureLinkUrl,
    required this.qrPayload,
    required this.createdAt,
  });

  final String announcementId;
  final String channelId;
  final String channel;
  final String renderedBody;
  final String captureLinkUrl;
  final String qrPayload;
  final DateTime createdAt;
}

class LinkInBioPageRecord {
  const LinkInBioPageRecord({
    required this.channelId,
    required this.handle,
    required this.displayName,
    required this.avatarRef,
    required this.captureLinkUrl,
    required this.qrPayload,
    required this.externalLinks,
  });

  final String channelId;
  final String handle;
  final String displayName;
  final String avatarRef;
  final String captureLinkUrl;
  final String qrPayload;
  final List<Map<String, String>> externalLinks;
}

class StarterPackRecord {
  const StarterPackRecord({
    required this.channelId,
    required this.starterPackToken,
    required this.memberIds,
    required this.defaultSelectedIds,
    required this.updatedAt,
  });

  final String channelId;
  final String starterPackToken;
  final List<String> memberIds;
  final List<String> defaultSelectedIds;
  final DateTime updatedAt;
}

class BulkFollowJobRecord {
  const BulkFollowJobRecord({
    required this.id,
    required this.channelId,
    required this.passportId,
    required this.followedIds,
    required this.alreadyFollowingIds,
    required this.feedReady,
    required this.createdAt,
  });

  final String id;
  final String channelId;
  final String passportId;
  final List<String> followedIds;
  final List<String> alreadyFollowingIds;
  final bool feedReady;
  final DateTime createdAt;
}

class ExtensionManifestRecord {
  const ExtensionManifestRecord({
    required this.extensionId,
    required this.name,
    required this.category,
    required this.riskTier,
    required this.surfaces,
    required this.permissions,
    required this.exportBehavior,
    required this.certificationState,
    required this.latestVersion,
    required this.description,
  });

  final String extensionId;
  final String name;
  final String category;
  final String riskTier;
  final List<String> surfaces;
  final List<String> permissions;
  final String exportBehavior;
  final String certificationState;
  final String latestVersion;
  final String description;
}

class ExtensionInstallRecord {
  const ExtensionInstallRecord({
    required this.installId,
    required this.channelId,
    required this.extensionId,
    required this.version,
    required this.approvedPermissions,
    required this.approvedSurfaces,
    required this.config,
    required this.state,
    required this.installedAt,
    required this.updatedAt,
  });

  final String installId;
  final String channelId;
  final String extensionId;
  final String version;
  final List<String> approvedPermissions;
  final List<String> approvedSurfaces;
  final Map<String, String> config;
  final String state;
  final DateTime installedAt;
  final DateTime updatedAt;
}

class ExtensionSessionRecord {
  const ExtensionSessionRecord({
    required this.sessionId,
    required this.channelId,
    required this.extensionId,
    required this.version,
    required this.surface,
    required this.fanId,
    required this.pairwiseCreatorFanId,
    required this.state,
    required this.allowedPermissions,
    required this.createdAt,
  });

  final String sessionId;
  final String channelId;
  final String extensionId;
  final String version;
  final String surface;
  final String fanId;
  final String pairwiseCreatorFanId;
  final String state;
  final List<String> allowedPermissions;
  final DateTime createdAt;
}

class ExtensionEventRecord {
  const ExtensionEventRecord({
    required this.eventId,
    required this.sessionId,
    required this.type,
    required this.payload,
    required this.createdAt,
    required this.idempotencyKey,
  });

  final String eventId;
  final String sessionId;
  final String type;
  final Map<String, String> payload;
  final DateTime createdAt;
  final String idempotencyKey;
}

class ExtensionStateRecord {
  const ExtensionStateRecord({
    required this.scopeKey,
    required this.key,
    required this.value,
    required this.exportBehavior,
    required this.updatedAt,
  });

  final String scopeKey;
  final String key;
  final Map<String, String> value;
  final String exportBehavior;
  final DateTime updatedAt;
}

class ExtensionStateExportRecord {
  const ExtensionStateExportRecord({
    required this.exportId,
    required this.channelId,
    required this.fanId,
    required this.generatedAt,
    required this.entries,
  });

  final String exportId;
  final String channelId;
  final String? fanId;
  final DateTime generatedAt;
  final List<ExtensionStateRecord> entries;
}

class ChannelThemeRecord {
  const ChannelThemeRecord({
    required this.themeId,
    required this.name,
    required this.primaryHex,
    required this.secondaryHex,
    required this.backgroundHex,
    required this.surfaceHex,
    required this.textHex,
    required this.accentHex,
  });

  final String themeId;
  final String name;
  final String primaryHex;
  final String secondaryHex;
  final String backgroundHex;
  final String surfaceHex;
  final String textHex;
  final String accentHex;
}

class SurfaceModuleRecord {
  const SurfaceModuleRecord({
    required this.moduleId,
    required this.kind,
    required this.title,
    required this.surface,
    required this.sortOrder,
    required this.enabled,
    required this.extensionId,
    required this.config,
  });

  final String moduleId;
  final String kind;
  final String title;
  final String surface;
  final int sortOrder;
  final bool enabled;
  final String? extensionId;
  final Map<String, String> config;
}

class InstalledExtensionRefRecord {
  const InstalledExtensionRefRecord({
    required this.installId,
    required this.extensionId,
    required this.name,
    required this.version,
    required this.surfaces,
    required this.state,
    required this.moduleIds,
  });

  final String installId;
  final String extensionId;
  final String name;
  final String version;
  final List<String> surfaces;
  final String state;
  final List<String> moduleIds;
}

class CreatorExperienceConfigRecord {
  const CreatorExperienceConfigRecord({
    required this.channelId,
    required this.theme,
    required this.bannerRef,
    required this.surfaceModules,
    required this.aiPersona,
    required this.adPosture,
    required this.installedExtensions,
    required this.version,
    required this.updatedAt,
  });

  final String channelId;
  final ChannelThemeRecord theme;
  final String bannerRef;
  final List<SurfaceModuleRecord> surfaceModules;
  final String aiPersona;
  final String adPosture;
  final List<InstalledExtensionRefRecord> installedExtensions;
  final int version;
  final DateTime updatedAt;
}

class ConversionStageRecord {
  const ConversionStageRecord({
    required this.stage,
    required this.count,
    required this.conversionFromPrevious,
  });

  final String stage;
  final int count;
  final double? conversionFromPrevious;
}

class ConversionFunnelRecord {
  const ConversionFunnelRecord({
    required this.channelId,
    required this.startsAt,
    required this.endsAt,
    required this.stages,
    required this.byChannelSource,
  });

  final String channelId;
  final DateTime startsAt;
  final DateTime endsAt;
  final List<ConversionStageRecord> stages;
  final Map<String, int> byChannelSource;
}

class ExternalAccountRecord {
  const ExternalAccountRecord({
    required this.linkId,
    required this.channelId,
    required this.platform,
    required this.handle,
    required this.verificationState,
    required this.linkedAt,
    this.profileUrl,
  });

  final String linkId;
  final String channelId;
  final String platform;
  final String handle;
  final String? profileUrl;
  final String verificationState;
  final DateTime linkedAt;
}

class PublicMetadataImportJobRecord {
  const PublicMetadataImportJobRecord({
    required this.jobId,
    required this.channelId,
    required this.status,
    required this.importedCount,
    required this.skippedCount,
    this.message,
  });

  final String jobId;
  final String channelId;
  final String status;
  final int importedCount;
  final int skippedCount;
  final String? message;
}

class PublicImportedReferenceRecord {
  const PublicImportedReferenceRecord({
    required this.referenceId,
    required this.channelId,
    required this.platform,
    required this.externalId,
    required this.title,
    required this.rightsBasis,
    required this.searchIndexable,
    required this.aiQueryable,
    this.description,
    this.thumbnailRef,
    this.sourceUrl,
    this.embedKind,
    this.accurateMatchLabel,
    this.sourceAttribution,
    this.creatorNote,
    this.publishedAt,
  });

  final String referenceId;
  final String channelId;
  final String platform;
  final String externalId;
  final String title;
  final String rightsBasis;
  final bool searchIndexable;
  final bool aiQueryable;
  final String? description;
  final String? thumbnailRef;
  final String? sourceUrl;
  final String? embedKind;
  final String? accurateMatchLabel;
  final String? sourceAttribution;
  final String? creatorNote;
  final DateTime? publishedAt;
}

class CrossPostTargetRecord {
  const CrossPostTargetRecord({
    required this.targetLinkId,
    required this.platform,
    required this.deliveryStatus,
    this.externalPostUrl,
    this.message,
  });

  final String targetLinkId;
  final String platform;
  final String deliveryStatus;
  final String? externalPostUrl;
  final String? message;
}

class CrossPostRecord {
  const CrossPostRecord({
    required this.crossPostId,
    required this.channelId,
    required this.message,
    required this.createdAt,
    required this.targets,
    this.announcementId,
    this.contentRef,
    this.captureLinkUrl,
  });

  final String crossPostId;
  final String channelId;
  final String message;
  final DateTime createdAt;
  final List<CrossPostTargetRecord> targets;
  final String? announcementId;
  final String? contentRef;
  final String? captureLinkUrl;
}

class SelectedAdRecord {
  const SelectedAdRecord({
    required this.adId,
    required this.brand,
    required this.category,
    required this.disclosure,
    required this.selectionBasis,
  });

  final String adId;
  final String brand;
  final String category;
  final String disclosure;
  final String selectionBasis;
}

class AdDecisionRecord {
  const AdDecisionRecord({
    required this.decisionId,
    required this.contentId,
    required this.ads,
    this.policyVersion,
  });

  final String decisionId;
  final String contentId;
  final List<SelectedAdRecord> ads;
  final String? policyVersion;
}

class AdImpressionRecord {
  const AdImpressionRecord({
    required this.id,
    required this.decisionId,
    required this.adId,
    required this.recorded,
    this.receiptId,
  });

  final String id;
  final String decisionId;
  final String adId;
  final bool recorded;
  final String? receiptId;
}

class PremiumNoAdStatusRecord {
  const PremiumNoAdStatusRecord({
    required this.passportId,
    required this.active,
    this.entitlementId,
    this.since,
    this.renewsAt,
  });

  final String passportId;
  final bool active;
  final String? entitlementId;
  final DateTime? since;
  final DateTime? renewsAt;
}

class PremiumNoAdEventRecord {
  const PremiumNoAdEventRecord({
    required this.id,
    required this.passportId,
    required this.contentId,
    required this.noAdApplied,
    this.receiptId,
  });

  final String id;
  final String passportId;
  final String contentId;
  final bool noAdApplied;
  final String? receiptId;
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
      await _db.delete(_db.aiSearchRuns).go();
      await _db.delete(_db.premiumNoAdEvents).go();
      await _db.delete(_db.adImpressions).go();
      await _db.delete(_db.adDecisions).go();
      await _db.delete(_db.crossPostJobs).go();
      await _db.delete(_db.publicImportedReferences).go();
      await _db.delete(_db.publicMetadataImportJobs).go();
      await _db.delete(_db.externalAccounts).go();
      await _db.delete(_db.bulkFollowJobs).go();
      await _db.delete(_db.starterPacks).go();
      await _db.delete(_db.linkInBioPages).go();
      await _db.delete(_db.renderedAnnouncements).go();
      await _db.delete(_db.announcementTemplates).go();
      await _db.delete(_db.reFollowEvents).go();
      await _db.delete(_db.captureLinks).go();
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
      await _db.delete(_db.exportJobs).go();
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
      await _db.delete(_db.externalSourceConnections).go();
      await _db.delete(_db.fanSearchAgentConfigs).go();
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

        batch.insertAll(_db.fanSearchAgentConfigs, [
          FanSearchAgentConfigsCompanion.insert(
            passportId: 'passport_demo_fan',
            provider: 'anthropic_claude',
            mcpEndpoint: '',
            connected: false,
            preferCreators: true,
            externalSourcesEnabled: false,
            updatedAt: _now(),
          ),
        ]);

        batch.insertAll(
          _db.externalSourceConnections,
          _defaultExternalSourceConnectionCompanions('passport_demo_fan'),
        );

        batch.insertAll(
          _db.announcementTemplates,
          _announcementTemplateSeeds.map(
            (template) => AnnouncementTemplatesCompanion.insert(
              templateId: template.templateId,
              name: template.name,
              channel: template.channel,
              body: template.body,
              placeholdersJson: jsonEncode(template.placeholders),
              active: true,
              updatedAt: _now(),
            ),
          ),
        );

        batch.insertAll(
          _db.captureLinks,
          world.creators.map((creator) {
            final token = _seedCaptureToken(creator.id);
            return CaptureLinksCompanion.insert(
              token: token,
              channelId: creator.id,
              url: _captureUrl(token),
              channel: 'link_in_bio',
              qrPayload: _qrPayload(token),
              starterPackEnabled: true,
              createdAt: _now(),
            );
          }),
        );

        batch.insertAll(
          _db.linkInBioPages,
          world.creators.map((creator) {
            final token = _seedCaptureToken(creator.id);
            return LinkInBioPagesCompanion.insert(
              channelId: creator.id,
              handle: creator.handle,
              displayName: creator.displayName,
              avatarRef: creator.avatarRef,
              captureLinkUrl: _captureUrl(token),
              qrPayload: _qrPayload(token),
              externalLinksJson: jsonEncode(_linkInBioExternalLinks(creator)),
              updatedAt: _now(),
            );
          }),
        );

        batch.insertAll(
          _db.starterPacks,
          world.creators.map((creator) {
            final memberIds = _starterPackMemberIds(
              creator.id,
              world.creators.map((item) => item.id),
            );
            return StarterPacksCompanion.insert(
              channelId: creator.id,
              starterPackToken: _starterPackToken(creator.id),
              memberIdsJson: jsonEncode(memberIds),
              defaultSelectedIdsJson: jsonEncode(memberIds),
              updatedAt: _now(),
            );
          }),
        );

        batch.insertAll(
          _db.externalAccounts,
          world.creators.expand((creator) {
            final handle = creator.handle;
            return [
              ExternalAccountsCompanion.insert(
                linkId: 'ext_${_slug(creator.id)}_youtube',
                channelId: creator.id,
                platform: 'youtube',
                handle: '@$handle',
                profileUrl: Value('https://youtube.example/$handle'),
                verificationState: 'verified',
                provenance: 'seeded_public_profile',
                linkedAt: _now(),
              ),
              ExternalAccountsCompanion.insert(
                linkId: 'ext_${_slug(creator.id)}_instagram',
                channelId: creator.id,
                platform: 'instagram',
                handle: '@$handle',
                profileUrl: Value('https://instagram.example/$handle'),
                verificationState: 'verified',
                provenance: 'seeded_public_profile',
                linkedAt: _now(),
              ),
            ];
          }),
        );

        batch.insertAll(
          _db.publicMetadataImportJobs,
          world.creators
              .where((creator) => _isGamingCreatorId(creator.id))
              .map(_gamingExternalImportJobSeed),
        );

        batch.insertAll(
          _db.publicImportedReferences,
          world.creators
              .where((creator) => _isGamingCreatorId(creator.id))
              .expand(_gamingExternalReferenceSeeds),
        );

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
          KvMetaCompanion.insert(
            key: _extensionManifestsKvKey,
            value: jsonEncode(_extensionManifestSeedMaps()),
          ),
          KvMetaCompanion.insert(
            key: _extensionInstallsKvKey,
            value: jsonEncode(_extensionInstallSeedMaps()),
          ),
          KvMetaCompanion.insert(
            key: _extensionSessionsKvKey,
            value: jsonEncode(const []),
          ),
          KvMetaCompanion.insert(
            key: _extensionEventsKvKey,
            value: jsonEncode(const []),
          ),
          KvMetaCompanion.insert(
            key: _extensionStateKvKey,
            value: jsonEncode(_extensionStateSeedMaps()),
          ),
          KvMetaCompanion.insert(
            key: _creatorExperienceConfigsKvKey,
            value: jsonEncode(_creatorExperienceConfigSeedMaps()),
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

  Future<FanSearchAgentConfigRecord> searchAgentConfig(
    String passportId,
  ) async {
    await _ensureSearchAgentConfig(passportId);
    final row = await (_db.select(
      _db.fanSearchAgentConfigs,
    )..where((tbl) => tbl.passportId.equals(passportId))).getSingle();
    return _mapSearchAgentConfig(row);
  }

  Future<FanSearchAgentConfigRecord> putSearchAgentConfig({
    required String passportId,
    required String provider,
    required String mcpEndpoint,
    required bool connected,
    required bool preferCreators,
    required bool externalSourcesEnabled,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'search_agent_config',
    );
    if (existing != null) {
      return searchAgentConfig(existing);
    }

    await _ensureSearchAgentConfig(passportId);
    await (_db.update(
      _db.fanSearchAgentConfigs,
    )..where((tbl) => tbl.passportId.equals(passportId))).write(
      FanSearchAgentConfigsCompanion(
        provider: Value(provider),
        mcpEndpoint: Value(mcpEndpoint),
        connected: Value(connected),
        preferCreators: Value(preferCreators),
        externalSourcesEnabled: Value(externalSourcesEnabled),
        updatedAt: Value(_now()),
      ),
    );
    await _saveIdempotency(idempotencyKey, 'search_agent_config', passportId);
    return searchAgentConfig(passportId);
  }

  Future<List<ExternalSourceConnectionRecord>> externalSourceConnections(
    String passportId,
  ) async {
    await _ensureExternalSourceConnections(passportId);
    final rows =
        await (_db.select(_db.externalSourceConnections)
              ..where((tbl) => tbl.passportId.equals(passportId))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.sourceType)]))
            .get();
    return rows.map(_mapExternalSourceConnection).toList(growable: false);
  }

  Future<ExternalSourceConnectionRecord> putExternalSourceConnection({
    required String passportId,
    required String sourceType,
    required bool connected,
    required String displayName,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'external_source_connection',
    );
    if (existing != null) {
      final row = await _externalSourceConnectionById(existing);
      if (row != null) {
        return row;
      }
    }

    await _ensureExternalSourceConnections(passportId);
    final id = _externalSourceConnectionId(passportId, sourceType);
    await _db
        .into(_db.externalSourceConnections)
        .insertOnConflictUpdate(
          ExternalSourceConnectionsCompanion.insert(
            id: id,
            passportId: passportId,
            sourceType: sourceType,
            connected: connected,
            displayName: displayName,
            updatedAt: _now(),
          ),
        );
    await _saveIdempotency(idempotencyKey, 'external_source_connection', id);
    return (await _externalSourceConnectionById(id))!;
  }

  Future<List<PublicImportedReferenceRecord>> externalContentCandidates({
    required String query,
    List<String> platforms = const ['youtube'],
    bool aiQueryableOnly = true,
    int limit = 8,
  }) async {
    final normalized = query.trim().toLowerCase();
    final terms = normalized.isEmpty
        ? const <String>[]
        : normalized.split(RegExp(r'\s+')).where((term) => term.isNotEmpty);
    final rows = await _db.select(_db.publicImportedReferences).get();
    final ranked =
        rows
            .where(
              (row) => platforms.isEmpty || platforms.contains(row.platform),
            )
            .where((row) => !aiQueryableOnly || row.aiQueryable)
            .where(
              (row) =>
                  terms.isEmpty ||
                  terms.any(
                    (term) =>
                        row.title.toLowerCase().contains(term) ||
                        (row.description ?? '').toLowerCase().contains(term) ||
                        (row.accurateMatchLabel ?? '').toLowerCase().contains(
                          term,
                        ),
                  ),
            )
            .map(_mapPublicImportedReference)
            .toList()
          ..sort((a, b) => a.title.compareTo(b.title));
    return ranked.take(limit).toList(growable: false);
  }

  Future<PublicImportedReferenceRecord?> publicImportedReferenceById(
    String referenceId,
  ) async {
    final row = await (_db.select(
      _db.publicImportedReferences,
    )..where((tbl) => tbl.referenceId.equals(referenceId))).getSingleOrNull();
    return row == null ? null : _mapPublicImportedReference(row);
  }

  Future<PublicImportedReferenceRecord> upsertExternalReference({
    required String channelId,
    required String platform,
    required String externalId,
    required String title,
    required String description,
    required String thumbnailRef,
    required String sourceUrl,
    required String rightsBasis,
    required bool searchIndexable,
    required bool aiQueryable,
    required String sourceAttribution,
    required String embedKind,
    String? accurateMatchLabel,
    String? creatorNote,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'external_reference',
    );
    if (existing != null) {
      final record = await publicImportedReferenceById(existing);
      if (record != null) {
        return record;
      }
    }
    final accountId = 'ext_${_slug(channelId)}_${_slug(platform)}_linked';
    final jobId = 'public_import_${_slug(channelId)}_${_slug(idempotencyKey)}';
    final referenceId =
        'pubref_${_slug(channelId)}_${_slug(platform)}_${_slug(externalId)}';
    await _db.transaction(() async {
      await _db
          .into(_db.externalAccounts)
          .insert(
            ExternalAccountsCompanion.insert(
              linkId: accountId,
              channelId: channelId,
              platform: platform,
              handle: '@${_slug(channelId)}',
              profileUrl: Value(
                'https://$platform.example/${_slug(channelId)}',
              ),
              verificationState: 'verified',
              provenance: 'creator_linked_external_content',
              linkedAt: _now(),
            ),
            mode: InsertMode.insertOrIgnore,
          );
      await _db
          .into(_db.publicMetadataImportJobs)
          .insertOnConflictUpdate(
            PublicMetadataImportJobsCompanion.insert(
              jobId: jobId,
              channelId: channelId,
              externalAccountLinkId: accountId,
              rightsBasis: rightsBasis,
              status: 'complete',
              importedCount: 1,
              skippedCount: 0,
              message: const Value('Creator-linked external reference.'),
              pollCount: 1,
              createdAt: _now(),
              updatedAt: _now(),
            ),
          );
      await _db
          .into(_db.publicImportedReferences)
          .insertOnConflictUpdate(
            PublicImportedReferencesCompanion.insert(
              referenceId: referenceId,
              jobId: jobId,
              channelId: channelId,
              platform: platform,
              externalId: externalId,
              title: title,
              description: Value(description),
              thumbnailRef: Value(thumbnailRef),
              sourceUrl: Value(sourceUrl),
              embedKind: Value(embedKind),
              accurateMatchLabel: Value(accurateMatchLabel),
              sourceAttribution: Value(sourceAttribution),
              creatorNote: Value(creatorNote),
              publishedAt: Value(_now()),
              rightsBasis: rightsBasis,
              searchIndexable: searchIndexable,
              aiQueryable: aiQueryable,
              createdAt: _now(),
            ),
          );
    });
    await _saveIdempotency(idempotencyKey, 'external_reference', referenceId);
    return (await publicImportedReferenceById(referenceId))!;
  }

  Future<AiSearchRunRecord> recordAiSearchRun({
    required String passportId,
    required String query,
    required String agentProvider,
    required List<String> resultRefs,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(idempotencyKey, 'ai_search_run');
    if (existing != null) {
      final row = await (_db.select(
        _db.aiSearchRuns,
      )..where((tbl) => tbl.runId.equals(existing))).getSingle();
      return _mapAiSearchRun(row);
    }

    final runId = 'aisearch_${_slug(idempotencyKey)}';
    final receiptId = 'receipt_search_${_slug(runId)}';
    await _db
        .into(_db.aiSearchRuns)
        .insertOnConflictUpdate(
          AiSearchRunsCompanion.insert(
            runId: runId,
            passportId: passportId,
            query: query,
            agentProvider: agentProvider,
            resultRefsJson: jsonEncode(resultRefs),
            receiptId: receiptId,
            createdAt: _now(),
          ),
        );
    await _saveIdempotency(idempotencyKey, 'ai_search_run', runId);
    return _mapAiSearchRun(
      await (_db.select(
        _db.aiSearchRuns,
      )..where((tbl) => tbl.runId.equals(runId))).getSingle(),
    );
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

  Future<ExportJobRecord> startExportJob({
    required String creatorId,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(idempotencyKey, 'export_job');
    if (existing != null) {
      final job = await exportJob(existing);
      if (job != null) {
        return job;
      }
    }

    final id = 'export_${_slug(idempotencyKey)}';
    final now = _now();
    await _db
        .into(_db.exportJobs)
        .insertOnConflictUpdate(
          ExportJobsCompanion.insert(
            id: id,
            creatorId: creatorId,
            state: 'queued',
            pollCount: 0,
            bundleRef: '',
            bundleJson: '',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await _saveIdempotency(idempotencyKey, 'export_job', id);
    return (await exportJob(id))!;
  }

  Future<ExportJobRecord?> exportJob(String id) async {
    final row = await (_db.select(
      _db.exportJobs,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapExportJob(row);
  }

  Future<ExportJobRecord> advanceExportJob({
    required String id,
    required String bundleRef,
    required String bundleJson,
  }) async {
    final row = await (_db.select(
      _db.exportJobs,
    )..where((tbl) => tbl.id.equals(id))).getSingle();
    if (row.state == 'complete') {
      return (await exportJob(id))!;
    }

    final nextPoll = row.pollCount + 1;
    final complete = nextPoll >= 2;
    await (_db.update(_db.exportJobs)..where((tbl) => tbl.id.equals(id))).write(
      ExportJobsCompanion(
        state: Value(complete ? 'complete' : 'processing'),
        pollCount: Value(nextPoll),
        bundleRef: complete ? Value(bundleRef) : const Value.absent(),
        bundleJson: complete ? Value(bundleJson) : const Value.absent(),
        updatedAt: Value(_now()),
      ),
    );
    return (await exportJob(id))!;
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

    if (kind == 'extensionHype') {
      resolvedCreatorId = creatorId ?? 'creator_nova_clutch';
      final creator = await creatorById(resolvedCreatorId);
      resolvedCreatorName = creator?.displayName ?? resolvedCreatorId;
      amountCents = 299;
    } else if (kind == 'creatorMembership') {
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
      } else if (intent.kind == 'creatorMembership') {
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
      final paymentSummary = switch (intent.kind) {
        'noAdsPremium' => 'Simulated no-ad premium payment confirmed.',
        'extensionHype' =>
          'Simulated extension hype payment confirmed for ${intent.creatorName ?? 'the creator'}.',
        _ => 'Simulated creator membership payment confirmed.',
      };
      final benefitType = switch (intent.kind) {
        'noAdsPremium' => 'premiumNoAd',
        'extensionHype' => 'extensionHype',
        _ => 'membership',
      };
      final benefitSummary = switch (intent.kind) {
        'noAdsPremium' =>
          'Premium no-ad entitlement is active across eligible playback.',
        'extensionHype' =>
          'Extension hype contribution is recorded as simulated fan value.',
        _ =>
          'Creator membership is active for ${intent.creatorName ?? 'the creator'}.',
      };
      await _db.batch((batch) {
        batch.insertAllOnConflictUpdate(_db.receipts, [
          ReceiptsCompanion.insert(
            id: 'receipt_payment_${_slug(intent.id)}',
            type: 'payment',
            passportId: intent.passportId,
            contentId: contentId,
            authorizationId: intent.id,
            summary: paymentSummary,
            createdAt: now,
          ),
          ReceiptsCompanion.insert(
            id: intent.kind == 'noAdsPremium'
                ? 'receipt_no_ad_${_slug(intent.id)}'
                : intent.kind == 'extensionHype'
                ? 'receipt_extension_hype_${_slug(intent.id)}'
                : 'receipt_membership_${_slug(intent.id)}',
            type: benefitType,
            passportId: intent.passportId,
            contentId: contentId,
            authorizationId: intent.id,
            summary: benefitSummary,
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

  Future<CaptureLinkRecord> createCaptureLink({
    required String channelId,
    required String channel,
    required bool starterPackEnabled,
    DateTime? expiresAt,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(idempotencyKey, 'capture_link');
    if (existing != null) {
      final link = await captureLinkByToken(existing);
      if (link != null) {
        return link;
      }
    }
    final creator = await creatorById(channelId);
    if (creator == null) {
      throw StateError('No channel exists for $channelId');
    }
    final token =
        'cap_${_slug(channelId)}_${_slug(channel)}_${_slug(idempotencyKey)}';
    await _db
        .into(_db.captureLinks)
        .insertOnConflictUpdate(
          CaptureLinksCompanion.insert(
            token: token,
            channelId: channelId,
            url: _captureUrl(token),
            channel: channel,
            qrPayload: _qrPayload(token),
            starterPackEnabled: starterPackEnabled,
            createdAt: _now(),
            expiresAt: Value(expiresAt),
          ),
        );
    await _saveIdempotency(idempotencyKey, 'capture_link', token);
    await _ensureLinkInBioForCreator(creator, token);
    return (await captureLinkByToken(token))!;
  }

  Future<CaptureLinkRecord?> captureLinkByToken(String token) async {
    final row = await (_db.select(
      _db.captureLinks,
    )..where((tbl) => tbl.token.equals(token))).getSingleOrNull();
    return row == null ? null : _mapCaptureLink(row);
  }

  Future<List<CaptureLinkRecord>> captureLinksForChannel(
    String channelId,
  ) async {
    final rows =
        await (_db.select(_db.captureLinks)
              ..where((tbl) => tbl.channelId.equals(channelId))
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
            .get();
    return rows.map(_mapCaptureLink).toList(growable: false);
  }

  Future<ReFollowEventRecord> recordReFollow({
    required String token,
    required String passportId,
    required String followVisibility,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(idempotencyKey, 're_follow');
    if (existing != null) {
      final event = await reFollowEventById(existing);
      if (event != null) {
        return event;
      }
    }
    final link = await captureLinkByToken(token);
    if (link == null) {
      throw StateError('No capture link exists for token=$token');
    }
    await ensureDemoPassport(passportId: passportId);
    final existingFollow = await followForPassportCreator(
      passportId: passportId,
      creatorId: link.channelId,
    );
    final alreadyFollowing = existingFollow != null && !existingFollow.blocked;
    final follow =
        existingFollow ??
        await createFollow(
          passportId: passportId,
          creatorId: link.channelId,
          visibility: followVisibility,
          idempotencyKey: 're-follow-follow-$idempotencyKey',
        );
    final id = 'refollow_${_slug(idempotencyKey)}';
    await _db
        .into(_db.reFollowEvents)
        .insertOnConflictUpdate(
          ReFollowEventsCompanion.insert(
            id: id,
            token: token,
            passportId: passportId,
            channelId: link.channelId,
            followId: follow.id,
            channel: link.channel,
            followState: alreadyFollowing ? 'already_following' : 'followed',
            pairwiseCreatorFanId:
                'pair_${_slug(link.channelId)}_${_slug(passportId)}',
            createdAt: _now(),
          ),
        );
    await _saveIdempotency(idempotencyKey, 're_follow', id);
    return (await reFollowEventById(id))!;
  }

  Future<ReFollowEventRecord?> reFollowEventById(String id) async {
    final row = await (_db.select(
      _db.reFollowEvents,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapReFollowEvent(row);
  }

  Future<List<ReFollowEventRecord>> reFollowEventsForChannel(
    String channelId,
  ) async {
    final rows =
        await (_db.select(_db.reFollowEvents)
              ..where((tbl) => tbl.channelId.equals(channelId))
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
            .get();
    return rows.map(_mapReFollowEvent).toList(growable: false);
  }

  Future<List<AnnouncementTemplateRecord>> announcementTemplates() async {
    final rows =
        await (_db.select(_db.announcementTemplates)
              ..where((tbl) => tbl.active.equals(true))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
            .get();
    return rows.map(_mapAnnouncementTemplate).toList(growable: false);
  }

  Future<RenderedAnnouncementRecord> renderAnnouncement({
    required String channelId,
    required String templateId,
    required String captureLinkToken,
    required Map<String, String> fields,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'rendered_announcement',
    );
    if (existing != null) {
      final announcement = await renderedAnnouncementById(existing);
      if (announcement != null) {
        return announcement;
      }
    }
    final creator = await creatorById(channelId);
    final template = await (_db.select(
      _db.announcementTemplates,
    )..where((tbl) => tbl.templateId.equals(templateId))).getSingleOrNull();
    final link = await captureLinkByToken(captureLinkToken);
    if (creator == null || template == null || link == null) {
      throw StateError('Announcement inputs are incomplete.');
    }
    final defaults = {
      'creatorName': creator.displayName,
      'creatorHandle': creator.handle,
      'captureLink': link.url,
      'linkInBio': link.url,
      ...fields,
    };
    final body = _renderTemplate(template.body, defaults);
    final id = 'ann_${_slug(idempotencyKey)}';
    await _db
        .into(_db.renderedAnnouncements)
        .insertOnConflictUpdate(
          RenderedAnnouncementsCompanion.insert(
            announcementId: id,
            channelId: channelId,
            templateId: templateId,
            channel: template.channel,
            renderedBody: body,
            captureLinkUrl: link.url,
            qrPayload: link.qrPayload,
            createdAt: _now(),
          ),
        );
    await _saveIdempotency(idempotencyKey, 'rendered_announcement', id);
    return (await renderedAnnouncementById(id))!;
  }

  Future<RenderedAnnouncementRecord?> renderedAnnouncementById(
    String id,
  ) async {
    final row = await (_db.select(
      _db.renderedAnnouncements,
    )..where((tbl) => tbl.announcementId.equals(id))).getSingleOrNull();
    return row == null ? null : _mapRenderedAnnouncement(row);
  }

  Future<LinkInBioPageRecord> linkInBioPage(String channelId) async {
    final row = await (_db.select(
      _db.linkInBioPages,
    )..where((tbl) => tbl.channelId.equals(channelId))).getSingleOrNull();
    if (row != null) {
      return _mapLinkInBioPage(row);
    }
    final creator = await creatorById(channelId);
    if (creator == null) {
      throw StateError('No channel exists for $channelId');
    }
    final links = await captureLinksForChannel(channelId);
    final link = links.isNotEmpty
        ? links.first
        : await createCaptureLink(
            channelId: channelId,
            channel: 'link_in_bio',
            starterPackEnabled: true,
            idempotencyKey: 'auto-link-in-bio-$channelId',
          );
    await _ensureLinkInBioForCreator(creator, link.token);
    return linkInBioPage(channelId);
  }

  Future<StarterPackRecord> starterPack(String channelId) async {
    final row = await (_db.select(
      _db.starterPacks,
    )..where((tbl) => tbl.channelId.equals(channelId))).getSingleOrNull();
    if (row != null) {
      return _mapStarterPack(row);
    }
    final creators = await this.creators();
    if (!creators.any((creator) => creator.id == channelId)) {
      throw StateError('No channel exists for $channelId');
    }
    final memberIds = _starterPackMemberIds(
      channelId,
      creators.map((creator) => creator.id),
    );
    await _db
        .into(_db.starterPacks)
        .insertOnConflictUpdate(
          StarterPacksCompanion.insert(
            channelId: channelId,
            starterPackToken: _starterPackToken(channelId),
            memberIdsJson: jsonEncode(memberIds),
            defaultSelectedIdsJson: jsonEncode(memberIds),
            updatedAt: _now(),
          ),
        );
    return starterPack(channelId);
  }

  Future<StarterPackRecord> putStarterPack({
    required String channelId,
    required List<String> memberIds,
    required List<String> defaultSelectedIds,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(idempotencyKey, 'starter_pack');
    if (existing != null) {
      return starterPack(existing);
    }
    final creators = await this.creators();
    final creatorIds = creators.map((creator) => creator.id).toSet();
    if (!creatorIds.contains(channelId)) {
      throw StateError('No channel exists for $channelId');
    }
    final normalizedMembers = <String>[
      channelId,
      ...memberIds.where((memberId) => memberId != channelId),
    ].where(creatorIds.contains).toSet().toList(growable: false);
    if (normalizedMembers.length < 2) {
      throw StateError('A starter pack must include at least two creators.');
    }
    final normalizedDefaultIds = defaultSelectedIds
        .where(normalizedMembers.contains)
        .toSet()
        .toList(growable: false);
    await _db
        .into(_db.starterPacks)
        .insertOnConflictUpdate(
          StarterPacksCompanion.insert(
            channelId: channelId,
            starterPackToken: _starterPackToken(channelId),
            memberIdsJson: jsonEncode(normalizedMembers),
            defaultSelectedIdsJson: jsonEncode(
              normalizedDefaultIds.isEmpty
                  ? normalizedMembers
                  : normalizedDefaultIds,
            ),
            updatedAt: _now(),
          ),
        );
    await _saveIdempotency(idempotencyKey, 'starter_pack', channelId);
    return starterPack(channelId);
  }

  Future<BulkFollowJobRecord> bulkFollow({
    required String channelId,
    required String passportId,
    required List<String> channelIds,
    required String followVisibility,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(idempotencyKey, 'bulk_follow');
    if (existing != null) {
      final row = await (_db.select(
        _db.bulkFollowJobs,
      )..where((tbl) => tbl.id.equals(existing))).getSingleOrNull();
      if (row != null) {
        return _mapBulkFollowJob(row);
      }
    }
    await ensureDemoPassport(passportId: passportId);
    final selectedIds = channelIds.toSet().toList(growable: false);
    final followed = <String>[];
    final alreadyFollowing = <String>[];
    for (final selectedId in selectedIds) {
      final existingFollow = await followForPassportCreator(
        passportId: passportId,
        creatorId: selectedId,
      );
      if (existingFollow != null && !existingFollow.blocked) {
        alreadyFollowing.add(selectedId);
        continue;
      }
      await createFollow(
        passportId: passportId,
        creatorId: selectedId,
        visibility: followVisibility,
        idempotencyKey: 'bulk-follow-$idempotencyKey-$selectedId',
      );
      followed.add(selectedId);
    }
    final id = 'bulk_${_slug(idempotencyKey)}';
    await _db
        .into(_db.bulkFollowJobs)
        .insertOnConflictUpdate(
          BulkFollowJobsCompanion.insert(
            id: id,
            channelId: channelId,
            passportId: passportId,
            followedIdsJson: jsonEncode(followed),
            alreadyFollowingIdsJson: jsonEncode(alreadyFollowing),
            feedReady: followed.length + alreadyFollowing.length >= 2,
            createdAt: _now(),
          ),
        );
    await _saveIdempotency(idempotencyKey, 'bulk_follow', id);
    final row = await (_db.select(
      _db.bulkFollowJobs,
    )..where((tbl) => tbl.id.equals(id))).getSingle();
    return _mapBulkFollowJob(row);
  }

  Future<List<ExtensionManifestRecord>> extensionManifests({
    String? category,
    bool certifiedOnly = true,
  }) async {
    final records = (await _readKvMapList(_extensionManifestsKvKey))
        .map(_extensionManifestFromJson)
        .where(
          (manifest) =>
              (category == null || manifest.category == category) &&
              (!certifiedOnly || manifest.certificationState == 'certified'),
        )
        .toList(growable: false);
    records.sort((a, b) => a.name.compareTo(b.name));
    return records;
  }

  Future<ExtensionManifestRecord?> extensionManifest(String extensionId) async {
    final manifests = await extensionManifests(certifiedOnly: false);
    return manifests
        .where((manifest) => manifest.extensionId == extensionId)
        .firstOrNull;
  }

  Future<ExtensionManifestRecord> publishExtension({
    required ExtensionManifestRecord manifest,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'extension_manifest',
    );
    if (existing != null) {
      final record = await extensionManifest(existing);
      if (record != null) {
        return record;
      }
    }
    final manifests = await extensionManifests(certifiedOnly: false);
    final next = [
      for (final current in manifests)
        if (current.extensionId != manifest.extensionId) current,
      manifest,
    ];
    await _writeKvMapList(
      _extensionManifestsKvKey,
      next.map(_extensionManifestToJson).toList(growable: false),
    );
    await _saveIdempotency(
      idempotencyKey,
      'extension_manifest',
      manifest.extensionId,
    );
    return manifest;
  }

  Future<List<ExtensionInstallRecord>> extensionInstallsForChannel(
    String channelId, {
    bool activeOnly = false,
  }) async {
    return (await _extensionInstallRecords())
        .where(
          (install) =>
              install.channelId == channelId &&
              (!activeOnly || install.state == 'active'),
        )
        .toList(growable: false);
  }

  Future<ExtensionInstallRecord?> extensionInstallById(String installId) async {
    return (await _extensionInstallRecords())
        .where((install) => install.installId == installId)
        .firstOrNull;
  }

  Future<ExtensionInstallRecord> installExtension({
    required String channelId,
    required String extensionId,
    required String version,
    required List<String> approvedPermissions,
    required List<String> approvedSurfaces,
    required Map<String, String> config,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'extension_install',
    );
    if (existing != null) {
      final record = await extensionInstallById(existing);
      if (record != null) {
        return record;
      }
    }
    final creator = await creatorById(channelId);
    if (creator == null) {
      throw StateError('No channel exists for $channelId');
    }
    final manifest = await extensionManifest(extensionId);
    if (manifest == null || manifest.certificationState != 'certified') {
      throw StateError('Extension $extensionId is not certified.');
    }
    final permissions = approvedPermissions.isEmpty
        ? manifest.permissions
        : approvedPermissions;
    final surfaces = approvedSurfaces.isEmpty
        ? manifest.surfaces
        : approvedSurfaces;
    final deniedPermissions = permissions
        .where((permission) => !manifest.permissions.contains(permission))
        .toList(growable: false);
    final deniedSurfaces = surfaces
        .where((surface) => !manifest.surfaces.contains(surface))
        .toList(growable: false);
    if (deniedPermissions.isNotEmpty || deniedSurfaces.isNotEmpty) {
      throw StateError(
        'Extension install request exceeds manifest permissions or surfaces.',
      );
    }
    final now = _now();
    final install = ExtensionInstallRecord(
      installId: 'install_${_slug(channelId)}_${_slug(extensionId)}',
      channelId: channelId,
      extensionId: extensionId,
      version: version.isEmpty ? manifest.latestVersion : version,
      approvedPermissions: permissions,
      approvedSurfaces: surfaces,
      config: config,
      state: 'active',
      installedAt: now,
      updatedAt: now,
    );
    final installs = await _extensionInstallRecords();
    await _writeExtensionInstallRecords([
      for (final current in installs)
        if (current.installId != install.installId) current,
      install,
    ]);
    await _saveIdempotency(
      idempotencyKey,
      'extension_install',
      install.installId,
    );
    return install;
  }

  Future<ExtensionInstallRecord> suspendExtension({
    required String channelId,
    required String extensionId,
    required String reason,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'extension_install',
    );
    if (existing != null) {
      final record = await extensionInstallById(existing);
      if (record != null) {
        return record;
      }
    }
    final installs = await _extensionInstallRecords();
    final current = installs
        .where(
          (install) =>
              install.channelId == channelId &&
              install.extensionId == extensionId,
        )
        .firstOrNull;
    if (current == null) {
      throw StateError('Extension $extensionId is not installed.');
    }
    final suspended = ExtensionInstallRecord(
      installId: current.installId,
      channelId: current.channelId,
      extensionId: current.extensionId,
      version: current.version,
      approvedPermissions: current.approvedPermissions,
      approvedSurfaces: current.approvedSurfaces,
      config: {...current.config, 'suspensionReason': reason},
      state: 'suspended',
      installedAt: current.installedAt,
      updatedAt: _now(),
    );
    await _writeExtensionInstallRecords([
      for (final install in installs)
        if (install.installId == suspended.installId) suspended else install,
    ]);
    await _saveIdempotency(
      idempotencyKey,
      'extension_install',
      suspended.installId,
    );
    return suspended;
  }

  Future<ExtensionSessionRecord> createExtensionSession({
    required String channelId,
    required String extensionId,
    required String surface,
    required String fanId,
    required String idempotencyKey,
    String? version,
    String? pairwiseCreatorFanId,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'extension_session',
    );
    if (existing != null) {
      final session = await extensionSession(existing);
      if (session != null) {
        return session;
      }
    }
    final install = (await extensionInstallsForChannel(
      channelId,
      activeOnly: true,
    )).where((candidate) => candidate.extensionId == extensionId).firstOrNull;
    if (install == null) {
      throw StateError('Extension $extensionId is not active on $channelId.');
    }
    if (!install.approvedSurfaces.contains(surface)) {
      throw StateError('Extension $extensionId is not approved for $surface.');
    }
    final session = ExtensionSessionRecord(
      sessionId: 'session_${_slug(idempotencyKey)}',
      channelId: channelId,
      extensionId: extensionId,
      version: version ?? install.version,
      surface: surface,
      fanId: fanId,
      pairwiseCreatorFanId:
          pairwiseCreatorFanId ?? 'pair_${_slug(channelId)}_${_slug(fanId)}',
      state: 'active',
      allowedPermissions: install.approvedPermissions,
      createdAt: _now(),
    );
    final sessions = await _extensionSessionRecords();
    await _writeExtensionSessionRecords([
      for (final current in sessions)
        if (current.sessionId != session.sessionId) current,
      session,
    ]);
    await _saveIdempotency(
      idempotencyKey,
      'extension_session',
      session.sessionId,
    );
    return session;
  }

  Future<ExtensionSessionRecord?> extensionSession(String sessionId) async {
    return (await _extensionSessionRecords())
        .where((session) => session.sessionId == sessionId)
        .firstOrNull;
  }

  Future<ExtensionEventRecord> submitExtensionEvent({
    required String sessionId,
    required String type,
    required Map<String, String> payload,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(idempotencyKey, 'extension_event');
    if (existing != null) {
      final event = await extensionEvent(existing);
      if (event != null) {
        return event;
      }
    }
    final session = await extensionSession(sessionId);
    if (session == null || session.state != 'active') {
      throw StateError('Extension session $sessionId is not active.');
    }
    final event = ExtensionEventRecord(
      eventId: 'event_${_slug(idempotencyKey)}',
      sessionId: sessionId,
      type: type,
      payload: payload,
      createdAt: _now(),
      idempotencyKey: idempotencyKey,
    );
    final events = await _extensionEventRecords();
    await _writeExtensionEventRecords([
      for (final current in events)
        if (current.eventId != event.eventId) current,
      event,
    ]);
    await _upsertExtensionState(
      ExtensionStateRecord(
        scopeKey:
            'channel:${session.channelId}:fan:${session.fanId}:extension:${session.extensionId}',
        key: 'last_event_${_slug(type)}',
        value: {'eventId': event.eventId, 'type': type, ...payload},
        exportBehavior: 'creator_and_fan',
        updatedAt: _now(),
      ),
    );
    await _applyExtensionRuntimeEvent(session, event);
    if (payload.containsKey('rewardCode') || type == 'reward_earned') {
      await _db
          .into(_db.receipts)
          .insertOnConflictUpdate(
            ReceiptsCompanion.insert(
              id: 'receipt_extension_${_slug(event.eventId)}',
              type: 'reward',
              passportId: session.fanId,
              contentId: session.extensionId,
              authorizationId: session.sessionId,
              summary:
                  'Extension reward ${payload['rewardCode'] ?? type} earned in ${session.extensionId}.',
              createdAt: _now(),
            ),
          );
    }
    await _saveIdempotency(idempotencyKey, 'extension_event', event.eventId);
    return event;
  }

  Future<void> _applyExtensionRuntimeEvent(
    ExtensionSessionRecord session,
    ExtensionEventRecord event,
  ) async {
    final aggregateScope =
        'channel:${session.channelId}:extension:${session.extensionId}';
    final now = _now();
    switch (event.type) {
      case 'clip_submitted':
        final clipId = event.payload['clipId'] ?? event.eventId;
        await _upsertExtensionState(
          ExtensionStateRecord(
            scopeKey: aggregateScope,
            key: 'clip:$clipId',
            value: {
              'clipId': clipId,
              'title': event.payload['title'] ?? 'Fan clip',
              'submitter': event.payload['submitter'] ?? 'Demo fan',
              'votes': event.payload['votes'] ?? '0',
              'season': event.payload['season'] ?? 'Current season',
            },
            exportBehavior: 'creator_and_fan',
            updatedAt: now,
          ),
        );
        break;
      case 'clip_vote':
        final clipId = event.payload['clipId'] ?? 'featured';
        final current = await _extensionStateByKey(
          aggregateScope,
          'clip:$clipId',
        );
        final votes =
            _parseExtensionInt(current?.value['votes'], fallback: 0) + 1;
        await _upsertExtensionState(
          ExtensionStateRecord(
            scopeKey: aggregateScope,
            key: 'clip:$clipId',
            value: {
              'clipId': clipId,
              'title':
                  current?.value['title'] ??
                  event.payload['title'] ??
                  'Featured clip',
              'submitter': current?.value['submitter'] ?? 'Demo fan',
              'votes': '$votes',
              'season':
                  current?.value['season'] ??
                  event.payload['season'] ??
                  'Current season',
            },
            exportBehavior: 'creator_and_fan',
            updatedAt: now,
          ),
        );
        if (event.payload.containsKey('rewardCode')) {
          await _upsertExtensionState(
            ExtensionStateRecord(
              scopeKey: aggregateScope,
              key: 'winner',
              value: {
                'clipId': clipId,
                'rewardCode': event.payload['rewardCode']!,
                'votes': '$votes',
              },
              exportBehavior: 'creator_and_fan',
              updatedAt: now,
            ),
          );
        }
        break;
      case 'pick_made':
        await _upsertExtensionState(
          ExtensionStateRecord(
            scopeKey: aggregateScope,
            key: 'pick:${session.fanId}',
            value: {
              'fanId': session.fanId,
              'name': event.payload['name'] ?? 'You',
              'pick': event.payload['pick'] ?? 'Undecided',
              'points': event.payload['points'] ?? '10',
              'question': event.payload['question'] ?? 'Creator prediction',
            },
            exportBehavior: 'fan_owned',
            updatedAt: now,
          ),
        );
        break;
      case 'hype_sent':
        final current = await _extensionStateByKey(
          aggregateScope,
          'hype_meter',
        );
        final amount = _parseExtensionInt(
          event.payload['amountCents'],
          fallback: 299,
        );
        final total =
            _parseExtensionInt(current?.value['totalCents'], fallback: 0) +
            amount;
        await _upsertExtensionState(
          ExtensionStateRecord(
            scopeKey: aggregateScope,
            key: 'hype_meter',
            value: {
              'totalCents': '$total',
              'lastAmountCents': '$amount',
              'lastFanId': session.fanId,
              'paymentIntentId': event.payload['paymentIntentId'] ?? '',
              'goal': event.payload['goal'] ?? current?.value['goal'] ?? '',
            },
            exportBehavior: 'creator_and_fan',
            updatedAt: now,
          ),
        );
        break;
      case 'quest_completed':
        final questId = event.payload['questId'] ?? 'main';
        final current = await _extensionStateByKey(
          aggregateScope,
          'quest:$questId',
        );
        final completions =
            _parseExtensionInt(current?.value['completions'], fallback: 0) + 1;
        await _upsertExtensionState(
          ExtensionStateRecord(
            scopeKey: aggregateScope,
            key: 'quest:$questId',
            value: {
              'questId': questId,
              'title': event.payload['title'] ?? 'Creator quest',
              'badge': event.payload['badge'] ?? 'Quest badge',
              'completions': '$completions',
              'lastFanId': session.fanId,
            },
            exportBehavior: 'creator_and_fan',
            updatedAt: now,
          ),
        );
        await _upsertExtensionState(
          ExtensionStateRecord(
            scopeKey: aggregateScope,
            key: 'badge:${session.fanId}:$questId',
            value: {
              'fanId': session.fanId,
              'badge': event.payload['badge'] ?? 'Quest badge',
              'questId': questId,
            },
            exportBehavior: 'fan_owned',
            updatedAt: now,
          ),
        );
        break;
      case 'build_submitted':
        final buildId = event.payload['buildId'] ?? event.eventId;
        await _upsertExtensionState(
          ExtensionStateRecord(
            scopeKey: aggregateScope,
            key: 'build:$buildId',
            value: {
              'buildId': buildId,
              'title': event.payload['title'] ?? 'Fan build',
              'submitter': event.payload['submitter'] ?? 'Demo fan',
              'votes': event.payload['votes'] ?? '0',
              'featured': event.payload['featured'] ?? 'false',
            },
            exportBehavior: 'creator_and_fan',
            updatedAt: now,
          ),
        );
        break;
      case 'build_vote':
        final buildId = event.payload['buildId'] ?? 'featured';
        final current = await _extensionStateByKey(
          aggregateScope,
          'build:$buildId',
        );
        final votes =
            _parseExtensionInt(current?.value['votes'], fallback: 0) + 1;
        await _upsertExtensionState(
          ExtensionStateRecord(
            scopeKey: aggregateScope,
            key: 'build:$buildId',
            value: {
              'buildId': buildId,
              'title':
                  current?.value['title'] ??
                  event.payload['title'] ??
                  'Featured build',
              'submitter': current?.value['submitter'] ?? 'Demo fan',
              'votes': '$votes',
              'featured': event.payload['featured'] ?? 'true',
            },
            exportBehavior: 'creator_and_fan',
            updatedAt: now,
          ),
        );
        break;
      case 'guild_contributed':
        final current = await _extensionStateByKey(
          aggregateScope,
          'guild_progress',
        );
        final amount = _parseExtensionInt(event.payload['amount'], fallback: 5);
        final total =
            _parseExtensionInt(current?.value['current'], fallback: 0) + amount;
        await _upsertExtensionState(
          ExtensionStateRecord(
            scopeKey: aggregateScope,
            key: 'guild_progress',
            value: {
              'current': '$total',
              'lastAmount': '$amount',
              'lastFanId': session.fanId,
              'target':
                  event.payload['target'] ?? current?.value['target'] ?? '',
              'milestone': event.payload['milestone'] ?? '',
            },
            exportBehavior: 'creator_and_fan',
            updatedAt: now,
          ),
        );
        break;
    }
  }

  Future<ExtensionStateRecord?> _extensionStateByKey(
    String scopeKey,
    String key,
  ) async {
    return (await _extensionStateRecords())
        .where((entry) => entry.scopeKey == scopeKey && entry.key == key)
        .firstOrNull;
  }

  Future<ExtensionEventRecord?> extensionEvent(String eventId) async {
    return (await _extensionEventRecords())
        .where((event) => event.eventId == eventId)
        .firstOrNull;
  }

  Future<ExtensionStateExportRecord> createExtensionStateExport({
    required String channelId,
    String? fanId,
  }) async {
    final entries = (await _extensionStateRecords())
        .where(
          (entry) =>
              entry.scopeKey.startsWith('channel:$channelId:') &&
              (fanId == null || entry.scopeKey.contains(':fan:$fanId:')),
        )
        .toList(growable: false);
    return ExtensionStateExportRecord(
      exportId:
          'extension_export_${_slug(channelId)}_${_slug(fanId ?? 'creator')}',
      channelId: channelId,
      fanId: fanId,
      generatedAt: _now(),
      entries: entries,
    );
  }

  Future<CreatorExperienceConfigRecord> creatorExperienceConfig(
    String channelId,
  ) async {
    final configs = await _readKvMapList(_creatorExperienceConfigsKvKey);
    final json = configs
        .where((item) => item['channelId'] == channelId)
        .firstOrNull;
    if (json == null) {
      final creator = await creatorById(channelId);
      if (creator == null) {
        throw StateError('No channel exists for $channelId');
      }
      return _defaultExperienceConfigForCreator(creator);
    }
    return _creatorExperienceConfigFromJson(
      json,
      installs: await extensionInstallsForChannel(channelId),
      manifests: await extensionManifests(certifiedOnly: false),
    );
  }

  Future<CreatorExperienceConfigRecord> putCreatorExperienceConfig({
    required CreatorExperienceConfigRecord config,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'creator_experience_config',
    );
    if (existing != null) {
      return creatorExperienceConfig(existing);
    }
    final configs = await _readKvMapList(_creatorExperienceConfigsKvKey);
    await _writeKvMapList(_creatorExperienceConfigsKvKey, [
      for (final item in configs)
        if (item['channelId'] != config.channelId) item,
      _creatorExperienceConfigToJson(config),
    ]);
    await _saveIdempotency(
      idempotencyKey,
      'creator_experience_config',
      config.channelId,
    );
    return creatorExperienceConfig(config.channelId);
  }

  Future<List<Map<String, Object?>>> _readKvMapList(String key) async {
    final row = await (_db.select(
      _db.kvMeta,
    )..where((tbl) => tbl.key.equals(key))).getSingleOrNull();
    if (row == null) {
      return const [];
    }
    return _decodeObjectMapList(row.value);
  }

  Future<void> _writeKvMapList(String key, List<Map<String, Object?>> values) {
    return _db
        .into(_db.kvMeta)
        .insertOnConflictUpdate(
          KvMetaCompanion.insert(key: key, value: jsonEncode(values)),
        );
  }

  Future<List<ExtensionInstallRecord>> _extensionInstallRecords() async {
    return (await _readKvMapList(
      _extensionInstallsKvKey,
    )).map(_extensionInstallFromJson).toList(growable: false);
  }

  Future<void> _writeExtensionInstallRecords(
    List<ExtensionInstallRecord> records,
  ) {
    return _writeKvMapList(
      _extensionInstallsKvKey,
      records.map(_extensionInstallToJson).toList(growable: false),
    );
  }

  Future<List<ExtensionSessionRecord>> _extensionSessionRecords() async {
    return (await _readKvMapList(
      _extensionSessionsKvKey,
    )).map(_extensionSessionFromJson).toList(growable: false);
  }

  Future<void> _writeExtensionSessionRecords(
    List<ExtensionSessionRecord> records,
  ) {
    return _writeKvMapList(
      _extensionSessionsKvKey,
      records.map(_extensionSessionToJson).toList(growable: false),
    );
  }

  Future<List<ExtensionEventRecord>> _extensionEventRecords() async {
    return (await _readKvMapList(
      _extensionEventsKvKey,
    )).map(_extensionEventFromJson).toList(growable: false);
  }

  Future<void> _writeExtensionEventRecords(List<ExtensionEventRecord> records) {
    return _writeKvMapList(
      _extensionEventsKvKey,
      records.map(_extensionEventToJson).toList(growable: false),
    );
  }

  Future<List<ExtensionStateRecord>> _extensionStateRecords() async {
    return (await _readKvMapList(
      _extensionStateKvKey,
    )).map(_extensionStateFromJson).toList(growable: false);
  }

  Future<void> _upsertExtensionState(ExtensionStateRecord record) async {
    final records = await _extensionStateRecords();
    await _writeKvMapList(
      _extensionStateKvKey,
      [
        for (final current in records)
          if (current.scopeKey != record.scopeKey || current.key != record.key)
            current,
        record,
      ].map(_extensionStateToJson).toList(growable: false),
    );
  }

  Future<ConversionFunnelRecord> conversionFunnel({
    required String channelId,
    DateTime? startsAt,
    DateTime? endsAt,
  }) async {
    final start = startsAt ?? _now().subtract(const Duration(days: 30));
    final end = endsAt ?? _now();
    final captureRows = await captureLinksForChannel(channelId);
    final announcementRows = await (_db.select(
      _db.renderedAnnouncements,
    )..where((tbl) => tbl.channelId.equals(channelId))).get();
    final crossPostRows = await (_db.select(
      _db.crossPostJobs,
    )..where((tbl) => tbl.channelId.equals(channelId))).get();
    final eventRows = (await reFollowEventsForChannel(channelId))
        .where((event) => !event.createdAt.isBefore(start))
        .where((event) => !event.createdAt.isAfter(end))
        .toList(growable: false);
    final currentFollows =
        await (_db.select(_db.follows)
              ..where((tbl) => tbl.creatorId.equals(channelId))
              ..where((tbl) => tbl.blocked.equals(false)))
            .get();
    final subscriptions =
        await (_db.select(_db.subscriptions)
              ..where((tbl) => tbl.creatorId.equals(channelId))
              ..where((tbl) => tbl.active.equals(true)))
            .get();
    final premiumRows = await (_db.select(
      _db.premiumNoAdEvents,
    )..where((tbl) => tbl.channelId.equals(channelId))).get();
    final bySource = <String, int>{};
    for (final link in captureRows) {
      bySource.update(link.channel, (value) => value + 30, ifAbsent: () => 30);
    }
    for (final event in eventRows) {
      bySource.update(event.channel, (value) => value + 1, ifAbsent: () => 1);
    }
    final reFollowed = {
      ...eventRows.map((event) => event.passportId),
      ...currentFollows.map((follow) => follow.passportId),
    }.length;
    final member = subscriptions.map((row) => row.passportId).toSet().length;
    final premium = premiumRows.map((row) => row.passportId).toSet().length;
    final reached = [
      reFollowed,
      captureRows.length * 30,
      announcementRows.length * 40,
      crossPostRows.length * 50,
    ].reduce((a, b) => a > b ? a : b);
    final counts = [
      ('reached', reached),
      ('re_followed', reFollowed),
      ('member', member),
      ('premium', premium),
    ];
    var previous = 0;
    final stages = <ConversionStageRecord>[];
    for (final (stage, count) in counts) {
      stages.add(
        ConversionStageRecord(
          stage: stage,
          count: count,
          conversionFromPrevious: previous == 0 ? null : count / previous,
        ),
      );
      previous = count;
    }
    return ConversionFunnelRecord(
      channelId: channelId,
      startsAt: start,
      endsAt: end,
      stages: stages,
      byChannelSource: bySource,
    );
  }

  Future<List<ExternalAccountRecord>> externalAccounts(String channelId) async {
    final rows =
        await (_db.select(_db.externalAccounts)
              ..where((tbl) => tbl.channelId.equals(channelId))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.platform)]))
            .get();
    return rows.map(_mapExternalAccount).toList(growable: false);
  }

  Future<ExternalAccountRecord> linkExternalAccount({
    required String channelId,
    required String platform,
    required String handle,
    String? profileUrl,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'external_account',
    );
    if (existing != null) {
      final record = await externalAccountById(existing);
      if (record != null) {
        return record;
      }
    }
    final id = 'ext_${_slug(channelId)}_${_slug(platform)}_${_slug(handle)}';
    await _db
        .into(_db.externalAccounts)
        .insertOnConflictUpdate(
          ExternalAccountsCompanion.insert(
            linkId: id,
            channelId: channelId,
            platform: platform,
            handle: handle,
            profileUrl: Value(profileUrl),
            verificationState: 'pending',
            provenance: 'creator_declared',
            linkedAt: _now(),
          ),
        );
    await _saveIdempotency(idempotencyKey, 'external_account', id);
    return (await externalAccountById(id))!;
  }

  Future<ExternalAccountRecord?> externalAccountById(String linkId) async {
    final row = await (_db.select(
      _db.externalAccounts,
    )..where((tbl) => tbl.linkId.equals(linkId))).getSingleOrNull();
    return row == null ? null : _mapExternalAccount(row);
  }

  Future<ExternalAccountRecord> verifyExternalAccount({
    required String channelId,
    required String linkId,
    required String method,
    String? evidence,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'external_account_verify',
    );
    if (existing != null) {
      final record = await externalAccountById(existing);
      if (record != null) {
        return record;
      }
    }
    await (_db.update(_db.externalAccounts)..where(
          (tbl) => tbl.linkId.equals(linkId) & tbl.channelId.equals(channelId),
        ))
        .write(
          ExternalAccountsCompanion(
            verificationState: const Value('verified'),
            provenance: Value('verified:$method:${evidence ?? 'demo'}'),
          ),
        );
    await _saveIdempotency(idempotencyKey, 'external_account_verify', linkId);
    return (await externalAccountById(linkId))!;
  }

  Future<void> unlinkExternalAccount({
    required String channelId,
    required String linkId,
  }) {
    return (_db.delete(_db.externalAccounts)..where(
          (tbl) => tbl.linkId.equals(linkId) & tbl.channelId.equals(channelId),
        ))
        .go();
  }

  Future<PublicMetadataImportJobRecord> startPublicMetadataImport({
    required String channelId,
    required String externalAccountLinkId,
    required String rightsBasis,
    required int maxItems,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'public_metadata_import',
    );
    if (existing != null) {
      final job = await publicMetadataImportJob(existing);
      if (job != null) {
        return job;
      }
    }
    final account = await externalAccountById(externalAccountLinkId);
    if (account == null || account.verificationState != 'verified') {
      throw StateError('A verified external account is required for import.');
    }
    final id = 'public_import_${_slug(idempotencyKey)}';
    await _db
        .into(_db.publicMetadataImportJobs)
        .insertOnConflictUpdate(
          PublicMetadataImportJobsCompanion.insert(
            jobId: id,
            channelId: channelId,
            externalAccountLinkId: externalAccountLinkId,
            rightsBasis: rightsBasis,
            status: 'processing',
            importedCount: 0,
            skippedCount: 0,
            message: Value(
              'Importing public metadata from ${account.platform}',
            ),
            pollCount: 0,
            createdAt: _now(),
            updatedAt: _now(),
          ),
        );
    await _saveIdempotency(idempotencyKey, 'public_metadata_import', id);
    return (await publicMetadataImportJob(id))!;
  }

  Future<PublicMetadataImportJobRecord?> publicMetadataImportJob(
    String jobId,
  ) async {
    final row = await (_db.select(
      _db.publicMetadataImportJobs,
    )..where((tbl) => tbl.jobId.equals(jobId))).getSingleOrNull();
    return row == null ? null : _mapPublicMetadataImportJob(row);
  }

  Future<PublicMetadataImportJobRecord> advancePublicMetadataImportJob(
    String jobId,
  ) async {
    final row = await (_db.select(
      _db.publicMetadataImportJobs,
    )..where((tbl) => tbl.jobId.equals(jobId))).getSingle();
    if (row.status == 'complete') {
      return _mapPublicMetadataImportJob(row);
    }
    final account = await externalAccountById(row.externalAccountLinkId);
    final platform = account?.platform ?? 'external';
    final samples = _publicMetadataImportItems(platform);
    await _db.transaction(() async {
      for (final item in samples) {
        await _db
            .into(_db.publicImportedReferences)
            .insertOnConflictUpdate(
              PublicImportedReferencesCompanion.insert(
                referenceId: 'pubref_${_slug(jobId)}_${_slug(item.externalId)}',
                jobId: jobId,
                channelId: row.channelId,
                platform: platform,
                externalId: item.externalId,
                title: item.title,
                description: Value(item.summary),
                thumbnailRef: Value(item.thumbnailRef),
                sourceUrl: Value(
                  'https://$platform.example/${item.externalId}',
                ),
                embedKind: Value(
                  platform == 'youtube' ? 'youtube_iframe' : 'link',
                ),
                accurateMatchLabel: Value(
                  'Accurate match for ${item.title.toLowerCase()}',
                ),
                sourceAttribution: Value(_sourceAttributionLabel(platform)),
                publishedAt: Value(_now().subtract(const Duration(days: 4))),
                rightsBasis: row.rightsBasis,
                searchIndexable: true,
                aiQueryable: row.rightsBasis != 'public_reference_only',
                createdAt: _now(),
              ),
            );
      }
      await (_db.update(
        _db.publicMetadataImportJobs,
      )..where((tbl) => tbl.jobId.equals(jobId))).write(
        PublicMetadataImportJobsCompanion(
          status: const Value('complete'),
          importedCount: Value(samples.length),
          skippedCount: const Value(0),
          message: const Value('Imported public metadata references.'),
          pollCount: Value(row.pollCount + 1),
          updatedAt: Value(_now()),
        ),
      );
    });
    return (await publicMetadataImportJob(jobId))!;
  }

  Future<List<PublicImportedReferenceRecord>> publicImportedReferences({
    required String channelId,
    String? jobId,
  }) async {
    final query = _db.select(_db.publicImportedReferences)
      ..where((tbl) => tbl.channelId.equals(channelId));
    if (jobId != null) {
      query.where((tbl) => tbl.jobId.equals(jobId));
    }
    final rows = await query.get();
    return rows.map(_mapPublicImportedReference).toList(growable: false);
  }

  Future<CrossPostRecord> createCrossPost({
    required String channelId,
    required List<String> targetLinkIds,
    required String message,
    String? announcementId,
    String? contentRef,
    String? captureLinkUrl,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(idempotencyKey, 'cross_post');
    if (existing != null) {
      final post = await crossPostById(existing);
      if (post != null) {
        return post;
      }
    }
    final accounts = <ExternalAccountRecord>[];
    for (final linkId in targetLinkIds) {
      final account = await externalAccountById(linkId);
      if (account != null && account.verificationState == 'verified') {
        accounts.add(account);
      }
    }
    if (accounts.isEmpty) {
      throw StateError('At least one verified external account is required.');
    }
    final targets = accounts
        .map(
          (account) => CrossPostTargetRecord(
            targetLinkId: account.linkId,
            platform: account.platform,
            deliveryStatus: 'processing',
            message: message,
          ),
        )
        .toList(growable: false);
    final id = 'cross_${_slug(idempotencyKey)}';
    await _db
        .into(_db.crossPostJobs)
        .insertOnConflictUpdate(
          CrossPostJobsCompanion.insert(
            crossPostId: id,
            channelId: channelId,
            message: message,
            targetLinkIdsJson: jsonEncode(targetLinkIds),
            targetsJson: jsonEncode(
              targets.map(_crossPostTargetToJson).toList(),
            ),
            announcementId: Value(announcementId),
            contentRef: Value(contentRef),
            captureLinkUrl: Value(captureLinkUrl),
            pollCount: 0,
            createdAt: _now(),
            updatedAt: _now(),
          ),
        );
    await _saveIdempotency(idempotencyKey, 'cross_post', id);
    return (await crossPostById(id))!;
  }

  Future<CrossPostRecord?> crossPostById(String crossPostId) async {
    final row = await (_db.select(
      _db.crossPostJobs,
    )..where((tbl) => tbl.crossPostId.equals(crossPostId))).getSingleOrNull();
    return row == null ? null : _mapCrossPost(row);
  }

  Future<CrossPostRecord> advanceCrossPost(String crossPostId) async {
    final row = await (_db.select(
      _db.crossPostJobs,
    )..where((tbl) => tbl.crossPostId.equals(crossPostId))).getSingle();
    if (row.pollCount > 0) {
      return _mapCrossPost(row);
    }
    final completed = _decodeCrossPostTargets(row.targetsJson)
        .map(
          (target) => CrossPostTargetRecord(
            targetLinkId: target.targetLinkId,
            platform: target.platform,
            deliveryStatus: 'complete',
            externalPostUrl:
                'https://${target.platform}.example/post/${_slug(row.crossPostId)}',
            message: target.message,
          ),
        )
        .toList(growable: false);
    await (_db.update(
      _db.crossPostJobs,
    )..where((tbl) => tbl.crossPostId.equals(crossPostId))).write(
      CrossPostJobsCompanion(
        targetsJson: Value(
          jsonEncode(completed.map(_crossPostTargetToJson).toList()),
        ),
        pollCount: Value(row.pollCount + 1),
        updatedAt: Value(_now()),
      ),
    );
    return (await crossPostById(crossPostId))!;
  }

  Future<List<CrossPostRecord>> crossPosts(String channelId) async {
    final rows =
        await (_db.select(_db.crossPostJobs)
              ..where((tbl) => tbl.channelId.equals(channelId))
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
            .get();
    return rows.map(_mapCrossPost).toList(growable: false);
  }

  Future<AdDecisionRecord> decideAds({
    required String contentId,
    required String adPosture,
    required String entitlementState,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(idempotencyKey, 'ad_decision');
    if (existing != null) {
      final decision = await adDecisionById(existing);
      if (decision != null) {
        return decision;
      }
    }
    final content = await contentById(contentId);
    if (content == null) {
      throw StateError('No content exists for $contentId');
    }
    final policy = await creatorAdPolicy(content.creatorId);
    final noAds = entitlementState == 'premium_no_ad' || adPosture == 'none';
    final inventory = noAds
        ? const <AdInventoryRecord>[]
        : await adInventory(
            allowedCategories: policy?.allowedCategories ?? const [],
            blockedCategories: policy?.blockedCategories ?? const [],
            surface: 'watch',
          );
    final limit = adPosture == 'reduced' ? 1 : 2;
    final selected = inventory
        .take(limit)
        .map(
          (ad) => SelectedAdRecord(
            adId: ad.id,
            brand: ad.brandName,
            category: ad.category,
            disclosure:
                'Contextual ad selected from creator policy; no behavioral targeting.',
            selectionBasis: 'creator_policy_contextual',
          ),
        )
        .toList(growable: false);
    final id = 'ad_decision_${_slug(idempotencyKey)}';
    await _db
        .into(_db.adDecisions)
        .insertOnConflictUpdate(
          AdDecisionsCompanion.insert(
            decisionId: id,
            contentId: contentId,
            adsJson: jsonEncode(selected.map(_selectedAdToJson).toList()),
            policyVersion: Value(
              policy == null
                  ? null
                  : 'creator-policy-${_slug(content.creatorId)}-${policy.updatedAt.millisecondsSinceEpoch}',
            ),
            createdAt: _now(),
          ),
        );
    await _saveIdempotency(idempotencyKey, 'ad_decision', id);
    return (await adDecisionById(id))!;
  }

  Future<AdDecisionRecord?> adDecisionById(String decisionId) async {
    final row = await (_db.select(
      _db.adDecisions,
    )..where((tbl) => tbl.decisionId.equals(decisionId))).getSingleOrNull();
    return row == null ? null : _mapAdDecision(row);
  }

  Future<AdImpressionRecord> recordAdImpression({
    required String decisionId,
    required String adId,
    required bool completed,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(idempotencyKey, 'ad_impression');
    if (existing != null) {
      final row = await (_db.select(
        _db.adImpressions,
      )..where((tbl) => tbl.id.equals(existing))).getSingleOrNull();
      if (row != null) {
        return _mapAdImpression(row);
      }
    }
    final decision = await adDecisionById(decisionId);
    if (decision == null || !decision.ads.any((ad) => ad.adId == adId)) {
      throw StateError('No matching ad decision exists.');
    }
    await ensureDemoPassport();
    final id = 'adimp_${_slug(idempotencyKey)}';
    final receiptId = 'receipt_addecision_${_slug(id)}';
    await _db.transaction(() async {
      await _db
          .into(_db.receipts)
          .insertOnConflictUpdate(
            ReceiptsCompanion.insert(
              id: receiptId,
              type: 'adImpression',
              passportId: 'passport_demo_fan',
              contentId: decision.contentId,
              authorizationId: decisionId,
              summary:
                  'Contextual ad impression recorded from creator-policy decision.',
              createdAt: _now(),
            ),
          );
      await _db
          .into(_db.adImpressions)
          .insertOnConflictUpdate(
            AdImpressionsCompanion.insert(
              id: id,
              decisionId: decisionId,
              adId: adId,
              completed: completed,
              receiptId: Value(receiptId),
              createdAt: _now(),
            ),
          );
      await _saveIdempotency(idempotencyKey, 'ad_impression', id);
    });
    final row = await (_db.select(
      _db.adImpressions,
    )..where((tbl) => tbl.id.equals(id))).getSingle();
    return _mapAdImpression(row);
  }

  Future<PremiumNoAdStatusRecord> premiumNoAdStatus(String passportId) async {
    await ensureDemoPassport(passportId: passportId);
    final grants = await activeEntitlements(
      passportId: passportId,
      codes: const ['premium_no_ads'],
    );
    final grant = grants.isEmpty ? null : grants.first;
    return PremiumNoAdStatusRecord(
      passportId: passportId,
      active: grant != null,
      entitlementId: grant?.id,
      since: grant?.grantedAt,
      renewsAt: grant?.grantedAt.add(const Duration(days: 30)),
    );
  }

  Future<PremiumNoAdEventRecord> recordPremiumNoAdView({
    required String passportId,
    required String contentId,
    String? channelId,
    String? sessionIntent,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'premium_no_ad_event',
    );
    if (existing != null) {
      final row = await (_db.select(
        _db.premiumNoAdEvents,
      )..where((tbl) => tbl.id.equals(existing))).getSingleOrNull();
      if (row != null) {
        return _mapPremiumNoAdEvent(row);
      }
    }
    final status = await premiumNoAdStatus(passportId);
    final content = await contentById(contentId);
    if (content == null) {
      throw StateError('No content exists for $contentId');
    }
    final resolvedChannelId = channelId ?? content.creatorId;
    final id = 'noad_${_slug(idempotencyKey)}';
    final receiptId = status.active ? 'receipt_noad_${_slug(id)}' : null;
    await _db.transaction(() async {
      if (status.active) {
        await _db
            .into(_db.receipts)
            .insertOnConflictUpdate(
              ReceiptsCompanion.insert(
                id: receiptId!,
                type: 'premiumNoAd',
                passportId: passportId,
                contentId: contentId,
                authorizationId: id,
                summary:
                    'Premium no-ad view allocated to creator without serving an ad.',
                createdAt: _now(),
              ),
            );
      }
      await _db
          .into(_db.premiumNoAdEvents)
          .insertOnConflictUpdate(
            PremiumNoAdEventsCompanion.insert(
              id: id,
              passportId: passportId,
              contentId: contentId,
              channelId: Value(resolvedChannelId),
              sessionIntent: Value(sessionIntent),
              receiptId: Value(receiptId),
              createdAt: _now(),
            ),
          );
      await _saveIdempotency(idempotencyKey, 'premium_no_ad_event', id);
    });
    final row = await (_db.select(
      _db.premiumNoAdEvents,
    )..where((tbl) => tbl.id.equals(id))).getSingle();
    return _mapPremiumNoAdEvent(row);
  }

  Future<void> _ensureLinkInBioForCreator(
    CreatorRecord creator,
    String captureToken,
  ) {
    return _db
        .into(_db.linkInBioPages)
        .insertOnConflictUpdate(
          LinkInBioPagesCompanion.insert(
            channelId: creator.id,
            handle: creator.handle,
            displayName: creator.displayName,
            avatarRef: creator.avatarRef,
            captureLinkUrl: _captureUrl(captureToken),
            qrPayload: _qrPayload(captureToken),
            externalLinksJson: jsonEncode(
              _linkInBioExternalLinks(
                SeedCreator(
                  id: creator.id,
                  handle: creator.handle,
                  displayName: creator.displayName,
                  vertical: creator.vertical,
                  avatarRef: creator.avatarRef,
                ),
              ),
            ),
            updatedAt: _now(),
          ),
        );
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

  Future<void> _ensureSearchAgentConfig(String passportId) async {
    await ensureDemoPassport(passportId: passportId);
    await _db
        .into(_db.fanSearchAgentConfigs)
        .insert(
          FanSearchAgentConfigsCompanion.insert(
            passportId: passportId,
            provider: 'anthropic_claude',
            mcpEndpoint: '',
            connected: false,
            preferCreators: true,
            externalSourcesEnabled: false,
            updatedAt: _now(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> _ensureExternalSourceConnections(String passportId) async {
    await ensureDemoPassport(passportId: passportId);
    for (final companion in _defaultExternalSourceConnectionCompanions(
      passportId,
    )) {
      await _db
          .into(_db.externalSourceConnections)
          .insert(companion, mode: InsertMode.insertOrIgnore);
    }
  }

  Future<ExternalSourceConnectionRecord?> _externalSourceConnectionById(
    String id,
  ) async {
    final row = await (_db.select(
      _db.externalSourceConnections,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapExternalSourceConnection(row);
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

FanSearchAgentConfigRecord _mapSearchAgentConfig(FanSearchAgentConfig row) {
  return FanSearchAgentConfigRecord(
    passportId: row.passportId,
    provider: row.provider,
    mcpEndpoint: row.mcpEndpoint,
    connected: row.connected,
    preferCreators: row.preferCreators,
    externalSourcesEnabled: row.externalSourcesEnabled,
    updatedAt: row.updatedAt,
  );
}

ExternalSourceConnectionRecord _mapExternalSourceConnection(
  ExternalSourceConnection row,
) {
  return ExternalSourceConnectionRecord(
    id: row.id,
    passportId: row.passportId,
    sourceType: row.sourceType,
    connected: row.connected,
    displayName: row.displayName,
    updatedAt: row.updatedAt,
  );
}

AiSearchRunRecord _mapAiSearchRun(AiSearchRun row) {
  return AiSearchRunRecord(
    runId: row.runId,
    passportId: row.passportId,
    query: row.query,
    agentProvider: row.agentProvider,
    resultRefs: _decodeStringList(row.resultRefsJson),
    receiptId: row.receiptId,
    createdAt: row.createdAt,
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

ExportJobRecord _mapExportJob(ExportJob row) {
  return ExportJobRecord(
    id: row.id,
    creatorId: row.creatorId,
    state: row.state,
    pollCount: row.pollCount,
    bundleRef: row.bundleRef,
    bundleJson: row.bundleJson,
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

CaptureLinkRecord _mapCaptureLink(CaptureLink row) {
  return CaptureLinkRecord(
    token: row.token,
    channelId: row.channelId,
    url: row.url,
    channel: row.channel,
    qrPayload: row.qrPayload,
    starterPackEnabled: row.starterPackEnabled,
    createdAt: row.createdAt,
    expiresAt: row.expiresAt,
  );
}

ReFollowEventRecord _mapReFollowEvent(ReFollowEvent row) {
  return ReFollowEventRecord(
    id: row.id,
    token: row.token,
    passportId: row.passportId,
    channelId: row.channelId,
    followId: row.followId,
    channel: row.channel,
    followState: row.followState,
    pairwiseCreatorFanId: row.pairwiseCreatorFanId,
    createdAt: row.createdAt,
  );
}

AnnouncementTemplateRecord _mapAnnouncementTemplate(AnnouncementTemplate row) {
  return AnnouncementTemplateRecord(
    templateId: row.templateId,
    name: row.name,
    channel: row.channel,
    body: row.body,
    placeholders: _decodeStringList(row.placeholdersJson),
  );
}

RenderedAnnouncementRecord _mapRenderedAnnouncement(RenderedAnnouncement row) {
  return RenderedAnnouncementRecord(
    announcementId: row.announcementId,
    channelId: row.channelId,
    channel: row.channel,
    renderedBody: row.renderedBody,
    captureLinkUrl: row.captureLinkUrl,
    qrPayload: row.qrPayload,
    createdAt: row.createdAt,
  );
}

LinkInBioPageRecord _mapLinkInBioPage(LinkInBioPage row) {
  return LinkInBioPageRecord(
    channelId: row.channelId,
    handle: row.handle,
    displayName: row.displayName,
    avatarRef: row.avatarRef,
    captureLinkUrl: row.captureLinkUrl,
    qrPayload: row.qrPayload,
    externalLinks: _decodeStringMapList(row.externalLinksJson),
  );
}

StarterPackRecord _mapStarterPack(StarterPack row) {
  return StarterPackRecord(
    channelId: row.channelId,
    starterPackToken: row.starterPackToken,
    memberIds: _decodeStringList(row.memberIdsJson),
    defaultSelectedIds: _decodeStringList(row.defaultSelectedIdsJson),
    updatedAt: row.updatedAt,
  );
}

BulkFollowJobRecord _mapBulkFollowJob(BulkFollowJob row) {
  return BulkFollowJobRecord(
    id: row.id,
    channelId: row.channelId,
    passportId: row.passportId,
    followedIds: _decodeStringList(row.followedIdsJson),
    alreadyFollowingIds: _decodeStringList(row.alreadyFollowingIdsJson),
    feedReady: row.feedReady,
    createdAt: row.createdAt,
  );
}

ExternalAccountRecord _mapExternalAccount(ExternalAccount row) {
  return ExternalAccountRecord(
    linkId: row.linkId,
    channelId: row.channelId,
    platform: row.platform,
    handle: row.handle,
    profileUrl: row.profileUrl,
    verificationState: row.verificationState,
    linkedAt: row.linkedAt,
  );
}

PublicMetadataImportJobRecord _mapPublicMetadataImportJob(
  PublicMetadataImportJob row,
) {
  return PublicMetadataImportJobRecord(
    jobId: row.jobId,
    channelId: row.channelId,
    status: row.status,
    importedCount: row.importedCount,
    skippedCount: row.skippedCount,
    message: row.message,
  );
}

PublicImportedReferenceRecord _mapPublicImportedReference(
  PublicImportedReference row,
) {
  return PublicImportedReferenceRecord(
    referenceId: row.referenceId,
    channelId: row.channelId,
    platform: row.platform,
    externalId: row.externalId,
    title: row.title,
    description: row.description,
    thumbnailRef: row.thumbnailRef,
    sourceUrl: row.sourceUrl,
    embedKind: row.embedKind,
    accurateMatchLabel: row.accurateMatchLabel,
    sourceAttribution: row.sourceAttribution,
    creatorNote: row.creatorNote,
    publishedAt: row.publishedAt,
    rightsBasis: row.rightsBasis,
    searchIndexable: row.searchIndexable,
    aiQueryable: row.aiQueryable,
  );
}

CrossPostRecord _mapCrossPost(CrossPostJob row) {
  return CrossPostRecord(
    crossPostId: row.crossPostId,
    channelId: row.channelId,
    message: row.message,
    createdAt: row.createdAt,
    targets: _decodeCrossPostTargets(row.targetsJson),
    announcementId: row.announcementId,
    contentRef: row.contentRef,
    captureLinkUrl: row.captureLinkUrl,
  );
}

AdDecisionRecord _mapAdDecision(AdDecision row) {
  return AdDecisionRecord(
    decisionId: row.decisionId,
    contentId: row.contentId,
    ads: _decodeSelectedAds(row.adsJson),
    policyVersion: row.policyVersion,
  );
}

AdImpressionRecord _mapAdImpression(AdImpression row) {
  return AdImpressionRecord(
    id: row.id,
    decisionId: row.decisionId,
    adId: row.adId,
    recorded: true,
    receiptId: row.receiptId,
  );
}

PremiumNoAdEventRecord _mapPremiumNoAdEvent(PremiumNoAdEvent row) {
  return PremiumNoAdEventRecord(
    id: row.id,
    passportId: row.passportId,
    contentId: row.contentId,
    noAdApplied: row.receiptId != null,
    receiptId: row.receiptId,
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

List<Map<String, String>> _decodeStringMapList(String value) {
  final decoded = jsonDecode(value);
  if (decoded is! List) {
    return const [];
  }
  return decoded
      .whereType<Map<String, Object?>>()
      .map(
        (item) => {
          for (final entry in item.entries) entry.key: '${entry.value ?? ''}',
        },
      )
      .toList(growable: false);
}

List<SelectedAdRecord> _decodeSelectedAds(String value) {
  final decoded = jsonDecode(value);
  if (decoded is! List) {
    return const [];
  }
  return decoded
      .whereType<Map<String, Object?>>()
      .map(
        (item) => SelectedAdRecord(
          adId: '${item['adId'] ?? ''}',
          brand: '${item['brand'] ?? ''}',
          category: '${item['category'] ?? ''}',
          disclosure: '${item['disclosure'] ?? ''}',
          selectionBasis: '${item['selectionBasis'] ?? ''}',
        ),
      )
      .where((item) => item.adId.isNotEmpty)
      .toList(growable: false);
}

Map<String, Object?> _selectedAdToJson(SelectedAdRecord record) {
  return {
    'adId': record.adId,
    'brand': record.brand,
    'category': record.category,
    'disclosure': record.disclosure,
    'selectionBasis': record.selectionBasis,
  };
}

List<CrossPostTargetRecord> _decodeCrossPostTargets(String value) {
  final decoded = jsonDecode(value);
  if (decoded is! List) {
    return const [];
  }
  return decoded
      .whereType<Map<String, Object?>>()
      .map(
        (item) => CrossPostTargetRecord(
          targetLinkId: '${item['targetLinkId'] ?? ''}',
          platform: '${item['platform'] ?? ''}',
          deliveryStatus: '${item['deliveryStatus'] ?? 'processing'}',
          externalPostUrl: item['externalPostUrl'] as String?,
          message: item['message'] as String?,
        ),
      )
      .where((item) => item.targetLinkId.isNotEmpty)
      .toList(growable: false);
}

Map<String, Object?> _crossPostTargetToJson(CrossPostTargetRecord record) {
  return {
    'targetLinkId': record.targetLinkId,
    'platform': record.platform,
    'deliveryStatus': record.deliveryStatus,
    'externalPostUrl': record.externalPostUrl,
    'message': record.message,
  };
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

const _extensionManifestsKvKey = 'extensions.manifests';
const _extensionInstallsKvKey = 'extensions.installs';
const _extensionSessionsKvKey = 'extensions.sessions';
const _extensionEventsKvKey = 'extensions.events';
const _extensionStateKvKey = 'extensions.state';
const _creatorExperienceConfigsKvKey = 'creatorExperience.configs';

List<Map<String, Object?>> _decodeObjectMapList(String value) {
  final decoded = jsonDecode(value);
  if (decoded is! List) {
    return const [];
  }
  return decoded
      .whereType<Map<String, Object?>>()
      .map((item) => item.cast<String, Object?>())
      .toList(growable: false);
}

List<String> _stringListFromObject(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value.whereType<String>().toList(growable: false);
}

Map<String, String> _stringMapFromObject(Object? value) {
  if (value is! Map) {
    return const {};
  }
  return {
    for (final entry in value.entries) '${entry.key}': '${entry.value ?? ''}',
  };
}

Map<String, Object?> _objectMapFromObject(Object? value) {
  if (value is! Map) {
    return const {};
  }
  return value.cast<String, Object?>();
}

DateTime _dateFromObject(Object? value) {
  return DateTime.tryParse('$value') ?? _now();
}

ExtensionManifestRecord _extensionManifestFromJson(Map<String, Object?> item) {
  return ExtensionManifestRecord(
    extensionId: '${item['extensionId'] ?? ''}',
    name: '${item['name'] ?? ''}',
    category: '${item['category'] ?? ''}',
    riskTier: '${item['riskTier'] ?? 'low'}',
    surfaces: _stringListFromObject(item['surfaces']),
    permissions: _stringListFromObject(item['permissions']),
    exportBehavior: '${item['exportBehavior'] ?? 'creator_and_fan'}',
    certificationState: '${item['certificationState'] ?? 'submitted'}',
    latestVersion: '${item['latestVersion'] ?? '1.0.0'}',
    description: '${item['description'] ?? ''}',
  );
}

Map<String, Object?> _extensionManifestToJson(ExtensionManifestRecord record) {
  return {
    'extensionId': record.extensionId,
    'name': record.name,
    'category': record.category,
    'riskTier': record.riskTier,
    'surfaces': record.surfaces,
    'permissions': record.permissions,
    'exportBehavior': record.exportBehavior,
    'certificationState': record.certificationState,
    'latestVersion': record.latestVersion,
    'description': record.description,
  };
}

ExtensionInstallRecord _extensionInstallFromJson(Map<String, Object?> item) {
  return ExtensionInstallRecord(
    installId: '${item['installId'] ?? ''}',
    channelId: '${item['channelId'] ?? ''}',
    extensionId: '${item['extensionId'] ?? ''}',
    version: '${item['version'] ?? '1.0.0'}',
    approvedPermissions: _stringListFromObject(item['approvedPermissions']),
    approvedSurfaces: _stringListFromObject(item['approvedSurfaces']),
    config: _stringMapFromObject(item['config']),
    state: '${item['state'] ?? 'active'}',
    installedAt: _dateFromObject(item['installedAt']),
    updatedAt: _dateFromObject(item['updatedAt']),
  );
}

Map<String, Object?> _extensionInstallToJson(ExtensionInstallRecord record) {
  return {
    'installId': record.installId,
    'channelId': record.channelId,
    'extensionId': record.extensionId,
    'version': record.version,
    'approvedPermissions': record.approvedPermissions,
    'approvedSurfaces': record.approvedSurfaces,
    'config': record.config,
    'state': record.state,
    'installedAt': record.installedAt.toIso8601String(),
    'updatedAt': record.updatedAt.toIso8601String(),
  };
}

ExtensionSessionRecord _extensionSessionFromJson(Map<String, Object?> item) {
  return ExtensionSessionRecord(
    sessionId: '${item['sessionId'] ?? ''}',
    channelId: '${item['channelId'] ?? ''}',
    extensionId: '${item['extensionId'] ?? ''}',
    version: '${item['version'] ?? '1.0.0'}',
    surface: '${item['surface'] ?? ''}',
    fanId: '${item['fanId'] ?? ''}',
    pairwiseCreatorFanId: '${item['pairwiseCreatorFanId'] ?? ''}',
    state: '${item['state'] ?? 'active'}',
    allowedPermissions: _stringListFromObject(item['allowedPermissions']),
    createdAt: _dateFromObject(item['createdAt']),
  );
}

Map<String, Object?> _extensionSessionToJson(ExtensionSessionRecord record) {
  return {
    'sessionId': record.sessionId,
    'channelId': record.channelId,
    'extensionId': record.extensionId,
    'version': record.version,
    'surface': record.surface,
    'fanId': record.fanId,
    'pairwiseCreatorFanId': record.pairwiseCreatorFanId,
    'state': record.state,
    'allowedPermissions': record.allowedPermissions,
    'createdAt': record.createdAt.toIso8601String(),
  };
}

ExtensionEventRecord _extensionEventFromJson(Map<String, Object?> item) {
  return ExtensionEventRecord(
    eventId: '${item['eventId'] ?? ''}',
    sessionId: '${item['sessionId'] ?? ''}',
    type: '${item['type'] ?? ''}',
    payload: _stringMapFromObject(item['payload']),
    createdAt: _dateFromObject(item['createdAt']),
    idempotencyKey: '${item['idempotencyKey'] ?? ''}',
  );
}

Map<String, Object?> _extensionEventToJson(ExtensionEventRecord record) {
  return {
    'eventId': record.eventId,
    'sessionId': record.sessionId,
    'type': record.type,
    'payload': record.payload,
    'createdAt': record.createdAt.toIso8601String(),
    'idempotencyKey': record.idempotencyKey,
  };
}

ExtensionStateRecord _extensionStateFromJson(Map<String, Object?> item) {
  return ExtensionStateRecord(
    scopeKey: '${item['scopeKey'] ?? ''}',
    key: '${item['key'] ?? ''}',
    value: _stringMapFromObject(item['value']),
    exportBehavior: '${item['exportBehavior'] ?? 'creator_and_fan'}',
    updatedAt: _dateFromObject(item['updatedAt']),
  );
}

Map<String, Object?> _extensionStateToJson(ExtensionStateRecord record) {
  return {
    'scopeKey': record.scopeKey,
    'key': record.key,
    'value': record.value,
    'exportBehavior': record.exportBehavior,
    'updatedAt': record.updatedAt.toIso8601String(),
  };
}

ChannelThemeRecord _channelThemeFromJson(Map<String, Object?> item) {
  return ChannelThemeRecord(
    themeId: '${item['themeId'] ?? 'loom-default'}',
    name: '${item['name'] ?? 'Loom Default'}',
    primaryHex: '${item['primaryHex'] ?? '#1B4D3E'}',
    secondaryHex: '${item['secondaryHex'] ?? '#F2C94C'}',
    backgroundHex: '${item['backgroundHex'] ?? '#F8FAF8'}',
    surfaceHex: '${item['surfaceHex'] ?? '#FFFFFF'}',
    textHex: '${item['textHex'] ?? '#151A17'}',
    accentHex: '${item['accentHex'] ?? '#E56B2F'}',
  );
}

Map<String, Object?> _channelThemeToJson(ChannelThemeRecord record) {
  return {
    'themeId': record.themeId,
    'name': record.name,
    'primaryHex': record.primaryHex,
    'secondaryHex': record.secondaryHex,
    'backgroundHex': record.backgroundHex,
    'surfaceHex': record.surfaceHex,
    'textHex': record.textHex,
    'accentHex': record.accentHex,
  };
}

SurfaceModuleRecord _surfaceModuleFromJson(Map<String, Object?> item) {
  final extensionId = item['extensionId'];
  return SurfaceModuleRecord(
    moduleId: '${item['moduleId'] ?? ''}',
    kind: '${item['kind'] ?? 'content'}',
    title: '${item['title'] ?? ''}',
    surface: '${item['surface'] ?? 'feed_module'}',
    sortOrder: (item['sortOrder'] as num?)?.toInt() ?? 0,
    enabled: item['enabled'] != false,
    extensionId: extensionId == null || '$extensionId'.isEmpty
        ? null
        : '$extensionId',
    config: _stringMapFromObject(item['config']),
  );
}

Map<String, Object?> _surfaceModuleToJson(SurfaceModuleRecord record) {
  return {
    'moduleId': record.moduleId,
    'kind': record.kind,
    'title': record.title,
    'surface': record.surface,
    'sortOrder': record.sortOrder,
    'enabled': record.enabled,
    'extensionId': record.extensionId,
    'config': record.config,
  };
}

CreatorExperienceConfigRecord _creatorExperienceConfigFromJson(
  Map<String, Object?> item, {
  required List<ExtensionInstallRecord> installs,
  required List<ExtensionManifestRecord> manifests,
}) {
  final theme = _channelThemeFromJson(_objectMapFromObject(item['theme']));
  final modules =
      _stringObjectMapList(
          item['surfaceModules'],
        ).map(_surfaceModuleFromJson).toList(growable: false)
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  final installedIds = _stringListFromObject(item['installedExtensionIds']);
  final manifestsById = {
    for (final manifest in manifests) manifest.extensionId: manifest,
  };
  final installedRefs = installs
      .where(
        (install) =>
            install.state == 'active' &&
            (installedIds.isEmpty ||
                installedIds.contains(install.extensionId)),
      )
      .map((install) {
        final manifest = manifestsById[install.extensionId];
        return InstalledExtensionRefRecord(
          installId: install.installId,
          extensionId: install.extensionId,
          name: manifest?.name ?? install.extensionId,
          version: install.version,
          surfaces: install.approvedSurfaces,
          state: install.state,
          moduleIds: modules
              .where((module) => module.extensionId == install.extensionId)
              .map((module) => module.moduleId)
              .toList(growable: false),
        );
      })
      .toList(growable: false);
  return CreatorExperienceConfigRecord(
    channelId: '${item['channelId'] ?? ''}',
    theme: theme,
    bannerRef: '${item['bannerRef'] ?? 'seed://banners/default'}',
    surfaceModules: modules,
    aiPersona: '${item['aiPersona'] ?? 'Helpful creator archive guide'}',
    adPosture: '${item['adPosture'] ?? 'contextual_only'}',
    installedExtensions: installedRefs,
    version: (item['version'] as num?)?.toInt() ?? 1,
    updatedAt: _dateFromObject(item['updatedAt']),
  );
}

Map<String, Object?> _creatorExperienceConfigToJson(
  CreatorExperienceConfigRecord record,
) {
  return {
    'channelId': record.channelId,
    'theme': _channelThemeToJson(record.theme),
    'bannerRef': record.bannerRef,
    'surfaceModules': record.surfaceModules
        .map(_surfaceModuleToJson)
        .toList(growable: false),
    'aiPersona': record.aiPersona,
    'adPosture': record.adPosture,
    'installedExtensionIds': record.installedExtensions
        .map((install) => install.extensionId)
        .toList(growable: false),
    'version': record.version,
    'updatedAt': record.updatedAt.toIso8601String(),
  };
}

List<Map<String, Object?>> _stringObjectMapList(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value
      .whereType<Map<String, Object?>>()
      .map((item) => item.cast<String, Object?>())
      .toList(growable: false);
}

CreatorExperienceConfigRecord _defaultExperienceConfigForCreator(
  CreatorRecord creator,
) {
  return CreatorExperienceConfigRecord(
    channelId: creator.id,
    theme: const ChannelThemeRecord(
      themeId: 'loom-default',
      name: 'Loom Default',
      primaryHex: '#1B4D3E',
      secondaryHex: '#F2C94C',
      backgroundHex: '#F8FAF8',
      surfaceHex: '#FFFFFF',
      textHex: '#151A17',
      accentHex: '#E56B2F',
    ),
    bannerRef: 'seed://banners/${creator.handle}',
    surfaceModules: const [
      SurfaceModuleRecord(
        moduleId: 'hero',
        kind: 'hero',
        title: 'Creator home',
        surface: 'channel_header',
        sortOrder: 0,
        enabled: true,
        extensionId: null,
        config: {},
      ),
      SurfaceModuleRecord(
        moduleId: 'content_rail',
        kind: 'content',
        title: 'Latest from the archive',
        surface: 'feed_module',
        sortOrder: 1,
        enabled: true,
        extensionId: null,
        config: {},
      ),
    ],
    aiPersona: 'Helpful archive guide for ${creator.displayName}.',
    adPosture: 'contextual_only',
    installedExtensions: const [],
    version: 1,
    updatedAt: _now(),
  );
}

List<Map<String, Object?>> _extensionManifestSeedMaps() {
  return _extensionManifestSeeds
      .map(_extensionManifestToJson)
      .toList(growable: false);
}

List<Map<String, Object?>> _extensionInstallSeedMaps() {
  final now = _now();
  return _extensionInstallSeeds
      .map((seed) {
        final manifest = _extensionManifestSeeds.firstWhere(
          (candidate) => candidate.extensionId == seed.extensionId,
        );
        return _extensionInstallToJson(
          ExtensionInstallRecord(
            installId:
                'install_${_slug(seed.channelId)}_${_slug(seed.extensionId)}',
            channelId: seed.channelId,
            extensionId: seed.extensionId,
            version: manifest.latestVersion,
            approvedPermissions: seed.approvedPermissions,
            approvedSurfaces: seed.approvedSurfaces,
            config: seed.config,
            state: 'active',
            installedAt: now,
            updatedAt: now,
          ),
        );
      })
      .toList(growable: false);
}

List<Map<String, Object?>> _extensionStateSeedMaps() {
  final now = _now();
  return _extensionInstallSeeds
      .map(
        (seed) => _extensionStateToJson(
          ExtensionStateRecord(
            scopeKey: 'channel:${seed.channelId}:extension:${seed.extensionId}',
            key: 'seed_state',
            value: {
              'source': 'seed',
              'headline': seed.config['seedHeadline'] ?? seed.extensionId,
            },
            exportBehavior: 'creator_owned_exportable',
            updatedAt: now,
          ),
        ),
      )
      .toList(growable: false);
}

List<Map<String, Object?>> _creatorExperienceConfigSeedMaps() {
  final now = _now().toIso8601String();
  return [
    _creatorExperienceConfigSeedMap(
      channelId: 'creator_nova_clutch',
      theme: _themeSeed(
        'nova-arena',
        'Nova Arena',
        '#16213E',
        '#E94560',
        '#F6F8FF',
        '#FFFFFF',
        '#111827',
        '#22C55E',
      ),
      bannerRef: 'seed://banners/nova-clutch',
      aiPersona: 'Tactical coach that explains clutch decisions plainly.',
      adPosture: 'performance_gear_contextual',
      installedExtensionIds: const [
        'ext_clip_arena',
        'ext_pickem',
        'ext_hypewars',
      ],
      modules: [
        _moduleSeed('hero', 'hero', 'Match room', 'channel_header', 0),
        _moduleSeed(
          'clip_arena',
          'extension',
          'Clip Arena',
          'feed_module',
          1,
          extensionId: 'ext_clip_arena',
          config: const {
            'cta': 'Vote the clutch',
            'seedHeadline': 'Ace retakes',
          },
        ),
        _moduleSeed(
          'pickem',
          'extension',
          'Pick\'Em',
          'feed_module',
          2,
          extensionId: 'ext_pickem',
          config: const {
            'question': 'Next map MVP?',
            'options': 'Nova|Rival captain|Support ace',
            'seedHeadline': 'Map picks',
          },
        ),
        _moduleSeed(
          'hypewars',
          'extension',
          'HypeWars',
          'feed_module',
          3,
          extensionId: 'ext_hypewars',
          config: const {'goal': 'Clutch fund', 'goalCents': '20000'},
        ),
        _gamingExternalModuleSeed('creator_nova_clutch', 4),
        _moduleSeed('content_rail', 'content', 'Latest VODs', 'feed_module', 5),
      ],
      updatedAt: now,
    ),
    _creatorExperienceConfigSeedMap(
      channelId: 'creator_ember_hollow',
      theme: _themeSeed(
        'ember-lore',
        'Ember Lore',
        '#3F2E24',
        '#D97706',
        '#FAF7F2',
        '#FFFDF8',
        '#1F1712',
        '#4F9F69',
      ),
      bannerRef: 'seed://banners/ember-hollow',
      aiPersona: 'Warm lorekeeper for builds, prompts, and survival strategy.',
      adPosture: 'crafting_and_indie_games_contextual',
      installedExtensionIds: const ['ext_quest_log', 'ext_build_showcase'],
      modules: [
        _moduleSeed('hero', 'hero', 'Campfire hub', 'channel_header', 0),
        _moduleSeed(
          'quest_log',
          'extension',
          'Quest Log',
          'feed_module',
          1,
          extensionId: 'ext_quest_log',
          config: const {
            'quest': 'Restore the valley shrine',
            'description':
                'Finish a cozy build step and unlock the shrine badge.',
            'badge': 'Shrine keeper',
          },
        ),
        _moduleSeed(
          'build_showcase',
          'extension',
          'Build Showcase',
          'feed_module',
          2,
          extensionId: 'ext_build_showcase',
          config: const {'prompt': 'Cozy defense build'},
        ),
        _gamingExternalModuleSeed('creator_ember_hollow', 3),
        _moduleSeed(
          'content_rail',
          'content',
          'Build archive',
          'feed_module',
          4,
        ),
      ],
      updatedAt: now,
    ),
    _creatorExperienceConfigSeedMap(
      channelId: 'creator_frame_by_frame',
      theme: _themeSeed(
        'frame-splits',
        'Frame Splits',
        '#0B1F2A',
        '#38BDF8',
        '#F5FBFF',
        '#FFFFFF',
        '#0F172A',
        '#F97316',
      ),
      bannerRef: 'seed://banners/frame-by-frame',
      aiPersona: 'Precise speedrun analyst focused on splits and route risk.',
      adPosture: 'hardware_and_training_contextual',
      installedExtensionIds: const ['ext_clip_arena', 'ext_pickem'],
      modules: [
        _moduleSeed('hero', 'hero', 'Run desk', 'channel_header', 0),
        _moduleSeed(
          'clip_arena',
          'extension',
          'Clip Arena',
          'feed_module',
          1,
          extensionId: 'ext_clip_arena',
          config: const {'cta': 'Rank the save', 'seedHeadline': 'Split saves'},
        ),
        _moduleSeed(
          'pickem',
          'extension',
          'Pick\'Em',
          'feed_module',
          2,
          extensionId: 'ext_pickem',
          config: const {
            'question': 'PB this weekend?',
            'options': 'PB pace|Safe route|Reset city',
          },
        ),
        _gamingExternalModuleSeed('creator_frame_by_frame', 3),
        _moduleSeed('content_rail', 'content', 'Run reviews', 'feed_module', 4),
      ],
      updatedAt: now,
    ),
    _creatorExperienceConfigSeedMap(
      channelId: 'creator_drift_and_chill',
      theme: _themeSeed(
        'drift-night',
        'Drift Night',
        '#232946',
        '#B8C1EC',
        '#F7F7FB',
        '#FFFFFF',
        '#121629',
        '#F4D35E',
      ),
      bannerRef: 'seed://banners/drift-and-chill',
      aiPersona: 'Relaxed variety-stream guide with low-pressure prompts.',
      adPosture: 'community_and_streaming_contextual',
      installedExtensionIds: const [
        'ext_clip_arena',
        'ext_hypewars',
        'ext_build_showcase',
        'ext_guild_quest',
      ],
      modules: [
        _moduleSeed('hero', 'hero', 'Chill lobby', 'channel_header', 0),
        _moduleSeed(
          'hypewars',
          'extension',
          'HypeWars',
          'feed_module',
          1,
          extensionId: 'ext_hypewars',
          config: const {
            'goal': 'Unlock community queue',
            'goalCents': '15000',
          },
        ),
        _moduleSeed(
          'build_showcase',
          'extension',
          'Build Showcase',
          'feed_module',
          2,
          extensionId: 'ext_build_showcase',
          config: const {'prompt': 'Best cozy corner'},
        ),
        _moduleSeed(
          'guild_quest',
          'extension',
          'Guild Quest',
          'feed_module',
          3,
          extensionId: 'ext_guild_quest',
          config: const {
            'goal': 'Fill the community queue board',
            'target': '30',
            'milestones': 'Queue opened|Bonus co-op stream',
          },
        ),
        _gamingExternalModuleSeed('creator_drift_and_chill', 4),
        _moduleSeed(
          'content_rail',
          'content',
          'Stream archive',
          'feed_module',
          5,
        ),
      ],
      updatedAt: now,
    ),
    _creatorExperienceConfigSeedMap(
      channelId: 'creator_iron_vael',
      theme: _themeSeed(
        'iron-guild',
        'Iron Guild',
        '#1F2937',
        '#9CA3AF',
        '#F4F5F7',
        '#FFFFFF',
        '#111827',
        '#F59E0B',
      ),
      bannerRef: 'seed://banners/iron-vael',
      aiPersona: 'Guild strategist for raids, builds, and newcomer paths.',
      adPosture: 'guild_tools_contextual',
      installedExtensionIds: const [
        'ext_guild_quest',
        'ext_quest_log',
        'ext_hypewars',
        'ext_build_showcase',
      ],
      modules: [
        _moduleSeed('hero', 'hero', 'Guild hall', 'channel_header', 0),
        _moduleSeed(
          'guild_quest',
          'extension',
          'Guild Quest',
          'feed_module',
          1,
          extensionId: 'ext_guild_quest',
          config: const {'goal': 'Prepare the next raid wing'},
        ),
        _moduleSeed(
          'quest_log',
          'extension',
          'Quest Log',
          'feed_module',
          2,
          extensionId: 'ext_quest_log',
          config: const {
            'quest': 'First-week guild path',
            'description': 'Complete a starter raid prep task with the guild.',
            'badge': 'Raid-ready recruit',
          },
        ),
        _moduleSeed(
          'build_showcase',
          'extension',
          'Build Showcase',
          'feed_module',
          3,
          extensionId: 'ext_build_showcase',
          config: const {'prompt': 'Raid-ready build board'},
        ),
        _gamingExternalModuleSeed('creator_iron_vael', 4),
        _moduleSeed(
          'content_rail',
          'content',
          'Guild archive',
          'feed_module',
          5,
        ),
      ],
      updatedAt: now,
    ),
  ];
}

Map<String, Object?> _creatorExperienceConfigSeedMap({
  required String channelId,
  required Map<String, Object?> theme,
  required String bannerRef,
  required String aiPersona,
  required String adPosture,
  required List<String> installedExtensionIds,
  required List<Map<String, Object?>> modules,
  required String updatedAt,
}) {
  return {
    'channelId': channelId,
    'theme': theme,
    'bannerRef': bannerRef,
    'surfaceModules': modules,
    'aiPersona': aiPersona,
    'adPosture': adPosture,
    'installedExtensionIds': installedExtensionIds,
    'version': 1,
    'updatedAt': updatedAt,
  };
}

Map<String, Object?> _themeSeed(
  String themeId,
  String name,
  String primaryHex,
  String secondaryHex,
  String backgroundHex,
  String surfaceHex,
  String textHex,
  String accentHex,
) {
  return {
    'themeId': themeId,
    'name': name,
    'primaryHex': primaryHex,
    'secondaryHex': secondaryHex,
    'backgroundHex': backgroundHex,
    'surfaceHex': surfaceHex,
    'textHex': textHex,
    'accentHex': accentHex,
  };
}

Map<String, Object?> _moduleSeed(
  String moduleId,
  String kind,
  String title,
  String surface,
  int sortOrder, {
  String? extensionId,
  Map<String, String> config = const {},
}) {
  return {
    'moduleId': moduleId,
    'kind': kind,
    'title': title,
    'surface': surface,
    'sortOrder': sortOrder,
    'enabled': true,
    'extensionId': extensionId,
    'config': config,
  };
}

Map<String, Object?> _gamingExternalModuleSeed(
  String channelId,
  int sortOrder,
) {
  final seed = _gamingExternalSeedsForCreator(channelId).firstOrNull;
  if (seed == null) {
    return _moduleSeed(
      'external_watch',
      'external_content',
      'Creator-linked watch',
      'feed_module',
      sortOrder,
      config: const {},
    );
  }
  final referenceId = 'pubref_${_slug(channelId)}_youtube_1';
  return _moduleSeed(
    'external_watch',
    'external_content',
    'Creator-linked watch',
    'feed_module',
    sortOrder,
    config: {
      'referenceId': referenceId,
      'sourceType': 'youtube',
      'externalId': seed.videoId,
      'originalTitle': seed.title,
      'summary': seed.summary,
      'thumbnailRef': seed.thumbnailRef,
      'sourceUrl': 'https://www.youtube.com/watch?v=${seed.videoId}',
      'sourceAttribution': 'YouTube',
      'rightsBasis': 'public_reference_seed',
      'embedKind': 'youtube_iframe',
      'searchIndexable': 'true',
      'aiQueryable': 'true',
      'accurateMatchLabel': seed.accurateMatchLabel,
      'creatorNote': seed.creatorNote,
    },
  );
}

const _extensionManifestSeeds = [
  ExtensionManifestRecord(
    extensionId: 'ext_clip_arena',
    name: 'Clip Arena',
    category: 'competitive',
    riskTier: 'medium',
    surfaces: ['feed_module', 'video_overlay'],
    permissions: ['read_public_clips', 'write_fan_vote', 'issue_reward'],
    exportBehavior: 'creator_and_fan',
    certificationState: 'certified',
    latestVersion: '1.0.0',
    description: 'Fan-voted clip battles and creator-approved leaderboards.',
  ),
  ExtensionManifestRecord(
    extensionId: 'ext_pickem',
    name: 'Pick\'Em',
    category: 'competitive',
    riskTier: 'medium',
    surfaces: ['feed_module', 'community_panel'],
    permissions: ['write_prediction', 'read_aggregate_outcome', 'issue_reward'],
    exportBehavior: 'fan_owned',
    certificationState: 'certified',
    latestVersion: '1.0.0',
    description: 'Prediction prompts with aggregate-only outcomes.',
  ),
  ExtensionManifestRecord(
    extensionId: 'ext_hypewars',
    name: 'HypeWars',
    category: 'economy',
    riskTier: 'high',
    surfaces: ['feed_module', 'channel_header'],
    permissions: ['read_wallet_status', 'write_tip_event', 'issue_reward'],
    exportBehavior: 'creator_and_fan',
    certificationState: 'certified',
    latestVersion: '1.0.0',
    description: 'A transparent hype meter for tips, boosts, and unlock goals.',
  ),
  ExtensionManifestRecord(
    extensionId: 'ext_quest_log',
    name: 'Quest Log',
    category: 'collaborative',
    riskTier: 'low',
    surfaces: ['feed_module', 'community_panel'],
    permissions: ['write_progress', 'read_aggregate_progress', 'issue_reward'],
    exportBehavior: 'creator_and_fan',
    certificationState: 'certified',
    latestVersion: '1.0.0',
    description: 'Creator-authored community quests with badge progress.',
  ),
  ExtensionManifestRecord(
    extensionId: 'ext_build_showcase',
    name: 'Build Showcase',
    category: 'creative',
    riskTier: 'medium',
    surfaces: ['feed_module', 'gallery_panel'],
    permissions: ['write_submission', 'write_fan_vote', 'issue_reward'],
    exportBehavior: 'creator_and_fan',
    certificationState: 'certified',
    latestVersion: '1.0.0',
    description: 'Moderated fan build submissions and showcase voting.',
  ),
  ExtensionManifestRecord(
    extensionId: 'ext_guild_quest',
    name: 'Guild Quest',
    category: 'collaborative',
    riskTier: 'medium',
    surfaces: ['feed_module', 'community_panel'],
    permissions: ['write_progress', 'read_roster_status', 'issue_reward'],
    exportBehavior: 'creator_and_fan',
    certificationState: 'certified',
    latestVersion: '1.0.0',
    description: 'Shared guild goals, roster tasks, and milestone badges.',
  ),
];

const _extensionInstallSeeds = [
  _ExtensionInstallSeed(
    channelId: 'creator_nova_clutch',
    extensionId: 'ext_clip_arena',
    approvedPermissions: [
      'read_public_clips',
      'write_fan_vote',
      'issue_reward',
    ],
    approvedSurfaces: ['feed_module', 'video_overlay'],
    config: {'seedHeadline': 'Ace retakes'},
  ),
  _ExtensionInstallSeed(
    channelId: 'creator_nova_clutch',
    extensionId: 'ext_pickem',
    approvedPermissions: [
      'write_prediction',
      'read_aggregate_outcome',
      'issue_reward',
    ],
    approvedSurfaces: ['feed_module'],
    config: {'seedHeadline': 'Map picks'},
  ),
  _ExtensionInstallSeed(
    channelId: 'creator_nova_clutch',
    extensionId: 'ext_hypewars',
    approvedPermissions: [
      'read_wallet_status',
      'write_tip_event',
      'issue_reward',
    ],
    approvedSurfaces: ['feed_module', 'channel_header'],
    config: {'seedHeadline': 'Clutch fund'},
  ),
  _ExtensionInstallSeed(
    channelId: 'creator_ember_hollow',
    extensionId: 'ext_quest_log',
    approvedPermissions: [
      'write_progress',
      'read_aggregate_progress',
      'issue_reward',
    ],
    approvedSurfaces: ['feed_module', 'community_panel'],
    config: {'seedHeadline': 'Valley shrine'},
  ),
  _ExtensionInstallSeed(
    channelId: 'creator_ember_hollow',
    extensionId: 'ext_build_showcase',
    approvedPermissions: ['write_submission', 'write_fan_vote', 'issue_reward'],
    approvedSurfaces: ['feed_module', 'gallery_panel'],
    config: {'seedHeadline': 'Cozy defense builds'},
  ),
  _ExtensionInstallSeed(
    channelId: 'creator_frame_by_frame',
    extensionId: 'ext_clip_arena',
    approvedPermissions: [
      'read_public_clips',
      'write_fan_vote',
      'issue_reward',
    ],
    approvedSurfaces: ['feed_module', 'video_overlay'],
    config: {'seedHeadline': 'Split saves'},
  ),
  _ExtensionInstallSeed(
    channelId: 'creator_frame_by_frame',
    extensionId: 'ext_pickem',
    approvedPermissions: [
      'write_prediction',
      'read_aggregate_outcome',
      'issue_reward',
    ],
    approvedSurfaces: ['feed_module', 'community_panel'],
    config: {'seedHeadline': 'PB weekend'},
  ),
  _ExtensionInstallSeed(
    channelId: 'creator_drift_and_chill',
    extensionId: 'ext_clip_arena',
    approvedPermissions: [
      'read_public_clips',
      'write_fan_vote',
      'issue_reward',
    ],
    approvedSurfaces: ['feed_module'],
    config: {'seedHeadline': 'Chill queue clips'},
  ),
  _ExtensionInstallSeed(
    channelId: 'creator_drift_and_chill',
    extensionId: 'ext_hypewars',
    approvedPermissions: [
      'read_wallet_status',
      'write_tip_event',
      'issue_reward',
    ],
    approvedSurfaces: ['feed_module', 'channel_header'],
    config: {'seedHeadline': 'Community queue goal'},
  ),
  _ExtensionInstallSeed(
    channelId: 'creator_drift_and_chill',
    extensionId: 'ext_build_showcase',
    approvedPermissions: ['write_submission', 'write_fan_vote', 'issue_reward'],
    approvedSurfaces: ['feed_module', 'gallery_panel'],
    config: {'seedHeadline': 'Cozy corners'},
  ),
  _ExtensionInstallSeed(
    channelId: 'creator_drift_and_chill',
    extensionId: 'ext_guild_quest',
    approvedPermissions: [
      'write_progress',
      'read_roster_status',
      'issue_reward',
    ],
    approvedSurfaces: ['feed_module', 'community_panel'],
    config: {'seedHeadline': 'Queue board'},
  ),
  _ExtensionInstallSeed(
    channelId: 'creator_iron_vael',
    extensionId: 'ext_guild_quest',
    approvedPermissions: [
      'write_progress',
      'read_roster_status',
      'issue_reward',
    ],
    approvedSurfaces: ['feed_module', 'community_panel'],
    config: {'seedHeadline': 'Raid wing prep'},
  ),
  _ExtensionInstallSeed(
    channelId: 'creator_iron_vael',
    extensionId: 'ext_quest_log',
    approvedPermissions: [
      'write_progress',
      'read_aggregate_progress',
      'issue_reward',
    ],
    approvedSurfaces: ['feed_module', 'community_panel'],
    config: {'seedHeadline': 'First-week path'},
  ),
  _ExtensionInstallSeed(
    channelId: 'creator_iron_vael',
    extensionId: 'ext_build_showcase',
    approvedPermissions: ['write_submission', 'write_fan_vote', 'issue_reward'],
    approvedSurfaces: ['feed_module', 'gallery_panel'],
    config: {'seedHeadline': 'Raid builds'},
  ),
  _ExtensionInstallSeed(
    channelId: 'creator_iron_vael',
    extensionId: 'ext_hypewars',
    approvedPermissions: [
      'read_wallet_status',
      'write_tip_event',
      'issue_reward',
    ],
    approvedSurfaces: ['feed_module', 'channel_header'],
    config: {'seedHeadline': 'Raid boost'},
  ),
];

class _ExtensionInstallSeed {
  const _ExtensionInstallSeed({
    required this.channelId,
    required this.extensionId,
    required this.approvedPermissions,
    required this.approvedSurfaces,
    required this.config,
  });

  final String channelId;
  final String extensionId;
  final List<String> approvedPermissions;
  final List<String> approvedSurfaces;
  final Map<String, String> config;
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

class _AnnouncementTemplateSeed {
  const _AnnouncementTemplateSeed({
    required this.templateId,
    required this.name,
    required this.channel,
    required this.body,
    required this.placeholders,
  });

  final String templateId;
  final String name;
  final String channel;
  final String body;
  final List<String> placeholders;
}

const _announcementTemplateSeeds = [
  _AnnouncementTemplateSeed(
    templateId: 'launch_social_post',
    name: 'Social launch post',
    channel: 'social_post',
    body:
        'I am moving my creator hub to Loom. Follow {creatorName} here: {captureLink}',
    placeholders: ['creatorName', 'captureLink'],
  ),
  _AnnouncementTemplateSeed(
    templateId: 'launch_email',
    name: 'Audience email',
    channel: 'email',
    body:
        'Hi, it is {creatorName}. My archive, memberships, and no-ad support now live on Loom: {captureLink}',
    placeholders: ['creatorName', 'captureLink'],
  ),
  _AnnouncementTemplateSeed(
    templateId: 'launch_pinned_comment',
    name: 'Pinned video comment',
    channel: 'video_pinned_comment',
    body:
        'New hub for my full catalog and Q&A: {captureLink}. Starter pack included.',
    placeholders: ['captureLink'],
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
  if (creatorId.contains('nova')) {
    return const ['fps_esports', 'hollowfall', 'creator_tools'];
  }
  if (creatorId.contains('ember')) {
    return const ['survival_builders', 'hollowfall', 'creator_tools'];
  }
  if (creatorId.contains('frame')) {
    return const ['speedrunning', 'hollowfall', 'creator_tools'];
  }
  if (creatorId.contains('drift')) {
    return const ['variety_streams', 'hollowfall', 'creator_tools'];
  }
  if (creatorId.contains('iron')) {
    return const ['mmo_rpg', 'hollowfall', 'creator_tools'];
  }
  return const ['creator_tools'];
}

String _seedCaptureToken(String channelId) {
  return 'cap_${_slug(channelId)}_launch';
}

String _captureUrl(String token) {
  return 'https://loom.example/c/$token';
}

String _qrPayload(String token) {
  return 'loom://capture/$token';
}

String _starterPackToken(String channelId) {
  return 'starter_${_slug(channelId)}_launch';
}

List<String> _starterPackMemberIds(
  String channelId,
  Iterable<String> creatorIds,
) {
  final ids = creatorIds.toList();
  final ordered = [channelId, ...ids.where((id) => id != channelId)];
  return ordered.take(6).toList(growable: false);
}

List<Map<String, String>> _linkInBioExternalLinks(SeedCreator creator) {
  final handle = creator.handle;
  return [
    {'label': 'Watch archive', 'url': 'https://youtube.example/$handle'},
    {'label': 'Daily updates', 'url': 'https://instagram.example/$handle'},
    {
      'label': 'Creator-owned Loom hub',
      'url': _captureUrl(_seedCaptureToken(creator.id)),
    },
  ];
}

String _renderTemplate(String template, Map<String, String> fields) {
  var rendered = template;
  for (final entry in fields.entries) {
    rendered = rendered.replaceAll('{${entry.key}}', entry.value);
  }
  return rendered.replaceAll(RegExp(r'\{[a-zA-Z0-9_]+\}'), '');
}

List<_ImportItem> _publicMetadataImportItems(String platform) {
  return _sampleImportItems
      .map(
        (item) => _ImportItem(
          externalId: '$platform-${item['externalId']}',
          contentType: item['contentType']!,
          title: item['title']!,
          summary: item['summary']!,
          thumbnailRef: item['thumbnailRef']!,
        ),
      )
      .toList(growable: false);
}

List<ExternalSourceConnectionsCompanion>
_defaultExternalSourceConnectionCompanions(String passportId) {
  return const [
        ('youtube', 'YouTube'),
        ('twitch', 'Twitch'),
        ('discord', 'Discord'),
        ('blog', 'Creator blogs'),
        ('webpage', 'Open web'),
      ]
      .map((source) {
        final (sourceType, displayName) = source;
        return ExternalSourceConnectionsCompanion.insert(
          id: _externalSourceConnectionId(passportId, sourceType),
          passportId: passportId,
          sourceType: sourceType,
          connected: false,
          displayName: displayName,
          updatedAt: _now(),
        );
      })
      .toList(growable: false);
}

String _externalSourceConnectionId(String passportId, String sourceType) {
  return 'source_${_slug(passportId)}_${_slug(sourceType)}';
}

String _sourceAttributionLabel(String platform) {
  switch (platform) {
    case 'youtube':
      return 'YouTube';
    case 'twitch':
      return 'Twitch';
    case 'discord':
      return 'Discord';
    case 'blog':
      return 'Creator blog';
    case 'webpage':
      return 'Open web';
  }
  return platform;
}

bool _isGamingCreatorId(String creatorId) {
  return _gamingCreatorIds.contains(creatorId);
}

PublicMetadataImportJobsCompanion _gamingExternalImportJobSeed(
  SeedCreator creator,
) {
  final jobId = _gamingExternalImportJobId(creator.id);
  return PublicMetadataImportJobsCompanion.insert(
    jobId: jobId,
    channelId: creator.id,
    externalAccountLinkId: 'ext_${_slug(creator.id)}_youtube',
    rightsBasis: 'public_reference_seed',
    status: 'complete',
    importedCount: _gamingExternalSeedsForCreator(creator.id).length,
    skippedCount: 0,
    message: const Value('Seeded gaming YouTube references.'),
    pollCount: 1,
    createdAt: _now(),
    updatedAt: _now(),
  );
}

Iterable<PublicImportedReferencesCompanion> _gamingExternalReferenceSeeds(
  SeedCreator creator,
) {
  final seeds = _gamingExternalSeedsForCreator(creator.id);
  return seeds.asMap().entries.map((entry) {
    final index = entry.key + 1;
    final seed = entry.value;
    return PublicImportedReferencesCompanion.insert(
      referenceId: 'pubref_${_slug(creator.id)}_youtube_$index',
      jobId: _gamingExternalImportJobId(creator.id),
      channelId: creator.id,
      platform: 'youtube',
      externalId: seed.videoId,
      title: seed.title,
      description: Value(seed.summary),
      thumbnailRef: Value(seed.thumbnailRef),
      sourceUrl: Value('https://www.youtube.com/watch?v=${seed.videoId}'),
      embedKind: const Value('youtube_iframe'),
      accurateMatchLabel: Value(seed.accurateMatchLabel),
      sourceAttribution: const Value('YouTube'),
      creatorNote: Value(seed.creatorNote),
      publishedAt: Value(_now().subtract(Duration(days: 10 + index))),
      rightsBasis: 'public_reference_seed',
      searchIndexable: true,
      aiQueryable: true,
      createdAt: _now(),
    );
  });
}

String _gamingExternalImportJobId(String creatorId) {
  return 'public_import_seed_${_slug(creatorId)}_youtube';
}

List<_GamingExternalSeed> _gamingExternalSeedsForCreator(String creatorId) {
  return _gamingExternalSeeds[creatorId] ?? const [];
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
  if (creatorId.contains('nova')) {
    return const ['fps_esports', 'creator_tools'];
  }
  if (creatorId.contains('ember')) {
    return const ['survival_builders', 'creator_tools'];
  }
  if (creatorId.contains('frame')) {
    return const ['speedrunning', 'creator_tools'];
  }
  if (creatorId.contains('drift')) {
    return const ['variety_streams', 'creator_tools'];
  }
  if (creatorId.contains('iron')) {
    return const ['mmo_rpg', 'creator_tools'];
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

const _gamingCreatorIds = {
  'creator_nova_clutch',
  'creator_ember_hollow',
  'creator_frame_by_frame',
  'creator_drift_and_chill',
  'creator_iron_vael',
};

const _youtubePlayableDemoId = 'M7lc1UVf-VE';

const _gamingExternalSeeds = {
  'creator_nova_clutch': [
    _GamingExternalSeed(
      videoId: _youtubePlayableDemoId,
      title: 'NovaClutch VOD: 1v4 retake without comms chaos',
      summary:
          'Public YouTube VOD reference focused on clutch timing, utility discipline, and clean post-round review.',
      thumbnailRef: 'seed://youtube/nova-clutch-retake',
      accurateMatchLabel: 'Exact tactical retake breakdown',
      creatorNote: 'Start here when you want calm clutch review, not hype.',
    ),
  ],
  'creator_ember_hollow': [
    _GamingExternalSeed(
      videoId: _youtubePlayableDemoId,
      title: 'EmberHollow build log: raid-proof starter base',
      summary:
          'Public YouTube reference covering compact survival-builder layout choices and defensive upgrade order.',
      thumbnailRef: 'seed://youtube/ember-hollow-raid-base',
      accurateMatchLabel: 'Accurate raid-proof base walkthrough',
      creatorNote:
          'Good companion video for viewers planning their first wipe.',
    ),
  ],
  'creator_frame_by_frame': [
    _GamingExternalSeed(
      videoId: _youtubePlayableDemoId,
      title: 'FrameByFrame route lab: checkpoint skip explained',
      summary:
          'Public YouTube reference that slows a speedrun route down to setup, input timing, and reset risk.',
      thumbnailRef: 'seed://youtube/frame-by-frame-route-lab',
      accurateMatchLabel: 'Precise speedrun route explanation',
      creatorNote: 'The cleanest visual version of the skip discussion.',
    ),
  ],
  'creator_drift_and_chill': [
    _GamingExternalSeed(
      videoId: _youtubePlayableDemoId,
      title: 'DriftAndChill stream cut: cozy chaos lobby night',
      summary:
          'Public YouTube reference for a variety-streaming session with low-pressure highlights and community moments.',
      thumbnailRef: 'seed://youtube/drift-and-chill-lobby',
      accurateMatchLabel: 'Best match for cozy variety highlights',
      creatorNote: 'Use this when the feed needs community energy.',
    ),
  ],
  'creator_iron_vael': [
    _GamingExternalSeed(
      videoId: _youtubePlayableDemoId,
      title: 'IronVael raid prep: healer cooldown map',
      summary:
          'Public YouTube reference mapping MMO raid cooldown assignments, wipe recovery, and guild callouts.',
      thumbnailRef: 'seed://youtube/iron-vael-cooldowns',
      accurateMatchLabel: 'Grounded raid-prep cooldown guide',
      creatorNote: 'Best for fans who ask what to watch before raid night.',
    ),
  ],
};

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

class _GamingExternalSeed {
  const _GamingExternalSeed({
    required this.videoId,
    required this.title,
    required this.summary,
    required this.thumbnailRef,
    required this.accurateMatchLabel,
    required this.creatorNote,
  });

  final String videoId;
  final String title;
  final String summary;
  final String thumbnailRef;
  final String accurateMatchLabel;
  final String creatorNote;
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

int _parseExtensionInt(String? value, {required int fallback}) {
  return int.tryParse(value ?? '') ?? fallback;
}

DateTime _now() => DateTime.utc(2026, 5, 31, 12);
