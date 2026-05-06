# Supported Apps

Aomi exposes 25+ apps that bundle protocol-specific tools. Each app is a context the agent loads for the next request. The catalog is dynamic — always confirm against the live CLI:

```bash
aomi app list       # enumerate apps exposed by the backend
aomi app current    # show the currently active app
```

Select an app for a chat turn with `--app <name>` or set `AOMI_APP=<name>` for a multi-command shell. When an app needs provider credentials, the CLI reports at runtime what is missing.

> **Credentials column** indicates whether an app needs user-configured credentials at all. The CLI reports the specific variable names at runtime when something is missing. The user configures these themselves — the skill does not perform credential setup unless the user explicitly asks (see SKILL.md "Security").

## App Catalog

All apps share a common base toolset (`send_transaction_to_wallet`, `encode_and_simulate`, `get_account_info`, `get_contract_abi`, etc.). The tools listed below are the app-specific additions.

| App | Description | App-Specific Tools | Credentials |
|-----|-------------|-------------------|-------------|
| `default` | General-purpose on-chain agent with web search | `brave_search` | None |
| `binance` | Binance CEX — prices, order book, klines | `binance_get_price`, `binance_get_depth`, `binance_get_klines` | Exchange credentials |
| `bybit` | Bybit CEX — orders, positions, leverage | `brave_search` (no Bybit-specific tools yet) | Exchange credentials |
| `cow` | CoW Protocol — MEV-protected swaps via batch auctions | `get_cow_swap_quote`, `place_cow_order`, `get_cow_order`, `get_cow_order_status`, `get_cow_user_orders` | None |
| `defillama` | DefiLlama — TVL, yields, volumes, stablecoins | `get_token_price`, `get_yield_opportunities`, `get_defi_protocols`, `get_chain_tvl`, `get_protocol_detail`, `get_dex_volumes`, `get_fees_overview`, `get_protocol_fees`, `get_stablecoins`, `get_stablecoin_chains`, `get_historical_token_price`, `get_token_price_change`, `get_historical_chain_tvl`, `get_dex_protocol_volume`, `get_stablecoin_history`, `get_yield_pool_history` | None |
| `dune` | Dune Analytics — execute and fetch SQL queries | `execute_query`, `get_execution_status`, `get_execution_results`, `get_query_results` | Provider token |
| `dydx` | dYdX perpetuals — markets, orderbook, candles, trades | `dydx_get_markets`, `dydx_get_orderbook`, `dydx_get_candles`, `dydx_get_trades`, `dydx_get_account` | None |
| `gmx` | GMX perpetuals — markets, positions, orders, prices | `get_gmx_prices`, `get_gmx_signed_prices`, `get_gmx_markets`, `get_gmx_positions`, `get_gmx_orders` | None |
| `hyperliquid` | Hyperliquid perps — mid prices, orderbook | `get_meta`, `get_all_mids` | None |
| `kaito` | Kaito — crypto social search, trending, mindshare | `kaito_search`, `kaito_get_trending`, `kaito_get_mindshare` | Provider token |
| `kalshi` | Kalshi prediction markets via Simmer SDK | `simmer_register`, `simmer_status`, `simmer_briefing` | SDK token |
| `khalani` | Khalani cross-chain intents — quote, build, submit | `get_khalani_quote`, `build_khalani_order`, `submit_khalani_order`, `get_khalani_order_status`, `get_khalani_orders_by_address` | None |
| `lifi` | LI.FI aggregator — cross-chain swaps & bridges | `get_lifi_swap_quote`, `place_lifi_order`, `get_lifi_bridge_quote`, `get_lifi_transfer_status`, `get_lifi_chains` | Optional provider token |
| `manifold` | Manifold prediction markets — search, bet, create | `list_markets`, `get_market`, `get_market_positions`, `search_markets`, `place_bet`, `create_market` | Provider token |
| `morpho` | Morpho lending — markets, vaults, positions | `get_markets`, `get_vaults`, `get_user_positions` | None |
| `neynar` | Farcaster social — users, search | `get_user_by_username`, `search_users` | Provider token |
| `okx` | OKX CEX — tickers, order book, candles | `okx_get_tickers`, `okx_get_order_book`, `okx_get_candles` | Exchange credentials |
| `oneinch` | 1inch DEX aggregator — quotes, swaps, allowances | `get_oneinch_quote`, `get_oneinch_swap`, `get_oneinch_approve_transaction`, `get_oneinch_allowance`, `get_oneinch_liquidity_sources` | Provider token |
| `para` | Para — MPC wallet management across EVM, Solana, Cosmos (threshold signing) | (Para wallet tools — confirm with `aomi app current` after selecting) | Provider token |
| `para-consumer` | Para Consumer — consumer-wallet helper: prices, yield, swap quotes, bridge routes | (Consumer-facing read tools — confirm via runtime) | Provider token |
| `polymarket` | Polymarket prediction markets — search, trade, CLOB | `search_polymarket`, `get_polymarket_details`, `get_polymarket_trades`, `resolve_polymarket_trade_intent`, `build_polymarket_order_preview` | None |
| `polymarket-rewards` | Polymarket LP — liquidity provisioning into reward-enrolled markets, ranked by reward APY | (LP scoring + position tools — confirm via runtime) | Provider token |
| `x` | X/Twitter — users, posts, search, trends | `get_x_user`, `get_x_user_posts`, `search_x`, `get_x_trends`, `get_x_post` | Provider token |
| `yearn` | Yearn Finance — vault discovery, details | `get_all_vaults`, `get_vault_detail`, `get_blacklisted_vaults` | None |
| `zerox` | 0x DEX aggregator — swaps, quotes, liquidity | `get_zerox_swap_quote`, `place_zerox_order`, `get_zerox_swap_chains`, `get_zerox_allowance_holder_price`, `get_zerox_liquidity_sources` | Provider token |

