---
name: aomi-build
description: >
  Scaffold new Aomi apps and plugins from API docs, OpenAPI/Swagger specs, or SDK
  references. aomi-build generates production-ready Rust SDK crates (lib.rs,
  client.rs, tool.rs) with tool schemas, preambles, host-interop flows, and
  validation — turning a vendor's API surface into AI-agent-callable tools. It
  covers the current `aomi-build` OpenAPI pipeline (`gen-specs` → `gen-client`
  → `gen-tool` → curate → compile/test) as well as greenfield apps. Use when
  the user wants to scaffold a new Aomi app from a spec, wrap a REST API as
  agent-callable tools, port an existing SDK, or extend an Aomi runtime with new
  integrations. Trigger with prompts about wrapping APIs, scaffolding Rust crates
  from specs, or adding protocol integrations that aomi-transact can drive. Output
  crates support progenitor-generated OpenAPI clients, curated tool layers, sync
  HTTP, async tools (DynAsyncSink), typed secrets, route plans
  (ToolReturn/RouteStep), EVM and SVM host handoffs, and multi-step
  quote→approval→swap flows. Same runtime that aomi-transact drives.
tags: [crypto, web3, evm, rust, sdk-scaffolding, openapi, swagger, agent-tools, defi, builder-tools]
compatibility: 'Best when a local aomi-sdk checkout is available, often at ../aomi-sdk. Falls back to bundled references when the SDK repo is not present. Verified against aomi-sdk v3.0.1 (Rust 2024 edition) and the current aomi-build Rust CLI. Install the current CLI with cargo install --git https://github.com/aomi-labs/aomi-sdk --features cli aomi-sdk, or run from source with cargo run -p aomi-sdk --features cli --bin aomi-build -- <command>. Designed for claude-code; also works with Cursor, Codex CLI, Gemini, and any agent runtime that supports the Anthropic skill spec.'
license: MIT
version: "0.1.1"
author: 'aomi-labs <hello@aomi.dev>'
# Claude Code allowed-tools. The skill scaffolds Rust source files (Write/Edit),
# inspects existing apps and SDK examples (Read/Grep), and runs cargo + git
# (Bash). Operational scope is locked down by OWASP permissions.shell below
# to `cargo` and `git` only — defense in depth.
allowed-tools: 'Bash(cargo:*), Bash(git:*), Read, Write, Edit, Grep'
metadata:
  author: 'aomi-labs <hello@aomi.dev>'
  version: "0.1.1"
  # Provenance — author-declared upstream coordinates.
  # `gh skill install` will add/overwrite `ref`, `tree_sha`, `installed_via`,
  # and `installed_at` at install time. Do not pre-populate those fields.
  repository: aomi-labs/skills
  homepage: https://github.com/aomi-labs/skills/tree/main/aomi-build

# OWASP AST03 (Over-Privileged Skills) permission manifest.
# Spec: https://owasp.org/www-project-agentic-skills-top-10/ast03
# Universal Skill Format v1.0 (March 2026).
permissions:
  files:
    # The skill reads source files in the user's project (the aomi-sdk
    # checkout or wherever the user runs from) and the SDK's bundled
    # docs/examples for pattern reference.
    read:
      - ./
      - ../aomi-sdk/
    # The skill writes new Rust source files within the project's apps/ tree
    # and may amend the workspace manifest to add the new crate to `exclude`.
    # cargo writes to target/ as a compile artifact; git writes index entries
    # when staging the new manifest for source control.
    write:
      - ./apps/
      - ./Cargo.toml
      - ./Cargo.lock
      - ./target/
      - ../aomi-sdk/apps/
      - ../aomi-sdk/Cargo.toml
      - ../aomi-sdk/Cargo.lock
      - ../aomi-sdk/target/
    # Identity files must never be modified (AST03 mitigation #3).
    # build.rs is denied because Rust build scripts run user-supplied
    # code at compile time; the standard Aomi app shape (lib.rs,
    # client.rs, tool.rs) does not need one. If the user genuinely
    # needs a build script they must opt in explicitly outside the
    # skill's default flow.
    deny_write:
      - SOUL.md
      - MEMORY.md
      - AGENTS.md
      - build.rs

  network:
    # The skill makes no network calls of its own. Any docs / specs / repo
    # links the user references are fetched out-of-band by the user (or by
    # the agent's own WebFetch capability operating outside the skill's
    # operational scope), then pasted into the conversation.
    allow: []
    deny: "*"

  # Shell access restricted to `cargo` and `git` argv prefixes (least-privilege
  # extension of the spec's boolean form, consistent with AST03 intent).
  # `cargo` runs aomi-build, build, and test; `git` runs
  # ls-files (used by app discovery) and add/status/diff for normal source work.
  shell:
    - cargo
    - git

  # No MCP/tool surface beyond local cargo + git + filesystem.
  tools: []

