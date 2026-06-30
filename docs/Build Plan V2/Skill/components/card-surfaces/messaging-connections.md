# Messaging and Connections Surface

## Supported Interactions

- Send/accept/decline/cancel invite, block/unblock, mute/archive, inspect connection status, create
  thread, reply, and mark read.

## Personas and Permissions

| Persona | Permissions | Can do |
| --- | --- | --- |
| Member | `community.surface.social.write` | Invite, accept, decline, block, reply, mark read. |
| Moderator | `community.surface.social.moderate` | Review abuse reports, enforce blocks. |
| Viewer | `community.surface.social.read` | Read allowed connection/message state. |

## Custom Experience Guidance

Customize invite copy, connection context, thread names, block/mute labels, unread presentation, and
privacy states. Shell Messages and Connections must remain reachable even when a custom shortcut exists.

## API Support

Requires `CommunitySocialSurfaceApi`: `sendInvite`, `acceptInvite`, `declineInvite`, `cancelInvite`,
`block`, `unblock`, `mute`, `archive`, `connectionStatus`, `createThread`, `reply`, `markRead`.
