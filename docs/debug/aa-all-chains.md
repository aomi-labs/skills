# AA support across supported chains

Source of truth:
- `packages/client/src/chains.ts` — chain IDs, names, viem mappings, `ALCHEMY_CHAIN_SLUGS`
- `packages/client/src/aa/types.ts` (`DEFAULT_AA_CONFIG`, lines 220–266) — per-chain mode/sponsorship/batching config
- `packages/client/src/aa/alchemy/create.ts` — Alchemy 4337 + raw 7702 paths
- `aa-bug-report.md` — observed real-run results from session-43

## Chain × AA matrix

| Chain ID | Name | Alchemy slug | AA configured | Default mode | Supported modes | Batching | Sponsorship | Observed status |
|---|---|---|---|---|---|---|---|---|
| 1 | Ethereum | `eth-mainnet` | ✅ | `7702` | `4337`, `7702` | ✅ | optional | ✅ Confirmed working — 3 successful AA-7702 tx, EOA paid gas (~0.000011–0.000017 ETH) |
| 137 | Polygon | `polygon-mainnet` | ✅ | `4337` | `4337`, `7702` | ✅ | optional | ⚠️ Untested in report; same proxy path as Base — likely affected by sponsorship issue if EOA has 0 native |
| 42161 | Arbitrum One | `arb-mainnet` | ✅ | `4337` | `4337`, `7702` | ✅ | optional | ⚠️ Untested in report; same proxy path as Base — likely affected |
| 10 | Optimism | `opt-mainnet` | ✅ | `4337` | `4337`, `7702` | ✅ | optional | ⚠️ Untested in report; same proxy path as Base — likely affected |
| 8453 | Base | `base-mainnet` | ✅ | `4337` | `4337`, `7702` | ✅ | optional | ❌ **Broken** — `--aa --aa-mode 4337` falls through to direct EOA send, fails with viem `insufficient funds for transfer` when EOA has 0 ETH on L2 |
| 11155111 | Sepolia | `eth-sepolia` | ❌ | — | — | — | — | Not in `DEFAULT_AA_CONFIG.chains` — AA disabled, EOA only |
| 31337 | Anvil (local) | — | ❌ | — | — | — | — | Not in `DEFAULT_AA_CONFIG.chains`, no Alchemy slug — AA disabled, EOA only |

## Notes

- "AA configured" = chain appears in `DEFAULT_AA_CONFIG.chains` with `enabled: true`. Sepolia and Anvil are intentionally absent.
- "Default mode" is what `buildAAExecutionPlan` picks when the user passes no `--aa-mode`. Ethereum is the only chain defaulting to `7702`; all production L2s default to `4337`.
- "Sponsorship: optional" means `gasPolicyId` is applied iff `sponsored: true` AND mode is `4337` (`alchemy/create.ts:163`). For `7702`, gas policy is dropped and the EOA pays — see the warning at `alchemy/create.ts:380-384`.
- The zero-config proxy URL is `${baseUrl}/aa/v1/${alchemy_slug}` (`cli/execution.ts:157-186`). When BYOK is absent, `4337` requests go through `https://staging-api.aomi.dev/aa/v1/<slug>`. Whether the backend has a paymaster policy attached for each slug is **not** verifiable from this repo.
- `ALCHEMY_CHAIN_SLUGS[8453]` returns `"base-mainnet"`. The bug report's hypothesis #3 ("wrong slug") is ruled out — the slug matches Alchemy's URL convention.

## Open questions (for backend / infra)

1. Does `staging-api.aomi.dev/aa/v1/{polygon-mainnet, arb-mainnet, opt-mainnet, base-mainnet}` have a paymaster policy attached? If only `eth-mainnet` does, every L2 in this table is broken in the same way.
2. When the proxy returns a UserOp without paymaster sig, does `@alchemy/wallet-apis` `sendCalls` silently route to a direct EOA submission, or is the viem error surfacing from somewhere else? The "Request Arguments" block in the bug report (`from = EOA`, raw approve calldata) suggests it's not going through `wallet_sendPreparedCalls` at all.
3. Should Sepolia be added to `DEFAULT_AA_CONFIG` for testnet smoke tests? It would let CI verify the proxy end-to-end without burning real funds.

## Empirical results — 2026-04-29 session-43 reproduction

Test action: 0-value self-transfer, wallet `0x5D907BEa404e6F821d467314a9cA07663CF64c9B`, BYOK Alchemy (`ALCHEMY_API_KEY` set, so 4337 path goes to real Alchemy Wallets API at `api.g.alchemy.com/v2`, **not** the staging-api proxy that the original bug report used). Each row is one `aomi tx sign --aa --aa-mode <mode>` invocation.

Pre-test native balances:

| Chain | Balance |
|---|---|
| Ethereum (1) | 0.0569 ETH |
| Polygon (137) | 0.0412 MATIC |
| Arbitrum (42161) | 0 ETH |
| Optimism (10) | 0 ETH |
| Base (8453) | 0 ETH |

### Results

