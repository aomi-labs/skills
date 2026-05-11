# Anthropic Plugin Directory submission — aomi (bundle)

> **Manual step**: open [https://clau.de/plugin-directory-submission](https://clau.de/plugin-directory-submission) in a browser and paste the field values below. Direct PRs to `anthropics/claude-plugins-official` are auto-closed by their bot — the form is the only path.

---

## Form fields

### Plugin name

```
aomi
```

### Plugin description

```
Aomi for AI agents — drive the Aomi CLI from natural-language prompts (chat, simulate, sign on-chain transactions with account-abstraction-first execution) and scaffold new Aomi apps from API specs. Bundle ships two skills: aomi-transact (run on-chain across 40+ DeFi/perps/CEX/social apps on EVM mainnets and L2s) and aomi-build (scaffold Rust SDK crates from OpenAPI/Swagger specs).
```

### Repository / source URL

```
https://github.com/aomi-labs/skills
```

### Path inside the repo (if asked)

```
plugins/aomi
```

### Plugin manifest path (if asked)

```
plugins/aomi/.claude-plugin/plugin.json
```

### Author / maintainer

- **Name:** aomi-labs
- **URL:** https://aomi.dev
- **Contact email:** info@aomi.dev (or whichever address is canonical)
- **Twitter:** https://x.com/aomi_labs

### License

```
MIT
```

### Category (their existing categories — pick one)

`productivity` is the safest existing bucket for now (no `crypto`/`finance` exists yet — closest fit). `development` is also defensible if framed as a developer tool.

```
productivity
```

### Homepage

```
https://github.com/aomi-labs/skills/tree/main/aomi-transact
```

### Tags / keywords (if a free-text field)

```
aomi, ai-agents, account-abstraction, intent, natural-language, transactions, simulation, evm, defi, cli
```

### Anything else / notes (if there's a free-text "Notes for reviewer" field)

```
The aomi plugin bundle ships two skills, structured per the canonical Anthropic
plugin shape (Helius pattern):

  plugins/aomi/
  ├── .claude-plugin/plugin.json
  ├── README.md
  ├── LICENSE
  ├── SECURITY.md
  └── skills/
      ├── transact/SKILL.md   — drive the Aomi CLI for on-chain transactions
      └── build/SKILL.md      — scaffold new Aomi apps from API specs

Both skills drive the @aomi-labs/client CLI (npm) — each `aomi <subcommand>`
invocation starts, runs, and exits. No long-running process or MCP server.

Risk profile:
  - aomi-transact: risk_tier L2 (signs/broadcasts on-chain transactions). Full
    OWASP AST03 permission manifest in skills/transact/SKILL.md frontmatter:
    permissions.{files, network, shell, tools} declared, network allowlist
    pins api.aomi.dev, shell argv prefixes pin `aomi` and
    `npx @aomi-labs/client@0.1.30`.
  - aomi-build: risk_tier L1 (scaffolds Rust source code; no runtime side
    effects, no network).

Per-skill SECURITY.md files map controls against OWASP AST01–AST10.

Captured scanner reports for both skills (Cisco AI Defense skill-scanner,
pors/skill-audit, NMitchem/SkillScan, Snyk agent-scan) live at
.scanner-reports/ in the source repo. CI workflow at
.github/workflows/skill-audit.yml runs Cisco + pors against both skills on
every PR with SARIF upload to the GitHub Security tab.

Closest existing entry in the marketplace is `helius` (Solana). The aomi
bundle would be the second on-chain plugin and the first multi-skill bundle
covering both end-user (transact) and developer (build) audiences.

Suggested ref pin: `main` initially; happy to move to a tagged release
(e.g. `v0.10`) once we cut one.
```

---

## What submitting will trigger

Per agent research:

1. The form posts to internal Anthropic triage.
2. An Anthropic team member files the PR on `anthropics/claude-plugins-official` from an internal branch.
3. CI runs `validate-marketplace.ts` and `check-marketplace-sorted.ts`.
4. If the entry passes, the PR merges and `bump-plugin-shas.yml` resolves the deterministic SHA from `main` (or a tag if we provide one).

If the form rejects or sits, the same content can be re-submitted — there's no fork+PR path.
