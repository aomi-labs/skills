# Drain Vectors

Read this when:

- A simulation fails with an annotation like `recipient != msg.sender` or similar, and you need to know whether that's a guard-block or a real bug.
- You're constructing a new flow and need to know which calldata field the agent treats as the "drain" for a given protocol.
- The user types a prompt with a non-self recipient (*"swap and send to 0xFriend"*) and you need to predict whether the agent will let it through.

## What this is

A **drain vector** is the calldata field where a malicious prompt could redirect funds away from the user — `recipient` in Uniswap, `onBehalfOf` in Aave, `mintRecipient` in CCTP, `_to` in OP-stack bridges. The agent blocks these at simulation time when they don't equal `msg.sender`.

When you see a `Batch success: false` with a drain-vector annotation, it is **not** a transaction-construction bug. It is the agent's guard rejecting calldata that would route the user's funds to a non-self address. The skill's job is to surface the block to the user — not to reformulate the prompt to bypass it.

For example flows that hit these guards (Uniswap recipient, Aave onBehalfOf, CCTP mintRecipient, OP-stack `_to`), see the relevant section in [examples.md](examples.md).

## Reference table

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
| OP-stack `bridgeETHTo` / `depositETHTo` (Base/Optimism) | `_to` | Plus `_to == address(0)` is a hard block (not just a warning) — bridging to zero permanently locks funds on L2 |
| zkSync Mailbox `requestL2Transaction` | `_contractL2` AND `_refundRecipient` | Both |
| LST tokens (stETH, wstETH, rETH, eETH, etc.) `transfer` / `transferFrom` | `_to` | Special-case block on the issued token, not on the staking call. The agent guards against attacker prompts like *"transfer my stETH to 0xdEaD"* even though stETH itself is a known Lido contract |

## How the guard fires

The agent runs `simulate_batch` against a forked chain before staging calldata to the wallet. When a drain vector is detected, the simulation result includes an annotation like:

```
Batch [1] failed: drain-vector at recipient != msg.sender
  step 1: exactInputSingle((USDC, WETH, 500, 0xdEaD..., 1_000_000, 0, 0))
  user:   0xUserAddress
  field:  recipient (word3)
```

The wallet never sees this calldata — it's rejected at the simulation gate. The skill should **surface the block** to the user. Two scenarios:

1. **The user typo'd or forgot their own address** → confirm with them ("did you mean to send to your own wallet?") and re-prompt with the corrected recipient.
2. **The user actually wanted to send to a different address** (a friend, a multisig, a contract) → the agent's default policy is conservative; the user can override only by re-prompting with explicit acknowledgment, and the skill should surface that the calldata is intentionally non-self before signing.

Do **not** attempt to bypass the guard by reformulating the prompt without the user's explicit redirect. Do not paste the exact same intent through a different app to evade the check.

## Hard blocks vs. soft warnings

Most drain-vector annotations are **soft warnings** — they fail simulation and ask for explicit confirmation. A few are **hard blocks** that cannot be acknowledged through:

- **`_to == address(0)`** on OP-stack bridges. Bridging to zero permanently locks funds on L2 with no recovery path. The agent fails simulation with a clear "L2 funds will be permanently unrecoverable" message. If the user typo'd, do **not** retry — surface the block and re-prompt for the correct address.
- **Token-level `transfer` to a known sink address** (`0x0`, `0xdEaD`, etc.) on a freshly issued LST. Special-case to prevent the staking-then-transfer attacker chain.

For the full per-protocol example flows that hit these guards, see [examples.md](examples.md).
