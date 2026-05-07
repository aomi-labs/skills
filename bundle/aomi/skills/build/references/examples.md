# Build Examples

Read this when:

- You need to translate a concrete spec or doc set into a working app.
- You want to see the SKILL.md guidance applied end-to-end.
- You're deciding what kind of app to build and want to pattern-match against a real one in `apps/`.

Each example is anchored to a real app crate in `aomi-apps`. Code excerpts come directly from those crates; the **"What you'd type"** blocks show how you'd brief the skill to reproduce them.

The build lifecycle is consistent across every example:

> **identify surface** → **propose toolset** → **scaffold** → **wire client + tools** → **build + test** → **handoff hooks**

If you only remember one thing: **don't mirror endpoints; map user intents.** A spec with 20 endpoints is rarely 20 tools. It's usually 4-8.

---

## 1. CEX read + signed orders — `apps/binance` shape

**Anchored to** `apps/binance/src/{lib.rs, client.rs, tool.rs, types.rs}`. The canonical "exchange API" shape: HMAC auth, public reads, signed writes, normalized response models.

### Source material

A REST API doc (Binance Spot v3) with ~30 endpoints across:

- public: tickers, depth, klines, 24h stats
- signed (HMAC-SHA256): place order, cancel order, account balances, trade history

### What you'd type

> "Build an Aomi app for Binance Spot. Cover the main public reads (price, depth, klines, 24h stats) plus signed order placement and account queries. Auth is HMAC-SHA256 with `BINANCE_API_KEY` + `BINANCE_SECRET_KEY`. Trading pairs use uppercase no-separator format (BTCUSDT)."

### Tool decisions

Resist 1:1 mapping. The spec has 30+ endpoints; the user intent reduces to 8 tools:

| Tool name | Intent | Endpoint(s) |
|-----------|--------|-------------|
| `binance_get_price` | "what's the price of X?" | `GET /ticker/price` |
| `binance_get_depth` | "what's the order book for X?" | `GET /depth` |
| `binance_get_klines` | "give me OHLC for technical analysis" | `GET /klines` |
| `binance_get_24hr_stats` | "rolling 24h stats" | `GET /ticker/24hr` |
| `binance_place_order` | "submit a buy/sell order" | `POST /order` (signed) |
| `binance_cancel_order` | "cancel my order" | `DELETE /order` (signed) |
| `binance_get_account` | "what's my balance?" | `GET /account` (signed) |
| `binance_get_trades` | "my fill history" | `GET /myTrades` (signed) |

Skip: server time, exchange info, system status, sub-account endpoints, futures (a separate app), savings, staking, mining. They'd bloat the model's tool surface without serving a clear primary user intent.

### Manifest (`lib.rs`)

```rust
use aomi_sdk::*;

mod client;
mod tool;
mod types;

const PREAMBLE: &str = r#"## Role
You are an AI assistant specialized in interacting with the Binance cryptocurrency exchange...

## Authentication
- Public market data endpoints do not require authentication
- Signed endpoints (orders, account, trades) require both api_key and secret_key
- The signature is computed as HMAC-SHA256(secret_key, query_string_with_timestamp)
- The timestamp parameter is appended automatically before signing

## Execution Guidelines
- Use price tickers for quick spot checks; use klines for technical analysis
- Check account balance before placing orders
- Order quantities and prices must respect lot size and tick size filters
- Always verify the trading pair exists before placing orders"#;

dyn_aomi_app!(
    app = client::BinanceApp,
    name = "binance",
    version = "0.1.0",
    preamble = PREAMBLE,
    tools = [
        client::GetPrice,
        client::GetDepth,
        client::GetKlines,
        client::Get24hrStats,
        client::PlaceOrder,
        client::CancelOrder,
        client::GetAccount,
        client::GetTrades,
    ],
    namespaces = ["common"]
);
```

`namespaces = ["common"]` because the app exposes signed-order tools — even though Binance handles signing internally (HMAC), the app is execution-oriented and may grow to use host wallet tools later. For purely-read apps you'd use `namespaces = []`.

