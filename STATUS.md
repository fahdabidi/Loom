# Community-to-remote migration tool — Member Social Space pilot

## What changed

- Added a VM-native Dart CLI at
  `app/packages/tooling/loom_ux_judges/bin/community_remote_migration.dart`.
  I placed it in `loom_ux_judges` rather than the app shell because that
  tooling package already owns the repository's JSONC parser and already
  depends on `loom_workflow_engine`, including `ArchetypeResolver`.
- The parser reads the real JSONC package, retains the raw experience map, and
  parses every workflow with the existing
  `LoomWorkflowStateMachine.fromJson` parser used inside the app shell's
  `LoomExperienceDefinition` parser. The raw definitions remain available
  for lossless pass-through fields and resolver input.
- Role ids use one documented deterministic rule everywhere: trim the
  `roleLabel`, lowercase ASCII, replace each run of non-`[a-z0-9]`
  characters with `-`, and trim leading/trailing hyphens. Slug collisions
  fail instead of merging distinct labels. For this pilot the result is
  `member` and `moderator`.
- Every actual `allowedPersonaIds` key is recursively audited, including
  state edit/read guards and transition guards. A list translates only when
  it names exactly every persona belonging to one role. Clean guards are
  rewritten to `allowedRoleIds` in the workflow-service definitions copy;
  mixed, partial, empty, unknown, and malformed sets become named findings.
- The App Access payload derives:
  - deduplicated `roles[]`;
  - all six `workflows[]`;
  - `cardSurfaceFamily` only through
    `ArchetypeResolver.resolveAll(...)`;
  - structural transition facts and safe `allowedRoleIds`; and
  - `createRoleIds` from the real
    `renderBindings[].actions[].byPersonaIds` create actions.
- The workflow-service payload is `{"specVersion": 4, "definitions": ...}`.
  Apart from clean legacy-guard key/value translations, definitions are
  copied recursively without a model round-trip.
- The default mode prints both payloads and the findings report, then returns
  before execution configuration or a network-capable executor is
  constructed. `--execute` is separately named and refuses to run while any
  translation finding remains.
- Live mode has configurable App Access, workflow-service, and Keycloak token
  URLs. App Access authentication follows
  `HttpAppAccessDecisionClient`'s cached OAuth client-credentials pattern.
  The workflow-service call uses a separately supplied existing fan JWT
  because its real `JwtWorkflowIdentityExtractor` requires a `fanId`
  claim. Both calls send correlation and idempotency headers.
- There is no group-membership operation in the live client. No app-shell
  source, reference/guide/archetype/community fixture, remote engine, or auth
  session file was edited.

Member Social Space contains 21 actual legacy guard keys (a raw text grep also
finds one comment). Fourteen translate cleanly and seven mixed-role transition
guards are findings. Both create actions translate cleanly.

## Verification

Corpus state was rechecked directly, excluding the two non-shipped Cedar
backup/slice files:

```text
$ corpus check
real_shipped_fixtures=11
real_shipped_with_allowedPersonaIds=11
corpus_allowedRoleIds_keys=0
pilot_allowedPersonaIds_keys=21
```

Whole-package Dart analysis is clean:

```text
$ cd app/packages/tooling/loom_ux_judges
$ dart analyze .
Analyzing ....
No issues found!
```

Focused unit/integration tests cover an exact full-role persona set, a strict
subset, a mixed-role set, create-action ownership, independent archetype
resolution, real-fixture parsing, clean definitions guard translation, raw
definition pass-through behavior, and the zero-network dry-run boundary:

```text
$ dart /home/fahd/Loom/app/.dart_tool/pub/bin/test/test.dart-3.11.5.snapshot \
    test/community_remote_migration_test.dart --reporter expanded
00:00 +0: loading test/community_remote_migration_test.dart
00:00 +0: PersonaRoleTranslator full persona set for one role translates cleanly
00:00 +1: PersonaRoleTranslator strict subset of one role is flagged instead of widened
00:00 +2: PersonaRoleTranslator personas from two roles are flagged instead of merged
00:00 +3: Member Social Space derivation (setUpAll)
00:00 +3: Member Social Space derivation uses the existing workflow model parser for the real fixture
00:00 +4: Member Social Space derivation derives createRoleIds from create-action byPersonaIds
00:00 +5: Member Social Space derivation cardSurfaceFamily matches an independent resolver call
00:00 +6: Member Social Space derivation audits every real legacy guard and omits unsafe role guesses
00:00 +7: Member Social Space derivation passes definitions through under specVersion 4 with clean guards translated
00:00 +8: Member Social Space derivation default dry run constructs no live executor and makes no calls
00:00 +9: Member Social Space derivation (tearDownAll)
00:00 +9: All tests passed!
```

The remaining package tests were run together while excluding only
`validator_http_server_test.dart`, whose localhost bind is prohibited by the
sandbox. All 246 non-socket tests passed:

```text
$ dart /home/fahd/Loom/app/.dart_tool/pub/bin/test/test.dart-3.11.5.snapshot \
    <all *_test.dart except validator_http_server_test.dart>
00:03 +246: All tests passed!
```

The unexcluded package run reached 246 passes and 16 failures, all in
`validator_http_server_test.dart`, all caused by the same environment error
before their HTTP assertions ran:

```text
SocketException: Failed to create server socket
(OS Error: Operation not permitted, errno = 1),
address = 127.0.0.1, port = 0
```

Dry-run command and its full output follow. This is the complete derived
`roles[]`, `workflows[]`, translated/pass-through `definitions`, and
findings report for the real shipped fixture:

