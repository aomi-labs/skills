# Troubleshooting

Read this when a build fails or behaves differently than the workflow predicts. Each section lists symptoms, likely cause, and a concrete fix.

## Build / xtask

### `cargo run -p xtask -- build-aomi --app <name>` reports "0 plugins built"

**Symptoms:**
- The build completes with no errors but produces no plugin file.
- The expected `target/release/lib<name>.dylib` (or `.so` / `.dll`) is missing.

**Cause:**
- The new app's `Cargo.toml` is untracked. xtask discovers apps via `git ls-files apps/*/Cargo.toml`. A brand-new crate that hasn't been `git add`-ed is invisible to discovery.

**Fix:**

```bash
# Track the new app's manifest
git add apps/<name>/Cargo.toml
cargo run -p xtask -- build-aomi --app <name>
```

For an immediate compile signal without staging anything:

```bash
cargo build --manifest-path apps/<name>/Cargo.toml
```

You don't have to commit, just `git add` is enough to make it visible to `git ls-files`.

### App is intentionally skipped

**Symptoms:**
- App is tracked but `build-aomi` skips it.
- xtask logs something like `skipping <name>: package metadata aomi.skip = true`.

**Cause:**
- The app's `Cargo.toml` has `[package.metadata.aomi.skip]` set, usually for in-progress crates that don't yet build.

**Fix:**

If the app is ready, remove the skip block from `apps/<name>/Cargo.toml`. If it's still in-progress, leave it alone — the skip is intentional.

### `cargo build` succeeds but `xtask build-aomi` errors with manifest validation

**Symptoms:**
- The crate compiles fine.
- xtask rejects with errors like "manifest does not export `aomi_create`" or "missing `aomi_sdk_version` symbol".

**Cause:**
- `lib.rs` is missing the `dyn_aomi_app!` macro invocation, OR the macro arguments are malformed (e.g. typo in `tools = [...]`, missing `namespaces` field).

**Fix:**

Compare against `sdk/examples/app-template-http/src/lib.rs`:

```rust
dyn_aomi_app!(
    app = client::MyApp,         // type from client.rs
    name = "my-app",             // string identifier
    version = "0.1.0",           // app version, not SDK version
    preamble = PREAMBLE,         // const &str
    tools = [client::Tool1, client::Tool2],
    namespaces = []              // required field; [] or ["common"]
);
```

Common mistakes:
- Trailing comma after `namespaces = []` — fine, but make sure it's there if you copy-paste.
- `preamble = "..."` inline string instead of `preamble = PREAMBLE` const reference. Both work; const is preferred for long preambles.
- Forgetting the `namespaces` field entirely — required since SDK v0.1.14+.

### macOS codesigning failure

**Symptoms:**
- xtask error like `codesign failed: errSecInternalComponent` or `unable to sign cdylib`.

**Cause:**
- macOS requires cdylibs to be signed before they can be loaded. xtask runs `codesign` automatically; this can fail if Xcode CLI tools are missing or the keychain is locked.

**Fix:**

```bash
# Confirm Xcode CLI tools are installed
xcode-select -p

# If missing:
xcode-select --install

# If keychain is locked:
security unlock-keychain login.keychain
```

Then retry the build. For CI, ensure the runner has codesigning capability or use `--target` to build for a non-Apple platform.

## Runtime / Host

### Plugin rejected at host load: SDK version mismatch

**Symptoms:**
- Host log: `plugin <name> rejected: aomi_sdk_version 0.1.14 does not match host 0.1.15`.

**Cause:**
- The plugin was built against an older (or newer) `aomi-sdk` than the host. The host enforces an **exact-match** version gate.

**Fix:**

```bash
# Pull the latest aomi-apps
git -C ../aomi-apps pull

# Rebuild ALL apps — the version gate is repo-wide
cargo run -p xtask -- build-aomi --release
```

A single app rebuild is not enough if other apps in the runtime also need to load. The hosted runtime treats SDK drift as a coordinated rebuild event — see `docs/sdk-version-compatibility.md`.

### Plugin loads but tool calls return empty/null

**Symptoms:**
- Host loads the plugin successfully.
- `aomi app current` shows the right tools.
- Calling a tool returns nothing or `{}`.

