# Book Club Headline Workflow

Mode: `local-demo`, validated in the Demo Loom Communities App with Local Backend.

## Purpose

Build a lightweight book club extension where members nominate books, vote, RSVP to discussion events,
chat in a discussion thread, and receive a permission-aware digest grounded in indexed community
content.

## Required Artifacts

- Form schema for nominations.
- Poll schema for monthly voting.
- Event route/card for the meeting.
- Discussion thread route/card.
- Search/digest configuration scoped to public book club content.
- Community card branding for the installed extension.

## Implementation Steps

1. Create nomination form fields.
2. Create the monthly poll and collect votes.
3. Create the meeting event and RSVP state.
4. Publish the winning selection.
5. Start a discussion thread.
6. Index public selection content.
7. Generate a digest with citation record IDs.
8. Validate that the installed Demo App card opens `local:ext_book_club@latest`.

## Validation

Primary workflow test: `wf_book-club-headline`.

The test uses the local backend plus forms/voting, events, publishing, messaging, search, AI, digest,
and App Shell contracts.
