# Neighborhood Book Club — Tabs, Cards, Actions (workflow-engine target design)

Source: `docs/Product Docs V2/Community Examples/neighborhood-book-club-product-experience.md`.
Anti-pattern to avoid: "a list of book workflows with generic completion buttons."

## Personas
| Persona | Role | Key constraint |
| --- | --- | --- |
| Member | actor on nominate/vote/RSVP/discuss/browse-library | non-members see public reading list/meeting summary only, cannot vote/nominate/post |
| Organizer/Host | actor on publish-selection/export | non-owners cannot publish or export |

## Tabs → Cards → Archetype → Actions

### Home (both) — `dashboard`
Pinned: current selection, open ballot, next meeting.

### Books (both) — `votePoll` + `notificationInbox`
- **Nomination card** (feeds the ballot, not its own archetype — a lightweight `singleItem` form):
  title/author/reason/nominator. States: draft / submitted / selected. Actions: nominate, edit,
  withdraw.
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

## Cross-cutting notes
- Book Club is the clearest evidence `votePoll` needs its own archetype — a nomination list plus a
  ballot with live results plus a distinct winning/tie state doesn't reduce cleanly to `list` or
  `table` without losing the comparative-standings visualization the source doc explicitly requires.
- The source doc's remediation log flags nomination/vote/RSVP/discussion/selection-publish as having
  had real implementation gaps ("in progress") — same pattern as Mosque: this already went wrong once
  under the narrower archetype set.
