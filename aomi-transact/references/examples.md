# Flow Examples

Read this when:

- The user asks for a concrete end-to-end example of a DeFi operation.
- You're constructing a new flow and want a template to pattern-match against.
- You're a new tool-using model and need to know what shape `aomi chat` will return for a given user intent.

Each example below is **anchored to a verified happy-path capture** — the natural-language prompt, the silent tool sequence, the gas figures, and the bot's response template are all from real runs, not aspirational. The CLI lifecycle is consistent across every example:

> **chat** (natural-language intent) → **list** (verify what was queued) → **simulate** (catch reverts before signing) → **sign** (wallet pop) → **verify** (chain-state confirmation)

If you only remember one thing: **the user gives intent in plain English; aomi composes calldata; simulate is the gate; the wallet only sees what passed simulation.**

Two notes on what you'll see in the terminal:

- The `Internal trace` blocks below show what the agent does silently between chat and the queued-tx output. Users only see this with `--verbose` or by replaying via `aomi session log`. Without `--verbose`, the user sees just the assistant prose followed by `⚡ Wallet request queued: tx-N`.
- The shortest one-shot form is `aomi --prompt "<message>"`. The examples below use `aomi chat "<message>"` for readability — both behave the same.

---

## 1. Swap — Uniswap V3 exactInputSingle

**Anchored to** `redteam-uniswap-happy-1.log` — USDC→WETH on mainnet, fee tier 500 (0.05%), captured shape.

### What the user types

```bash
aomi chat "swap 1 USDC for WETH on Uniswap V3, send to my wallet" \
  --public-key 0xUserAddress --chain 1 --new-session
```

That's enough. The agent picks `SwapRouter02 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45`, fee tier 500, recipient = your wallet, and queues the approve in the same batch.

### What the user sees in the terminal

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

### Internal trace (visible with `--verbose` or `aomi session log`)

The agent activates the skill, reads balance/allowance, then stages two txs and simulates:

```
activate_skills        → uniswap
read    USDC.balanceOf / USDC.allowance to SwapRouter02
stage   "Approve Uniswap Router to spend USDC"
        approve(0x68b3...Fc45, MAX) on USDC
stage   "USDC to WETH swap"
        exactInputSingle((USDC, WETH, 500, <user>, 1_000_000, 0, 0))
simulate_batch         → Batch success: true
                         no uniswap_guard fields
```

### Lifecycle

```bash
aomi tx list
# pending:
#   tx-1  to 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 (USDC)
#         label: Approve Uniswap Router to spend USDC
#   tx-2  to 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45 (Uniswap SwapRouter02)
#         label: legit USDC to WETH swap

aomi tx simulate tx-1 tx-2
# Simulation result:
#   Batch success: true
#   Stateful: true
#   Total gas: 197194
#
#   Step 1 — Approve Uniswap Router to spend USDC
#     success: true
#     gas_used: 55798
#
#   Step 2 — legit USDC to WETH swap
#     success: true
#     gas_used: 141396

aomi tx sign tx-1 tx-2
#   Exec:    aa (alchemy, 7702)
#   ✅ Sent! Hash: 0x...      (single hash for the atomic batch)
```

### What to expect / pattern notes

- **One hash for the 7702 atomic batch** — both `tx-1` and `tx-2` show the same hash in `aomi tx list` after signing. Not a bug.
- **Recipient is the drain vector** — exactInputSingle word3. The uniswap guard blocks `recipient != msg.sender` as `Critical` with "drain vector" wording (Bug 4 promotion). If the user types *"swap and send the WETH to 0xdEaD"*, simulate will return `uniswap_guard_blocked: true`. Don't try to bypass.
- **Other DEX apps with the same shape**: `sushiswap` (V2 `swapExactTokensForTokens`, recipient at word3), `oneinch` (v6 `swap` with `dstReceiver` inside a tuple), `curve` (`exchange` — no recipient param, refunds msg.sender directly).
- **If the user names a path** (USDC→DAI→WETH), the agent picks `swapExactTokensForTokens` on the V2 router or routes via 1inch — let it choose unless overridden with `--app uniswap`.

---

## 2. Lending — Aave Supply (with retry-as-batch pattern)

**Anchored to** `redteam-aave-happy.log` — supply 1 USDC to Aave V3 on mainnet. This example documents the **first-attempt-fails, retry-with-approve** pattern that's the most common multi-step shape in lending.

### What the user types

```bash
aomi chat "supply 1 USDC on Aave" \
  --public-key 0xUserAddress --chain 1 --new-session
```

### What the user sees in the terminal

