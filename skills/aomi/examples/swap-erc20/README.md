# Swap ERC20

This example shows how to use Aomi to swap one token for another through an EVM router.

## When to use this example

Use this flow when the user wants to:

- swap one token for another
- compare a quote before signing
- review approval requirements
- simulate a state-dependent flow

## Prerequisites

- A wallet with source token balance
- Gas token for the chain
- A target chain
- A known source token and destination token

## Flow

1. Ask Aomi for the swap route.
2. Review the quote, slippage, and recipient.
3. Queue approval if needed.
4. Simulate the batch when approval and swap are linked.
5. Sign the batch.
6. Verify the final balance change.

## Example

```bash
aomi chat "Swap 1 ETH for USDC on Base with tight slippage" --new-session --chain 8453
```

If Aomi queues an approval and swap as separate steps:

```bash
aomi tx
aomi simulate tx-1 tx-2
aomi sign tx-1 tx-2 --private-key 0xYOUR_PRIVATE_KEY --rpc-url https://mainnet.base.org
```

## What good output looks like

- the route names the router or venue
- slippage is visible
- approvals are explicit
- simulation happens before signing
- the final output explains what changed

## Notes

- A swap is not just a single sentence.
- The user should know if a token approval is required.
- If the quote expires, request a fresh one.