```text
$ cd app/packages/tooling/loom_ux_judges
$ dart run bin/community_remote_migration.dart \
    ../../../../docs/references/communities/Loom_Communities_Workflow_Engine_MemberSocialSpace_Example.jsonc
Running build hooks...Running build hooks...=== installCommunityPackage payload ===
{
  "communityHandle": "member-social-space",
  "displayName": "Member Social Space",
  "grammarVersion": 1,
  "roles": [
    {
      "roleId": "member",
      "label": "Member"
    },
    {
      "roleId": "moderator",
      "label": "Moderator"
    }
  ],
  "workflows": [
    {
      "workflowType": "platform-message-thread",
      "cardSurfaceFamily": "discussionThread",
      "transitions": [
        {
          "transitionId": "start-thread",
          "action": null,
          "tone": "primary",
          "isTerminal": false,
          "allowedRoleIds": [
            "member"
          ]
        },
        {
          "transitionId": "post-message",
          "action": null,
          "tone": "primary",
          "isTerminal": false,
          "allowedRoleIds": []
        },
        {
          "transitionId": "mark-read",
          "action": null,
          "tone": "secondary",
          "isTerminal": false,
          "allowedRoleIds": []
        },
        {
          "transitionId": "mute",
          "action": null,
          "tone": "secondary",
          "isTerminal": false,
          "allowedRoleIds": []
        },
        {
          "transitionId": "unmute",
          "action": null,
          "tone": "secondary",
          "isTerminal": false,
          "allowedRoleIds": []
        },
        {
          "transitionId": "archive",
          "action": null,
          "tone": "destructive",
          "isTerminal": false,
          "allowedRoleIds": []
        },
        {
          "transitionId": "unarchive",
          "action": null,
          "tone": "secondary",
          "isTerminal": false,
          "allowedRoleIds": []
        }
      ],
      "createRoleIds": [
        "member"
      ]
    },
    {
      "workflowType": "platform-connection",
      "cardSurfaceFamily": "approvalQueueItem",
      "transitions": [
        {
          "transitionId": "send-invite",
          "action": null,
          "tone": "primary",
          "isTerminal": false,
          "allowedRoleIds": [
            "member"
          ]
        },
        {
          "transitionId": "accept-invite",
          "action": null,
          "tone": "primary",
          "isTerminal": false,
          "allowedRoleIds": [
            "member"
          ]
        },
        {
          "transitionId": "decline-invite",
          "action": null,
          "tone": "secondary",
          "isTerminal": true,
          "allowedRoleIds": [
            "member"
          ]
        },
        {
          "transitionId": "cancel-invite",
          "action": null,
          "tone": "destructive",
          "isTerminal": true,
          "allowedRoleIds": [
            "member"
          ]
        },
        {
          "transitionId": "block",
          "action": null,
          "tone": "destructive",
          "isTerminal": false,
          "allowedRoleIds": [
            "member"
          ]
        },
        {
          "transitionId": "unblock",
          "action": null,
          "tone": "primary",
          "isTerminal": false,
          "allowedRoleIds": [
            "member"
          ]
        }
      ],
      "createRoleIds": [
        "member"
      ]
    },
    {
      "workflowType": "platform-blocked-target",
      "cardSurfaceFamily": "approvalQueueItem",
      "transitions": [
        {
          "transitionId": "confirm-block",
          "action": null,
          "tone": "primary",
          "isTerminal": false,
          "allowedRoleIds": [
            "member"
          ]
        },
        {
          "transitionId": "close-review",
          "action": null,
          "tone": "secondary",
          "isTerminal": true,
          "allowedRoleIds": [
            "member"
          ]
        }
      ],
      "createRoleIds": []
    },
    {
      "workflowType": "platform-in-stream-ad",
      "cardSurfaceFamily": "notificationInbox",
      "transitions": [
        {
          "transitionId": "record-impression",
          "action": null,
          "tone": "secondary",
          "isTerminal": false
        },
        {
          "transitionId": "open-sponsor-link",
          "action": null,
          "tone": "primary",
          "isTerminal": false
        },
        {
          "transitionId": "dismiss-ad",
          "action": null,
          "tone": "secondary",
          "isTerminal": false,
          "allowedRoleIds": [
            "member"
          ]
        },
        {
          "transitionId": "report-sponsor",
          "action": null,
          "tone": "destructive",
          "isTerminal": false
        }
      ],
      "createRoleIds": []
    },
    {
      "workflowType": "platform-top-banner-no-fill",
      "cardSurfaceFamily": "notificationInbox",
      "transitions": [
        {
          "transitionId": "refresh-slot",
          "action": null,
          "tone": "secondary",
          "isTerminal": false
        },
        {
          "transitionId": "inspect-reason",
          "action": null,
          "tone": "secondary",
          "isTerminal": false
        }
      ],
      "createRoleIds": []
    },
    {
      "workflowType": "platform-sensitive-no-fill",
      "cardSurfaceFamily": "notificationInbox",
      "transitions": [
        {
          "transitionId": "acknowledge-suppression",
          "action": null,
          "tone": "primary",
          "isTerminal": false
        },
        {
          "transitionId": "review-policy",
          "action": null,
          "tone": "secondary",
          "isTerminal": false
        }
      ],
      "createRoleIds": []
    }
  ]
}
=== replaceWorkflowDefinitions payload ===
{
  "specVersion": 4,
  "definitions": {
    "platform-message-thread": {
      "initialState": "draft",
      "visibility": {
        "default": "guarded",
        "readGuard": {
          "formula": "$viewer == participantAPersonaId || $viewer == participantBPersonaId"
        }
      },
      "states": {
        "draft": {
          "label": "Draft",
          "tone": "info",
          "editableFields": [
            "participantBPersonaId"
          ],
          "editGuard": {
            "allowedRoleIds": [
              "member"
            ]
          },
          "readGuard": {
            "allowedRoleIds": [
              "member"
            ]
          }
        },
        "open": {
          "label": "Open",
          "tone": "positive",
          "editableFields": [
            "participantBPersonaId"
          ],
          "editGuard": {
            "actorEqualsField": {
              "key": "participantAPersonaId"
            }
          }
        },
        "archived": {
          "label": "Archived",
          "tone": "info"
        }
      },
      "transitions": [
        {
          "id": "start-thread",
          "label": "Start conversation",
          "icon": "send",
          "tone": "primary",
          "from": [
            "draft"
          ],
          "to": "open",
          "guard": {
            "allowedRoleIds": [
              "member"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "participantAPersonaId",
              "value": "$actor"
            }
          ]
        },
        {
          "id": "post-message",
          "label": "Send",
          "icon": "send",
          "tone": "primary",
          "from": [
            "open"
          ],
          "to": null,
          "inputs": {
            "body": {
              "type": "text",
              "required": true
            }
          },
          "guard": {
            "formula": "($actor == participantAPersonaId || $actor == participantBPersonaId) && !blockedActive"
          },
          "effects": [
            {
              "op": "append",
              "key": "messages",
              "value": {
                "senderPersonaId": "$actor",
                "body": "{input.body}",
                "timestamp": "$timestamp"
              }
            },
            {
              "op": "branch",
              "if": "$actor == participantAPersonaId",
              "then": [
                {
                  "op": "set",
                  "key": "unreadForB",
                  "value": true
                },
                {
                  "op": "set",
                  "key": "unreadForA",
                  "value": false
                }
              ],
              "else": [
                {
                  "op": "set",
                  "key": "unreadForA",
                  "value": true
                },
                {
                  "op": "set",
                  "key": "unreadForB",
                  "value": false
                }
              ]
            }
          ]
        },
        {
          "id": "mark-read",
          "label": "Mark read",
          "icon": "mark_email_read",
          "tone": "secondary",
          "from": [
            "open"
          ],
          "to": null,
          "guard": {
            "formula": "$actor == participantAPersonaId || $actor == participantBPersonaId"
          },
          "effects": [
            {
              "op": "branch",
              "if": "$actor == participantAPersonaId",
              "then": [
                {
                  "op": "set",
                  "key": "unreadForA",
                  "value": false
                }
              ],
              "else": [
                {
                  "op": "set",
                  "key": "unreadForB",
                  "value": false
                }
              ]
            }
          ]
        },
        {
          "id": "mute",
          "label": "Mute",
          "icon": "notifications_off",
          "tone": "secondary",
          "from": [
            "open"
          ],
          "to": null,
          "guard": {
            "formula": "$actor == participantAPersonaId || $actor == participantBPersonaId",
            "actorInList": {
              "key": "mutedByPersonaIds",
              "present": false
            }
          },
          "effects": [
            {
              "op": "appendUnique",
              "key": "mutedByPersonaIds",
              "value": "$actor"
            }
          ]
        },
        {
          "id": "unmute",
          "label": "Unmute",
          "icon": "notifications_active",
          "tone": "secondary",
          "from": [
            "open"
          ],
          "to": null,
          "guard": {
            "formula": "$actor == participantAPersonaId || $actor == participantBPersonaId",
            "actorInList": {
              "key": "mutedByPersonaIds",
              "present": true
            }
          },
          "effects": [
            {
              "op": "removeValue",
              "key": "mutedByPersonaIds",
              "value": "$actor"
            }
          ]
        },
        {
          "id": "archive",
          "label": "Archive",
          "icon": "archive",
          "tone": "destructive",
          "from": [
            "open"
          ],
          "to": "archived",
          "guard": {
            "formula": "$actor == participantAPersonaId || $actor == participantBPersonaId"
          }
        },
        {
          "id": "unarchive",
          "label": "Unarchive",
          "icon": "unarchive",
          "tone": "secondary",
          "from": [
            "archived"
          ],
          "to": "open",
          "guard": {
            "formula": "$actor == participantAPersonaId || $actor == participantBPersonaId"
          }
        }
      ],
      "renderBindings": [
        {
          "states": [
            "draft"
          ],
          "role": "any",
          "tabId": "messages",
          "cardSurfaceFamily": "discussionThread",
          "bindingKind": "primary",
          "actions": [
            {
              "kind": "create",
              "label": "New message",
              "byPersonaIds": [
                "platform-member-alex",
                "platform-member-bailey",
                "platform-member-casey"
              ],
              "scope": "tab",
              "presentation": "fab"
            }
          ]
        },
        {
          "states": [
            "open"
          ],
          "role": "any",
          "tabId": "messages",
          "cardSurfaceFamily": "discussionThread",
          "bindingKind": "primary"
        },
        {
          "states": [
            "archived"
          ],
          "role": "any",
          "tabId": "messages",
          "cardSurfaceFamily": "discussionThread",
          "bindingKind": "summary"
        }
      ],
      "instanceDataSchema": {
        "participantAPersonaId": {
          "type": "personaId?",
          "writableBy": "effect",
          "displayIcon": "person_outline",
          "labelTemplate": "{value}",
          "hideWhenEmpty": true,
          "displayContexts": [
            "tile",
            "detail"
          ]
        },
        "participantBPersonaId": {
          "type": "personaId",
          "required": true,
          "writableBy": "formEntry",
          "displayIcon": "person_add_outlined",
          "labelTemplate": "With {value}",
          "displayContexts": [
            "tile",
            "detail"
          ]
        },
        "messages": {
          "type": "list",
          "writableBy": "effect",
          "displayIcon": "forum",
          "labelTemplate": "{value.length} messages",
          "displayContexts": [
            "tile",
            "detail"
          ]
        },
        "unreadForA": {
          "type": "bool",
          "writableBy": "effect",
          "displayContexts": []
        },
        "unreadForB": {
          "type": "bool",
          "writableBy": "effect",
          "displayContexts": []
        },
        "isUnreadForViewer": {
          "type": "bool",
          "formula": "if($viewer == participantAPersonaId, unreadForA, unreadForB)",
          "displayIcon": "mark_email_unread_outlined",
          "labelTemplate": "Unread: {value}",
          "displayContexts": [
            "tile",
            "detail"
          ]
        },
        "mutedByPersonaIds": {
          "type": "personaId[]",
          "writableBy": "effect",
          "displayIcon": "notifications_off_outlined",
          "labelTemplate": "Muted by {value.length}",
          "hideWhenEmpty": true,
          "displayContexts": [
            "detail"
          ]
        },
        "blockedActive": {
          "type": "bool",
          "writableBy": "effect",
          "displayContexts": []
        },
        "blockedByPersonaId": {
          "type": "personaId?",
          "writableBy": "effect",
          "displayContexts": []
        },
        "messageCount": {
          "type": "number",
          "formula": "size(messages)",
          "displayIcon": "chat_bubble_outline",
          "labelTemplate": "{value} messages",
          "displayContexts": [
            "tile",
            "detail"
          ]
        }
      }
    },
    "platform-connection": {
      "initialState": "draft",
      "visibility": {
        "default": "guarded",
        "readGuard": {
          "formula": "$viewer == inviterPersonaId || $viewer == inviteePersonaId || $viewer == 'platform-moderator-dakota'"
        }
      },
      "states": {
        "draft": {
          "label": "Draft",
          "tone": "info",
          "editableFields": [
            "reason",
            "inviteePersonaId"
          ],
          "editGuard": {
            "allowedRoleIds": [
              "member"
            ]
          },
          "readGuard": {
            "allowedRoleIds": [
              "member"
            ]
          }
        },
        "invited": {
          "label": "Invite sent",
          "tone": "info"
        },
        "connected": {
          "label": "Connected",
          "tone": "positive"
        },
        "declined": {
          "label": "Declined",
          "tone": "negative",
          "isTerminal": true
        },
        "blocked": {
          "label": "Blocked",
          "tone": "negative"
        }
      },
      "transitions": [
        {
          "id": "send-invite",
          "label": "Send invite",
          "icon": "send",
          "tone": "primary",
          "from": [
            "draft"
          ],
          "to": "invited",
          "guard": {
            "allowedRoleIds": [
              "member"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "inviterPersonaId",
              "value": "$actor"
            }
          ]
        },
        {
          "id": "accept-invite",
          "label": "Accept",
          "icon": "check_circle",
          "tone": "primary",
          "from": [
            "invited"
          ],
          "to": "connected",
          "guard": {
            "allowedRoleIds": [
              "member"
            ],
            "actorEqualsField": {
              "key": "inviteePersonaId"
            }
          },
          "effects": [
            {
              "op": "set",
              "key": "respondedAt",
              "value": "$timestamp"
            }
          ]
        },
        {
          "id": "decline-invite",
          "label": "Decline",
          "icon": "cancel",
          "tone": "secondary",
          "from": [
            "invited"
          ],
          "to": "declined",
          "guard": {
            "allowedRoleIds": [
              "member"
            ],
            "actorEqualsField": {
              "key": "inviteePersonaId"
            }
          },
          "effects": [
            {
              "op": "set",
              "key": "respondedAt",
              "value": "$timestamp"
            }
          ]
        },
        {
          "id": "cancel-invite",
          "label": "Cancel invite",
          "icon": "undo",
          "tone": "destructive",
          "from": [
            "invited"
          ],
          "to": "declined",
          "guard": {
            "allowedRoleIds": [
              "member"
            ],
            "actorEqualsField": {
              "key": "inviterPersonaId"
            }
          },
          "effects": [
            {
              "op": "set",
              "key": "respondedAt",
              "value": "$timestamp"
            }
          ]
        },
        {
          "id": "block",
          "label": "Block",
          "icon": "block",
          "tone": "destructive",
          "from": [
            "invited",
            "connected"
          ],
          "to": "blocked",
          "inputs": {
            "reason": {
              "type": "text",
              "required": true
            }
          },
          "guard": {
            "allowedRoleIds": [
              "member"
            ],
            "formula": "$actor == inviterPersonaId || $actor == inviteePersonaId"
          },
          "effects": [
            {
              "op": "set",
              "key": "blockedByPersonaId",
              "value": "$actor"
            },
            {
              "op": "branch",
              "if": "$actor == inviterPersonaId",
              "then": [
                {
                  "op": "createInstance",
                  "workflowType": "platform-blocked-target",
                  "fields": {
                    "connectionId": "{id}",
                    "blockerPersonaId": "$actor",
                    "targetPersonaId": "{inviteePersonaId}",
                    "blockReason": "{input.reason}"
                  }
                }
              ],
              "else": [
                {
                  "op": "createInstance",
                  "workflowType": "platform-blocked-target",
                  "fields": {
                    "connectionId": "{id}",
                    "blockerPersonaId": "$actor",
                    "targetPersonaId": "{inviterPersonaId}",
                    "blockReason": "{input.reason}"
                  }
                }
              ]
            },
            {
              "op": "set",
              "key": "blockedActive",
              "value": true,
              "relatedInstance": "messageThreadId"
            },
            {
              "op": "set",
              "key": "blockedByPersonaId",
              "value": "$actor",
              "relatedInstance": "messageThreadId"
            }
          ]
        },
        {
          "id": "unblock",
          "label": "Unblock",
          "icon": "lock_open",
          "tone": "primary",
          "from": [
            "blocked"
          ],
          "to": "connected",
          "guard": {
            "allowedRoleIds": [
              "member"
            ],
            "actorEqualsField": {
              "key": "blockedByPersonaId"
            }
          },
          "effects": [
            {
              "op": "set",
              "key": "blockedByPersonaId",
              "value": null
            },
            {
              "op": "set",
              "key": "blockedActive",
              "value": false,
              "relatedInstance": "messageThreadId"
            },
            {
              "op": "set",
              "key": "blockedByPersonaId",
              "value": null,
              "relatedInstance": "messageThreadId"
            }
          ]
        }
      ],
      "renderBindings": [
        {
          "states": [
            "draft"
          ],
          "role": "any",
          "tabId": "messages",
          "cardSurfaceFamily": "approvalQueueItem",
          "bindingKind": "primary",
          "actions": [
            {
              "kind": "create",
              "label": "Send connection invite",
              "byPersonaIds": [
                "platform-member-alex",
                "platform-member-bailey",
                "platform-member-casey"
              ],
              "scope": "tab",
              "presentation": "fab"
            }
          ]
        },
        {
          "states": [
            "invited"
          ],
          "role": "any",
          "tabId": "messages",
          "cardSurfaceFamily": "approvalQueueItem",
          "bindingKind": "primary"
        },
        {
          "states": [
            "invited"
          ],
          "role": "any",
          "tabId": "home",
          "cardSurfaceFamily": "notificationInbox",
          "bindingKind": "summary"
        },
        {
          "states": [
            "connected",
            "declined",
            "blocked"
          ],
          "role": "any",
          "tabId": "messages",
          "cardSurfaceFamily": "statusTimeline",
          "bindingKind": "summary"
        },
        {
          "states": [
            "invited",
            "connected",
            "declined",
            "blocked"
          ],
          "role": "any",
          "tabId": "admin",
          "cardSurfaceFamily": "statusTimeline",
          "bindingKind": "summary"
        }
      ],
      "instanceDataSchema": {
        "inviterPersonaId": {
          "type": "personaId?",
          "writableBy": "effect",
          "displayIcon": "person_outline",
          "labelTemplate": "Invited by {value}",
          "hideWhenEmpty": true,
          "displayContexts": [
            "tile",
            "detail"
          ]
        },
        "inviteePersonaId": {
          "type": "personaId",
          "required": true,
          "writableBy": "formEntry",
          "displayIcon": "person_add_outlined",
          "labelTemplate": "Invitee: {value}",
          "displayContexts": [
            "tile",
            "detail"
          ]
        },
        "reason": {
          "type": "textarea",
          "required": true,
          "writableBy": "formEntry",
          "maxLength": 300,
          "displayIcon": "chat_bubble_outline",
          "labelTemplate": "{value}",
          "displayContexts": [
            "detail"
          ]
        },
        "messageThreadId": {
          "type": "text?",
          "writableBy": "effect",
          "displayContexts": []
        },
        "blockedByPersonaId": {
          "type": "personaId?",
          "writableBy": "effect",
          "displayContexts": []
        },
        "respondedAt": {
          "type": "date?",
          "writableBy": "effect",
          "sortable": true,
          "hideWhenEmpty": true,
          "displayIcon": "schedule",
          "labelTemplate": "Responded {value}",
          "displayContexts": [
            "detail"
          ]
        }
      }
    },
    "platform-blocked-target": {
      "initialState": "active",
      "visibility": {
        "default": "guarded",
        "readGuard": {
          "actorEqualsField": {
            "key": "blockerPersonaId"
          }
        }
      },
      "states": {
        "active": {
          "label": "Block active",
          "tone": "negative"
        },
        "closed": {
          "label": "Reviewed",
          "tone": "info",
          "isTerminal": true
        }
      },
      "transitions": [
        {
          "id": "confirm-block",
          "label": "Confirm block",
          "icon": "fact_check",
          "tone": "primary",
          "from": [
            "active"
          ],
          "to": null,
          "guard": {
            "allowedRoleIds": [
              "member"
            ],
            "actorEqualsField": {
              "key": "blockerPersonaId"
            }
          },
          "effects": [
            {
              "op": "set",
              "key": "confirmedAt",
              "value": "$timestamp"
            }
          ]
        },
        {
          "id": "close-review",
          "label": "Mark reviewed",
          "icon": "task_alt",
          "tone": "secondary",
          "from": [
            "active"
          ],
          "to": "closed",
          "guard": {
            "allowedRoleIds": [
              "member"
            ],
            "actorEqualsField": {
              "key": "blockerPersonaId"
            }
          },
          "effects": [
            {
              "op": "set",
              "key": "reviewedAt",
              "value": "$timestamp"
            }
          ]
        }
      ],
      "renderBindings": [
        {
          "states": [
            "active"
          ],
          "role": "any",
          "tabId": "home",
          "cardSurfaceFamily": "approvalQueueItem",
          "bindingKind": "primary"
        },
        {
          "states": [
            "closed"
          ],
          "role": "any",
          "tabId": "home",
          "cardSurfaceFamily": "approvalQueueItem",
          "bindingKind": "summary"
        }
      ],
      "instanceDataSchema": {
        "connectionId": {
          "type": "text",
          "required": true,
          "writableBy": "effect",
          "displayContexts": []
        },
        "blockerPersonaId": {
          "type": "personaId",
          "required": true,
          "writableBy": "effect",
          "displayIcon": "person_outline",
          "labelTemplate": "{value}",
          "displayContexts": [
            "detail"
          ]
        },
        "targetPersonaId": {
          "type": "personaId",
          "required": true,
          "writableBy": "effect",
          "displayIcon": "block",
          "labelTemplate": "Target: {value}",
          "displayContexts": [
            "tile",
            "detail"
          ]
        },
        "blockReason": {
          "type": "textarea",
          "required": true,
          "writableBy": "effect",
          "maxLength": 500,
          "displayIcon": "report_outlined",
          "labelTemplate": "Reason: {value}",
          "displayContexts": [
            "detail"
          ]
        },
        "confirmedAt": {
          "type": "date?",
          "writableBy": "effect",
          "hideWhenEmpty": true,
          "displayIcon": "check_circle_outline",
          "labelTemplate": "Confirmed {value}",
          "displayContexts": [
            "detail"
          ]
        },
        "reviewedAt": {
          "type": "date?",
          "writableBy": "effect",
          "hideWhenEmpty": true,
          "displayIcon": "fact_check_outlined",
          "labelTemplate": "Reviewed {value}",
          "displayContexts": [
            "detail"
          ]
        }
      }
    },
    "platform-in-stream-ad": {
      "initialState": "filled",
      "visibility": {
        "default": "public"
      },
      "states": {
        "filled": {
          "label": "Filled",
          "tone": "positive"
        }
      },
      "transitions": [
        {
          "id": "record-impression",
          "label": "View",
          "icon": "visibility",
          "tone": "secondary",
          "from": [
            "filled"
          ],
          "to": null,
          "guard": {
            "allowedPersonaIds": [
              "platform-member-alex",
              "platform-member-bailey",
              "platform-member-casey",
              "platform-moderator-dakota"
            ]
          },
          "effects": [
            {
              "op": "appendUnique",
              "key": "impressionedByPersonaIds",
              "value": "$actor"
            }
          ]
        },
        {
          "id": "open-sponsor-link",
          "label": "Open sponsor",
          "icon": "open_in_new",
          "tone": "primary",
          "from": [
            "filled"
          ],
          "to": null,
          "guard": {
            "allowedPersonaIds": [
              "platform-member-alex",
              "platform-member-bailey",
              "platform-member-casey",
              "platform-moderator-dakota"
            ]
          },
          "effects": [
            {
              "op": "appendUnique",
              "key": "clickedByPersonaIds",
              "value": "$actor"
            }
          ]
        },
        {
          "id": "dismiss-ad",
          "label": "Dismiss",
          "icon": "close",
          "tone": "secondary",
          "from": [
            "filled"
          ],
          "to": null,
          "guard": {
            "allowedRoleIds": [
              "member"
            ],
            "instanceDataEquals": {
              "key": "dismissible",
              "value": true
            }
          },
          "effects": [
            {
              "op": "appendUnique",
              "key": "dismissedByPersonaIds",
              "value": "$actor"
            }
          ]
        },
        {
          "id": "report-sponsor",
          "label": "Report sponsor",
          "icon": "flag",
          "tone": "destructive",
          "from": [
            "filled"
          ],
          "to": null,
          "guard": {
            "allowedPersonaIds": [
              "platform-member-alex",
              "platform-member-bailey",
              "platform-member-casey",
              "platform-moderator-dakota"
            ]
          },
          "effects": [
            {
              "op": "appendUnique",
              "key": "reportedByPersonaIds",
              "value": "$actor"
            }
          ]
        }
      ],
      "renderBindings": [
        {
          "states": [
            "filled"
          ],
          "role": "any",
          "tabId": "home",
          "cardSurfaceFamily": "notificationInbox",
          "bindingKind": "primary"
        }
      ],
      "instanceDataSchema": {
        "sponsorName": {
          "type": "text",
          "required": true,
          "writableBy": "effect",
          "displayIcon": "storefront_outlined",
          "labelTemplate": "Sponsor: {value}",
          "displayContexts": [
            "tile",
            "detail"
          ]
        },
        "disclosureText": {
          "type": "text",
          "required": true,
          "writableBy": "effect",
          "displayIcon": "info_outlined",
          "labelTemplate": "{value}",
          "displayContexts": [
            "tile",
            "detail"
          ]
        },
        "bodyText": {
          "type": "text?",
          "writableBy": "effect",
          "hideWhenEmpty": true,
          "displayContexts": [
            "detail"
          ]
        },
        "dismissible": {
          "type": "bool",
          "required": true,
          "writableBy": "effect",
          "displayContexts": []
        },
        "impressionedByPersonaIds": {
          "type": "personaId[]",
          "writableBy": "effect",
          "displayContexts": []
        },
        "clickedByPersonaIds": {
          "type": "personaId[]",
          "writableBy": "effect",
          "displayContexts": []
        },
        "dismissedByPersonaIds": {
          "type": "personaId[]",
          "writableBy": "effect",
          "displayContexts": []
        },
        "reportedByPersonaIds": {
          "type": "personaId[]",
          "writableBy": "effect",
          "displayContexts": []
        },
        "impressionCount": {
          "type": "number",
          "formula": "size(impressionedByPersonaIds)",
          "displayIcon": "visibility_outlined",
          "labelTemplate": "{value} views",
          "displayContexts": [
            "tile",
            "detail"
          ]
        },
        "clickCount": {
          "type": "number",
          "formula": "size(clickedByPersonaIds)",
          "displayIcon": "touch_app_outlined",
          "labelTemplate": "{value} clicks",
          "displayContexts": [
            "detail"
          ]
        }
      }
    },
    "platform-top-banner-no-fill": {
      "initialState": "no-fill",
      "visibility": {
        "default": "public"
      },
      "states": {
        "no-fill": {
          "label": "No fill",
          "tone": "warning"
        }
      },
      "transitions": [
        {
          "id": "refresh-slot",
          "label": "Refresh slot",
          "icon": "refresh",
          "tone": "secondary",
          "from": [
            "no-fill"
          ],
          "to": null,
          "guard": {
            "allowedPersonaIds": [
              "platform-member-alex",
              "platform-member-bailey",
              "platform-member-casey",
              "platform-moderator-dakota"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "lastRefreshedAt",
              "value": "$timestamp"
            }
          ]
        },
        {
          "id": "inspect-reason",
          "label": "Inspect no-fill reason",
          "icon": "manage_search",
          "tone": "secondary",
          "from": [
            "no-fill"
          ],
          "to": null,
          "guard": {
            "allowedPersonaIds": [
              "platform-member-alex",
              "platform-member-bailey",
              "platform-member-casey",
              "platform-moderator-dakota"
            ]
          },
          "effects": [
            {
              "op": "appendUnique",
              "key": "reasonInspectedByPersonaIds",
              "value": "$actor"
            }
          ]
        }
      ],
      "renderBindings": [
        {
          "states": [
            "no-fill"
          ],
          "role": "any",
          "tabId": "home",
          "cardSurfaceFamily": "notificationInbox",
          "bindingKind": "primary"
        }
      ],
      "instanceDataSchema": {
        "disclosureText": {
          "type": "text",
          "required": true,
          "writableBy": "effect",
          "displayIcon": "info_outlined",
          "labelTemplate": "{value}",
          "displayContexts": [
            "tile",
            "detail"
          ]
        },
        "noFillReason": {
          "type": "text",
          "required": true,
          "writableBy": "effect",
          "displayIcon": "report_gmailerrorred_outlined",
          "labelTemplate": "{value}",
          "displayContexts": [
            "tile",
            "detail"
          ]
        },
        "lastRefreshedAt": {
          "type": "date?",
          "writableBy": "effect",
          "hideWhenEmpty": true,
          "displayIcon": "refresh",
          "labelTemplate": "Refreshed {value}",
          "displayContexts": [
            "detail"
          ]
        },
        "reasonInspectedByPersonaIds": {
          "type": "personaId[]",
          "writableBy": "effect",
          "displayContexts": []
        }
      }
    },
    "platform-sensitive-no-fill": {
      "initialState": "suppressed",
      "visibility": {
        "default": "public"
      },
      "states": {
        "suppressed": {
          "label": "Suppressed",
          "tone": "info"
        }
      },
      "transitions": [
        {
          "id": "acknowledge-suppression",
          "label": "Continue",
          "icon": "check",
          "tone": "primary",
          "from": [
            "suppressed"
          ],
          "to": null,
          "guard": {
            "allowedPersonaIds": [
              "platform-member-alex",
              "platform-member-bailey",
              "platform-member-casey",
              "platform-moderator-dakota"
            ]
          },
          "effects": [
            {
              "op": "appendUnique",
              "key": "acknowledgedByPersonaIds",
              "value": "$actor"
            }
          ]
        },
        {
          "id": "review-policy",
          "label": "Review policy",
          "icon": "policy",
          "tone": "secondary",
          "from": [
            "suppressed"
          ],
          "to": null,
          "guard": {
            "allowedPersonaIds": [
              "platform-member-alex",
              "platform-member-bailey",
              "platform-member-casey",
              "platform-moderator-dakota"
            ]
          },
          "effects": [
            {
              "op": "appendUnique",
              "key": "policyReviewedByPersonaIds",
              "value": "$actor"
            }
          ]
        }
      ],
      "renderBindings": [
        {
          "states": [
            "suppressed"
          ],
          "role": "any",
          "tabId": "home",
          "cardSurfaceFamily": "notificationInbox",
          "bindingKind": "primary"
        }
      ],
      "instanceDataSchema": {
        "disclosureText": {
          "type": "text",
          "required": true,
          "writableBy": "effect",
          "displayIcon": "info_outlined",
          "labelTemplate": "{value}",
          "displayContexts": [
            "tile",
            "detail"
          ]
        },
        "noFillReason": {
          "type": "text",
          "required": true,
          "writableBy": "effect",
          "displayIcon": "shield_outlined",
          "labelTemplate": "{value}",
          "displayContexts": [
            "tile",
            "detail"
          ]
        },
        "acknowledgedByPersonaIds": {
          "type": "personaId[]",
          "writableBy": "effect",
          "displayContexts": []
        },
        "policyReviewedByPersonaIds": {
          "type": "personaId[]",
          "writableBy": "effect",
          "displayContexts": []
        }
      }
    }
  }
}
=== findings report ===
{
  "summary": {
    "guardsTranslatedCleanly": 14,
    "guardsFlagged": 7,
    "createActionsTranslatedCleanly": 2,
    "createActionsFlagged": 0,
    "networkCallsMade": 0
  },
  "findings": [
    {
      "code": "mixed_role_labels",
      "location": "$.experience.workflowDefinitions.platform-in-stream-ad.transitions[id=record-impression].guard.allowedPersonaIds",
      "source": "guard",
      "personaIds": [
        "platform-member-alex",
        "platform-member-bailey",
        "platform-member-casey",
        "platform-moderator-dakota"
      ],
      "roleLabels": [
        "Member",
        "Moderator"
      ],
      "message": "$.experience.workflowDefinitions.platform-in-stream-ad.transitions[id=record-impression].guard.allowedPersonaIds mixes personas from role labels Member, Moderator; the target role-only grammar cannot express this per-persona rule without a human decision."
    },
    {
      "code": "mixed_role_labels",
      "location": "$.experience.workflowDefinitions.platform-in-stream-ad.transitions[id=open-sponsor-link].guard.allowedPersonaIds",
      "source": "guard",
      "personaIds": [
        "platform-member-alex",
        "platform-member-bailey",
        "platform-member-casey",
        "platform-moderator-dakota"
      ],
      "roleLabels": [
        "Member",
        "Moderator"
      ],
      "message": "$.experience.workflowDefinitions.platform-in-stream-ad.transitions[id=open-sponsor-link].guard.allowedPersonaIds mixes personas from role labels Member, Moderator; the target role-only grammar cannot express this per-persona rule without a human decision."
    },
    {
      "code": "mixed_role_labels",
      "location": "$.experience.workflowDefinitions.platform-in-stream-ad.transitions[id=report-sponsor].guard.allowedPersonaIds",
      "source": "guard",
      "personaIds": [
        "platform-member-alex",
        "platform-member-bailey",
        "platform-member-casey",
        "platform-moderator-dakota"
      ],
      "roleLabels": [
        "Member",
        "Moderator"
      ],
      "message": "$.experience.workflowDefinitions.platform-in-stream-ad.transitions[id=report-sponsor].guard.allowedPersonaIds mixes personas from role labels Member, Moderator; the target role-only grammar cannot express this per-persona rule without a human decision."
    },
    {
      "code": "mixed_role_labels",
      "location": "$.experience.workflowDefinitions.platform-top-banner-no-fill.transitions[id=refresh-slot].guard.allowedPersonaIds",
      "source": "guard",
      "personaIds": [
        "platform-member-alex",
        "platform-member-bailey",
        "platform-member-casey",
        "platform-moderator-dakota"
      ],
      "roleLabels": [
        "Member",
        "Moderator"
      ],
      "message": "$.experience.workflowDefinitions.platform-top-banner-no-fill.transitions[id=refresh-slot].guard.allowedPersonaIds mixes personas from role labels Member, Moderator; the target role-only grammar cannot express this per-persona rule without a human decision."
    },
    {
      "code": "mixed_role_labels",
      "location": "$.experience.workflowDefinitions.platform-top-banner-no-fill.transitions[id=inspect-reason].guard.allowedPersonaIds",
      "source": "guard",
      "personaIds": [
        "platform-member-alex",
        "platform-member-bailey",
        "platform-member-casey",
        "platform-moderator-dakota"
      ],
      "roleLabels": [
        "Member",
        "Moderator"
      ],
      "message": "$.experience.workflowDefinitions.platform-top-banner-no-fill.transitions[id=inspect-reason].guard.allowedPersonaIds mixes personas from role labels Member, Moderator; the target role-only grammar cannot express this per-persona rule without a human decision."
    },
    {
      "code": "mixed_role_labels",
      "location": "$.experience.workflowDefinitions.platform-sensitive-no-fill.transitions[id=acknowledge-suppression].guard.allowedPersonaIds",
      "source": "guard",
      "personaIds": [
        "platform-member-alex",
        "platform-member-bailey",
        "platform-member-casey",
        "platform-moderator-dakota"
      ],
      "roleLabels": [
        "Member",
        "Moderator"
      ],
      "message": "$.experience.workflowDefinitions.platform-sensitive-no-fill.transitions[id=acknowledge-suppression].guard.allowedPersonaIds mixes personas from role labels Member, Moderator; the target role-only grammar cannot express this per-persona rule without a human decision."
    },
    {
      "code": "mixed_role_labels",
      "location": "$.experience.workflowDefinitions.platform-sensitive-no-fill.transitions[id=review-policy].guard.allowedPersonaIds",
      "source": "guard",
      "personaIds": [
        "platform-member-alex",
        "platform-member-bailey",
        "platform-member-casey",
        "platform-moderator-dakota"
      ],
      "roleLabels": [
        "Member",
        "Moderator"
      ],
      "message": "$.experience.workflowDefinitions.platform-sensitive-no-fill.transitions[id=review-policy].guard.allowedPersonaIds mixes personas from role labels Member, Moderator; the target role-only grammar cannot express this per-persona rule without a human decision."
    }
  ]
}
```

