# Error Codes

This file maps common Aomi or EVM workflow failures to likely causes and fixes.

## AOMI_NO_PENDING_TX

- **Meaning:** There is no queued wallet request to sign.
- **Cause:** The build step has not produced a request, or the session is read-only.
- **Fix:** Re-run the prompt, check the session, and confirm the action path.

## AOMI_SESSION_EXPIRED

- **Meaning:** The current session is stale or no longer usable.
- **Cause:** Old session state, reused local pointer, or expired backend context.
- **Fix:** Start a fresh session and restate the request.

## AOMI_CHAIN_MISMATCH

- **Meaning:** The chain in the request does not match the selected chain.
- **Cause:** Wrong chain ID, stale default, or incorrect RPC pairing.
- **Fix:** Restate the chain explicitly and use the matching RPC.

## AOMI_BALANCE_TOO_LOW

- **Meaning:** The wallet does not have enough balance for the value or gas.
- **Cause:** Insufficient ETH, token balance, or wrong funding wallet.
- **Fix:** Top up the wallet or lower the amount.

## AOMI_APPROVAL_REQUIRED

- **Meaning:** A token approval is required before the write action can execute.
- **Cause:** No allowance or the allowance was revoked.
- **Fix:** Queue and sign the approval first.

## AOMI_QUOTE_EXPIRED

- **Meaning:** The route or quote is too old to trust.
- **Cause:** Delay between quote and sign.
- **Fix:** Request a fresh quote and re-run the flow.

## AOMI_SLIPPAGE_EXCEEDED

- **Meaning:** The price moved beyond the allowed range.
- **Cause:** Tight slippage or market movement.
- **Fix:** Reduce size or relax slippage carefully.

## AOMI_SIGNATURE_REJECTED

- **Meaning:** The signer rejected the payload.
- **Cause:** Wrong signer, malformed data, or user rejection.
- **Fix:** Verify the wallet and reissue the request.

## AOMI_RPC_UNAVAILABLE

- **Meaning:** The RPC endpoint cannot respond.
- **Cause:** Bad URL, timeout, or provider outage.
- **Fix:** Switch RPCs or retry later.

## AOMI_REVERTED

- **Meaning:** The transaction reverted on-chain or in simulation.
- **Cause:** Wrong calldata, stale state, missing approval, or invalid route.
- **Fix:** Read the revert reason and rebuild the request.

## AOMI_INVALID_RECIPIENT

- **Meaning:** The recipient address or name is invalid.
- **Cause:** Malformed address or unresolvable ENS name.
- **Fix:** Resolve the destination and confirm the final address.

## AOMI_UNSUPPORTED_TOKEN

- **Meaning:** The token is not supported by the current route or example.
- **Cause:** Wrong symbol, unsupported chain, or missing liquidity.
- **Fix:** Use a supported token or a different route.

## AOMI_BUILD_TARGET_UNKNOWN

- **Meaning:** The builder workflow does not know what to scaffold.
- **Cause:** Missing repo, docs, API surface, or product target.
- **Fix:** Provide the actual source of truth and the desired output.

## AOMI_HOST_HANDOFF_REQUIRED

- **Meaning:** The host or wallet must complete the next step.
- **Cause:** The skill built a wallet request or signature step.
- **Fix:** Continue with the host callback or sign in the correct wallet flow.

## AOMI_SAFE_MODE

- **Meaning:** The flow is blocked by safety rules until the user confirms.
- **Cause:** A high-risk action, large value, or unclear destination.
- **Fix:** Reconfirm the action with explicit details.

## Handling Pattern

For every error:

1. name the problem
2. explain the cause
3. show the fix
4. say whether the request can be retried as-is
5. if needed, suggest the next prompt
