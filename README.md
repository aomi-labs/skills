# Aomi Skills

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE) ![Works with Claude Code · Cursor · Gemini · Copilot](https://img.shields.io/badge/Works%20with-Claude%20Code%20%C2%B7%20Cursor%20%C2%B7%20Gemini%20%C2%B7%20Copilot-6E56CF)

> Agent Skills for Aomi — open-source AI infrastructure for automating crypto. Works with Claude Code, Cursor, Gemini CLI, VS Code Copilot, and other Agent Skills–compatible tools.

## What are Aomi Skills?

Aomi Skills are drop-in Agent Skills that let any Agent Skills–compatible AI tool — Claude Code, Cursor, Gemini CLI, VS Code Copilot, and others — interact with Aomi, open-source AI infrastructure for automating crypto. The `aomi-build` skill scaffolds new Aomi apps and plugins from API specs and SDK docs. The `aomi-transact` skill drives the Aomi CLI through natural language — querying prices and balances, simulating transactions, and signing and broadcasting on-chain swaps and transfers.

## Skills

| Skill | Description |
|-------|-------------|
| [aomi-build](aomi-build/SKILL.md) | Build Aomi apps and plugins from APIs, specs, SDK docs, runtime interfaces, and product requirements |
| [aomi-transact](aomi-transact/SKILL.md) | Build and execute EVM transactions through a conversational AI agent via the `aomi` CLI |

## Use Cases

- **Automate transactions from your AI coding assistant** — ask Claude Code, Cursor, or Gemini CLI to swap, send, stake, or sign EIP-712 payloads via the `aomi` CLI.
- **Scaffold new Aomi plugins from an API spec** — point `aomi-build` at an OpenAPI spec, REST endpoint, or SDK docs and it generates a working Aomi SDK crate (`lib.rs`, `client.rs`, `tool.rs`).
- **Explore on-chain state without a dashboard** — query balances, prices, routes, and quotes right from your AI assistant.
- **Orchestrate multi-step DeFi flows with batch simulation** — simulate approve → swap or bridge → settle sequences before signing, catching reverts before they cost gas.

## Installation

```bash
npx skills add aomi-labs/skills
```

Works with Claude Code, Cursor, Gemini CLI, VS Code Copilot, and any [Agent Skills](https://agentskills.io)-compatible tool.

## Prerequisites

```bash
npm install -g @aomi-labs/client
```

For transaction signing, also install [viem](https://viem.sh):

```bash
npm install -g viem
```

## Usage

Once installed, ask your agent:

- "Use aomi: What's the price of ETH?"
- "Swap 1 ETH for USDC on Uniswap"
- "Send 0.1 ETH to vitalik.eth"

The agent handles the full flow: chat with the backend, review pending transactions, sign and broadcast on-chain.

## FAQ

**Which AI coding tools support Aomi Skills?**
Any Agent Skills–compatible tool: Claude Code, Cursor, Gemini CLI, VS Code Copilot, and others. Install once with `npx skills add aomi-labs/skills` and the skills become available in whichever tool you're using.

**Do I need an Aomi account or API key?**
For the default app and most public data queries, no. For non-default apps and private flows, you'll need an `AOMI_API_KEY` — pass it with `--api-key` or set it as an environment variable. Provider-specific credentials (e.g., exchange keys, bundler keys) can be injected per-session via `aomi secret add`.

**How is this different from an MCP server?**
Agent Skills are lightweight instructions and tool references that live inside your AI tool's context. MCP servers are long-running external processes exposing a protocol. The `aomi-transact` skill drives the `aomi` CLI — each command starts, runs, and exits — so there's no server to manage. You can use Aomi Skills alongside MCP servers; they don't conflict.

**Can I use these skills without signing transactions?**
Yes. `aomi-transact` has a read-only mode — `aomi chat "what's the price of ETH?"`, `aomi tx list`, `aomi tx simulate`, balance and portfolio queries all work without any signing key. A signing key is only needed when you want to broadcast a transaction on-chain.

**Which chains does `aomi-transact` support?**
Ethereum, Polygon, Arbitrum, Base, Optimism, and Sepolia (testnet). Set the active chain with `--chain <id>` or the `AOMI_CHAIN_ID` env var. Each signing invocation needs an RPC URL that matches the target chain.

**How do I update to the latest version of the skills?**
Re-run `npx skills add aomi-labs/skills`. Re-running pulls the latest skill definitions and overwrites the local copies.

## Resources

- [@aomi-labs/client on npm](https://www.npmjs.com/package/@aomi-labs/client)
- [Aomi](https://github.com/aomi-labs/aomi)
- [Agent Skills Spec](https://agentskills.io)