Dry-run network safety was confirmed two ways:

- Code inspection: the CLI returns at `if (!args.execute) return 0;` before
  reading live credentials or constructing `HttpLiveMigrationExecutor`.
- Test harness: an injected executor factory increments a counter and returns
  an executor that throws if called; default dry-run exits 0 with factory
  count 0 and prints `"networkCallsMade": 0`.

The current pilot's explicit execution path was also exercised without live
credentials. It refused before any executor construction because the seven
findings remain:

```text
$ dart run bin/community_remote_migration.dart <member-social-space.jsonc> --execute
exit=2
ERROR: --execute refused because 7 persona-to-role finding(s) require a human decision.
```

No live endpoint was called during any verification.

## Proposed next steps

1. Review the complete dry-run payload above and make an explicit human
   authorization decision for each of the seven mixed Member+Moderator
   guards. Do not infer that they should become both roles merely because the
   lists happen to include all four current personas.
2. Reconcile the grammar-version contract noted below, then rerun dry-run and
   require zero findings.
3. In a separate, explicitly authorized step, run `--execute` with reviewed
   payloads, configured service URLs, App Access client credentials, and a
   valid workflow-service fan JWT; verify both endpoint responses
   independently.
4. Only after install and definition replacement are verified should a later
   ticket call `setGroupMembership` for a real test fan. This ticket neither
   grants nor proposes granting a fan any role.

