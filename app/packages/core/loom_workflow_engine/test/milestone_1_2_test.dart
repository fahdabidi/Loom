import 'dart:convert';
import 'dart:io';

import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Reuse the same marketplace fixture helper from M1.1 tests
// ---------------------------------------------------------------------------

LoomWorkflowStateMachine _loanMachine() {
  const json = '''
{
  "initialState": "draft",
  "states": {
    "draft":          { "label": "Draft",
                         "editableFields": ["title","category","condition","description"] },
    "published":      { "label": "Published", "tone": "positive" }
  },
  "transitions": [
    {
      "id": "submit-listing", "label": "Submit for review", "icon": "send", "tone": "primary",
      "from": ["draft"], "to": "published",
      "guard": { "allowedRoleIds": ["member", "member-1", "member-2", "member-owner"] }
    },
    {
      "id": "join-queue",
      "label": "Join queue", "icon": "add_circle_outline", "tone": "secondary",
      "from": ["published"], "to": null,
      "guard": {
        "allowedRoleIds": ["member", "member-1", "member-2", "alice", "bob", "member-owner"],
        "actorInList": { "key": "queuedFanIds", "present": false }
      },
      "effects": [{ "op": "appendUnique", "key": "queuedFanIds", "value": "\$actor" }]
    },
    {
      "id": "leave-queue",
      "label": "Leave queue", "icon": "remove_circle_outline", "tone": "secondary",
      "from": ["published"], "to": null,
      "guard": {
        "allowedRoleIds": ["member", "member-1", "member-2", "alice", "bob", "member-owner"],
        "actorInList": { "key": "queuedFanIds", "present": true }
      },
      "effects": [{ "op": "removeValue", "key": "queuedFanIds", "value": "\$actor" }]
    }
  ],
  "renderBindings": [
    { "states": ["draft"], "audience": "actor", "tabId": "marketplace",
      "cardSurfaceFamily": "listing-editor", "bindingKind": "primary" },
    { "states": ["published"], "audience": "any", "tabId": "marketplace",
      "cardSurfaceFamily": "equipment-loan", "bindingKind": "primary" }
  ],
  "instanceDataSchema": {
    "title": {
      "type": "text", "required": true,
      "writableBy": "formEntry", "storage": "inline",
      "searchable": true, "sortable": true
    },
    "category": {
      "type": "text", "required": false,
      "writableBy": "formEntry", "storage": "inline", "sortable": true
    },
    "condition": {
      "type": "text", "required": false,
      "writableBy": "formEntry", "storage": "inline", "sortable": true
    },
    "description": {
      "type": "textarea", "required": false, "maxLength": 500,
      "writableBy": "formEntry", "storage": "inline", "sortable": false
    },
    "holderFanId": {
      "type": "fanId?",
      "writableBy": "effect", "sortable": false
    },
    "queuedFanIds": {
      "type": "fanId[]",
      "writableBy": "effect"
    }
  }
}
''';
  return LoomWorkflowStateMachine.fromJson(
    jsonDecode(json) as Map<String, dynamic>,
    'equipment-loan',
  );
}

LocalWorkflowEngineApi _makeApi({String communityId = 'tabletop'}) {
  final db = WorkflowDatabase.memory();
  final api = LocalWorkflowEngineApi(db: db, communityId: communityId);
  for (final fanId in const [
    'member',
    'member-1',
    'member-2',
    'alice',
    'bob',
  ]) {
    api.setRoleForFan(fanId, 'member');
  }
  api.setRoleForFan('member-owner', 'member-owner');
  api.registerDefinition(_loanMachine());
  return api;
}

// ---------------------------------------------------------------------------
// The 7 validation tests from the Phase 1 doc milestone 1.2
// ---------------------------------------------------------------------------

