# aomi-transact

Drive the [Aomi CLI](https://www.npmjs.com/package/@aomi-labs/client) from natural-language prompts: chat → simulate → sign with account-abstraction-first execution. Wraps swaps, lending, bridges, staking, perps, and CEX read across 25+ apps on EVM mainnets and L2s.

## What is this?

A drop-in Agent Skill for Claude Code, Cursor, Gemini CLI, VS Code Copilot, OpenAI Codex, and any [Agent Skills](https://agentskills.io)–compatible AI tool. The skill is shaped as a procedure for the agent to drive the [`@aomi-labs/client`](https://www.npmjs.com/package/@aomi-labs/client) CLI:

> **chat** (intent) → **list** (verify what was queued) → **simulate** (catch reverts before signing) → **sign** (wallet pop) → **verify** (chain-state confirmation)

The user types something like *"swap 1 ETH for USDC on Uniswap"*; the agent picks the right protocol and contract, stages the approve+swap as a batch, simulates it on a forked chain, and returns a queued wallet request. Signing is a separate, explicit step — the wallet only ever sees calldata that already passed simulation.

The CLI is **account-abstraction-first**: by default it signs through a zero-config Alchemy proxy (no provider credentials needed), using EIP-7702 on Ethereum mainnet and ERC-4337 on L2s.

## Installation

### Prerequisites

```bash
npm install -g @aomi-labs/client      # version 0.1.30 or newer
```

(or use `npx @aomi-labs/client@0.1.30 ...` for one-shot invocations.)

### Drop into your agent's skills directory

For Claude Code:

```bash
git clone https://github.com/aomi-labs/skills
cp -r skills/aomi-transact ~/.claude/skills/
```

For Cursor / Codex / Gemini, replace `~/.claude/skills/` with the host's skills directory.

Alternative install paths (after the marketplace registers it):

```bash
gh skill install aomi-labs/skills/aomi-transact     # GitHub CLI
/plugin marketplace add aomi-labs/skills            # Claude Code self-hosted
/plugin install aomi-transact                       #   then install
```

## Usage

Once installed, ask your agent:

- *"What is the price of ETH?"*
- *"Swap 1 USDC for WETH on Uniswap V3, send to my wallet."*
- *"Stake 0.01 ETH with Lido to get stETH."*
- *"Bridge 50 USDC from Ethereum to Base via CCTP."*
- *"Show my Aave positions."*

The agent handles the full flow: chat with the backend, review pending transactions, simulate as a batch on a forked chain, and queue a wallet request for you to sign with `aomi tx sign`.

## Skill structure

```
aomi-transact/
├── SKILL.md                     # Main skill (procedure for the agent)
├── SECURITY.md                  # OWASP AST01–AST10 walkthrough
├── LICENSE                      # MIT
├── README.md                    # This file
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest (Anthropic git-subdir loader)
├── agents/
│   └── openai.yaml              # Codex/OpenAI host metadata
├── references/
│   ├── account-abstraction.md   # AA modes, providers, sponsorship
│   ├── apps.md                  # 25+ app catalog
│   ├── drain-vectors.md         # Per-protocol drain-vector reference
│   ├── examples.md              # End-to-end flow examples (real captures)
│   ├── session.md               # Two-tier storage, lifecycle
│   └── troubleshooting.md       # Chat, signing, RPC, simulation, AA
└── templates/
    └── aomi-workflow.sh         # Reusable bash function library
```

## Security posture

Mapped against [OWASP Agentic Skills Top 10 (v1.0, March 2026)](https://owasp.org/www-project-agentic-skills-top-10/) with a complete `permissions:` manifest in SKILL.md frontmatter, including `risk_tier: L2` (signs/broadcasts on-chain transactions).

Per-control analysis lives in [`SECURITY.md`](SECURITY.md). Captured scanner reports (Cisco AI Defense skill-scanner, pors/skill-audit, NMitchem/SkillScan) live under [`.scanner-reports/`](../.scanner-reports/) at the repo root.

## Hard rules

The skill explicitly forbids:

- **Inventing or echoing credential values.** Credentials only reach the CLI when the user supplies them for a specific command; they are never echoed back.
- **Unsolicited credential setup.** `aomi wallet set`, `aomi secret add`, `--api-key`, `--private-key` are run only when the user explicitly asks and supplies the value.
- **Blind signing.** Multi-step batches go through `aomi tx simulate` on a forked chain before `aomi tx sign`.
- **Drain-vector bypass.** When the agent rejects calldata where `recipient`/`onBehalfOf`/`mintRecipient` ≠ `msg.sender`, the skill surfaces the block to the user rather than reformulating the prompt.

## License

MIT. See [LICENSE](LICENSE).

## About Aomi

Aomi Labs builds the native harness for blockchains, functioning like Claude Code on-chain. We specialize in executions against arbitrary protocols with non-custodial workflow, account abstraction, and full security via fork-chain simulation. Aomi also hosts agentic applications deployed and owned by developers, companies, and the agents themselves. We ship end-to-end: chat UI, agent Skills, and SDKs in TypeScript and Rust.

**Links:**
- 🌐 Website: [aomi.dev](https://aomi.dev)
- 🤖 Agents: [aomi.dev/agents](https://aomi.dev/agents)
- 𝕏 Twitter: [x.com/aomi_labs](https://x.com/aomi_labs)
- 💻 GitHub: [github.com/aomi-labs](https://github.com/aomi-labs)
- 📦 Packages:
  - [@aomi-labs/widget-lib](https://www.npmjs.com/package/@aomi-labs/widget-lib)
  - [@aomi-labs/client](https://www.npmjs.com/package/@aomi-labs/client)
  - [aomi-sdk](https://crates.io/crates/aomi-sdk)

Companion skill: [aomi-build](../aomi-build) — scaffold new Aomi apps from API specs.