### Client (`client.rs`) — auth and helpers

Keep all third-party API quirks in `client.rs`. Tools should never see them.

```rust
use hmac::{Hmac, Mac};
use sha2::Sha256;

type HmacSha256 = Hmac<Sha256>;

pub(crate) fn sign(secret_key: &str, query_string: &str) -> Result<String, String> {
    let mut mac = HmacSha256::new_from_slice(secret_key.as_bytes())
        .map_err(|e| format!("[binance] failed to create HMAC key: {e}"))?;
    mac.update(query_string.as_bytes());
    Ok(hex_encode(&mac.finalize().into_bytes()))
}

pub(crate) const SPOT_BASE_URL: &str = "https://api.binance.com/api/v3";

pub(crate) struct BinanceClient {
    pub(crate) http: reqwest::blocking::Client,
}

impl BinanceClient {
    pub(crate) fn new() -> Result<Self, String> {
        let http = reqwest::blocking::Client::builder()
            .timeout(Duration::from_secs(30))
            .build()
            .map_err(|e| format!("[binance] failed to build HTTP client: {e}"))?;
        Ok(Self { http })
    }
    // public_get, signed_get, signed_post helpers...
}
```

### Tool args (`client.rs`) — typed with `JsonSchema`

```rust
#[derive(Debug, Deserialize, JsonSchema)]
pub(crate) struct GetPriceArgs {
    /// Trading pair symbol (e.g., "BTCUSDT", "ETHUSDT"). If omitted, returns prices for all symbols.
    pub(crate) symbol: Option<String>,
}

pub(crate) struct GetPrice;
```

The doc comment on `symbol` becomes the model-facing schema description. It matters — write it for the model, not for the developer.

### Tool impl (`tool.rs`)

```rust
impl DynAomiTool for GetPrice {
    type App = BinanceApp;
    type Args = GetPriceArgs;
    const NAME: &'static str = "binance_get_price";
    const DESCRIPTION: &'static str =
        "Get the latest price for a trading pair, or all trading pairs if no symbol is specified.";

    fn run(_app: &BinanceApp, args: Self::Args, _ctx: DynToolCallCtx) -> Result<Value, String> {
        let client = BinanceClient::new()?;
        let query = match &args.symbol {
            Some(s) => format!("symbol={s}"),
            None => String::new(),
        };
        ok(client.public_get::<BinancePriceResponse>(SPOT_BASE_URL, "/ticker/price", &query)?)
    }
}
```

The `ok(...)` helper at the top of `tool.rs` adds a stable `"source": "binance"` field to every response — this prevents accidental name collisions when results from multiple apps appear in the same conversation history.

### Validation

```bash
cargo run -p xtask -- new-app binance      # if scaffolding from scratch
cargo run -p xtask -- build-aomi --app binance
```

Add a unit test for the args-encoding logic (the HMAC query-string canonicalization is the kind of thing that breaks silently):

```rust
#[test]
fn signed_query_string_includes_timestamp() {
    let qs = build_signed_query("symbol=BTCUSDT", 1700000000000);
    assert!(qs.contains("timestamp=1700000000000"));
    assert!(qs.contains("signature="));
}
```

### Pattern notes

- **Auth resolution lives in tool.rs**, not in `lib.rs`. `resolve_secret_value(arg, ENV_VAR, error_msg)` reads from the explicit tool arg first, then falls back to environment. This pattern repeats across every credentialed app — see `apps/dune`, `apps/neynar`, `apps/x` for the same shape.
- **Errors are short and prefixed.** `[binance] missing api_key argument and BINANCE_API_KEY environment variable` — never raw upstream HTML or stack traces.
- **One tool per user intent.** `binance_get_price` covers the symbol-or-all-symbols variation through an optional arg, not two tools.

---

## 2. SDK-only / builder-oriented — when no public API exists

Anchored to the **fallback case** — the source material is mostly SDK docs and example repos with no public hosted API. The right move is a builder assistant, not a fake transactional client.

