# Aomi — Agent Skills bundle

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) ![Works with Claude Code · Cursor · Gemini · Codex · Copilot](https://img.shields.io/badge/Works%20with-Claude%20Code%20%C2%B7%20Cursor%20%C2%B7%20Gemini%20%C2%B7%20Codex%20%C2%B7%20Copilot-6E56CF)

> Aomi for AI agents — drive on-chain action and build new app integrations through natural-language prompts. Works with Claude Code, Cursor, Gemini CLI, OpenAI Codex, VS Code Copilot, and any [Agent Skills](https://agentskills.io)–compatible AI tool.

## What's in this bundle

| Skill | Purpose | Risk tier | Audience |
|-------|---------|-----------|----------|
| [`aomi-transact`](skills/transact/SKILL.md) | Drive the Aomi CLI to chat, simulate, and sign on-chain transactions with account-abstraction-first execution. Wraps swaps, lending, bridges, staking, perps, and CEX read across 25+ apps on EVM mainnets and L2s. | **L2** (signs/broadcasts) | End-user / power-user |
| [`aomi-build`](skills/build/SKILL.md) | Scaffold new Aomi apps and plugins from API docs, OpenAPI/Swagger specs, SDK docs, and product requirements. Generates Rust SDK crates with `lib.rs`, `client.rs`, `tool.rs`, plus tool schemas, preambles, and host-interop flows. | **L0** (scaffolds code) | Developer |

The two skills are different audiences and different risk profiles. Bundling means the agent loads only the skill whose description triggers match — there is no token bloat for installing both.

## Install

### Via Claude Code (after Anthropic listing lands)

```bash
/plugin marketplace add anthropics/claude-code
/plugin install aomi
```

### Via Self-hosted marketplace (canonical alternative)

```bash
/plugin marketplace add aomi-labs/skills
/plugin install aomi
```

### Via `gh` extension

```bash
gh extension install ai-ecoverse/gh-upskill
gh upskill aomi-labs/skills --skill aomi
```

### Via direct clone

```bash
git clone https://github.com/aomi-labs/skills
cp -r skills/bundle/aomi ~/.claude/skills/
```

## Prerequisites

```bash
# Required for aomi-transact (the on-chain CLI driver)
npm install -g @aomi-labs/client      # version 0.1.30 or newer
```

`aomi-build` has no runtime prerequisites — it generates Rust source code from specs.

## Usage

Once installed, ask your agent in natural language. The agent picks the right skill based on the prompt:

**Triggers `aomi-transact`:**
- *"What's the price of ETH?"*
- *"Swap 1 USDC for WETH on Uniswap V3, send to my wallet."*
- *"Stake 0.01 ETH with Lido."*
- *"Bridge 50 USDC from Ethereum to Base via CCTP."*

**Triggers `aomi-build`:**
- *"Use aomi-build to turn this OpenAPI spec into an Aomi app."*
- *"Build an Aomi plugin from these REST endpoints."*
- *"Convert this SDK README into an Aomi tool surface."*

## Bundle structure

```
aomi/
├── .claude-plugin/
│   └── plugin.json             # bundle manifest
├── README.md                   # this file
├── LICENSE                     # MIT
├── SECURITY.md                 # bundle-level OWASP AST01–AST10 walkthrough
└── skills/
    ├── transact/
    │   ├── SKILL.md            # main skill
    │   ├── agents/openai.yaml  # Codex/OpenAI host metadata
    │   ├── references/
    │   │   ├── account-abstraction.md
    │   │   ├── apps.md
    │   │   ├── drain-vectors.md
    │   │   ├── examples.md
    │   │   ├── session.md
    │   │   └── troubleshooting.md
    │   └── templates/
    │       └── aomi-workflow.sh
    └── build/
        ├── SKILL.md
        ├── agents/openai.yaml
        ├── references/
        │   ├── aomi-sdk-patterns.md
        │   ├── examples.md
        │   ├── host-routes.md
        │   ├── spec-to-tools.md
        │   └── troubleshooting.md
        └── templates/
            └── quick-scaffold.sh
```

## Security posture

`aomi-transact` ships with a complete [OWASP AST03 (Over-Privileged Skills)](https://owasp.org/www-project-agentic-skills-top-10/ast03) permission manifest in its frontmatter — `risk_tier: L2`, `permissions.{files,network,shell,tools}` declarations. `aomi-build` is `risk_tier: L0` (scaffolds code, no runtime side effects).

The bundle has been scanned by four independent tools: Cisco AI Defense skill-scanner, pors/skill-audit, NMitchem/SkillScan, and Snyk agent-scan. Captured reports live at [`.scanner-reports/`](https://github.com/aomi-labs/skills/tree/main/.scanner-reports) in the repo root. Per-skill OWASP AST01–AST10 walkthroughs are in [`SECURITY.md`](SECURITY.md).

## License

MIT. See [LICENSE](LICENSE).

## Links

- [aomi.dev](https://aomi.dev) — official docs
- [@aomi-labs/client on npm](https://www.npmjs.com/package/@aomi-labs/client) — the CLI `aomi-transact` drives
- [aomi-labs/skills on GitHub](https://github.com/aomi-labs/skills) — upstream
- [aomi-labs/skills issues](https://github.com/aomi-labs/skills/issues) — bug reports & feature requests
- [Aomi on X](https://x.com/aomi_labs)

## About Aomi

Aomi Labs builds the blockchain harness for agentic AI. Execution and settlement across any on-chain protocol or off-chain API — think Claude Code, on-chain. Aomi also hosts agentic applications built and deployed by developers, companies, and the agents themselves. We ship end-to-end: a chat UI, agent Skills, and SDKs in TypeScript and Rust.