| Chain | Mode requested | AA 4337 result | AA 7702 result | Final exec path | Tx hash / outcome | Service fee charged |
|---|---|---|---|---|---|---|
| Ethereum (1) | `4337` | `wallet_prepareCalls` → `execution reverted` (paymaster policy `fb17d7d7-…` rejected the call) | retry → `eth_estimateUserOperationGas` → `AA23 reverted` (account validation) | **EOA fallback** (despite `--aa`) | ✅ `0x1ffbfa5287ba5d98a15499456cea141fee8756fccb1257c52eb9dc97d4846bbb` (count: 2) | 0.000002 ETH |
| Ethereum (1) | `7702` | retry → `wallet_prepareCalls` → `execution reverted` | `eth_estimateUserOperationGas` → `AA23 reverted` | **EOA fallback** (despite `--aa`) | ✅ `0x7503fd1a9ed5e8324e5e07c19cc963f3a33d3626b717415c39bd2c6d6af0e0d5` (count: 2) | 0.000002 ETH |
| Polygon (137) | `4337` | `wallet_prepareCalls` → `execution reverted` | retry → `AA23 reverted` | **EOA fallback** (despite `--aa`) | ✅ `0x54d40527e61789fb1d8e08e82d8a57471cae4094f905e5047ac6d99c7d693d47` (count: 2) | 0.000260 MATIC |
| Polygon (137) | `7702` | retry → `wallet_prepareCalls` → `execution reverted` | `User operation must include a paymaster for sponsorship` (Polygon-specific bundler requirement) | **EOA fallback** (despite `--aa`) | ✅ `0x989552c33ef4ee6d261b9db279dc6609f0dab05ce97807f2ded792beb8dd4a78` (count: 2) | 0.000265 MATIC |
| Arbitrum (42161) | `4337` | `wallet_prepareCalls` → `execution reverted` | retry → `AA23 reverted` | EOA fallback attempted but **failed: `insufficient funds for transfer`** (0 ETH balance) | ❌ tx-5 stays pending; CliExit 1 | — |
| Arbitrum (42161) | `7702` | retry → `wallet_prepareCalls` → `execution reverted` | `AA23 reverted` | EOA fallback attempted but **failed: insufficient funds** | ❌ tx-5 stays pending; CliExit 1 | — |
| Optimism (10) | `4337` | `wallet_prepareCalls` → `execution reverted` | retry → `AA23 reverted` | EOA fallback attempted but **failed: insufficient funds for gas \* price + value: balance 0, tx cost 40823907003** | ❌ tx-6 stays pending; CliExit 1 | — |
| Optimism (10) | `7702` | retry → `wallet_prepareCalls` → `execution reverted` | `AA23 reverted` | EOA fallback attempted but **failed: insufficient funds, balance 0, tx cost 41044251126** | ❌ tx-6 stays pending; CliExit 1 | — |
| Base (8453) | `4337` | `wallet_prepareCalls` → `execution reverted` | retry → `AA23 reverted` | EOA fallback attempted but **failed: insufficient funds for gas \* price + value: have 0 want 151200000000** | ❌ tx-7 stays pending; CliExit 1 | — |
| Base (8453) | `7702` | retry → `wallet_prepareCalls` → `execution reverted` | `AA23 reverted` | EOA fallback attempted but **failed: insufficient funds, have 0 want 151200000000** | ❌ tx-7 stays pending; CliExit 1 | — |

### Findings (in order of severity)

1. **`--aa` does NOT prevent EOA fallback.** Documented behavior: "`--aa`: require AA only … no EOA fallback." Observed: every successful row above is an EOA-signed tx (`exec: eoa` in `aomi tx list`). The CLI logs `[aomi][aa] AA execution failed; falling back to EOA` even with `--aa`. This is a **separate bug** from the original Base report and is the more consequential one — users who explicitly opt out of EOA still pay EOA gas.

2. **AA 4337 is broken on every supported chain via the BYOK Alchemy Wallets API path.** `wallet_prepareCalls` returns "execution reverted" with policy ID `fb17d7d7-9a32-479d-937a-52d72b849c40`. Either the policy doesn't cover any of these chains, the `from` address (`0xF28A6eDc38896B27C248e0b11Df7f7ab8936F94b` — a derived smart-account address, not the EOA) isn't whitelisted, or the policy itself is misconfigured.

3. **AA 7702 is broken on every supported chain via the BYOK SDK path.** `eth_estimateUserOperationGas` returns `AA23 reverted` (account validation). This routes through `@getpara/aa-alchemy` (`alchemy/create.ts:190` `createAlchemySdkState` because `options.apiKey` is set), bypassing the working raw-viem path at `createAlchemy7702State`. The bug-report's three successful 7702 mainnet tx must have run with **no** `ALCHEMY_API_KEY`, taking the raw-viem path instead.

4. **Polygon's bundler requires a paymaster for ALL UserOps.** Even when 7702 is requested, Alchemy's Polygon endpoint rejects with "User operation must include a paymaster for sponsorship" (linked to https://www.alchemy.com/docs/wallets/resources/chain-reference/polygon-pos#transactions). This is a chain-specific quirk worth documenting in the AA reference.

5. **The original Base bug reproduces identically on Arbitrum and Optimism.** All three L2s with 0 native balance fail the same way: AA 4337 fails, AA 7702 fails, EOA fallback fails for lack of gas, tx stays pending. Severity is broader than the bug report claimed — three of the four L2s in `DEFAULT_AA_CONFIG` are affected.

6. **The 4337 calldata always includes a service-fee call** to `0x9C7a99480c59955a635123EDa064456393e519f5` as a second batched call. When AA succeeds it's part of the UserOp; when it falls back to EOA it lands as a second tx (`count: 2`). Worth confirming this is intended even on AA-failure paths.

### Pending wallet requests left behind (cleanup needed)

- `tx-5` chain 42161 (Arbitrum) — pending
- `tx-6` chain 10 (Optimism) — pending
- `tx-7` chain 8453 (Base) — pending

These cannot be signed without funding the EOA on each chain or fixing the AA paths. They'll show in `aomi tx list` until manually cleared.
