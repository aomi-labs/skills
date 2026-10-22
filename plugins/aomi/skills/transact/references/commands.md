# Command reference

## Availability

The standalone package is `@aomi-labs/cli`; `@aomi-labs/client` now ships an
instructional migration shim. Legacy client-embedded CLI 0.9.4 and standalone
CLI 0.1.2 have separate version histories. Compare capabilities, not the two
version numbers.

This revision targets CLI 0.1.2 / client 0.10.6 from
[aomi PR 769](https://github.com/aomi-labs/aomi/pull/769). On 2026-10-22 the public
npm registry returned E404 for the standalone package. The candidate was tested
from packed artifacts; that is not evidence of public publication. Before
recommending installation, verify the exact version exists:

```sh
npm view @aomi-labs/cli@0.1.2 version --registry=https://registry.npmjs.org
```

After availability is confirmed, an installation is a separate user-approved
setup action. Use the published standalone CLI, then inspect the binary actually
on PATH:

```sh
aomi --version
aomi tx --help
aomi tx export --help
aomi tx submit --help
aomi tx preflight --help
```

An existing executable can be an old embedded CLI even when a newer package is
installed elsewhere. If a required command is absent, stop that branch and report
which package/capability is needed. Preserve the working executable when the
replacement is unavailable. Skill installation updates instructions only.

## Commit and payment commands

```sh
aomi config current --json
aomi wallet current --json
aomi session list
aomi session resume <local-session-id>
aomi tx preflight <intent-file>
aomi chat "<intent>" --new-session --public-key <sender> --chain <chain-id>
aomi tx list --json
aomi tx export <commit-id> --format commit > reviewed-commit.json
aomi tx sign <commit-id>
aomi tx submit <commit-id> --signed-file <signed-export-file>
aomi tx submit <commit-id> --tx-hash <prepared-broadcast-hash>
```

Preflight is read-only on chain and never signs.
A full Commit ID identifies the durable payment. An external signed file uses
`aomi.commit.v1`, the unchanged exact exported Commit, and a top-level `payloads`
array. `--tx-hash` reports the exact prepared broadcast hash; it is not a general
way to attach arbitrary transactions.

`tx list` can contain both Commits and legacy Actions. `tx simulate` accepts
legacy EVM Action IDs; consult the current help only if that branch is needed.
A Commit's simulation evidence is already in its durable review.

## Transport and signing

| Setting | Meaning |
| --- | --- |
| `--backend-url` / `AOMI_BACKEND_URL` | Portal/BFF origin, production `https://chat.aomi.dev`, staging `https://chat-staging.aomi.dev` |
| `--public-key` | Intended sender context, not authorization or proof of funding |
| `--chain` | Explicit session chain ID |
| `--rpc-url` / `CHAIN_RPC_URL` | Signing RPC, must match the prepared transaction's chain |
| `--account-bearer` / `AOMI_ACCOUNT_BEARER` | Account authorization, never print its value |
| `AOMI_STATE_DIR` | Local CLI state directory, default `~/.aomi` |

`config current --json` reports a sanitized origin and its source (flag, env,
saved session, default). Environment overrides take precedence over saved
configuration. The direct backend `api.aomi.dev` / `api-staging.aomi.dev` does
not serve Portal guest login. Correct only the CLI's override when other tools
still need a direct backend URL.

Signing configuration belongs to the designated signer. Inspect the live
command help for EOA/AA/Solana flags, then match the exported Commit payload.
The separate Rust `aomi-cli` interface is not interchangeable with these commands.
