# Member Meetup Scheduling Surface

## Supported Interactions

- Propose one-to-one or small-group meetups, suggest slots, counter-propose, accept, decline, cancel,
  reschedule, set privacy/visibility, send reminders, and display participant state.
- Useful for tennis matches, chess games, study sessions, mentoring, photo walks, and pickup games.

## Personas and Permissions

| Persona | Permissions | Can do |
| --- | --- | --- |
| Member | `community.surface.meetup.write` | Propose, accept, decline, counter, cancel, reschedule. |
| Organizer | `community.surface.meetup.admin` | Moderate availability rules and visibility defaults. |
| Viewer | `community.surface.meetup.read` | View public/shared meetup status. |

## Custom Experience Guidance

Customize participant roles, slot duration, venue/court/room, skill level, match type, privacy,
availability windows, and scoring handoff. A tennis club can configure "Challenge Alex to singles" with
court preference, time options, ladder implications, and response state.

## API Support

Requires `CommunityMeetupApi`: `proposeMeetup`, `suggestSlots`, `counterPropose`, `acceptMeetup`,
`declineMeetup`, `cancelMeetup`, `rescheduleMeetup`, `listParticipants`, `setVisibility`,
`sendReminder`.