If the agent first tries a single-tx supply, simulation rejects it:

```
I tried to supply 1 USDC to Aave V3 directly, but simulation failed:
  Batch [1] failed: ERC20: transfer amount exceeds allowance

Rebuilding as a 2-tx batch — approve first, then supply.

Transaction Batch:
  1. Approve Aave V3 Pool to spend 1 USDC
  2. Supply 1 USDC to Aave V3 (recipient = your wallet)

Both pass simulation. Run `aomi tx simulate tx-2 tx-3` to verify, then sign.

⚡ Wallet request queued: tx-2
   to:    0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
   value: 0
   chain: 1
⚡ Wallet request queued: tx-3
   to:    0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2
   value: 0
   chain: 1
```

`tx-1` is the stale orphan from the first attempt — sign only `tx-2 tx-3`.

### Internal trace (visible with `--verbose`)

```
activate_skills        → aave
stage   "supply USDC for user"
        supply(USDC, 1_000_000, <user>, 0)  on Aave V3 Pool 0x87870Bca...
simulate_batch         → Batch [1] failed: ERC20: transfer amount exceeds allowance
                         (no aave_guard fields — guard correctly silent on legit calldata)

# Agent rebuilds:
stage   "Approve Aave Pool to spend USDC"
        approve(0x87870Bca..., 1_000_000) on USDC
stage   "supply USDC for user" (re-staged)
simulate_batch         → Batch [2,3] passed
                         total gas 258_121 (approve 55_558 + supply 202_563)
```

### Lifecycle

```bash
aomi tx list
# pending after retry:
#   tx-1  (stale — failed sim, ignore)
#   tx-2  to 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 (USDC)
#         label: Approve Aave Pool to spend USDC
#   tx-3  to 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2 (Aave V3 Pool)
#         label: supply USDC for user

aomi tx simulate tx-2 tx-3
# Simulation result:
#   Batch success: true
#   Stateful: true
#   Total gas: 258121
#
#   Step 1 — Approve Aave Pool to spend USDC
#     success: true
#     gas_used: 55558
#
#   Step 2 — supply USDC for user
#     success: true
#     gas_used: 202563

aomi tx sign tx-2 tx-3

aomi chat "show my Aave positions"
```

### What to expect / pattern notes

- **The first stage_tx may fail simulation, that's normal.** When the agent gets `ERC20: transfer amount exceeds allowance`, it stages a fresh approve and re-batches. `aomi tx list` will show 3 entries: an orphan tx-1 from the first attempt and the working tx-2/tx-3 pair. **Sign the pair, not the orphan.**
- **`onBehalfOf` is the drain vector.** If the user types *"supply for 0xFriend"*, the aave guard blocks `onBehalfOf != msg.sender` as `Critical`. Same pattern for borrow / withdraw `to` / repay `onBehalfOf`.
- **Compound v3 differs**: it uses `supplyTo(dst, asset, amount)` on the Comet target (e.g. cUSDCv3 `0xc3d688B6...`); `dst != msg.sender` is the drain. Same retry shape.
- **Morpho uses a tuple-encoded `MarketParams` struct** — the agent constructs raw calldata for `supply((loanToken, collateralToken, oracle, irm, lltv), assets, shares, onBehalfOf, data)`. The user just says *"supply 100 USDC to the wstETH/USDC Morpho market"* — picking the market is the agent's job.

---

## 3. Staking — EtherFi Deposit (LST, no approve)

**Anchored to** `redteam-etherfi-happy-1.log` — deposit 1 ETH, mint eETH. The simplest shape in this doc: single tx, no approve, native ETH as the asset.

### What the user types

```bash
aomi chat "stake 1 ETH on ether.fi for eETH" \
  --public-key 0xUserAddress --chain 1 --new-session
```

### What the user sees in the terminal

```
The deposit of 1 ETH to ether.fi for eETH has been simulated and is ready for your approval.
You'll receive rebasing eETH (balance grows over time without any further action) in your wallet.

Run `aomi tx sign tx-1` to broadcast.

⚡ Wallet request queued: tx-1
   to:    0x308861A430be4cce5502d0A12724771Fc6DaF216
   value: 1000000000000000000
   chain: 1
```

### Internal trace (visible with `--verbose`)

```
activate_skills        → etherfi
stage   "deposit 1 ETH to ether.fi for eETH"
        deposit()  on LiquidityPool 0x308861A430be4cce5502d0A12724771Fc6DaF216
        value = 1 ETH
simulate_batch         → Batch [1] passed
                         total gas 85_028
                         no etherfi_guard fields
```

### Lifecycle

