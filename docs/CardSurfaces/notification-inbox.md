# Notification Inbox Surface

## Supported Interactions

- List inbox items, mark read/unread, archive, mute source, open source object, inspect delivery status,
  manage notification preferences, and retry failed delivery where allowed.

## Personas and Permissions

| Persona | Permissions | Can do |
| --- | --- | --- |
| Member | `community.surface.inbox.read` | Read, mark, archive, open source, adjust preferences. |
| Admin/sender | `community.surface.inbox.delivery.read` | Inspect aggregate delivery status. |
| System job | `community.surface.inbox.retry` | Retry delivery and emit audit events. |

## Custom Experience Guidance

Customize inbox grouping, notification type labels, source deep links, read-state visuals, and channel
preference copy. Keep notification content neutral when sensitive care/protected data is involved.

## API Support

Requires `CommunityInboxSurfaceApi`: `listInboxItems`, `markRead`, `markUnread`, `archiveItem`,
`muteSource`, `openSource`, `deliveryStatus`, `notificationPreferences`, `retryDelivery`.
