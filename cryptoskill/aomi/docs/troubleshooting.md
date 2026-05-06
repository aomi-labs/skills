# Troubleshooting

Read this when a command fails unexpectedly or behaves differently than the canonical workflow predicts. Each section lists symptoms, the most likely cause, and a concrete fix.

## Chat / Session

### `(no response)` from `aomi chat`

**Symptoms:**
- The chat command returns with no agent prose.
- No `⚡ Wallet request queued` line.

**Cause:**
- Backend timeout, or the local active-session pointer is stale.

**Fix:**

```bash
# 1. Check session status
aomi session status

# 2. If session is gone or unreachable, retry with --new-session
aomi chat "<original message>" --new-session
```

### `[session] Backend user_state mismatch (non-fatal)` log spam

**Symptoms:**
- Large JSON dumps in stdout between the prompt and the agent response.
- Looks alarming but the chat actually completes.

**Cause:**
- Known v0.1.30 cosmetic noise — the backend sends a state-sync diagnostic that gets logged verbatim.

**Fix:**

Ignore. Look past the JSON for the actual response and `⚡ Wallet request queued` line. Do not try to suppress the output — the message is informational.

## Pending TX

### `Error: No active session` from `aomi tx list`

**Symptoms:**
- `aomi tx list` errors out even after a successful chat.

**Cause:**
- The active-session pointer (`~/.aomi/active-session.txt`) was lost between subprocess invocations. Known v0.1.30 quirk.

**Fix:**

```bash
# 1. Find the right session
aomi session list

# 2. Resume + read in the SAME shell call (pointer survives)
aomi session resume 43 > /dev/null && aomi tx list
```

### Stale failed-simulation txs in `aomi tx list`

**Symptoms:**
- Three or more pending `tx-N` entries when you only expect two.
- Some entries tagged `failed at step N: 0x...`, others `Batch [...] passed`.

**Cause:**
- The agent's first attempt failed simulation (e.g. tried single-tx supply, got allowance error). It rebuilt as approve+supply automatically, but the failed entry stays visible.

**Fix:**

Match against the `batch_status` metadata. **Sign only txs marked `Batch [...] passed`. Skip `failed at step N` entries.**

```bash
aomi tx list
# Identify the passing batch by status, e.g. tx-2 tx-3
aomi tx sign tx-2 tx-3
```

## Signing

### AA mode failure with `--eoa` suggestion

**Symptoms:**
- Output says something like *"AA signing failed (4337 then 7702). Try `--eoa` to skip AA."*

**Cause:**
- Both AA modes failed. Underlying causes: missing/invalid provider credential, unsupported chain, or sponsorship policy denying the call.

**Fix:**

Read the console output for the specific error:
- **Credential error** → ask the user to check their provider configuration. Do not configure it from the skill.
- **Chain not supported** → e.g. Sepolia, Anvil; pass `--eoa` if user accepts EOA signing.
- **Sponsorship denied** → user's policy rejected the UserOp. Either fund the EOA for self-paid execution, or update the policy on the provider's dashboard.

### `insufficient funds for transfer` (viem) on L2 sign

**Symptoms:**
- `aomi tx sign tx-1` on Base/Optimism/Arbitrum returns viem's `insufficient funds for transfer`.
- Followed by `Use --eoa to sign without account abstraction`.

**Cause:**
- The zero-config Alchemy proxy did **not** sponsor the call (verified behavior on Base in v0.1.30). The CLI fell through to a direct EOA `eth_sendTransaction`, which fails because the EOA has 0 native gas on the destination chain.

**Fix:**

Do **not** retry with `--eoa` blindly — `--eoa` also requires gas. Two options:

1. **Fund the EOA with a tiny amount of native gas** on the destination chain (~0.0005 ETH equivalent).
2. **Configure a real BYOK AA provider** with a sponsorship policy:
   - Alchemy with a Gas Manager policy attached, OR
   - Pimlico with a sponsorship policy on the dashboard.
   - Then pass `--aa-provider alchemy --aa-mode 4337` (or `pimlico`) on `aomi tx sign`.
   - The exact credential variable names are documented by `aomi --help`.

The skill does not configure these credentials itself.

### Signer address differs from session public key

**Symptoms:**
- Console message like *"Signer 0xabc... does not match stored session public key 0xdef... — updating session."*

**Cause:**
- The user's local wallet is set to a different address than the session was created with.

**Fix:**

Expected behavior. The CLI updates the session to the signer address and continues. Not an error — confirm with the user that the new address is the one they want to sign from.

## RPC

### `401`, `429`, or generic parameter errors during `aomi tx sign`

**Symptoms:**
- HTTP 401 (auth failed) or 429 (rate limited) from the signing RPC.
- Or a parameter error that makes no sense given the calldata.

**Cause:**
- RPC problem, not a transaction-construction problem.

**Fix:**

Pass a reliable chain-matching public RPC via `--rpc-url`:

```bash
aomi tx sign tx-1 --rpc-url https://ethereum-rpc.publicnode.com
```

If one or two public RPCs fail, **stop rotating through random endpoints**. Ask the user to supply a proper RPC URL for that chain. Do not paste provider-keyed URLs into chat.

### Cross-chain RPC mismatch

**Symptoms:**
- The chat session is on chain X, but the queued tx targets chain Y.
- `aomi tx sign` errors or signs with wrong gas estimates.

**Cause:**
- `--chain` (session context) and `--rpc-url` (signing transport) are independent. The default RPC matches the session, not the queued tx.

**Fix:**

The pending transaction already contains its target chain. Override with `--rpc-url` matching the **queued tx's** chain:

