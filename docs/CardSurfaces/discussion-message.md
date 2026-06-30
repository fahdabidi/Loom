# Discussion and Message Surface

## Supported Interactions

- Create thread, reply, edit/delete own message, mark read, list unread, mute, archive, moderate,
  attach media, mention members, and show sender/audience/member scope.

## Personas and Permissions

| Persona | Permissions | Can do |
| --- | --- | --- |
| Member | `community.surface.thread.write` | Reply, edit own message, mute/archive. |
| Moderator | `community.surface.thread.moderate` | Remove/flag messages and manage thread state. |
| Viewer | `community.surface.thread.read` | Read thread according to role and membership. |

## Custom Experience Guidance

Customize thread type, prompts, reply affordances, member-only/private labels, media support, moderation
policy, and related actions. Book clubs should show prompt, latest sender, message body, unread count,
and reply action.

## API Support

Requires `CommunityThreadApi`: `createThread`, `reply`, `editMessage`, `deleteMessage`, `markRead`,
`listUnread`, `muteThread`, `archiveThread`, `moderateMessage`, `attachMedia`, `mentionMember`.