# Risk tier per spec: L0 safe, L1 low, L2 elevated, L3 destructive.
# L1 = the skill writes source files and runs the Rust toolchain.
# It does not move funds, sign transactions, custody secrets, or make
# network calls of its own.
risk_tier: L1

requires:
  binaries: [cargo, git]
---

# Aomi Build

## Overview

Aomi Build scaffolds production-ready Rust SDK crates for Aomi apps and plugins from
OpenAPI/Swagger specs, SDK docs, or product requirements. Generates `lib.rs`, `client.rs`,
`tool.rs` with typed tool schemas, host-interop flows, and validation steps.

## When to Use

- Scaffold a new Aomi app from an OpenAPI spec or REST API
- Wrap an existing SDK as agent-callable Aomi tools
- Extend an Aomi runtime with new protocol integrations

Do **not** use this skill for executing transactions — use **aomi-transact** for that.

## Prerequisites

- Rust toolchain (2024 edition) and `cargo` on PATH
- `git` on PATH
- Aomi SDK v3.0.1 or newer
- Local `aomi-sdk` checkout at `../aomi-sdk` (recommended)
- Current `aomi-build` binary, or run it from source with the `cli` feature

## Quick Start

```bash
cd ../aomi-sdk
cargo run -p aomi-sdk --features cli --bin aomi-build -- init my-integration
cargo run -p aomi-sdk --features cli --bin aomi-build -- compile --app my-integration
cargo run -p aomi-sdk --features cli --bin aomi-build -- new-app geckoterminal --from-url https://api.geckoterminal.com/docs/v2/swagger.json
```

## Instructions

1. Identify the integration target and its callable surface.
2. State the proposed toolset (3–8 intent-shaped tools) before coding.
3. Scaffold greenfield apps with `aomi-build init <name>`; scaffold OpenAPI-driven apps with `aomi-build new-app <name>` or the staged `gen-specs` / `gen-client` / `gen-tool` pipeline.
4. Implement `client.rs` (HTTP, auth, models), `tool.rs` (`DynAomiTool` impls), `lib.rs` (manifest + preamble).
5. For execution apps, return `ToolReturn::with_routes(...)` instead of bare JSON.
6. Build and validate: `aomi-build compile --app <name>` or `cargo run -p aomi-sdk --features cli --bin aomi-build -- compile --app <name>`. For generated OpenAPI apps, also run `aomi-build test-schema <name>` when the live API is safe to fuzz.

## Examples

```bash
grep -r "dyn_aomi_app!" ../aomi-sdk/apps/
cargo run -p aomi-sdk --features cli --bin aomi-build -- compile --app binance
cargo test --manifest-path apps/my-integration/Cargo.toml
```

## Output

- Rust crate at `apps/<name>/` with `lib.rs`, `client.rs`, `tool.rs`, `Cargo.toml`
- Compiled `.so`/`.dylib` plugin artifact under `target/`
- Typed tool schema embedded in the plugin manifest

## Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| `compile` reports zero plugins | No tracked or discoverable `apps/*/Cargo.toml` | Check the app path and package name; current compile scans tracked manifests and the apps directory |
| `SDK version mismatch` | Plugin built against old SDK | Bump version in `Cargo.toml`, rebuild all |
| `JsonSchema derive failed` | Missing derive on Args | Add `schemars` dep, `#[derive(JsonSchema)]` on Args |
| Async tool hangs | `is_canceled()` not polled | Add cancellation check in `run_async` loop |
| Installed `aomi-build` lacks `deploy` | Old binary on PATH | Run from source with `cargo run -p aomi-sdk --features cli --bin aomi-build -- ...` or reinstall from the current repo |
| Generated tool names are endpoint-shaped | `gen-tool` stubs one tool per operationId | Curate `tool.rs` into user-intent tools before shipping |
| `progenitor` fails | Spec violates generator assumptions | Inspect `openapi.preprocessed.yaml`, patch `openapi.yaml`, or add a generic preprocessing pass |

