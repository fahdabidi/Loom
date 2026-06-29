# Extension Creation Process

Use this process for arbitrary Loom Communities extensions.

## Modes

| Mode | Output |
| --- | --- |
| `planning-only` | Research, workflow docs, API/rules/events maps, UX docs, tracker, and phase docs. |
| `build-and-validate` | All planning artifacts plus generated source, extension/init packages, local Demo App validation, and completion report. |

## Required Steps

1. **Bootstrap Loom knowledge.** Discover a local Loom checkout or fetch the Loom repo at the pinned
   source version. Load the Skill references and only the matching component/workflow guides needed.
2. **Research the community.** Review several comparable implementations, apps, policies, and community
   examples. If network access is unavailable, ask the user for source examples.
3. **Extract high-level artifacts.** Create `community-research.md` with personas, high-level workflows,
   policy concerns, sensitive data, payments, communication patterns, and UX patterns.
4. **Write the community product experience doc.** Create
   `docs/product/community-product-experience.md` in the extension workspace. This is the local product
   contract for standalone Skill runs. It defines community identity, product promise, personas,
   jobs-to-be-done, home IA, domain-native product surfaces, workflow-to-surface mapping,
   persona/state matrix, required visible content, API/rules/events mapping, visual standard, and UX
   acceptance criteria. Treat fetched Loom Product Docs V2 as read-only reference material.
5. **Write product workflow docs.** Create multiple detailed workflow docs organized by functionality
   area: onboarding/membership, events, content, payments, messaging, admin/moderation, search, export.
6. **Map workflows to implementation.** Create docs that map each workflow step to Loom APIs, backend
   functions/jobs, declarative rules, events, UI surfaces, fake-backend seed data, and tests.
7. **Create UX docs.** Apply the Loom UX methodology: reference sources reviewed, patterns extracted,
   key UX decisions, key implementation decisions, workflow walkthrough, open questions/tradeoffs.
8. **Create an extension build tracker and phases.** Use Loom's phase template, but scope phases to
   the extension. Each phase must define tests, validation, and commit gates.
9. **Stop for owner approval.** Do not generate code or packages until the user approves the research,
   community product experience doc, workflow docs, API maps, UX docs, tracker, and phase docs.
10. **Execute phase by phase.** Write or update tests first, generate code/artifacts, run validation,
   update tracker, and commit before moving on.
11. **Package and validate.** Generate `.loom-extension.zip` and `.loom-init.zip`, run static validators,
    run Demo App local workflow validation, and write `validation-report.json` and
    `validation-report.md`.
12. **Iterate.** Treat owner feedback as a versioned change. Update docs and tests first, rebuild,
    revalidate, and only report completion when every requested workflow is implemented and validated.

## Approval Gate

Before execution, present these artifacts for review:

- `community-research.md`
- `docs/product/community-product-experience.md`
- product workflow docs by functionality area
- workflow API/rules/events mapping docs
- UX research and guidelines docs
- extension `Build Tracker.md`
- extension phase docs and UX Decisions docs

The owner may approve, request changes, or defer build-and-validate.
