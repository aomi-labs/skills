# Thread Management — Resume, Recover, Cleanup

Aomi threads are split across two stores. Knowing what lives where is the difference between a quick recovery and a confused user. This example walks through the four operations that come up most often: starting fresh, continuing an existing task, recovering from a lost thread pointer, and cleaning up old state.

## Two-tier storage model

**Backend (the aomi server)** holds the durable record:

- Full conversation transcript (user prompts + assistant prose).
- All tool calls + tool outputs the agent made silently.
- System events (BYOK key changes, sponsorship decisions).
- Indexed by a `sessionId` UUID.

`aomi session log`, `aomi session events`, and `aomi session status` hit the backend with the local `sessionId`. If the backend is unreachable or the sessionId is wrong, these silently return empty.

**Local on disk** (`$AOMI_STATE_DIR` if set, else `~/.aomi/`) holds the lookup keys and wallet-flow state:

- `sessionId` and `clientId` (UUIDs the backend uses to find the rest).
- `publicKey`, `chainId`, `baseUrl` (current wallet/chain/backend context).
- `pendingTxs[]` and `signedTxs[]` (full calldata, gas estimates, hashes — mirrored locally so `aomi tx list` works without a network round-trip).
- `secretHandles{}` (handle names only — values are never stored locally).

`aomi tx list`, `aomi tx sign`, and `aomi config current` read local. None of these touch the backend.

## File layout

```
~/.aomi/
├── active-session.txt              # one line, the local thread id (e.g. "43")
├── aa.json                         # AA config cache; usually "{}"
└── sessions/
    ├── session-1.json
    ├── session-2.json
    ├── ...
    ├── session-<N>.json            # one file per local thread
    ├── current.json                # rolling pointer/cache used by the REPL
    └── messages-cli-<unix-ns>.json # per-call message buffers (REPL streaming)
```

Each `session-<N>.json` is the local source of truth for that thread. Inspecting it is safe — it does not contain credential values, only handle names:

```bash
cat ~/.aomi/sessions/session-43.json | jq '{sessionId, chainId, publicKey, pending: (.pendingTxs|length), signed: (.signedTxs|length)}'
```

## Pattern 1: Start fresh

When starting a new task in a new shell, pass `--new-session` on the **first** chat command. This avoids old thread state (pending txs from previous tasks, accumulated message tokens) bleeding in.

```bash
aomi chat "supply 100 USDC on Aave" \
  --public-key 0xUser \
  --chain 1 \
  --new-session
```

Subsequent commands in the same task should **omit** `--new-session` — the agent loses context (e.g. the quote it just gave you) if you start over mid-flow:

```bash
# Same shell, same task — DO NOT pass --new-session here
aomi chat "yes, proceed"
aomi tx list
aomi tx simulate tx-1 tx-2
aomi tx sign tx-1 tx-2
```

## Pattern 2: Resume an existing thread

Useful when `aomi tx list` shows pending txs from a thread that was closed earlier — for example, a deadline-bearing Across bridge that needs signing after a shell rotation.

```bash
aomi session list
```

```
thread-41   topic: "swap 100 USDC for WETH"     pending: 0  signed: 2
thread-42   topic: "stake 1 ETH on Lido"        pending: 0  signed: 1
thread-43   topic: "bridge 50 USDC to Base"     pending: 2  signed: 0
```

Pick the right thread by topic and pending count, then resume:

```bash
aomi session resume 43
aomi tx list
aomi tx sign tx-1 tx-2
```

Selectors accept the backend thread ID, `thread-N`, or just `N`.

## Pattern 3: Recover from "No active session"

The active-session pointer is a single line in `~/.aomi/active-session.txt`. It can be lost between subprocess invocations (observed on 0.1.x; not re-verified on v0.4.2). If `aomi tx list` returns:

```
Error: No active session
```

But you know you just had a successful chat — recover in a single shell call so the pointer survives:

```bash
aomi session list
# ... locate the right thread by topic ...

aomi session resume 43 > /dev/null && aomi tx list
```

The `&&` chaining matters: separate shell invocations may lose the pointer again. Keep the resume and the read in one call.

## Pattern 4: Clean up old threads

After a few weeks of use, `~/.aomi/sessions/` can hold 50–100+ files. Cleanup is safe but check for pending txs first.

```bash
aomi session list
```

For each thread you want to delete, check it has no pending wallet requests:

```bash
aomi session resume <id>
aomi tx list
# If "pending: 0", safe to delete
aomi session delete <id>
```

Deleting a thread with pending txs **orphans them** — the backend may still know about them, but the local CLI loses the calldata and ids needed to sign.

The active pointer can be cleared without touching thread state files:

```bash
aomi session close
# next chat starts fresh; old threads still in ~/.aomi/sessions/
```

`messages-cli-*.json` buffer files are safe to remove manually — they're per-invocation REPL caches, not thread state:

```bash
find ~/.aomi/sessions -name 'messages-cli-*.json' -delete
```

## Pattern 5: Isolate state for testing

`AOMI_STATE_DIR` lets the user point the CLI at a non-default state root. Useful for clean-slate test runs that don't contaminate the user's main `~/.aomi/`:

```bash
AOMI_STATE_DIR=$(mktemp -d) aomi --prompt "what is the price of ETH?" --new-session
```

The skill itself does not set this variable. If the user wants isolation, they configure it in their own shell.

## Inspecting thread state

Useful one-liners when debugging:

```bash
# What thread id is active right now?
cat ~/.aomi/active-session.txt

# Pending tx count across all threads
for f in ~/.aomi/sessions/session-*.json; do
  jq -r '"\(input_filename): pending=\(.pendingTxs|length) signed=\(.signedTxs|length)"' "$f"
done

# Replay a thread's conversation (backend-sourced)
aomi session resume 43 > /dev/null
aomi session log

# Raw backend system events for the active thread
aomi session events
```

## Notes

- **Local and backend can diverge.** If a chat succeeded but `aomi tx list` is empty, the local mirror may be stale — try `aomi session resume <id>` to refresh, or `aomi session log` to confirm the backend received the prompt.
- **`secretHandles{}` are scoped to the thread's `clientId`.** The values are stored on the backend, not locally. `aomi secret clear` removes them from the backend; deleting the thread locally does not.
- **The `--new-session` + `--provider-key` quirk** (observed on 0.1.x; not re-verified on v0.4.2). Registering a BYOK key on the same call as `--new-session` does not register the key for that prompt. Workaround: register first with a no-op prompt, then issue the real prompt as a second call without `--new-session`.

```bash
# Register provider key
aomi --provider-key anthropic:sk-ant-... --new-session --prompt "ack"

# Real prompt — same active thread, key is now registered
aomi chat "swap 1 USDC for WETH on Uniswap"
```

## Complete Recovery Script

```bash
#!/usr/bin/env bash
set -euo pipefail

# Find the right thread by topic
TOPIC="bridge 50 USDC to Base"

THREAD_ID=$(aomi session list \
  | awk -v topic="$TOPIC" '$0 ~ topic {print $1}' \
  | head -1 \
  | sed 's/thread-//')

if [ -z "$THREAD_ID" ]; then
  echo "No thread matching: $TOPIC" >&2
  exit 1
fi

# Resume + list + sign in one shell call (pointer survives)
aomi session resume "$THREAD_ID" > /dev/null && {
  aomi tx list
  echo "---"
  read -p "Sign all pending? [y/N] " yn
  if [ "$yn" = "y" ]; then
    aomi tx sign $(aomi tx list | grep -oE 'tx-[0-9]+' | tr '\n' ' ')
  fi
}
```
