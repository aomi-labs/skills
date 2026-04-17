# Send ETH

This example shows how to use Aomi to send ETH to a recipient on Ethereum.

## When to use this example

Use this flow when the user wants to:

- send ETH to a wallet address
- send ETH to an ENS name
- review a payment before signing
- verify the chain and destination before broadcast

## Prerequisites

- A funded wallet
- A valid recipient address or ENS name
- The intended chain
- Access to the Aomi CLI

## Flow

1. Ask Aomi to prepare the send request.
2. Review the recipient and amount.
3. Confirm the queued transaction.
4. Sign the request.
5. Verify the broadcast.

## Example

```bash
aomi chat "Send 0.1 ETH to vitalik.eth" --new-session --chain 1
```

Check the queued request:

```bash
aomi tx
```

If the request looks right, sign it:

```bash
aomi sign tx-1 --private-key 0xYOUR_PRIVATE_KEY --rpc-url https://eth.llamarpc.com
```

## What good output looks like

- the chain is explicit
- the recipient is resolved or clearly identified
- the amount is unambiguous
- the signer confirms before broadcast

## Notes

- Do not guess the recipient.
- Do not skip confirmation for a value transfer.
- If the wallet is on the wrong chain, stop and restate the chain first.
