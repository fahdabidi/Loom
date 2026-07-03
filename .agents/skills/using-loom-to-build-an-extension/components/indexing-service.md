# Indexing Service

Use `CommunityIndexingApi` to project searchable records from owning components into the search index.

## Extension Use

- Index only display-safe fields exposed by the owning component contract.
- Use `visibility` values that search can enforce through Loom policy.
- Remove records when the source component deletes or withdraws visibility.

## Validation

- `vt_search_deindex` proves index removal.
- `ct_publishing__search_index-visible-content` and `ct_documents__search_index-visible-documents`
  prove source components can project visible content.
