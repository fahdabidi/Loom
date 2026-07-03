# Data Schema Store

Use `CommunityDataSchemaApi` to register extension-owned schemas and export/index policies.

## Extension Use

- Mark only safe fields as indexable.
- Mark schemas exportable when they must appear in portability bundles.
- Keep schema registration separate from seeded data.

## Validation

- `vt_data-schema_register` and `vt_data-schema_export-index` prove schema registration and export/index metadata.
- `ct_data-schema-store__import-export_schema-enumeration` proves export enumeration.
