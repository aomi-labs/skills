#!/usr/bin/env bash
# aomi-skill-manager.sh — manage aomi skill distribution across platforms
# Run from repo root. Requires: python3 + pyyaml, git.
set -euo pipefail

REGISTRY="_registry.yaml"
WORKTREES_DIR=".worktrees"
SKILL_FILES=("aomi-transact/SKILL.md" "aomi-build/SKILL.md")

RED='\033[0;31m'; YEL='\033[0;33m'; GRN='\033[0;32m'
CYN='\033[0;36m'; DIM='\033[2m'; BOLD='\033[1m'; NC='\033[0m'

usage() { cat <<'EOF'
aomi-skill-manager — distribute aomi skills across platforms

Commands:
  status                      Table of every platform: type, status, staleness, blocker
  stale                       List git-pr branches that lag main on skill files
  setup [platform]            Create platform branch + worktree (all if omitted)
  sync  <platform|--all>      Rebase platform branch(es) onto current main
  diff  <platform>            Diff canonical skill files vs platform branch
  open  <platform>            Print worktree path  (cd $(./aomi-skill-manager.sh open ccpi))
  push  <platform>            Push platform branch to origin
  set-status <platform> <s>   Update platform status in registry
  note  <platform> <text>     Append timestamped note to platform entry
  add   <name>                Interactively scaffold a new platform entry
  check [platform]            Curl every URL entry with browser UA; report status + title
  registry                    Pretty-print _registry.yaml
EOF
}

_py() {
  python3 - "$@" <<'PYEOF'
import sys, yaml, json, datetime

with open("_registry.yaml") as f:
    data = yaml.safe_load(f)
cmd = sys.argv[1]

def save():
    with open("_registry.yaml", "w") as f:
        yaml.dump(data, f, default_flow_style=False, sort_keys=False,
                  allow_unicode=True, width=120)

if cmd == "platforms":
    [print(n) for n in data.get("platforms", {})]
elif cmd == "git-pr-platforms":
    [print(n) for n, p in data.get("platforms", {}).items() if p.get("type") == "git-pr"]
elif cmd == "get":
    val = data["platforms"][sys.argv[2]].get(sys.argv[3], "")
    print(" ".join(val) if isinstance(val, list) else ("" if val is None else val))
elif cmd == "status-table":
    for n, p in data.get("platforms", {}).items():
        blocker = (p.get("blocker") or p.get("notes") or "")[:55]
        print(f"{n}|{p.get('type','')}|{p.get('tier','-')}|{p.get('status','?')}|{p.get('branch','-')}|{blocker}")
elif cmd == "update-sha":
    data["platforms"][sys.argv[2]]["last_synced_sha"] = sys.argv[3]; save()
elif cmd == "update-status":
    data["platforms"][sys.argv[2]]["status"] = sys.argv[3]; save()
    print(f"Set {sys.argv[2]}.status = {sys.argv[3]}")
elif cmd == "append-note":
    ts = datetime.date.today().isoformat()
    existing = data["platforms"][sys.argv[2]].get("notes") or ""
    data["platforms"][sys.argv[2]]["notes"] = f"{existing} [{ts}] {sys.argv[3]}".strip(); save()
    print(f"Note appended to {sys.argv[2]}")
elif cmd == "add-platform":
    entry = json.loads(sys.argv[2]); name = entry.pop("name")
    if name in data["platforms"]: print(f"exists: {name}", file=sys.stderr); sys.exit(1)
    data["platforms"][name] = entry; save(); print(f"Added: {name}")
elif cmd == "skills":
    [print(n) for n in data.get("skills", {})]
elif cmd == "skill-version":
    print(data["skills"][sys.argv[2]].get("version", "?"))
elif cmd == "urls":
    for n, p in data.get("platforms", {}).items():
        if p.get("url"):
            print(f"{n}|{p['url']}")
        for slug, url in (p.get("urls") or {}).items():
            print(f"{n}:{slug}|{url}")
elif cmd == "update-checked":
    import datetime
    data["platforms"][sys.argv[2]]["last_checked"] = datetime.date.today().isoformat(); save()
PYEOF
}

_check_deps() {
    command -v python3 >/dev/null || { echo "python3 required"; exit 1; }
    python3 -c "import yaml" 2>/dev/null || { echo "pip3 install pyyaml"; exit 1; }
    command -v git >/dev/null || { echo "git required"; exit 1; }
}
_check_root() {
    [[ -f "$REGISTRY" ]] || { echo "Run from repo root (no $REGISTRY here)"; exit 1; }
}
_branch_exists() { git show-ref --verify --quiet "refs/heads/$1" 2>/dev/null; }
_commits_ahead() {
    git log --oneline "$1..main" -- "${SKILL_FILES[@]}" 2>/dev/null | wc -l | tr -d ' '
}

