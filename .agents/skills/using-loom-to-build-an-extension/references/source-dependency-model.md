# Source Dependency Model

The Skill must run in Codex or Claude Code environments that may not already have the Loom source
tree. It must distinguish bundled knowledge from repo-fetched execution dependencies.

## Built Into The Skill

Bundle these because they are small, stable, and needed before a repo checkout exists:

- `SKILL.md`
- extension creation process
- Loom reference implementation methodology
- compact workflow/component indexes
- workflow API mapping template
- UX methodology template
- extension package and initialization package shape summaries
- review-doc templates
- example prompts and small golden examples
- static validation rules for package/report shape

## Fetched From The Loom Repo

Fetch these because they are larger, executable, or fast-changing:

- Demo Loom Communities App
- Local In-App Backend
- App Shell Runtime
- Dart/Flutter validators and tests
- OpenAPI specs
- Product Docs V2 and Architecture V2
- phase gates, manifest gates, and Skill Debug Harness

## Bootstrap Requirements

1. Detect whether the current workspace already contains the Loom repo.
2. If not, fetch the repo from the configured GitHub URL at the pinned commit or tag.
3. Run setup and validation commands from the discovered repo root.
4. Generate a new environment lock for the current machine. Never reuse another user's absolute paths.
5. Use bundled static validators before full repo validation, but do not claim completion without the
   repo-fetched Demo App validation path.
