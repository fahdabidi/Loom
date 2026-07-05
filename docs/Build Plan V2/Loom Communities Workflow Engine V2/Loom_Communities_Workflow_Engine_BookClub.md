# Neighborhood Book Club — Tabs, Cards, Actions (workflow-engine target design)

Source: `docs/Product Docs V2/Community Examples/neighborhood-book-club-product-experience.md`.
Anti-pattern to avoid: "a list of book workflows with generic completion buttons."

## Personas
| Persona        | Role                                               | Key constraint                                                                      |
| -------------- | -------------------------------------------------- | ----------------------------------------------------------------------------------- |
| Member         | actor on nominate/vote/RSVP/discuss/browse-library | non-members see public reading list/meeting summary only, cannot vote/nominate/post |
| Organizer/Host | actor on publish-selection/export                  | non-owners cannot publish or export                                                 |

## Tabs → Cards → Archetype → Actions

### Home (both) — `dashboard`
Pinned: current selection, open ballot, next meeting.

### Books (both) — `formEntry` + `votePoll` + `notificationInbox`
- **Nomination form** (`formEntry`, `role: actor`): typed fields title/author/reason/cover-image.
  States: draft / submitted / selected. Actions: nominate, edit, withdraw. (Previously mislabeled a
  "lightweight singleItem form" — it's genuine multi-field data entry, i.e. `formEntry` #14.)
- **Ballot card** (`votePoll`): candidates = current nominations, deadline, live aggregate
  totals/status. Actions: cast, change, clear vote. States: open / closed, with a winning/tie state
  once closed.
- **Selection publish card** (`notificationInbox`, organizer composer / member receiver): draft →
  preview → schedule/publish → sent/read, announcing the winning book club-wide.

### Calendar (both) — `calendarAgenda`
- **Meeting card**: title, date/time, location-or-virtual-link, recurrence, reminder. Actions: RSVP
  going/maybe/not-going, change/cancel; attendance visible to organizer.

### Library ("shared library" tab; both) — `stateMachineGrid`
- **Lending item card**: book/DVD/audiobook/game, owner/current-holder, due date, queue position,
  condition, loan-vs-giveaway mode. States: available / queued / borrowed / overdue / given /
  returned / lost. Actions: browse/search/filter, list item, request loan, join/leave waitlist, claim
  giveaway, return, edit/delist own listing, report lost, renew/extend. Explicitly the richest
  `stateMachineGrid` instance across all 7 communities — direct match to the `MarketplaceTabSurface`
  renderer contract (browse/search/filter + responsive 2/3-up grid + persona-gated engine-derived
  actions + custody history).

### Discussions (both) — `discussionThread`
- **Discussion thread card**: prompt, message body, sender, tied contextually to the current book.
  Actions: reply, edit, delete, moderate/mute/archive (organizer). Read/unread badges.

### Documents (both) — `documentLibrary`
- **Reading material card**: guides/author links/excerpts, tied to the current reading cycle. Actions:
  open embedded, open external, download.

### Search (both) — `searchAiAnswer`
- Same query/answer/citations pattern as Mosque, here framed as a "knowledge" surface over book
  discussion history and reading guides.

## Community-specific customizations (per archetype, per persona)

| Archetype                       | Community customization (theme/fields/states/copy)                           | Member needs                                        | Host/Organizer needs                                   |
| ------------------------------- | ---------------------------------------------------------------------------- | --------------------------------------------------- | ------------------------------------------------------ |
| `formEntry` (nominate)          | Book-forward: fields title/author/reason/cover-image; editorial tone         | nominate, edit, withdraw own                        | — (host curates, members nominate)                     |
| `votePoll`                      | Candidates = nominations; deadline countdown; winning/tie state; live totals | cast/change/clear vote                              | see live aggregate, close ballot, break ties           |
| `calendarAgenda`                | Meeting = physical OR virtual link; reading-cycle context                    | RSVP, get link/reminder                             | schedule meeting, see attendance                       |
| `stateMachineGrid` (library)    | Cover-art item template; formats book/DVD/audiobook/game; queue+custody      | browse/search, borrow, join waitlist, claim, return | list/delist own items, see custody history             |
| `documentLibrary`               | Tied to current reading cycle; guides/excerpts                               | open embedded/external, download                    | curate reading materials                               |
| `discussionThread`              | Per-book discussion prompts; thread affordances                              | reply/edit/delete own, read/unread                  | moderate/mute/archive                                  |
| `notificationInbox` (selection) | Announces winning book club-wide                                             | receive selection announcement                      | compose/schedule selection publish                     |
| `searchAiAnswer`                | Over discussion history + reading guides                                     | ask, refine                                         | see all sources                                        |
| `exportWizard`                  | Schema = book records; scope/checksum                                        | read-only export view                               | run export, transfer, rollback                         |
| `dashboard` (Home)              | Book-forward typography, cover art, reading-progress/vote-state              | pins: current selection, open ballot, next meeting  | pins: nomination queue, ballot results, publish action |

## Cross-cutting notes
- Book Club is the clearest evidence `votePoll` needs its own archetype — a nomination list plus a
  ballot with live results plus a distinct winning/tie state doesn't reduce cleanly to `list` or
  `table` without losing the comparative-standings visualization the source doc explicitly requires.
- The source doc's remediation log flags nomination/vote/RSVP/discussion/selection-publish as having
  had real implementation gaps ("in progress") — same pattern as Mosque: this already went wrong once
  under the narrower archetype set.
