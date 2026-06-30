# Documents, Facilities, and Roster Surface

## Supported Interactions

- List/open/download/acknowledge documents, request access, inspect document versions, reserve/update/
  cancel facilities, resolve conflicts, view roster, update roster member, and inspect roster history.

## Personas and Permissions

| Persona | Permissions | Can do |
| --- | --- | --- |
| Member | `community.surface.operations.read` | Read allowed documents, roster, reservation availability. |
| Owner/admin | `community.surface.operations.admin` | Upload/version docs, manage roster, resolve reservation conflicts. |
| Facility requester | `community.surface.facility.reserve` | Reserve, update, cancel facility booking. |

## Custom Experience Guidance

Customize document categories, facility types, roster fields, conflict rules, acknowledgement labels,
member privacy, and export behavior. Use for HOA documents, soccer rosters, classrooms, courts, rooms,
and community facilities.

## API Support

Requires `CommunityOperationsSurfaceApi`: `listDocuments`, `openDocument`, `downloadDocument`,
`acknowledgeDocument`, `requestAccess`, `documentVersions`, `reserveFacility`, `updateReservation`,
`cancelReservation`, `resolveConflict`, `getRoster`, `updateRosterMember`, `rosterHistory`.
