# Error Codes

CLI errors and on-chain revert reasons the aomi flow surfaces, with concrete fixes. Grouped by which command produces them.

For full diagnostic walkthroughs and the recovery patterns, see [docs/troubleshooting.md](../docs/troubleshooting.md).

## `aomi chat` errors

| Error | Cause | Fix |
|-------|-------|-----|
| `(no response)` | Backend timeout or stale local session pointer | Wait briefly, run `aomi session status`. If session is gone, retry with `--new-session` |
| `[session] Backend user_state mismatch (non-fatal)` log spam | Known v0.1.30 cosmetic noise (state-sync diagnostic) | Ignore. Look past the JSON for the actual response and `⚡ Wallet request queued` line |
| Credit limit error after `--new-session --provider-key` | v0.1.30 quirk: BYOK key registers but prompt still routes through Aomi credits | Workaround: register on a no-op call first (`aomi --provider-key x:y --new-session --prompt "ack"`), then issue the real prompt without `--new-session` |
| `BYOK key set for anthropic: sk-ant-...` echo | By design — provider identification, not authentication. First ~7 chars of the key are echoed | Not a credential leak. Do not try to scrub |

## `aomi tx list` errors

| Error | Cause | Fix |
|-------|-------|-----|
| `No active session` | Active-session pointer (`~/.aomi/active-session.txt`) lost between subprocess invocations | `aomi session list` to find session, then `aomi session resume <N> > /dev/null && aomi tx list` in same shell call |
| Pending entries with `failed at step N: 0x...` status | Stale orphans from earlier failed simulation attempts | Match against `batch_status`. Sign only `Batch [...] passed` txs. Skip orphans |

## `aomi tx simulate` errors

| Revert reason | Cause | Fix |
|---------------|-------|-----|
| `expired quote` / `expired deadline` | Deadline-bearing route (Across, Khalani filler) had its quote expire | Agent self-heals — re-check `aomi tx list` for the new passing batch. Don't re-prompt |
| `transfer amount exceeds allowance` | Agent staged single-tx that needed approval | Wait for retry; sign new pair (`tx-2 tx-3`); ignore orphan `tx-1` |
| Insufficient balance | User doesn't have the input asset | Surface to user; let them adjust amount |
| `STF` (Uniswap "Slippage tolerance failure") | Price moved beyond tolerance | Reduce size or accept higher slippage; re-prompt |
| Drain-vector annotation: `recipient != msg.sender` | User's prompt would have routed funds to a different address (Uniswap `recipient`, Aave `onBehalfOf`, CCTP `mintRecipient`, OP-stack `_to`) | Surface the block. Do not attempt to bypass |
| `_to = address(0)` (OP-stack bridge) | Hard block — bridging to `0x0` permanently locks funds on L2 | Do not retry. Surface the block; user likely typo'd |
| `Stateful: false` in result | Backend could not fork chain; ran each tx via `eth_call` | Retry simulation. State-dependent flows may show false negatives. Check backend Anvil status |

## `aomi tx sign` errors

| Error | Cause | Fix |
|-------|-------|-----|
| AA mode error suggesting `--eoa` | Both AA modes (preferred + alternative) failed | Read console output. Address root cause: provider creds, chain support, sponsorship policy. Use `--eoa` only if user accepts EOA signing |
| `insufficient funds for transfer` (viem) on L2 | Zero-config AA proxy did not sponsor; fell through to direct EOA `eth_sendTransaction` with 0 native gas | Either fund EOA with native gas on destination chain (~0.0005 ETH equivalent), OR configure BYOK Alchemy/Pimlico provider with sponsorship policy and pass `--aa-provider --aa-mode 4337`. **Do not retry with `--eoa`** — that path also needs gas |
| `Signer 0x... does not match stored session public key 0x... — updating session` | User's local wallet differs from session's stored public key | Expected behavior. CLI updates session and continues. Confirm with user that the new address is intended |
| HTTP 401 from RPC | RPC auth failed | Pass `--rpc-url <reliable-public-rpc>` for the queued tx's chain |
| HTTP 429 from RPC | RPC rate-limited | Pass `--rpc-url <different-public-rpc>`. **Do not rotate through random endpoints** — ask user for a reliable URL |
| Generic parameter error during sign | Usually an RPC problem, not transaction-construction | Pass a chain-matching public RPC via `--rpc-url` |
| `--rpc-url` mismatch with queued tx chain | Cross-chain flow — session is on chain X but queued tx is on chain Y | Pass `--rpc-url` matching the **queued tx's** chain (visible in `aomi tx list`), not the session chain |
| Mixed-chain multi-sign request fails | A single `--rpc-url` cannot serve txs on different chains | Sign per-chain in separate calls |

