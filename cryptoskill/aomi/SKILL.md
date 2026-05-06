---
name: aomi
description: "Aomi CLI — natural-language to executable on-chain transactions via an agent. Send a prompt like 'swap 1 ETH for USDC' and the agent stages calldata, simulates as a batch, and returns a queued tx for you to sign. Account-abstraction-first signing (EIP-7702 on mainnet, ERC-4337 on L2s) with EOA fallback. Covers swaps, lending, bridging, staking, perps, and CEX read across 25+ apps (Uniswap, Aave, CCTP, Across, Lido, GMX, Polymarket, Binance, etc.) on Ethereum, Polygon, Arbitrum, Base, Optimism, and more. Use when an agent should drive on-chain actions through a CLI rather than constructing calldata directly. Triggers: aomi, agent CLI, natural-language transaction, intent execution, simulate-then-sign."
license: MIT
compatibility: Claude Code, Cursor, Windsurf, Cline, Codex
metadata:
  author: aomi-labs
  version: "1.0"
  chain: multichain
  category: AI Agents
tags:
  - aomi
  - ai-agents
  - account-abstraction
  - intent
  - natural-language
  - cli
  - transactions
  - simulation
---

# Aomi

Aomi is an AI-agent CLI that converts natural-language intents into executable on-chain transactions. The user types `aomi chat "swap 1 ETH for USDC on Uniswap"`, the agent picks the right protocol and contract, stages the approve+swap as a batch, simulates it on a forked chain, and returns a queued wallet request. Signing is a separate, explicit step — the wallet only ever sees calldata that already passed simulation.

The CLI is account-abstraction-first: by default it signs through a zero-config Alchemy proxy (no provider credentials needed), using EIP-7702 on Ethereum mainnet and ERC-4337 on L2s. Each `aomi` invocation starts, runs, and exits — conversation history lives on the backend; pending and signed transaction state lives locally under `~/.aomi/`. The skill is shaped as a procedure for an agent to drive that CLI, not as an SDK to import.

