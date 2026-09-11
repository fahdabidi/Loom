# Community initialization and authorization — review doc

**Status: FOR REVIEW. Nothing has been changed, ticketed, or repaired on the strength of this
document.** Written 2026-09-10 in answer to two questions:

1. *"The expectation is that during community initialization from the Skill, it should trigger an API
   that both creates the installable package/extension and initializes the community-admin role with
   all the default + community permissions. We should not be hand-granting the admin its permissions,
   or for that matter any of the roles. Those should be automatically done at the time of community
   creation through the Skill, AND dynamically through workflow executions depending on the community.
   You are allowed to manually create a non-community-admin role to seed the roles, but CANNOT assign
   permissions — that has to be 100% from the Skill triggering the initialization API (handled in the
   backend) or from the in-app community workflows (again handled via APIs). Walk me through how the
   existing code base maps to this. What are the gaps (if any)?"*
2. *"What are the security implications of [the policy endpoints accepting any valid Keycloak JWT]?
   What makes a Keycloak token valid and invalid?"*

Everything below was verified by reading the code and querying the live cluster. Where something is
inferred rather than observed, it says so.

---

## 0. The short version

**Your model is already the design of the install endpoint, and the server is stricter than you might
expect: it does not accept permissions from the caller at all.** The client sends *facts* (roles,
workflows, transitions, who may create, who may fire each transition); the backend derives every
permission id itself from the vendored vocabulary, and generates + grants the community admin role
without being asked. On that axis there is no gap.

**The gaps are on either side of it.** Nothing *triggers* that endpoint automatically — the Skill
cannot make network calls, so a human runs two Dart CLIs by hand. Nothing *prevents* the bypass —
`createRole` and `setRolePermissions` remain open, unauthorized, permission-accepting endpoints, and
they are what produced the Masjid over-grant. And the "dynamically through workflow executions" half
**does not exist at all**: the workflow service's App Access client is read-only.

**The security finding is worse than the Masjid incident that led to it.** An ordinary seeded member
account, holding zero governance permissions, reached both policy-mutation endpoints on the live
cluster during this review. Proof is in §2.4.

---

## 1. How community initialization actually works today

### 1.1 The chain, end to end

```
  [1] Skill dispatch            data/call_skill_authoring_agent.sh
        │                       Codex, --ephemeral, scratch dir with ZERO repo content.
        │                       Produces: product doc + community *.jsonc. Files only.
        ▼
  [2] a human copies the package into
        app/packages/core/loom_communities_app_shell/assets/<Community>_Example.jsonc
        ▼
  [3] a human runs the CLIENT-SIDE deriver          (Dart, in the Loom repo)
        loom_app_access_provisioning/bin/derive_app_access_provisioning_plan.dart <assets dir>
        → emits one InstallCommunityPackageRequest per community: communityHandle,
          grammarVersion, roles[{roleId,label}], workflows[{workflowType, cardSurfaceFamily,
          createRoleIds[], transitions[{transitionId, action, allowedRoleIds[]}]}]
        NOTE: it emits NO permission ids. It cannot. It has no vocabulary.
        ▼
  [4] a human runs the applier, or a hand-written curl
        loom_app_access_provisioning/bin/apply_app_access_provisioning.dart   (--apply)
        → POST /v1/apps/loom_communities/community-installations
          headers: Idempotency-Key, X-Loom-Actor, X-Loom-Correlation-Id (must be a real UUID)
        ▼
  [5] SERVER: AppAccessService.installCommunityPackage()      ← the authoritative step
        CommunityPermissionDeriver.derive(request):
          • rejects a grammarVersion that is not the vocabulary's specVersion
          • for each workflow: archetype → permissionPrefix
              createRoleIds[]      → "<prefix>.create"      granted to those roles
              transition.action    → "<prefix>.<action>"    granted to transition.allowedRoleIds[]
          • builds permissionsByRoleId ENTIRELY from the vocabulary; the request's
            contribution is only *which role* and *which action*
          • resolveSystemAdminRole(communityHandle) reads the vocabulary's
            governance.adminRole:
                { isSystemDefault: true,
                  idTemplate: "<communityHandle>-admin",
                  grantedPermissions: [community.view, community.invite,
                                       community.manage_members, community.manage_roles,
                                       community.manage_settings] }
        then, in order:
          • create each declared domain role it does not already find (with NO permissions)
          • create the "<handle>-admin" role if absent (with NO permissions)
          • setRolePermissions(each domain role, its derived set)
          • setRolePermissions("<handle>-admin", exactly the 5 governance ids)
          • sweep: delete any group role the package does not declare
            (the generated admin and the platform admin are explicitly spared)
```

