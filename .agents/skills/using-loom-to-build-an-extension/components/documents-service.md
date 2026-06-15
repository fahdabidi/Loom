# Documents Service

Use `CommunityDocumentsApi` for community document libraries, handbooks, forms, and exportable records.

## Extension Use

- Request `documents.write` for authoring surfaces.
- Use restricted visibility only when the member has a Loom policy grant.
- Let export and search consume the document contract rather than reading document storage.

## Validation

- `vt_documents_permissions` proves restricted visibility behavior.
- `ct_documents__export_include-documents` proves export includes visible documents.
- `ct_documents__search_index-visible-documents` remains pending until A4b.