### Source material

A protocol's docs link to:

- a Rust/TS SDK on GitHub
- an example client repo
- a self-hosted node config + RPC reference
- architecture diagrams

There is no `https://api.<protocol>.com` to call.

### What you'd type

> "Build an Aomi app for `<protocol>`. The docs mostly describe how to integrate via their SDK and run a self-hosted node. There's no public REST API. Make a builder assistant that helps users understand the SDK surface, find example commands, and look up RPC/network defaults."

### What NOT to do

- Don't invent endpoints like `https://api.protocol.com/swap/quote` if the docs don't publish one.
- Don't claim the app can submit transactions when it can't.
- Don't generate tools named `place_order` or `submit_swap` against a service that doesn't exist.

### Tool decisions

| Tool name | Intent | Source |
|-----------|--------|--------|
| `list_<protocol>_resources` | "what's available in this ecosystem?" | curated index of SDK packages, example repos, docs |
| `get_<protocol>_overview` | "high-level architecture" | architecture doc summary |
| `get_<protocol>_quickstart` | "how do I run this locally?" | quickstart commands from README |
| `get_<protocol>_rpc_surface` | "what RPC methods are available?" | RPC reference |
| `get_<protocol>_defaults` | "default ports, chain IDs, addresses" | config reference |

These are deliberately read-only, doc-shaped tools. The preamble must surface this:

```rust
const PREAMBLE: &str = r#"## Role
You are a builder assistant for `<protocol>`. You help developers understand
the SDK surface and run a local example stack. **You are NOT an end-user
trading agent.** This protocol does not expose a hosted public API for swaps
or transactions; users who want to execute on-chain operations must run their
own node or service.

## Workflow
1. Use `list_*_resources` to enumerate the available SDK packages and examples.
2. Use `get_*_quickstart` for concrete commands to run a local example.
3. Use `get_*_rpc_surface` and `get_*_defaults` for integration details.

## Guardrails
- Do not pretend a hosted public API exists.
- Do not generate calldata for protocols that require user-side signing.
- If a user asks for a swap or trade, explain that they need to run their own
  service against the SDK and provide the relevant quickstart.
"#;
```

### Pattern notes

- **Builder apps are valid outcomes**, but they're the fallback, not the default. Always check first whether the SDK produces a runnable service the app could call.
- **The "upgrade path" matters.** If the user later spins up a hosted instance, the builder app should be replaceable with a real client app. Keep tool names suffixed with `_resources` / `_overview` / `_quickstart` / `_defaults` so it's clear at a glance which is which.
- See `references/spec-to-tools.md` "Builder-oriented fallbacks" for more detail.

---

## 3. Adding wallet handoff to an existing app — `run` → `run_with_routes`

**Anchored to** `apps/polymarket/src/tool.rs`. Demonstrates upgrading a `Value`-returning tool to a `ToolReturn`-with-routes tool when the app needs to chain into host wallet tools.

### Before — bare `run` returning `Value`

```rust
impl DynAomiTool for BuildPolymarketOrder {
    type App = PolymarketApp;
    type Args = BuildPolymarketOrderArgs;
    const NAME: &'static str = "build_polymarket_order";
    const DESCRIPTION: &'static str = "Build a Polymarket order preview.";

    fn run(_app: &PolymarketApp, args: Self::Args, ctx: DynToolCallCtx) -> Result<Value, String> {
        let client = PolymarketClient::new()?;
        let preview = client.build_preview(&args)?;
        Ok(json!({ "preview": preview, "next_step": "User must sign typed data manually" }))
    }
}
```

