# clawhub.ai — `aomi-build` (skill) submission

> See [`clawhub-aomi-transact.md`](clawhub-aomi-transact.md) for the registry's submission flow context — same flow, different folder + slug.

---

## Path A — CLI

```bash
# (Reuse the clawhub login session from the aomi-transact submission)
cd /Users/cecilia/Code/aomi-skill

clawhub skill publish ./plugins/aomi/skills/build \
  --slug aomi-build \
  --name "Aomi Build" \
  --version 0.10.0 \
  --changelog "Initial release: scaffold new Aomi apps and plugins from API docs, OpenAPI/Swagger specs, SDK docs, runtime interfaces, or product requirements. Generates Rust SDK crates with lib.rs, client.rs, tool.rs and full host-interop flows." \
  --tags "aomi,sdk,scaffold,openapi,swagger,rust,code-generation,agent-tools,developer-tools"
```

## Path B — Web upload

1. Open [clawhub.ai/publish-skill](https://clawhub.ai/publish-skill) → sign in with GitHub
2. Drag the folder `plugins/aomi/skills/build/` (or zip it first)
3. Confirm prefilled fields and submit

## Form field values

| Field | Value |
|---|---|
| **Slug** | `aomi-build` |
| **Name** | Aomi Build |
| **Version** | 0.10.0 |
| **License** | MIT |
| **Tags** | `aomi`, `sdk`, `scaffold`, `openapi`, `swagger`, `rust`, `code-generation`, `agent-tools`, `developer-tools` |
| **Summary / one-liner** | Scaffold new Aomi apps from API docs, OpenAPI/Swagger specs, and product requirements. Generates production-ready Rust SDK crates with `lib.rs`, `client.rs`, `tool.rs`. |
| **Description** | (paste the Tier 2 short — see `submission-desc.md` § "aomi-build (short)" — ~400 chars) |
| **Source / homepage** | https://github.com/aomi-labs/skills/tree/main/plugins/aomi/skills/build |
| **Repository** | https://github.com/aomi-labs/skills |

## About Aomi (same block as the aomi-transact packet)

Aomi Labs builds native harness around blockchains functioning like Claude Code on-chain. We specialize in executions against arbitrary protocol with non-custodial workflow, account abstraction, and full security with simulations. Aomi also host agentic applications deployed and owned by developers, companies, and agents. Aomi provides E2E integration with UI, Skills and SDKs.

**Links:**
- 🌐 Website: [aomi.dev](https://aomi.dev)
- 🤖 Agents: [aomi.dev/agents](https://aomi.dev/agents)
- 𝕏 Twitter: [x.com/aomi_labs](https://x.com/aomi_labs)
- 💻 GitHub: [github.com/aomi-labs](https://github.com/aomi-labs)
- 📦 Packages:
  - [@aomi-labs/react](https://www.npmjs.com/package/@aomi-labs/react)
  - [aomi-sdk](https://crates.io/crates/aomi-sdk)
