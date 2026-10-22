# Payment workflows

## Funding

Resolve destination chain ID, token contract/decimals, amount and recipient first.
Read the wallet catalog's role/address/chain metadata without exposing keys.
For each known operational position, obtain fresh token and native gas balances
from a chain-matching RPC. Check the actual token contract, not only its symbol.
Exclude treasury, development and third-party wallets from automatic selection.
Role metadata records provenance; it does not grant signing authorization.

When available, `aomi tx preflight <intent-file>` performs these read-only checks
in the shared SDK. File shape:

```json
{
  "payment": {
    "asset": { "chainId": 1, "token": "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", "decimals": 6 },
    "recipient": "0x2222222222222222222222222222222222222222",
    "amount": "1500"
  },
  "rpcUrl": "https://ethereum-rpc.publicnode.com",
  "sources": [{
    "address": "0x1111111111111111111111111111111111111111",
    "role": "operational",
    "asset": { "chainId": 1, "token": "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", "decimals": 6 },
    "rpcUrl": "https://ethereum-rpc.publicnode.com"
  }]
}
```

Replace example terms with the approved catalog and user request. Add a source
for each known funded chain/asset; this command does not discover every wallet
position. After selecting, save the approved address as `payment.sender` for
status reconciliation. Preserve this file, original session and full Commit ID
together. Keep private keys/bearers outside the file and secure any credentialed
RPC URLs; reports omit URLs.

The report shows source and destination assets, balances, exact token shortfall
and an estimated native gas budget in base units (gas estimate × twice current
gas price). This is a budget, not a guaranteed fee. `route_required` means a
different token/chain needs a fresh route; fees remain `unquoted` and shortfall
unknown until minimum destination output is verified. A failed RPC is unavailable
evidence, not a zero balance. A token-funded wallet without native gas is not a
funded direct-transfer source. Report the operational shortfall before proposing
any separately authorized treasury refill.

## Execution

Use the main skill's prepare/review procedure, preserving its original session.
Export the exact full Commit ID and check all payment terms, simulation and
fees. Use only the reviewed Commit for execution. For local authorized signing:

```sh
aomi tx sign <commit-id>
```

For external signing, hand the unchanged export to the designated signer. A
signed export must retain `format: "aomi.commit.v1"`, the exact current `commit`
and a top-level `payloads` array. Report it using `tx submit --signed-file`.
For a wallet-broadcast prepared transaction, report its exact expected hash with
`tx submit --tx-hash`. A modified/expired review needs fresh review before signing.

## Reconciliation

Resume the original session and refresh the existing Commit before retrying.
An outstanding wallet attempt, signed payload or known transaction hash must be
reconciled before requesting a new signature; a timeout does not mean failure.
For one direct ERC-20 EOA payment:

```sh
aomi tx status <commit-id> --payment <intent-file>
```

The intent requires the approved `payment.sender`. Status projects the existing
durable Commit and live chain evidence; it does not create another payment or
signer. Keep all stages attached to that ID:

| Evidence | Report |
| --- | --- |
| Prepared review, no valid simulation | Prepared; review incomplete |
| Passed simulation, no signature | Simulated; awaiting authorized signature |
| Signed, not submitted | Signed; awaiting submission |
| Hash, no mined receipt | Submitted/pending; reconcile that hash |
| Receipt reverted | Failed on chain; preserve evidence |
| Receipt success, destination proof missing | Recipient verification pending |
| Canonical receipt, exact Transfer and recipient increase | Payment completed |

RPC failures, noncanonical blocks, missing historical state or same-block outgoing
funds can leave verification pending. Do not infer a second payment is needed.
For swaps, AA, batches and bridges, the direct ERC-20 reader cannot prove payment;
verify the actual execution plus destination receipt, output token and spendable
balance separately. A source bridge receipt is only the source leg.

## Secret ingestion

Use an existing authorized signer for execution. Changing credentials is a
separate, explicitly requested setup action. CLI wallet setup persists local
signing material in private state; secret ingestion transmits supplied app
credentials to the backend and stores returned handles locally. Explain that
storage/transmission boundary before setup. Keep values opaque: report only
address, credential name/presence or handle name, never values or signed bytes.