## Categories

The same apps grouped by what kind of operation they support.

### DEX / DEX aggregators (on-chain swaps)

`uniswap` (always loaded as a built-in skill), `cow`, `oneinch`, `zerox`, `sushiswap`, `curve`. The agent picks the right one based on the user's request, or use `--app <name>` to force one.

### Lending

`aave`, `morpho`, `compound` (built-in), `yearn` (yield aggregator). Aave is the default for *"supply"* / *"borrow"* / *"repay"* prompts; Morpho is selected when the user names a market.

### Cross-chain / Bridges

`khalani`, `cctp` (built-in), `across` (built-in), `lifi`, `stargate` (built-in), `base_native` (built-in), `op_native` (built-in), `arbitrum_native` (built-in). Khalani and LiFi are intent-based aggregators; the others are protocol-direct.

### Liquid Staking

Built-in — no `--app` flag needed: `lido`, `rocket_pool`, `etherfi`, `kelp`, `renzo`, `mantle_staked_eth`. Each follows the same single-tx `submit()` / `deposit()` shape, with the issued LST as the receipt token.

### Perpetuals & Derivatives

`gmx`, `dydx`, `hyperliquid`. Read-only for the most part — the agent reports markets and prices. Order placement requires user-side credentials.

### Prediction Markets

`polymarket`, `polymarket-rewards`, `kalshi`, `manifold`. Polymarket has the deepest tool set including order preview.

### CEX (read-only)

`binance`, `bybit`, `okx`. Tickers, order books, candles. Trade execution requires exchange API credentials and is gated behind explicit user request.

### Social

`x` (Twitter), `neynar` (Farcaster), `kaito` (mindshare). Useful for *"what is X saying about Y?"* style prompts.

### Analytics / Data

`defillama` (TVL, yields, fees), `dune` (SQL queries). Read-only.

### Wallet management

`para` (MPC), `para-consumer`. Threshold signing across EVM/Solana/Cosmos.

### Game

`molinar` (on-chain world). Movement, exploration, chat — not transactional in the DeFi sense.

## Picking an app

Most of the time you don't need `--app`. The agent picks the right context based on the prompt:

```bash
aomi chat "supply 100 USDC on Aave" --new-session   # → aave
aomi chat "swap 1 ETH for USDC" --new-session       # → uniswap (or cow / 1inch / 0x as agent picks)
aomi chat "bridge 50 USDC to Base" --new-session    # → cctp / across (agent picks based on speed/cost)
```

Override only when the user asks for a specific protocol:

```bash
aomi chat "swap 100 USDC for WETH using CoW" --app cow --new-session
aomi chat "what's the dydx ETH-USD orderbook?" --app dydx --new-session
```

For a multi-command session on a non-default app, set the env var:

```bash
export AOMI_APP=khalani
aomi chat "quote 100 USDC from Polygon to Base"
aomi chat "build the order"
aomi tx sign tx-1
```

## Credentials

Credentials are scoped to the active session. Inspect with `aomi secret list` (handle names only — no values are ever printed). To configure (only when the user explicitly asks and provides the value):

```bash
aomi secret add NEYNAR_API_KEY=neynar_...
aomi secret add BINANCE_API_KEY=... BINANCE_API_SECRET=...
```

**Trust-boundary warning**: `aomi secret add` transmits the credential value to the aomi backend and stores a handle locally. If the user prefers the value to stay entirely local, advise them to export it in their own shell environment instead and let the CLI read from there. See SKILL.md "Security" for the full rule.

## Building a new app

To add a new app from an OpenAPI spec or SDK docs, use the companion skill **aomi-build** in [aomi-labs/skills](https://github.com/aomi-labs/skills/tree/main/aomi-build). It scaffolds the Rust crate (`lib.rs`, `client.rs`, `tool.rs`), tool schemas, preambles, and host-interop flows.
