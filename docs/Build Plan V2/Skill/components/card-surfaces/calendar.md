# Calendar Surface

## Supported Interactions

- Browse agenda, month/list views, upcoming events, practices, services, deadlines, reservations,
  dues dates, volunteer shifts, and personal commitments.
- Create/update/cancel/reschedule calendar items where the persona has permission.
- Subscribe to calendar feeds, import ICS, export filtered feeds, sync external calendars, inspect
  conflicts, and open a linked event/RSVP or reservation surface.
- Show read-only receiver states such as "added to my calendar", "reminder scheduled", "event moved",
  and "registration closed".

## Personas and Permissions

| Persona | Permissions | Can do |
| --- | --- | --- |
| Member | `community.surface.calendar.read` | Browse calendar, filter by space/team/group, open details, subscribe, add reminders. |
| Organizer | `community.surface.calendar.write` | Create/update/cancel/reschedule items, publish recurring schedules, send reminders. |
| Calendar admin | `community.surface.calendar.admin` | Import/export feeds, resolve conflicts, manage external sync, define visibility defaults. |

## Custom Experience Guidance

Customize calendar views, color coding, event type labels, recurrence rules, time zone handling,
capacity indicators, reminder language, external feed names, and linked surfaces. A soccer community
can show team practices, games, registration deadlines, and payment due dates in tabs by team. A
Masjid can show prayer, classes, Ramadan events, volunteer shifts, and donation deadlines.

Use this surface when users need to discover "what is happening when" across the community. Use
[Event RSVP](./event-rsvp.md) for the event detail/action flow after a calendar item is selected.

## API Support

Requires `CommunityCalendarSurfaceApi`: `listCalendarItems`, `getCalendarItem`, `createCalendarItem`,
`updateCalendarItem`, `cancelCalendarItem`, `rescheduleCalendarItem`, `createRecurringSchedule`,
`subscribeCalendarFeed`, `importIcsFeed`, `exportCalendarFeed`, `syncExternalCalendar`,
`detectCalendarConflicts`, `setReminder`, `openLinkedSurface`.