cmd_status() {
    _check_root
    printf "\n${BOLD}${CYN}%-22s %-13s %-5s %-12s %-9s %s${NC}\n"         PLATFORM TYPE TIER STATUS STALE? "BLOCKER / NOTE"
    printf "${DIM}%s${NC}\n" "$(printf '─%.0s' {1..108})"
    while IFS='|' read -r name ptype tier status branch blocker; do
        stale="-"
        if [[ "$ptype" == "git-pr" && "$branch" != "-" && -n "$branch" ]]; then
            if _branch_exists "$branch"; then
                behind=$(_commits_ahead "$branch")
                stale=$([[ "$behind" -gt 0 ]] && echo "${YEL}${behind} behind${NC}" || echo "${GRN}ok${NC}")
            else
                stale="${DIM}no branch${NC}"
            fi
        fi
        color=$NC
        case "$status" in
            merged|live|approved) color=$GRN ;;
            blocked|rejected)     color=$RED ;;
            pending|open|ready)   color=$YEL ;;
            deferred|waiting)     color=$DIM ;;
        esac
        printf "%-22s %-13s %-5s ${color}%-12s${NC} %-18b %s\n"             "$name" "$ptype" "$tier" "$status" "$stale" "$blocker"
    done < <(_py status-table)
    echo
    printf "${DIM}Skills: "
    while read -r s; do printf "%s@%s  " "$s" "$(_py skill-version "$s")"; done < <(_py skills)
    printf "${NC}\n\n"
}

cmd_stale() {
    _check_root; found=0
    while read -r name; do
        branch=$(_py get "$name" branch); [[ -z "$branch" ]] && continue
        _branch_exists "$branch" || { printf "${DIM}no branch${NC}  %s\n" "$name"; continue; }
        commits=$(git log --oneline "$branch..main" -- "${SKILL_FILES[@]}" 2>/dev/null)
        if [[ -n "$commits" ]]; then
            printf "${YEL}STALE${NC}  %-22s  %s\n" "$name" "$branch"
            echo "$commits" | sed 's/^/         /'; found=1
        fi
    done < <(_py git-pr-platforms)
    [[ "$found" -eq 0 ]] && printf "${GRN}All git-pr branches up to date.${NC}\n"
}

cmd_setup() {
    _check_root; mkdir -p "$WORKTREES_DIR"
    local target="${1:-}"
    [[ -n "$target" ]] && platforms=("$target") || mapfile -t platforms < <(_py git-pr-platforms)
    for name in "${platforms[@]}"; do
        branch=$(_py get "$name" branch); wt=$(_py get "$name" worktree)
        [[ -z "$branch" || -z "$wt" ]] && { printf "${DIM}skip${NC} %s\n" "$name"; continue; }
        if [[ -d "$wt" ]]; then printf "${GRN}exists${NC} %-22s → %s\n" "$name" "$wt"; continue; fi
        _branch_exists "$branch" || { git checkout -b "$branch" main -q; git checkout main -q; }
        git worktree add "$wt" "$branch"
        printf "${GRN}ok${NC} %-22s → %s\n" "$name" "$wt"
    done
}

cmd_sync() {
    _check_root; target="${1:-}"
    [[ -z "$target" ]] && { echo "Usage: sync <platform|--all>"; exit 1; }
    [[ "$target" == "--all" ]] && mapfile -t platforms < <(_py git-pr-platforms) || platforms=("$target")
    main_sha=$(git rev-parse HEAD)
    for name in "${platforms[@]}"; do
        branch=$(_py get "$name" branch); [[ -z "$branch" ]] && continue
        _branch_exists "$branch" || { printf "${YEL}skip${NC} %s — run: setup %s\n" "$name" "$name"; continue; }
        behind=$(_commits_ahead "$branch")
        if [[ "$behind" -eq 0 ]]; then printf "${GRN}ok${NC} %-22s already up to date\n" "$name"; continue; fi
        printf "Syncing %-22s (%s commits behind)…\n" "$name" "$behind"
        git checkout "$branch" -q
        if git rebase main -q; then
            git checkout main -q; _py update-sha "$name" "${main_sha:0:7}"
            printf "${GRN}ok${NC} %-22s synced → %s\n" "$name" "${main_sha:0:7}"
        else
            git rebase --abort; git checkout main -q
            printf "${RED}CONFLICT${NC} %s — rebase aborted. Fix manually:\n  git checkout %s\n  git rebase main\n" "$name" "$branch"
        fi
    done
}