```bash
aomi tx list
# tx-1 is on chain 8453 (Base), session was on chain 1 (Ethereum)
aomi tx sign tx-1 --rpc-url https://base.publicnode.com
```

## Simulation

### `Batch success: false` with revert reason

**Symptoms:**
- Simulation reports a step failed.
- Specific revert message in the step output.

**Cause:**
Common revert reasons:
- `expired quote` / `expired deadline` — deadline-bearing route (Across, Khalani filler) had its quote expire while the user was thinking.
- `transfer amount exceeds allowance` — the agent staged a single-tx that needed approval first. Will retry as approve+action automatically.
- Insufficient balance — user doesn't have the input asset.
- `STF` (Uniswap) — slippage tolerance failure; price moved beyond tolerance.
- Drain-vector annotation (`recipient != msg.sender`, `onBehalfOf != msg.sender`, etc.) — the user's prompt would have routed funds away from their own address.

**Fix:**

Read the revert reason. **Do not blindly re-sign after a simulation failure.**

- **Expired deadline** → for Across/Khalani, the agent self-heals by rebuilding the request with fresh deadlines. Don't re-prompt — re-check `aomi tx list` for the new passing batch.
- **Allowance error** → wait for the agent's retry; sign the new pair (`tx-2 tx-3`), ignore the orphan `tx-1`.
- **Drain-vector block** → surface to the user. Do not attempt to bypass.
- **Insufficient balance / slippage** → tell the user, let them adjust the size or accept higher slippage.

### `stateful: false` in simulation result

**Symptoms:**
- Simulation completes but reports `Stateful: false`.
- Multi-step batch may show false negatives (step 2 reverts as if step 1 didn't run).

**Cause:**
- The backend could not fork the chain. Fell back to running each tx independently via `eth_call`.

**Fix:**

Retry the simulation. If it persistently reports `stateful: false`, check the backend Anvil instance status (the user's responsibility, not the skill's). For state-dependent flows, do not sign while simulation is running in non-stateful mode.

```bash
aomi tx simulate tx-1 tx-2
# If stateful: false, retry
sleep 2
aomi tx simulate tx-1 tx-2
```

## Cross-chain

### Session chain differs from queued tx chain

**Symptoms:**
- `--chain` was set to one chain, but `aomi tx list` shows a tx on a different chain.

**Cause:**
- Normal — the user asked for a cross-chain operation. The session chain is the **starting context**; the agent may stage txs on multiple chains in a single flow (e.g. bridge source + destination).

**Fix:**

This is not an error. Sign with `--rpc-url` matching the queued tx's chain, not the session chain:

```bash
aomi tx sign tx-3 --rpc-url <queued-tx-chain-rpc>
```

A single `--rpc-url` cannot serve a mixed-chain multi-sign request. Sign per-chain:

```bash
# Source chain
aomi tx sign tx-1 tx-2 --rpc-url https://ethereum-rpc.publicnode.com

# Destination chain (separate call)
aomi tx sign tx-3 --rpc-url https://base.publicnode.com
```

## Invocation

### `aomi: command not found`

**Symptoms:**
- Shell can't find the `aomi` binary.

**Cause:**
- No global install, or a PATH issue.

**Fix:**

Substitute `npx @aomi-labs/client` for `aomi` in every command:

```bash
npx @aomi-labs/client --version
npx @aomi-labs/client chat "swap 1 USDC for WETH" --new-session
```

Or install globally:

```bash
npm install -g @aomi-labs/client
```

### Older version (< 0.1.30)

**Symptoms:**
- `aomi --version` reports something older than `0.1.30`.
- Flags like `--aa`, `--aa-provider`, `--aa-mode` not recognized.

**Cause:**
- This skill assumes flags introduced in v0.1.30.

**Fix:**

```bash
npm install -g @aomi-labs/client@latest
# or
npx @aomi-labs/client@latest <command>
```

## Quirks observed in v0.1.30

These are not bugs the skill should try to fix — they are CLI behaviors to recognize and route around.

- **`--new-session` + `--provider-key` on the same call hits a credit-limit error.** The provider key gets registered, but the prompt on that same call still routes through Aomi-managed credits. Workaround: register first with a no-op prompt, then issue the real prompt as a second call without `--new-session`.

  ```bash
  aomi --provider-key anthropic:sk-ant-... --new-session --prompt "ack"
  aomi chat "swap 1 USDC for WETH on Uniswap"
  ```

- **Active session pointer disappears between shell invocations.** Recovery: `aomi session list` → `aomi session resume <N> > /dev/null && aomi tx list` in one shell call.

- **`BYOK key set for anthropic: sk-ant-...` echoes the first ~7 characters of the provider key.** This is by design (provider identification, not authentication). Do not try to scrub it from output — it is not a credential leak.

- **Agent self-heals expired deadlines.** For deadline-bearing routes (Across, Khalani fillers), if simulation reports an expiry, the agent rebuilds the request automatically with fresh deadlines. Do not re-prompt — re-check `aomi tx list` for the latest passing batch.

## Debug Checklist

When in doubt, run through this list:

- [ ] `aomi --version` reports 0.1.30 or newer?
- [ ] `aomi session status` shows an active session matching the expected topic?
- [ ] `aomi tx list` shows the expected `tx-N` entries?
- [ ] For multi-step: `aomi tx simulate tx-1 tx-2` reports `Batch success: true` and `Stateful: true`?
- [ ] If sponsorship was expected on L2, has the user confirmed BYOK provider configuration?
- [ ] Does the EOA have at least a tiny amount of native gas on the **destination** chain?
- [ ] Is `--rpc-url` (signing transport) matched to the queued tx's chain, not the session chain?
- [ ] Are you signing only `Batch [...] passed` txs, ignoring orphans from earlier failed attempts?