## Safety Justification

`Bash(cargo:*, git:*)` — restricted to two argv prefixes. `cargo` runs `aomi-build`, builds, and tests
crates; `git` runs `ls-files` and `add` only. No other shell commands permitted;
`permissions.shell` enforces this at the OWASP AST03 level.

`Read` — reads within `./` and `../aomi-sdk/` only. `Write` — writes to `./apps/`,
`../aomi-sdk/apps/`, `Cargo.toml`, `Cargo.lock`, `target/` only; identity files
(`SOUL.md`, `MEMORY.md`, `AGENTS.md`, `build.rs`) are `deny_write`-listed.
`Edit` — same paths as Write. `Grep` — read-only search, no writes.

Risk tier: L1 (source files + Rust toolchain only; no fund movement, no network calls).

---

Use this skill for tasks like:

- "Build an Aomi app from this OpenAPI spec."
- "Turn these REST endpoints into an Aomi plugin."
- "Scaffold a new Aomi SDK app for this product/API."
- "Update an existing Aomi app to support these new endpoints."
- "Turn these builder docs or SDK repos into an Aomi assistant."

## First Read

If a local `aomi-sdk` checkout exists (often at `../aomi-sdk`), inspect these first. The current SDK is **v3.0.1**, Rust 2024 edition. The `aomi-build` binary is part of the `aomi-sdk` crate behind the `cli` feature.

- `sdk/examples/app-template-http/src/lib.rs` — canonical HTTP-API template (sync read-only)
- `sdk/examples/app-template-http/src/client.rs`
- `sdk/examples/app-template-http/src/tool.rs`
- `sdk/examples/app-template-http/Cargo.toml` — note `edition = "2024"` and `crate-type = ["cdylib"]`
- `sdk/src/types.rs` and `sdk/src/route.rs` — `DynToolCallCtx`, `DynAomiTool`, async tool contracts, and `ToolReturn` / `RouteStep`
- `docs/repo-structure.md` — file roles and authoring guidelines
- `docs/host-interop.md` — public host tools (`encode_and_call`, `stage_tx`, `simulate_batch`, `commit_txs`, `evm_commit_message`) plus SVM route targets
- `docs/aomi-build.md` and `sdk/bin/build/CONTRIBUTING.md` — current `aomi-build` commands (`gen-specs`, `gen-client`, `gen-tool`, `new-app`, `test-schema`, `tighten-spec`, `init`, `compile`, `deploy`, `connect`, `sdk check|fix`)
- `docs/sdk-version-compatibility.md` — exact-match SDK version gate enforced via `aomi_sdk_version` symbol
- 2 or 3 relevant apps under `apps/*/src/{lib,client,tool}.rs`. Recommended:
  - `apps/binance` — execution-oriented with required secrets and normalized models
  - `apps/oneinch` — execution planner with routed quote → approval → swap flow
  - `apps/geckoterminal` — current OpenAPI/progenitor app-local pipeline (`openapi.yaml`, generated `src/client/`, curated `tool.rs`)
  - `apps/svm-transfer` — current SVM lane-1/lane-2 route patterns (`svm_stage_ix`, `svm_stage_tx`, `svm_commit_ix`, `svm_commit_tx`)
  - `apps/khalani`, `apps/polymarket`, or `apps/polymarket-rewards` — host handoff via `ToolReturn` routes

If the supplied docs mostly point to GitHub repositories, SDKs, or examples instead of listing public endpoints:

- treat those linked repositories as the real source of truth
- inspect their README, config examples, example commands, and RPC/API surfaces
- check whether they expose or produce a runnable service interface such as REST, GraphQL, JSON-RPC, gRPC, webhooks, or another stable client contract
- prefer building against that executable surface instead of wrapping the docs themselves
- avoid inventing a public transactional API that the docs do not actually publish

If the current repo is `aomi-widget`, also inspect:

- `apps/landing/content/examples/*.mdx`
- `apps/landing/content/guides/build/**/*.mdx`

If the `aomi-sdk` checkout is not available, read:

