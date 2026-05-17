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
  verify [platform]           Hit each `verify_urls` (inverted: 404=available, 200=squatted)
  publish <plat> <slug>       Publish a cli-publish platform's skill (use --dry-run to preview)
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
elif cmd == "verify-urls":
    for n, p in data.get("platforms", {}).items():
        for slug, url in (p.get("verify_urls") or {}).items():
            print(f"{n}:{slug}|{url}")
elif cmd == "publish-path":
    p = data["platforms"][sys.argv[2]].get("publish_paths") or {}
    print(p.get(sys.argv[3], ""))
elif cmd == "platform-cli":
    print(data["platforms"][sys.argv[2]].get("cli", ""))
elif cmd == "record-published":
    pub = data["platforms"][sys.argv[2]].setdefault("publish" + "ed", {})
    pub[sys.argv[3]] = sys.argv[4]
    import datetime
    data["platforms"][sys.argv[2]]["last_published"] = datetime.date.today().isoformat()
    save()
elif cmd == "health-checks-tsv":
    for n, p in data.get("platforms", {}).items():
        hc = dict(p.get("health_check") or {})
        if not hc:
            # Back-compat inference if a platform lacks health_check.
            if "pr" in p: hc = {"method": "gh-pr", "pr": p["pr"]}
            elif "issue" in p: hc = {"method": "gh-issue", "issue": p["issue"]}
            elif "urls" in p: hc = {"method": "http-200", "urls": p["urls"]}
            elif "url" in p: hc = {"method": "http-200", "url": p["url"]}
            else: hc = {"method": "manual", "reason": "no health_check configured"}
        method = hc.pop("method", "manual")
        print(f"{n}\t{method}\t{json.dumps(hc)}")
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

_UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'

# Each method handler: prints one line per probe and returns 0 on overall pass, 1 on fail.
# Args: $1=platform name, rest=method-specific JSON from _py health-check-json.

_curl_with_retry() {
    # $1=url; emits body + __STATUS__<code> on stdout. Retries once on 000 (transient).
    local url="$1" body status
    body=$(curl -sL -A "$_UA" --max-time 10 -w '\n__STATUS__%{http_code}' "$url" 2>/dev/null || printf '\n__STATUS__000')
    status="${body##*__STATUS__}"
    if [[ "$status" == "000" ]]; then
        sleep 1
        body=$(curl -sL -A "$_UA" --max-time 15 -w '\n__STATUS__%{http_code}' "$url" 2>/dev/null || printf '\n__STATUS__000')
    fi
    printf '%s' "$body"
}

_hc_http_200() {
    local name="$1" cfg="$2" pass=1
    # cfg is JSON; pull url(s) and optional needle
    local urls; urls=$(echo "$cfg" | python3 -c "import json,sys; d=json.load(sys.stdin); us=d.get('urls') or {}; print('\n'.join(f'{k}\t{v}' for k,v in us.items()) if us else f'_\t{d.get(\"url\",\"\")}')")
    local needle; needle=$(echo "$cfg" | python3 -c "import json,sys; print(json.load(sys.stdin).get('needle',''))")
    local needle_optional; needle_optional=$(echo "$cfg" | python3 -c "import json,sys; print('1' if json.load(sys.stdin).get('needle_optional') else '')")
    while IFS=$'\t' read -r slug url; do
        [[ -z "$url" ]] && continue
        [[ "$slug" == "_" ]] && slug=""
        local key="$name"; [[ -n "$slug" ]] && key="$name:$slug"
        local body; body=$(_curl_with_retry "$url")
        local status="${body##*__STATUS__}"
        local content; content=$(printf '%s' "${body%__STATUS__*}" | tr -d '\0')
        local detail=""
        local ok=1
        if [[ "$status" != "200" ]]; then ok=0; detail="HTTP $status"; fi
        if [[ -n "$needle" && "$ok" -eq 1 ]]; then
            if ! grep -qE "$needle" <<<"$content"; then
                if [[ -n "$needle_optional" ]]; then
                    detail="200, needle '$needle' not found (ok: indexing pending)"
                else
                    ok=0; detail="200 but needle '$needle' missing"
                fi
            else
                detail="200 + needle"
            fi
        fi
        if [[ "$ok" -eq 1 ]]; then
            printf "${GRN}  ok${NC}  %-32s  %s\n" "$key" "$detail"
        else
            printf "${RED}fail${NC}  %-32s  %s\n" "$key" "$detail"; pass=0
        fi
    done <<<"$urls"
    return $((1 - pass))
}

