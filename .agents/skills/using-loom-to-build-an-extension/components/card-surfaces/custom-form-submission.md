# Custom Form Submission Surface

## Supported Interactions

- Load form, validate draft, save draft, submit, update submission, withdraw, route protected fields,
  review submission, and export submission.

## Personas and Permissions

| Persona | Permissions | Can do |
| --- | --- | --- |
| Submitter | `community.surface.form.write` | Draft, validate, submit, edit/withdraw own submission. |
| Reviewer | `community.surface.form.review` | Review, request changes, approve/reject where configured. |
| Protected reviewer | `community.surface.form.protected.read` | Read protected fields where policy allows. |

## Custom Experience Guidance

Use only when no richer surface fits. Customize field groups, validation, privacy classes, review route,
result state, and export mapping. Avoid using this as a generic replacement for event, payment,
volunteer, or approval surfaces.

## API Support

Requires `CommunityFormSurfaceApi`: `loadForm`, `validateDraft`, `saveDraft`, `submitForm`,
`updateSubmission`, `withdrawSubmission`, `routeProtectedFields`, `reviewSubmission`,
`exportSubmission`.