### 1.2 Against your stated expectation

| Your requirement | Where it stands |
|---|---|
| One API that creates the installable package **and** initializes the community-admin role with default + community permissions | **The API exists and does both** (`POST /v1/apps/{appId}/community-installations`, step [5]). The admin role is generated from the vocabulary template and granted the 5 `community.*` ids without the caller asking. |
| No hand-granting of permissions to the admin | **Correct by construction at this endpoint** — the install request has no permission field; the server derives. The endpoint cannot be used to hand-grant. |
| No hand-granting of permissions to any role | **Correct at this endpoint, but not enforced elsewhere** — see gap G2. |
| Done automatically at community creation, triggered by the Skill | **Gap G1.** The Skill cannot call an API. A human runs steps [2] [3] [4]. |
| Dynamically through workflow executions | **Gap G3.** No such path exists. |
| Manually creating a non-admin role to seed roles is allowed | Supported — `createRole` does this. But the same endpoint also accepts `permissionIds` inline, which is the thing you want forbidden (G2). |

### 1.3 The gaps

**G1 — the Skill cannot trigger initialization, and structurally cannot.**
`call_skill_authoring_agent.sh` runs the authoring agent `--ephemeral`, in a scratch directory with
zero repo content and `--add-dir` never granted. It produces text. Even the validator on `:8787` is
documented as unreachable from that sandbox — the script's own header records that its shell-level
network access is unreliable and that output must be validated from outside. So "the Skill triggers
the API" is not a small wiring change: something *outside* the Skill sandbox has to own that call.
Today that something is a person running two CLIs. The honest framing is that initialization is a
**documented manual runbook**, not an automated pipeline, and every incident in this area has come
from a human improvising inside that runbook.

**G2 — `createRole` and `setRolePermissions` are open, permission-accepting endpoints.**
- `createRole(appId, request)` accepts `permissionIds` inline and validates only
  `ensurePermissionsExist` (the ids are real). It will happily attach `community.manage_roles` to any
  new role.
- `setRolePermissions(appId, roleId, request)` replaces a role's entire set with whatever is posted;
  again the only check is that the ids exist.
- Neither knows what *kind* of role it is editing. `app_role(app_id, role_id, group_id, display_name,
  description, created_at)` has **no column** distinguishing a package-declared domain role from the
  platform-generated governance role. The only difference is the shape of the string.
- `permissions.md:522` states the invariant — *"It holds the `community.* ` governance permissions,
  and only the admin role holds them"* — and **nothing in the service, the schema, or any gate
  enforces it.** `check_role_parity.sh` compares role **existence** only, so it passes today with a
  28-permission admin sitting in the database.

This is precisely the "hand-granting" you want eliminated, and it is how the Masjid state was
produced (§3).

**G2a — a latent collision in the installer itself.** If a package declares a `roleId` equal to the
generated admin id (`<handle>-admin`), `installCommunityPackage` creates/reuses that one row as a
domain role, writes its derived domain permissions, then the governance step overwrites them with the
5 governance ids, and the sweep spares it. No conflict, no finding, no rollback. **Any existing
holders of that domain role silently become community administrators.** Verified by reading
`AppAccessService.java:498-575`; not currently triggered by any shipped package.

**G3 — workflows cannot grant anything.** The workflow service's App Access client exposes exactly
four methods, all read-only: `checkAccess`, `resolveRoleIds`, `hasActiveMembership`,
`listGroupMembers`. There is no call anywhere in `loom_workflow_service/lib` that assigns a role,
creates a role, or changes a permission set. So the "dynamically through workflow executions
depending on the community" half of your model **is not implemented**. A workflow named "approve
membership" today changes a workflow instance's state; it does not make anyone a member or grant them
a role. If that capability is intended, it is new work — and it is the one place where a *narrow,
audited, server-side* grant path would need to be designed deliberately, because it means a community
workflow can change authorization.

**G4 — direct SQL against the auth database is an accepted operational path.** The Access Control
tracker (lines ~2149-2176) documents an approved per-community `BEGIN; INSERT … UPDATE … DELETE;
COMMIT;` recipe for renaming roles. It ran on 2026-09-02 and left **zero** trace in
`idempotency_record`, which only records API calls. Anything written that way bypasses every rule the
service might later enforce.

**G5 — a package role rename is a migration nothing propagates.** Already recorded in `CLAUDE.md` and
guarded (for *existence*) by `check_role_parity.sh` after the September incident. Unchanged by this
review.

---

## 2. The token model, and what it means

