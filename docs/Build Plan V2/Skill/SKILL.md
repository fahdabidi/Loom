---
name: using-loom-to-build-an-extension
description: Build, validate, locally download, sideload, certify, and maintain Loom Communities extensions using the reference Loom source, APIs, component guides, workflow guides, examples, and validator feedback.
---

# Using Loom To Build An Extension

Use this Skill when an owner, builder, or agent needs to create or modify a Loom Communities extension.
The Skill is provider-neutral: it can be followed by any LLM or developer tool that can read the Loom
source tree, API contracts, architecture docs, and validation output.

The first supported execution targets are Codex and Claude Code running locally over the Loom source
tree. Online-only chat surfaces are deferred until Loom has a hosted build and validation backend.

## Operating Rules

1. Loom owns identity, membership, roles, consent, payments, protected data, ads, receipts, audit,
   certification, and export.
2. The extension owns experience, domain UI, schema declarations, rules, workflows, jobs, and optional
   sandboxed functions.
3. Use fixed Loom APIs. Do not invent backend storage or bypass App Shell, wallet, vault, ad, or audit
   invariants.
4. Declare the minimum permissions and surfaces needed.
5. Write fixtures and tests before local sideload or certification.
6. Keep custom data exportable.
7. In local mode, produce both a downloadable extension package and a downloadable initialization
   package for the fake backend.
8. Preserve the required shell structure: top ad banner, Messages, Connections, Loom payment surface,
   and ad-off behavior.
9. Keep prompt fixtures, golden outputs, and validator failure transcripts current so the Skill itself
   can be debugged.
10. Run system prereq setup before validation; do not claim an extension is validated unless
    `Skill/setup/validation-environment.lock.json` is current and the Demo App smoke check passes.
11. Bundle local icons/images for local-demo, declare their hashes/metadata, and preserve App
    Shell-owned community-card rendering and fallback priority.

## Delivery Modes

- `local-demo`: create a downloadable extension package and initialization package for the Demo Loom
  Communities App with the Local Backend.
- `real-backend-publish`: create the package and backend initialization payloads required for a real
  Loom Communities backend publish flow.

All workflow validation uses the Demo App with the Local Backend. Real-backend publish behavior is
proved through local stubs/contracts before any external backend is used.

## System Prereq Setup

Before generating or validating packages, read [setup/system-prereqs.md](./setup/system-prereqs.md)
and [setup/prereq-manifest.json](./setup/prereq-manifest.json). The Skill must detect whether it is
running under Codex or Claude Code, prepare the required validation tools, and write
[setup/validation-environment.lock.json](./setup/validation-environment.lock.json).

## Primary Walkthrough

Start with [using-loom-to-build-an-extension.md](./using-loom-to-build-an-extension.md).

## Phase-Enriched Guides

- Component guides live under [components](./components).
- Workflow guides live under [workflows](./workflows).
- Worked examples live under [examples](./examples).
- Setup guides live under [setup](./setup).

This skeleton is created in Phase 0. Every later phase must enrich it before that phase can complete.
