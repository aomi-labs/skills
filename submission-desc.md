# Submission descriptions — source of truth

This file is the canonical copy for every place that quotes Aomi: SKILL.md frontmatter, plugin.json, marketplace.json catalog cards, PR bodies, submission forms, READMEs, social posts. **When you change the pitch, update this file first**, then run a fan-out to the rest.

**Last updated:** 2026-05-07.

---

## Tone

- **Concrete, not branded.** Lead with what the user does, not adjectives. Examples in code-like quotes: *"swap 1 ETH for USDC"*, *"open a 3x GMX long"*.
- **Trigger-rich.** SKILL.md descriptions get scanned by agents to decide whether to load. Explicit "Trigger when the user wants to..." beats vague capability statements.
- **Protocol-name dense.** Every name (Polymarket, 1inch, GMX, Uniswap, Aave, Hyperliquid) is a search anchor. Drop them in lists, not in prose, so they're scannable.
- **No t.co / shortener URLs.** Real URLs only. Shorteners trip security scanners (Snyk W012 already flags one for `npx`); adding more reduces trust signal.
- **Non-custodial framing is the differentiator.** "Keys never leave the user", "fork-chain simulation before every signature", "wallet handoff" — these distinguish us from custodial agent frameworks.
- **40+ protocol apps.** We're scaling there. If the actual count grows, update this file and propagate. Don't say 25+ anymore.
- **Codex parallel.** Both Anthropic and OpenAI Codex have plugin marketplaces. Anthropic's: split community (broad) + official (curated). OpenAI's: official is "coming soon"; the immediate option is the third-party `codex-marketplace.com`. Our plugin manifest is duplicated into `.claude-plugin/plugin.json` AND `.codex-plugin/plugin.json` per spec — keep both in sync when descriptions change.

## Versions

We ship three description tiers. Pick by audience and char budget.

### Tier 0 — Antigravity-cap (≤ 300 chars)

Antigravity-awesome-skills' validator (`tools/scripts/validate_skills.py:137`) hard-caps `description` at **300 chars**. This tier is specific to that platform.

> Build natural-language crypto/DeFi agents and EVM MCP plugins (Claude Code, Cursor, Codex, Gemini). Aomi turns prompts into wallet-signed txs on Ethereum, Base, Arbitrum, Optimism, Polygon, Linea — non-custodial, fork-simulated. 40+ apps: Uniswap, Aave, Lido, Morpho, GMX, Hyperliquid, Polymarket.

### Tier 1 — Tooltip (≤ 220 chars)

For catalog cards where space is tight.

> Drive natural-language EVM transactions from agents — chat, fork-simulate, sign. Non-custodial, account-abstraction-first, 40+ protocol apps (Polymarket, 1inch, GMX, Hyperliquid, Aave, Uniswap, …). Keys never leave the user.

For the bundle (combining transact + build):

> Aomi for AI agents — drive natural-language EVM transactions (transact) and scaffold new Aomi apps from API specs (build). Non-custodial, fork-simulated, 40+ protocol apps.

### Tier 2 — Short (≤ 700 chars)

For `plugin.json` description, `marketplace.json` catalog entries, ccpi marketplace.extended.json, agensi short blurb.

**aomi-transact (short):**

> The Aomi CLI drives an Aomi runtime that reads and writes EVM chain state: stages calldata, simulates as a batch on a forked chain, and returns wallet requests for the user to sign. Works on any EVM contract via low-level primitives — ABI encoding (encode_and_call), fork-batch simulation (simulate_batch), staged-tx queueing (stage_tx), and wallet handoff with EIP-712 (commit_tx, commit_eip712) — including multi-step swap-approve-execute routing. Ships with 40+ tuned protocol apps (Polymarket, 1inch, Dune, GMX, Binance, Hyperliquid, Kaito, …), each loaded dynamically and tuned to the vendor's full API. Every action simulates first, batches when possible, and is signed by the end-user wallet.