_hc_http_404() {
    local name="$1" cfg="$2" pass=1
    local urls; urls=$(echo "$cfg" | python3 -c "import json,sys; d=json.load(sys.stdin); us=d.get('urls') or {}; print('\n'.join(f'{k}\t{v}' for k,v in us.items()) if us else f'_\t{d.get(\"url\",\"\")}')")
    while IFS=$'\t' read -r slug url; do
        [[ -z "$url" ]] && continue
        [[ "$slug" == "_" ]] && slug=""
        local key="$name"; [[ -n "$slug" ]] && key="$name:$slug"
        local code; code=$(curl -sL -A "$_UA" --max-time 10 -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
        if [[ "$code" == "404" ]]; then
            printf "${GRN}  ok${NC}  %-32s  404 (slug available)\n" "$key"
        elif [[ "$code" == "200" ]]; then
            printf "${RED}fail${NC}  %-32s  200 (slug SQUATTED — investigate)\n" "$key"; pass=0
        else
            printf "${YEL}warn${NC}  %-32s  HTTP $code (api state unknown)\n" "$key"; pass=0
        fi
    done <<<"$urls"
    return $((1 - pass))
}

_hc_gh_pr() {
    local name="$1" cfg="$2"
    local pr; pr=$(echo "$cfg" | python3 -c "import json,sys; print(json.load(sys.stdin).get('pr',''))")
    [[ -z "$pr" ]] && { printf "${YEL}warn${NC}  %-32s  no pr URL\n" "$name"; return 1; }
    local info; info=$(gh pr view "$pr" --json state,isDraft,mergeable,statusCheckRollup,updatedAt 2>&1)
    if ! echo "$info" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null; then
        printf "${RED}fail${NC}  %-32s  gh: %s\n" "$name" "$(echo "$info" | head -1 | head -c 60)"
        return 1
    fi
    local state; state=$(echo "$info" | python3 -c "import json,sys; print(json.load(sys.stdin).get('state',''))")
    local updated; updated=$(echo "$info" | python3 -c "import json,sys; print(json.load(sys.stdin).get('updatedAt','')[:10])")
    local color="$NC" tag="$state"
    case "$state" in
        MERGED) color="$GRN"; tag="merged" ;;
        OPEN)   color="$CYN"; tag="open" ;;
        CLOSED) color="$YEL"; tag="closed (not merged)" ;;
    esac
    printf "${color}%4s${NC}  %-32s  %s · updated %s\n" "${tag:0:4}" "$name" "$tag" "$updated"
    return 0
}

_hc_gh_issue() {
    local name="$1" cfg="$2"
    local issue; issue=$(echo "$cfg" | python3 -c "import json,sys; print(json.load(sys.stdin).get('issue',''))")
    [[ -z "$issue" ]] && { printf "${YEL}warn${NC}  %-32s  no issue URL\n" "$name"; return 1; }
    local info; info=$(gh issue view "$issue" --json state,comments,updatedAt 2>&1)
    if ! echo "$info" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null; then
        printf "${RED}fail${NC}  %-32s  gh: %s\n" "$name" "$(echo "$info" | head -1 | head -c 60)"
        return 1
    fi
    local state; state=$(echo "$info" | python3 -c "import json,sys; print(json.load(sys.stdin).get('state',''))")
    local comments; comments=$(echo "$info" | python3 -c "import json,sys; print(len(json.load(sys.stdin).get('comments',[])))")
    local updated; updated=$(echo "$info" | python3 -c "import json,sys; print(json.load(sys.stdin).get('updatedAt','')[:10])")
    local color="$NC" tag="$state"
    case "$state" in
        OPEN)   color="$CYN"; tag="open" ;;
        CLOSED) color="$GRN"; tag="closed" ;;
    esac
    printf "${color}%4s${NC}  %-32s  %s · %s comments · updated %s\n" "${tag:0:4}" "$name" "$tag" "$comments" "$updated"
    return 0
}

