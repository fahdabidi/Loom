# Completion Plan — Discovery Feed 2×3 Grid Toggle

## Context

Feature: add a **2-column grid view** (YouTube-style, ~6 tiles visible) to the Loom Fan App discovery feed,
toggled from the ⋮ menu in the toolbar. The list view is preserved as the default.

Target file: `app/packages/features/fan/feature_discovery/lib/src/discovery_home_screen.dart`

All shell commands must be run via **WSL Ubuntu** (never PowerShell).

---

## What is already done

The following edits have already been applied to `discovery_home_screen.dart`:

1. `_gridView` state bool added to `_DiscoveryHomeScreenState` (after `_showSearchPage`).
2. `_openContent(FeedItem item)` helper method added to `_DiscoveryHomeScreenState`.
3. Both `_DiscoveryToolbar` call-sites pass `gridView: _gridView` and `onToggleLayout: () => setState(() => _gridView = !_gridView)`.
4. Feed section branched: when `_gridView` is true it renders `_DiscoveryFeedGrid(...)`, otherwise the existing `for` loop of `_DiscoveryFeedCard` widgets (unchanged, with all existing keys).
5. `_DiscoveryToolbar` constructor and fields extended with `required this.gridView` and `required this.onToggleLayout`.
6. `_DiscoveryToolbar.build()` was started with a `Theme(visualDensity: compact)` wrapper — **but the edit was interrupted mid-way and the method is currently broken** (see Step 1 below).

---

## What still needs to be done

### Step 1 — Fix `_DiscoveryToolbar.build()` (BROKEN, must fix first)

The `build` method currently has a half-applied `Theme(...)` wrapper. The inner `Row`'s closing and
the `Theme`'s closing are wrong/missing, and the `PopupMenuButton` was never inserted.

**Replace the entire `build` method** of `_DiscoveryToolbar` (from `@override` through the closing `}`)
with the following:

```dart
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(visualDensity: VisualDensity.compact),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Discover',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          Tooltip(
            message: 'Start onboarding',
            child: IconButton.filled(
              key: const ValueKey('start_fan_onboarding_button'),
              onPressed: onStartOnboarding,
              icon: const Icon(Icons.person_add_alt_1_rounded),
            ),
          ),
          Tooltip(
            message: immersive ? 'Dense feed' : 'Immersive feed',
            child: IconButton.filledTonal(
              key: const ValueKey('p14_toggle_immersive_button'),
              onPressed: onToggleImmersive,
              icon: Icon(
                immersive
                    ? Icons.view_agenda_rounded
                    : Icons.smart_display_rounded,
              ),
            ),
          ),
          Tooltip(
            message: 'Creator invite',
            child: IconButton.filledTonal(
              key: const ValueKey('p12_open_capture_link_button'),
              onPressed: onOpenCaptureLink,
              icon: const Icon(Icons.link_rounded),
            ),
          ),
          Tooltip(
            message: 'Wallet',
            child: IconButton(
              key: const ValueKey('p6_open_wallet_button'),
              onPressed: onOpenWallet,
              icon: const Icon(Icons.account_balance_wallet_rounded),
            ),
          ),
          Tooltip(
            message: 'Data rights',
            child: IconButton(
              key: const ValueKey('p7_open_data_rights_button'),
              onPressed: onOpenDataRights,
              icon: const Icon(Icons.verified_user_outlined),
            ),
          ),
          Tooltip(
            message: 'Campaigns',
            child: IconButton(
              key: const ValueKey('p8_open_campaigns_button'),
              onPressed: onOpenCampaigns,
              icon: const Icon(Icons.emoji_events_outlined),
            ),
          ),
          PopupMenuButton<_ToolbarAction>(
            key: const ValueKey('p3_feed_overflow_menu'),
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'More options',
            onSelected: (action) {
              switch (action) {
                case _ToolbarAction.toggleLayout:
                  onToggleLayout();
                case _ToolbarAction.openSettings:
                  onOpenSettings?.call();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _ToolbarAction.toggleLayout,
                child: Row(
                  children: [
                    Icon(gridView
                        ? Icons.view_list_rounded
                        : Icons.grid_view_rounded),
                    const SizedBox(width: 12),
                    Text(gridView ? 'List view' : 'Grid view (2×3)'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _ToolbarAction.openSettings,
                child: const Row(
                  children: [
                    Icon(Icons.tune_rounded),
                    SizedBox(width: 12),
                    Text('AI search settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
```