**aomi-build (short):**

> Build new Aomi apps and plugins from API docs, OpenAPI/Swagger specs, SDK docs, runtime interfaces, or product requirements. Aomi-build scaffolds production-ready Rust SDK crates (lib.rs, client.rs, tool.rs) with tool schemas, preambles, host-interop flows, and validation steps — turning a vendor's full API surface into AI-agent-callable tools. Same runtime that aomi-transact drives.

**aomi bundle (short):**

> Aomi for AI agents — drive the Aomi CLI from natural-language prompts (chat, simulate, sign on-chain transactions with account-abstraction-first execution) and scaffold new Aomi apps from API specs. Bundle ships two skills: aomi-transact (run on-chain across 40+ DeFi/perps/CEX/social apps on EVM mainnets and L2s) and aomi-build (scaffold Rust SDK crates from OpenAPI/Swagger specs).

### Tier 3 — Long (≤ 1024 chars per agentskills.io spec)

For `SKILL.md` frontmatter descriptions where agents make trigger decisions, and for the `agensi.io` listing description body.

**aomi-transact (long):**

> Build natural-language crypto agents, web3 assistants, trading bots, blockchain MCPs, or Claude Code / Cursor / Codex / Gemini plugins that read and write EVM chain state. Aomi turns user prompts ("swap 1 ETH for USDC", "open a 3x GMX long", "bet $100 yes on Polymarket") into wallet-signed transactions on Ethereum, Base, Arbitrum, Optimism, Polygon, and Linea — non-custodial, fork-chain simulated.
>
> Trigger when the user wants to scaffold a crypto/DeFi agent, build an AI trading/wallet assistant, wrap an EVM protocol as MCP tools, create natural-language interfaces to Across / 1inch / GMX / Hyperliquid / Polymarket / Binance / OKX, or add on-chain execution to Uniswap / Aave / Lido / Morpho.
>
> The Aomi CLI drives a runtime that reads and writes EVM chain state: stages calldata, fork-simulates as a batch, returns wallet requests for the user to sign. Works on any EVM contract via low-level primitives — encode_and_call, simulate_batch, stage_tx, commit_tx, commit_eip712 — including multi-step swap-approve-execute routing. Ships with 40+ tuned protocol apps. Keys never leave the user.

**aomi-build (long):**

> Build new Aomi apps and plugins from API docs, OpenAPI/Swagger specs, SDK docs, runtime interfaces, or product requirements. Aomi-build scaffolds production-ready Rust SDK crates that turn a vendor's full API surface into AI-agent-callable tools — generated as lib.rs, client.rs, and tool.rs with tool schemas, preambles, host-interop flows, and validation steps.
>
> Trigger when the user wants to scaffold a new Aomi app from an OpenAPI/Swagger spec, wrap a REST API as agent-callable tools, port an existing SDK to Aomi, generate a tool surface from product requirements, or extend an Aomi runtime with new integrations. Prefers real product integrations over docs-only helpers whenever a callable surface exists.
>
> Output crates support sync HTTP, async tools (cancellation-safe via DynAsyncSink), proxy-unwrap (EIP-1967), and host-interop flows that route quote → approval → swap as multi-step transactions. Same runtime that aomi-transact drives.

---

## About section

Use **verbatim** in every README, every PR body that has an "About the author" section, and every form's "Notes for reviewer" field. Real URLs, no t.co.

```markdown
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
```

---

## Where each tier goes