void main() {
  group('Milestone 1.2 — WorkflowEngineApi + SQLite LocalWorkflowEngineApi', () {
    test(
      'WorkflowDatabase uses drift NativeDatabase SQLite, not a fallback store',
      () async {
        final db = WorkflowDatabase.memory();

        expect(db.isSqliteBacked, isTrue);
        expect(db.storageBackend, 'drift-native-sqlite');
        expect(await db.sqliteVersion(), matches(RegExp(r'^\d+\.\d+\.\d+')));

        await db.execute(
          'CREATE TABLE workflow_backing_probe (id TEXT PRIMARY KEY)',
        );
        await db.execute(
          "INSERT INTO workflow_backing_probe (id) VALUES ('ok')",
        );
        db.close();
      },
    );

    // ── 1. createInstance ────────────────────────────────────────────
    group('createInstance', () {
      test('valid data succeeds and returns a resolvable instanceId', () async {
        final api = _makeApi();

        final id = await api.createInstance(
          workflowType: 'equipment-loan',
          initialInstanceData: {
            'title': 'Catan',
            'category': 'Board Games',
            'condition': 'Like new',
            'description': 'A classic game.',
            'queuedFanIds': <String>[],
          },
          fanId: 'member-1',
        );

        expect(id, isNotEmpty);
        expect(id.startsWith('tabletop_equipment-loan_'), isTrue);

        // Resolvable via queryInstances.
        final page = await api.queryInstances(
          tabId: 'marketplace',
          fanId: 'member-1',
        );
        expect(page.items.any((i) => i.instanceId == id), isTrue);
      });

      test(
        'missing required field throws WorkflowValidationError naming the field',
        () async {
          final api = await _makeApi();

          await expectLater(
            api.createInstance(
              workflowType: 'equipment-loan',
              initialInstanceData: {
                'category': 'Board Games',
                // title is required but missing
              },
              fanId: 'member-1',
            ),
            throwsA(
              isA<WorkflowValidationError>().having(
                (e) => e.fieldName,
                'fieldName',
                'title',
              ),
            ),
          );
        },
      );
    });

    // ── 2. updateInstanceFields ──────────────────────────────────────
    group('updateInstanceFields', () {
      test('editing an editableField succeeds', () async {
        final api = await _makeApi();
        final id = await api.createInstance(
          workflowType: 'equipment-loan',
          initialInstanceData: {'title': 'Catan'},
          fanId: 'member-1',
        );

        // Instance starts in "draft" where all formEntry fields are editable.
        await api.updateInstanceFields(
          workflowType: 'equipment-loan',
          instanceId: id,
          fieldUpdates: {'title': 'Catan v2'},
          fanId: 'member-1',
        );

        final page = await api.queryInstances(
          tabId: 'marketplace',
          fanId: 'member-1',
        );
        final inst = page.items.firstWhere((i) => i.instanceId == id);
        expect(inst.instanceData['title'], 'Catan v2');
      });

      test('editing a non-editable field (holderFanId) is rejected', () async {
        final api = await _makeApi();
        final id = await api.createInstance(
          workflowType: 'equipment-loan',
          initialInstanceData: {'title': 'Catan'},
          fanId: 'member-1',
        );

        // holderFanId is writableBy: "effect" — not in editableFields.
        await expectLater(
          api.updateInstanceFields(
            workflowType: 'equipment-loan',
            instanceId: id,
            fieldUpdates: {'holderFanId': 'alice'},
            fanId: 'member-1',
          ),
          throwsA(isA<WorkflowAuthorizationError>()),
        );
      });

      test(
        'leaving required fields empty still succeeds (required NOT enforced here)',
        () async {
          final api = await _makeApi();
          final id = await api.createInstance(
            workflowType: 'equipment-loan',
            initialInstanceData: {'title': 'Catan', 'category': 'Board Games'},
            fanId: 'member-1',
          );

          // Update category without touching title (which is required).
          // Per §3c, required is NOT enforced on updateInstanceFields.
          await api.updateInstanceFields(
            workflowType: 'equipment-loan',
            instanceId: id,
            fieldUpdates: {'category': 'Strategy Games', 'title': ''},
            fanId: 'member-1',
          );

          final page = await api.queryInstances(
            tabId: 'marketplace',
            fanId: 'member-1',
          );
          final inst = page.items.firstWhere((i) => i.instanceId == id);
          expect(inst.instanceData['title'], '');
          expect(inst.instanceData['category'], 'Strategy Games');
        },
      );
    });

    // ── 3. applyTransition transactional-atomicity ────────────────────
    group('applyTransition — transactional atomicity', () {
      test(
        'two concurrent join-queue on same instance: exactly one succeeds',
        () async {
          final api = await _makeApi();

          // Create a published instance.
          final id = await api.createInstance(
            workflowType: 'equipment-loan',
            initialInstanceData: {'title': 'Catan', 'queuedFanIds': <String>[]},
            fanId: 'member',
          );
          // First, submit it so it's published.
          final result = await api.applyTransition(
            workflowType: 'equipment-loan',
            instanceId: id,
            transitionId: 'submit-listing',
            fanId: 'member',
          );
          expect(result.newState, 'published');

          // Two concurrent calls to join-queue — fire both without awaiting
          // the first before starting the second.
          final futures = <Future<bool>>[
            api
                .applyTransition(
                  workflowType: 'equipment-loan',
                  instanceId: id,
                  transitionId: 'join-queue',
                  fanId: 'member',
                )
                .then((_) => true)
                .catchError((_) => false),
            api
                .applyTransition(
                  workflowType: 'equipment-loan',
                  instanceId: id,
                  transitionId: 'join-queue',
                  fanId: 'member',
                )
                .then((_) => true)
                .catchError((_) => false),
          ];

          final results = await Future.wait(futures);

          // Exactly one succeeds — the guard sees the fan already in queue
          // after the first caller's effects commit.
          final successCount = results.where((r) => r == true).length;
          expect(
            successCount,
            1,
            reason: 'exactly one concurrent join-queue must succeed',
          );

          // Read back — exactly one entry (the fan once).
          final page = await api.queryInstances(
            tabId: 'marketplace',
            fanId: 'member-owner',
          );
          final inst = page.items.firstWhere((i) => i.instanceId == id);
          final queue = inst.instanceData['queuedFanIds'] as List;
          expect(queue, ['member']);
        },
      );
    });

    // ── 4. queryInstances keyset pagination ──────────────────────────
    group('queryInstances — keyset pagination', () {
      test('pages through > 1 page correctly with nextCursor', () async {
        final api = await _makeApi();

        // Seed 55 published listings (limit defaults to 25).
        for (var i = 0; i < 55; i++) {
          final id = await api.createInstance(
            workflowType: 'equipment-loan',
            initialInstanceData: {
              'title': 'Item ${i.toString().padLeft(3, '0')}',
              'queuedFanIds': <String>[],
            },
            fanId: 'member-1',
          );
          await api.applyTransition(
            workflowType: 'equipment-loan',
            instanceId: id,
            transitionId: 'submit-listing',
            fanId: 'member-1',
          );
        }

        // Page 1.
        var page = await api.queryInstances(
          tabId: 'marketplace',
          fanId: 'member-1',
          limit: 25,
        );
        expect(page.items.length, 25);
        expect(page.hasMore, isTrue);
        expect(page.nextCursor, isNotNull);
        // Verify cursor encodes the sort key.
        expect(page.nextCursor, startsWith('title\x1f'));

        // Page 2.
        page = await api.queryInstances(
          tabId: 'marketplace',
          fanId: 'member-1',
          limit: 25,
          cursor: page.nextCursor,
        );
        expect(page.items.length, 25);
        expect(page.hasMore, isTrue);
        expect(page.nextCursor, startsWith('title\x1f'));

        // Page 3 (final — should have 5 remaining).
        page = await api.queryInstances(
          tabId: 'marketplace',
          fanId: 'member-1',
          limit: 25,
          cursor: page.nextCursor,
        );
        expect(page.items.length, 5);
        expect(page.hasMore, isFalse);
        expect(page.nextCursor, isNull);
      });

      test(
        'concatenated pages contain every seeded instance exactly once in stable order',
        () async {
          final api = await _makeApi();
          const n = 30;
          for (var i = 0; i < n; i++) {
            await api.createInstance(
              workflowType: 'equipment-loan',
              initialInstanceData: {
                'title': 'Item ${i.toString().padLeft(3, '0')}',
                'queuedFanIds': <String>[],
              },
              fanId: 'member-1',
            );
          }

          final allIds = <String>{};
          String? cursor;
          var totalItems = 0;
          while (true) {
            final page = await api.queryInstances(
              tabId: 'marketplace',
              fanId: 'member-1',
              limit: 10,
              cursor: cursor,
            );
            for (final item in page.items) {
              allIds.add(item.instanceId);
            }
            totalItems += page.items.length;
            if (!page.hasMore) break;
            cursor = page.nextCursor;
          }

          expect(totalItems, n);
          expect(allIds.length, n); // no duplicates
        },
      );

      test(
        'insert between pages does not skip or duplicate rows (keyset stability)',
        () async {
          final api = await _makeApi();

          // Seed two items: "A" and "C".
          final idA = await api.createInstance(
            workflowType: 'equipment-loan',
            initialInstanceData: {'title': 'A', 'queuedFanIds': <String>[]},
            fanId: 'member-1',
          );
          final idC = await api.createInstance(
            workflowType: 'equipment-loan',
            initialInstanceData: {'title': 'C', 'queuedFanIds': <String>[]},
            fanId: 'member-1',
          );

          // Page 1: limit=1 → gets "A".
          var page = await api.queryInstances(
            tabId: 'marketplace',
            fanId: 'member-1',
            limit: 1,
            query: const SurfaceQuery(sort: SortSpec(key: 'title')),
          );
          expect(page.items.length, 1);
          expect(page.items.first.instanceId, idA);

          // Insert "0-Aardvark" which sorts BEFORE A (the cursor position).
          // With keyset pagination, a row inserted before the cursor should
          // NOT appear on page 2 (it's already past) and should NOT cause any
          // already-fetched row to be duplicated or skipped.
          await api.createInstance(
            workflowType: 'equipment-loan',
            initialInstanceData: {
              'title': '0-Aardvark',
              'queuedFanIds': <String>[],
            },
            fanId: 'member-1',
          );

          // Page 2: cursor still from after "A" → should get "C".
          page = await api.queryInstances(
            tabId: 'marketplace',
            fanId: 'member-1',
            limit: 1,
            cursor: page.nextCursor,
            query: const SurfaceQuery(sort: SortSpec(key: 'title')),
          );
          expect(page.items.length, 1);
          expect(
            page.items.first.instanceId,
            idC,
            reason:
                'page 2 should still return "C" — insert before cursor is invisible',
          );
        },
      );
    });

    // ── 5. queryInstances sort-change test ───────────────────────────
    group('queryInstances — sort change resets pagination', () {
      test('stale cursor from different sort key resets to page 1', () async {
        final api = await _makeApi();

        // Seed 6 items with title values that sort AFTER category values,
        // so a title-sorted cursor is visible as "different sort" when
        // used against a category sort.
        // Title: "Zeta-0".."Zeta-5", Category: "Alpha-0".."Alpha-5"
        for (var i = 0; i < 6; i++) {
          await api.createInstance(
            workflowType: 'equipment-loan',
            initialInstanceData: {
              'title': 'Zeta-${i.toString()}',
              'category': 'Alpha-${i.toString()}',
              'queuedFanIds': <String>[],
            },
            fanId: 'member-1',
          );
        }

        // Page 1 sorted by title → gets first 3 (limit=3).
        final page1 = await api.queryInstances(
          tabId: 'marketplace',
          fanId: 'member-1',
          limit: 3,
          query: const SurfaceQuery(sort: SortSpec(key: 'title')),
        );
        expect(page1.items.length, 3);
        // All items on page 1 should be sorted by title (Zeta-0, Zeta-1, Zeta-2).
        final titles1 = page1.items
            .map((i) => i.instanceData['title'])
            .toList();
        expect(titles1, containsAllInOrder(['Zeta-0', 'Zeta-1', 'Zeta-2']));
        // The cursor encodes sortKey=title.
        expect(page1.nextCursor, startsWith('title\x1f'));

        // Page 2 with a DIFFERENT sort key using the stale title cursor.
        // The engine must detect the sort-key mismatch and reset to page 1.
        final page2 = await api.queryInstances(
          tabId: 'marketplace',
          fanId: 'member-1',
          limit: 3,
          cursor: page1.nextCursor,
          query: const SurfaceQuery(sort: SortSpec(key: 'category')),
        );
        // With reset: page1 of category-sorted data = Alpha-0, Alpha-1, Alpha-2.
        expect(
          page2.items.length,
          3,
          reason: 'sort change with stale cursor resets to page 1, not empty',
        );
        final cats2 = page2.items
            .map((i) => i.instanceData['category'])
            .toList();
        expect(cats2, containsAllInOrder(['Alpha-0', 'Alpha-1', 'Alpha-2']));

        // The stale cursor is ignored, so page 2 returns the first page of
        // the new sort — which overlaps with page 1's items. The total unique
        // across both pages is at most the total seeded count.
        final allIds = {
          ...page1.items.map((i) => i.instanceId),
          ...page2.items.map((i) => i.instanceId),
        };
        expect(
          allIds.length,
          lessThanOrEqualTo(6),
          reason: 'no more than the 6 seeded items appear',
        );
        expect(
          page2.items,
          isNotEmpty,
          reason: 'stale cursor ignored, page 2 has items (not empty)',
        );
      });
    });

    // ── 6. Cross-restart persistence test ────────────────────────────
    group('Cross-restart persistence', () {
      test('instances survive close + reopen', () async {
        // Use a unique file-backed DB path per run to avoid stale data.
        final tempDir = await _tempDir();
        final dbPath =
            '$tempDir/persist_${DateTime.now().millisecondsSinceEpoch}.sqlite';

        // Write.
        {
          final db = WorkflowDatabase.file(dbPath);
          final api = LocalWorkflowEngineApi(db: db, communityId: 'tabletop');
          api.registerDefinition(_loanMachine());
          await api.createInstance(
            workflowType: 'equipment-loan',
            initialInstanceData: {'title': 'Persistent Item'},
            fanId: 'member-1',
          );
          db.close();
        }

        // Reopen.
        {
          final db = WorkflowDatabase.file(dbPath);
          final api = LocalWorkflowEngineApi(db: db, communityId: 'tabletop');
          api.registerDefinition(_loanMachine());

          final page = await api.queryInstances(
            tabId: 'marketplace',
            fanId: 'member-1',
          );
          expect(page.items.length, 1);
          expect(page.items.first.instanceData['title'], 'Persistent Item');
          db.close();
        }
      });
    });

    // ── 7. Dynamic-schema query test ─────────────────────────────────
    group('Dynamic-schema queries', () {
      test(
        'two different workflow definitions with disjoint sortable fields both work',
        () async {
          final db = WorkflowDatabase.memory();
          final api = LocalWorkflowEngineApi(db: db, communityId: 'tabletop');
          api.registerDefinition(_loanMachine());

          // Second workflow type with different fields.
          const giveawayJson = '''
{
  "initialState": "available",
  "states": {
    "available": { "label": "Available" },
    "claimed":   { "label": "Claimed" }
  },
  "transitions": [
    { "id": "claim", "label": "Claim", "from": ["available"], "to": "claimed",
      "guard": { "allowedRoleIds": ["member"] },
      "effects": [{ "op": "set", "key": "claimedByFanId", "value": "\$actor" }] }
  ],
  "renderBindings": [
    { "states": ["available","claimed"], "audience": "any", "tabId": "marketplace",
      "cardSurfaceFamily": "equipment-loan", "bindingKind": "primary" }
  ],
  "instanceDataSchema": {
    "title":           { "type": "text", "required": true, "writableBy": "formEntry",
                         "storage": "inline", "sortable": true },
    "claimedByFanId": { "type": "fanId?", "writableBy": "effect", "sortable": false }
  }
}
''';
          final giveaway = LoomWorkflowStateMachine.fromJson(
            jsonDecode(giveawayJson) as Map<String, dynamic>,
            'equipment-giveaway',
          );
          api.registerDefinition(giveaway);

          // Seed one instance of each type.
          await api.createInstance(
            workflowType: 'equipment-loan',
            initialInstanceData: {'title': 'Loan Alpha'},
            fanId: 'member-1',
          );
          await api.createInstance(
            workflowType: 'equipment-giveaway',
            initialInstanceData: {'title': 'Giveaway Beta'},
            fanId: 'member-1',
          );

          // Query — both types share marketplace tab, both sorted by "title".
          final page = await api.queryInstances(
            tabId: 'marketplace',
            fanId: 'member-1',
            query: const SurfaceQuery(sort: SortSpec(key: 'title')),
          );
          expect(page.items.length, 2);

          final titles = page.items.map((i) => i.instanceData['title']).toSet();
          expect(titles, contains('Loan Alpha'));
          expect(titles, contains('Giveaway Beta'));
        },
      );
    });
  });
}

/// Simple temp directory for file-backed DB.
Future<String> _tempDir() async {
  final dir = '${Directory.current.path}/.dart_tool/test_tmp';
  final d = Directory(dir);
  if (!await d.exists()) await d.create(recursive: true);
  return dir;
}
