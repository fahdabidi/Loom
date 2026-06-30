# Book Nomination Surface

## Supported Interactions

- Create, edit, withdraw, list nominations, check duplicate titles, check eligibility, link nomination
  to ballot, show nomination status, and hand off to vote/meeting surfaces.

## Personas and Permissions

| Persona | Permissions | Can do |
| --- | --- | --- |
| Member | `community.surface.nomination.write` | Nominate, edit, withdraw own nomination. |
| Organizer | `community.surface.nomination.review` | Review eligibility and ballot readiness. |
| Viewer | `community.surface.nomination.read` | Read accepted nominations and rationale. |

## Custom Experience Guidance

Customize nomination object, required fields, rationale prompts, duplicate policy, voting cycle,
visibility, and selected-outcome handoff. Non-book communities can reuse this for speaker nominations,
award nominations, or project proposals.

## API Support

Requires `CommunityNominationApi`: `createNomination`, `updateNomination`, `withdrawNomination`,
`listNominations`, `detectDuplicate`, `checkEligibility`, `linkToBallot`, `nominationStatus`.
