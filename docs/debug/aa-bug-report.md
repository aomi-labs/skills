# AA on Base does not sponsor — falls through to EOA, fails when wallet has no L2 gas

## Summary

`aomi tx sign` against a Base-bound transaction fails with viem's `insufficient funds for transfer` even when AA is requested explicitly (`--aa --aa-mode 4337`). The CLI advertises Base as a 4337-default sponsored chain, but in practice the EOA at `0x5D907BEa404e6F821d467314a9cA07663CF64c9B` was used to send the approve directly — not a UserOperation through a paymaster. The same wallet on Ethereum mainnet (default mode 7702, paid by the EOA's small ETH stash) signed three batched transactions cleanly in the same session.

## Environment

- `@aomi-labs/client` **v0.1.30** (global install)
- Backend: `https://staging-api.aomi.dev`
- Node `v20+`, viem `2.48.4` (per error stack)
- Macos 14.x, zsh
- Wallet: `0x5D907BEa404e6F821d467314a9cA07663CF64c9B`
- Provider key registered: `--provider-key anthropic:...` (BYOK Anthropic)
- AA configuration on the user side: **none** (no `ALCHEMY_API_KEY`, no `PIMLICO_API_KEY` in env, no sponsorship policy configured) — relying on the zero-config Alchemy proxy path documented in `execution.ts:137-139`

## Steps to reproduce

```bash
# 1. Set up — wallet pre-configured via `aomi wallet set`, env has BANANA_PRIVATE_KEY only
aomi wallet current
# 0x5D907BEa404e6F821d467314a9cA07663CF64c9B (address only)

# 2. Bridge 1 USDC mainnet → Base (this succeeded via AA 7702 on mainnet)
aomi --prompt "Bridge exactly 1 USDC from Ethereum mainnet to Base for wallet 0x5D907BEa404e6F821d467314a9cA07663CF64c9B via Across. Include approve as a separate tx." --chain 1
PRIVATE_KEY="$BANANA_PRIVATE_KEY" aomi tx sign tx-4 tx-7
# ✅ Sent! Hash: 0x6d2c9b20f8d456a6425cb71e465eaa20177685a8db8de9602fdf3431c450b2cd
# Exec:    aa (alchemy, 7702)
# Fee:     0.000011 ETH

# 3. After Across settles ~30s later, bridge it BACK from Base → mainnet
aomi --prompt "Now bridge exactly 1 USDC from Base back to Ethereum mainnet for the same wallet. Use Across. Include approve as a separate tx." --chain 8453
# Agent queues tx-8 (approve to 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913 USDC contract on Base)
# Agent queues tx-9 (Across spoke pool deposit)
# Simulation passes: Batch [8,9] passed, total gas 128,649

# 4. Sign on Base RPC, default AA path (no flags = auto-detect AA)
PRIVATE_KEY="$BANANA_PRIVATE_KEY" aomi tx sign tx-8 tx-9 \
  --rpc-url https://mainnet.base.org --chain 8453
# ❌ Error: insufficient funds for transfer

# 5. Force AA explicitly with 4337 mode (the documented Base default)
PRIVATE_KEY="$BANANA_PRIVATE_KEY" aomi tx sign tx-8 tx-9 \
  --aa --aa-mode 4337 \
  --rpc-url https://mainnet.base.org --chain 8453
# ❌ Same error: insufficient funds for transfer
#    Use `--eoa` to sign without account abstraction.
```

The wallet has **0 ETH on Base** and ~661 USDC on Base after the inbound bridge. We expected 4337 mode to sponsor the call via Alchemy's paymaster proxy.

## Expected

`aomi tx sign tx-8 tx-9 --aa --aa-mode 4337 --rpc-url https://mainnet.base.org --chain 8453` should:

1. Build a UserOperation containing both the approve and the Across deposit calls.
2. Submit it through the bundler with the paymaster sponsoring gas (per the `proxy: true` path in `execution.ts:137-139`).
3. Return `Exec: aa (alchemy, 4337, proxy)` and a UserOp / tx hash, exactly like the mainnet 7702 case did.

The wallet having 0 native ETH on the destination chain is precisely the scenario sponsorship is supposed to solve.

