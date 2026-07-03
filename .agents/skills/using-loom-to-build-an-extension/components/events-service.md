# Events Service

Use `CommunityEventsApi` for community events, RSVPs, and ticket codes. Events emit typed events for
workflow automation and notifications.

## Extension Use

- Create events with explicit capacity.
- Use RSVP state for attendance and optional ticketing.
- Handle capacity errors instead of overbooking.

## Validation

- `vt_events_rsvp` proves RSVP transitions.
- `vt_events_ticketing` proves ticket codes for accepted RSVPs.
