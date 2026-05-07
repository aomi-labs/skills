# Distribution platform map — `aomi` plugin bundle

Sorted by leverage (Tier 1 first). The "Shape" column signals whether the platform prefers a **comprehensive** plugin bundle (`aomi/.claude-plugin/plugin.json` with multiple skills inside) or a **light** per-skill SKILL.md.

> **Bundle shipped 2026-05-07; renamed `bundle/` → `plugins/` 2026-05-08** to satisfy codex-marketplace.com's *"target the repository root plugin or a direct plugins/<name> path"* requirement. Both skills now live at [`plugins/aomi/`](plugins/aomi/) following the canonical Anthropic plugin pattern (Helius reference). End-user install: `/plugin install aomi`. Legacy top-level `aomi-transact/` and `aomi-build/` directories remain in place for backwards compatibility.

## Tier 1 — real reach

| # | Platform | Description | Website | Shape | Other example | Status |
|---|---|---|---|---|---|---|
| 10a | **anthropics/claude-plugins-community** | Anthropic's community marketplace, ~1,920 plugins. Once approved: `/plugin marketplace add anthropics/claude-plugins-community` then `/plugin install aomi@claude-plugins-community` | [platform.claude.com/plugins/submit](https://platform.claude.com/plugins/submit) | **Comprehensive** (bundle) | [defi-skills](https://github.com/anthropics/claude-plugins-community), [helius](https://github.com/helius-labs/core-ai/tree/main/helius-plugin), [0x](https://github.com/anthropics/claude-plugins-community), [circle](https://github.com/anthropics/claude-plugins-community) — ~20 crypto plugins already in community | [x] **Submitted via platform.claude.com/plugins/submit**<br>[ ] Wait for automated security scan + nightly sync into the community marketplace<br>[ ] If review feedback comes back, address it |
| 10b | **anthropics/claude-plugins-official** | Anthropic-curated marketplace, ~55 plugins. Auto-included in Claude Code by default | Same form (decision is server-side) | **Comprehensive** (bundle) | Helius (only third-party crypto entry) | [ ] BD outreach to Anthropic plugin team for "Anthropic Verified" badge consideration — pursue **after** community listing lands and we have install volume |
| 11 | **Self-hosted marketplace.json** at `aomi-labs/skills` | Canonical install path independent of Anthropic curation. `/plugin marketplace add aomi-labs/skills` | [github.com/aomi-labs/skills](https://github.com/aomi-labs/skills) | **Comprehensive** (bundle) | [cryptoskills](https://github.com/0xinit/cryptoskills/blob/main/.claude-plugin/marketplace.json) | [x] Live at `.claude-plugin/marketplace.json` (single `aomi` plugin → `./plugins/aomi`)<br>[x] All meta files in place (plugin.json, README.md, LICENSE, SECURITY.md)<br>[ ] End-user `/plugin install aomi` smoke test on a fresh machine |
| codex | **OpenAI Codex official Plugin Directory** | OpenAI's first-party Codex plugin marketplace. Self-serve submissions "coming soon" per Codex docs | [developers.openai.com/codex/plugins](https://developers.openai.com/codex/plugins) | **Comprehensive** (bundle) | ~20 plugins in directory, all OpenAI-published | [x] `.codex-plugin/plugin.json` authored, ready to submit when self-serve opens<br>[ ] Watch [codex changelog](https://developers.openai.com/codex/changelog) for the launch announcement |
| 17 | **antigravity-awesome-skills** | Multi-host installer; one PR fans out to Claude/Codex/Cursor/Gemini/Antigravity | [github.com/sickn33/antigravity-awesome-skills](https://github.com/sickn33/antigravity-awesome-skills) | **Light** (flat `skills/<name>/SKILL.md`) | [emblemai-crypto-wallet](https://github.com/sickn33/antigravity-awesome-skills/blob/main/skills/emblemai-crypto-wallet/SKILL.md) | [x] PR [#575](https://github.com/sickn33/antigravity-awesome-skills/pull/575) open, validator clean, Tier 0 description (293 chars under their 300 cap), full PR body with marketing pitch + About<br>[ ] Wait on merge |

## Tier 2 — catalog visibility

| # | Platform | Description | Website | Shape | Other example | Status |
|---|---|---|---|---|---|---|
| codex-mp | **codex-marketplace.com** | Third-party Codex plugin directory ("Not affiliated with OpenAI"). PLUGIN, SKILL, HOOK, MARKETPLACE artifact types submitted separately | [codex-marketplace.com](https://codex-marketplace.com) | **Comprehensive** (PLUGIN) + **Light** (SKILL × 2) | (no public catalog browser observed yet) | [x] PLUGIN `aomi` submitted at `plugins/aomi/` (UNDER REVIEW, 2026-05-08 02:38)<br>[x] SKILL `aomi-transact` submitted at `plugins/aomi/skills/transact/` (UNDER REVIEW, 02:40)<br>[x] SKILL `aomi-build` submitted at `plugins/aomi/skills/build/` (UNDER REVIEW, 02:40)<br>[ ] Wait on manual review |
| 18 | **ccpi** (`@intentsolutionsio/ccpi`) | npm-style CLI package manager + plugin marketplace, daily external sync | [github.com/jeremylongshore/claude-code-plugins-plus-skills](https://github.com/jeremylongshore/claude-code-plugins-plus-skills) | **Comprehensive** (plugin bundle) | [blockchain-explorer-cli](https://github.com/jeremylongshore/claude-code-plugins-plus-skills/tree/main/plugins/crypto/blockchain-explorer-cli) | [x] PR [#679](https://github.com/jeremylongshore/claude-code-plugins-plus-skills/pull/679) open with `source_path: plugins/aomi`, sync-marketplace clean, marketing pitch + About in body<br>[ ] Wait on merge + daily cron sync |
| 16 | **cryptoskill.org** | Crypto-specific Claude Code skills index | [cryptoskill.org](https://cryptoskill.org) ([github.com/jiayaoqijia/cryptoskill](https://github.com/jiayaoqijia/cryptoskill)) | **Light** (issue with GitHub URL pointer) | [emblem-vault submission issues](https://github.com/jiayaoqijia/cryptoskill/issues?q=is%3Aissue+vault) | [x] Issue [#36](https://github.com/jiayaoqijia/cryptoskill/issues/36) open, body has marketing pitch + About + real URLs<br>[ ] Wait on maintainer triage |
| Bonus | **cryptoskills.dev** (0xinit) | The richer crypto-skills directory; 10-file enriched format | [cryptoskills.dev](https://cryptoskills.dev) ([github.com/0xinit/cryptoskills](https://github.com/0xinit/cryptoskills)) | **Light enriched** (10-file per-skill) | [brian-api](https://github.com/0xinit/cryptoskills/tree/main/skills/brian-api) — closest analogue (NL→tx) | [x] PR [#21](https://github.com/0xinit/cryptoskills/pull/21) open with all 10 files, validator clean, Tier 3 long-form description (1017 chars), marketing pitch + About in body<br>[ ] Wait on merge |
| 15 | **LobeHub Skills** | Multi-AI agent marketplace, auto-imports from GitHub | [lobehub.com/skills](https://lobehub.com/skills) | **Light** (auto-pulls each SKILL.md) | [coinbase-agentic-wallet-skills-fund](https://lobehub.com/skills/coinbase-agentic-wallet-skills-fund) | [x] **Live** — [aomi-transact](https://lobehub.com/skills/aomi-labs-aomi-aomi-transact), [aomi-build](https://lobehub.com/skills/aomi-labs-aomi-aomi-build)<br>[ ] Visual render check (low priority) |
| 13 | **skillsmp.com** | Auto-indexed Claude/Codex/ChatGPT marketplace. Filter: ≥2 GitHub stars + topic | [skillsmp.com](https://skillsmp.com) | **Light** (auto-index via GitHub topics) | [defi-amm-security](https://skillsmp.com/skills/defi-amm-security), [k3-blockchain-agent](https://skillsmp.com/skills/k3-blockchain-agent) | [x] GitHub topics set (`claude-skills`, `claude-code-skill`, `agent-skills`, `defi`, `crypto`, `account-abstraction`, `evm`, `aomi`)<br>[ ] Wait on next scrape (24–48h), verify listing renders |
| 14 | **agensi.io** | Curated marketplace, manual zip upload, runs their own 8-point scanner | [agensi.io](https://agensi.io) | **Comprehensive** (zip upload) | [defi-autopilot](https://agensi.io/skills/defi-autopilot) — closest analogue | [x] **Live** at [agensi.io/skills/aomi-transact](https://www.agensi.io/skills/aomi-transact)<br>[ ] Visual render check<br>[ ] Submit `aomi-build` as a second listing if relevant |
| 12 | **claudemarketplaces.com** | Discovery/catalog auto-crawled from `skills.sh` | [claudemarketplaces.com](https://claudemarketplaces.com) | **Light** (passive, gated on 500 installs) | (n/a — registry, not skill listings) | [ ] Skip until install volume crosses 500 |
| 19 | **clawhub.ai** (OpenClaw ecosystem) | Open community registry — ~180k users, ~52.7k tools. Submissions gated only by GitHub-account-age ≥ 1 week + automated security scan. Recognized by other registries (cryptoskill.org, gh-upskill `clawhub:<slug>`). Skill format = folder with SKILL.md (zero-effort for us); plugin format requires `package.json` with `openclaw` schema (skip) | [clawhub.ai](https://clawhub.ai) ([CLI: `npm i -g clawhub`](https://www.npmjs.com/package/clawhub)) | **Light** (skill, two submissions) | [`clawdhub`](https://clawhub.ai/steipete/clawdhub) and many SKILL.md-only entries | [ ] **Two skill submissions ready to fire** (manual — needs `clawhub login` browser auth):<br>&nbsp;&nbsp;`clawhub skill publish ./plugins/aomi/skills/transact --slug aomi-transact ...`<br>&nbsp;&nbsp;`clawhub skill publish ./plugins/aomi/skills/build --slug aomi-build ...`<br>[ ] Pre-filled command + flags in `.staging/clawhub-aomi-transact.md` and `.staging/clawhub-aomi-build.md`<br>[ ] Or web upload at [clawhub.ai/publish-skill](https://clawhub.ai/publish-skill) — drag the skill folder |

## Security scanners (in our flow, not registries)

| # | Tool | Status |
|---|---|---|
| 1 | **OWASP AST03 manifest** | [x] Authored in `plugins/aomi/skills/transact/SKILL.md` and legacy `aomi-transact/SKILL.md` (`risk_tier: L2`)<br>[ ] Author L1 manifest for `aomi-build` |
| 2 | **Snyk agent-scan** | [x] **PASS (advisory)** — 4 HIGH classifications of intentional risk surface (W007/W009/W011/W012), per-finding mitigations in `SECURITY.md` |
| 3 | **Cisco AI Defense skill-scanner** | [x] **PASS, 0 findings** on both skills, CI workflow live |
| 4 | **pors/skill-audit** | [x] **PASS** — 0 errors / 4 doc-pattern WARNs, CI workflow live |
| 6 | **NMitchem/SkillScan** | [x] **PASS** — transact Risk 2.0/10 (only the known upstream `MCP_001` regex bug), build 0.0/10 |

## TL;DR — Live pipeline

**Submitted, awaiting review:**
- 🟡 Anthropic community ([platform.claude.com](https://platform.claude.com/plugins/submit) — submitted)
- 🟡 codex-marketplace.com × 3 (PLUGIN + 2 SKILLs UNDER REVIEW)
- 🟡 ccpi PR [#679](https://github.com/jeremylongshore/claude-code-plugins-plus-skills/pull/679)
- 🟡 antigravity PR [#575](https://github.com/sickn33/antigravity-awesome-skills/pull/575)
- 🟡 cryptoskills.dev PR [#21](https://github.com/0xinit/cryptoskills/pull/21)
- 🟡 cryptoskill.org issue [#36](https://github.com/jiayaoqijia/cryptoskill/issues/36)

**Ready to submit (manual, needs login):**
- 🟡 clawhub.ai × 2 — `clawhub skill publish` for `aomi-transact` + `aomi-build`. Commands pre-filled at `.staging/clawhub-aomi-{transact,build}.md`

**Live:**
- ✅ Self-hosted `marketplace.json` at `aomi-labs/skills`
- ✅ LobeHub auto-imported (both skills)
- ✅ agensi.io — [aomi-transact listing](https://www.agensi.io/skills/aomi-transact)

**Passive / waiting:**
- 🟡 skillsmp.com (topics set, awaiting next scrape)
- ⏸ OpenAI Codex official ("coming soon")
- ⏸ Anthropic official tier (BD play, post-community)
- ⏸ claudemarketplaces.com (gated on 500 installs)

---

**Last refresh:** 2026-05-08.
