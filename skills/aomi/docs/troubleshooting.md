# Troubleshooting

This document covers the most common failure modes when using Aomi.

## Before you start

Confirm these basics first:

- the correct chain is selected
- the wallet has enough balance for gas and value
- the token or contract address is correct
- the request is the intended one
- approvals are present when needed
- the route has not expired
- the signer is using the expected account

If one of those is wrong, fix it before debugging anything deeper.

## 1. The request is queued, but nothing is happening

### Symptom

You asked Aomi to do something, but there is no visible execution yet.

### Likely causes

- the agent is waiting for confirmation
- the request needs a second step
- the transaction was queued but not signed
- the session is read-only

### Fix

- run the status or tx view for the current session
- confirm whether a wallet request exists
- if the flow has multiple steps, simulate before signing
- reply with the minimal confirmation needed

## 2. Wrong chain

### Symptom

Aomi shows a route or transaction for a different chain than the one you wanted.

### Likely causes

- the prompt did not name the chain
- the default chain from the session is still active
- the RPC URL does not match the transaction chain

### Fix

- restate the chain explicitly
- use the exact chain name or chain ID
- confirm the RPC matches the chain before signing
- do not reuse stale chain context

## 3. Insufficient balance

### Symptom

The request fails because the wallet does not have enough ETH, gas, or token balance.

### Likely causes

- the wallet lacks gas token
- the amount is too large
- the token balance is split across multiple wallets
- the route includes hidden approval costs

### Fix

- check wallet balance first
- reduce the amount
- top up gas separately if needed
- verify the source wallet is the one you intended

## 4. Approval missing

### Symptom

A swap or contract interaction fails because the token is not approved.

### Likely causes

- the approval step was skipped
- the allowance was reset or revoked
- the target spender is different from the one approved

### Fix

- queue and sign the approval first
- simulate the batch if the approval and action depend on each other
- confirm the spender address before signing

## 5. Quote expired

### Symptom

The swap or route no longer matches the quoted outcome.

### Likely causes

- too much time passed between quote and sign
- market conditions moved
- the route has a deadline that already expired

### Fix

- request a fresh quote
- re-run the transaction build flow
- lower the delay between review and signing
- use a tighter workflow with fewer pauses

## 6. Slippage exceeded

### Symptom

The route reverts because the price moved beyond tolerance.

### Likely causes

- slippage is too tight
- the market moved quickly
- liquidity is thin
- the trade size is too large for the pool depth

### Fix

- increase slippage tolerance carefully
- reduce size
- use a deeper venue or route
- re-quote immediately before signing

## 7. Signature rejected

### Symptom

The wallet refuses to sign the payload.

### Likely causes

- the signer address does not match the expected wallet
- the signing mode is wrong
- the payload is malformed
- the user rejected the request

### Fix

- verify the signer address
- confirm whether AA or EOA should be used
- check that the transaction or typed data is complete
- ask the user to confirm intent again

## 8. RPC unavailable

### Symptom

Aomi cannot read state or submit the transaction because the RPC endpoint fails.

### Likely causes

- bad RPC URL
- rate limit or timeout
- chain mismatch
- upstream provider outage

### Fix

- switch to a healthy RPC
- retry with a shorter request
- confirm the chain and URL pair
- keep a backup RPC available

## 9. Reverted transaction

### Symptom

The simulation or broadcast fails with a revert.

### Likely causes

- stale calldata
- wrong recipient
- missing approval
- insufficient balance
- contract state changed since the quote

### Fix

- inspect the revert reason
- resimulate the batch
- refresh the quote or route
- check the contract state before retrying

## 10. Invalid recipient

### Symptom

A send or transfer flow rejects the destination.

### Likely causes

- malformed address
- unsupported ENS resolution
- wrong checksum in a strict context
- empty destination field

### Fix

- verify the address format
- resolve ENS first if needed
- copy the destination again from source of truth
- do not guess the recipient

## 11. Session confusion

### Symptom

Aomi seems to be acting on the wrong session or old context.

### Likely causes

- an older session is still active
- local state was reused accidentally
- the model carried over a stale chain or app selection

### Fix

- start a new session when the task is unrelated
- confirm the current app and chain
- clear old local state if needed
- keep prompt context narrow

## 12. Build flow cannot find the source of truth

### Symptom

The builder workflow does not know what to scaffold.

### Likely causes

- no API docs were supplied
- the docs only describe the product, not the runtime
- the repo links are missing or stale
- the target service is not actually runnable

### Fix

- provide the concrete API, SDK, or repo
- identify the actual executable surface
- do not ask the builder skill to invent endpoints
- fall back to a docs-only assistant only when there is no runtime target

## 13. Output is too vague

### Symptom

The response explains the idea but does not give a usable next step.

### Likely causes

- the prompt was underspecified
- the skill is overfitting to docs instead of action
- the request did not identify the final operation

### Fix

- ask for a concrete verb
- use prompts like send, swap, sign, build, scaffold, review
- name the chain, asset, amount, and destination
- ask for the smallest missing detail

## 14. How to debug a bad flow quickly

Use this order:

1. check chain
2. check balance
3. check approval
4. check route freshness
5. simulate
6. sign
7. verify the result

If a step fails, stop and fix that step before moving on.

## 15. Good debug prompts

- "Show me the pending request and the missing step"
- "Why did the swap revert"
- "Which approval is missing"
- "What chain is this queued on"
- "Does this need a fresh quote"
- "What would I need to change to make this executable"

## 16. When to ask for help

Ask for help only after you have:

- checked the chain
- checked the balance
- checked the spender or recipient
- checked the quote age
- checked the simulation output

At that point, the issue is usually a real upstream or integration problem, not user error.
