# aomi-build Security Posture

This document maps the `aomi-build` skill against [OWASP Agentic Skills Top 10 (v1.0, March 2026)](https://owasp.org/www-project-agentic-skills-top-10/) and records the controls in place for each risk. Reviewers can audit the per-control claims against the live SKILL.md frontmatter, the references, and the captured scanner reports under [`.scanner-reports/aomi-build/`](../.scanner-reports/aomi-build/).

**Last reviewed:** 2026-05-07 against SKILL.md @ commit `HEAD`.

## Threat model

`aomi-build` is a procedure for an AI agent to scaffold new Aomi app crates from API docs, OpenAPI/Swagger specs, SDK docs, repository examples, endpoint notes, runtime interfaces, or product requirements. The skill writes Rust source files (`lib.rs`, `client.rs`, `tool.rs`, `Cargo.toml`) inside an `aomi-apps`-shaped workspace and runs `cargo` + `git` commands to compile and track the new crate. It does not move funds, sign transactions, custody secrets, or make network calls of its own. It is correctly classified as **risk_tier: L1** (low) under the OWASP universal manifest schema.

The principal harm path the skill must guard against is **scaffolding code that, when later compiled and run by the user, exfiltrates data or executes attacker-controlled logic**. The OWASP `permissions:` manifest, the explicit `build.rs` deny-write entry, the no-network policy, and the documented "do not embed credentials in scaffolded source" rule all target this path.

## Controls by AST risk

### AST01 — Malicious Skills

**Risk**: A skill is published that hides an exfiltration / drain payload behind benign-looking documentation.

**Controls in place:**

- The skill is published from [`aomi-labs/skills`](https://github.com/aomi-labs/skills) under MIT license; provenance is verifiable via `git log` and the GitHub repo signing keys.
- The skill body (`SKILL.md` plus `references/`, `templates/`, `agents/`) contains no executable code beyond the `templates/quick-scaffold.sh` shell wrapper and shell snippets in documentation. The wrapper is human-auditable (~157 lines, no minification, no eval/exec, no curl-pipe-bash).
- All shell snippets in `references/*.md` are documentation, not executed by the skill itself. The skill's actual operational scope is constrained to `cargo <subcommand>` and `git <subcommand>` per the `permissions.shell` declaration.
- No network calls outside the declared `permissions.network.allow` list (which is empty — the skill is fully offline).
- **Open**: signed releases (sigstore / `gh attestation`) are not yet wired up. Tracked separately at the repo level.

### AST02 — Skill Injection / Tampering

**Risk**: A modified skill is loaded from an untrusted source; tampering goes undetected.

**Controls in place:**

- Canonical source is the `aomi-labs/skills` GitHub repo. Tags are not yet signed; users who care about integrity should pin to a commit SHA and verify against the upstream repo.
- The `permissions.files.deny_write` list (`SOUL.md`, `MEMORY.md`, `AGENTS.md`) blocks the skill from rewriting agent identity files, which is the canonical injection target.
- The same `deny_write` list also includes `build.rs` — Rust build scripts run user-supplied code at compile time, and a tampered skill could otherwise scaffold a malicious build script that runs the first time the user types `cargo build`.
- **Open**: `gh skill` repo / ref / tree-SHA frontmatter pre-population is on the release checklist (see `docs/todo` item #8) but not yet landed.

### AST03 — Over-Privileged Skills

**Risk**: A skill declares broad permissions (`shell: true`, `network: true`) it doesn't actually need; an injection prompt later abuses the privilege.

**Controls in place:**

- A complete OWASP-format `permissions:` manifest is declared in `SKILL.md` frontmatter:
  - `files.read`: `./` and `../aomi-apps/` only — the project the user is working in plus the upstream SDK checkout for pattern reference. No reads under `~/.ssh/`, `~/.aws/`, `~/.config/`, or other credential paths.
  - `files.write`: scoped to `apps/`, workspace `Cargo.toml`, `Cargo.lock`, and `target/` within the project root. The skill never writes outside the workspace.
  - `files.deny_write`: identity files (`SOUL.md`, `MEMORY.md`, `AGENTS.md`) plus `build.rs` (Rust build scripts run code at compile time and are not part of the canonical Aomi app shape).
  - `network.allow: []` and `network.deny: "*"` — the skill makes no network calls. Spec / docs URLs that the user references are fetched out-of-band by the user (or via the agent's `WebFetch` operating outside the skill's operational scope) and pasted into the conversation.
  - `shell`: array form with two argv prefixes (`cargo`, `git`). Spec example uses boolean; the array form is a least-privilege extension consistent with AST03 intent.
  - `tools: []` — no MCP / external tool surface.
- Claude Code's `allowed-tools` field is set to `Bash, Read, Write, Edit, Grep` (sufficient for scaffolding) and the OWASP manifest provides the actual operational lockdown as defense-in-depth.

**Verification**:

- [`Cisco AI Defense skill-scanner`](https://github.com/cisco-ai-defense/skill-scanner) v0.x — **0 findings**, `Status: SAFE`. Report: `.scanner-reports/aomi-build/cisco-ai-defense.md`.
- [`NMitchem/SkillScan`](https://github.com/NMitchem/SkillScan) — **Risk 0.0/10**, 0 findings, `PASS`. Report: `.scanner-reports/aomi-build/skillscan.txt`.

### AST04 — Skill Confused Deputy

**Risk**: A skill's identity is reused for a privileged action the user didn't authorize.

**Controls in place:**

- The skill is **scaffold-only by default**. It does not run scaffolded code automatically. The standard validation loop (`cargo build`, `cargo run -p xtask -- build-aomi`) is invoked **only** when the user has asked for it and reviewed the scaffolded files.
- The skill explicitly forbids fabricating endpoints, auth flows, or contract addresses the source material does not document — surfaced in the SKILL.md description and in `references/spec-to-tools.md` ("Find The Real Integration Target", "Builder-oriented fallbacks").
- For execution-oriented apps that hand off to the host wallet, the skill teaches `ToolReturn::with_routes` over prose-based `SYSTEM_NEXT_ACTION` hints. The runtime resolves routes mechanically; the skill cannot smuggle non-self recipients past simulation by reformulating prose. See [`references/host-routes.md`](references/host-routes.md).

### AST05 — Skill Side-Effects / Hidden Actions

**Risk**: A skill performs persistent state changes that survive the session without the user's knowledge.

**Controls in place:**

- File-system writes are scoped to the user's workspace (`./apps/`, workspace `Cargo.toml`/`Cargo.lock`, `target/`). The skill never writes to `~/.config/`, `~/.aomi/`, or other system locations.
- The workspace `Cargo.toml` change is a single-line addition to the `exclude = [...]` list (so xtask discovery picks up the new crate). The change is observable via `git diff` before commit.
- `cargo build` and `cargo run -p xtask` produce output under `target/`, which is conventionally gitignored. No persistent change escapes the project tree.
- `git add apps/<name>/Cargo.toml` (run by `templates/quick-scaffold.sh` to ensure xtask discovery works) only stages, never commits. The user makes the actual commit.
- Read-side tooling (`cargo metadata`, `git ls-files`, `git status`) is non-destructive.

### AST06 — Insecure Skill Communication

**Risk**: A skill exfiltrates data through a side channel (logging, telemetry, off-domain HTTP).

**Controls in place:**

- The skill makes no direct network calls. `permissions.network.allow: []` and `deny: "*"` are declarative; scanners verify no HTTP/fetch/url patterns appear in the skill body or templates.
- `cargo build` may fetch crate dependencies from `crates.io` as part of the user's local Cargo configuration. The skill does not modify that configuration — it relies on whatever registry the user has set up. Users in air-gapped environments (vendored deps, local registry) work without modification.
- The skill **never embeds credentials in scaffolded source files**. Auth resolution patterns (`resolve_secret_value` in `tool.rs`) read from explicit tool arguments first, then fall back to environment variables — the same pattern shown in `references/examples.md` "Example 1" using the `apps/binance` reference.
- No telemetry, no logging to remote endpoints, no analytics.

### AST07 — Inadequate Logging / Auditability

**Risk**: A skill takes actions that cannot be reconstructed after the fact.

**Controls in place:**

- All file writes are observable via `git status` / `git diff` before commit. The user reviews the scaffolded code before running it.
- All shell invocations (`cargo run`, `cargo build`, `git add`) are observable in the user's shell history.
- The standard validation loop produces deterministic build artifacts under `target/release/lib<name>.dylib` (or platform equivalent), inspectable via `cargo` or `nm`.
- Scaffolded source files include doc comments on every tool and arg struct (see `references/examples.md`); the model-facing schema is recoverable directly from the source.

### AST08 — Skill Supply-Chain Attacks

**Risk**: A dependency the skill relies on is compromised; the skill picks up the compromise transitively.

**Controls in place:**

- The skill itself has **no runtime dependencies** beyond the `cargo` / `git` binaries and the user's local Rust toolchain.
- Scaffolded apps depend on `aomi-sdk = { workspace = true }`, which resolves through the user's `aomi-apps` checkout. The host enforces an exact-match SDK version gate at plugin load (see `docs/sdk-version-compatibility.md`); a tampered SDK that bumps the version stamp would not load against the user's host without coordinated action.
- Scaffolded apps' transitive dependencies (e.g. `reqwest`, `serde`, `schemars`) are managed by Cargo as usual; the skill itself does not pin or vendor anything.
- `templates/quick-scaffold.sh` depends only on POSIX shell and `cargo` + `git`, both checked at startup.
- **Open**: sigstore attestation for the skill itself is not yet wired up.

### AST09 — Insufficient User Consent

**Risk**: A skill performs actions the user has not explicitly authorized.

**Controls in place:**

- Every action requires explicit user request:
  - Scaffolding new app — user must ask ("build an app for X") and provide source material.
  - Modifying workspace `Cargo.toml` — only when scaffolding (single `exclude = [...]` line addition, observable via `git diff`).
  - Running `cargo build` — only when the user asks to validate, or when `templates/quick-scaffold.sh --build` is invoked explicitly.
  - Staging files via `git add` — only inside `templates/quick-scaffold.sh` (a wrapper the user opts into) for the discovery-fix purpose.
- The skill **never auto-commits**. `git commit` is the user's action, not the skill's.
- The skill **never embeds credentials** or auto-fills secrets the user did not paste. The pattern documented in `references/examples.md` is "read explicit args first, fall back to env vars" — the skill teaches this pattern and never bypasses it.

### AST10 — Cross-Platform Reuse

**Risk**: A skill that's safe on one host (e.g. Claude Code) becomes unsafe when loaded on a different host (Codex, Cursor, OpenClaw) due to differing tool-permission semantics.

**Controls in place:**

- The OWASP `permissions:` manifest is declarative metadata that all OWASP-aware scanners and registries can read regardless of host. The Claude Code-specific `allowed-tools` field coexists as a sibling.
- An `agents/openai.yaml` is provided for Codex/OpenAI-host metadata.
- The skill's operational scope (`cargo` + `git` + filesystem within the workspace) is uniform across hosts; there are no host-specific tool surfaces that would behave differently on Codex vs Claude Code.
- **Open**: end-to-end install verification across Claude Code + Codex + at least one community installer is on the release checklist (#9, #20). The skill is shaped for cross-platform reuse but has not yet been load-tested on every host.

## Captured scanner reports

All reports under [`.scanner-reports/aomi-build/`](../.scanner-reports/aomi-build/). Re-run any scanner with the local commands documented in [`docs/todo`](../docs/todo) and `.scanner-reports/README.md` (substituting `./aomi-build/` for the target).

| Scanner | Status | Findings | Report |
|---------|--------|----------|--------|
| Cisco AI Defense skill-scanner | **PASS** | 0 critical / 0 high / 0 medium / 0 low | [`cisco-ai-defense.md`](../.scanner-reports/aomi-build/cisco-ai-defense.md) |
| pors/skill-audit | **PASS** | 0 errors / 2 doc-regex warns | [`pors-skill-audit.txt`](../.scanner-reports/aomi-build/pors-skill-audit.txt) |
| NMitchem/SkillScan | **PASS** | Risk 0.0/10, 0 findings | [`skillscan.txt`](../.scanner-reports/aomi-build/skillscan.txt) |
| Snyk agent-scan | **Pending** | Requires `SNYK_TOKEN`; report to be captured by maintainer | — |

**Notes on findings**:

- The 2 pors WARN findings match documentation patterns:
  - `prompt/(delete|remove|rm)...` matches a row in `references/examples.md` table where one of the example tools is `binance_cancel_order` mapped to a `DELETE /order` HTTP endpoint. The match is on the literal string `DELETE` inside the reference table, not on a destructive instruction — the skill itself never deletes files.
  - `prompt/(read|access|get|ext...)` matches `references/spec-to-tools.md` describing the canonical tool naming pattern (`get_*`, `read_*`, `list_*`). Documentation about the convention, not an instruction to access sensitive data.
- Snyk requires an API token for the SaaS-backed analysis. Token-gated runs are tracked as a maintainer task; the W-code analysis approach used for `aomi-transact` (see [`aomi-transact/SECURITY.md`](../aomi-transact/SECURITY.md) Snyk W-code table) will apply if any HIGH-class characterizations come back. For `aomi-build` specifically, the only Snyk W-codes that could plausibly apply are W007 (insecure credential handling) — already mitigated by the no-credential-embedding rule and the auth resolution pattern documented in `references/examples.md`. The skill does not move funds (no W009), does not depend on third-party content (no W011), and does not invoke `npx` or other unpinned external URLs (no W012).

## Reporting issues

Security issues should be reported privately. See the top-level [`SECURITY.md`](../SECURITY.md) in `aomi-labs/skills` for the disclosure process, or open a private security advisory on the GitHub repo.