_hc_marketplace_search() {
    local name="$1" cfg="$2"
    local url; url=$(echo "$cfg" | python3 -c "import json,sys; print(json.load(sys.stdin).get('url',''))")
    local needle; needle=$(echo "$cfg" | python3 -c "import json,sys; print(json.load(sys.stdin).get('needle',''))")
    local body; body=$(curl -sL -A "$_UA" --max-time 15 "$url" 2>/dev/null)
    if [[ -z "$body" ]]; then sleep 1; body=$(curl -sL -A "$_UA" --max-time 30 "$url" 2>/dev/null); fi
    if [[ -z "$body" ]]; then
        printf "${RED}fail${NC}  %-32s  fetch failed: %s\n" "$name" "$url"
        return 1
    fi
    if grep -qE "$needle" <<<"$body"; then
        printf "${GRN}  ok${NC}  %-32s  needle '%s' found in marketplace\n" "$name" "$needle"
        return 0
    fi
    printf "${YEL}pend${NC}  %-32s  needle '%s' not yet in %s\n" "$name" "$needle" "${url##*/}"
    return 1
}

_hc_npm_view() {
    local name="$1" cfg="$2"
    local pkg; pkg=$(echo "$cfg" | python3 -c "import json,sys; print(json.load(sys.stdin).get('package',''))")
    [[ -z "$pkg" ]] && { printf "${YEL}warn${NC}  %-32s  no package name\n" "$name"; return 1; }
    command -v npm >/dev/null || { printf "${YEL}warn${NC}  %-32s  npm not installed\n" "$name"; return 1; }
    local ver; ver=$(npm view "$pkg" version 2>/dev/null)
    if [[ -n "$ver" ]]; then
        printf "${GRN}  ok${NC}  %-32s  %s@%s\n" "$name" "$pkg" "$ver"
        return 0
    fi
    printf "${RED}fail${NC}  %-32s  %s — npm view returned empty\n" "$name" "$pkg"
    return 1
}

_hc_manual() {
    local name="$1" cfg="$2"
    local reason; reason=$(echo "$cfg" | python3 -c "import json,sys; print(json.load(sys.stdin).get('reason','manual check'))")
    printf "${DIM} man${NC}  %-32s  %s\n" "$name" "$reason"
    return 0
}

cmd_check() {
    _check_root
    command -v curl >/dev/null || { echo "curl required"; exit 1; }
    local filter="${1:-}" hit_any=0 fail_count=0
    while IFS=$'\t' read -r name method cfg; do
        [[ -z "$name" ]] && continue
        [[ -n "$filter" && "$name" != "$filter" ]] && continue
        hit_any=1
        local rc=0
        case "$method" in
            http-200) _hc_http_200 "$name" "$cfg" || rc=$? ;;
            http-404) _hc_http_404 "$name" "$cfg" || rc=$? ;;
            gh-pr)    _hc_gh_pr "$name" "$cfg" || rc=$? ;;
            gh-issue) _hc_gh_issue "$name" "$cfg" || rc=$? ;;
            marketplace-search) _hc_marketplace_search "$name" "$cfg" || rc=$? ;;
            npm-view) _hc_npm_view "$name" "$cfg" || rc=$? ;;
            manual)   _hc_manual "$name" "$cfg" || rc=$? ;;
            *) printf "${YEL}skip${NC}  %-32s  unknown method: %s\n" "$name" "$method"; rc=1 ;;
        esac
        [[ "$rc" -ne 0 ]] && fail_count=$((fail_count + 1))
        # Mark last_checked on every probe regardless of pass/fail (we ran the check).
        _py update-checked "$name" >/dev/null 2>&1 || true
    done < <(_py health-checks-tsv)
    if [[ "$hit_any" -eq 0 ]]; then
        printf "${YEL}No platforms%s${NC}\n" "${filter:+ matching $filter}"
        return 1
    fi
    echo
    printf "${BOLD}%d failures${NC}\n" "$fail_count"
    return 0
}

