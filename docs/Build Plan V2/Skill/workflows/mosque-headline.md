# Mosque Headline Flow

Use this workflow when building a mosque extension that needs announcements, events, volunteer signup,
donations, donor visibility, protected care requests, notifications, and local Demo App validation.

## Process

1. Create a mosque community package with shell-rendered card branding.
2. Declare permissions for publishing, events, forms, donations, protected care data, notifications,
   search/AI citation, and local install.
3. Publish public announcements and index only the public announcement text.
4. Create events and collect RSVPs with immediate confirmation.
5. Use forms for volunteer signup, marking contact fields as sensitive.
6. Store donor visibility before recording a donation.
7. Route care-request details through the protected vault, not public posts or searchable content.
8. Send neutral confirmation notifications that do not expose sensitive details.
9. Validate in the Demo Loom Communities App with Local Backend.

## Covering Test

- `wf_mosque-headline`

## Gotchas

- B5 models donor visibility as a core vault preference so the local flow can validate privacy without
  adding hosted donation API fields prematurely.
- Public prayer walls are intentionally not part of B5; care requests are private by default.
- Search/AI citations must come from public announcements only.
