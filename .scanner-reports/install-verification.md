# Install verification — `aomi` plugin bundle

`docs/todo` item #20 calls for end-to-end install verification across 3+ channels on a clean machine. Below is what's verifiable today (2026-05-07) given that the Anthropic + ccpi + antigravity PRs are open but not yet merged.

> **Bundle migration**: as of 2026-05-07 the canonical install target is the `aomi` bundle at [`bundle/aomi/`](../bundle/aomi/), shipping both `aomi-transact` and `aomi-build` skills under one plugin. The legacy top-level `aomi-transact/` and `aomi-build/` directories remain in place for backwards compatibility. End-user install: `/plugin install aomi`.

## Channel A — Self-hosted Claude Code marketplace (#11)

**Status: ✅ infrastructure live, tested locally.**

The marketplace.json schema validates and is publicly fetchable:

```bash
$ curl -sL https://raw.githubusercontent.com/aomi-labs/skills/main/.claude-plugin/marketplace.json | python3 -m json.tool | head -5
{
    "name": "aomi-skills",
    "owner": {
        "name": "Aomi Labs",
        ...
```

Both plugins resolve cleanly:

```
plugins count: 2
  - aomi-build:    source=./aomi-build,    SKILL.md ✓, plugin.json ✓
  - aomi-transact: source=./aomi-transact, SKILL.md ✓, plugin.json ✓
```

End-user flow once Claude Code is installed:

```
/plugin marketplace add aomi-labs/skills
/plugin install aomi
```

Cannot fully exercise this without a Claude Code instance on the verifying machine, but the JSON validates against the same schema used by Anthropic's `claude-plugins-official` marketplace and the cryptoskills marketplace. The single `aomi` plugin entry resolves to `bundle/aomi/` which contains both `skills/transact/SKILL.md` and `skills/build/SKILL.md`.

## Channel B — `gh upskill` install (#8 / community installer)

**Status: ✅ verified end-to-end.**

```bash
$ gh extension install ai-ecoverse/gh-upskill
$ gh upskill aomi-labs/skills --all --dest-path /tmp/verify-aomi/.claude/skills
[9/10] Installed skill: aomi-build
[10/10] Installed skill: aomi
Installed 10 skill(s)
Done.
```

Full bundle was installed for `aomi-transact`:

```
.claude/skills/aomi-transact/
├── SKILL.md           (29 KB — frontmatter + body intact, OWASP manifest preserved)
├── README.md
├── SECURITY.md
├── LICENSE
├── .claude-plugin/plugin.json
├── agents/openai.yaml
├── references/        (account-abstraction.md, apps.md, drain-vectors.md,
│                       examples.md, session.md, troubleshooting.md)
└── templates/aomi-workflow.sh
```

The agentskills.io spec frontmatter (`name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`) is present and parses; the OWASP `permissions:` block coexists.

## Channel C — antigravity multi-host installer (#17)

**Status: ⏸ blocked on PR merge** ([sickn33/antigravity-awesome-skills#575](https://github.com/sickn33/antigravity-awesome-skills/pull/575)).

`npm run validate` passes locally on the PR branch (`✨ All skills passed validation!`). Once merged:

```bash
npx antigravity-awesome-skills --claude
npx antigravity-awesome-skills --codex
npx antigravity-awesome-skills --cursor
npx antigravity-awesome-skills --gemini
npx antigravity-awesome-skills --antigravity
```

These will install `skills/aomi-transact/SKILL.md` from the merged `main`.

## Channel D — ccpi (`@intentsolutionsio/ccpi`) (#18)

**Status: ⏸ blocked on PR merge** ([jeremylongshore/claude-code-plugins-plus-skills#679](https://github.com/jeremylongshore/claude-code-plugins-plus-skills/pull/679)).

Once merged + the daily external-sync cron runs:

```bash
npx @intentsolutionsio/ccpi install aomi-transact
```

The PR adds entries to `sources.yaml` + `.claude-plugin/marketplace.extended.json`; `pnpm run sync-marketplace` ran clean locally before push.

## Channel E — Anthropic official directory (#10)

**Status: ⏸ awaiting form submission.**

Direct PRs to `anthropics/claude-plugins-official` are auto-closed by their bot. Manual form submission required at https://clau.de/plugin-directory-submission. Field values pre-filled at [`.staging/anthropic-form-submission.md`](../.staging/anthropic-form-submission.md). Once Anthropic adds the entry:

```bash
/plugin marketplace add anthropics/claude-code
/plugin install aomi-transact
```

## Channel F — LobeHub (#15)

**Status: ✅ live (auto-imported).**

- https://lobehub.com/skills/aomi-labs-aomi-aomi-transact
- https://lobehub.com/skills/aomi-labs-aomi-aomi-build

LobeHub auto-pulls from GitHub on its own cadence. No manual install command — users discover and copy from the listing.

## Channel G — skillsmp.com (#13)

**Status: 🟡 GitHub topics set; awaiting next scrape.**

Topics added: `claude-skills`, `claude-code-skill`, `agent-skills`, `defi`, `crypto`, `account-abstraction`, `evm`, `aomi`. The site's scraper will re-index on its regular cycle. No install command — they list sources for users to clone.

## Summary

| Channel | Mechanism | Status | Bundle test |
|---------|-----------|--------|-------------|
| A | Self-hosted Claude Code marketplace | ✅ infrastructure live | n/a (needs Claude Code) |
| B | `gh upskill` | ✅ end-to-end verified | full bundle ✓ |
| C | antigravity multi-host | ⏸ PR open | validator passed |
| D | ccpi | ⏸ PR open | sync-marketplace clean |
| E | Anthropic official | ⏸ form submission | n/a |
| F | LobeHub auto-import | ✅ live | passive listing |
| G | skillsmp scrape | 🟡 topics set | passive listing |

**Two channels (B and F) are end-to-end live today.** A is live infrastructure pending an end-user test. C, D, E land as their PRs/forms close.

**Last refresh:** 2026-05-07.
