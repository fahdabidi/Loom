# Loom Communities Product Definition 12: Community Discovery, Connections, and Invitations

Status: Draft for review
Product area: 12 of 22 (Loom Communities / V2)
Source inputs: [Core Thesis V2](./01-core-thesis-and-platform-principles.md), [API Reference 1.20](./Extensible%20Loom%20API%20Reference.md#120-connections-api)
Predecessor: [Loom V1 Creator-Led Recommendation Economy](../Product%20Docs/12-creator-led-recommendation-economy.md)

## 1. Product Definition

Community discovery in V2 is handle-, QR-, invite-, connection-, and search-driven. The V1
creator-referral economy does not map directly to real-world communities, so this area becomes the
member-safe way to find, add, invite, and connect across communities.

The key primitive is the Passport-level connections graph: members can connect with people, invite them
into communities or spaces, and carry social context across communities without exposing private
membership or follower data by default.

## 2. Scope

This area covers community handles, QR codes, local add-to-app, invitations, connection graph, contact
and link invites, blocked/revoked invite behavior, member referrals without economic incentives,
community directories, and discovery handoff into search. Search ranking and AI discovery are Product
13; member data rights are Product 14.

## 3. Key Features and Differentiators

| Feature | Definition | Product value | Interacting areas |
| --- | --- | --- | --- |
| Handle discovery | Friendly community handles resolve to public or joinable profile records. | Communities can be shared verbally and in print. | 04, 13 |
| QR add | QR payload opens Main Loom App and adds or previews community. | Works for churches, mosques, classrooms, sports fields, and meetings. | 15 |
| Invitations | Invite links, QR, email, SMS, and connection-based invites with role/space context. | Owners can onboard members without importing external graphs. | 04, 21 |
| Connections graph | Passport-level person-to-person relationship with invite permissions and blocks. | Members can invite trusted contacts across communities. | 05, 14 |
| Local directory | Public and member-visible community directory entries. | Members can browse nearby or known communities where policy allows. | 13 |
| Privacy-preserving recommendations | Suggestions may use public metadata, member intent, and connections without exposing private membership. | Helps discovery without recreating V1 referral economics. | 14, 17 |

## 4. Product Experience Requirements

Members should be able to scan a QR, enter a handle, accept an invite, connect with another member, and
invite a connection to a community or space. They should see whether a community is public, private,
invite-only, paid, restricted, or sensitive. Owners should be able to generate invites, restrict invite
permissions, revoke links, and see onboarding funnel status.

## 5. User Stories

1. **As a member**, I scan a mosque QR code and add the community.
   End state: profile preview opens and membership request or join is available.
2. **As an owner**, I create a youth soccer team invite for parents.
   End state: invite carries space, role, expiry, and guardian requirements.
3. **As a member**, I connect with a neighbor and invite them to an HOA space.
   End state: connection invite is delivered unless blocked or policy denies it.
4. **As an admin**, I revoke an old invite link.
   End state: future attempts fail with a clear reason.
5. **As a member**, I hide my membership from public discovery.
   End state: connection and directory views respect visibility settings.

## 6. End-to-End Workflows

### Workflow 1: Resolve handle or QR

1. Member enters handle or scans QR.
2. Community registry resolves payload and visibility.
3. App Shell shows community card, join rules, installed app preview, and data/permission notes.
4. Member joins, requests approval, or saves for later.
5. Audit records discovery/add event where policy requires.

### Workflow 2: Create and accept invite

1. Admin selects community or space, target role, expiry, and invite mode.
2. Invite service creates signed payload.
3. Candidate opens invite and resolves Passport.
4. Role/policy engine checks join rules, guardian requirements, capacity, and block state.
5. Membership is created or request enters approval queue.

### Workflow 3: Connection-based invitation

1. Member opens Connections shell and selects contact.
2. App checks connection state, blocks, invite permission, and community policy.
3. Invite is sent with limited preview.
4. Recipient accepts, denies, or blocks.
5. Connections graph and community membership update accordingly.

## 7. Cross-Area Requirements

- Discovery must not reveal private membership, protected spaces, or sensitive data.
- Invites must carry role/space context and versioned policy.
- Blocks and revocations must apply across communities.
- Search and AI must treat invite-only/private communities as non-public unless policy allows.
- No referral economics should be introduced without explicit governance review.

## 8. Prototype Implications

The MVP should implement handle lookup, QR payloads, invite link generation, invite accept/request,
Connections shell basics, block state, and member visibility settings. Full contact import can be
deferred.

## 9. FAQ

**Is this a recommendation economy?**
Not in V2. Communities need discovery and invitations first; monetized referrals are not part of the
baseline community model.

**Can members invite anyone?**
Only if community policy, role, connection state, and block rules allow it.

## 10. Open Questions

- Should nearby/community directory discovery be enabled in MVP or only handle/QR/invite?
- What limits prevent invite spam?
- How much connection graph import is acceptable without privacy risk?
