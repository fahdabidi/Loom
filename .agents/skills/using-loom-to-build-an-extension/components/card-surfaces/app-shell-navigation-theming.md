# App Shell Navigation, Tabs, Pinning, And Theming Surface

## Supported Interactions

- Configure community tabs, assign card surfaces to tabs, pin important surfaces, and expose Home and
  Messages/Communication as default tabs.
- Configure role-specific tabs, labels, icons, order, visibility, pinned surfaces, and surface
  assignment so a member, admin, coach, board member, guardian, donor, or reviewer can each see the
  navigation model that matches their jobs-to-be-done.
- Support minimized, medium/in-focus, and expanded/maximized presentation states for card surfaces.
- Persist scroll/focus state, make the first card in a tab the in-focus medium card, minimize cards
  that scroll past, and expand a tapped card into a full/detail view.
- Configure community theme tokens for color, imagery, icons, typography roles, and surface-level
  variants while preserving App Shell accessibility and required controls.
- Expose customization knobs for typography roles, card density, tab labels, tab icons, surface
  presentation defaults, pinned state, community-card treatment, and shell-safe color palettes.
- Let render bindings derive each tab renderer from its bound archetypes. See
  [Per-Tab Renderer Contracts](./tab-renderer-contracts.md).

## Roles and Permissions

| Role | Permissions | Can do |
| --- | --- | --- |
| Member | `community.surface.navigation.read` | Use role-appropriate tabs, pinned surfaces, expansion, messages, and theme-rendered community UI. |
| Owner/admin | `community.surface.navigation.configure` | Configure tab labels, tab order, icons, role visibility, pinned surfaces, surface grouping, presentation defaults, and theme tokens. |
| Shell/governance | `community.surface.navigation.admin` | Enforce Home/Messages defaults, accessibility, ad/nav invariants, binding-derived visibility, and safe theme bounds. |

## Custom Experience Guidance

Every community gets Home and Messages/Communication by default. All card surfaces appear on Home
unless assigned to custom tabs. A community can add tabs such as Calendar, Documents, Teams, Giving,
Marketplace, Care, or Admin. Pinned surfaces remain visible at the top of a tab. Theme tokens should be
declared once and applied across the community card, tabs, cards, expanded surfaces, buttons, labels,
edit text, and dialogs — implemented today as the card theme cascade described below: a community-level
default, optionally overridden per tab, optionally overridden per card surface (workflow), so no card
surface has to hardcode its own colors independent of the community it belongs to.

Tabs are resolved per role. The same community may expose `Home`, `Calendar`, `Marketplace`, and
`Messages` to a general member, while an admin sees `Home`, `Admin`, `Documents`, `Giving`, and
`Messages`. Unauthorized role tabs must be hidden or disabled with a reason; they must not leak
restricted workflow content. A surface can appear in multiple role tabs when the visible state is
different, such as a member seeing read-only request status while a board reviewer sees the decision
queue.

Customization knobs should be declared as a `CommunityAppShellCustomizationSpec`:

- tab labels, tab icons, order, role visibility, and pinned-surface defaults;
- community-card minimized and medium presentation, including logo, card image, title typography,
  detail typography, accent color, and badges;
- in-community typography roles: community title, section title, card-surface title, body, label,
  button, edit text, badge, metadata, and receipt/audit text;
- surface presentation defaults: minimized, medium/in-focus, expanded, pinned, density, and spacing;
- safe theme palette: primary/accent/background/surface/text/action colors with contrast validation.

Omit `rendererContractId`; the workflows bound to a tab determine its renderer. When every binding
uses `event-rsvp`, the App Shell derives the calendar surface. When every binding uses
`equipment-loan`, it derives the marketplace surface. Those are the only whole-tab archetype
surfaces.

### Binding-derived tabs

A tab with mixed archetypes, or any other archetype, gets the engine-native generic list. That is the
correct renderer: it runs the live query and dispatches every instance to the widget for its own
`cardSurfaceFamily`. Declaring `engine-native-generic-list` explicitly overrides derivation and can pin
an otherwise eligible tab to the generic list, so omit the field and let the bindings decide. Home and
Messages remain structural App Shell tabs. See
[Per-Tab Renderer Contracts](./tab-renderer-contracts.md) for the exact derivation rules.

## Package / Initialization Contract

Standalone Skill-generated extensions can declare App Shell behavior in the extension package or
initialization package instead of requiring a Loom source edit. The Demo App reads an optional
`appShell` object from `loom.initialization.json` first, then from `loom.extension.json`.

Minimal shape:

```json
{
  "appShell": {
    "tabs": [
      {
        "tabId": "calendar",
        "label": "Walks",
        "icon": "calendar",
        "description": "Photo walk schedule and RSVP detail.",
        "sectionTitles": ["Upcoming events"],
        "cardSurfaceFamilies": ["event-rsvp"],
        "pinningPolicy": "pin-first-critical-surface",
        "pinningPolicyRationale": "The next dated event is the most time-sensitive item.",
        "pinnedWorkflowIds": ["photo-walk-rsvp"],
        "visibleRoleIds": ["camera-organizer", "camera-member"]
      }
    ],
    "roleTabs": {
      "camera-member": [
        {
          "tabId": "messages",
          "label": "Club chat",
          "icon": "messages",
          "description": "Member threads and invites.",
          "pinningPolicy": "none",
          "pinningPolicyRationale": "Messages uses inbox/thread state rather than pinned cards."
        }
      ]
    }
  }
}
```

`tabs` declares community-level tab overrides. `roleTabs` adds or overrides tabs for a specific
role. Home and Messages remain required shell destinations; custom declarations may rename,
reorder, or specialize them, but cannot remove the shell-owned navigation invariants.

### Seeding domain tab content

A community seeds its domain tabs — Messages, Marketplace, Calendar, Giving — through the
`experience` block. Each tab's data shape is documented in
[Per-Tab Renderer Contracts](./tab-renderer-contracts.md); the JSON fields map directly to the
parser in `part15_evidence_catalog.dart`.

**Messages (`experience.threads`):**

```json
"threads": [
  {
    "threadId": "tt-announcements",
    "subject": "Club announcements",
    "participantPersonaIds": ["camera-organizer", "camera-member"],
    "muted": false,
    "messages": [
      {
        "messageId": "msg-1",
        "senderPersonaId": "camera-organizer",
        "body": "Welcome to the club! Our first photo walk is April 18.",
        "timestamp": "2026-04-01T09:00:00"
      }
    ]
  }
]
```

**Marketplace (`experience.marketplaceListings`):**

```json
"marketplaceListings": [
  {
    "listingId": "ml-lens-50mm",
    "title": "50mm f/1.8 lens",
    "category": "Lenses",
    "condition": "Excellent",
    "availability": "available",
    "description": "Lightweight prime lens for portraits and street photography.",
    "linkedWorkflowId": "gear-loan-request"
  },
  {
    "listingId": "ml-tripod-carbon",
    "title": "Carbon-fiber tripod",
    "category": "Tripods",
    "condition": "Good",
    "availability": "onLoan",
    "currentHolderLabel": "Camera member",
    "queueLength": 2,
    "dueLabel": "Return by Apr 25",
    "linkedWorkflowId": "gear-loan-request"
  }
]
```

**Calendar (`workflow.calendar` — per-workflow field):**

```json
{
  "workflowId": "photo-walk-rsvp",
  "calendar": {
    "date": "2026-04-18",
    "time": "10:00",
    "location": "Riverside Greenhouse, north entrance",
    "capacityLabel": "18 members going, 6 spots left",
    "host": "Maya Chen, Camera Club coordinator"
  }
}
```

**Giving (`workflow.givingPayment` — per-workflow field):**

```json
{
  "workflowId": "club-dues-payment",
  "givingPayment": {
    "amountLabel": "$15",
    "purpose": "Quarterly club dues",
    "cadence": "recurring",
    "entitlement": "ad-off"
  }
}
```

When these fields are absent, the corresponding domain tab shows a themed placeholder
("‹Tab› is coming to ‹community›") instead of the full domain UI.

## Card Theme Cascade

A community's card surfaces (workflow tiles, their chrome frame, and their buttons) resolve their
visual style from a three-level cascade, each level optional: **community default -> per-tab
override -> per-workflow override**. Declaring only the fields you want to change at any level is
enough — unset fields inherit from the level above, and declaring just a new `accent` at a deeper
level re-derives that level's entire look (border, headings, buttons) from the new accent rather
than mixing old and new colors.

The community-level default is always available for free from `accentColor` alone: it derives a
**neutral card surface with the accent used only for highlights** — borders, headings, badges, and
buttons — rather than filling the whole card in one solid color. This is what keeps a community's
chrome frame (the "in-focus"/"expanded product surface" bar wrapping every tile) and the tile it
wraps visually coherent instead of using two unrelated colors.

### Light ("modern card") opt-in