### 2.1 What makes a token valid here

`JwtSecurityConfiguration` is the whole of app-access's authorization:

```java
.authorizeHttpRequests(a -> a
    .requestMatchers("/actuator/health/readiness", "/actuator/health/liveness").permitAll()
    .anyRequest().authenticated())
.oauth2ResourceServer(rs -> rs.jwt(Customizer.withDefaults()))
```

and the decoder:

```java
NimbusJwtDecoder.withJwkSetUri(jwkSetUri).jwsAlgorithm(SignatureAlgorithm.RS256).build();
decoder.setJwtValidator(JwtValidators.createDefaultWithIssuer(expectedIssuer));
```

Deployed values: `JWT_ISSUER=http://192.168.56.10:30082/realms/loom`,
`JWT_JWKS_URI=http://keycloak.loom.svc.cluster.local:8080/realms/loom/protocol/openid-connect/certs`.

So a token is **valid** if and only if:

| Checked | Not checked |
|---|---|
| RS256 signature verifies against the `loom` realm's JWKS | **audience** (`aud`) — not validated |
| `iss` equals the configured issuer | **client** (`azp`) — any realm client is accepted |
| `exp` / `nbf` within clock skew | **scope** — not inspected |
| | **realm/client roles** — not inspected |
| | **whether the subject is a Loom fan at all** — no `fanId` claim required |
| | **whether the caller may administer the target app, group, or community** |

"Invalid" therefore means only: malformed, wrong signature, wrong issuer, or expired. **Nothing about
who you are.** `anyRequest().authenticated()` is the entire policy — there is no `@PreAuthorize`, no
authority mapping, no per-route rule.

### 2.2 The asymmetry that makes this a defect rather than a design choice

The service *does* have an authorization concept, and uses it — on the **membership** endpoints:

```
setGroupMembership      : requireGroupAdministrator(appId, groupId, setByFanId, …)     AppAccessService:668
issueInvite             : requireGroupAdministrator(…)                                 :710
decideGroupMembership   : requireGroupAdministrator(…)                                 :920
removeMember            : requireGroupAdministrator(…)                                 :1000
```

The **policy** endpoints — the ones that define what any role may do — have no equivalent:

```
createRole              : no caller check
setRolePermissions      : no caller check
installCommunityPackage : no caller check
deleteRole              : no caller check
```

Worse, `requireGroupAdministrator` decides administration by testing for `community.manage_members`
(`AppAccessService:1316`). So the unguarded endpoint can **mint the very permission the guarded
endpoints trust**: grant yourself `community.manage_members` via `setRolePermissions`, and every
membership check then passes legitimately.

Note also that `IdempotencyService:59` can return a stored response without re-executing the mutation.
Any authorization check must therefore run *before* idempotency replay, not only inside the write.

### 2.3 Exposure

`app-access` is a **NodePort** service (`8080:30080/TCP`), as is Keycloak (`30082`). Both are
reachable on the VM's host-reachable address `192.168.56.10` — that is how every tool in this repo,
and this review, calls them. This is a development cluster on a host-only network, so the practical
blast radius today is "anything that can reach the VM". It is not internet-exposed. But the service
is written as though something upstream restricts these routes, and nothing does.

### 2.4 Live proof (non-mutating)

Run during this review against the deployed cluster. The account is `loom-social-member-1` /
`fan-social-member-1`, which holds exactly one role (`member` in Member Social Space, 8 permissions,
**0 governance permissions**) — verified by query.

Its token was obtained from Keycloak's **built-in `admin-cli` public client** via a plain password
grant — no client secret, no consent. The resulting token carries `aud: null`, no `fanId`, scope
`email profile`, `azp: admin-cli`. It is not even a Loom application token.

Two deliberately non-mutating probes, chosen so that *authorization* failure and *business-logic*
failure are distinguishable, plus a control:

| Request as `loom-social-member-1` | Result |
|---|---|
| `PUT /v1/apps/loom_communities/roles/zzz-probe-nonexistent-role/permissions` | **HTTP 404** `role_not_found` |
| `POST /v1/apps/loom_communities/roles` with `roleId: chess-owner` | **HTTP 409** `role_already_exists` |
| same PUT, **no token** (control) | **HTTP 401** |

The control proves the 404/409 are past the authentication boundary. **404 and 409 are business-logic
answers: the request was authorized and failed only because the role did not exist / already
existed.** Had the first probe named a real role, the write would have gone through.

