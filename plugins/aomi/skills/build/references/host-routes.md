# Host Routes

Read this when:

- The app you're building must hand off to the host wallet (sign, submit, broadcast) at some point.
- The app needs to chain multiple tool calls where a later step depends on an artifact produced by an earlier wallet callback (`signature`, `transaction_hash`).
- You see `ToolReturn` or `RouteStep` in an existing app and want to know what the runtime does with them.

## What this replaces

Older Aomi apps returned a `SYSTEM_NEXT_ACTION` field embedded inside a JSON payload, and the runtime parsed prose hints to figure out what to call next. **That convention is gone.** The current contract is structured: tools return `ToolReturn::with_routes(value, [...])` envelopes, the runtime resolves the routes mechanically, and prose is never parsed.

If you see `SYSTEM_NEXT_ACTION` in older code or docs, treat it as outdated. Replace it with a `RouteStep` that names the next tool by its `host::*` marker.

## The envelope

A tool returns either a bare `Value` (read-only) or a `ToolReturn` (with routes):

```rust
pub struct ToolReturn {
    pub value: Value,                 // the tool's structured payload
    pub routes: Vec<RouteStep>,       // ordered continuations
}
```

Tools opt into routes by overriding `run_with_routes()` instead of (or in addition to) `run()`. The default `run_with_routes()` impl wraps `run()` into `ToolReturn::value(...)` with empty routes — so non-routing tools need no changes.

```rust
impl DynAomiTool for BuildMyOrder {
    type App = MyApp;
    type Args = BuildMyOrderArgs;
    const NAME: &'static str = "build_my_order";
    const DESCRIPTION: &'static str = "Build an order and return the next signing step.";

    fn run_with_routes(
        _app: &Self::App,
        args: Self::Args,
        ctx: DynToolCallCtx,
    ) -> Result<ToolReturn, String> {
        // ... build typed_data, prepare submit_template ...
        Ok(ToolReturn::with_routes(
            json!({ "preview": preview, "wallet_request": typed_data.clone() }),
            [
                RouteStep::on_return("commit_eip712", typed_data)
                    .bind_as("clob_l1_signature")
                    .prompt("Sign the typed data to authorize the order."),
                RouteStep::on_bound_event(
                    "submit_my_order",
                    submit_template,
                    "clob_l1_signature",
                )
                .prompt("Wallet signed — submit the order now."),
            ],
        ))
    }
}
```

## RouteStep anatomy

```rust
pub struct RouteStep {
    pub tool: String,          // the next tool to call (host or app-local)
    pub args: Value,           // hinted args; aliases get spliced in
    pub trigger: RouteTrigger, // OnSyncReturn or OnBoundEvent { alias }
    pub bind_as: Option<String>, // publish this step's result under an alias
    pub prompt: Option<String>,  // override prompt text for this step
}
```

### Triggers

- **`RouteTrigger::OnSyncReturn`** (built via `RouteStep::on_return(...)`) — the route fires immediately when the current tool returns. Use this for "do the next thing right away" continuations.
- **`RouteTrigger::OnBoundEvent { alias }`** (built via `RouteStep::on_bound_event(..., alias)`) — the route fires when the named alias resolves in the session's artifact store. Wallet callbacks publish artifacts (`signature`, `transaction_hash`) under aliases, so a step bound to `"signature"` fires only after the wallet signs.

### Aliases (`bind_as`)

`bind_as` publishes the step's terminal result under the given alias in the session's artifact store. A later step with `OnBoundEvent { alias: "<same-name>" }` consumes that artifact. The runtime splices the artifact into hinted args automatically — you don't have to know the wallet callback shape, just bind the alias and reference it.

Wallet tools publish their callbacks under predictable aliases:

| Host tool | Callback artifact | Typical alias |
|-----------|-------------------|---------------|
| `commit_tx` | `transaction_hash` | `"transaction_hash"` (or domain-specific, e.g. `"approve_tx_hash"`) |
| `commit_eip712` | `signature` | `"signature"` (or domain-specific, e.g. `"clob_l1_signature"`) |
| `stage_tx` | `pending_tx_id` | `"pending_tx_id"` |

Pick descriptive aliases when you have multiple of the same kind in flight (e.g. `"approve_signature"` vs `"swap_signature"`).

### Typed targets

For host tools, prefer the typed `RouteTarget` markers in `aomi_sdk::builder::host` over raw string names:

```rust
use aomi_sdk::builder::host;

RouteStep::on_return_to::<host::CommitEip712>(typed_data)
    .bind_as("signature")
    .prompt("Sign the typed data.");

RouteStep::on_bound_to::<host::CommitTx>(submit_args, "pending_tx_id")
    .prompt("Broadcast the staged transaction.");
```