- [references/aomi-sdk-patterns.md](references/aomi-sdk-patterns.md) — manifest shape, file roles, real-app conventions
- [references/spec-to-tools.md](references/spec-to-tools.md) — converting OpenAPI / SDK docs / endpoint lists into intent-shaped tools
- [references/host-routes.md](references/host-routes.md) — `ToolReturn` envelope and `RouteStep` builders for execution apps that hand off to the host wallet
- [references/examples.md](references/examples.md) — five end-to-end walkthroughs anchored to real apps (`binance`, builder fallback, `polymarket` routes upgrade, async tool with cancellation, SDK version bump)
- [references/troubleshooting.md](references/troubleshooting.md) — common build/runtime failures with concrete fixes (untracked `Cargo.toml`, SDK version mismatch, async tool hangs, route resolution issues, JsonSchema derive failures)

## Default Workflow

1. Identify the product surface:
   - What external API, SDK, repo, or spec is the source of truth?
   - What concrete callable surface exists: REST, GraphQL, JSON-RPC, gRPC, webhook, CLI contract, or something else?
   - Is there a real target we can point the app at: hosted service, self-hosted node, local example stack, or customer-provided endpoint?
   - Is this read-only, execution-oriented, or mixed?
   - What auth/env vars are required?
   - What user state must come from the host or caller?
   - Is this actually a public end-user API, a standard client interface exposed by a runtime/example app, or only builder-facing documentation?
2. Describe the intended user-facing toolset before implementation:
   - list the proposed tools by name
   - say what user intent each tool serves
   - call out which tools are read-only, which prepare actions, and which write or submit
   - mention any expected target URL, runtime, or host dependency
   - if the toolset is uncertain, surface the uncertainty before coding
   - identify the primary user workflow the app should make easy first
   - keep the first pass to the smallest sufficient toolset for that workflow unless the user asked for broader API coverage
3. Reduce the spec into semantically meaningful tools.
4. Scaffold or update the Aomi app using the standard file split:
   - `lib.rs` for manifest and preamble. Register with `dyn_aomi_app!` including the `namespaces = [...]` field — `["evm-core"]` for most EVM apps and generated OpenAPI apps, SVM namespaces such as `["svm-reads", "svm-ix-broadcast", "svm-tx-broadcast"]` for Solana apps, or `[]` only for tools that need no host namespace at all. The old `"common"` namespace is stale and should not be copied into new apps.
   - `client.rs` for HTTP client, auth, models, and normalization
   - `tool.rs` for `DynAomiTool` implementations. Sync tools implement `run`; async tools set `const IS_ASYNC: bool = true` and implement `run_async` with `DynAsyncSink::emit`/`complete`/`is_canceled` (see `sdk/examples/hello-app/src/lib.rs`).
5. Write the preamble around actual tool behavior, confirmation rules, and any host handoff. Execution apps that drive multi-step wallet flows return `ToolReturn::with_routes(...)` instead of bare JSON — see [references/host-routes.md](references/host-routes.md).
6. Validate with the SDK build flow and add focused tests when logic is non-trivial.

## Tool Design Rules

- First decide what kind of app this should be:
  - product client
  - execution assistant
  - builder / SDK / runtime assistant
- Before implementing, state the proposed toolset in concrete user-facing terms. This is part of the design, not optional polish.
- Prefer the smallest sufficient toolset that makes the primary user workflow work end to end.
- If there are multiple plausible integration targets, briefly state which one you are choosing and why before coding.
- Prefer tools that interact with an actual product surface over tools that merely restate documentation.
- A hosted API is not required. A self-hosted service, local example stack, standard RPC server, or other runnable interface still counts as a real integration target.
- If the source material is SDK- or architecture-heavy, first ask whether it produces a service that clients call. If yes, build the client for that service.
- Only fall back to a builder-oriented or docs-oriented tool surface when no stable executable target is available.
- Do not mirror every endpoint 1:1 unless that is actually the cleanest model-facing API or the user explicitly asked for broad coverage.
- Prefer 3 to 8 tools with clear user intent boundaries such as `search_*`, `get_*`, `build_*`, `submit_*`, `list_*`, or `resolve_*`.
- Prefer intent-shaped tool names over raw protocol or transport names when practical.
- Aggregate noisy upstream endpoints behind a smaller tool surface when the model does not need the raw distinction.
- Prefer typed arguments over raw JSON string blobs when the primary workflow can be modeled cleanly that way.
- Separate core tools from escape hatches. A generic fallback tool such as `*_rpc` or `*_raw` is fine, but it should not replace a clean core workflow.
- Keep args typed and documented with `JsonSchema`. Field doc comments are model-facing and matter.
- Return stable JSON with predictable keys. Normalize upstream naming, paging, and inconsistent shapes inside `client.rs` or helper functions.
- Convert upstream errors into short actionable messages. Do not leak raw HTML, secrets, or giant payload dumps.

