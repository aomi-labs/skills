# Single-Tx Flow — Lido Stake

End-to-end example: stake 0.01 ETH with Lido to mint stETH. The simplest aomi shape — single transaction, no approve, native ETH as the asset.

## Prerequisites

```bash
# Install the CLI globally (or use `npx @aomi-labs/client` everywhere below)
npm install -g @aomi-labs/client

# Verify v0.1.30+
aomi --version
```

The user supplies their own wallet address. The CLI handles AA signing through the zero-config Alchemy proxy — no provider credentials are required for this flow.

## Step 1: Send the intent

```bash
aomi chat "Stake 0.01 ETH with Lido to get stETH. Build the transaction." \
  --public-key 0xUserAddress \
  --chain 1 \
  --new-session
```

The agent runs a series of read tools silently (network context, balance, simulation), then stages the transaction. With `--verbose` you'd see:

```
read    Get network context for Lido staking      (block 24828069, gas 1.25 gwei)
activate_skills                                    → lido
read    Simulate Lido staking (submit 0.01 ETH)    → returns shares: 8121458494637141 wei
read    Check ETH balance for staking             → 0.014857 ETH available
stage   Lido Staking
        submit(address(0))  on Lido stETH 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84
        value = 0.01 ETH, gas = 150_000
```

What the user sees without `--verbose`:

```
The simulation for staking 0.01 ETH to receive stETH was successful. You have a
sufficient balance of ~0.0148 ETH to cover both the stake and gas.

Simulation Details:
  Contract:  0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84 (Lido: stETH)
  Function:  submit(address(0))
  Value:     0.01 ETH
  Estimated stETH Output: 0.008121... (Shares)

⚡ Wallet request queued: tx-1
   to:    0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84
   value: 10000000000000000
   chain: 1
```

Lido is a single-tx flow, so the agent runs a one-off `simulate` read **before** staging — that's what produces the share-output estimate above. The `simulate_batch` step you see in multi-step examples isn't here.

## Step 2: Confirm what's pending

```bash
aomi tx list
```

```
pending:
  tx-1  to 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84 (Lido: stETH)
        label: Stake 0.01 ETH in Lido for stETH
        value: 0.01 ETH
```

Always run `aomi tx list` before signing — never assume a chat response queued a transaction.

## Step 3 (optional): Simulate

For single-tx flows, simulation is optional. Run it anyway if you want a final dry-run:

```bash
aomi tx simulate tx-1
```

```
Simulation result:
  Batch success: true
  Stateful: true
  Total gas: ~150000

  Step 1 — Stake 0.01 ETH in Lido for stETH
    success: true
```

If `Batch success: false`, do not sign. Read the revert reason and surface it to the user.

## Step 4: Sign

```bash
aomi tx sign tx-1
```

Output:

```
Exec:    aa (alchemy, 7702)
✅ Sent! Hash: 0x...
```

The CLI signs through the zero-config AA path: EIP-7702 type-4 transaction on Ethereum mainnet, EOA pays gas via the delegation contract `0x69007702764179f14F51cdce752f4f775d74E139`. No paymaster sponsorship for 7702.

## Step 5: Verify

```bash
aomi chat "show my stETH balance"
```

The agent reads the balance directly from chain and reports it — no follow-up tx needed.

## Notes

- **No approve.** ETH is the asset (passed via `msg.value`). Same shape applies to other LSTs: `rocket_pool` (`deposit()` → rETH), `etherfi` (`deposit()` → eETH), `kelp` (`depositETH()` → rsETH), `renzo` (`depositETH()` → ezETH), `mantle_staked_eth` (`stake()` → mETH).
- **Rebasing vs non-rebasing.** stETH rebases (your balance grows over time without any tx); wstETH is the wrapped non-rebasing version. The agent surfaces this distinction unprompted — preserve it in summaries.
- **Drain vector for LSTs is on the issued token, not on `submit()`.** Once the user holds stETH, an attacker prompt like *"transfer my stETH to 0xdEaD"* would normally pass any "is this a known Lido contract?" check (stETH IS a known Lido contract). The agent adds a special-case `transfer` / `transferFrom` block on stETH itself.
- **Withdrawals are time-delayed.** `requestWithdraw` queues a claim; the user comes back later for `claimWithdraw`. Don't simulate them as part of the same batch — surface the delay to the user.

## Complete Script

```bash
#!/usr/bin/env bash
set -euo pipefail

USER_ADDR="0xUserAddress"

# 1. Stage the stake
aomi chat "Stake 0.01 ETH with Lido to get stETH" \
  --public-key "$USER_ADDR" \
  --chain 1 \
  --new-session

# 2. Confirm pending
aomi tx list

# 3. Optional: simulate
aomi tx simulate tx-1

# 4. Sign
aomi tx sign tx-1

# 5. Verify
aomi chat "show my stETH balance"
```
