# App Shell Navigation, Tabs, Pinning, And Theming Surface

## Supported Interactions

- Configure community tabs, assign card surfaces to tabs, pin important surfaces, and expose Home and
  Messages/Communication as default tabs.
- Configure persona-specific tabs, labels, icons, order, visibility, pinned surfaces, and surface
  assignment so a member, admin, coach, board member, guardian, donor, or reviewer can each see the
  navigation model that matches their jobs-to-be-done.
- Support minimized, medium/in-focus, and expanded/maximized presentation states for card surfaces.
- Persist scroll/focus state, make the first card in a tab the in-focus medium card, minimize cards
  that scroll past, and expand a tapped card into a full/detail view.
- Configure community theme tokens for color, imagery, icons, typography roles, and surface-level
  variants while preserving App Shell accessibility and required controls.
- Expose customization knobs for typography roles, card density, tab labels, tab icons, surface
  presentation defaults, pinned state, community-card treatment, and shell-safe color palettes.

## Personas and Permissions

| Persona | Permissions | Can do |
| --- | --- | --- |
| Member | `community.surface.navigation.read` | Use persona-appropriate tabs, pinned surfaces, expansion, messages, and theme-rendered community UI. |
| Owner/admin | `community.surface.navigation.configure` | Configure tab labels, tab order, icons, persona visibility, pinned surfaces, surface grouping, presentation defaults, and theme tokens. |
| Shell/governance | `community.surface.navigation.admin` | Enforce Home/Messages defaults, accessibility, ad/nav invariants, permission-filtered visibility, and safe theme bounds. |

## Custom Experience Guidance

Every community gets Home and Messages/Communication by default. All card surfaces appear on Home
unless assigned to custom tabs. A community can add tabs such as Calendar, Documents, Teams, Giving,
Marketplace, Care, or Admin. Pinned surfaces remain visible at the top of a tab. Theme tokens should be
declared once and applied across the community card, tabs, cards, expanded surfaces, buttons, labels,
edit text, and dialogs.

Tabs are resolved per persona. The same community may expose `Home`, `Calendar`, `Marketplace`, and
`Messages` to a general member, while an admin sees `Home`, `Admin`, `Documents`, `Giving`, and
`Messages`. Unauthorized persona tabs must be hidden or disabled with a reason; they must not leak
restricted workflow content. A surface can appear in multiple persona tabs when the visible state is
different, such as a member seeing read-only request status while a board reviewer sees the decision
queue.

Customization knobs should be declared as a `CommunityAppShellCustomizationSpec`:

- tab labels, tab icons, order, persona visibility, and pinned-surface defaults;
- community-card minimized and medium presentation, including logo, card image, title typography,
  detail typography, accent color, and badges;
- in-community typography roles: community title, section title, card-surface title, body, label,
  button, edit text, badge, metadata, and receipt/audit text;
- surface presentation defaults: minimized, medium/in-focus, expanded, pinned, density, and spacing;
- safe theme palette: primary/accent/background/surface/text/action colors with contrast validation.

## API Support

Requires `CommunityAppShellNavigationApi`: `getTabConfiguration`, `updateTabConfiguration`,
`assignSurfaceToTab`, `pinSurface`, `unpinSurface`, `setSurfacePresentationState`,
`persistSurfaceFocusState`, `resolveCommunityTheme`, `updateCommunityTheme`, `validateThemeContrast`,
`getMessagesTabState`, `openMessagesTab`, `getPersonaTabConfiguration`,
`updatePersonaTabConfiguration`, `resolvePersonaTabs`, `assignSurfaceToPersonaTab`,
`pinSurfaceForPersona`, `unpinSurfaceForPersona`, `getCustomizationKnobs`,
`updateCustomizationKnobs`, `previewNavigationConfiguration`, `validatePersonaNavigation`,
`getPersonaSurfacePresentationState`, and `updatePersonaSurfacePresentationState`.
