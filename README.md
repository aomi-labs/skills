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

## Resources

- [@aomi-labs/client on npm](https://www.npmjs.com/package/@aomi-labs/client)
- [Aomi](https://github.com/aomi-labs/aomi)
- [Agent Skills Spec](https://agentskills.io)
