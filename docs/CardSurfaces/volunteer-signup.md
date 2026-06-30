# Volunteer Signup Surface

## Supported Interactions

- Show shift, role, time, location, open spots, roster count, who volunteered where allowed, protected
  contact policy, coordinator, signup status, check-in, no-show, edit availability, and cancel signup.

## Personas and Permissions

| Persona | Permissions | Can do |
| --- | --- | --- |
| Member | `community.surface.volunteer.write` | Sign up, edit availability, cancel, check in. |
| Coordinator | `community.surface.volunteer.roster.read`, `community.surface.volunteer.admin` | View roster, reveal protected contact, assign, check in, mark no-show. |
| Viewer | `community.surface.volunteer.read` | See open needs and aggregate volunteer count. |

## Custom Experience Guidance

Customize shift types, volunteer roles, roster visibility, contact-sharing policy, capacity, reminders,
and coordinator handoff. For Masjid iftar, show setup/check-in/meal handoff roles, 4:30-6:30 PM shift,
open spots, and whether phone is protected.

## API Support

Requires `CommunityVolunteerApi`: `createShift`, `updateShift`, `listShifts`, `signup`,
`updateAvailability`, `cancelSignup`, `listVolunteers`, `volunteerSummary`, `protectedContactReveal`,
`assignCoordinator`, `checkIn`, `markNoShow`.
