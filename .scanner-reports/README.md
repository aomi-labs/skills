# Scanner reports

Audit artifacts for the security scanners listed in [`docs/todo`](../docs/todo) Phase 1. Reports are organized per skill: top-level files cover `aomi-transact`; the [`aomi-build/`](aomi-build/) subdirectory covers `aomi-build`.

## `aomi-transact`

| Scanner | Status | Report |
|---------|--------|--------|
| [Cisco AI Defense skill-scanner](https://github.com/cisco-ai-defense/skill-scanner) | **PASS** (0 findings) | [`cisco-ai-defense.md`](cisco-ai-defense.md), [`cisco-ai-defense.sarif`](cisco-ai-defense.sarif) |
| [pors/skill-audit](https://github.com/pors/skill-audit) | **PASS** (0 errors, 4 doc-pattern warns) | [`pors-skill-audit.txt`](pors-skill-audit.txt), [`pors-skill-audit.sarif`](pors-skill-audit.sarif) |
| [NMitchem/SkillScan](https://github.com/NMitchem/SkillScan) | **PASS** (Risk 2.0/10, 1 upstream-regex-bug HIGH) | [`skillscan.txt`](skillscan.txt), [`skillscan.json`](skillscan.json), [`skillscan.sarif`](skillscan.sarif) |
| [Snyk agent-scan](https://github.com/snyk/agent-scan) | **PASS (advisory)** — 4 HIGH characterizations of intentional risk surface (W007, W009, W011, W012) | [`snyk-agent-scan.txt`](snyk-agent-scan.txt), [`snyk-agent-scan.json`](snyk-agent-scan.json) |

See [`aomi-transact/SECURITY.md`](../aomi-transact/SECURITY.md) for the per-finding analysis (including the W-code finding-by-finding table for Snyk) and the OWASP AST01–AST10 walkthrough.

## `aomi-build`

| Scanner | Status | Report |
|---------|--------|--------|
| [Cisco AI Defense skill-scanner](https://github.com/cisco-ai-defense/skill-scanner) | **PASS** (0 findings, SAFE) | [`aomi-build/cisco-ai-defense.md`](aomi-build/cisco-ai-defense.md), [`aomi-build/cisco-ai-defense.sarif`](aomi-build/cisco-ai-defense.sarif) |
| [pors/skill-audit](https://github.com/pors/skill-audit) | **PASS** (0 errors, 2 doc-pattern warns) | [`aomi-build/pors-skill-audit.txt`](aomi-build/pors-skill-audit.txt), [`aomi-build/pors-skill-audit.sarif`](aomi-build/pors-skill-audit.sarif) |
| [NMitchem/SkillScan](https://github.com/NMitchem/SkillScan) | **PASS** (Risk 0.0/10, 0 findings) | [`aomi-build/skillscan.txt`](aomi-build/skillscan.txt), [`aomi-build/skillscan.json`](aomi-build/skillscan.json), [`aomi-build/skillscan.sarif`](aomi-build/skillscan.sarif) |
| [Snyk agent-scan](https://github.com/snyk/agent-scan) | **Pending** — requires `SNYK_TOKEN` | — |

See [`aomi-build/SECURITY.md`](../aomi-build/SECURITY.md) for the OWASP AST01–AST10 walkthrough.

## Reproducing the scans

All scanners except Snyk run free, offline, and without API keys. Substitute `aomi-transact` ↔ `aomi-build` in the commands below depending on which skill you're scanning; report outputs go under `.scanner-reports/<skill>/` for `aomi-build` (top-level for `aomi-transact`).

```bash
SKILL=aomi-build   # or aomi-transact
OUT=.scanner-reports/$([ "$SKILL" = "aomi-transact" ] && echo "" || echo "aomi-build/")

# Cisco — offline analyzers only
python3 -m venv /tmp/sscan && source /tmp/sscan/bin/activate
pip install cisco-ai-skill-scanner
skill-scanner scan ./$SKILL \
  --use-behavioral --lenient --format markdown --detailed \
  --output ${OUT}cisco-ai-defense.md
skill-scanner scan ./$SKILL \
  --use-behavioral --lenient --format sarif \
  --output ${OUT}cisco-ai-defense.sarif

# pors/skill-audit — needs shellcheck + semgrep + trufflehog
brew install shellcheck semgrep trufflehog  # macOS; apt-get on Linux
pipx install "git+https://github.com/pors/skill-audit@main"
skill-audit ./$SKILL/ > ${OUT}pors-skill-audit.txt 2>&1
skill-audit --format sarif --output ${OUT}pors-skill-audit.sarif ./$SKILL/

# SkillScan — pure Python, no extra deps
pipx install skillscan
skillscan audit ./$SKILL/ --dir --no-color > ${OUT}skillscan.txt 2>&1
skillscan audit ./$SKILL/ --dir --format json > ${OUT}skillscan.json
skillscan audit ./$SKILL/ --dir --format sarif > ${OUT}skillscan.sarif

# Snyk agent-scan — needs SNYK_TOKEN
pipx install snyk-agent-scan
SNYK_TOKEN=... snyk-agent-scan --skills ./$SKILL/SKILL.md
```

The CI workflow at [`.github/workflows/skill-audit.yml`](../.github/workflows/skill-audit.yml) runs Cisco + pors on **both** `aomi-transact` and `aomi-build` on every PR and uploads SARIF to the GitHub Security tab.

**Last refresh:** 2026-05-07.