Declaring an `experience.theme` block at all — even just `{"accent": "#C4703F"}` with no other
fields — opts the whole community into a second, lighter visual mode: a subtle accent-tinted fill
over white with fixed dark ink heading/body text, matching the community-list card's look, instead
of the neutral-dark-with-accent-highlights default a bare `accentColor` produces. Every secondary
chip, badge, panel, avatar, persona status strip, interaction-summary panel, and workflow action
surface body background resolves from the same cascade — declaring the theme block once re-themes
them all consistently to an accent tint rather than needing per-widget configuration.

When the theme block is declared, every workflow's action surface body background switches from a
hardcoded dark fill to the same light white+tint treatment, both for rich-spec workflows (e.g.
event RSVP, payment, export) and for generic-list cards used by other workflows. Authors do
not need to configure this per-workflow or per-action-surface — it follows the theme opt-in
automatically.

### Buttons

`primaryButton`/`secondaryButton` are **consumed by every card surface's buttons**, not just
carried as inert style hints: a workflow's primary action (RSVP, confirm, pay) renders as a solid
`primaryButton`-styled pill; its alternate/receive/cancel actions render `secondaryButton`-styled;
a multi-choice response bar (e.g. Going/Maybe/Can't go) styles its first non-destructive choice
`primaryButton`, remaining non-destructive choices `secondaryButton`, and **a choice marked
`isDestructive` always keeps the platform's semantic error color** regardless of the theme, so a
declining/cancelling action stays recognizable across every community.

Every field below is optional in JSON; omitted ones are derived from `accent`:

```json
{
  "experience": {
    "accentColor": "#C4703F",
    "theme": {
      "accent": "#C4703F",
      "fillColor": "#1C2024",
      "fillOpacity": 1.0,
      "borderColor": "#C4703F",
      "borderOpacity": 0.34,
      "borderWidth": 1,
      "headingColor": "#FFFFFF",
      "headingOpacity": 1.0,
      "headingWeight": "w800",
      "bodyColor": "#FFFFFF",
      "bodyOpacity": 0.82,
      "cornerRadius": 16,
      "elevation": 3,
      "shadowOpacity": 0.24,
      "primaryButton": {
        "fillColor": "#C4703F", "fillOpacity": 1.0,
        "foregroundColor": "#FFFFFF", "shape": "pill", "labelWeight": "w700"
      },
      "secondaryButton": {
        "fillColor": "#C4703F", "fillOpacity": 0.12,
        "borderColor": "#C4703F", "borderOpacity": 0.4,
        "foregroundColor": "#C4703F", "shape": "pill", "labelWeight": "w600"
      },
      "tabThemes": {
        "giving": { "accent": "#8A5A34" }
      }
    },
    "workflows": [
      {
        "workflowId": "pay-quarterly-dues",
        "theme": { "accent": "#8A5A34" }
      }
    ]
  }
}
```

- `theme` (community level, sibling of `accentColor`): the community default. `tabThemes` is a map
  keyed by `tabId`; declaring an entry re-themes every card surface in that tab.
- A workflow's own `theme` block is the most specific override, merged on top of its owning tab's
  theme in turn.
- `primaryButton`/`secondaryButton` accept the same `fillColor`/`fillOpacity`/`borderColor`/
  `borderOpacity`/`borderWidth`/`foregroundColor`/`foregroundOpacity`/`shape`
  (`"pill"`|`"rounded"`|`"square"`)/`labelWeight` (`"w400"` through `"w800"`) shape.

See the worked example at
[`docs/Build Plan V2/Skill/examples/verify-tabletop-club/`](../Build%20Plan%20V2/Skill/examples/verify-tabletop-club/README.md),
which gives its Giving tab a deeper accent than the rest of the community, and gives one workflow
its own accent on top of that, to demonstrate all three cascade levels at once.

## API Support

Requires `CommunityAppShellNavigationApi`: `getTabConfiguration`, `updateTabConfiguration`,
`assignSurfaceToTab`, `pinSurface`, `unpinSurface`, `setSurfacePresentationState`,
`persistSurfaceFocusState`, `resolveCommunityTheme`, `updateCommunityTheme`, `validateThemeContrast`,
`resolveTabTheme`, `resolveCardTheme`,
`getMessagesTabState`, `openMessagesTab`, `getPersonaTabConfiguration`,
`updatePersonaTabConfiguration`, `resolvePersonaTabs`, `assignSurfaceToPersonaTab`,
`pinSurfaceForPersona`, `unpinSurfaceForPersona`, `getCustomizationKnobs`,
`updateCustomizationKnobs`, `previewNavigationConfiguration`, `validatePersonaNavigation`,
`getPersonaSurfacePresentationState`, `updatePersonaSurfacePresentationState`,
`resolveTabRendererContract` and `recordTabRendererEvidence`.
