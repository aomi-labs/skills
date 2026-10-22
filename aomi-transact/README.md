# Aomi Transact

An Agent Skill for preparing and executing user-authorized transactions through
the standalone `@aomi-labs/cli` interface:

```text
operational funding → exact intent → durable Commit review and simulation
→ authorized signature → submission → receipt → recipient funds
```

Start with [SKILL.md](SKILL.md). Before recommending any CLI upgrade, follow the
[availability and capability gate](references/commands.md#availability). The
current skill targets CLI 0.1.2 / client 0.10.6 from aomi PR 769; packed-artifact
verification does not establish public npm availability. Skill installation
never upgrades a pre-existing global executable.

Install the instructions with your host's skill installer or from the repository's
Aomi plugin. The canonical source is this folder; the plugin's `skills/transact`
copy is checked for exact agreement in CI.

Use the skill for balances, direct payments, swaps, lending, bridging or staking.
It selects known operational funding positions before considering a separately
authorized treasury refill, preserves exact Commit identity through interruption,
and requires destination evidence before reporting completion. AA and cross-chain
flows follow their own prepared payloads and destination proofs.

The [shell template](templates/aomi-workflow.sh) offers preparation and read-only
review/recovery helpers. It requires explicit sender/chain and does not install,
sign, broadcast or sweep a queue. Run `python3 -m unittest discover -s tests -v`
from the repository root to verify the template and plugin mirror.

Read [SECURITY.md](SECURITY.md) for credential, authorization and trust boundaries.
