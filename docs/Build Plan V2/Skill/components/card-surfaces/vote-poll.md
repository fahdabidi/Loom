# Vote and Poll Surface

## Supported Interactions

- Open/close ballot, cast vote, change vote, clear vote, inspect vote state, view results when allowed,
  resolve tie, publish selected outcome, and audit vote state.

## Personas and Permissions

| Persona | Permissions | Can do |
| --- | --- | --- |
| Eligible voter | `community.surface.vote.cast` | Cast/change/clear vote while ballot is open. |
| Organizer | `community.surface.vote.admin` | Open/close ballot, publish outcome, resolve ties. |
| Viewer | `community.surface.vote.read` | View ballot or results according to policy. |

## Custom Experience Guidance

Customize ballot options, anonymity, one-vote/multi-vote rules, eligibility, deadline, result visibility,
tie-breaker, and next surface. Use for book votes, HOA decisions, committee elections, surveys, and
class choices.

## API Support

Requires `CommunityVoteApi`: `openBallot`, `closeBallot`, `castVote`, `changeVote`, `clearVote`,
`getVoteState`, `getResults`, `resolveTie`, `publishSelection`, `auditVote`.
