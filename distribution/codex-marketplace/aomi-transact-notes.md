# codex-marketplace.com — `aomi-transact` (separate) submission

> **Manual step**: open [codex-marketplace.com](https://codex-marketplace.com) → Submit Plugin form, paste the field values below.
>
> **When to use this packet**: only after the bundle (`aomi`) submission has been processed. Submit this if codex-marketplace allows multiple submissions per repo OR if the bundle is rejected and we need to try the per-skill route.
>
> **Structural caveat**: the legacy `aomi-transact/` directory has `SKILL.md` at its root, not inside a `skills/<name>/SKILL.md` subdirectory like Codex's spec example shows. Codex's `.codex-plugin/plugin.json` schema makes the `skills` field optional — if their loader auto-discovers root-level SKILL.md, the legacy layout works as-is. If it requires the spec layout, we'd need to restructure (move `aomi-transact/SKILL.md` to `aomi-transact/skills/aomi-transact/SKILL.md`) before submitting. Check the form's validator output; restructure if needed.

---

## Form fields

### GitHub repository URL

```
https://github.com/aomi-labs/skills/tree/main/aomi-transact
```

### Plugin name

```
aomi-transact
```

### Plugin description

Use **Tier 2 short** (~700 chars):

```
The Aomi CLI drives an Aomi runtime that reads and writes EVM chain state: stages calldata, simulates as a batch on a forked chain, and returns wallet requests for the user to sign. Works on any EVM contract via low-level primitives — ABI encoding (encode_and_call), fork-batch simulation (simulate_batch), staged-tx queueing (stage_tx), and wallet handoff with EIP-712 (commit_tx, commit_eip712) — including multi-step swap-approve-execute routing. Ships with 40+ tuned protocol apps (Polymarket, 1inch, Dune, GMX, Binance, Hyperliquid, Kaito, …), each loaded dynamically and tuned to the vendor's full API. Every action simulates first, batches when possible, and is signed by the end-user wallet.
```

### Author

- **Name:** aomi-labs
- **URL:** https://aomi.dev

### Homepage

```
https://github.com/aomi-labs/skills/tree/main/aomi-transact
```

### License

```
MIT
```

### Tags / keywords

```
aomi, ai-agents, account-abstraction, intent, natural-language, transactions, simulation, evm, defi, cli
```

### Category

`AI Agents` or `DeFi` (whichever the form lists)

### Notes for reviewer

```
aomi-transact is the on-chain executor skill from the Aomi bundle, submitted
separately for narrower discovery (this lets users find it under "wallet" /
"trading" / "DeFi" search terms specifically without the bundled aomi-build
diluting the listing).

The skill drives @aomi-labs/client (the Aomi CLI) from natural-language
prompts. Each `aomi <subcommand>` invocation starts, runs, and exits — no
long-running process or MCP server.

Risk profile: risk_tier L2 (signs/broadcasts on-chain transactions). Full
OWASP AST03 permission manifest is declared in the SKILL.md frontmatter
(permissions.{files,network,shell,tools}) plus a per-control walkthrough in
SECURITY.md against AST01–AST10.

Independent scanner reports for this skill (live in the source repo at
.scanner-reports/):
  - Cisco AI Defense skill-scanner: SAFE (0 findings)
  - NMitchem/SkillScan: PASS — Risk 2.0/10 (only the known upstream MCP_001
    regex bug; documented in SECURITY.md)
  - pors/skill-audit: PASS (0 errors / 4 doc-pattern WARNs)
  - Snyk agent-scan: PASS (advisory) with 4 W-codes (W007/W009/W011/W012)
    that characterize the intentional risk surface of a tx-signing AI skill;
    each acknowledged with a mitigation in SECURITY.md

If you also accepted the `aomi` bundle submission, this is the same skill
inside that bundle, surfaced as a standalone listing for discoverability.

Note: legacy directory layout has SKILL.md at the plugin root rather than at
skills/aomi-transact/SKILL.md. The .codex-plugin/plugin.json declares no
`skills` field; if your loader expects skills/<name>/SKILL.md, please flag
and we'll restructure.
```