cmd_diff() {
    _check_root; name="${1:?Usage: diff <platform>}"
    branch=$(_py get "$name" branch); [[ -z "$branch" ]] && { echo "No branch for $name"; exit 1; }
    _branch_exists "$branch" || { echo "Branch $branch not found. Run: setup $name"; exit 1; }
    git diff "main...$branch" -- "${SKILL_FILES[@]}"
}

cmd_open() {
    _check_root; name="${1:?Usage: open <platform>}"
    wt=$(_py get "$name" worktree); [[ -z "$wt" ]] && { echo "No worktree for $name"; exit 1; }
    echo "$wt"
}

cmd_push() {
    _check_root; name="${1:?Usage: push <platform>}"
    branch=$(_py get "$name" branch); [[ -z "$branch" ]] && { echo "No branch for $name"; exit 1; }
    git push -u origin "$branch"; printf "${GRN}pushed${NC} %s\n" "$branch"
}

cmd_set_status() {
    _check_root
    _py update-status "${1:?Usage: set-status <platform> <status>}" "${2:?missing status}"
}

cmd_note() {
    _check_root
    _py append-note "${1:?Usage: note <platform> <text>}" "${2:?missing text}"
}

cmd_check() {
    _check_root
    command -v curl >/dev/null || { echo "curl required"; exit 1; }
    local ua='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    local filter="${1:-}" hit_any=0
    declare -A platform_seen
    while IFS='|' read -r key url; do
        [[ -z "$url" ]] && continue
        platform="${key%%:*}"
        [[ -n "$filter" && "$platform" != "$filter" ]] && continue
        hit_any=1
        body=$(curl -sL -A "$ua" --max-time 10 -w '\n__STATUS__%{http_code}' "$url" 2>/dev/null || printf '\n__STATUS__000')
        status="${body##*__STATUS__}"
        title=$(printf '%s' "${body%__STATUS__*}" | tr -d '\0' | grep -oE '<title>[^<]*</title>' | head -1 | sed -E 's/<[^>]*>//g; s/^[[:space:]]+//; s/[[:space:]]+$//' || true)
        case "$status" in
            200)    color=$GRN ;;
            301|302|307|308) color=$CYN ;;
            403|404|410)     color=$YEL ;;
            5*|000) color=$RED ;;
            *)      color=$NC  ;;
        esac
        printf "${color}%3s${NC}  %-32s  %s\n" "$status" "$key" "${title:0:70}"
        if [[ "$status" == "200" && -z "${platform_seen[$platform]:-}" ]]; then
            _py update-checked "$platform" >/dev/null
            platform_seen[$platform]=1
        fi
    done < <(_py urls)
    if [[ "$hit_any" -eq 0 ]]; then
        printf "${YEL}No URL entries%s${NC}\n" "${filter:+ matching $filter}"
        return 1
    fi
    return 0
}

cmd_add() {
    _check_root; name="${1:?Usage: add <name>}"
    read -rp "Type [git-pr/artifact/cli-publish/auto-index]: " ptype; ptype="${ptype:-git-pr}"
    read -rp "Tier [1/2/3]: " tier; tier="${tier:-2}"
    read -rp "Description: " desc
    read -rp "Skills (space-sep) [aomi-transact]: " skills_raw; skills_raw="${skills_raw:-aomi-transact}"
    entry=$(python3 -c "
import json
e = {'name':'$name','type':'$ptype','tier':int('$tier'),'description':'$desc',
     'skills':'$skills_raw'.split(),'status':'open'}
if '$ptype'=='git-pr': e.update({'branch':'platform/$name','worktree':'.worktrees/$name','last_synced_sha':None})
elif '$ptype' in ('artifact','cli-publish'): e['path']='distribution/$name/'
print(json.dumps(e))")
    _py add-platform "$entry"
    if [[ "$ptype" == "git-pr" ]]; then
        echo "Run: ./aomi-skill-manager.sh setup $name"
    else
        mkdir -p "distribution/$name"; touch "distribution/$name/.gitkeep"
        printf "${GRN}Created${NC} distribution/%s/\n" "$name"
    fi
}

_check_deps
case "${1:-help}" in
    status)     cmd_status ;;
    stale)      cmd_stale ;;
    setup)      cmd_setup "${2:-}" ;;
    sync)       cmd_sync "${2:-}" ;;
    diff)       cmd_diff "${2:-}" ;;
    open)       cmd_open "${2:-}" ;;
    push)       cmd_push "${2:-}" ;;
    set-status) cmd_set_status "${2:-}" "${3:-}" ;;
    note)       cmd_note "${2:-}" "${3:-}" ;;
    add)        cmd_add "${2:-}" ;;
    check)      cmd_check "${2:-}" ;;
    registry)   cat "$REGISTRY" ;;
    help|--help|-h) usage ;;
    *) echo "Unknown: $1"; usage; exit 1 ;;
esac
