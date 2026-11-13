# Aomi distribution

The canonical plugin is `plugins/aomi`, with transaction skill/plugin version
`0.14.1` and build skill `0.1.1`. Install the CLI separately with
`npm install -g @aomi-labs/cli@latest`. `@aomi-labs/client` is the TypeScript SDK.

## Public URLs

| Purpose | URL |
|---|---|
| Website and documentation | https://aomi.dev |
| Chat and account sign-in | https://aomi.chat |
| Agent MCP | https://aomi.chat/v1/agent/mcp |
| Pipeline MCP | https://aomi.chat/v1/pipeline/mcp |

Each MCP resource needs its own OAuth grant. Users migrating an existing
connection must update the URL and authorize again. CLI users with a saved
backend override should run `aomi config set-backend https://aomi.chat` and
check `AOMI_BACKEND_URL` and `--backend-url` overrides.

Published CLI `0.2.0` still defaults to the retired host; set the backend even on
a fresh install. [Release follow-up](https://github.com/aomi-labs/aomi/issues/887).

## Existing distribution channels

See [_registry.yaml](_registry.yaml) for checked dates, publication versions,
source pointers, and pending submissions. A canonical-source update does not
prove that a cached listing or separately uploaded package has refreshed.

| Channel | Update route |
|---|---|
| Self-hosted Claude/Codex marketplace | Canonical manifests and skill mirrors on this repository's main branch; 0.14.1 pushed |
| Hosted skill on aomi.dev | [Aomi PR 883](https://github.com/aomi-labs/aomi/pull/883) merged; production serves `prod`; [draft publication patch 888](https://github.com/aomi-labs/aomi/pull/888) needs the normal frontend release |
| Anthropic community | Both standalone listings exist but pin an older source commit; update via the owning developer portal account. The GitHub marketplace is a read-only mirror |
| Agentic Awesome Skills (Antigravity) | [PR 2332](https://github.com/sickn33/agentic-awesome-skills/pull/2332) updates the copied skill; awaiting maintainer review |
| Tons of Skills (CCPI) | [PR 1859](https://github.com/jeremylongshore/tons-of-skills-marketplace/pull/1859) includes `.mcp.json`; [issue 1858](https://github.com/jeremylongshore/tons-of-skills-marketplace/issues/1858) requests the reviewed source-pin refresh |
| CryptoSkill.org | [Existing submission 36](https://github.com/jiayaoqijia/cryptoskill/issues/36) updated; awaiting triage |
| cryptoskills.dev | Upstream repository unavailable; local enriched mirror updated |
| ClawHub | Transaction 0.14.0 remains live; publish 0.14.1 with publisher credentials. Build 0.1.1 needs no domain update |
| Agensi | Existing uploaded transaction listing is stale; upload current package through publisher dashboard |
| codex-marketplace.com | Existing plugin source points here; cached V0.10 metadata needs publisher refresh |
| skills.sh | [Reindex request 2752](https://github.com/vercel-labs/skills/issues/2752) for stale CLI/skill snapshot |
| LobeHub | [Source correction 22974](https://github.com/lobehub/lobehub/issues/22974): listing points at a deleted directory |
| SkillsMP | Security verification blocks content/index checks |
| Composio / Awesome Onchain Agents | Existing open submissions point to canonical GitHub sources; no retired endpoint in submission diff |
| BehiSecc Awesome Claude Skills | Prior submission closed for minimum-star requirement; no duplicate submission |

## Updating a release

1. Update canonical skills, mirrored plugin skills, manifests, and `.mcp.json`.
2. Run `python3 -m unittest discover -s tests -v` and parse changed JSON/YAML.
3. Push the canonical source. Update the separately hosted landing-site copy.
4. Refresh copied listings through their required maintainer or publisher path.
   Preserve source locks and review requirements; include `.mcp.json` in bundles.
5. Use the current instructions under `distribution/` for uploaded packages.
   Record a published version only after the registry serves it.

For Anthropic's older Console submissions, follow its
[migration instructions](https://claude.com/docs/directory/publish) before
creating a replacement. Official or deferred directories are not new submissions
in this domain migration.

OpenAI now supports public plugin ZIP submissions through its
[submission portal workflow](https://developers.openai.com/plugins/deploy/submission).
The old “self-serve not open” tracker entry has been corrected. No new official
Aomi listing has been submitted in this migration.
