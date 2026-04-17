---
name: aomi
description: >-
  On-chain AI transaction builder for EVM. Use when swapping tokens, sending
  transactions, signing and broadcasting onchain actions, or building Aomi
  apps and plugins from APIs, specs, SDK docs, and runtime interfaces.
  Trigger phrases: swap, send, sign, broadcast, build, scaffold, plugin,
  transaction builder, EVM, agent workflow.
license: Apache-2.0
compatibility: Claude Code, Cursor, Gemini CLI, VS Code Copilot
metadata:
  author: aomi-labs
  version: "1.0"
  chain: multichain
  category: AI Agents
tags:
  - aomi
  - evm
  - transactions
  - swaps
  - build
  - transact
---

# Aomi

Aomi is an on-chain AI transaction builder for EVM.

Use `aomi-transact` when the job is to inspect, prepare, simulate, sign, or broadcast wallet actions. Use `aomi-build` when the job is to turn specs, SDK docs, or runtime interfaces into Aomi apps and plugins.

Aomi is protocol-agnostic at the surface and workflow-specific underneath. The skill does not pretend to be a single protocol guide. It helps agents execute real EVM work safely, with explicit review steps, clear confirmations, and a strong bias toward readable, user-friendly transaction flows.

This skill is for cases where an agent needs to do real work onchain, not just summarize docs.

## What You Probably Got Wrong

- **Aomi is not a protocol** → It is a transaction builder and app builder for EVM workflows.
- **Aomi is not Polymarket-specific** → It should work across EVM actions, not one market vertical.
- **Aomi is not just a CLI wrapper** → It includes both transact and build workflows.
- **A skill can be one markdown file** → CryptoSkills expects a richer package with examples, troubleshooting, resources, and a template.
- **Any EVM action is safe to auto-execute** → Never skip review, simulation, or confirmation for wallet actions.
- **All prompts are equivalent** → Good prompts name the chain, asset, amount, destination, and expected outcome.
- **A build request is the same as a write request** → Build tasks scaffold code and specs; transact tasks move value.
- **Chain-agnostic means address-free** → Even chain-agnostic skills need concrete address references for examples and troubleshooting.

## Quick Start

Install the Aomi skill and its runtime client:

```bash
npx skills add aomi-labs/skills
npm install -g @aomi-labs/client
npm install -g viem
```

Use Aomi when you want to say things like:

- "Swap 1 ETH for USDC on Uniswap"
- "Send 0.1 ETH to vitalik.eth"
- "Review and sign the queued transaction"
- "Build an Aomi app from this API spec"
- "Turn these docs into a plugin scaffold"

Aomi should respond with a clear action flow, not a dump of raw protocol noise.

## Core Concepts

### 1. Transaction intent

Aomi converts a human request into a concrete wallet action. The important details are:

- chain
- asset
- amount
- destination
- slippage or deadline when relevant
- whether the action is read-only, preparatory, or executable

### 2. Review before action

For anything that moves funds or signs data:

- inspect the route
- confirm the chain
- check the recipient
- check the amount
- review any approvals
- simulate first when the flow has multiple steps

### 3. Exactness matters

Agents should preserve:

- token symbols
- contract addresses
- chain IDs
- route selection
- signing mode
- deadlines
- slippage bounds

### 4. Two sub-skills, two jobs

- `aomi-transact` handles wallet and execution flows.
- `aomi-build` handles scaffolding, integration, and plugin generation.

Do not blend them together in a way that hides the actual job.

### 5. EVM first

This skill is centered on EVM-compatible work:

- Ethereum
- Base
- Arbitrum
- Optimism
- Polygon
- and other EVM chains where the integration is stable

### 6. Conversational execution

The best prompts are short, specific, and intention-rich.

Examples:

- "Send 0.25 ETH to this wallet"
- "Swap USDC for ETH with low slippage"
- "Build the plugin from this OpenAPI spec"
- "Review the pending transaction and tell me what it does"

## Workflow

### A. Transaction workflow

1. Parse the user request.
2. Identify the chain and asset pair.
3. Determine whether any approvals are needed.
4. Build the route or transaction request.
5. Review the request in plain language.
6. Simulate multi-step flows.
7. Sign only after the user confirms.
8. Broadcast.
9. Verify the result.

### B. Build workflow

1. Identify the target product surface.
2. Confirm the source of truth.
3. Map the real callable interface.
4. Decide the smallest useful tool surface.
5. Scaffold the Aomi app or plugin.
6. Normalize inputs and outputs.
7. Add any needed tests.
8. Validate against the real target.

