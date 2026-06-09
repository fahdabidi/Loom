import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_fake_backend/loom_fake_backend.dart';
import 'package:loom_local_store/a5_engine_store_schema.dart';
import 'package:loom_seed_data/community_engine_seed_data.dart';
import 'package:loom_seed_data/community_foundation_seed_data.dart';
import 'package:loom_seed_data/community_registry_seed_data.dart';
import 'package:test/test.dart';

void main() {
  group('A5 extension-engine validation tests', () {
    test('vt_extension-runtime_session', () async {
      final harness = await _harnessWithRuntimePermission();
      final session = await harness.engine.runtime.startSession(
        extensionId: communityEngineSeed.extensionId,
        communityId: harness.community.communityId,
        passportId: communityFoundationSeed.ownerActorId,
        requestedPermissions: const ['content.publish'],
        idempotencyKey: 'runtime-session',
      );

      expect(session.permissions, contains('content.publish'));
      expect(
        A5EngineStoreSchema.tables.map((table) => table.componentId),
        contains('extension-runtime-bridge'),
      );
    });

    test('vt_extension-runtime_bridge-call', () async {
      final harness = await _harnessWithRuntimePermission();
      final session = await _runtimeSession(harness);
      final call = await harness.engine.runtime.callApi(
        session: session,
        apiName: 'CommunityPublishingApi.publishPost',
        arguments: const {'requiredPermission': 'content.publish'},
        idempotencyKey: 'runtime-call',
      );

      expect(call.allowed, isTrue);
    });

    test('vt_extension-runtime_permission', () async {
      final harness = await _harness();
      final session = await _runtimeSession(harness);
      final call = await harness.engine.runtime.callApi(
        session: session,
        apiName: 'CommunityPublishingApi.publishPost',
        arguments: const {'requiredPermission': 'content.publish'},
        idempotencyKey: 'runtime-denied',
      );

      expect(call.allowed, isFalse);
      expect(call.result['error'], 'permission-denied');
    });

    test('vt_rule-engine_evaluate', () async {
      final harness = await _harness();
      final decision = await harness.engine.rules.evaluate(
        ruleId: communityEngineSeed.ruleId,
        facts: const {'event': 'vote.closed'},
        whenEqualsKey: 'event',
        whenEqualsValue: 'vote.closed',
        action: 'start-workflow',
      );

      expect(decision.matched, isTrue);
    });

    test('vt_rule-engine_action', () async {
      final harness = await _harnessWithRuntimePermission();
      final session = await _runtimeSession(harness);
      final decision = await harness.engine.rules.evaluate(
        ruleId: communityEngineSeed.ruleId,
        facts: const {'event': 'vote.closed'},
        whenEqualsKey: 'event',
        whenEqualsValue: 'vote.closed',
        action: 'runtime:CommunityPublishingApi.publishPost',
      );
      final call = await harness.engine.runtime.callApi(
        session: session,
        apiName: decision.action.replaceFirst('runtime:', ''),
        arguments: const {'requiredPermission': 'content.publish'},
        idempotencyKey: 'rule-action-call',
      );

      expect(decision.action, contains('CommunityPublishingApi'));
      expect(call.allowed, isTrue);
    });

    test('vt_workflow-engine_start', () async {
      final harness = await _harness();
      final run = await harness.engine.workflows.startWorkflow(
        workflowId: communityEngineSeed.workflowId,
        firstStep: 'collect-nominations',
        idempotencyKey: 'workflow-start',
      );

      expect(run.state, CommunityWorkflowState.started);
    });

    test('vt_workflow-engine_transition', () async {
      final harness = await _harness();
      final run = await harness.engine.workflows.startWorkflow(
        workflowId: communityEngineSeed.workflowId,
        firstStep: 'collect-nominations',
        idempotencyKey: 'workflow-transition-start',
      );
      final transitioned = await harness.engine.workflows.transition(
        workflowRunId: run.workflowRunId,
        nextStep: 'publish-winner',
        complete: true,
        idempotencyKey: 'workflow-transition',
      );

      expect(transitioned.state, CommunityWorkflowState.completed);
      expect(transitioned.currentStep, 'publish-winner');
    });

    test('vt_job-scheduler_trigger', () async {
      final harness = await _harness();
      final job = await harness.engine.jobs.schedule(
        ruleId: communityEngineSeed.ruleId,
        trigger: 'cron:daily',
        idempotencyKey: 'job-schedule',
      );
      final triggered = await harness.engine.jobs.trigger(
        jobId: job.jobId,
        idempotencyKey: 'job-trigger',
      );

      expect(triggered.triggered, isTrue);
    });

    test('vt_function-runtime_sandbox-permission', () async {
      final harness = await _harness();
      final denied = await harness.engine.functions.invoke(
        functionId: communityEngineSeed.functionId,
        requestedPermissions: const ['documents.write'],
        grantedPermissions: const [],
        input: const {'title': 'Digest'},
        idempotencyKey: 'function-denied',
      );

      expect(denied.allowed, isFalse);
    });

    test('vt_data-schema_register', () async {
      final harness = await _harness();
      final schema = await harness.engine.dataSchemas.registerSchema(
        extensionId: communityEngineSeed.extensionId,
        schemaId: communityEngineSeed.schemaId,
        indexableFields: const ['title', 'author'],
        exportable: true,
        idempotencyKey: 'schema-register',
      );

      expect(schema.indexableFields, contains('title'));
    });

    test('vt_data-schema_export-index', () async {
      final harness = await _harness();
      await harness.engine.dataSchemas.registerSchema(
        extensionId: communityEngineSeed.extensionId,
        schemaId: communityEngineSeed.schemaId,
        indexableFields: const ['title', 'author'],
        exportable: true,
        idempotencyKey: 'schema-export-index',
      );
      final exportable = await harness.engine.dataSchemas.exportableSchemas(
        communityEngineSeed.extensionId,
      );

      expect(exportable.single.exportable, isTrue);
      expect(exportable.single.indexableFields, contains('author'));
    });

    test('vt_secrets-connector_scoped-secret', () async {
      final harness = await _harness();
      final secret = await harness.engine.secrets.storeSecret(
        extensionId: communityEngineSeed.extensionId,
        scope: 'provider:calendar',
        value: 'secret-token',
        idempotencyKey: 'secret-store',
      );

      expect(secret.redactedValue, 's***');
    });

    test('vt_extension-package_downloadable-shape', () async {
      final harness = await _harness();
      final validation = await harness.engine.extensionPackages.validatePackage(
        _validManifest(),
      );

      expect(validation.valid, isTrue);
    });

    test('vt_extension-package_asset-manifest', () async {
      final harness = await _harness();
      final validation = await harness.engine.extensionPackages.validatePackage(
        _validManifest(),
      );

      expect(validation.errors, isEmpty);
    });

    test('vt_extension-package_asset-policy', () async {
      final harness = await _harness();
      final validation = await harness.engine.extensionPackages.validatePackage(
        CommunityExtensionPackageManifest(
          extensionId: communityEngineSeed.extensionId,
          version: communityEngineSeed.extensionVersion,
          files: _requiredPackageFiles,
          defaultCardImage: 'assets/brand/default-card-image.png',
          assets: const [
            CommunityPackageAsset(
              path: 'assets/brand/default-card-image.gif',
              sha256: 'bad',
              kind: 'gif',
              width: 4096,
              height: 4096,
              altText: '',
            ),
          ],
        ),
      );

      expect(validation.valid, isFalse);
      expect(validation.errors, contains('unsupported-asset:assets/brand/default-card-image.gif'));
    });

    test('vt_initialization-package_schema', () async {
      final harness = await _harness();
      final validation = await harness.engine.initializationPackages
          .validateInitialization(_validInitialization());

      expect(validation.valid, isTrue);
    });

    test('vt_initialization-package_idempotency', () async {
      final harness = await _harness();
      final first = await harness.engine.initializationPackages
          .validateInitialization(_validInitialization());
      final second = await harness.engine.initializationPackages
          .validateInitialization(_validInitialization());

      expect(second.importKey, first.importKey);
      expect(second.packageId, first.packageId);
    });

    test('vt_initialization-package_community-branding', () async {
      final harness = await _harness();
      final validation = await harness.engine.initializationPackages
          .validateInitialization(_validInitialization());

      expect(validation.brandingComplete, isTrue);
    });
  });

  group('A5 built-counterpart consumer contract tests', () {
    test('ct_rule-engine__extension-runtime_action-dispatch', () async {
      final harness = await _harnessWithRuntimePermission();
      final session = await _runtimeSession(harness);
      final decision = await harness.engine.rules.evaluate(
        ruleId: communityEngineSeed.ruleId,
        facts: const {'event': 'approved'},
        whenEqualsKey: 'event',
        whenEqualsValue: 'approved',
        action: 'CommunityPublishingApi.publishPost',
      );
      final call = await harness.engine.runtime.callApi(
        session: session,
        apiName: decision.action,
        arguments: const {'requiredPermission': 'content.publish'},
        idempotencyKey: 'contract-rule-runtime',
      );

      expect(call.allowed, isTrue);
    });

    test('ct_job-scheduler__rule-engine_trigger', () async {
      final harness = await _harness();
      final job = await harness.engine.jobs.schedule(
        ruleId: communityEngineSeed.ruleId,
        trigger: 'event:vote.closed',
        idempotencyKey: 'contract-job',
      );
      final triggered = await harness.engine.jobs.trigger(
        jobId: job.jobId,
        idempotencyKey: 'contract-job-trigger',
      );
      final decision = await harness.engine.rules.evaluate(
        ruleId: triggered.ruleId,
        facts: const {'event': 'vote.closed'},
        whenEqualsKey: 'event',
        whenEqualsValue: 'vote.closed',
        action: 'start-workflow',
      );

      expect(triggered.triggered, isTrue);
      expect(decision.matched, isTrue);
    });

    test('ct_workflow-engine__case-task_transition', () async {
      final harness = await _harness();
      final caseTask = await harness.ops.caseTasks.openCase(
        communityId: harness.community.communityId,
        title: 'Workflow review',
        assigneePassportId: communityFoundationSeed.ownerActorId,
        idempotencyKey: 'contract-case-open',
      );
      final run = await harness.engine.workflows.startWorkflow(
        workflowId: communityEngineSeed.workflowId,
        firstStep: 'review',
        idempotencyKey: 'contract-workflow-start',
      );
      await harness.engine.workflows.transition(
        workflowRunId: run.workflowRunId,
        nextStep: 'resolved',
        complete: true,
        idempotencyKey: 'contract-workflow-transition',
      );
      final resolved = await harness.ops.caseTasks.transitionCase(
        caseId: caseTask.caseId,
        status: CommunityCaseStatus.resolved,
        actorPassportId: communityFoundationSeed.ownerActorId,
        idempotencyKey: 'contract-case-resolve',
      );

      expect(resolved.status, CommunityCaseStatus.resolved);
    });

    test('ct_data-schema-store__import-export_schema-enumeration', () async {
      final harness = await _harness();
      await harness.engine.dataSchemas.registerSchema(
        extensionId: communityEngineSeed.extensionId,
        schemaId: communityEngineSeed.schemaId,
        indexableFields: const ['title'],
        exportable: true,
        idempotencyKey: 'contract-schema-export',
      );
      final exportable = await harness.engine.dataSchemas.exportableSchemas(
        communityEngineSeed.extensionId,
      );

      expect(exportable.map((schema) => schema.schemaId), contains(communityEngineSeed.schemaId));
    });

    test('ct_export__components_enumerate', () async {
      final harness = await _harness();
      await harness.engine.dataSchemas.registerSchema(
        extensionId: communityEngineSeed.extensionId,
        schemaId: communityEngineSeed.schemaId,
        indexableFields: const ['title'],
        exportable: true,
        idempotencyKey: 'contract-export-components-schema',
      );
      final bundle = await harness.ops.exports.assemble(
        communityId: harness.community.communityId,
        redactProtectedData: true,
        idempotencyKey: 'contract-export-components',
      );
      final schemas = await harness.engine.dataSchemas.exportableSchemas(
        communityEngineSeed.extensionId,
      );

      expect(bundle.componentIds, contains('export-service'));
      expect(schemas.single.schemaId, communityEngineSeed.schemaId);
    });

    test('ct_data-schema-store__search_indexability', () async {
      final harness = await _harness();
      final schema = await harness.engine.dataSchemas.registerSchema(
        extensionId: communityEngineSeed.extensionId,
        schemaId: communityEngineSeed.schemaId,
        indexableFields: const ['title'],
        exportable: true,
        idempotencyKey: 'contract-schema-search',
      );

      expect(schema.indexableFields, contains('title'));
    });

    test('ct_extension-runtime__protected-vault_write', () async {
      final harness = await _harnessWithProtectedPermission();
      final session = await harness.engine.runtime.startSession(
        extensionId: communityEngineSeed.extensionId,
        communityId: harness.community.communityId,
        passportId: communityFoundationSeed.memberPassportId,
        requestedPermissions: const ['protected.write'],
        idempotencyKey: 'contract-runtime-protected-session',
      );
      final call = await harness.engine.runtime.callApi(
        session: session,
        apiName: 'CommunityProtectedVaultApi.writeProtectedRecord',
        arguments: const {'requiredPermission': 'protected.write'},
        idempotencyKey: 'contract-runtime-protected-call',
      );

      expect(call.allowed, isTrue);
    });
  });

  group('A1-A4 provider contracts unblocked by A5', () {
    test('ct_role-policy__extension-runtime_effective-permission', () async {
      final harness = await _harnessWithRuntimePermission();
      final session = await _runtimeSession(harness);

      expect(session.permissions, contains('content.publish'));
    });

    test('ct_event-bus__rule-engine_publish-replay', () async {
      final harness = await _harness();
      await harness.foundation.eventBus.publish(
        type: 'community.vote.closed',
        sourceComponent: 'forms-voting-service',
        subjectId: 'poll_1',
        payload: const {'event': 'vote.closed'},
        idempotencyKey: 'contract-event-rule',
      );
      final events = await harness.foundation.eventBus.replay(
        type: 'community.vote.closed',
      );
      final decision = await harness.engine.rules.evaluate(
        ruleId: communityEngineSeed.ruleId,
        facts: events.single.payload,
        whenEqualsKey: 'event',
        whenEqualsValue: 'vote.closed',
        action: 'start-workflow',
      );

      expect(decision.matched, isTrue);
    });

    test('ct_events__workflow-engine_event-registration', () async {
      final harness = await _harness();
      final event = await harness.experience.events.createEvent(
        communityId: harness.community.communityId,
        title: 'Book vote',
        capacity: 20,
        idempotencyKey: 'contract-event-workflow-event',
      );
      final run = await harness.engine.workflows.startWorkflow(
        workflowId: 'event-registration:${event.eventId}',
        firstStep: 'open-registration',
        idempotencyKey: 'contract-event-workflow',
      );

      expect(run.workflowId, contains(event.eventId));
    });

    test('ct_notification__workflow-engine_delivery', () async {
      final harness = await _harness();
      final run = await harness.engine.workflows.startWorkflow(
        workflowId: 'notify-members',
        firstStep: 'deliver',
        idempotencyKey: 'contract-notification-workflow',
      );
      final notification = await harness.experience.notifications.deliver(
        passportId: communityFoundationSeed.memberPassportId,
        channel: 'push',
        subject: 'Workflow reminder',
        dedupeKey: run.workflowRunId,
      );

      expect(notification.delivered, isTrue);
    });

    test('ct_case-task__workflow-engine_transition', () async {
      final harness = await _harness();
      final run = await harness.engine.workflows.startWorkflow(
        workflowId: communityEngineSeed.workflowId,
        firstStep: 'case-open',
        idempotencyKey: 'provider-case-workflow-start',
      );
      final transitioned = await harness.engine.workflows.transition(
        workflowRunId: run.workflowRunId,
        nextStep: 'case-resolved',
        complete: true,
        idempotencyKey: 'provider-case-workflow-transition',
      );

      expect(transitioned.state, CommunityWorkflowState.completed);
    });
  });

  group('A5 pending counterpart contract kits', () {
    test(
      'ct_extension-runtime__app-shell_session',
      () {},
      skip: 'app-shell-runtime is built in A6',
    );
    test(
      'ct_extension-package__demo-loader_validate-load',
      () {},
      skip: 'loom-communities-demo-app is built in A6',
    );
    test(
      'ct_initialization-package__fake-backend_import',
      () {},
      skip: 'local-in-app-backend is built in A6',
    );
    test(
      'ct_initialization-package__fake-backend_branding-import',
      () {},
      skip: 'local-in-app-backend is built in A6',
    );
  });
}