## AA-specific errors

| Error | Cause | Fix |
|-------|-------|-----|
| `--aa-provider` and `--eoa` together | Mutually exclusive — `--aa-provider` forces AA, `--eoa` skips AA | Pass only one. Use `--aa-provider` to force a specific AA path; use `--eoa` to skip AA entirely |
| `--aa-mode` and `--eoa` together | Same — `--aa-mode` forces AA | Pass only one |
| AA on Sepolia/Anvil | These chains have no AA defaults | Pass `--eoa` explicitly when signing on Sepolia or local Anvil |
| Provider credentials missing | User has selected a BYOK provider but credentials are not configured in their environment | Stop and ask the user to configure on their side. Do not configure from the skill |

## Credential / Setup errors

| Error | Cause | Fix |
|-------|-------|-----|
| Apps require credentials user hasn't configured | App-specific (e.g. `binance`, `polymarket`, `dune` require provider tokens) | Surface to user; ask them to configure. Run `aomi secret add` only if they explicitly asked and supplied the value (see SKILL.md "Security") |
| Skill attempted credential setup user didn't ask for | Hard rule violation | Stop. Never run `aomi wallet set`, `aomi secret add`, `--api-key`, or `--private-key` on the skill's initiative |

## Drain Vector Reference

Calldata fields where a malicious prompt could redirect funds. The agent blocks `<field> != msg.sender` at simulation time. The skill's job is to **surface the block, not bypass**.

| Protocol | Drain Vector | Notes |
|----------|--------------|-------|
| Uniswap V3 `exactInputSingle` / `exactOutputSingle` | `recipient` (word3) | Block at simulation if != msg.sender |
| Uniswap V2 `swapExactTokensForTokens` | `to` parameter | Same |
| 1inch v6 `swap` | `dstReceiver` inside `SwapDescription` tuple | Same |
| Sushi V2 `swapExactTokensForTokens` | `to` (recipient) | Same |
| Curve `exchange` | n/a — refunds msg.sender directly | No drain vector by design |
| Aave V3 `supply` | `onBehalfOf` | Same |
| Aave V3 `borrow` / `withdraw` | `to` | Same |
| Aave V3 `repay` | `onBehalfOf` | Same |
| Compound V3 `supplyTo` | `dst` | Same |
| Morpho `supply` | `onBehalfOf` (inside MarketParams call) | Same |
| CCTP `depositForBurn` | `mintRecipient` (bytes32, left-padded) | Same |
| Across `depositV3` | `recipient` (word1) | Same |
| Stargate `send` | `recipient` inside `SendParam` AND separate `refundAddress` | **Both** are drain vectors |
| Arbitrum native bridge `outboundTransferCustomRefund` | `_to` AND `_refundTo` | Both |
| OP-stack `bridgeETHTo` / `depositETHTo` (Base/Optimism) | `_to` | Plus `_to == address(0)` is a hard block |
| zkSync Mailbox `requestL2Transaction` | `_contractL2` AND `_refundRecipient` | Both |
| LST tokens (stETH, wstETH, rETH, eETH, etc.) `transfer` / `transferFrom` | `_to` | Special-case block on the issued token, not on the staking call |
