# HOA Headline Flow

Use this workflow when building an HOA extension that needs dues, documents, amenity reservation,
architectural review, committee decision, export, and local Demo App validation.

## Process

1. Create an HOA community package with shell-rendered card branding.
2. Declare permissions for payments, documents, facilities, case/task review, workflow transition,
   notifications, and export.
3. Record dues before operational actions that depend on financial standing.
4. Upload governing documents with the least-visible document level that still supports members.
5. Reserve the facility and record the reservation payment.
6. Open an architectural request as a case, transition the committee workflow, resolve the case, and
   notify the owner.
7. Assemble an export bundle and verify document plus operational component coverage.
8. Validate in the Demo Loom Communities App with Local Backend.

## Covering Test

- `wf_hoa-headline`

## Gotchas

- Export currently proves component coverage and document IDs; record-level case/payment/reservation
  IDs should be added in B8.
- Architectural request attachments are represented through documents for now; a richer attachment
  schema belongs in the visual HOA portal backlog.