## File Responsibilities

### `lib.rs`

- Keep it easy to scan.
- Define `PREAMBLE` or a small `build_preamble()` hook.
- Register tools with `dyn_aomi_app!`. Always include the `namespaces` field explicitly — `namespaces = ["evm-core"]` for most EVM or generated API apps, SVM namespaces for Solana apps, and `namespaces = []` only when no host namespace should be injected. The macro generates the C ABI exports (`aomi_create`, `aomi_manifest`, `aomi_async_tool_start`, etc.) and embeds the SDK version stamp the host uses for the exact-match compatibility check.
- Only keep manifest-level wiring here.

### `client.rs`

- Own the app struct, HTTP client, auth headers, env vars, typed models, and response normalization.
- Prefer `reqwest::blocking::Client` with explicit timeouts for sync tools, matching the current SDK examples.
- Keep third-party API quirks here instead of spreading them across tool implementations.

### `tool.rs`

- Implement `DynAomiTool`. Required associated types: `App` (the app struct from `client.rs`) and `Args` (a `JsonSchema + Deserialize` struct). Required consts: `NAME`, `DESCRIPTION`. Optional const: `IS_ASYNC` (defaults to `false`).
- Use descriptions that tell the model when to call the tool, not just what endpoint it wraps.
- Map normalized client results into concise JSON results. Sync tools return `Result<Value, String>` from `run()`; async tools return `Result<(), String>` from `run_async()` and emit progress through the `DynAsyncSink`. Cancellation: poll `sink.is_canceled()` and return `Ok(())` early.
- Use `DynToolCallCtx` when host state such as connected wallet, session state, or caller attributes is needed. `ctx.session_id` and `ctx.call_id` are stable identifiers for logging or routing.
- For execution apps that hand off to the wallet, return `ToolReturn::with_routes(value, [RouteStep::on_return(...).bind_as(...).prompt(...)])` instead of a bare `Value`. The `run_with_routes()` method on `DynAomiTool` has a default impl that wraps `run()` — only override it when you need routes. See [references/host-routes.md](references/host-routes.md).

## Preamble Rules

Write the preamble from the app's real contract:

- Define role, capabilities, workflow, and guardrails.
- Mention tool order for multi-step flows.
- State explicit confirmation requirements before write actions.
- If dates matter, include the current date or instruct the app to use exact dates.
- If the app relies on host wallet/signing tools, say that clearly and do not imply hidden infrastructure.

For deeper patterns and examples, read [references/aomi-sdk-patterns.md](references/aomi-sdk-patterns.md).

## Host Interop And Execution

For execution-oriented apps:

- Follow the public host conventions from `docs/host-interop.md`. The available host tools include `encode_and_call`, `stage_tx`, `simulate_batch`, `commit_txs`, `evm_commit_message`, and SVM targets such as `svm_stage_ix`, `svm_stage_tx`, `svm_commit_ix`, and `svm_commit_tx`. Apps reference these by name or typed route markers in route hints — they are public contract, not private infrastructure.
- Do not invent private namespaces (`CommonNamespace` etc.) or internal fallback behavior. Do not use the old `"common"` namespace in new app manifests; current host namespace names are canonical strings such as `"evm-core"`, `"svm-reads"`, `"svm-ix-broadcast"`, and `"svm-tx-broadcast"`.
- When the next step belongs to the host wallet or signer, return a `ToolReturn` envelope with explicit `RouteStep` builders instead of any prose-based `SYSTEM_NEXT_ACTION` convention. The runtime's `RoutedEventBridge` resolves `OnSyncReturn` and `OnBoundEvent` triggers, splices wallet-callback artifacts (`signature`, `transaction_hash`) into hinted args, and injects the continuation prompt. The runtime never parses prose — structured fields are the contract.
- Preserve exact transaction or signature args when a downstream host tool must execute them. For raw external tx payloads, use `stage_tx` with `data: { raw: "0x..." }`; for ABI-driven calls, use `data: { encode: { signature, args } }`.
- Do not claim a write succeeded until the upstream API submit step has actually completed.

