# aomi-build

Build [Aomi](https://aomi.dev) apps and plugins from API docs, OpenAPI/Swagger specs, SDK docs, runtime interfaces, and product requirements. Scaffolds Rust SDK crates with `lib.rs`, `client.rs`, and `tool.rs`, plus tool schemas, preambles, host-interop flows, and validation steps.

## What is this?

A drop-in Agent Skill for Claude Code, Cursor, Gemini CLI, VS Code Copilot, OpenAI Codex, and any [Agent Skills](https://agentskills.io)–compatible AI tool. The skill turns specs into Aomi SDK apps that the Aomi backend can serve as agent-callable tools.

## Installation

```bash
git clone https://github.com/aomi-labs/skills
cp -r skills/aomi-build ~/.claude/skills/
```

For other hosts, replace `~/.claude/skills/` with the appropriate skills dir.

## Usage

Once installed, ask your agent:

- *"Use aomi-build to turn this OpenAPI spec into an Aomi app."*
- *"Build an Aomi plugin from these REST endpoints."*
- *"Convert this SDK README into an Aomi tool surface."*

The skill prefers real product integrations over docs-only helpers whenever a callable surface exists.

## Skill structure

```
aomi-build/
├── SKILL.md                     # Main skill
├── LICENSE                      # MIT
├── README.md                    # This file
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest
├── agents/
│   └── openai.yaml              # Codex/OpenAI host metadata
└── references/
    ├── aomi-sdk-patterns.md     # Canonical SDK patterns (lib.rs, client.rs, tool.rs)
    ├── spec-to-tools.md         # Translating specs into tool schemas
    └── ...
```

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

Companion skill: [aomi-transact](../aomi-transact) — drive the Aomi CLI from natural language.
