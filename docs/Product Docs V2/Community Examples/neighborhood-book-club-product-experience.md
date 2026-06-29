# Neighborhood Book Club Product Experience

## 1. Community Identity And Promise

| Field | Value |
| --- | --- |
| Community name | Neighborhood Book Club |
| Community type | Reading group |
| Product promise | Help members nominate, vote, discuss, RSVP, and discover reading context without leaving the club space. |
| Brand cues | Book, discussion, calendar, and reading-list cues; editorial but utilitarian tone. |
| What this must not feel like | A list of book workflows with generic completion buttons. |

## 2. Personas, Roles, And Jobs

| Persona | Role/capabilities | Primary jobs-to-be-done | Sensitive constraints | Success state |
| --- | --- | --- | --- | --- |
| Member | Nominate, vote, RSVP, discuss, search/digest | Participate in the reading cycle and know what to read next. | Discussion messages and preferences stay within club context. | Member sees selected book, meeting details, vote/discussion state. |
| Organizer | Publish selection and export metadata | Curate reading cycle and keep data portable. | Export must show scope and checksum. | Selection published and members have clear next step. |

## 3. Information Architecture

| Surface | Purpose | Primary persona | Required content | Primary action |
| --- | --- | --- | --- | --- |
| Book club home | Current book cycle. | Member | current/next book, nominations, vote status, meeting, discussion prompt. | Vote / RSVP / discuss |
| Nomination/detail | Submit or inspect nomination. | Member | title, author, reason, nominator. | Nominate book |
| Vote surface | Pick/read vote state. | Member | candidates, current totals/status, deadline. | Cast vote |
| Discussion | Member conversation. | Member | prompt, latest messages, author. | Send message |

## 4. Home Screen Requirements

The home must make the current reading cycle obvious: what book is being chosen or read, when the group
meets, and how the member participates next.

## 5. Domain-Native Product Surfaces

| Surface | Required visible content | Required states | Natural actions | Anti-patterns |
| --- | --- | --- | --- | --- |
| Nomination | title, author, reason, nominator | draft/submitted/selected | nominate, edit | workflow card only |
| Vote | candidates, deadline, vote status | open/voted/closed | vote, change vote | abstract poll chip |
| Meeting RSVP | date, location, attendance | open/RSVPed/full | RSVP | checklist dialog |
| Discussion | prompt, message body, sender | empty/unread/sent | reply | generic message workflow |

## 6. Workflow-To-Surface Mapping

| Workflow | Persona | Product surface | Required visible proof | Loom APIs/rules/events | Test/evidence IDs |
| --- | --- | --- | --- | --- | --- |
| book-nomination | member | Nomination form/detail | book title/author/reason and submitted state | Publishing/forms/events | B14/B25 |
| book-vote | member | Vote surface | candidates and voted result | Voting/events/audit | B14/B25 |
| book-meeting-rsvp | member | Meeting detail | date/location/attendance | Events/notifications | B14/B25 |
| book-discussion-message | member | Discussion thread | prompt/message/sender | Messaging/events | B14/B25 |
| book-selection-publish | owner | Admin publish | selected book/audience/timing | Publishing/notifications | B14/B25 |
| book-search-ai-digest | member | Search/digest | query/citations/summary | Search/AI/digest | B14/B25 |
| book-export-metadata | owner | Export status | scope/checksum/redaction | Export/documents | B14/B25 |

## 7. Persona And State Matrix

| Workflow | Actor state | Receiver state | Read-only state | Disabled/hidden state | Unauthorized behavior |
| --- | --- | --- | --- | --- | --- |
| selection publish | organizer publishes | member sees selected book | guests read public meeting summary | publish hidden for members | no admin action |
| discussion | member posts | members see thread | organizer can moderate/read | send disabled without text | non-members hidden |

## 8. Content And Seed Data Requirements

Use real book titles/authors, meeting dates/locations, discussion prompts, vote candidates, digest
citations, sender names, and export metadata.

## 9. Visual And Interaction Standard

Use readable book-cycle sections, clear editorial hierarchy, discussion thread affordances, and compact
meeting/vote cards. Avoid generic workflow-card repetition.

## 10. Review And Remediation Log

| Review run | Product-spec gap? | Implementation gap? | Product doc changes | UI changes required | Status |
| --- | --- | --- | --- | --- | --- |
| B25 next pass | no | pending review | Created canonical Book Club product experience. | Judge current screenshots against reading-cycle surfaces. | open |