_semver_from_frontmatter() {
    python3 - "$1" <<'PYEOF'
import sys, re
with open(sys.argv[1]) as f:
    content = f.read()
m = re.search(r'^---\s*\n(.*?)\n---', content, re.DOTALL)
if not m: sys.exit("no frontmatter")
fm = m.group(1)
vm = re.search(r'^version:\s*[\'\"]?([0-9.]+)[\'\"]?\s*$', fm, re.MULTILINE)
if not vm: sys.exit("no version field")
parts = vm.group(1).split(".")
while len(parts) < 3: parts.append("0")
print(".".join(parts[:3]))
PYEOF
}

cmd_publish() {
    _check_root
    local platform="${1:?Usage: publish <platform> <slug> [--dry-run]}"
    local slug="${2:?Usage: publish <platform> <slug> [--dry-run]}"
    local dry=""; [[ "${3:-}" == "--dry-run" ]] && dry=1
    local cli; cli=$(_py platform-cli "$platform")
    [[ -z "$cli" ]] && { printf "${RED}No 'cli:' field for platform '%s'${NC}\n" "$platform"; exit 1; }
    command -v "$cli" >/dev/null || { printf "${RED}CLI not installed: %s${NC}\n" "$cli"; exit 1; }
    local rel; rel=$(_py publish-path "$platform" "$slug")
    [[ -z "$rel" ]] && { printf "${RED}No publish_paths.%s on platform %s${NC}\n" "$slug" "$platform"; exit 1; }
    local abs; abs="$(pwd)/$rel"
    [[ -d "$abs" ]] || { printf "${RED}Not a directory: %s${NC}\n" "$abs"; exit 1; }
    [[ -f "$abs/SKILL.md" ]] || { printf "${RED}No SKILL.md in %s${NC}\n" "$abs"; exit 1; }
    local version; version=$(_semver_from_frontmatter "$abs/SKILL.md") || exit 1
    printf "${BOLD}publish${NC} %s/%s @ %s ${DIM}(%s)${NC}\n" "$platform" "$slug" "$version" "$abs"
    if [[ -n "$dry" ]]; then
        printf "${DIM}DRY-RUN — would run from /tmp:${NC}\n  %s --no-input skill publish %s --slug %s --version %s\n" \
            "$cli" "$abs" "$slug" "$version"
        return 0
    fi
    case "$cli" in
        clawhub)
            ( cd /tmp && "$cli" --no-input skill publish "$abs" --slug "$slug" --version "$version" )
            ;;
        *)
            printf "${RED}publish not implemented for cli: %s${NC}\n" "$cli"; exit 1
            ;;
    esac
    local rc=$?
    if [[ "$rc" -eq 0 ]]; then
        _py record-published "$platform" "$slug" "$version" >/dev/null
        printf "${GRN}published${NC} %s/%s @ %s\n" "$platform" "$slug" "$version"
    else
        printf "${RED}publish failed${NC} (exit %s)\n" "$rc"
        exit "$rc"
    fi
}

cmd_verify() {
    _check_root
    command -v curl >/dev/null || { echo "curl required"; exit 1; }
    local ua='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    local filter="${1:-}" hit_any=0
    while IFS='|' read -r key url; do
        [[ -z "$url" ]] && continue
        platform="${key%%:*}"
        [[ -n "$filter" && "$platform" != "$filter" ]] && continue
        hit_any=1
        code=$(curl -sL -A "$ua" --max-time 10 -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
        case "$code" in
            404)    color=$GRN; verdict="available" ;;
            200)    color=$RED; verdict="SQUATTED — investigate" ;;
            3*)     color=$CYN; verdict="redirect" ;;
            5*|000) color=$YEL; verdict="api down?" ;;
            *)      color=$NC;  verdict="?" ;;
        esac
        printf "${color}%3s${NC}  %-32s  %s\n" "$code" "$key" "$verdict"
    done < <(_py verify-urls)
    if [[ "$hit_any" -eq 0 ]]; then
        printf "${YEL}No verify_urls entries%s${NC}\n" "${filter:+ matching $filter}"
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
    verify)     cmd_verify "${2:-}" ;;
    publish)    cmd_publish "${2:-}" "${3:-}" "${4:-}" ;;
    registry)   cat "$REGISTRY" ;;
    help|--help|-h) usage ;;
    *) echo "Unknown: $1"; usage; exit 1 ;;
esac