Concretely, with no additional privilege, that account could have issued
`PUT /v1/apps/loom_communities/roles/member/permissions` with the five `community.*` ids and made
every member of Member Social Space a community administrator. **This is exactly the scenario in your
question — a normal user acquiring permissions intended for an admin — and it is available today.**

No state was changed by these probes.

**What this does *not* establish:** no evidence suggests this has ever been exploited. All 230
`idempotency_record` rows are attributable to operator sessions. Absence of evidence in a log that
only records API calls is weak evidence, and the 2026-09-02 SQL writes are invisible to it entirely.

### 2.5 One correction to my earlier report

I previously told you the over-granted Masjid admin "can fire the four owner-only transitions". **That
was wrong**, and the root cause agent caught it. Workflow guards intersect actual **role ids**
(`guard_evaluator.dart:29-37`) and never consult permissions, so a holder of `masjid-nur-admin` fails
a `byRoleIds: ["owner"]` guard regardless of what permissions that role carries. The violation is real
at the App Access layer — `checkAccess` returns domain allowances for that holder, which is what the
workflow service's `create` gate consults — and absent at the engine-guard layer. Same trap as the
calendar-permissions row: one layer's answer is not the system's answer.

---

## 3. How the Masjid incident maps onto these gaps

Not a JSON defect. The package declared ordinary domain roles and the 2026-08-26 install derived
exactly 21 + 23 = 44 grants correctly.

| Step | What happened | Gap it used |
|---|---|---|
| 2026-08-31 02:32 | A session needed a governance admin per community, saw the **domain** role `masjid-admin` (label "Masjid Admin"), classified it as governance **by its name**, and sent it 23 domain + 5 governance permissions via `PUT /roles/masjid-admin/permissions` (HTTP 200, in `idempotency_record`). | **G2** — the endpoint accepted a mixed set with no kind rule |
| 2026-09-02 09:33:34–35 | The documented SQL recipe renamed all eleven admins to `<handle>-admin` in one second, **no API records**. Its mapping said `masjid-admin → masjid-nur-admin (preserve all 28 grants)`, copying the domain role's label, grants and holder into the governance id and deleting the domain role. Its own anomaly note flagged the 23 extras "for user decision"; unresolved. | **G4** — direct SQL, unaudited, no rules |
| 2026-09-05 | Package regenerated, `masjid-admin → owner`. Nothing re-provisioned; `owner` did not exist until it was created by hand on 09-09. | **G5** |

Live state, measured: `masjid-nur-admin` 28 (5 governance + exactly the 23 derived for `owner`);
`owner` 23; `community-member` 21. Every other `<handle>-admin` holds exactly 5. No non-admin role in
any live group holds any `community.*` — the single hit is `cedar_commons_hoa_admin` in the orphaned
underscored duplicate group, a known separate artifact from 2026-08-13.

The through-line: **every one of these steps was a person acting in good faith inside a documented
runbook, and the platform had no opinion about any of them.**

---

## 4. Proposed target design — for your approval, not yet ticketed

Stated as your rule, then what would have to exist for the platform to *hold* it rather than rely on
operator care.

> **Permissions are never assigned by hand. A role's permission set is a pure function of the
> installed package plus the vocabulary, computed server-side. Role *membership* is assigned by
> people and by workflows; role *capability* is not.**

**P1 — Authorize the policy endpoints.** Require a trusted provisioning principal (a Keycloak client
role or service account — never an end-user fan token) on `createRole`, `setRolePermissions`,
`installCommunityPackage`, `deleteRole`, and any catalog-mutation route. Check **before** idempotency
replay. Keep membership assignment (fan-facing, `requireGroupAdministrator`) separate from permission
definition (provisioning-facing). Decide separately whether app-access should also move off NodePort
to ClusterIP so only in-cluster callers reach it.

**P2 — Make permission assignment structurally impossible by hand.** The strongest form of your rule:
remove `permissionIds` from the public `createRole` contract, and make `setRolePermissions`
**internal to the installer** rather than a public route. A hand-created seeding role would then be
created *without* permissions and receive them only from the next install derivation — which matches
"you may manually create a non-admin role, but cannot assign permissions" exactly. If a public
override must survive for emergencies, it should be a distinct, loudly-named, provisioning-only route
that writes an audit event.

**P3 — Persist role kind and enforce grant compatibility.** Add an immutable, service-set kind
(`package_domain` | `community_system_admin`, with an explicit policy for any other existing roles).
Rules, keyed on **vocabulary membership, not on name shape**:
- `package_domain` → permission set contains no governance-catalog id;
- `community_system_admin` → has a group, its id equals that group's resolved admin id, and its set
  equals the vocabulary's governance set exactly;
