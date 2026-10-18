# INFRA — re-authenticate the agent CLIs on the Loom VM (Claude Code and Muse)

**Status:** DONE 2026-10-18 — both logins completed by the user through URLs relayed by the validation
agent, and both verified with a real model call, not just a status read.

## Why

The VM's Claude Code CLI had reported `OAuth session expired and could not be refreshed` since at least
2026-10-10, blocking every dispatch that uses it. Before the login, `claude auth status` showed
`loggedIn: false, authMethod: none` — the credentials were gone, not merely stale. On 2026-10-11 the
network was ruled out as the cause (outbound confirmed working, same error). On 2026-10-18 the user also
directed that the implementation agent move to the Muse CLI, which needed its own login.

## How it was done — reusable

Both CLIs need an interactive terminal, so each login ran inside a detached `tmux` session on the VM,
with `BROWSER=/bin/false` so the headless browser-open failed harmlessly and the URL was printed:

    tmux new-session -d -s claude-login -x 500 -y 60
    tmux send-keys -t claude-login "BROWSER=/bin/false ~/.nvm/versions/node/v22.23.2/bin/claude auth login" Enter
    tmux capture-pane -p -J -t claude-login          # read the authorize URL
    tmux send-keys -t claude-login -l '<code#state>'; tmux send-keys -t claude-login Enter

`claude auth login` is a **paste-back** flow (the page shows a code to paste into the waiting CLI).
`muse login` is a **device-code** flow (approve a code in the browser; the CLI polls and needs nothing
pasted back) — it also waits for Enter before polling, so send one.

## Verified

| CLI | status | real call |
|---|---|---|
| Claude Code 2.1.228 | `loggedIn: true`, `authMethod: claude.ai`, subscription `max` | `claude -p --model sonnet` → `READY`, exit 0 |
| Muse Code 1.4.10 | "Model API access verified." | `muse exec --model muse-spark-1.3 --reasoning-effort medium` → `READY`, exit 0 |

Both binaries resolve on the `~/.loom-env.sh` PATH that the `data/call_*.sh` dispatchers source. Both
tmux sessions were closed afterwards.
