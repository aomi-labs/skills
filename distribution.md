# Distribution platform map — `aomi` plugin bundle

Sorted by leverage (Tier 1 first). The "Shape" column signals whether the platform prefers a **comprehensive** plugin bundle (`aomi/.claude-plugin/plugin.json` with multiple skills inside) or a **light** per-skill SKILL.md.

> **Bundle shipped 2026-05-07.** The two skills are now packaged together at [`bundle/aomi/`](bundle/aomi/) following the canonical Anthropic plugin pattern (Helius reference). End-user install: `/plugin install aomi`. Legacy top-level `aomi-transact/` and `aomi-build/` directories remain in place for backwards compatibility.

## Tier 1 — real reach

| # | Platform | Description | Website | Shape | Other example | Status | Recommended next steps |
|---|---|---|---|---|---|---|---|
| 10 | **anthropics/claude-plugins-official** | Anthropic's curated marketplace; `/plugin marketplace add anthropics/claude-code` is built into Claude Code | [clau.de/plugin-directory-submission](https://clau.de/plugin-directory-submission) | **Comprehensive** (bundle) | [Helius](https://github.com/helius-labs/core-ai/tree/main/helius-plugin) — `helius-plugin/` with `.claude-plugin/plugin.json` + `.mcp.json` + `skills/` + LICENSE + README | [x] Bundle restructured at `bundle/aomi/`<br>[ ] Submit form at clau.de/plugin-directory-submission<br>[ ] Wait for Anthropic engineer to file internal PR<br>[ ] PR merged into `claude-plugins-official` main | [ ] Pre-fill values from `.staging/anthropic-form-submission.md` (bundle path: `bundle/aomi`)<br>[ ] Use category `productivity` (no DeFi exists yet)<br>[ ] Suggest ref pin `main` initially; tagged release `v0.10` available |
| 11 | **Self-hosted marketplace.json** at `aomi-labs/skills` | The canonical install path that doesn't depend on Anthropic curation. Users run `/plugin marketplace add aomi-labs/skills` | [github.com/aomi-labs/skills](https://github.com/aomi-labs/skills) | **Comprehensive** (bundle) | [cryptoskills](https://github.com/0xinit/cryptoskills/blob/main/.claude-plugin/marketplace.json) — single marketplace.json listing 98 plugins | [x] `.claude-plugin/marketplace.json` updated to single `aomi` plugin pointing at `./bundle/aomi`<br>[x] Bundle `.claude-plugin/plugin.json` authored<br>[x] Bundle README.md + LICENSE + SECURITY.md authored<br>[x] Schema validates (1 plugin, resolves to bundle)<br>[ ] End-user `/plugin install aomi` test on a fresh machine | [ ] Add `.mcp.json` if/when we expose an MCP surface<br>[ ] Once stable, consider tagged release pin |
| 17 | **antigravity-awesome-skills** | Multi-host installer; single PR fans out to Claude/Codex/Cursor/Gemini/Antigravity | [github.com/sickn33/antigravity-awesome-skills](https://github.com/sickn33/antigravity-awesome-skills) | **Light** (flat `skills/<name>/SKILL.md`) | [emblemai-crypto-wallet](https://github.com/sickn33/antigravity-awesome-skills/blob/main/skills/emblemai-crypto-wallet/SKILL.md) — flat SKILL.md, `risk: critical`, multi-chain wallet ops | [x] Fork created<br>[x] SKILL.md in their format (`risk: critical`, `source_repo`, etc.)<br>[x] `npm run validate` clean<br>[x] PR [#575](https://github.com/sickn33/antigravity-awesome-skills/pull/575) opened<br>[x] Placeholder syntax fix synced<br>[ ] PR merged | [ ] No change needed — antigravity prefers flat SKILL.md, bundling upstream doesn't affect their copy<br>[ ] If maintainers ask for more, add `aomi-build` as a sibling `skills/aomi-build/SKILL.md` in the same PR |

## Tier 2 — catalog visibility

| # | Platform | Description | Website | Shape | Other example | Status | Recommended next steps |
|---|---|---|---|---|---|---|---|
| 18 | **ccpi** (`@intentsolutionsio/ccpi`) | npm-style CLI package manager + plugin marketplace, daily external sync | [github.com/jeremylongshore/claude-code-plugins-plus-skills](https://github.com/jeremylongshore/claude-code-plugins-plus-skills) | **Comprehensive** (plugin bundle) | [blockchain-explorer-cli](https://github.com/jeremylongshore/claude-code-plugins-plus-skills/tree/main/plugins/crypto/blockchain-explorer-cli) — full plugin under `plugins/crypto/` | [x] Fork created<br>[x] `sources.yaml` entry<br>[x] `marketplace.extended.json` entry<br>[x] `pnpm run sync-marketplace` clean<br>[x] PR [#679](https://github.com/jeremylongshore/claude-code-plugins-plus-skills/pull/679) opened<br>[ ] PR updated to `source_path: bundle/aomi` (in flight)<br>[ ] PR merged<br>[ ] Daily cron syncs the actual plugin content | [x] Push update changing entry name from `aomi-transact` to `aomi` and `source_path` to `bundle/aomi`<br>[ ] Their crypto category will surface the bundle correctly |
| 16 | **cryptoskill.org** | Crypto-specific Claude Code skills index (`ai-crypto`, `defi`, etc.) | [cryptoskill.org](https://cryptoskill.org) ([github.com/jiayaoqijia/cryptoskill](https://github.com/jiayaoqijia/cryptoskill)) | **Light** (issue with GitHub URL pointer) | [emblem-vault skill submission issues](https://github.com/jiayaoqijia/cryptoskill/issues?q=is%3Aissue+vault) | [x] Issue [#36](https://github.com/jiayaoqijia/cryptoskill/issues/36) opened<br>[ ] Maintainer review/triage | [ ] No change needed — issue points at GitHub URL, restructure transparent<br>[ ] If maintainer asks, can add `aomi-build` as a separate issue under `dev-tools` category |
| Bonus | **cryptoskills.dev** (0xinit) | The richer crypto-skills directory (different from cryptoskill.org); 10-file enriched format | [cryptoskills.dev](https://cryptoskills.dev) ([github.com/0xinit/cryptoskills](https://github.com/0xinit/cryptoskills)) | **Light enriched** (10-file per-skill, NOT plugin bundle) | [brian-api](https://github.com/0xinit/cryptoskills/tree/main/skills/brian-api) — closest analogue (NL→tx) with `examples/`, `resources/`, `templates/`, `docs/` | [x] Variant authored at `cryptoskill/aomi/` with all 10 files<br>[x] Validator passes (0 errors)<br>[x] PR [#21](https://github.com/0xinit/cryptoskills/pull/21) opened<br>[ ] PR merged | [ ] No change needed — their format expects per-skill enriched layout, not plugin bundles<br>[ ] Response to reviewer feedback if it comes |
| 15 | **LobeHub Skills** | Multi-AI agent marketplace (LobeHub-centric). Auto-imports from GitHub | [lobehub.com/skills](https://lobehub.com/skills) | **Light** (auto-pulls each SKILL.md) | [coinbase-agentic-wallet-skills-fund](https://lobehub.com/skills/coinbase-agentic-wallet-skills-fund) | [x] Auto-imported, both skills live<br>[x] [aomi-transact listing](https://lobehub.com/skills/aomi-labs-aomi-aomi-transact)<br>[x] [aomi-build listing](https://lobehub.com/skills/aomi-labs-aomi-aomi-build)<br>[ ] Visual render check | [ ] After bundle restructure, paste GitHub URL into LobeHub's "Submit Skill" modal to trigger resync<br>[ ] LobeHub auto-finds new SKILL.md paths regardless of bundle structure |
| 13 | **skillsmp.com** | Auto-indexed Claude/Codex/ChatGPT marketplace. Filter: ≥2 GitHub stars + topic | [skillsmp.com](https://skillsmp.com) | **Light** (auto-index via GitHub topics) | [defi-amm-security](https://skillsmp.com/skills/defi-amm-security), [k3-blockchain-agent](https://skillsmp.com/skills/k3-blockchain-agent) | [x] GitHub topics added (`claude-skills`, `claude-code-skill`, `agent-skills`, `defi`, `crypto`, `account-abstraction`, `evm`, `aomi`)<br>[x] Repo public, MIT license<br>[ ] Awaiting next scrape (24–48h)<br>[ ] Verify listing renders | [ ] No change needed — auto-scrape will find new structure<br>[ ] After bundle merge, may show different slug (`aomi-labs-skills-aomi`); verify and reach out if rendering breaks |
| 14 | **agensi.io** | Curated marketplace, manual zip upload, runs their own 8-point scanner | [agensi.io](https://agensi.io) | **Comprehensive** (zip upload, can include full bundle) | [defi-autopilot](https://agensi.io/skills/defi-autopilot) — closest analogue | [ ] **HARD BLOCK** — sign up at agensi.io<br>[ ] Connect Stripe Connect (required even for free)<br>[ ] Package as zip (after bundle restructure: zip the `aomi/` directory)<br>[ ] Submit via Creator Dashboard<br>[ ] 8-point auto-scan + 24–48h manual review | [ ] **Manual user action required** (account creation + payment connection)<br>[ ] Submit AFTER bundle restructure so the zip contains the canonical bundle<br>[ ] Be ready to point reviewers at `SECURITY.md` W-code mitigation table if they re-flag W007/W009/W011/W012 |
| 12 | **claudemarketplaces.com** | Discovery/catalog auto-crawled from `skills.sh` | [claudemarketplaces.com](https://claudemarketplaces.com) | **Light** (passive, gated) | (n/a — registry, not skill listings) | [ ] **GATED** on 500 installs (premature for new skill)<br>[ ] Email mert@vinena.studio if want to expedite, but unlikely to pre-list | [ ] Skip until install volume crosses 500<br>[ ] Track install count via npm or GitHub clones; revisit when crossed |

## Tier 3 — skip by default

| # | Platform | Description | Website | Shape | Status | Why skip |
|---|---|---|---|---|---|---|
| 19 | **clawhub** (OpenClaw ecosystem) | Third-party skill registry, separate from Claude ecosystem | [clawhub.ai](https://clawhub.ai) | **Light** | [ ] Skip per original plan | Small audience, separate trust hop, third-party ecosystem |

## Security scanners (in our flow, not registries)

| # | Tool | Description | Website | Status | Recommended |
|---|---|---|---|---|---|
| 1 | **OWASP AST03 manifest** | Permission manifest in SKILL.md frontmatter | [owasp.org/www-project-agentic-skills-top-10](https://owasp.org/www-project-agentic-skills-top-10) | [x] Authored, in `aomi-transact/SKILL.md` frontmatter<br>[ ] Author for `aomi-build` (lower `risk_tier: L0`) | [ ] After bundle, lift the manifest to `aomi/.claude-plugin/plugin.json`-level if the spec evolves to plugin-level manifests |
| 2 | **Snyk agent-scan** | Snyk's risk-class scanner | [snyk.com](https://snyk.com) | [x] **PASS (advisory)**, 4 HIGH characterizations, mitigations documented<br>[x] Reports captured at `.scanner-reports/` | [ ] Re-run after bundle restructure to confirm no regression |
| 3 | **Cisco AI Defense skill-scanner** | Static + behavioral analyzer | [github.com/cisco-ai-defense/skill-scanner](https://github.com/cisco-ai-defense/skill-scanner) | [x] **PASS, 0 findings**<br>[x] CI workflow live | [ ] Re-run on bundled form |
| 4 | **pors/skill-audit** | Regex/static scanner with SARIF | [github.com/pors/skill-audit](https://github.com/pors/skill-audit) | [x] **PASS**, 0 errors / 4 doc-pattern WARNs<br>[x] CI workflow live | [ ] Re-run on bundled form |
| 6 | **NMitchem/SkillScan** | Sandboxed runtime test | [github.com/NMitchem/SkillScan](https://github.com/NMitchem/SkillScan) | [x] **PASS, Risk 2.0/10**, 1 upstream-regex-bug HIGH | [ ] Re-run on bundled form<br>[ ] File upstream issue for MCP_001 regex bug |

## TL;DR — Bundle status

**Done (2026-05-07):**

- ✅ Bundle assembled at [`bundle/aomi/`](bundle/aomi/) following the canonical Anthropic plugin shape (Helius reference)
- ✅ Bundle `.claude-plugin/plugin.json`, README.md, LICENSE, SECURITY.md authored
- ✅ Self-hosted `.claude-plugin/marketplace.json` updated — single `aomi` plugin pointing at `./bundle/aomi`
- ✅ Bundle scanned: Cisco SAFE (0 findings), SkillScan PASS (Risk 2.0/10, only the known upstream regex bug HIGH), pors PASS, Snyk PASS (advisory)
- ✅ Anthropic submission form values updated to bundle path (`bundle/aomi`)
- 🟡 ccpi PR #679 update in flight — switching to `source_path: bundle/aomi`

**Still owed:**

- Anthropic form submission (manual, ~2 min)
- agensi.io listing (manual sign-up + Stripe Connect, ~20 min)
- Wait on PR merges (ccpi #679, antigravity #575, cryptoskills.dev #21)

**Comprehensive plugin platforms (Anthropic, Self-hosted, ccpi, agensi)** — these are the channels where bundling matters. **5 out of 11 platforms** benefit directly. The pattern is one repo dir = one plugin = N skills inside.

**Light per-skill platforms (LobeHub, skillsmp, claudemarketplaces, cryptoskills.dev, cryptoskill.org, antigravity)** — these auto-find SKILL.md files individually regardless of parent grouping. Bundle is invisible to them.

---

**Last refresh:** 2026-05-07.