- reject a package `roleId` equal to the resolved admin id **before any write** (closes G2a);
- database uniqueness: one system-admin role per app/group.
Backfill kinds from package declarations and provenance — **not** from current grants, which are
contaminated.

*The root cause agent's caveat, which I agree with:* a kind column alone is not sufficient, and it
does not distinguish a domain *member* from a domain *owner* — both are `package_domain`. Only the
install derivation knows the correct set per role, which is the argument for P2: the derivation should
be the sole writer.

**P4 — Permission-SET parity gate.** Extend `check_role_parity.sh` (or add a sibling) to compare
**exact id sets**, not existence and not counts — replacing one correct permission with a wrong one
preserves the count. Per app/group/role: generated admin identity and set vs the vocabulary; every
domain role vs its derived set; no governance ids on any other managed role. Expected values must come
from the **Java deriver** via a read-only preview/export path, not from a second permission algorithm
re-implemented in shell or Python. Needs a positive control and a negative test that makes it exit 1.
A gate detects drift; it prevents nothing unless deployment depends on passing it.

**P5 — Close the SQL bypass and add an audit trail.** Retire the tracker's rename recipe. A rename
becomes `createRole` + move every assignment/reference + `deleteRole`, same kind only, refusing
destination collisions. **Domain → governance is never a rename**: a governance role is created
separately and assigned deliberately. Add an actor-attributed audit event for policy writes (before/
after sets, package version, correlation id) — `idempotency_record` stores responses, not a
before/after history. If operational SQL must remain possible, the compatibility rules need database-
level enforcement too, since service rules cannot protect writes that bypass the service.

**P6 — Validator rule + reference reconciliation.** A validator error when a package declares a
`roleId` matching the governance id template, mirroring the backend rejection (early feedback; the
backend stays authoritative). The agent advised **against** banning every `-admin`/`_admin` suffix or
"Admin" label — that rejects legitimate domain terminology and security must not depend on avoiding a
word. Separately, `identity-types.md:63-78` ties community setup and admission to the package's
reserved `owner`, while `permissions.md:510` assigns governance to the generated `<handle>-admin`;
that conflict contributed to the 09-05 rename and needs reconciling (reference docs — my edit).

**P7 — Decide whether workflows may grant.** G3 is currently a *hole in your model*, not a defect in
the code: nothing grants anything from a workflow. If "dynamically through workflow executions" is
intended, it needs its own design — which effects may grant which roles, under whose authority, and
how that is audited. It should not be bolted onto the existing effect vocabulary casually, because it
makes community-authored JSON able to change authorization.

**Coverage check** — what each control would have caught:

| Control | 2026-08-31 (governance onto a domain role) | 2026-09-02 (SQL copy into governance) | The §2.4 probe |
|---|---|---|---|
| P1 authorize policy endpoints | no (operator was authorized) | no (bypasses the API) | **yes** |
| P2 remove hand-assignment | **yes** | no (bypasses the API) | **yes** |
| P3 kind + grant rules | **yes** | only via the API path | **yes** |
| P4 exact-set parity gate | detects | detects | detects |
| P5 close SQL + audit | no | **yes** | no |
| P6 validator + docs | no | no | no |

Note that no single control covers everything, and that P4 is the only one that would have *surfaced*
both historical steps after the fact.

---

## 5. What I could not verify

- Whether any upstream network control (outside k3s) restricts the NodePorts. I verified the service
  type and that the routes answer from the VM; I did not audit host firewall rules.
- Whether the over-granted admin's App Access allowances were ever *used* to do anything. The B25
  evidence shows the 09-03 walkthrough used `masjid-admin-20` (not `fan-masjid-admin`), and the 09-08
  manifest reports the owner-only transitions as unreachable for the admin. No evidence of misuse; no
  proof of its absence either.
- Whether `admin-cli` password grant is intended to be enabled on the `loom` realm, or is a leftover
  default. I observed that it works; I did not review the realm's client configuration.
- The exact set of "other" app-level roles that a `role_kind` backfill would need a policy for. Today
  there are zero roles with `group_id IS NULL`, which makes the backfill simpler than it might be
  later.

---

## 6. What happens next

Nothing, until you say so. On approval I will fold the agreed items into `TODO.md` and the Access
Control tracker as real rows and work them in dependency order — P1 and P2 first (they close the live
exposure), then P3/P4 together (write-time rule plus the gate that proves it), then P5/P6, with P7
treated as a separate design question rather than a fix.

The two `needs-user-decision` rows already added to `TODO.md` on 2026-09-10 record the raw findings
and cite this document; they do not commit to any of the above.
