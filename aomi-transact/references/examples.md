# Flow Examples

Read this when:

- The user asks for a concrete end-to-end example of a DeFi operation.
- You're constructing a new flow and want a template to pattern-match against.

Each example shows the full lifecycle: **chat → list → simulate (if multi-step) → sign → verify**. Substitute apps and chains as appropriate; the structural shape stays the same.

> **Verification status.** Examples 1 (Approve+Swap, SushiSwap mainnet) and 3 (Bridging, Across mainnet→Base) are verified end-to-end against CLI v0.1.30 — the gas figures, addresses, and exec lines are real captured output. Examples 2 (Lending) and 4 (Staking) are still skeletons; the protocol details are placeholders.

## 1. Approve + Swap

The canonical state-dependent multi-step flow: an ERC-20 approval followed by a swap that consumes that allowance. **Always simulate before signing** — the swap will revert if submitted independently.

This example is **verified** against CLI v0.1.30 — SushiSwap on Ethereum mainnet, real captured shape.

```bash
# 1. Build a multi-step request. The agent queues approve + swap.
aomi chat "swap exactly 1 USDC to ETH on SushiSwap on Ethereum mainnet. Include the approve as a separate tx so we can simulate then sign as a batch." \
  --public-key 0xUserAddress --chain 1 --new-session

# 2. Confirm the agent queued two requests
aomi tx list
# expected pending:
#   tx-1  approve to 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 (USDC)
#         label: Approve 1 USDC to SushiSwap Router
#   tx-2  to 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F (SushiSwap V2 Router)
#         label: Swap exactly 1 USDC for ETH on SushiSwap

# 3. Simulate the batch — tx-2 sees tx-1's allowance change
aomi tx simulate tx-1 tx-2
# verified output (gas exact for this batch shape):
#   ✓ 1. Approve 1 USDC to SushiSwap Router       gas: 38,458
#   ✓ 2. Swap exactly 1 USDC for ETH on SushiSwap gas: 128,378
#   Total gas: 166,836

# 4. Sign the batch — AA 7702 default on Ethereum, EOA pays via the delegation
aomi tx sign tx-1 tx-2
# verified output:
#   Exec:    aa (alchemy, 7702)
#   Fee:     0.000017 ETH → 0x9C7a99480c59955a635123EDa064456393e519f5
#   ✅ Sent! Hash: 0x...      (single hash for the atomic batch)
#   Deleg:   0x69007702764179f14F51cdce752f4f775d74E139

# 5. Verify
aomi tx list
# Both tx-1 and tx-2 should now show as Signed with the same hash.
```

Pattern notes:

- The 7702 atomic batch returns **one hash for both txs** — they execute as a single transaction via the delegation contract. Both `tx-1` and `tx-2` show the same hash in `aomi tx list`. This is normal.
- If `aomi tx list` only shows one tx, ask the agent to include the approval explicitly.
- If simulation fails at step 2 with "insufficient allowance", the approve in step 1 may have been built with a smaller amount — re-chat to confirm the agent set the allowance to ≥ swap amount.
- Swap apps you can use here: `oneinch`, `zerox`, `cow` (CoW Protocol uses an off-chain order, may queue a single signature instead of a tx batch). Or, like the verified example above, just ask for SushiSwap by name without specifying `--app` — the agent will pick the right tool.

## 2. Lending — Deposit Into a Vault

Supply collateral or stablecoins into a lending market or vault and start earning yield. Often a two-step flow: approve the asset, then deposit.

```bash
# 1. Identify the right market/vault first (read-only)
aomi chat "what are the highest-yield USDC markets on Morpho on Base?" \
  --app morpho --chain 8453 --new-session

# 2. Build the deposit request
aomi chat "deposit 1000 USDC into <market-or-vault-name> on Morpho" \
  --app morpho --chain 8453 --public-key 0xUserAddress

# 3. Review what was queued
aomi tx list
# expected: tx-1 (approve USDC for the vault), tx-2 (deposit into vault)

# 4. Simulate the batch
aomi tx simulate tx-1 tx-2

# 5. Sign
aomi tx sign tx-1 tx-2

# 6. Verify the position was opened
aomi chat "show my Morpho positions" --app morpho
```

Pattern notes:

- Lending apps available today: `morpho`, `yearn`. Pick whichever the user names; otherwise ask before defaulting.
- Withdrawal flows are usually single-step (no approval) — skip simulation if it's read-only-of-state safe, otherwise simulate as a single-tx batch (`aomi tx simulate tx-1`).

## 3. Bridging — Move Assets Across Chains

Move tokens from one chain to another via a bridge aggregator. Source-chain approval (if ERC-20) plus a bridge call. Settlement on the destination chain happens out-of-band.

This example is **verified** against CLI v0.1.30 — Across mainnet→Base, real captured shape.

```bash
# 1. Build the bridge request (the agent picks Across as the tool)
aomi chat "Bridge exactly 1 USDC from Ethereum mainnet to Base for wallet 0xUserAddress via Across. Include approve as a separate tx so we can simulate." \
  --public-key 0xUserAddress --chain 1 --new-session

# 2. Inspect what was queued
aomi tx list
# expected pending:
#   tx-1  approve to 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 (USDC)
#   tx-2  to 0x5c7BCd6E7De5423a257D81B442095A1a6ced35C5 (Across SpokePool)
# If multiple "bridge" txs appear, the agent retried with fresh deadlines.
# Match metadata: only sign the pair tagged "Batch [N,M] passed".

# 3. Simulate the chosen pair
aomi tx simulate tx-1 tx-2
# expected: Batch success: true, Stateful: true, Total gas ~111,655

# 4. Sign — mainnet leg, AA 7702 default, EOA pays a tiny fee from its ETH stash
aomi tx sign tx-1 tx-2
# verified output:
#   Exec:    aa (alchemy, 7702)
#   Fee:     0.000011 ETH → 0x9C7a99480c59955a635123EDa064456393e519f5
#   ✅ Sent! Hash: 0x...
#   Deleg:   0x69007702764179f14F51cdce752f4f775d74E139

# 5. Track destination-chain settlement (off-chain — Across is fast, ~30s)
aomi chat "track the Across order I just submitted"
```

Pattern notes:

- The agent will queue **stale failed attempts** if it retries with new deadlines. `aomi tx list` may show several `tx-N` entries for one bridge request. Read the `batch_status` metadata and sign only the pair marked `Batch [...] passed`.
- Destination-chain settlement is **not** a `tx-N` — it's a status the agent polls via the bridge's API.
- Bridge apps available: `lifi` (direct bridges), `khalani` (intent-based, see [apps.md → Solver Networks](apps.md#solver-networks--khalani)). Across is reachable via the agent's tool surface as shown above, **not** as `--app across`.
- **L2 return leg requires native gas on the L2.** Bridging *back* from Base to mainnet has a known limitation in v0.1.30: if the EOA has 0 ETH on Base, the AA 4337 path falls through to a direct EOA send and fails with viem `insufficient funds for transfer`. See [account-abstraction.md → Sponsorship in practice](account-abstraction.md#sponsorship-in-practice-verified-against-v0130) before attempting the return.

## 4. Staking — Stake Into a Vault or Validator

Stake an asset into a validator, vault, or restaking protocol to earn rewards. Usually approve + stake.

```bash
# 1. Pick a destination
aomi chat "what staking options are available for ETH on Yearn?" \
  --app yearn --chain 1 --new-session

# 2. Build the stake request
aomi chat "stake 0.5 ETH into <vault-name> on Yearn" \
  --app yearn --chain 1 --public-key 0xUserAddress

# 3. Inspect
aomi tx list
# expected: tx-1 (approve, if needed), tx-2 (stake/deposit)

# 4. Simulate
aomi tx simulate tx-1 tx-2

# 5. Sign
aomi tx sign tx-1 tx-2

# 6. Confirm position
aomi chat "show my Yearn positions" --app yearn
```

Pattern notes:

- Native ETH staking sometimes skips the approve step (no ERC-20 allowance needed). If `aomi tx list` shows only one tx, simulate it standalone: `aomi tx simulate tx-1`.
- Unstaking and reward-claim flows follow the same shape; just adjust the chat prompt.

## What All Four Flows Have in Common

- **Always start a wallet-aware session** with `--public-key 0xUserAddress` and the right `--chain`.
- **Always read `aomi tx list`** between chat and signing — never guess what's queued.
- **Always simulate multi-step batches** before signing. Single-tx flows are simulation-optional but never wrong to simulate.
- **Always confirm** with the user before `aomi tx sign` for any flow that moves funds.
