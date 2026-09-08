# Ad-Free Community — `ad-off-member-checkout` live write, re-verified with database proof

**Date:** 2026-09-08 (device local, America/Los_Angeles = UTC-7; engine stamps are UTC, so
`12:43:15Z` is 05:43 local)
**Device:** `emulator-5554`, Android SDK 36, `sdk_gphone64_x86_64`, 1080x2400
**adb path:** the emulator is **Windows-hosted**; this session ran **on the Loom VM itself**
(`192.168.56.10`), which has no AVD. It was reached by talking to the **Windows host's adb server** —
`adb -H 192.168.56.1 -P 5037`. The VM-local adb server saw zero devices.
**App:** `com.example.loom_communities_demo/.MainActivity`
**Workflow:** `ad-off-member-checkout` in Ad-Free Community (`community_ad_free_community`,
`ext_ad_free_community`)
**Supersedes:** the reopened Ad-Free Community claim, which had no corresponding database row.

## Outcome

Both halves of the proof standard were met **in one session**, and the UI evidence and the Postgres
rows are reported together and **agree**.

- Signed in for real as `loom-ad-off-member-1` (fan `fan-ad-off-member-1`) through the in-app OAuth
  flow against Keycloak.
- Created an `ad-off-member-checkout` **from nothing** through the real UI, reaching `offer`.
- Drove `start-checkout` → `reviewing` and `submit-payment` → `payment-pending` as the member.
- **Escalated to `loom-ad-off-owner-1`** (fan `fan-ad-off-owner-1`, role `ad-off-owner`) — required,
  because `record-payment-confirmed` is owner-guarded — and drove it to **`active`**.
- Read the rows back from Postgres with `kubectl exec … psql` after each step.

`active` is the product's success state for this workflow: the entitlement is live, the receipt is
issued, and the suppression proof is ready. The only `isTerminal: true` state is `refunded`; it was
**not** driven. See "Terminal-state reachability" below for why it is nevertheless reachable, and
what was proven live versus argued.

## Baseline — confirmed, not stale

The ticket's control was *"`workflow_instances` held **13** rows total, and **zero** of
`workflow_type = 'ad-off-member-checkout'`."*

**That was exactly correct** at this session's first database read, before any device interaction:

```
 total
-------
    13

 instance_id | community_id | workflow_type | created_by_fan_id | current_state | created_at
-------------+--------------+---------------+-------------------+---------------+------------
(0 rows)
```

Zero `ad-off-member-checkout` rows. The rows below are therefore necessarily this session's. The
total moved **13 → 17**: one row created by hand, plus **three** created by the `createInstance`
effects on `record-payment-confirmed`.

## The rows

```
                    instance_id                          |       workflow_type       |  created_by_fan_id  | current_state |     created_utc
---------------------------------------------------------+---------------------------+---------------------+---------------+---------------------
 …_ad-off-member-checkout_9kmvxftjpbjr                   | ad-off-member-checkout    | fan-ad-off-member-1 | active        | 2026-09-08 12:43:15
 …_ad-off-entitlement-status_t0y00x34yrrv                | ad-off-entitlement-status | fan-ad-off-owner-1  | active        | 2026-09-08 12:52:58
 …_ad-off-receipt-evidence_gp6hlkqbd21l                  | ad-off-receipt-evidence   | fan-ad-off-owner-1  | issued        | 2026-09-08 12:52:58
 …_ad-off-ad-suppression_2d0t7n4botql                    | ad-off-ad-suppression     | fan-ad-off-owner-1  | unreviewed    | 2026-09-08 12:52:58
```

`created_by_fan_id` on the checkout is **`fan-ad-off-member-1`** — the identity that was
authenticated and driven. The three derived rows are attributed to `fan-ad-off-owner-1` because the
owner fired the transition whose effects created them, which is correct.

Full distribution after this session (14 distinct types, 17 rows):

```
 hoa-facility-reservation      |     3
 hoa-dues-payment              |     2
 ad-off-ad-suppression         |     1      <- this session
 ad-off-entitlement-status     |     1      <- this session
 ad-off-member-checkout        |     1      <- this session
 ad-off-receipt-evidence       |     1      <- this session
 chess-match-result            |     1
 critique-submission           |     1
 garden-tool-loan              |     1
 hoa-owner-notification        |     1
 mosque-donation-payment       |     1
 soccer-guardian-join-approval |     1
 soccer-registration-payment   |     1
 soccer-waiver-document        |     1
```

## Stored field values — verified against `instance_data`, not the screen