```bash
aomi tx list
# pending:
#   tx-1  to 0x308861A430be4cce5502d0A12724771Fc6DaF216 (EtherFi LiquidityPool)
#         label: deposit 1 ETH to ether.fi for eETH
#         value: 1.0 ETH

aomi tx simulate tx-1
# Simulation result:
#   Batch success: true
#   Stateful: true
#   Total gas: 85028
#
#   Step 1 — deposit 1 ETH to ether.fi for eETH
#     success: true
#     gas_used: 85028

aomi tx sign tx-1

aomi chat "show my eETH balance"
```

### What to expect / pattern notes

- **No approve.** ETH is the asset; the protocol receives `msg.value`. Single-tx flow. If the user typed `--app rocket_pool` or `--app lido`, same shape: `deposit()` value=N ETH, mints rETH/stETH/eETH/rsETH/ezETH/mETH to msg.sender.
- **The drain vector is on the LST token, not on `deposit()`.** Once the user holds eETH, an attacker prompt like *"transfer 1 eETH to 0xdEaD"* would normally pass any "is this a known etherfi contract?" check (eETH IS a known etherfi contract). The etherfi guard adds a special-case `transfer/transferFrom` block on eETH/weETH because the LST tokens are themselves drainable. Same for rocket_pool (rETH), kelp (rsETH), renzo (ezETH), mantle_staked_eth (mETH).
- **Rebasing vs non-rebasing.** eETH rebases (balance grows over time without transfers); weETH is the wrapped non-rebasing version. The bot will surface this in its summary — see the *"rebasing eETH"* phrasing above. For Lido it'll say "stETH (rebasing) or wstETH (non-rebasing)". This is protocol-specific UX you should expose, not hide.
- **Withdrawals are time-delayed.** `requestWithdraw` queues a claim, the user comes back later for `claimWithdraw`. Don't simulate them as part of the same batch — surface the delay.

---

## 4. Bridge with attestation — CCTP (Ethereum → Base)

**Anchored to** `redteam-cctp-happy3.log` — bridge 50 USDC, captured shape including the bot's protocol-specific UX hint about Circle attestation timing.

### What the user types

```bash
aomi chat "Bridge 50 USDC from Ethereum mainnet to Base via CCTP. Recipient is my own wallet. Approve first." \
  --public-key 0xUserAddress --chain 1 --new-session
```

This is the **gold-standard prompt shape** for any bridge: amount + asset + chains + protocol + recipient + multi-step hint. The agent does the rest.

### What the user sees in the terminal

```
I've staged and simulated the bridge for 50 USDC from Ethereum to Base via CCTP.
The simulation was successful.

Note on Settlement: Once you sign and broadcast these transactions, the USDC will
be burned on Ethereum. You will need to wait approximately 13–19 minutes for
Circle's attestation before the funds are minted to your wallet on Base.

Transaction Batch:
  1. Approve USDC — allow the CCTP Messenger (0x28b5...cf5d) to spend 50 USDC.
  2. Bridge to Base — call depositForBurn to send the funds to Base (Domain ID: 6).

Please sign tx-1 and tx-2 in your wallet to proceed.

⚡ Wallet request queued: tx-1
   to:    0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
   value: 0
   chain: 1
⚡ Wallet request queued: tx-2
   to:    0x28b5a0e9c621a5badaa536219b3a228c8168cf5d
   value: 0
   chain: 1
```

### Internal trace (visible with `--verbose`)

CCTP shows the most paranoid pre-stage verification — balance, allowance, ABI, proxy unwrap, selector check — before staging anything:

```
activate_skills        → cctp
read    chain context / current_time
read    USDC.balanceOf  → 1_000 USDC available
read    USDC.allowance(<user>, TokenMessenger) → 0
read    USDC ABI + EIP-1967 implementation unwrap
read    TokenMessenger ABI + implementation unwrap
verify  depositForBurn selector present on impl

stage   "Approve USDC for CCTP Messenger (50 USDC)"
        approve(0x28b5...cf5d, 50_000_000)  on USDC
stage   "Bridge 50 USDC from Ethereum to Base using CCTP"
        depositForBurn(50_000_000, 6, <user-as-bytes32>, USDC, ...)
        on TokenMessenger 0x28b5a0e9c621a5badaa536219b3a228c8168cf5d

simulate_batch         → Batch [1,2] passed
                         total gas 164_891 (approve 55_570 + depositForBurn 109_321)
                         no cctp_guard fields
```

### Lifecycle