## Anything I could not do

- Seven real transition guards cannot be safely represented as one role under
  the mandated translation rule. All name all three Member personas plus the
  Moderator persona and are reported as `mixed_role_labels`:
  - `platform-in-stream-ad / record-impression`
  - `platform-in-stream-ad / open-sponsor-link`
  - `platform-in-stream-ad / report-sponsor`
  - `platform-top-banner-no-fill / refresh-slot`
  - `platform-top-banner-no-fill / inspect-reason`
  - `platform-sensitive-no-fill / acknowledge-suppression`
  - `platform-sensitive-no-fill / review-policy`
- The current App Access source has a separate live blocker:
  `CommunityPermissionDeriver` compares request `grammarVersion` to the
  permissions vocabulary's `specVersion`, currently `4`, while the
  authoritative request rule requires this fixture's
  `experience.workflowGrammarVersion`, currently `1`. The tool correctly
  emits `grammarVersion: 1`; the present deployed-compatible Java logic would
  report `unsupported_grammar_version` until that contract mismatch is
  reconciled.
- A VM console executable cannot instantiate the Flutter app-shell
  `LoomExperienceDefinition` wrapper because importing that library requires
  `dart:ui`. I did not alter prohibited app-shell source to move the model.
  The CLI instead invokes the exact existing
  `LoomWorkflowStateMachine.fromJson` inner parser that wrapper uses for
  every engine-native workflow and has a real-fixture test proving all six
  definitions parse.
- I did not call either live API and did not call `setGroupMembership`, as
  required.
- The sandbox prevented the 16 existing localhost HTTP-server tests from
  binding a socket. The focused suite and every non-socket package test pass.
