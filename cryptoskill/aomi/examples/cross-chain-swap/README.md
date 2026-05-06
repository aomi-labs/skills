# Cross-Chain — CCTP Bridge (Ethereum → Base)

End-to-end example: bridge 50 USDC from Ethereum mainnet to Base via Circle's Cross-Chain Transfer Protocol (CCTP). Demonstrates the multi-step bridge pattern with off-chain attestation settlement.

## Prerequisites

```bash
npm install -g @aomi-labs/client
aomi --version    # expects 0.1.30+
```

The user holds 50+ USDC on Ethereum mainnet and wants the same balance on Base. CCTP burns USDC on the source chain and mints native USDC on the destination chain — there's no wrapped or bridged variant.

## Step 1: Send the intent

The gold-standard prompt shape for any bridge: amount + asset + chains + protocol + recipient + multi-step hint.

```bash
aomi chat "Bridge 50 USDC from Ethereum mainnet to Base via CCTP. Recipient is my own wallet. Approve first." \
  --public-key 0xUserAddress \
  --chain 1 \
  --new-session
```

The agent runs the most paranoid pre-stage verification of any flow — balance, allowance, ABI fetch, EIP-1967 proxy unwrap, selector check — before staging anything (`--verbose` or `aomi session log`):

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
                         (no drain-vector annotations)
```

What the user sees:

```
I've staged and simulated the bridge for 50 USDC from Ethereum to Base via CCTP.
The simulation was successful.

Note on Settlement: Once you sign and broadcast these transactions, the USDC will
be burned on Ethereum. You will need to wait approximately 13–19 minutes for
Circle's attestation before the funds are minted to your wallet on Base.

Transaction Batch:
  1. Approve USDC — allow the CCTP Messenger (0x28b5...cf5d) to spend 50 USDC.
  2. Bridge to Base — call depositForBurn to send the funds to Base (Domain ID: 6).

⚡ Wallet request queued: tx-1
   to:    0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
   value: 0
   chain: 1
⚡ Wallet request queued: tx-2
   to:    0x28b5a0e9c621a5badaa536219b3a228c8168cf5d
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
        label: Approve USDC for CCTP Messenger (50 USDC)
  tx-2  to 0x28b5a0e9c621a5badaa536219b3a228c8168cf5d (CCTP TokenMessenger)
        label: Bridge 50 USDC from Ethereum to Base using CCTP
```

## Step 3: Simulate

```bash
aomi tx simulate tx-1 tx-2
```

```
Simulation result:
  Batch success: true
  Stateful: true
  Total gas: 164891

  Step 1 — Approve USDC for CCTP Messenger (50 USDC)
    success: true
    gas_used: 55570

  Step 2 — Bridge 50 USDC from Ethereum to Base using CCTP
    success: true
    gas_used: 109321
```

## Step 4: Sign

```bash
aomi tx sign tx-1 tx-2
```

The signing chain is Ethereum (the queued txs target chain 1). No `--rpc-url` override needed; the default Ethereum RPC works. Output:

```
Exec:    aa (alchemy, 7702)
✅ Sent! Hash: 0x...      (single hash on the 7702 atomic-batch path)
```

## Step 5: Track settlement

The source-chain burn confirms in 1-2 blocks. The destination mint requires Circle's off-chain attestation (~13-19 minutes). This is **not** a `tx-N` in `aomi tx list` — track it via chat:

```bash
aomi chat "track my CCTP bridge — has Circle attested yet?"
```

The agent queries Circle's attestation API and reports either *"still pending"* or *"attested, ready to mint on Base"*. Once attested, the agent can stage the destination-side `receiveMessage` call, but in practice CCTP relayers complete the mint automatically — most users just wait and check their Base USDC balance.

## Notes

- **`mintRecipient` is the L2 owner, encoded as `bytes32`.** A natural-language *"send to my wallet"* gets correctly converted to `0x000000...<20-byte-address>` left-padded. If the user types a different address, the agent blocks `mintRecipient != msg.sender` at simulation time — surface the block.
- **Domain IDs are CCTP-specific, not chain IDs.** Base = 6, Arbitrum = 3, Optimism = 2, Avalanche = 1, Solana = 5. The agent translates *"to Base"* → `destinationDomain = 6` automatically.
- **Settlement is off-chain.** No on-chain `tx-N` for the destination mint. Track via follow-up chat.
- **Other bridge shapes.**
  - **Across** — `depositV3` to SpokePool, ~30s settlement, recipient at word1. Fast but variable relayer fee. Agent fetches a quote first.
  - **Stargate** — `send(SendParam, fee, refundAddress)`, recipient inside SendParam tuple, separate refundAddress, LayerZero settlement. **Both** recipient AND refundAddress are drain vectors.
  - **Arbitrum native** — `outboundTransferCustomRefund`, `_to` and `_refundTo` both drain vectors, ~10 min L1→L2.
  - **OP-stack native** (Base/Optimism) — `bridgeETHTo` or `depositETHTo`, single tx, no approve, ~1-3 min L1→L2.

## Cross-chain RPC handling

The session is on chain 1 (`--chain 1`), and so are the queued txs in this example. For a flow where the agent queues a tx on a different chain than the session (e.g. user starts on Ethereum, agent stages a destination-side claim on Base), pass `--rpc-url` matching the **queued tx's** chain when signing:

```bash
aomi tx sign tx-3 --rpc-url https://base.publicnode.com
```

`--chain` (session context) and `--rpc-url` (signing transport) are independent controls — keep them aligned with the transaction you're signing.

## Complete Script

```bash
#!/usr/bin/env bash
set -euo pipefail

USER_ADDR="0xUserAddress"

# 1. Stage approve + bridge as a batch
aomi chat "Bridge 50 USDC from Ethereum to Base via CCTP. Recipient is my wallet. Approve first." \
  --public-key "$USER_ADDR" \
  --chain 1 \
  --new-session

# 2. Confirm pending
aomi tx list

# 3. Simulate (mandatory for multi-step bridge)
aomi tx simulate tx-1 tx-2

# 4. Sign — settles on Ethereum, mints on Base after Circle attestation
aomi tx sign tx-1 tx-2

# 5. Track destination settlement (~13-19 min)
sleep 900    # ~15 min
aomi chat "track my CCTP bridge — has Circle attested yet?"
```