## Actual

```
Request Arguments:
  from:   0x5D907BEa404e6F821d467314a9cA07663CF64c9B
  to:     0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913   # USDC on Base
  value:  0 ETH
  data:   0x095ea7b300000000000000000000000009aea4b2242abc8bb4bb78d537a67a245a7bec6400000000000000000000000000000000000000000000000000000000000f4240

Details: insufficient funds for transfer
Version: viem@2.48.4
Use `--eoa` to sign without account abstraction.

CliExit [Error]
    at fatal (file:///opt/homebrew/lib/node_modules/@aomi-labs/client/dist/cli.js:45:9)
    at signCommand (file:///opt/homebrew/lib/node_modules/@aomi-labs/client/dist/cli.js:4831:13)
    ...
```

The "Request Arguments" block is the giveaway: the CLI is sending a **direct EOA transaction** (`from` = the EOA's address, calldata = the approve), not wrapping it as a UserOperation. The AA flow appears to skip the paymaster entirely and emit a plain `eth_sendRawTransaction`-shaped call from the signer.

## What works (control case, same session)

| # | Chain | Mode | Result |
|---|---|---|---|
| 1 | Ethereum (1) | AA 7702 (default) | ✅ Approve+swap batch, hash `0xa361...0f74fc`, fee 0.000017 ETH |
| 2 | Ethereum (1) | AA 7702 (default) | ✅ Reverse swap, hash `0x819d...c97e1`, fee 0.000012 ETH |
| 3 | Ethereum (1) | AA 7702 (default) | ✅ Approve+bridge to Base, hash `0x6d2c...b2cd`, fee 0.000011 ETH |
| 4 | Base (8453) | AA 4337 (default + explicit) | ❌ `insufficient funds for transfer` |

The exact same wallet, exact same session (session-43), exact same `BANANA_PRIVATE_KEY`. Only difference: chain.

On Ethereum the EOA has ~0.057 ETH which the 7702 delegation uses to pay; on Base the EOA has 0 ETH so 7702 can't apply (no gas for the authorization tx) and 4337 was supposed to take over.

## Hypothesis

Looking at `packages/client/src/cli/execution.ts:110-140`:

```ts
// Default: Alchemy proxy (zero-config)
const aaMode = resolveMode(chain, callList, config.aaMode);
return { execution: "aa", provider: "alchemy", aaMode, proxy: true };
```

And `createCliProviderState` (`execution.ts:157-186`):

```ts
const proxyBaseUrl = decision.proxy && chainSlug
  ? `${baseUrl}/aa/v1/${chainSlug}`
  : undefined;

return createAAProviderState({
  provider: decision.provider,
  chain,
  owner: { kind: "direct", privateKey },
  rpcUrl,
  callList,
  mode: decision.aaMode,
  apiKey: decision.apiKey,
  proxyBaseUrl,
});
```

The proxy URL gets built (`https://staging-api.aomi.dev/aa/v1/base`) and handed to `createAAProviderState` from the `aa` module. One of the following is happening downstream:

1. **The proxy endpoint exists but has no paymaster policy attached for Base.** The bundler builds a UserOp, simulation succeeds, but signing/submission expects the EOA to cover gas because no paymaster signs the UserOp.
2. **The 4337 path falls back to a direct `eth_sendTransaction` when the paymaster step fails silently.** The fact that viem's stack appears (`viem@2.48.4`) and the error mentions "transfer" with `from = EOA` strongly suggests the call left the AA module entirely.
3. **The AA module never engaged on Base** — possibly `getAAChainConfig` returns no config for Base under proxy mode, or the chain slug lookup `ALCHEMY_CHAIN_SLUGS[chain.id]` returns the wrong value, causing the paymaster URL to 404 and the code path to fall through to EOA without warning.

Worth checking specifically:

- `ALCHEMY_CHAIN_SLUGS[8453]` — does it return `"base"` (matches Alchemy's URL convention) or something else?
- The aomi backend `/aa/v1/base` endpoint — does it exist? Does it have a paymaster policy?
- The `createAAProviderState` function in the `aa` module — when sponsorship fails, does it fall back to `walletClient.sendTransaction` instead of returning an error? That would explain why we see a viem error instead of an AA error.

## Workarounds (current user-side)

1. Send a tiny amount of ETH (~0.0005 ETH) to the wallet on Base, then retry — `--eoa` and AA 4337 will both work because the EOA can pay.
2. Configure a real BYOK Alchemy account with a sponsorship policy that covers Base, set `ALCHEMY_API_KEY` and `ALCHEMY_GAS_POLICY_ID` (if the latter is real — it's referenced in older skill docs but not in the current code, see separate note).
3. Configure Pimlico (`PIMLICO_API_KEY`) and pass `--aa-provider pimlico --aa-mode 4337` — Pimlico's dashboard policies are easier to set up than Alchemy's gas-manager.

## Severity

Medium-high for the user experience, low for blast radius.

- The CLI's headline value prop is "AA-first signing — sign without thinking about gas." On L2s where users most need this, the proxy path silently doesn't deliver. New users with $1-of-USDC test bridges (exactly the canonical onboarding flow) will hit this immediately.
- The error message is misleading. `insufficient funds for transfer` from viem reads like a wallet problem, not a config problem. The user thinks "I need more ETH" rather than "the AA proxy isn't sponsoring." The line `Use --eoa to sign without account abstraction` is also misleading because `--eoa` on a wallet with 0 ETH on the destination chain will fail the same way.
- Mainnet AA works perfectly, so any local testing on Anvil/Sepolia + chain 1 won't surface this.

## Suggested fixes

1. **Make the failure mode unambiguous.** When `decision.proxy === true` and the paymaster doesn't sign, the CLI should emit a clear error: `AA sponsorship unavailable: zero-config proxy on chain <id> did not return a paymaster signature. Configure ALCHEMY_API_KEY (BYOK) or PIMLICO_API_KEY, or fund the EOA with native gas on this chain.` Not viem's generic message.
2. **Confirm the proxy actually sponsors L2s** end-to-end via a CI smoke test (sign a no-op call on Base from a freshly-generated zero-balance wallet). Right now there's nothing forcing this to keep working.
3. **Document the limitation** in the AA reference until sponsorship is reliable: "On L2s, the zero-config proxy may not sponsor — verify with a small test or use BYOK." (I'll PR this in the skill at the same time.)
4. **Verify `ALCHEMY_CHAIN_SLUGS`** for all chains in `chains.ts`, especially Base / Optimism / Arbitrum, to rule out a stale mapping.

## Related observations from the same run

- `--new-session` + `--provider-key` on the same call doesn't apply BYOK to that prompt → credit-limit error on the very first prompt of a fresh session.
- `[session] Backend user_state mismatch (non-fatal)` log spam appears between the user prompt and the agent response — clutters output, may confuse users.
- Across deadline retries: agent queued tx-5 and tx-6 with deadlines that expired by simulation time, then auto-retried as tx-7 which passed. Failed pending txs (tx-5, tx-6) stayed visible in `aomi tx list` afterward — would be nice to auto-clear or mark with a `[expired]` tag.
- `aomi --provider-key anthropic:$KEY` echoes back `BYOK key set for anthropic: sk-ant-...` — leaks the first ~7 characters of the API key. Probably fine (not authentication-grade), but worth a confirm.

## Receipts

For verification, the three successful AA-7702 mainnet hashes:

- `0xa36136c8f4b74abaae621c34b44667dcebf9a8ab87950c85410c6eafbf0f74fc` (approve+swap batch)
- `0x819db3878f416609740b8bed9be4511f204da26af305236464c5168bc4fc97e1` (reverse swap)
- `0x6d2c9b20f8d456a6425cb71e465eaa20177685a8db8de9602fdf3431c450b2cd` (approve+bridge to Base)

7702 delegation contract used: `0x69007702764179f14F51cdce752f4f775d74E139`
Service fee receiver: `0x9C7a99480c59955a635123EDa064456393e519f5`

The Base-bound bridge (#3) DID land on Base — wallet now holds the bridged 1 USDC plus ~14 USDC pre-existing. Stuck because no native gas on Base to bridge it back.