**Also remove** the now-redundant `AI search settings` standalone `IconButton` from the toolbar
(the `Tooltip(message: 'AI search settings', ...)` block that wraps
`IconButton(key: ValueKey('p22_open_ai_search_settings_button'), ...)`) — it is now
surfaced through the PopupMenu. If keeping the key for integration tests matters, move the
`ValueKey('p22_open_ai_search_settings_button')` onto the `PopupMenuButton` itself, or
leave the IconButton if removing it would break test coverage (agent's call).

---

### Step 2 — Add the `_ToolbarAction` enum

Insert directly above the `_DiscoveryToolbar` class:

```dart
enum _ToolbarAction { toggleLayout, openSettings }
```

---

### Step 3 — Add the `_DiscoveryFeedGrid` widget

Insert directly after the closing `}` of `_DiscoveryFeedCard` (around line 1340 before edits;
search for `class _Poster` and insert just before it).

```dart
class _DiscoveryFeedGrid extends StatelessWidget {
  const _DiscoveryFeedGrid({
    required this.items,
    required this.onWhy,
    required this.onOpen,
    required this.onOpenCreator,
    required this.onFeedback,
    required this.onRecordDiscovery,
  });

  final List<FeedItem> items;
  final void Function(FeedItem) onWhy;
  final void Function(FeedItem) onOpen;
  final void Function(FeedItem) onOpenCreator;
  final void Function(FeedItem, FeedbackAction) onFeedback;
  final void Function(FeedItem) onRecordDiscovery;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.72,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _GridTile(
          key: ValueKey('p3_feed_card_${item.tile.contentId}'),
          item: item,
          onWhy: () => onWhy(item),
          onOpen: () => onOpen(item),
          onOpenCreator: () => onOpenCreator(item),
          onFeedback: (action) => onFeedback(item, action),
          onRecordDiscovery:
              item.providerLabel.startsWith('Recommended by ')
              ? () => onRecordDiscovery(item)
              : null,
        );
      },
    );
  }
}

class _GridTile extends StatelessWidget {
  const _GridTile({
    required this.item,
    required this.onWhy,
    required this.onOpen,
    required this.onOpenCreator,
    required this.onFeedback,
    required this.onRecordDiscovery,
    super.key,
  });

  final FeedItem item;
  final VoidCallback onWhy;
  final VoidCallback onOpen;
  final VoidCallback? onOpenCreator;
  final ValueChanged<FeedbackAction> onFeedback;
  final VoidCallback? onRecordDiscovery;

  @override
  Widget build(BuildContext context) {
    return FeedCard(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster: full-width 16:9 with title overlay (compact:false mode)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: _Poster(item: item, compact: false),
            ),
            // Creator row
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Row(
                children: [
                  InkWell(
                    key: ValueKey(
                      'p4_open_channel_${item.tile.creatorId}_${item.tile.contentId}',
                    ),
                    onTap: onOpenCreator,
                    borderRadius: BorderRadius.circular(999),
                    child: _CreatorAvatar(
                      name: item.tile.creatorName,
                      radius: 10,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      item.tile.creatorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  GestureDetector(
                    key: ValueKey('p3_why_button_${item.tile.contentId}'),
                    onTap: onWhy,
                    child: const Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Single-line action strip
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 4, 6),
              child: Row(
                children: [
                  _ActionChip(
                    icon: item.tile.contentTypeLabel == 'Video'
                        ? Icons.play_arrow_rounded
                        : Icons.article_rounded,
                    label: item.tile.contentTypeLabel == 'Video'
                        ? 'Play'
                        : 'Read',
                  ),
                  const SizedBox(width: 4),
                  if (item.providerLabel != 'Loom native graph')
                    Flexible(
                      child: _ProviderPill(
                        key: ValueKey(
                          'p8_recommendation_disclosure_${item.tile.contentId}',
                        ),
                        label: item.providerLabel,
                      ),
                    )
                  else
                    const Spacer(),
                  _FeedbackIcon(
                    keyValue: 'p3_feedback_like_${item.tile.contentId}',
                    icon: Icons.thumb_up_alt_outlined,
                    label: 'Like',
                    onTap: () => onFeedback(FeedbackAction.like),
                  ),
                  _FeedbackIcon(
                    keyValue: 'p3_feedback_dislike_${item.tile.contentId}',
                    icon: Icons.thumb_down_alt_outlined,
                    label: 'Dislike',
                    onTap: () => onFeedback(FeedbackAction.dislike),
                  ),
                  _FeedbackIcon(
                    keyValue: 'p3_feedback_mute_${item.tile.contentId}',
                    icon: Icons.volume_off_outlined,
                    label: 'Mute creator',
                    onTap: () => onFeedback(FeedbackAction.muteCreator),
                  ),
                  if (onRecordDiscovery != null)
                    Tooltip(
                      message: 'Record discovery receipt',
                      child: IconButton(
                        key: ValueKey(
                          'p8_record_discovery_${item.tile.contentId}',
                        ),
                        onPressed: onRecordDiscovery,
                        constraints:
                            BoxConstraints.tight(const Size.square(28)),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.receipt_long_rounded, size: 16),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### Step 4 — Verify

Run from WSL Ubuntu:

```bash
cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app/packages/features/fan/feature_discovery"
dart analyze lib/src/discovery_home_screen.dart
```

Expected: `No issues found!`

If there are errors, fix them (common: missing imports — all needed types are already imported
at the top of the file; `FeedbackAction` comes from `loom_api_contracts`).

---

## Key constraints to preserve

- **All ValueKeys must be kept exactly as-is** (integration tests rely on them):
  `p3_feed_card_<id>`, `p4_open_channel_<creatorId>_<contentId>`, `p3_why_button_<id>`,
  `p3_feedback_like_<id>`, `p3_feedback_dislike_<id>`, `p3_feedback_mute_<id>`,
  `p8_recommendation_disclosure_<id>`, `p8_record_discovery_<id>`.
- **List view is the default** (`_gridView` starts as `false`).
- **`_DiscoveryFeedCard` is unchanged** — the grid uses its own `_GridTile`, so both views coexist.
- **No new imports needed** — all types (`FeedCard`, `LoomColors`, `FeedItem`, `FeedbackAction`,
  `PopupMenuButton`, etc.) are already in scope.
- **WSL only** — run all commands via `wsl -d Ubuntu -- bash -lc '...'`, never PowerShell.