### C. What to ask for when details are missing

If the user omits a critical input, ask for the smallest missing piece:

- chain ID
- token symbol or address
- amount
- recipient
- app target
- RPC URL
- signing mode

Do not invent missing values when they matter.

## Common Patterns

### Pattern 1: Send value

Use this when the user wants to move ETH or another token to a destination address or ENS name.

Checklist:

- confirm chain
- confirm recipient
- confirm amount
- confirm token type
- confirm whether the destination is an address or ENS name
- check whether gas is available

Example prompt:

```text
Send 0.1 ETH to vitalik.eth on Ethereum.
```

### Pattern 2: Swap tokens

Use this when the user wants to exchange one token for another through a router or aggregator.

Checklist:

- confirm source token
- confirm destination token
- confirm amount
- confirm slippage tolerance
- confirm chain
- check whether approval is needed

Example prompt:

```text
Swap 1 ETH for USDC on Base with tight slippage.
```

### Pattern 3: Sign and broadcast

Use this when the user already has a queued request and wants the agent to finalize it.

Checklist:

- identify the transaction request ID
- simulate if the flow has dependencies
- sign with the right mode
- broadcast
- verify the final state

Example prompt:

```text
Sign the queued request and broadcast it.
```

### Pattern 4: Build an app or plugin

Use this when the user wants code, not a transaction.

Checklist:

- identify the source of truth
- decide whether the target is a service, SDK, repo, or docs set
- choose the smallest useful tool surface
- scaffold the app or plugin
- normalize the outputs
- validate with a representative flow

Example prompt:

```text
Build an Aomi plugin from these API docs.
```

## Contract Addresses

Always use `resources/contract-addresses.md` for the concrete addresses used in examples.

Guidelines:

- keep the table scoped to the examples in this package
- include chain labels
- include the verification date
- prefer checksummed addresses
- note the source of truth for each address
- update the resource when examples change

Aomi itself is chain-agnostic, but examples are not. Examples need real addresses.

## Error Handling

Aomi should explain failures in a useful way.

Common failure classes:

- wrong chain
- insufficient balance
- approval missing
- quote expired
- slippage exceeded
- signature rejected
- RPC unavailable
- route reverted
- invalid recipient
- unsupported token

When a failure happens:

- say what failed
- say why it likely failed
- say what to change
- say whether the request can be retried as-is

Do not surface raw opaque payloads unless the user asks for them.

## Security and Best Practices

- Never skip confirmation for wallet-signing flows.
- Never hide the recipient or contract behind vague language.
- Never make slippage or deadline assumptions silently.
- Always prefer simulation before signing when multiple steps depend on state.
- Always confirm chain ID before broadcast.
- Prefer explicit token addresses when ambiguity exists.
- Keep secrets out of logs and examples.
- Do not pretend a write succeeded until the broadcast or submit step completes.
- Treat approvals as separate risk-bearing actions.
- Prefer the smallest sufficient approval or permission scope.
- Explain whether a prompt is read-only, preparatory, or executable.
- Use clear names for the two sub-skills so the user understands the split.

## Skill Structure

The CryptoSkills submission should be organized as:

```text
skills/aomi/
├── SKILL.md
├── docs/
│   └── troubleshooting.md
├── examples/
│   ├── send-eth/
│   │   └── README.md
│   ├── swap-erc20/
│   │   └── README.md
│   ├── build-plugin/
│   │   └── README.md
│   └── review-sign-broadcast/
│       └── README.md
├── resources/
│   ├── contract-addresses.md
│   └── error-codes.md
└── templates/
    └── aomi-client.ts
```

This package should be complete on its own. Do not rely on hidden local files.

## Guidelines

- Keep the top of the file focused on the user job.
- Put the most important use cases before the edge cases.
- Use the exact chain name when it matters.
- Use token symbols only when they are unambiguous.
- Use addresses when ambiguity would cause a mistake.
- Keep examples runnable.
- Keep troubleshooting concrete.
- Keep error messages short and actionable.
- Keep the build template small enough to adapt.
- Keep the content aligned with the live shipped product.
- Keep the skill about EVM execution and Aomi app building.
- Keep Polymarket-specific language out unless it is part of a real example.

## References

Primary references used for this skill:

- Aomi GitHub repo
- Aomi npm client package
- Aomi launch article
- Aomi announcement post
- Aomi widget examples
- official protocol and SDK docs used by the examples

When in doubt, prefer the live shipped product over older drafts.
