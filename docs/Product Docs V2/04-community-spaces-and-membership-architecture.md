# Loom Communities Product Definition 04: Community, Spaces, and Membership Architecture

Status: Draft for review
Product area: 04 of 22 (Loom Communities / V2)
Source inputs: [Core Thesis V2](./01-core-thesis-and-platform-principles.md), [API Reference 1.1-1.4](./Extensible%20Loom%20API%20Reference.md#1-core-community-api-families)
Predecessor: [Loom V1 Creator Channel and Metadata Architecture](../Product%20Docs/04-creator-channel-and-metadata-architecture.md)

## 1. Product Definition

The community model is the durable container for Loom Communities. A community owns its handle,
profile, spaces, memberships, roles, policies, installed extensions, data, payments, audit history, and
export boundary. It replaces the V1 creator channel as the main product object while preserving the V1
principle that the owner should not be locked into a single host, app, or provider.

A space is a nestable sub-community: a team, committee, ministry, classroom, book room, facility,
case queue, event group, marketplace, or care circle. Spaces inherit community identity and policy but
can narrow membership, roles, surfaces, extensions, and visibility.

## 2. Scope

This area covers the community object, handles, profiles, spaces, membership lifecycle, roles,
permissions, invitations, join policies, directory visibility, extension bindings, and member/space
audit. Identity internals are Product 05; app-shell rendering is Product 15; governance and
certification are Product 19.

## 3. Key Features and Differentiators

| Feature | Definition | Product value | Interacting areas |
| --- | --- | --- | --- |
| Community object | Stable `communityId`, unique handle, profile, visibility, owner, installed extensions, and export policy. | A community can be discovered, installed, exported, and moved without changing identity. | 06, 10, 12, 15, 21 |
| Nestable spaces | Arbitrary-depth spaces with inherited or narrowed membership and policy. | Real communities can model teams, committees, classes, rooms, and private groups without custom backend code. | 10, 13, 15 |
| Membership lifecycle | Invite, request, approve, join, suspend, leave, remove, transfer owner, and archive. | Gives owners/admins operational control without owning member identity. | 05, 14, 17 |
| Roles and permissions | Role templates plus custom role grants scoped to community, space, or workflow. | Extension actions can be permissioned consistently across verticals. | 05, 10, 19 |
| Policy inheritance | Community policies establish defaults; spaces and extensions can narrow but not bypass them. | Safe customization without fragmentation. | 14, 17 |
| Extension bindings | Extensions mount to community or space surfaces and receive only approved context. | One community can run many custom experiences while sharing platform primitives. | 10, 15 |
| Directory and visibility controls | Public, unlisted, private, invite-only, and member-visible records. | Discovery works without exposing private spaces or sensitive membership. | 12, 13, 14 |
| Audit and export boundary | Membership, role, space, and install changes produce audit records and exportable state. | Portability and dispute resolution are built in. | 06, 19, 21 |

## 4. Product Experience Requirements

Owners and admins should be able to create a community, claim a handle, choose a template, define
spaces, approve or reject membership, assign roles, install extensions, and export the full community
state. They should see clear warnings when a policy or extension affects member data, payments, minors,
protected vault data, ads, or portability.

Members should be able to understand which community and space they are joining, which roles they hold,
what data is visible, what notifications they will receive, and how to leave or export their own data.
They should never need a new account for each community.

Extensions should be able to read community/space context, request role-scoped capabilities, and create
domain entities through Loom APIs without writing directly to community membership or role storage.

## 5. User Stories

1. **As an owner**, I create a community, claim a handle, and install a starter extension.
   End state: `CommunityRegistryApi` stores the community, App Shell can resolve it, and the owner has
   the `owner` role.
2. **As an admin**, I create spaces for teams, committees, or ministries.
   End state: each `CommunitySpace` has scoped members, roles, surfaces, and export state.
3. **As a member**, I join by QR code or invitation without creating a new identity.
   End state: my Passport is linked to a community membership and my visibility preferences apply.
4. **As an owner**, I assign a treasurer or coach role for one space only.
   End state: effective permissions allow only the scoped actions.
5. **As an extension**, I create a soccer team space or HOA committee through public APIs.
   End state: the platform owns the space record and emits auditable events.

## 6. End-to-End Workflows

### Workflow 1: Create community and claim handle

1. Owner signs in with Passport.
2. Owner chooses community type, handle, profile, default visibility, and starter template.
3. `CommunityRegistryApi.createCommunity` validates handle uniqueness and writes the community.
4. `CommunityRolePolicyApi` assigns owner and default admin/member roles.
5. `CommunityAppShellApi` registers the community card and required shell surfaces.
6. Audit records `community.created`; discovery can resolve the handle or QR payload.

### Workflow 2: Create a nested space

1. Admin selects a community and parent space, if any.
2. Admin defines name, type, visibility, member rules, role overrides, and allowed extensions.
3. `CommunitySpacesApi.createSpace` writes the space and parent relationship.
4. Role/policy engine computes inherited and narrowed permissions.
5. Search and App Shell receive events to update visible navigation and discoverable records.

### Workflow 3: Invite and approve member

1. Admin creates invite link, QR, email, or connection-based invite.
2. Candidate opens invite in the Main Loom App.
3. Passport resolves identity; member reviews visibility, notifications, and data grants.
4. Join policy auto-approves or routes to an admin approval queue.
5. Membership record is created, role grants are assigned, and notifications are emitted.

### Workflow 4: Role change and policy enforcement

1. Admin changes a member's role for a community or space.
2. Role/policy engine checks actor authority and writes a versioned grant.
3. Extension runtime and App Shell pick up new effective permissions.
4. Protected data, payments, moderation, and admin actions immediately use the new permission version.

### Workflow 5: Leave, remove, or archive

1. Member leaves or admin removes a member.
2. Membership state changes to left, removed, suspended, or archived.
3. Notifications, role grants, extension access, and visibility are revoked or narrowed.
4. Member data rights, export, and retention rules continue under Product 14.

## 7. Cross-Area Requirements

- Identity comes from Passport; communities do not own accounts.
- Roles and policy are contract-first and versioned; all mutations carry idempotency keys.
- Sensitive membership contexts, such as minors or care groups, must route through protected vaults.
- Search sees only records allowed by community/space visibility and member consent.
- Extensions may request capabilities but cannot bypass community policy, app-shell invariants, ads, or export.

## 8. Prototype Implications

The MVP must support community creation, handle/QR resolution, one level of spaces, membership invite,
owner/admin/member roles, installed extension references, and exportable community state. Deeply nested
spaces, advanced role templates, and complex join policies can follow after the first vertical demos.

## 9. FAQ

**Is a community the same as a V1 creator channel?**
No. A V1 channel is creator/media-centered. A V2 community is a broader operational container that can
include publishing, messaging, payments, events, facilities, documents, and custom extensions.

**Can extensions create spaces?**
Yes, but only through `CommunitySpacesApi`, with declared capability permission and owner/admin policy.

**Can members belong to multiple communities?**
Yes. Passport identity is portable; membership records are community-scoped.

## 10. Open Questions

- How much role-template vocabulary should be standardized for MVP verticals?
- Should deeply nested spaces ship in MVP or be simulated by one parent/child level first?
- Which membership states need first-class legal retention rules versus extension-defined labels?