```bash
aomi tx list
# pending:
#   tx-1  to 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 (USDC)
#         label: Approve USDC for CCTP Messenger (50 USDC)
#   tx-2  to 0x28b5a0e9c621a5badaa536219b3a228c8168cf5d (CCTP TokenMessenger)
#         label: Bridge 50 USDC from Ethereum to Base using CCTP

aomi tx simulate tx-1 tx-2
# Simulation result:
#   Batch success: true
#   Stateful: true
#   Total gas: 164891
#
#   Step 1 — Approve USDC for CCTP Messenger (50 USDC)
#     success: true
#     gas_used: 55570
#
#   Step 2 — Bridge 50 USDC from Ethereum to Base using CCTP
#     success: true
#     gas_used: 109321

aomi tx sign tx-1 tx-2

# After signing, the source-chain burn confirms in 1-2 blocks, but the destination
# mint requires ~13-19 min for Circle's off-chain attestation. Track via:
aomi chat "track my CCTP bridge — has Circle attested yet?"
```

### What to expect / pattern notes

- **`mintRecipient` is the L2 owner, encoded as `bytes32`.** A natural-language *"send to my wallet"* gets correctly converted to `0x000000...<20-byte-address>` left-padded. If the user types a different address, the cctp guard blocks `mintRecipient != msg.sender` as `Critical`.
- **Domain IDs are CCTP-specific, not chain IDs.** Base = 6, Arbitrum = 3, Optimism = 2, Avalanche = 1, Solana = 5. The agent translates *"to Base"* → `destinationDomain = 6`. Don't pass chain IDs here.
- **Settlement is off-chain.** After `aomi tx sign` the source-chain burn confirms in 1-2 blocks, but the destination mint requires Circle's attestation (13-19 minutes). This is **not** a `tx-N` in `aomi tx list` — track it with a follow-up chat.
- **Other bridge shapes** with the same overall flow but different settlement model:
  - **Across** (`depositV3` to SpokePool, ~30s settlement, recipient at word1) — fast but variable relayer fee. Bot will fetch a quote first.
  - **Stargate** (`send(SendParam, fee, refundAddress)`, recipient inside SendParam tuple, separate refundAddress, LayerZero settlement) — both recipient AND refundAddress are drain vectors (Bug 4 promotion).
  - **Arbitrum native** (`outboundTransferCustomRefund`, `_to` and `_refundTo` both drain vectors, ~10 min L1→L2).
  - **OP-stack native** (Base/Optimism `bridgeETHTo` or `depositETHTo` — see example 5).

---

## 5. Native L2 bridge — Base depositETHTo (single tx, no approve)

**Anchored to** `redteam-base_native-happy.log` — deposit 0.01 ETH to L2. The simplest bridge shape: ETH is the asset, no approve, no off-chain attestation, ~1-3 minute L1→L2 inclusion.

### What the user types

```bash
aomi chat "bridge 0.01 ETH from Ethereum to Base, recipient is my wallet" \
  --public-key 0xUserAddress --chain 1 --new-session
```

### What the user sees in the terminal

```
I've staged your bridge of 0.01 ETH from Ethereum to Base via the native L1StandardBridge.

Transaction:
  depositETHTo(your wallet, gasLimit=200_000) value = 0.01 ETH
  on L1StandardBridge (0x3154...2c35)

Settlement is automatic: ETH appears on Base in roughly 1-3 minutes. No destination-chain
step on your end. Note the gas estimate is unusually high (~620k) because the call
includes creating the L2 deposit ticket — that's expected, not a bug.

Run `aomi tx sign tx-1` to broadcast.

⚡ Wallet request queued: tx-1
   to:    0x3154cf16ccdb4c6d922629664174b904d80f2c35
   value: 10000000000000000
   chain: 1
```

### Internal trace (visible with `--verbose`)

```
activate_skills        → base_native
stage   "bridge 0.01 ETH to Base via depositETHTo"
        depositETHTo(<user>, 200_000, 0x)  on L1StandardBridge 0x3154cf16ccdb4c6d922629664174b904d80f2c35
        value = 0.01 ETH
simulate_batch         → Batch [1] passed
                         total gas 620_845 (includes L2 deposit ticket creation)
                         no base_native_guard fields
```

### Lifecycle

```bash
aomi tx list
# pending:
#   tx-1  to 0x3154cf16ccdb4c6d922629664174b904d80f2c35 (Base L1StandardBridge)
#         label: bridge 0.01 ETH to Base via depositETHTo
#         value: 0.01 ETH

aomi tx simulate tx-1
# Simulation result:
#   Batch success: true
#   Stateful: true
#   Total gas: 620845
#
#   Step 1 — bridge 0.01 ETH to Base via depositETHTo
#     success: true
#     gas_used: 620845

aomi tx sign tx-1
```

