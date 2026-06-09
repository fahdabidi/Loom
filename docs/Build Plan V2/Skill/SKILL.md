---
name: using-loom-to-build-an-extension
description: Build, validate, certify, and maintain Loom Communities extensions using the reference Loom source, APIs, component guides, workflow guides, examples, and validator feedback.
---

# Using Loom To Build An Extension

Use this Skill when an owner, builder, or agent needs to create or modify a Loom Communities extension.
The Skill is provider-neutral: it can be followed by any LLM or developer tool that can read the Loom
source tree, API contracts, architecture docs, and validation output.

## Operating Rules

1. Loom owns identity, membership, roles, consent, payments, protected data, ads, receipts, audit,
   certification, and export.
2. The extension owns experience, domain UI, schema declarations, rules, workflows, jobs, and optional
   sandboxed functions.
3. Use fixed Loom APIs. Do not invent backend storage or bypass App Shell, wallet, vault, ad, or audit
   invariants.
4. Declare the minimum permissions and surfaces needed.
5. Write fixtures and tests before certification.
6. Keep custom data exportable.
7. Preserve the required shell structure: top ad banner, Messages, Connections, Loom payment surface,
   and ad-off behavior.

## Primary Walkthrough

Start with [using-loom-to-build-an-extension.md](./using-loom-to-build-an-extension.md).

## Phase-Enriched Guides

- Component guides live under [components](./components).
- Workflow guides live under [workflows](./workflows).
- Worked examples live under [examples](./examples).

This skeleton is created in Phase 0. Every later phase must enrich it before that phase can complete.