**Cause:**
Several:
- The tool's `run` returned `Ok(Value::Null)` or `Ok(json!({}))` — check the implementation.
- The HTTP client succeeded but response deserialization silently produced an empty struct (loose `serde` defaults).
- For async tools: `complete()` was never called, only `emit()`.

**Fix:**

1. Add a temporary `eprintln!("response: {:?}", raw_response)` before the JSON conversion in `client.rs`.
2. Confirm the upstream response shape matches your typed model. Run with `RUST_LOG=debug` if the SDK exposes it.
3. For async tools, audit `run_async` for a path that emits without ever completing. Every async tool must either `complete()` once or return `Err(...)`.

## Tool implementation

### `JsonSchema` derive failure

**Symptoms:**
```
error[E0277]: the trait bound `MyType: JsonSchema` is not satisfied
```

**Cause:**
- A field in `MyArgs` is a custom type that doesn't implement `JsonSchema`. The derive needs every field to be deriveable.

**Fix:**

Add the derive on the inner type:

```rust
#[derive(Debug, Deserialize, JsonSchema)]
pub struct MyArgs {
    pub config: NestedConfig,    // NestedConfig must also derive JsonSchema
}

#[derive(Debug, Deserialize, JsonSchema)]
pub struct NestedConfig {
    pub field: String,
}
```

For std/external types that don't have it (`bigdecimal::BigDecimal`, `chrono::DateTime`, etc.) — represent them as `String` in the args struct and parse inside the tool. Schemars-compatible features for some crates (`schemars` with `chrono` feature) work but tie you to specific versions.

### `Args` deserialization fails at runtime

**Symptoms:**
- Tool called by the LLM returns `Err("missing field 'symbol'")` or `Err("invalid type: string, expected u32")`.

**Cause:**
- The LLM produced args that don't match your `Args` struct. Common reasons: required field marked as required in schema but the LLM omitted it; type mismatch from prose-style numeric strings.

**Fix:**

Make optional fields explicitly optional and add doc comments that guide the LLM:

```rust
#[derive(Debug, Deserialize, JsonSchema)]
pub struct GetDepthArgs {
    /// Trading pair symbol in uppercase, no separator (e.g., "BTCUSDT", "ETHUSDT").
    pub symbol: String,

    /// Optional. Number of price levels to return. Valid values: 5, 10, 20, 50, 100, 500, 1000, 5000. Default 100.
    #[serde(default)]
    pub limit: Option<u32>,
}
```

Doc comments become part of the model-facing schema. Spell out valid values, units, and formats — they are the only signal the model has.

### Async tool hangs / never completes

**Symptoms:**
- The host shows the tool as "in progress" indefinitely.
- No `emit` or `complete` events ever fire.

**Cause:**
Several:
- The tool calls a blocking HTTP request that itself hangs (no timeout).
- Inner loop never reaches `sink.complete(...)` because of an unhandled condition.
- `IS_ASYNC` set to `true` but the tool implements `run` instead of `run_async`.

**Fix:**

1. Confirm `const IS_ASYNC: bool = true;` is set, AND `run_async` is implemented (not `run`).
2. Add explicit timeouts to all HTTP calls:

   ```rust
   reqwest::blocking::Client::builder()
       .timeout(Duration::from_secs(30))
       .build()
   ```

3. Audit every code path in `run_async` — does each branch call either `sink.complete(...)` or return `Err(...)`? A loop with no exit condition will hang silently.
4. Add `is_canceled()` checks at loop boundaries:

   ```rust
   loop {
       if sink.is_canceled() { return Ok(()); }
       // ... work ...
   }
   ```

### Tool returns successfully but routes don't fire

**Symptoms:**
- Tool returns a `ToolReturn::with_routes(value, [...])` envelope.
- The runtime acknowledges the tool result but never invokes the routed-to tool.