| Surface | Tier | Notes |
|---|---|---|
| `bundle/aomi/.codex-plugin/plugin.json` `description:` | **Short** (bundle) | OpenAI Codex plugin loader reads this |
| Legacy `aomi-{transact,build}/.codex-plugin/plugin.json` | **Short** (per skill) | Mirror until legacy dirs are removed |
| `bundle/aomi/skills/transact/SKILL.md` frontmatter `description:` | **Long** (transact) | Agent triggers fire on this |
| `bundle/aomi/skills/build/SKILL.md` frontmatter `description:` | **Long** (build) | Same |
| Legacy `aomi-transact/SKILL.md` frontmatter | **Long** (transact) | Mirror until legacy dirs are removed |
| Legacy `aomi-build/SKILL.md` frontmatter | **Long** (build) | Same |
| `bundle/aomi/.claude-plugin/plugin.json` `description:` | **Short** (bundle) | Anthropic git-subdir loader reads this |
| `aomi-transact/.claude-plugin/plugin.json` (legacy) | **Short** (transact) | |
| `aomi-build/.claude-plugin/plugin.json` (legacy) | **Short** (build) | |
| Self-hosted `.claude-plugin/marketplace.json` `plugins[].description` | **Short** (bundle) | One entry, points at `./bundle/aomi` |
| Anthropic `claude-plugins-official` form `description` | **Short** (bundle) | Catalog tooltip; brief is better. Realistic landing tier: `claude-plugins-community` (~1,920 plugins). Form: platform.claude.com/plugins/submit |
| Anthropic form "Notes for reviewer" | **Long** (bundle) + scanner summary | Full SEO + risk story |
| codex-marketplace.com form (third-party Codex directory) | **Short** (bundle or per-skill) | Form auto-validates `.codex-plugin/plugin.json`. Submission packets pre-filled at `.staging/codex-marketplace-*.md` |
| OpenAI official Codex Plugin Directory | **Short** (bundle) | Self-serve submissions "coming soon" per OpenAI docs — wait, then mirror Anthropic submission |
| ccpi `sources.yaml` and `marketplace.extended.json` | **Short** (bundle) | Card on tonsofskills.com |
| antigravity PR #575 SKILL.md `description:` | **Long** (transact) | Their `description` field is the agent trigger |
| cryptoskills.dev PR #21 SKILL.md `description:` | **Long** (transact) | Their validator caps at 1024 |
| cryptoskill.org issue #36 body | **Short** (transact) | Maintainer reads once |
| LobeHub auto-import | (auto) | Pulls from upstream SKILL.md frontmatter |
| skillsmp.com auto-index | (auto) | Same |
| agensi.io listing description | **Long** (bundle) | Their listing field is long-form |
| Top-level `README.md` "What" section | **Short** (bundle) + About | Repo landing |
| Per-skill `README.md` "What" sections | **Short** (per skill) + About | Skill landing |

---

## Update protocol

When the pitch shifts (e.g. count goes from 40+ to 60+, new chain added, new flagship protocol):

1. Edit this file first — update the relevant Tier paragraphs.
2. Fan out via:
   - Edit `bundle/aomi/skills/{transact,build}/SKILL.md` frontmatter
   - Edit `aomi-transact/SKILL.md` and `aomi-build/SKILL.md` frontmatter (legacy mirror)
   - Edit `bundle/aomi/.claude-plugin/plugin.json` description
   - Edit `aomi-transact/.claude-plugin/plugin.json` and `aomi-build/.claude-plugin/plugin.json` descriptions (legacy)
   - Edit `.claude-plugin/marketplace.json` plugin entry
   - Edit `bundle/aomi/README.md`, `aomi-transact/README.md`, `aomi-build/README.md`, top-level `README.md` (sync About)
   - Edit `.staging/anthropic-form-submission.md` (form values)
3. Push updates to open external PRs:
   - antigravity PR #575 — update `skills/aomi-transact/SKILL.md` description
   - cryptoskills.dev PR #21 — update `skills/aomi/SKILL.md` description
   - ccpi PR #679 — update `sources.yaml` + `.claude-plugin/marketplace.extended.json`
4. Re-run scanners on bundle: Cisco, pors/skill-audit, NMitchem/SkillScan. Snyk if `SNYK_TOKEN` is set.
5. Commit on `aomi-labs/skills` main with a message that links back to this file.
