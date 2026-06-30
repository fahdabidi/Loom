# Event RSVP Surface

## Supported Interactions

- Show named event detail: title, date, time, location, host, capacity, attendance status, waitlist,
  reminders, calendar state, and changes.
- RSVP going/maybe/not attending, change response, cancel RSVP, join waitlist, receive reminder, and
  read cancellation/reschedule notices.

## Personas and Permissions

| Persona | Permissions | Can do |
| --- | --- | --- |
| Member | `community.surface.event.rsvp` | RSVP, change/cancel response, join waitlist. |
| Organizer | `community.surface.event.write` | Create, update, cancel, reschedule, message attendees. |
| Viewer | `community.surface.event.read` | Read public/member event detail without changing attendance. |

## Custom Experience Guidance

Use for mosque iftars, book meetings, soccer practices, classes, photo walks, and neighborhood events.
Customize event copy, capacity rules, waitlist language, family/guest counts, location privacy, and
calendar/reminder behavior.

Example: a book club meeting should show selected book, host, discussion prompt, capacity, and "change
response" rather than a generic "Complete RSVP" action.

## API Support

Requires `CommunityEventRsvpApi`: `createEvent`, `updateEvent`, `cancelEvent`, `rescheduleEvent`,
`getEventDetail`, `respondGoingMaybeNo`, `changeRsvp`, `cancelRsvp`, `joinWaitlist`,
`listAttendees`, `deliveryReminders`, `calendarState`.
