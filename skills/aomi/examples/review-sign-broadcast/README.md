# Review, Sign, Broadcast

This example shows the safe end-to-end flow for signing a queued Aomi request.

## When to use this example

Use this flow when the user wants to:

- inspect a queued request
- confirm the exact action before signing
- simulate a multi-step batch
- finalize and broadcast a wallet request

## Prerequisites

- A queued request in the current session
- The correct signer address
- The correct RPC endpoint for the chain
- A confirmation from the user that the action should proceed

## Flow

1. Inspect the queue.
2. Read the request in plain language.
3. Simulate if the flow depends on prior state.
4. Confirm the user still wants to proceed.
5. Sign the request.
6. Verify the result.

## Example

```bash
aomi chat "Approve and swap 100 USDC for ETH" --new-session --chain 1
```

Inspect the queue:

```bash
aomi tx
```

Simulate the state-dependent batch:

```bash
aomi simulate tx-1 tx-2
```

Sign after the simulation succeeds:

```bash
aomi sign tx-1 tx-2 --private-key 0xYOUR_PRIVATE_KEY --rpc-url https://eth.llamarpc.com
```

## What good output looks like

- the transaction IDs are visible
- the user can tell what each step does
- the simulation result is clear
- the signer waits for confirmation before broadcasting

## Notes

- Never sign blind.
- Never broadcast a state-dependent flow without simulation if there is a prior approval or dependent step.
- If the route changes, rebuild the request before signing.
