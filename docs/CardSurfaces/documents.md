# Documents Surface

## Supported Interactions

- Browse document libraries by category, role, date, version, acknowledgement requirement, and access
  state.
- Open documents in embedded web/Chrome-tab mode, launch an external app/link, download when allowed,
  request access, acknowledge a required document, inspect version history, and view access/audit state.
- Support external documents such as Google Docs, PDFs, HTML pages, shared drives, and externally
  hosted forms without copying private content into Loom unless import policy allows it.

## Personas and Permissions

| Persona | Permissions | Can do |
| --- | --- | --- |
| Member | `community.surface.documents.read` | Browse allowed documents, open embedded/external links, acknowledge, request access. |
| Document owner | `community.surface.documents.write` | Add, update, version, retire, tag, and publish documents. |
| Compliance/admin | `community.surface.documents.admin` | Manage access, retention, acknowledgement policies, export, and audit history. |

## Custom Experience Guidance

Customize document categories, icons, file metadata, open mode, acknowledgement copy, access request
labels, version labels, retention notes, and external provider disclosure. An HOA can organize bylaws,
meeting minutes, architectural forms, and pool rules. A team can organize waivers, schedules, travel
guides, and practice plans.

The document card must show enough context for a real user: title, source, owner/publisher, last
updated date, file type, access state, acknowledgement/read state, and safe open/download actions.

## API Support

Requires `CommunityDocumentSurfaceApi`: `listDocuments`, `getDocumentDetail`, `openEmbeddedDocument`,
`openExternalDocument`, `downloadDocument`, `acknowledgeDocument`, `requestDocumentAccess`,
`listDocumentVersions`, `linkExternalDocument`, `refreshExternalPreview`, `setDocumentPermissions`,
`retireDocument`, `documentAuditTrail`.

