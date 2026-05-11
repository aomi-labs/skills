# clawhub.ai — `aomi-transact` (skill) submission

> **What this is**: ClawHub is the OpenClaw ecosystem's primary skill registry — open community submissions, gated only by GitHub-account-age ≥ 1 week + automated security scan. ~180k users, ~52.7k tools indexed. Recognized by other registries (cryptoskill.org install instructions cite `clawhub install <slug>` as a supported path; gh-upskill supports `clawhub:<slug>` URI scheme).
>
> **Why submit as a skill, not a plugin**: ClawHub's skill format is a folder with a SKILL.md — our `plugins/aomi/skills/transact/` directory works as-is. The plugin (package) format requires a `package.json` with an `openclaw.{extensions, runtimeExtensions, compat, build}` schema we don't have. Skill submission is zero-effort; plugin submission would require authoring a real package.json schema.
>
> **Two paths to submit**: CLI (recommended for repeatability) or web upload (drag-and-drop folder/zip/tgz at clawhub.ai/publish-skill).

---

## Path A — CLI (recommended)

```bash
# One-time setup
npm install -g clawhub
clawhub login          # opens https://clawhub.ai/cli/auth, GitHub OAuth

# Verify the GitHub account you're signing in with is ≥ 1 week old —
# new accounts are blocked from publishing.

# From the repo root:
cd /Users/cecilia/Code/aomi-skill

clawhub skill publish ./plugins/aomi/skills/transact \
  --slug aomi-transact \
  --name "Aomi Transact" \
  --version 0.10.0 \
  --changelog "Initial release: drive the Aomi CLI from natural-language prompts with account-abstraction-first execution and simulate-then-sign across 40+ DeFi/perps/CEX/social apps on EVM mainnets and L2s." \
  --tags "defi,crypto,web3,account-abstraction,evm,wallet,trading,intent,cli,natural-language,agent"
```

If you need to re-publish, bump `--version` (semver) and add a changelog entry.

## Path B — Web upload

1. Open [clawhub.ai/publish-skill](https://clawhub.ai/publish-skill) → sign in with GitHub
2. Either:
   - **Drag the folder**: `plugins/aomi/skills/transact/` (the directory containing SKILL.md)
   - **Or upload a zip**: `cd plugins/aomi/skills && zip -r aomi-transact.zip transact && open .` then drag the zip
3. ClawHub auto-inspects and prefills the form from SKILL.md frontmatter
4. Confirm the prefilled fields (override below as needed) and submit

## Form field values (override prefill if needed)

| Field | Value |
|---|---|
| **Slug** | `aomi-transact` |
| **Name** | Aomi Transact |
| **Version** | 0.10.0 |
| **License** | MIT |
| **Tags** | `defi`, `crypto`, `web3`, `account-abstraction`, `evm`, `wallet`, `trading`, `intent`, `cli`, `natural-language`, `agent` |
| **Summary / one-liner** | Drive the Aomi CLI from natural-language prompts: chat → simulate → sign EVM transactions with account-abstraction-first execution. 40+ tuned protocol apps. |
| **Description** | (paste the Tier 2 short — see `submission-desc.md` § "aomi-transact (short)" — ~700 chars) |
| **Source / homepage** | https://github.com/aomi-labs/skills/tree/main/plugins/aomi/skills/transact |
| **Repository** | https://github.com/aomi-labs/skills |

## What ClawHub will do post-submission

1. Automated security scan (the registry's own checks — separate from our captured Cisco/pors/SkillScan/Snyk reports)
2. Listing stays private until checks complete
3. On approval: appears in the public catalog, installable via `clawhub install aomi-transact`

## About Aomi (paste verbatim if a free-text "About the author" field exists)

Aomi Labs builds native harness around blockchains functioning like Claude Code on-chain. We specialize in executions against arbitrary protocol with non-custodial workflow, account abstraction, and full security with simulations. Aomi also host agentic applications deployed and owned by developers, companies, and agents. Aomi provides E2E integration with UI, Skills and SDKs.

**Links:**
- 🌐 Website: [aomi.dev](https://aomi.dev)
- 🤖 Agents: [aomi.dev/agents](https://aomi.dev/agents)
- 𝕏 Twitter: [x.com/aomi_labs](https://x.com/aomi_labs)
- 💻 GitHub: [github.com/aomi-labs](https://github.com/aomi-labs)
- 📦 Packages:
  - [@aomi-labs/react](https://www.npmjs.com/package/@aomi-labs/react)
  - [aomi-sdk](https://crates.io/crates/aomi-sdk)