Available `host::*` markers (non-exhaustive — confirm against `sdk/src/builder.rs`): `ViewState`, `RunTx`, `StageTx`, `SimulateBatch`, `CommitTx`, `CommitEip712`. Using the marker types means renames in the host contract show up as compile errors instead of silent string drift.

## Fluent builder style

For multi-step routes with shared state, the `RouteBuilder` API is more readable than nested `with_routes([...])` calls:

```rust
use aomi_sdk::{RouteBuilder, ToolReturn};
use aomi_sdk::builder::host;

let mut route = RouteBuilder::new(value);

route.next(|next| {
    next.add::<host::ViewState>(allowance_args)
        .note("preflight allowance check; surface failures before continuing");
    next.add::<host::CommitEip712>(typed_data)
        .note("sign the typed data to authorize the order");
});

route.after(|after| {
    after.awaits("clob_l1_signature");
    after.next(|next| {
        next.add_named("submit_my_order", submit_template)
            .note("wallet signed — submit the order now");
    });
});

Ok(route.build())
```

`add::<T>()` resolves the tool name from a typed marker; `add_named(name, args)` is the escape hatch for app-local tools or markers you don't have a `RouteTarget` for. `.note(...)` sets the per-step `prompt` field.

## What the runtime does with routes

The runtime treats each route as advisory routing, not blind execution:

- **`OnSyncReturn` steps** render into the next system prompt the LLM sees. The model still chooses whether to call the suggested tool — routes are hints, not forced calls.
- **`OnBoundEvent` steps** wait in a queue until the named alias resolves. Wallet callbacks, staged-transaction completions, and other out-of-band events flow through the runtime's `RoutedEventBridge`, which splices the callback artifact into hinted args (the `signature` field in your hinted submit template gets filled with the actual signature when the wallet signs) before the continuation prompt is injected.
- **`bind_as` aliases** persist for the session's lifetime once published. A later step in a different tool call can still bind to them.

The runtime never parses prose. The route's structured fields — `tool`, `args`, `trigger`, `bind_as` — are the contract.

## When NOT to use routes

- **Pure read-only tools** (search, get, list). Return a bare `Value` from `run()`. Adding empty routes is noise.
- **Single-call writes that complete in-tool.** If your tool calls an HTTP submit endpoint and gets back a confirmation, return the confirmation as a `Value`. No host handoff needed.
- **Direct-mode flows where the SDK handles signing internally.** E.g. when the app is configured with a private key and submits through the upstream SDK's own sign-and-broadcast path. Use `ToolReturn::value(...)` with no routes and let the result speak for itself.

The rule of thumb: use routes when (a) the host wallet must take an action and (b) a follow-up tool needs the wallet's callback artifact. If neither applies, a bare `Value` is the right shape.

## Worked examples in the repo

- **`apps/khalani`** — quote → build → wallet sign → submit. Uses `RouteBuilder` with preflight allowance checks injected via `add::<host::ViewState>(...)`. Demonstrates `add_named` for app-local continuations and the `.after(...).awaits(...)` pattern for wallet callbacks.
- **`apps/polymarket`** — order preview → CLOB L1 signature → CLOB L2 signature → submit. Shows `bind_as("clob_l1_signature")` chaining and the wallet-mode vs direct-SDK-mode split.
- **`apps/polymarket-rewards`** — LP-position mutation flows with multiple bound aliases.

For a tool that doesn't need routes at all, `apps/binance` and `apps/oneinch` (read paths) are the cleanest references — they return bare `Value`s and let the model decide what to call next.

## Testing routes

`aomi_sdk::testing::run_tool` returns the full `ToolReturn`, so route assertions are straightforward:

```rust
use aomi_sdk::testing::{TestCtxBuilder, run_tool};
use serde_json::json;

#[test]
fn build_order_emits_signature_route() {
    let ctx = TestCtxBuilder::new("build_my_order").build();
    let result = run_tool::<BuildMyOrder>(&MyApp, json!({"market_id": "..."}), ctx).unwrap();

    assert_eq!(result.routes.len(), 2);
    assert_eq!(result.routes[0].tool, "commit_eip712");
    assert_eq!(result.routes[0].bind_as.as_deref(), Some("clob_l1_signature"));
    assert!(matches!(
        result.routes[1].trigger,
        RouteTrigger::OnBoundEvent { ref alias } if alias == "clob_l1_signature"
    ));
}
```

For async tools, `run_async_tool` returns `(updates, terminal)` — `terminal` is a `ToolReturn` with the same shape.
