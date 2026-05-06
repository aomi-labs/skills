# Scanner reports — `aomi-transact`

Audit artifacts for the security scanners listed in [`docs/todo`](../docs/todo) Phase 1.

| Scanner | Status | Report |
|---------|--------|--------|
| [Cisco AI Defense skill-scanner](https://github.com/cisco-ai-defense/skill-scanner) | **PASS** (0 findings) | [`cisco-ai-defense.md`](cisco-ai-defense.md), [`cisco-ai-defense.sarif`](cisco-ai-defense.sarif) |
| [pors/skill-audit](https://github.com/pors/skill-audit) | **PASS** (0 errors, 4 doc-pattern warns) | [`pors-skill-audit.txt`](pors-skill-audit.txt), [`pors-skill-audit.sarif`](pors-skill-audit.sarif) |
| [NMitchem/SkillScan](https://github.com/NMitchem/SkillScan) | **PASS** (Risk 2.0/10, 1 upstream-regex-bug HIGH) | [`skillscan.txt`](skillscan.txt), [`skillscan.json`](skillscan.json), [`skillscan.sarif`](skillscan.sarif) |
| [Snyk agent-scan](https://github.com/snyk/agent-scan) | **BLOCKED** (needs `SNYK_TOKEN`) | [`snyk-agent-scan.txt`](snyk-agent-scan.txt) |

See [`aomi-transact/SECURITY.md`](../aomi-transact/SECURITY.md) for the per-finding analysis and the OWASP AST01–AST10 walkthrough.

## Reproducing the scans

All scanners run free, offline, and without API keys. Capture reports with:

```bash
# Cisco — offline analyzers only
python3 -m venv /tmp/sscan && source /tmp/sscan/bin/activate
pip install cisco-ai-skill-scanner
skill-scanner scan ./aomi-transact \
  --use-behavioral --lenient --format markdown --detailed \
  --output .scanner-reports/cisco-ai-defense.md
skill-scanner scan ./aomi-transact \
  --use-behavioral --lenient --format sarif \
  --output .scanner-reports/cisco-ai-defense.sarif

# pors/skill-audit — needs shellcheck + semgrep + trufflehog
brew install shellcheck semgrep trufflehog  # macOS; apt-get on Linux
pipx install "git+https://github.com/pors/skill-audit@main"
skill-audit ./aomi-transact/ > .scanner-reports/pors-skill-audit.txt 2>&1
skill-audit --format sarif --output .scanner-reports/pors-skill-audit.sarif ./aomi-transact/

# SkillScan — pure Python, no extra deps
pipx install skillscan
skillscan audit ./aomi-transact/ --dir --no-color > .scanner-reports/skillscan.txt 2>&1
skillscan audit ./aomi-transact/ --dir --format json > .scanner-reports/skillscan.json
skillscan audit ./aomi-transact/ --dir --format sarif > .scanner-reports/skillscan.sarif

# Snyk agent-scan — needs SNYK_TOKEN
pipx install snyk-agent-scan
SNYK_TOKEN=... snyk-agent-scan scan --skills ./aomi-transact/SKILL.md
```

The CI workflow at [`.github/workflows/skill-audit.yml`](../.github/workflows/skill-audit.yml) runs Cisco + pors on every PR and uploads SARIF to the GitHub Security tab.

**Last refresh:** 2026-05-06.
