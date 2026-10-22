# Session state and recovery

`AOMI_STATE_DIR` defaults to `~/.aomi`. Local sessions retain backend origin,
thread ID, wallet context and authentication. State can contain private keys,
Solana keypairs, guest/account bearers and secret handles. Inspect only the
specific public metadata needed; keep complete state dumps out of logs or chat.

Use `aomi session list` and resume the original local session for an existing
payment. Keep its full Commit ID, approved intent and known transaction hash in
the payment record. `aomi tx list --json` refreshes backend Commit state; it is
not an offline queue listing. Local filesystem state alone cannot prove settlement.

After interruption, query the same Commit and reconcile its existing hash or
wallet attempt before signing again. `tx status` is read-only on chain. Its
direct ERC-20 proof requires chain-matching RPC access and historical recipient
balances. Missing history leaves verification pending for manual reconciliation.
Start a new chat session only for a genuinely new task, not to clear an ambiguous
payment. Refer to [workflows.md](workflows.md#reconciliation) for evidence stages.
