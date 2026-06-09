# Youth Soccer Headline Workflow

Mode: `local-demo`, validated in the Demo Loom Communities App with Local Backend.

## Purpose

Build a youth sports extension that supports guardian join, team spaces, protected minor data,
registration payment, schedule events, roster-safe views, and practice notifications.

## Required Artifacts

- Guardian/minor registration schema with protected fields.
- Team/roster space definitions.
- Registration payment configuration.
- Schedule event route/card.
- Notification templates.
- Community card branding.

## Implementation Steps

1. Request and approve guardian membership.
2. Create a team space.
3. Store minor data in the protected vault.
4. Record the registration payment.
5. Create the schedule event.
6. Send a practice reminder.
7. Open the local extension through the Demo App shell.

## Validation

Primary workflow test: `wf_youth-soccer-headline`.

The test proves protected minor data is redacted and permission-gated while roster, payment, schedule,
and notification state stay available to the local extension.