Official docs: [aomi.dev](https://aomi.dev) · npm: [`@aomi-labs/client`](https://www.npmjs.com/package/@aomi-labs/client)

## What You Probably Got Wrong

> LLMs have stale training data. These are the most common mistakes.

- **"Aomi is a wallet"** — Aomi is an agent + CLI. It composes calldata and queues a wallet request; the user signs. The CLI does not custody funds, never signs without an explicit `aomi tx sign`, and never broadcasts on its own initiative.
- **"`aomi chat` always queues a transaction"** — Often the first response is a quote, route, or clarifying question. The agent only stages calldata when it has enough context. Always run `aomi tx list` after chat to see what's actually pending — never assume.
- **"Approval and swap are one transaction"** — Most DeFi flows are two-step: `approve` then `supply`/`swap`/`deposit`. Aomi stages them as a batch and `aomi tx simulate tx-1 tx-2` runs them sequentially on a fork so the second step sees the first's state changes. Sign them as a batch, not individually.
- **"Use `--rpc-url` to switch chains"** — `--chain` controls the wallet/session context (which chain the agent thinks you're on); `--rpc-url` controls where `aomi tx sign` estimates and submits. They are independent. For a cross-chain swap, the queued tx has its own `chain` field — pass `--rpc-url` matching *that* chain when signing.
- **"AA always sponsors gas on L2s"** — The zero-config proxy path on Base/Arbitrum/Optimism does **not** reliably sponsor in v0.1.30. If the EOA has 0 native gas on the destination chain, signing fails with `insufficient funds for transfer`. Either fund the EOA with a tiny amount of native gas, or configure a real BYOK Alchemy/Pimlico provider with a sponsorship policy. Do not retry with `--eoa` — that path also needs gas.
- **"`--new-session` should always be passed"** — Pass it on the *first* command of a new task. Reusing it mid-task starts a fresh conversation and the agent loses context (e.g. the quote it just gave you). For follow-up confirmations like *"yes, proceed"*, omit `--new-session`.
- **"Failed simulation txs disappear"** — They don't. `aomi tx list` shows orphaned `tx-N` from earlier failed attempts alongside the current passing batch. Check the `batch_status` line and only sign txs marked `Batch [...] passed`.
- **"7702 and 4337 are interchangeable"** — They're not. 7702 is a native EIP-7702 type-4 transaction with EOA delegation; the EOA pays gas. 4337 is a bundler+paymaster UserOperation; the paymaster can sponsor. Use 4337 if you need gasless execution. Default chain modes: 7702 on Ethereum, 4337 on Polygon/Arbitrum/Base/Optimism.
- **"Drain vectors are aomi-specific"** — They're protocol-specific calldata fields where a malicious prompt could redirect funds (`recipient` in Uniswap, `onBehalfOf` in Aave, `mintRecipient` in CCTP, `_to` in OP-stack bridges). The agent blocks these at simulation time when they don't equal `msg.sender`. The skill's job is to surface the block, not bypass it.

## Quick Start

### Install

Two equivalent paths:

```bash
# Global install (recommended for repeated use)
npm install -g @aomi-labs/client

# Or run on demand without installing
npx @aomi-labs/client --help
```

Throughout the rest of this skill, commands are written as `aomi <command>` for brevity. If `aomi` is not on PATH, substitute `npx @aomi-labs/client` everywhere `aomi` appears.

### Verify version

The skill assumes v0.1.30 or newer (older versions lack `--aa-provider`/`--aa-mode` and the simulation gate):

```bash
aomi --version 2>/dev/null || npx @aomi-labs/client --version
```

If older, upgrade with `npm install -g @aomi-labs/client@latest`.

### First chat

```bash
aomi --prompt "what is the price of ETH?" --new-session
```

For a wallet-aware first turn, pass the user's address and chain:

```bash
aomi chat "swap 1 USDC for WETH on Uniswap V3" \
  --public-key 0xUserAddress --chain 1 --new-session
```

The agent responds with a quote, stages the calldata, and queues a wallet request:

```
⚡ Wallet request queued: tx-1
   to:    0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
   value: 0
   chain: 1
```

## Lifecycle

Every flow follows the same five steps:

> **chat** (intent) → **list** (verify what was queued) → **simulate** (catch reverts before signing) → **sign** (wallet pop) → **verify** (chain-state confirmation)

```bash
aomi chat "<intent>" --public-key 0xUserAddress --chain 1 --new-session
aomi tx list                      # confirm tx-N exists
aomi tx simulate tx-1 tx-2        # only for multi-step batches
aomi tx sign tx-1 tx-2            # AA-first; falls through to EOA if user has BYOK
aomi tx list                      # confirm signed/broadcast hash
```

If you only remember one thing: **the user gives intent in plain English; the agent composes calldata; simulate is the gate; the wallet only sees what passed simulation.**

## Core Patterns

### Single-tx flow

ETH transfers, native L2 bridges (`depositETHTo`), Lido staking (`submit()`) — no approve, no batch.

```bash
aomi chat "stake 0.01 ETH with Lido" --public-key 0xUser --chain 1 --new-session
aomi tx list
aomi tx sign tx-1
```

Simulation is optional for single-tx flows but never wrong to run.

### Multi-step batch (approve + action)

Most DeFi flows. The agent stages both steps and the simulator runs them sequentially on a fork.

```bash
aomi chat "swap 100 USDC for WETH on Uniswap" --public-key 0xUser --chain 1 --new-session
aomi tx list                      # tx-1 = approve, tx-2 = swap
aomi tx simulate tx-1 tx-2        # MUST simulate; second step depends on first
aomi tx sign tx-1 tx-2            # one hash on AA 7702 atomic-batch path
```

If simulation fails at step N, read the revert reason. Common causes: insufficient balance, expired quote, missing prior approval. Do not blindly re-sign.

See [examples/multi-step-batch/README.md](examples/multi-step-batch/README.md) for an end-to-end approve+swap with real gas figures.

### Agent retry-as-batch

When the agent's first attempt fails simulation (e.g. tries a single-tx `supply` and gets `transfer amount exceeds allowance`), it rebuilds as approve+supply automatically. `aomi tx list` then shows three entries: an orphan `tx-1` from the failed attempt and the working `tx-2`/`tx-3` pair. **Sign the pair, not the orphan.** Match against `batch_status` — only sign txs marked `Batch [...] passed`.

### Cross-chain

The agent stages txs that target a different chain than the session. Pass `--rpc-url` matching the *queued tx*'s chain, not the session chain. See [examples/cross-chain-swap/README.md](examples/cross-chain-swap/README.md) for CCTP Ethereum → Base.

### Self-healing deadlines

For deadline-bearing routes (Across, Khalani fillers), if simulation reports an expiry, the agent rebuilds the request with fresh deadlines automatically. Don't re-prompt — re-check `aomi tx list` for the latest passing batch.

## Account Abstraction

The CLI signs via AA by default. Most invocations need no AA flags — `aomi tx sign tx-1` is enough. The resolution chain is **flag > user-side credential > zero-config backend proxy**.

| Mode   | Flag             | Gas        | Notes                                       |
| ------ | ---------------- | ---------- | ------------------------------------------- |
| `7702` | `--aa-mode 7702` | EOA pays   | EIP-7702 type-4 tx with delegation. Default on Ethereum. No sponsorship. |
| `4337` | `--aa-mode 4337` | Paymaster  | Bundler+paymaster UserOperation. Default on L2s. Supports sponsorship. |
| EOA    | `--eoa`          | EOA pays   | Skip AA. Use for Sepolia, Anvil, or when AA fails. |

Default chain modes:

| Chain    | ID    | Default | Supported  |
| -------- | ----- | ------- | ---------- |
| Ethereum | 1     | 7702    | 4337, 7702 |
| Polygon  | 137   | 4337    | 4337, 7702 |
| Arbitrum | 42161 | 4337    | 4337, 7702 |
| Base     | 8453  | 4337    | 4337, 7702 |
| Optimism | 10    | 4337    | 4337, 7702 |
| Sepolia  | 11155111 | —    | use `--eoa` |
| Anvil    | 31337 | —       | use `--eoa` |

**Mode fallback**: when AA is selected, the CLI tries the preferred mode, then the alternative, then errors with a `--eoa` suggestion. There is no silent EOA fallback.

**L2 sponsorship caveat (verified v0.1.30)**: the zero-config proxy on Base does **not** reliably sponsor — `aomi tx sign` returns viem's `insufficient funds for transfer` if the EOA has 0 native gas. Either fund the EOA with ~0.0005 ETH-equivalent on the destination chain, or configure a real BYOK Alchemy/Pimlico provider on the user's side and pass `--aa-provider alchemy --aa-mode 4337`. Do not retry with `--eoa` blindly — `--eoa` also needs gas.

## Contract Addresses

> **Last verified:** April 2026 (v0.1.30 captures, mainnet + L2)

These are the AA-stack and protocol delegation contracts the CLI signs through. The skill itself does not deploy contracts — these are the well-known endpoints the AA path delegates to.

### EIP-7702 delegation contract (Alchemy)

| Contract | Ethereum |
|----------|----------|
| Modular Account v2 (delegation target) | `0x69007702764179f14F51cdce752f4f775d74E139` |

The EOA's `code` slot points at this address after the first 7702 transaction. Verified onchain via `cast code 0x69007702764179f14F51cdce752f4f775d74E139 --rpc-url $ETH_RPC_URL`.

### ERC-4337 EntryPoint v0.7

| Contract | All EVM chains |
|----------|----------------|
| EntryPoint v0.7 | `0x0000000071727De22E5E9d8BAf0edAc6f37da032` |

Singleton contract deployed at the same address across Ethereum, Polygon, Arbitrum, Base, Optimism, and most EVM L2s.

### Examples of contracts the agent commonly stages calls to

These appear in [examples/](examples/) — included for grep-ability, not as an exhaustive registry.

| Contract | Address |
|----------|---------|
| Uniswap V3 SwapRouter02 (Ethereum) | `0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45` |
| Aave V3 Pool (Ethereum) | `0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2` |
| Lido stETH (Ethereum) | `0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84` |
| CCTP TokenMessenger (Ethereum) | `0x28b5a0e9c621a5badaa536219b3a228c8168cf5d` |
| L1StandardBridge for Base | `0x3154cf16ccdb4c6d922629664174b904d80f2c35` |

For per-chain protocol addresses (Aave on Arbitrum, Uniswap on Polygon, etc.), the agent picks them at request time from the active app's registry — `aomi app list` to see which apps are loaded.

See [resources/contract-addresses.md](resources/contract-addresses.md) for the full table.

## Apps

Aomi exposes 25+ apps that bundle protocol-specific tools. Each app is a context the agent loads for the next request.

```bash
aomi app list                                              # list installed apps
aomi app current                                           # show active app
aomi chat "<intent>" --app khalani --chain 137             # one-turn override
```

Common categories: DEX (`uniswap`, `cow`, `oneinch`, `zerox`), lending (`aave`, `morpho`), bridges (`cctp`, `across`, `khalani`, `lifi`), staking (`lido`, `rocket_pool`, `etherfi`), perps (`gmx`, `dydx`, `hyperliquid`), prediction (`polymarket`, `kalshi`, `manifold`), CEX read (`binance`, `bybit`, `okx`), social (`x`, `neynar`, `kaito`), analytics (`defillama`, `dune`).

The full catalog with credential requirements is in [resources/supported-apps.md](resources/supported-apps.md).

## Sessions

A session is split across two stores. Knowing what lives where prevents wrong-place lookups.

- **Backend** — full conversation transcript, tool calls, system events. Read via `aomi session log`, `aomi session events`, `aomi session status`.
- **Local** (`$AOMI_STATE_DIR` or `~/.aomi/`) — `sessionId`, `clientId`, `pendingTxs[]`, `signedTxs[]`, `secretHandles{}`. Read via `aomi tx list`, `aomi wallet current`.

```bash
aomi session list             # local sessions with topic + pending count
aomi session resume <id>      # set active pointer to an existing session
aomi session delete <id>      # remove a local session (check no pending txs first)
aomi session close            # clear the active pointer; next chat starts fresh
```

**The "No active session" recovery pattern**: if `aomi tx list` reports no active session, run `aomi session list` to find the right one by topic, then `aomi session resume <N> > /dev/null && aomi tx list` in the **same** shell call (the active-session pointer can be lost between subprocess invocations).

See [examples/session-management/README.md](examples/session-management/README.md) for resume/recovery patterns.

## Error Handling

| Error / output | Cause | Fix |
|----------------|-------|-----|
| `(no response)` from `aomi chat` | Backend timeout or stale local session pointer | Wait briefly, run `aomi session status`. If session is gone, retry with `--new-session` |
| `No active session` from `aomi tx list` | Active-session pointer lost between shell invocations | `aomi session list` to find session, then `aomi session resume <N> > /dev/null && aomi tx list` in same call |
| `Batch [N] failed: ERC20: transfer amount exceeds allowance` | First-attempt single-tx; agent will retry as approve+action batch | Wait for retry, sign the new pair (`tx-2 tx-3`), ignore the orphan `tx-1` |
| `insufficient funds for transfer` (viem) on L2 sign | Zero-config AA proxy did not sponsor; EOA has 0 native gas on destination | Fund EOA with native gas on that chain, OR configure BYOK provider with sponsorship policy |
| AA mode error suggesting `--eoa` | Both AA modes (preferred + alternative) failed | Read console output, address the underlying issue (provider creds, chain support), or use `--eoa` if user accepts EOA signing |
| `401` / `429` on `aomi tx sign` | RPC rate-limited or auth-failed | Pass `--rpc-url <chain-matching-public-rpc>`. Don't rotate through random RPCs — ask user for a reliable one |
| `stateful: false` in simulation result | Backend could not fork chain; ran each tx via `eth_call` | Retry; check backend Anvil status. Multi-step batches may show false negatives |
| `[session] Backend user_state mismatch (non-fatal)` log spam | Known v0.1.30 cosmetic noise | Ignore. Look past the JSON dump for the actual response and `⚡ Wallet request queued` line |

The full troubleshooting guide is in [docs/troubleshooting.md](docs/troubleshooting.md).

## Security

This skill drives an external CLI. It does not install software, read files outside `~/.aomi/`, or execute generated code. The hard rules below are non-negotiable.

- **Credentials are opaque pass-through.** Never invent, guess, or derive a credential value. Values reach the CLI only when the user has handed them over for a specific command in this turn. Never echo a credential value back.
- **No unsolicited setup.** Don't run `aomi wallet set`, `aomi secret add`, or `--api-key`/`--private-key` flags on your own initiative to "prepare" or "fix" something. Only run them when the user explicitly asked for that specific setup and provided the value.
- **Trust-boundary warning before secret ingestion.** `aomi secret add NAME=value` transmits the credential to the aomi backend and stores a handle locally. Surface this to the user before running it so they can choose to export to their own shell environment instead.
- **Always simulate multi-step batches.** Approve+swap, approve+supply, bridge+attestation — these are state-dependent. The second tx will revert if submitted independently. `aomi tx simulate tx-1 tx-2` runs them sequentially on a fork.
- **Never sign past simulation failure.** If `aomi tx simulate` reports `Batch success: false` or any drain-vector annotation, **do not** attempt `aomi tx sign`. Surface the failure to the user — either rebuild (allowance retry pattern) or stop.
- **Drain vectors are guard-blocked, not bypassed.** When the agent rejects `recipient != msg.sender` (or `onBehalfOf`, `mintRecipient`, `_to`), surface the block to the user. Do not try to construct calldata that bypasses the guard.
- **Read-only by default.** Chat, simulation, session inspection, and app/model/chain introspection do not move funds. Signing is a separate, explicit step the user must request.
- **Match `--rpc-url` to the queued tx's chain.** A single `--rpc-url` cannot serve a mixed-chain multi-sign request. The pending tx already contains its target chain — pass an RPC for that chain.
- **`--aa-provider` and `--aa-mode` cannot combine with `--eoa`.** They force AA. If the user wants EOA, pass only `--eoa`.

## Skill Structure

```
aomi/
├── SKILL.md                              # This file
├── docs/
│   └── troubleshooting.md                # Full troubleshooting guide (chat, signing, RPC, simulation, AA, quirks)
├── examples/
│   ├── chat-and-sign/README.md           # Lido stake — single-tx flow
│   ├── multi-step-batch/README.md        # Uniswap V3 swap — approve + swap with simulation
│   ├── cross-chain-swap/README.md        # CCTP Ethereum → Base — bridge with attestation
│   └── session-management/README.md      # Resume, recover, cleanup
├── resources/
│   ├── contract-addresses.md             # AA stack + commonly staged protocol contracts
│   ├── error-codes.md                    # CLI error reference with fixes
│   └── supported-apps.md                 # 25+ app catalog with credential requirements
└── templates/
    └── aomi-workflow.sh                  # Reusable bash functions for chat → simulate → sign
```

## Guidelines

1. **Default `--new-session` on the first command of a new task; omit it for follow-up confirmations** in the same flow (the agent loses context otherwise).
2. **Never sign before `aomi tx list` confirms a pending `tx-N`.** A chat response does not always queue a transaction immediately.
3. **Always `aomi tx simulate` before signing a multi-step batch.** Single-tx flows are simulation-optional but never wrong to simulate.
4. **Sign only `Batch [...] passed` txs.** Skip orphans from earlier failed attempts (`failed at step N: 0x...`).
5. **Match `--rpc-url` to the queued tx's chain**, not the session chain (`--chain`). They are independent controls.
6. **Don't retry `--eoa` on L2 `insufficient funds for transfer`** — that path also needs gas. Fix the root cause: fund the EOA, or configure BYOK sponsorship.
7. **Surface drain-vector blocks to the user.** Do not attempt to bypass them by reformulating the prompt.
8. **Never echo credential values back to the user** after a setup command. Confirm with handle name or derived address only.

## References

- [aomi-labs/client on npm](https://www.npmjs.com/package/@aomi-labs/client)
- [aomi.dev](https://aomi.dev) — official docs
- [aomi-labs/skills](https://github.com/aomi-labs/skills) — upstream source for this skill, including [aomi-build](https://github.com/aomi-labs/skills/tree/main/aomi-build) for building new apps from API specs
- [EIP-7702](https://eips.ethereum.org/EIPS/eip-7702) — Set EOA account code
- [ERC-4337](https://eips.ethereum.org/EIPS/eip-4337) — Account Abstraction Using Alt Mempool
- [Alchemy AA stack](https://accountkit.alchemy.com/) — provider for the zero-config AA proxy path