**Cause:**
Several:
- The route's `tool` field references a tool name that doesn't exist (typo, or the tool isn't registered).
- For `OnBoundEvent` routes: the alias never resolves because no upstream step published it via `bind_as`.
- The app's `namespaces = []` doesn't include `"common"`, so host tool references in routes are not authorized.

**Fix:**

1. Confirm `namespaces = ["common"]` in the manifest.
2. For `OnSyncReturn` routes: confirm the `tool` field matches an exported tool name exactly. For host tools, prefer the typed marker `RouteStep::on_return_to::<host::CommitEip712>(args)` to catch typos at compile time.
3. For `OnBoundEvent` routes: trace the alias chain. The earlier step that publishes via `bind_as("foo")` must execute and complete before a later step bound to `"foo"` can fire. Check the order of routes in the `with_routes([...])` array.
4. Inspect the host's event log: it logs every `OnBoundEvent` resolution and any unresolved aliases at session end.

## Testing

### `run_tool` fails with "args type mismatch"

**Symptoms:**
- Test code: `run_tool::<MyTool>(&MyApp, json!({"foo": "bar"}), ctx)?`
- Error: `expected MyArgs, got Value::Object`.

**Cause:**
- The args you passed don't deserialize into `MyTool::Args`. Same as runtime — but easier to catch in tests.

**Fix:**

Construct the args with the typed struct first, then serialize:

```rust
let args = json!(MyArgs {
    foo: "bar".to_string(),
    optional_field: None,
});
let result = run_tool::<MyTool>(&MyApp, args, ctx)?;
```

This catches missing fields and type mismatches at compile time rather than runtime.

### `run_async_tool` returns no updates

**Symptoms:**
- `let (updates, terminal) = run_async_tool::<...>(...)`.
- `updates` is empty.

**Cause:**
- The async tool went straight to `complete()` without any `emit()` calls. Or the test runs faster than the tool's polling loop.

**Fix:**

Check whether `updates.is_empty()` is actually a bug or expected for this tool. Many async tools have legitimate fast paths — e.g. job already complete on first poll. Adjust the assertion to allow `>= 0` updates and only require `terminal.value` to be correct.

For tools that should always emit at least one progress update, audit the implementation — they may have a synchronous fast path that should be split into a separate sync tool.

## Manifest / Workspace

### "package not found in workspace" when running xtask

**Symptoms:**
- `cargo run -p xtask -- build-aomi --app <name>` errors with `package <name> not found in workspace`.

**Cause:**
- The app is not in the workspace's `exclude = [...]` list, or `xtask new-app` was never run.

**Fix:**

The aomi-apps workspace excludes app crates by default (they build as cdylibs which xtask handles separately). Add the new app to `exclude`:

```toml
# Cargo.toml (workspace root)
[workspace]
exclude = [
    "apps/<existing>",
    "apps/<your-new-app>",   # add this
]
```

`xtask new-app <name>` does this automatically. If you scaffolded by copying instead, you need to add it manually.

### Two apps with the same `name = "..."` in `dyn_aomi_app!`

**Symptoms:**
- Both apps build successfully.
- Host loads only one of them; the other is silently shadowed.

**Cause:**
- The `name` field in `dyn_aomi_app!` is the runtime identifier and must be unique across all loaded plugins.

**Fix:**

Change one of the names:

```rust
dyn_aomi_app!(
    app = client::MyApp,
    name = "my-app",       // must be unique
    ...
);
```

The crate name (`Cargo.toml` `[package].name`) and the app name don't have to match, but it's a good convention to keep them aligned.

## Diagnostic Checklist

When something doesn't work, run through these in order:

- [ ] `aomi-apps` repo is on the latest commit (`git -C ../aomi-apps log -1`)?
- [ ] SDK version in `sdk/Cargo.toml` matches the host's `AOMI_SDK_VERSION`?
- [ ] App's `Cargo.toml` is git-tracked (`git ls-files apps/<name>/Cargo.toml` returns the path)?
- [ ] App is in the workspace `exclude = [...]` list?
- [ ] `dyn_aomi_app!` has all required fields including `namespaces`?
- [ ] Every `Args` struct derives `Deserialize + JsonSchema`?
- [ ] Async tools set `const IS_ASYNC: bool = true` AND implement `run_async` (not `run`)?
- [ ] Every async tool path either calls `complete()` or returns `Err(...)`?
- [ ] HTTP clients have explicit timeouts?
- [ ] For wallet-handoff tools: `namespaces = ["common"]` and routes use typed `host::*` markers?
- [ ] For deprecated patterns: no remaining `SYSTEM_NEXT_ACTION` strings, no prose-only "next_step" hints?