This works for direct-SDK mode where the app holds the private key and submits internally. But for wallet-mode (the user's wallet signs), the prose `"next_step"` field is brittle — the runtime can't act on it.

### After — `run_with_routes` returning `ToolReturn`

```rust
use aomi_sdk::{RouteStep, ToolReturn, builder::host};

impl DynAomiTool for BuildPolymarketOrder {
    type App = PolymarketApp;
    type Args = BuildPolymarketOrderArgs;
    const NAME: &'static str = "build_polymarket_order";
    const DESCRIPTION: &'static str =
        "Build a canonical Polymarket order preview and continuation template. \
         This tool never places the order itself. In wallet mode it also returns \
         the explicit post-confirmation signing sequence.";

    fn run_with_routes(
        _app: &PolymarketApp,
        args: Self::Args,
        ctx: DynToolCallCtx,
    ) -> Result<ToolReturn, String> {
        let connected_wallet = args
            .wallet_address
            .clone()
            .or_else(|| ctx.attribute_string(&["domain", "evm", "address"]));
        let (mode, wallet_address) = determine_polymarket_execution(connected_wallet.as_deref())?;

        let client = PolymarketClient::new()?;
        let preview = client.build_preview(&args)?;

        match mode {
            ExecutionMode::DirectSdk => {
                // SDK handles signing; no host handoff needed
                Ok(ToolReturn::value(json!({
                    "preview": preview,
                    "execution_mode": "DIRECT_SDK",
                })))
            }
            ExecutionMode::Wallet => {
                let typed_data = build_clob_l1_typed_data(&preview, &wallet_address)?;
                let submit_template = build_submit_template(&preview);

                Ok(ToolReturn::with_routes(
                    json!({
                        "preview": preview,
                        "execution_mode": "WALLET",
                        "wallet_request": typed_data.clone(),
                    }),
                    [
                        RouteStep::on_return_to::<host::CommitEip712>(typed_data)
                            .bind_as("clob_l1_signature")
                            .prompt("Sign the CLOB L1 authorization."),
                        RouteStep::on_bound_to::<SubmitPolymarketOrder>(
                            submit_template,
                            "clob_l1_signature",
                        )
                        .prompt("Wallet signed — submit the order."),
                    ],
                ))
            }
        }
    }
}
```

### What changed

| Before | After |
|--------|-------|
| `fn run(...) -> Result<Value, String>` | `fn run_with_routes(...) -> Result<ToolReturn, String>` |
| Returned `json!({...})` | Returns `ToolReturn::value(...)` or `ToolReturn::with_routes(...)` |
| Prose `"next_step"` field | Structured `RouteStep` with typed `host::CommitEip712` target |
| Runtime couldn't act on next-step hint | Runtime mechanically chains: sign → bind alias → submit |

Tools that don't need routes need **no changes** — the default `run_with_routes()` impl wraps `run()` into `ToolReturn::value(...)` automatically.

### Manifest update

Add `"common"` to `namespaces` if it wasn't already there:

```rust
dyn_aomi_app!(
    app = client::PolymarketApp,
    name = "polymarket",
    version = "0.1.0",
    preamble = PREAMBLE,
    tools = [...],
    namespaces = ["common"]   // required because routes reference host::CommitEip712
);
```

### Pattern notes

- **Don't convert tools that don't need it.** `get_polymarket_details`, `search_polymarket` are pure reads — leave them as `run`. Only the build/submit tools get the routes treatment.
- **Match the `bind_as` alias to the wallet artifact.** `commit_eip712` callbacks publish a `signature`; bind it under a domain-specific name like `"clob_l1_signature"` so multi-sign flows don't collide.
- **The prompt field is a hint.** The runtime renders it into the next system prompt for the LLM, but doesn't force the call. Keep prompts short and action-oriented (*"Sign the typed data"*, *"Submit the order"*).
- See `references/host-routes.md` for the full route contract.

---

## 4. Async tool with cancellation — `apps/sdk/examples/hello-app` shape

**Anchored to** `sdk/examples/hello-app/src/lib.rs`. Use this when the tool emits progress over time (polling a long-running job, streaming events, scanning a slow upstream) and must respect cancellation.

### Source material

A REST API with a long-poll endpoint, a websocket stream, or any operation that doesn't return synchronously within a few seconds.

### What you'd type

> "Wrap this poll endpoint as an Aomi async tool. It returns updates over a few minutes and the user might cancel mid-stream."

### Tool impl

```rust
impl DynAomiTool for PollJobStatus {
    type App = MyApp;
    type Args = PollJobStatusArgs;
    const NAME: &'static str = "poll_job_status";
    const DESCRIPTION: &'static str = "Poll a long-running job until terminal status.";
    const IS_ASYNC: bool = true;     // ← the key flag

    fn run_async(
        app: &Self::App,
        args: Self::Args,
        ctx: DynToolCallCtx,
        sink: DynAsyncSink,           // ← async sink, not Result<Value, String>
    ) -> Result<(), String> {
        let client = MyClient::new()?;

        loop {
            // Cooperative cancellation check
            if sink.is_canceled() {
                return Ok(());
            }

            let status = client.get_job_status(&args.job_id)?;

            if status.is_terminal() {
                // Final result via complete()
                sink.complete(json!({
                    "job_id": args.job_id,
                    "status": status.kind,
                    "result": status.result,
                }))?;
                return Ok(());
            } else {
                // Progress update via emit()
                sink.emit(json!({
                    "job_id": args.job_id,
                    "status": status.kind,
                    "progress": status.progress,
                }))?;
                std::thread::sleep(Duration::from_millis(args.poll_interval_ms.unwrap_or(1000)));
            }
        }
    }
}
```

### Hard rules for async tools

| Rule | Reason |
|------|--------|
| Set `const IS_ASYNC: bool = true` | The macro generates different FFI exports for async; without this flag the runtime calls `run` and never reads the sink |
| Implement `run_async`, NOT `run` | Mixing both is a confusing footgun — pick one |
| Poll `sink.is_canceled()` regularly | The runtime sets this when the user aborts; without polling, the tool hangs |
| Use `emit(...)` for progress, `complete(...)` for the final value | `complete` signals terminal status to the runtime; `emit` adds an intermediate update |
| Don't return a `Value` from `run_async` | Return `Result<(), String>` — the data path is the sink, not the return |
| Don't return route envelopes from `emit` | Only `complete()` accepts `ToolReturn` envelopes; intermediate `emit` calls take bare `Value`s |

### Testing async tools

```rust
use aomi_sdk::testing::{TestCtxBuilder, run_async_tool};
use serde_json::json;

#[test]
fn poll_emits_progress_then_completes() {
    let ctx = TestCtxBuilder::new("poll_job_status").build();
    let (updates, terminal) = run_async_tool::<PollJobStatus>(
        &MyApp,
        json!({ "job_id": "test-job", "poll_interval_ms": 10 }),
        ctx,
    ).unwrap();

    assert!(updates.len() >= 1);
    assert_eq!(terminal.value["status"], "completed");
}
```

`run_async_tool` returns `(updates, terminal)` — assert both shapes. `updates` is a `Vec<Value>` of intermediate `emit` payloads; `terminal` is a `ToolReturn` (with optional routes) from the final `complete` or from a returned error.

### Pattern notes

- **Don't spawn Tokio inside `run_async`**. The runtime drives the call on its own thread. Use `std::thread::sleep` for delays, blocking HTTP for I/O.
- **Cancellation is cooperative.** If your inner loop calls a blocking HTTP request, the cancellation can only fire between requests — not mid-request. For very long requests, prefer chunked or streaming HTTP that yields control.
- **Panic containment is automatic.** If `run_async` panics, the runtime catches it and surfaces an error to the LLM rather than crashing the host. See `apps/sdk/examples/hello-app/src/lib.rs` `PanicSyncTool` for a deliberate test of this path.

---

## 5. Updating an app for a new SDK version

**Anchored to** the exact-match SDK version gate documented in `docs/sdk-version-compatibility.md`. The host rejects plugins whose `aomi_sdk_version` symbol does not match its compiled `AOMI_SDK_VERSION`. After bumping `sdk/Cargo.toml`, all apps must be rebuilt — there's no per-app version negotiation.

### When this comes up

- Routine SDK bumps (`0.1.14` → `0.1.15`).
- Adding a new `host::*` tool marker that an existing app would benefit from.
- Adopting new SDK APIs (e.g. `RouteBuilder` fluent style replacing manual `with_routes`).

### What you'd type

> "Update `apps/<name>` for the new SDK version. The SDK introduced `<feature>`; refactor the relevant tools."

### Workflow

1. **Check `sdk/Cargo.toml`** — confirm the new SDK version. The workspace `Cargo.toml` uses `{ workspace = true }` for `aomi-sdk`, so individual apps don't pin a version.
2. **Search for deprecated patterns**:
   ```bash
   # Hunt for prose-based hand-off (legacy)
   git grep 'SYSTEM_NEXT_ACTION' apps/<name>/

   # Hunt for tools that should now use route hints
   git grep 'next_step\|"requires_signature"' apps/<name>/
   ```
3. **Convert tools that should benefit** — see Example 3 above for `run` → `run_with_routes`.
4. **Add `namespaces`** if you've grown into using host tools:
   ```rust
   dyn_aomi_app!(
       ...
       namespaces = ["common"]   // was []
   );
   ```
5. **Rebuild + test:**
   ```bash
   cargo run -p xtask -- build-aomi --app <name>
   cargo test -p <name>
   ```
6. **Confirm the host accepts the new plugin.** Load it in your local runtime; the host logs the SDK version match check on plugin load.

### Pattern notes

- **The version gate is exact-match, not semver-compatible.** A `0.1.14` plugin will NOT load against a `0.1.15` host even though `0.1.14` and `0.1.15` are semver-compatible. This is by design — the FFI surface and manifest format live inside `aomi-sdk`, and the hosted runtime treats SDK drift as a coordinated rebuild.
- **If you only changed app code, no rebuild is needed.** App-only release tags (`apps-v0.1.X`) don't change `AOMI_SDK_VERSION` and don't trigger a forced rebuild.
- **The version stamp is automatic.** The plugin exports `aomi_sdk_version` as a symbol via the macro — you never write the version in app code.

---

## What All Five Examples Have in Common

- **Decide the app type before naming tools.** Product client (real API), execution assistant (build/submit/sign), or builder assistant (SDK + docs only). The wrong call here cascades into wrong tool names and wrong preamble.
- **Tool surface is shaped by user intent, not by endpoint count.** 30 endpoints rarely need 30 tools. 3-8 intent-shaped tools (`search_*`, `get_*`, `build_*`, `submit_*`) usually beat raw endpoint mirroring.
- **Auth resolution lives in tool boundary code**, not the app struct. Read explicit args first, fall back to env vars, never embed credentials in preambles or tool descriptions.
- **`namespaces = ["common"]`** for any app that uses host tools (`stage_tx`, `commit_tx`, `commit_eip712`, etc.) or returns `ToolReturn::with_routes` envelopes. Read-only apps use `namespaces = []`.
- **Prefer typed JSON shapes.** Args are `JsonSchema + Deserialize` structs; client responses are typed deserializations from `client.rs`; tool outputs add a stable `"source"` field for cross-app deduplication.
- **The build loop is `cargo run -p xtask -- build-aomi --app <name>` after the manifest is tracked.** For untracked apps, use `cargo build --manifest-path apps/<name>/Cargo.toml` until you've added the crate to git.
- **Validate against a real target when one is available.** A passing compile is necessary but not sufficient — call the real API for at least one read flow before declaring the app done.

For deeper coverage of specific patterns:

- File roles, real-app conventions, and the validation loop → [aomi-sdk-patterns.md](aomi-sdk-patterns.md)
- Spec-to-tool reduction with mapping rubrics → [spec-to-tools.md](spec-to-tools.md)
- The full `ToolReturn` / `RouteStep` contract → [host-routes.md](host-routes.md)
- Common build errors and recovery → [troubleshooting.md](troubleshooting.md)
