# Search and AI Digest Surface

## Supported Interactions

- Search permission-aware records, ask AI question, list/open citations, save/share digest, refresh
  index, check stale citations, and show visibility decisions.

## Personas and Permissions

| Persona | Permissions | Can do |
| --- | --- | --- |
| Member | `community.surface.knowledge.search` | Search and ask questions over allowed content. |
| Admin | `community.surface.knowledge.admin` | Refresh index and inspect visibility decisions. |
| Guest | `community.surface.knowledge.public.read` | Search public records only. |

## Custom Experience Guidance

Customize searchable sources, question templates, citation layout, digest style, public/member/private
visibility, and safety copy. A Masjid question about iftar should cite the public announcement and hide
care/private details.

## API Support

Requires `CommunityKnowledgeSurfaceApi`: `search`, `answerQuestion`, `listCitations`, `openCitation`,
`saveDigest`, `shareDigest`, `refreshIndex`, `staleCitationCheck`, `visibilityDecision`.