```
  billingPeriod            = 'monthly'
  checkoutReferenceId      = 'community_ad_free_community_ad-off-member-checkout_9kmvxftjpbjr'
  coverageDescription      = 'Removes ads on home feed, giving surfaces, and community ad slots.'
  currency                 = 'USD'
  disclosureAcknowledged   = True
  memberFanId              = 'fan-ad-off-member-1'
  paymentMethodLabel       = 'Visa ending 4242'
  paymentOutcomeRecordedAt = '2026-09-08T12:52:58.590545Z'
  priceAmount              = 4.99
  submittedAt              = '2026-09-08T12:46:23.639178Z'
```

`memberFanId` was written by the `start-checkout` effect `{"op":"set","value":"$actor"}` — it is
independent confirmation that the acting identity was the member, not merely the selected one.

### The input-fidelity rule earned its place here

`adb shell input text` **truncated `coverageDescription` from 66 characters to 40** on first entry,
storing `'Removes ads on home feed, giving surface'`. The on-screen check did **not** catch it: the
field scrolls horizontally, and the screen showed `ves ads on home feed, giving surface` — the
scrolled *tail of the truncated value*, which reads exactly like the middle of a complete one. Only
the `instance_data` comparison found it.

It was corrected through the real UI (state `offer` declares `coverageDescription` in
`editableFields` with an `ad-off-member` `editGuard`), by appending the remainder in two short
chunks and pressing **Save changes**. The stored value then matched the intended string byte for
byte at 66 characters. That correction is itself an additional proven round-trip: an inline field
edit persisted server-side to Postgres.

This is a harness artifact, **not** a product defect.

## Path driven

| # | Actor | Surface | Action | Resulting state |
|---|---|---|---|---|
| 1 | `fan-ad-off-member-1` | Giving tab FAB "Buy ad-off" | create | `offer` |
| 2 | `fan-ad-off-member-1` | inline edit + "Save changes" | fix `coverageDescription` | `offer` |
| 3 | `fan-ad-off-member-1` | "Turn off ads" | `start-checkout` | `reviewing` |
| 4 | `fan-ad-off-member-1` | "Checkout" | `submit-payment` | `payment-pending` |
| 5 | `fan-ad-off-owner-1` | "Record verified payment" (+ 2 required inputs) | `record-payment-confirmed` | **`active`** |

Step 5 inputs: `renewalDate = 2026-10-08`, `expiryDate = 2027-09-08`. Both were read back on screen
and both appear correctly in the derived entitlement row.

At `payment-pending` the member correctly saw **only** "Cancel checkout" — the confirm/fail
transitions are `ad-off-owner`-guarded and were absent from the member's card. That is the guard
working, observed rather than assumed.

## Escalation — declared

The ticket asked that any escalation be named explicitly. **`loom-ad-off-owner-1` was used**, and it
was necessary: `record-payment-confirmed` and `record-payment-failed` are the only transitions out of
`payment-pending`, and both are guarded `allowedRoleIds: ["ad-off-owner"]`. The member cannot reach
`active` alone. The generated `ad-free-community-admin` role was **not** substituted for the package
role.

## Terminal-state reachability — this community passes

The ticket flags three communities that fail this check. Ad-Free Community fails none of them, and
each premise below was verified rather than assumed:

- **Both package roles are provisioned** (the Masjid Nur failure). Proven live, not by inspection:
  the member fired two role-guarded transitions and the owner fired one. Both authenticated against
  Keycloak with HTTP 200.
- **A surface visible to the acting role renders the instance** (the Youth Soccer failure). Proven
  live: signed in as the owner, the member's checkout appeared on the **Giving** tab — which
  declares no `visibleRoleIds` and is therefore visible to both roles — carrying both owner actions.
  The checkout's `visibility.fields.parties` lists `memberFanId` **and** `{"role":"ad-off-owner"}`,
  so the owner is a party and can read it.
- **Preconditions are satisfiable from the state the instance will realistically be in** (the Garden
  Club failure). The refund path is self-healing rather than self-blocking: `request-refund` is
  guarded on `refundRequestForwardedAt == null`, and **both** exits from `refund-requested` reset
  that field to `null` — `withdraw-refund-request` (member) and `decline-refund` (owner). A declined
  or withdrawn refund therefore does not strand the member.

The single terminal state `refunded` is reached by `active → request-refund` (member) →
`refund-requested → record-refunded` (owner). Every link in that chain is a transition of the same
two roles this session already drove successfully, on an instance both roles can see.

**Stated plainly: `refunded` was not driven.** It would have required two further full identity
switches, and `active` is the success state the product is actually for. The reachability claim above
is an argument from verified premises, not an observation.

## Defects found

Neither is visible in a validator run, and neither blocked the path driven.

### 1. `ad-off-notification` is declared in the package but absent from the published catalog

The package declares **7** workflow definitions. The backend has **6**:

