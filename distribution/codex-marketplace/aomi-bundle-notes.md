# codex-marketplace.com — `aomi` (bundle) submission

> **Manual step**: open [codex-marketplace.com](https://codex-marketplace.com) → Submit Plugin form, paste the field values below.
>
> **What this is**: codex-marketplace.com is a third-party Codex plugin directory ("Not affiliated with OpenAI" per their footer). Submission is open and uses automated review + manual review for ambiguous cases. They take a GitHub repo URL or tree URL plus auto-validate the `.codex-plugin/plugin.json` manifest.
>
> **Why this submission first**: this is the canonical bundled form, matching the Helius / Anthropic plugin pattern. The legacy single-skill submissions are optional follow-ups.

---

## Form fields

### GitHub repository URL

```
https://github.com/aomi-labs/skills/tree/main/plugins/aomi
```

(Or just `https://github.com/aomi-labs/skills` if their form auto-discovers the plugin path from `.codex-plugin/plugin.json` location — try the tree URL first; fall back to repo URL if rejected.)

### Plugin name (auto-detected from manifest)

```
aomi
```

### Plugin description

```
Aomi for AI agents — drive the Aomi CLI from natural-language prompts (chat, simulate, sign on-chain transactions with account-abstraction-first execution) and scaffold new Aomi apps from API specs. Bundle ships two skills: aomi-transact (run on-chain across 40+ DeFi/perps/CEX/social apps on EVM mainnets and L2s) and aomi-build (scaffold Rust SDK crates from OpenAPI/Swagger specs).
```

### Author

- **Name:** Aomi Labs
- **URL:** https://aomi.dev
- **Email:** info@aomi.dev

### Homepage

```
https://aomi.dev
```

### License

```
MIT
```

### Tags / keywords (if free-text field)

```
aomi, ai-agents, account-abstraction, intent, natural-language, transactions, simulation, evm, defi, cli, sdk, scaffold, openapi, rust, code-generation
```

### Category (if asked)

The site has its own taxonomy — pick whichever fits best, with `AI Agents` or `DeFi` / `Web3` / `Crypto` as preferred fallbacks. If only one category allowed, use **AI Agents**.

### Notes for reviewer (if free-text field)

```
Aomi is the native harness for blockchains in agentic AI — think Claude Code on-chain.

The bundle ships two skills under one plugin (canonical Anthropic/Helius pattern):
  - aomi-transact: signs and broadcasts on-chain transactions via natural-
    language prompts; risk_tier L2; full OWASP AST03 permission manifest in the
    SKILL.md frontmatter.
  - aomi-build: scaffolds new Aomi apps (Rust SDK crates) from API docs and
    OpenAPI/Swagger specs; risk_tier L1 (writes source code, no runtime side
    effects).

Bundle layout (matches Codex plugin spec — skills under skills/<name>/SKILL.md):
  plugins/aomi/
  ├── .codex-plugin/plugin.json
  ├── .claude-plugin/plugin.json
  ├── README.md, LICENSE, SECURITY.md
  └── skills/
      ├── transact/SKILL.md  (+ agents/openai.yaml, references/, templates/)
      └── build/SKILL.md     (+ agents/openai.yaml, references/, templates/)

Per-skill `agents/openai.yaml` provides Codex/OpenAI host UI metadata (display
name, short description, default prompt).

Independent security scanning (reports captured at .scanner-reports/ in the
source repo):
  - Cisco AI Defense skill-scanner: PASS, 0 findings on both skills
  - NMitchem/SkillScan: PASS — transact 2.0/10 (only the known upstream MCP_001
    regex bug), build 0.0/10
  - pors/skill-audit: clean
  - Snyk agent-scan: PASS (advisory) with 4 W-codes documented as
    characterizations of intentional risk surface (W007/W009/W011/W012),
    mitigations in SECURITY.md

Already submitted to other Claude Code marketplaces: anthropics' community
marketplace (in flight), antigravity-awesome-skills (PR #575), ccpi (PR #679),
cryptoskills.dev (PR #21), cryptoskill.org (issue #36), LobeHub (auto-imported
and live).

The same bundle is being submitted to OpenAI's official Codex Plugin Directory
once their self-serve submission opens — currently flagged "coming soon" in
the Codex docs.
```

---

## About Aomi

Aomi Labs builds native harness around blockchains functioning like Claude Code on-chain. We specialize in executions against arbitrary protocol with non-custodial workflow, account abstraction, and full security with simulations. Aomi also host agentic applications deployed and owned by developers, companies, and agents. Aomi provides E2E integration with UI, Skills and SDKs.

**Links:**
- 🌐 Website: [aomi.dev](https://aomi.dev)
- 🤖 Agents: [aomi.dev/agents](https://aomi.dev/agents)
- 𝕏 Twitter: [x.com/aomi_labs](https://x.com/aomi_labs)
- 💻 GitHub: [github.com/aomi-labs](https://github.com/aomi-labs)
- 📦 Packages:
  - [@aomi-labs/react](https://www.npmjs.com/package/@aomi-labs/react)
  - [aomi-sdk](https://crates.io/crates/aomi-sdk)
