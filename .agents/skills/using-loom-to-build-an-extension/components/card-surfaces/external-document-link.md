# External Document Link Surface

## Supported Interactions

- Present links to external documents, PDFs, Google Docs, HTML pages, shared forms, or provider-hosted
  assets with clear source, access, and privacy disclosure.
- Open in embedded Chrome-tab/custom-tab mode, open in external app/browser, copy/share link when
  allowed, refresh preview metadata, and record open/download audit.
- Handle access errors, expired links, unsupported file types, offline state, and permission-restricted
  external documents.

## Personas and Permissions

| Persona | Permissions | Can do |
| --- | --- | --- |
| Member | `community.surface.external-document.open` | Open permitted external docs in embedded or external mode. |
| Document owner | `community.surface.external-document.write` | Add/update link, choose open mode, refresh preview, retire link. |
| Compliance/admin | `community.surface.external-document.admin` | Enforce access policy, audit opens, export link metadata, revoke unsafe links. |

## Custom Experience Guidance

Use this surface when the experience needs to keep an existing Google Doc, PDF, webpage, or external
provider page in the user's workflow. The UI must explain whether the user is leaving Loom, whether an
embedded tab is available, and what access/account may be required. It should always provide a safe
fallback from embedded mode to external app launch.

## API Support

Requires `CommunityExternalDocumentApi`: `registerExternalDocument`, `getExternalDocumentPreview`,
`openEmbeddedExternalDocument`, `launchExternalDocument`, `copyExternalDocumentLink`,
`refreshExternalDocumentMetadata`, `recordExternalDocumentOpen`, `requestExternalDocumentAccess`,
`revokeExternalDocument`, `externalDocumentAuditTrail`.

