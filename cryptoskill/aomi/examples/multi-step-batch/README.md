# Multi-Step Batch — Uniswap V3 Swap

End-to-end example: swap 1 USDC for WETH on Uniswap V3 via SwapRouter02. Demonstrates the canonical approve+swap pattern with batch simulation. This is the most common multi-step shape in DeFi.

## Prerequisites

```bash
npm install -g @aomi-labs/client
aomi --version    # expects 0.1.30+
```

The user holds USDC on Ethereum mainnet and wants to swap a small amount for WETH. No provider credentials needed for the AA path.

## Step 1: Send the intent

```bash
aomi chat "swap 1 USDC for WETH on Uniswap V3, send to my wallet" \
  --public-key 0xUserAddress \
  --chain 1 \
  --new-session
```

That's enough. The agent picks `SwapRouter02 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45`, fee tier 500 (0.05%), recipient = the user's wallet, and stages approve+swap as a batch. Internal trace (visible with `--verbose`):

```
activate_skills        → uniswap
read    USDC.balanceOf / USDC.allowance to SwapRouter02
stage   "Approve Uniswap Router to spend USDC"
        approve(0x68b3...Fc45, MAX) on USDC
stage   "USDC to WETH swap"
        exactInputSingle((USDC, WETH, 500, <user>, 1_000_000, 0, 0))
simulate_batch         → Batch success: true
                         (no drain-vector annotations)
```

What the user sees:

```
I've staged your USDC → WETH swap on Uniswap V3 (0.05% fee tier).

Transaction Batch:
  1. Approve Uniswap Router to spend USDC
  2. Swap 1 USDC → WETH on V3 0.05% pool, recipient = your wallet

Run `aomi tx simulate tx-1 tx-2` to dry-run, then `aomi tx sign tx-1 tx-2` to send.

⚡ Wallet request queued: tx-1
   to:    0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
   value: 0
   chain: 1
⚡ Wallet request queued: tx-2
   to:    0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45
   value: 0
   chain: 1
```

## Step 2: Confirm what's pending

```bash
aomi tx list
```

```
pending:
  tx-1  to 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 (USDC)
        label: Approve Uniswap Router to spend USDC
  tx-2  to 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45 (Uniswap SwapRouter02)
        label: Swap 1 USDC for WETH on Uniswap V3 (0.05% pool)
```

## Step 3: Simulate as a batch

**This is mandatory for multi-step flows.** The simulator runs each tx sequentially on a forked chain — the swap step sees the approve's state changes. Submitting them independently would revert step 2 with `transfer amount exceeds allowance`.

```bash
aomi tx simulate tx-1 tx-2
```

```
Simulation result:
  Batch success: true
  Stateful: true
  Total gas: 197194

  Step 1 — Approve Uniswap Router to spend USDC
    success: true
    gas_used: 55798

  Step 2 — Swap 1 USDC for WETH on Uniswap V3
    success: true
    gas_used: 141396
```

If `Batch success: false`, do not proceed. Read the revert reason for the failing step. Common causes:
- `expired quote` — re-chat for a fresh quote (deadline-bearing routes)
- `transfer amount exceeds allowance` — agent will retry as a fresh approve+swap; sign the new pair
- `STF` (Uniswap "Slippage tolerance failure") — price moved beyond tolerance; reduce size or accept higher slippage

## Step 4: Sign

```bash
aomi tx sign tx-1 tx-2
```

```
Exec:    aa (alchemy, 7702)
✅ Sent! Hash: 0x...      (single hash for the atomic batch)
```

**One hash for the AA 7702 atomic batch** — both `tx-1` and `tx-2` show the same hash in `aomi tx list` after signing. Not a bug — the 7702 path bundles them as one transaction.

If the user passed `--eoa` (or the AA path falls through), each tx carries a separate `txHashes: [hash1, hash2]` array — same operation, two on-chain transactions.

## Step 5: Verify

```bash
aomi tx list                         # signed entries with hash
aomi chat "show my WETH balance"     # confirm balance change
```

## Notes

- **The drain vector is `recipient` (word3 of `exactInputSingle`).** The agent blocks `recipient != msg.sender` at simulation time. If the user types *"swap and send the WETH to 0xdEaD"*, the batch fails simulation with a drain-vector annotation. Surface the block, do not bypass.
- **Other DEX apps with the same shape.** `sushiswap` (V2 `swapExactTokensForTokens`, recipient at word3), `oneinch` (v6 `swap` with `dstReceiver` inside a tuple), `curve` (`exchange` — no recipient param, refunds msg.sender directly).
- **Multi-hop paths.** If the user names a path (USDC→DAI→WETH), the agent picks `swapExactTokensForTokens` on the V2 router or routes via 1inch. Let it choose unless overridden with `--app uniswap`.
- **1inch unoswap fallback.** If the agent stages `oneinch unoswap` directly, simulation may revert because `unoswap` requires a `dex` parameter encoded by the 1inch off-chain API. The agent will explain the gap and offer to fall back to Uniswap or Sushiswap directly. Agree to the fallback (*"yes, use Uniswap"*) and the agent rebuilds the batch — don't insist on 1inch unless the user has a separate API key configured.

## Complete Script

```bash
#!/usr/bin/env bash
set -euo pipefail

USER_ADDR="0xUserAddress"

# 1. Stage approve + swap as a batch
aomi chat "swap 1 USDC for WETH on Uniswap V3, send to my wallet" \
  --public-key "$USER_ADDR" \
  --chain 1 \
  --new-session

# 2. Confirm pending
aomi tx list

# 3. Simulate (mandatory for multi-step)
aomi tx simulate tx-1 tx-2

# 4. Sign as a batch — one hash on the AA 7702 atomic-batch path
aomi tx sign tx-1 tx-2

# 5. Verify
aomi chat "show my WETH balance"
```

## Lending — same shape

The Aave V3 supply flow is structurally identical: approve the Pool, then `supply()`. One nuance: the agent often tries a single-tx supply first, gets `transfer amount exceeds allowance`, and rebuilds as approve+supply automatically. `aomi tx list` shows three entries — sign the working pair (`tx-2 tx-3`), ignore the orphan `tx-1`. Match against the `batch_status` line: only sign txs marked `Batch [...] passed`.
