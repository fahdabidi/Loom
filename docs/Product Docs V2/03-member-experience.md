# Loom Communities Product Definition 03: Member Experience

Status: Draft for review
Product area: 3 of 22 (Loom Communities / V2)
Source inputs: [Core Thesis V2](./01-core-thesis-and-platform-principles.md), [Extensible Loom Product Definition](./Extensible%20Loom%20Product%20Definition.md)
Predecessor: [Loom V1 Fan Experience](../Product%20Docs/03-fan-experience.md)

## 1. Product Definition

The member experience is how a person joins and participates in the communities they belong to —
through one portable identity, one inbox (Messages), one connections graph, and one wallet — using a
custom experience tuned to each community. A member should experience Loom as a better way to be part
of their real-world groups, not as a protocol.

## 2. Scope

Covers: adding a community (handle/QR); the required shell structure from the member's view (top ad
banner, nav panel with Messages and Connections); running community headline flows; messaging and
in-stream ads; connections and invitations; payments (dues/donations/tickets); consent and data
control; ad-free subscription; running the latest version automatically.

Does not cover: the App Shell architecture (Product 15), identity internals (Product 05), or ad
mechanics (Product 09) — referenced where relevant.

## 3. Key Experiences

### 3.1 One identity, many communities

- Sign in once with a Loom Passport; participate in every community under one identity.
- One inbox, one connections graph, one wallet across communities; pairwise/scoped relationships limit
  cross-community tracking.
- V1 creator/fan surfaces still work for members who use them.

### 3.2 Add a community

- Tap "Add a community"; find it by friendly handle or by scanning a QR code.
- The community's extension downloads locally; the member approves the permissions it needs.
- The community card appears in the member's home; opening it fetches the latest version automatically.

### 3.3 The shell a member always sees

- A thin **ad banner** at the top (unless ads are off for the member or community).
- A **navigation panel** (placement varies) that always includes **Messages** and **Connections**
  (which a community may rename), plus the community's own content.

### 3.4 Run the community's headline flows

- Vote on the next book; register a child for a soccer season and pay; submit an HOA architectural
  request; donate to a mosque fund; RSVP to an event; reserve a facility.
- Flows are custom per community but built on the same primitives, so they feel native and consistent.

### 3.5 Messages

- Chat, group/team messages, forums, and feeds — rich content (formatting, images, links, attachments).
- Loom may inject **in-stream ads** as native, labeled items (unless ads are off). They are part of the
  stream, not a removable banner.

### 3.6 Connections

- See the people in this community you're connected with.
- Invite your connections to join a community (unless they've blocked you); accept/decline requests;
  block to stop future invites.

### 3.7 Payments and wallet

- Pay dues, donate, buy tickets — through Loom-rendered payment surfaces — and get receipts.
- One wallet across all communities; private donation receipts where applicable.

### 3.8 Consent and data control

- See and revoke what each extension can access; control directory visibility.
- Sensitive submissions (care requests, minor data) go to the protected vault, visible only to the
  intended role.

### 3.9 Remove ads

- Subscribe to turn off all ads everywhere on Loom; or benefit from a community owner who has paid to
  remove ads on that community's surface.

## 4. User Stories

1. **As a member**, I scan a QR to add a community and immediately do something useful, so my first
   session has value.
2. **As a member of several communities**, I have one identity, inbox, connections, and wallet.
3. **As a member**, I message my team and see clearly labeled in-stream ads I can't be tricked by.
4. **As a member**, I invite a friend (a connection) to join my community.
5. **As a parent**, I register my child and pay, and my child's medical info stays in the protected vault.
6. **As a member**, I subscribe to remove ads.
7. **As a member**, I always run the latest version of the community app without reinstalling.

## 5. End-to-End Workflows

### Workflow A: Discover and install

Add community by handle/QR → extension downloads → approve permissions → card appears → open fetches
latest version. (Architecture V2 / 01 Workflow 2.)

### Workflow B: Participate

Open community → run headline flow → message/connect → pay where needed → receive receipts and notifications.

### Workflow C: Control and remove ads

Review/revoke consent → optionally subscribe to remove ads.

## 6. Cross-Area Requirements

- One Passport identity; portable wallet, connections, and consent.
- The member always sees the nav panel with Messages and Connections.
- In-stream ads are clearly labeled and reportable; ads honor ad-off.
- Sensitive submissions go to the protected vault; access is audited.
- Members always run the latest certified extension version.

## 7. Open Questions

- Connections privacy defaults (who sees your connections; per-community vs. global).
- In-stream ad reporting/mute affordances.
- How members discover public communities beyond direct handle/QR (see Product 13).
