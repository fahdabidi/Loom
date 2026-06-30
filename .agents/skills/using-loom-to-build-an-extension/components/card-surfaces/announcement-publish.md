# Announcement and Publish Surface

## Supported Interactions

- Create draft, edit before publish, preview, choose audience, choose channel, schedule, publish,
  cancel scheduled send, edit published copy, unpublish, inspect delivery status, read receipts, and
  revision history.
- Receiver/member reads announcement, marks read, opens source workflow, and sees updated/retracted
  state.

## Personas and Permissions

| Persona | Permissions | Can do |
| --- | --- | --- |
| Owner/admin | `community.surface.announcement.write`, `community.surface.announcement.admin` | Draft, preview, schedule, publish, revise, unpublish. |
| Member | `community.surface.announcement.read` | Read, mark read, open related event/payment/care action. |
| Moderator | `community.surface.announcement.review` | Review flagged announcement and request changes. |

## Custom Experience Guidance

Customize announcement type, sender label, audience segments, channel labels, message template,
required preview fields, hero copy, and follow-up actions. Keep the object concrete: title, body,
author/sender, audience, delivery time, channel, and receiver state must be visible.

Example: Masjid Nur can configure "Ramadan community night" with sender `Masjid Admin`, audience
`All active members`, delivery `Today 6:00 PM`, and next actions for RSVP and volunteer signup.

## API Support

Requires `CommunityAnnouncementApi`: `createDraft`, `updateDraft`, `previewAnnouncement`,
`scheduleAnnouncement`, `publishAnnouncement`, `cancelScheduledAnnouncement`,
`updatePublishedAnnouncement`, `unpublishAnnouncement`, `deliveryStatus`, `readReceipts`,
`revisionHistory`.