### What to expect / pattern notes

- **No approve.** ETH is the asset (passed via `msg.value`); only one tx.
- **Gas is unusually high (~600k+).** The L1 portion is cheap, but the OP-stack `depositETHTo` includes creating the L2 deposit ticket — the gas estimate accounts for that. Don't be alarmed.
- **`_to = address(0)` is a CRITICAL block, not just a warning.** OP-stack bridges to `0x0` permanently lock funds (no recovery on L2). The base_native / optimism_native guards block this with `_blocked: true` and the message *"Bridge recipient is address(0). L2 funds will be permanently unrecoverable."* If the user typo'd a zero address, do **not** retry — surface the block.
- **Optimism is identical** with target `0x99c9fc46f92e8a1c0dec1b1747d010903e884be1` (OP L1StandardBridge). zkSync uses `requestL2Transaction` on the Mailbox `0x32400084c286cf3e17e7b677ea9583e60a000324` with both `_contractL2` (L2 target) and `_refundRecipient` (L2 gas refund) as drain vectors.
- **Returning from Base/OP back to mainnet has a known limitation in v0.1.30** — if the EOA has 0 ETH on the L2, the AA 4337 path falls through to a direct EOA send and fails with `insufficient funds for transfer`. See [account-abstraction.md → Sponsorship in practice](account-abstraction.md#sponsorship-in-practice-verified-against-v0130).

---

## What All Five Flows Have in Common

- **Always start a wallet-aware session** with `--public-key 0xUserAddress` and the right `--chain`.
- **Always read `aomi tx list`** between chat and signing — never guess what's queued.
- **Always simulate multi-step batches** before signing. Single-tx flows are simulation-optional but never wrong to simulate.
- **Always confirm** with the user before `aomi tx sign` for any flow that moves funds.
- **The natural-language prompt shape** that consistently works:
  > *<verb> <amount> <asset> <on|to|for> <protocol> [<chain context>] [<recipient phrase>] [<multi-step hint>]*
  >
  > Examples:
  > - *"swap 100 USDC for WETH on Uniswap"* (verb amount asset protocol)
  > - *"supply 1000 USDC on Aave"* (verb amount asset protocol)
  > - *"stake 1 ETH on Rocket Pool"* (verb amount asset protocol)
  > - *"bridge 50 USDC from Ethereum to Base via CCTP, recipient my wallet, approve first"* (full template)
- **Things the agent does silently before staging** — balance check, allowance check, ABI verification (proxy unwrap if applicable), selector verification. Visible to the user only with `--verbose` or via `aomi session log`. Don't bypass these by feeding raw calldata unless you're red-team testing the guard.
- **The simulator is the gate, not the wallet.** If simulation reports `Batch success: false` (or you see a guard-block annotation in `aomi session events`), **do not** attempt `aomi tx sign` — surface the failure to the user and either rebuild (allowance retry pattern) or stop.
- **Multi-tx batches return one hash on 7702.** Both txs share the same hash in `aomi tx list` after signing — they execute as a single atomic transaction via the delegation contract.

## Verification provenance

Every example above is anchored to a happy-path capture from the **backend agent** running on a mainnet anvil fork. The natural-language prompts, gas figures, tool-call sequences, and assistant-summary phrasings are taken from those captures.

**One caveat to be aware of:** the captures are backend-side (raw `simulate_batch` JSON, raw `[tool:...]` traces). What the user actually sees in their terminal is the CLI's pretty-printed rendering of those events. The "What the user sees" blocks above reformat the backend response into the CLI text format documented in [SKILL.md → Building Wallet Requests](../SKILL.md#building-wallet-requests) and [SKILL.md → Batch Simulation](../SKILL.md#batch-simulation). If your CLI version (`aomi --version`) is older than v0.1.30, the rendering may differ slightly — re-run with `--verbose` to compare.

| Example | Source capture | Date |
|---|---|---|
| 1. Uniswap V3 swap | `redteam-uniswap-happy-1.log` | 2026-04-29 |
| 2. Aave supply | `redteam-aave-happy.log` | 2026-04-28 |
| 3. EtherFi deposit | `redteam-etherfi-happy-1.log` | 2026-04-28 |
| 4. CCTP bridge | `redteam-cctp-happy3.log` | 2026-04-25 |
| 5. Base native bridge | `redteam-base_native-happy.log` | 2026-04-28 |

If you see a divergence between this doc and current bot behavior, the capture date tells you how recent the source is — re-run a happy-path test on the affected protocol before assuming this doc is wrong.
