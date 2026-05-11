---
name: manage-aomi-skill
description: >
  Manage the aomi skill distribution pipeline. Trigger when the user asks about platform
  submission status, wants to push a skill update to a distribution channel, needs to add
  a new platform, wants to check staleness, or asks about any platform in _registry.yaml,
  including PR #679, PR #575, PR #21, issue #36, clawhub, codex-marketplace, agensi,
  lobehub, or anthropic submission.
version: "1.0"
author: aomi-labs
license: MIT
compatible-with: claude-code
allowed-tools: "Bash(./aomi-skill-manager.sh:*, git:*, python3:*), Read, Edit, Grep"
permissions:
  files:
    read: [_registry.yaml, aomi-transact/SKILL.md, aomi-build/SKILL.md, distribution/, .worktrees/]
    write: [_registry.yaml, distribution/]
    deny_write: [aomi-transact/SKILL.md, aomi-build/SKILL.md]
  shell: [./aomi-skill-manager.sh, git, python3]
  network: {allow: [], deny: "*"}
risk_tier: L1
requires:
  binaries: [git, python3]
  python_packages: [pyyaml]
---

# Manage Aomi Skill

## Overview

Manages distribution of `aomi-transact` and `aomi-build` across 14 platforms.
Three layers: (1) canonical SKILL.md files on `main`, (2) `_registry.yaml` as
machine-readable status tracker, (3) `./aomi-skill-manager.sh` CLI.

Platform types: `git-pr` (GitHub PR → `platform/*` branch + `.worktrees/*`),
`artifact` (form/upload → `distribution/*`), `cli-publish` (CLI tool → `distribution/*`),
`auto-index` (platform crawls GitHub), `self-hosted` (lives in this repo).

## When to Use

- Check platform status or install counts
- Push Grade A SKILL.md fixes to PR #679 (ccpi)
- Add a new distribution platform
- Check staleness after editing a canonical skill
- Update status after a PR merges or gets blocked
- Set up local worktrees for the first time

## Prerequisites

- `python3` + `pyyaml` (`pip3 install pyyaml`)
- `git` on PATH
- Run all commands from repo root (where `_registry.yaml` lives)

## Quick Start

```bash
./aomi-skill-manager.sh status          # all platforms at a glance
./aomi-skill-manager.sh setup           # create all git-pr worktrees
./aomi-skill-manager.sh stale           # which branches lag main
cd $(./aomi-skill-manager.sh open ccpi) # jump into a platform worktree
```

## Instructions

**Check status:** `./aomi-skill-manager.sh status` — STALE? column shows how many
canonical commits each platform branch hasn't seen. `ok` = up to date.

**Fix blocked PR #679 (ccpi):**
```bash
./aomi-skill-manager.sh setup ccpi
./aomi-skill-manager.sh sync ccpi     # rebases Grade A fixes onto platform/ccpi
./aomi-skill-manager.sh diff ccpi     # verify changes
./aomi-skill-manager.sh push ccpi
./aomi-skill-manager.sh set-status ccpi open
./aomi-skill-manager.sh note ccpi "Grade A fixes pushed — awaiting re-review"
```

**After editing a canonical SKILL.md on main:**
```bash
./aomi-skill-manager.sh stale
./aomi-skill-manager.sh sync --all
```

**Add a new platform:**
```bash
./aomi-skill-manager.sh add smithery
./aomi-skill-manager.sh setup smithery
cd $(./aomi-skill-manager.sh open smithery)
# adapt files for the platform's schema
git add -p && git commit -m "feat: smithery platform variant"
cd - && ./aomi-skill-manager.sh push smithery
```

**Update state after external events:**
```bash
./aomi-skill-manager.sh set-status antigravity merged
./aomi-skill-manager.sh note clawhub "slug released — republishing"
```

## Examples

```bash
./aomi-skill-manager.sh status
./aomi-skill-manager.sh diff ccpi
./aomi-skill-manager.sh sync --all
./aomi-skill-manager.sh set-status codex-marketplace approved
./aomi-skill-manager.sh note agensi "install count: 3"
```

## Output

- `status` → colour table: platform / type / tier / status / staleness / blocker
- `stale` → platforms behind main with commit log
- `setup` → per-platform: exists / ok / skip
- `sync` → ok+synced or CONFLICT with recovery steps
- `diff` → standard git diff on skill files only
- `open` → worktree path for use with `cd $(...)`

## Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| `no _registry.yaml` | Wrong directory | `cd` to repo root |
| `pyyaml required` | Missing package | `pip3 install pyyaml` |
| `Branch not found` | setup not run | `./aomi-skill-manager.sh setup <name>` |
| `CONFLICT` on sync | Branch diverged | Follow printed recovery instructions |
| push rejected | No auth | Check `git remote -v`, ensure SSH/HTTPS auth |

## Safety Justification

Reads and writes `_registry.yaml` and `distribution/`. Does not modify canonical
`aomi-transact/SKILL.md` or `aomi-build/SKILL.md` (deny_write). Shell restricted to
`./aomi-skill-manager.sh`, `git`, `python3`. No network calls. Risk tier: L1.