For deeper coverage of the routes pattern, including `OnSyncReturn` vs `OnBoundEvent`, `bind_as` aliases, and worked examples from `apps/khalani` and `apps/polymarket`, read [references/host-routes.md](references/host-routes.md).

## Validation

When working inside `aomi-sdk`:

- Scaffold greenfield apps with `cargo run -p aomi-sdk --features cli --bin aomi-build -- init <name>`, or scaffold API-driven apps with `cargo run -p aomi-sdk --features cli --bin aomi-build -- new-app <platform> --from-url <url>`.
- Build the plugin with `cargo run -p aomi-sdk --features cli --bin aomi-build -- compile --app <name>`. Optional flags: `--release`, `--target <triple>`. The build validates the manifest, codesigns on macOS, and validates the produced plugin.
- For OpenAPI apps, the current pipeline is `gen-specs` (writes `apps/<p>/openapi.yaml` by default, or `ext/specs/<p>.yaml` with `--shared`) → `gen-client` (progenitor into `apps/<p>/src/client/` or `ext/src/<p>/`) → `gen-tool` (mechanical stubs) → curate → `compile`. `openapi.preprocessed.yaml` is a debug artifact overwritten by `gen-client`; edit `openapi.yaml`, not the preprocessed copy.
- `gen-tool` intentionally produces endpoint-shaped stubs. Before shipping, collapse them into user-story tools, write a real preamble, and add `apps/<p>/test.json` when the app needs real LLM/runtime validation.
- If `compile` reports zero built plugins for a brand new app, check the app path, package metadata, and whether `[package.metadata.aomi.skip]` is set. Current compile scans tracked manifests and the apps directory.
- For a direct compile signal on an untracked app, use `cargo build --manifest-path apps/<name>/Cargo.toml`.
- If the app has meaningful branching or normalization logic, add unit tests with `aomi_sdk::testing::{TestCtxBuilder, run_tool, run_async_tool}`. `TestCtxBuilder::new(tool_name).build()` produces a `DynToolCallCtx`; `run_tool` returns a full `ToolReturn` with routes; `run_async_tool` returns `(updates, terminal)`.
- The host-plugin compatibility gate is **exact-match SDK version**. After bumping `sdk/Cargo.toml` `package.version`, all apps must be rebuilt — the host rejects plugins whose `aomi_sdk_version` symbol does not match its compiled `AOMI_SDK_VERSION`. See `docs/sdk-version-compatibility.md`.
- If a real target is available, validate the app with a short ladder:
  - compile/build
  - connectivity check
  - one representative read flow
  - one representative write or submit flow when applicable
  - post-write verification such as status, receipt, or refreshed state
- Prefer proving one end-to-end user scenario over checking many disconnected endpoints.

When the task also touches docs or demos in `aomi-widget`, update the relevant examples or guides to match the new app behavior.

## Output Expectations

Aim to leave behind:

- a coherent Aomi app crate or patch
- typed tool args and strong descriptions
- a preamble that explains the tool contract and rules
- stable JSON outputs for the host/model
- an app that can point at a real product surface when one exists
- a short validation pass or a clear note about what could not be verified

## Resources

- Source repository: https://github.com/aomi-labs/skills/tree/main/aomi-build
- Companion runtime skill: [aomi-transact](https://github.com/aomi-labs/skills/tree/main/aomi-transact)
- npm runtime client: https://www.npmjs.com/package/@aomi-labs/client
- Aomi SDK patterns: [references/aomi-sdk-patterns.md](references/aomi-sdk-patterns.md)
- Spec-to-tools mapping: [references/spec-to-tools.md](references/spec-to-tools.md)
- Host route conventions: [references/host-routes.md](references/host-routes.md)
- End-to-end build examples: [references/examples.md](references/examples.md)
- Troubleshooting playbook: [references/troubleshooting.md](references/troubleshooting.md)
- Anthropic skill spec: https://docs.claude.com/en/docs/claude-code/skills