const _requiredPackageFiles = [
  'loom.extension.json',
  'ui/',
  'assets/',
  'schemas/',
  'rules/',
  'workflows/',
  'jobs/',
  'docs/',
];

CommunityExtensionPackageManifest _validManifest() {
  return CommunityExtensionPackageManifest(
    extensionId: communityEngineSeed.extensionId,
    version: communityEngineSeed.extensionVersion,
    files: _requiredPackageFiles,
    defaultCardImage: 'assets/brand/default-card-image.png',
    assets: const [
      CommunityPackageAsset(
        path: 'assets/brand/default-card-image.png',
        sha256: 'abc123',
        kind: 'png',
        width: 1024,
        height: 576,
        altText: 'Book club table',
      ),
    ],
  );
}

CommunityInitializationPackage _validInitialization() {
  return CommunityInitializationPackage(
    packageId: communityEngineSeed.initializationPackageId,
    communityHandle: communityRegistrySeed.handle,
    displayName: communityRegistrySeed.displayName,
    logoPath: 'seed/assets/logo.png',
    cardImagePath: 'seed/assets/card.png',
    heroImagePath: 'seed/assets/hero.png',
    accentColor: '#246B62',
    idempotencyKey: 'init-book-club',
  );
}

Future<_EngineHarness> _harness() async {
  final foundation = CommunityFoundationFakeBackend();
  final registry = CommunityRegistryControlPlaneFakeBackend(foundation);
  final community = await registry.communityRegistry.registerCommunity(
    handle: communityRegistrySeed.handle,
    displayName: communityRegistrySeed.displayName,
    branding: CommunityBranding(
      logoAssetId: communityRegistrySeed.logoAssetId,
      cardImageAssetId: communityRegistrySeed.cardImageAssetId,
      accentColor: '#246B62',
      altText: 'Book club table',
    ),
    ownerPassportId: communityFoundationSeed.ownerActorId,
    idempotencyKey: 'a5-register-community',
  );
  final experience = CommunityExperienceServicesFakeBackend(
    foundation: foundation,
    registry: registry,
  );
  final ops = CommunityOpsServicesFakeBackend(
    foundation: foundation,
    registry: registry,
    experience: experience,
  );
  final engine = CommunityEngineServicesFakeBackend(foundation: foundation);
  return _EngineHarness(
    foundation: foundation,
    registry: registry,
    experience: experience,
    ops: ops,
    engine: engine,
    community: community,
  );
}