```
 community_ad_free_community_ad-off-ad-suppression     | ad-off-ad-suppression
 community_ad_free_community_ad-off-community-checkout | ad-off-community-checkout
 community_ad_free_community_ad-off-entitlement-status | ad-off-entitlement-status
 community_ad_free_community_ad-off-member-checkout    | ad-off-member-checkout
 community_ad_free_community_ad-off-receipt-evidence   | ad-off-receipt-evidence
 community_ad_free_community_ad-off-settlement-utility | ad-off-settlement-utility
```

`ad-off-notification` is missing. **Control run, because an empty result is not evidence of
absence:** the same query shape returns the six rows above for this community, and a query for
notification-typed definitions across the catalog returns five rows for *other* communities
(`book-notification`, `hoa-owner-notification`, `garden-notification`,
`mosque-neutral-notification`, `soccer-reminder-notification`). Notification workflows are normally
published; this one is not. Catalog total is 82.

Two transitions declare a `createInstance` effect targeting it:

- `ad-off-member-checkout :: record-payment-failed` (`payment-pending → payment-failed`) — the
  failure branch of the very workflow under test
- `ad-off-settlement-utility :: record-settlement` (`allocated → settled`)

**I did not drive either path**, so the runtime consequence is stated as a mechanism, not an observed
failure. This has the shape of the standing "publishing definitions is not a one-time step" trap: the
deployed copy is stale relative to the package, nothing errors until the affected branch is taken.

### 2. `paymentConfirmationId` is an orphan field

In `ad-off-member-checkout`'s `instanceDataSchema`, `paymentConfirmationId` declares **no
`writableBy`** and has **no writer anywhere in the package** — no `set` effect, no `createInstance`
field, no cross-workflow `relatedInstance` effect. It carries `displayIcon`, `labelTemplate`
`"Payment confirmation: {value}"` and `displayContexts: ["detail"]`, so it is a field the product
offers to display and nothing can ever populate.

**Control:** the same query shape finds 8 writers for `submittedAt`, so the search is sound. It is
`hideWhenEmpty`, which is why it is invisible in the UI rather than showing as blank — and why it
survived unnoticed.

## Screenshot manifest

`*.png` is gitignored, so the images are transient; these SHA-256 digests are the durable record.
Captured to `/tmp/adoff/` on the Loom VM.

```
6f022a4f9bb0fead1cd194dbe5971f24d23f05a612acfe96d26d19c4a78bbe55  08_kc.png            real Keycloak form (no stale SSO)
439bef9db9ee71549d8f570e9cfec88b9a4cbef8d5ec2889ca3ac6789622786c  13_entered.png       signed in as Ad Off Member 1 / Member
8105f508d130bf932873002422ffa38e3b96d0ed97ec4be16ece79b1920a12ee  28_toggle.png        create form complete, disclosure ON
df99d7031a25ad748a454e4985c8b16e813beb1d53babc0e84193ba41a255493  29_created.png       after Create
8eedf8fa924422138f2f96912d79181420308cca8a1e65307368866bc55e731a  34_reviewing.png     "Review payment" + 3 actions
2cda129a7748ac84bf1bff434732386f3e07df5f39d2ec0ca6b7e3514c7a559a  35_pending.png       "Payment awaiting verification", member sees only Cancel
898eccc5faa59f1df8220cbac3337587e4851b496025dad8122770283add824e  45_owner_giving.png  owner sees the member's instance + both owner actions
cea1b49e16d0d1b45f242b990159e5c8c1e14f459d16bc7fc0040722ae189d76  49_active.png        suppression proof + linked entitlement
0ee1369da0db9dc6cd0518af573bb5af79256ba0d666b47501492afb3fa6b72b  53_final.png         "Ad-off active" + "Receipt issued"
```

## Notes on method

- **Identity was cleared between the two sign-ins.** `pm clear com.android.chrome` **and**
  `pm clear com.example.loom_communities_demo`, then the community gate was confirmed to report
  `LoomAuthNotLoggedInException: No Loom authentication session is stored` and the **real Keycloak
  login form** was confirmed to appear before typing. No stale-SSO green screen was accepted.
- **`uiautomator dump` disagreed with the screen here, again.** It returned a sparse tree with two
  unlabelled buttons and none of the visible text fields. Screenshots were treated as authoritative
  throughout, per standing instruction.
- **`input keyevent 111` (ESC) dismisses the create dialog**, discarding entry, and TAB traversal
  wrapped from the last field back into `Price`, corrupting it. The reliable pattern was: tap field →
  type → tap the IME hide-chevron → screenshot the full form → tap the next field.
- No application code, community JSON, or tracker was modified. No credential was created or reset.