Future<_EngineHarness> _harnessWithRuntimePermission() async {
  final harness = await _harness();
  await harness.foundation.rolePolicy.grantPermission(
    actorId: communityFoundationSeed.ownerActorId,
    communityId: harness.community.communityId,
    permission: 'content.publish',
    grantedBy: 'system',
    idempotencyKey: 'grant-a5-runtime',
  );
  return harness;
}

Future<_EngineHarness> _harnessWithProtectedPermission() async {
  final harness = await _harness();
  await harness.foundation.rolePolicy.grantPermission(
    actorId: communityFoundationSeed.memberPassportId,
    communityId: harness.community.communityId,
    permission: 'protected.write',
    grantedBy: 'system',
    idempotencyKey: 'grant-a5-protected',
  );
  return harness;
}

Future<CommunityExtensionSession> _runtimeSession(_EngineHarness harness) {
  return harness.engine.runtime.startSession(
    extensionId: communityEngineSeed.extensionId,
    communityId: harness.community.communityId,
    passportId: communityFoundationSeed.ownerActorId,
    requestedPermissions: const ['content.publish'],
    idempotencyKey: 'shared-runtime-session',
  );
}

class _EngineHarness {
  const _EngineHarness({
    required this.foundation,
    required this.registry,
    required this.experience,
    required this.ops,
    required this.engine,
    required this.community,
  });

  final CommunityFoundationFakeBackend foundation;
  final CommunityRegistryControlPlaneFakeBackend registry;
  final CommunityExperienceServicesFakeBackend experience;
  final CommunityOpsServicesFakeBackend ops;
  final CommunityEngineServicesFakeBackend engine;
  final CommunityProfile community;
}
