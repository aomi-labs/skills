#!/usr/bin/env bash
#
# quick-scaffold.sh — End-to-end aomi-apps app scaffold helper.
#
# Wraps `cargo run -p xtask -- new-app` with the surrounding workflow:
#   1. Verifies the aomi-apps checkout is reachable
#   2. Creates a new app crate via xtask
#   3. Tracks the new Cargo.toml so xtask discovery picks it up
#   4. Runs an initial cargo build for an immediate compile signal
#   5. Optionally runs the full xtask build-aomi after tracking
#
# Usage:
#   AOMI_APPS=/path/to/aomi-apps ./quick-scaffold.sh <app-name> [--build]
#
# Or from inside the aomi-apps repo:
#   ./aomi-build/templates/quick-scaffold.sh <app-name> [--build]

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

APP_NAME="${1:?usage: quick-scaffold.sh <app-name> [--build]}"
shift || true

# Detect aomi-apps location: AOMI_APPS env var, current dir, or ../aomi-apps
if [ -n "${AOMI_APPS:-}" ]; then
    REPO_ROOT="$AOMI_APPS"
elif [ -f Cargo.toml ] && grep -q 'aomi-sdk' Cargo.toml 2>/dev/null; then
    REPO_ROOT="$(pwd)"
elif [ -d ../aomi-apps ] && [ -f ../aomi-apps/Cargo.toml ]; then
    REPO_ROOT="$(cd ../aomi-apps && pwd)"
else
    echo "[quick-scaffold] cannot locate aomi-apps repo." >&2
    echo "[quick-scaffold] set AOMI_APPS=/path/to/aomi-apps or run from inside the repo." >&2
    exit 2
fi

if [ ! -d "$REPO_ROOT/sdk" ] || [ ! -d "$REPO_ROOT/apps" ]; then
    echo "[quick-scaffold] $REPO_ROOT does not look like an aomi-apps checkout (missing sdk/ or apps/)." >&2
    exit 2
fi

# Validate app name: lowercase, hyphens, no special chars
case "$APP_NAME" in
    *[!a-z0-9-]*)
        echo "[quick-scaffold] app name must be lowercase letters, digits, and hyphens only: $APP_NAME" >&2
        exit 2
        ;;
esac

if [ -d "$REPO_ROOT/apps/$APP_NAME" ]; then
    echo "[quick-scaffold] apps/$APP_NAME already exists — refusing to overwrite." >&2
    exit 2
fi

# ============================================================================
# Pre-flight: SDK version + git status
# ============================================================================

SDK_VERSION=$(grep -E '^version\s*=' "$REPO_ROOT/sdk/Cargo.toml" | head -1 | sed -E 's/.*"(.*)".*/\1/')
echo "[quick-scaffold] aomi-apps:    $REPO_ROOT"
echo "[quick-scaffold] aomi-sdk:     $SDK_VERSION"
echo "[quick-scaffold] new app:      $APP_NAME"
echo

if ! git -C "$REPO_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    echo "[quick-scaffold] WARNING: $REPO_ROOT is not a git repo. xtask discovery uses 'git ls-files'" >&2
    echo "[quick-scaffold]          and may not find your new app even after tracking." >&2
fi

# ============================================================================
# Step 1: scaffold via xtask
# ============================================================================

echo "[quick-scaffold] step 1/4: scaffolding via xtask new-app..."
(
    cd "$REPO_ROOT"
    cargo run -p xtask -- new-app "$APP_NAME"
)
echo

# ============================================================================
# Step 2: track Cargo.toml so build-aomi discovers it
# ============================================================================

echo "[quick-scaffold] step 2/4: staging the new app's Cargo.toml..."
git -C "$REPO_ROOT" add "apps/$APP_NAME/Cargo.toml" 2>&1 || {
    echo "[quick-scaffold] WARNING: could not stage Cargo.toml. Run manually:" >&2
    echo "  git -C $REPO_ROOT add apps/$APP_NAME/Cargo.toml" >&2
}
echo

# ============================================================================
# Step 3: initial compile check (works on untracked apps too)
# ============================================================================

echo "[quick-scaffold] step 3/4: running cargo build for compile signal..."
(
    cd "$REPO_ROOT"
    cargo build --manifest-path "apps/$APP_NAME/Cargo.toml"
)
echo

# ============================================================================
# Step 4: optional full xtask build
# ============================================================================

DO_BUILD=0
for arg in "$@"; do
    case "$arg" in
        --build) DO_BUILD=1 ;;
    esac
done

if [ "$DO_BUILD" = "1" ]; then
    echo "[quick-scaffold] step 4/4: running xtask build-aomi --app $APP_NAME..."
    (
        cd "$REPO_ROOT"
        cargo run -p xtask -- build-aomi --app "$APP_NAME"
    )
else
    echo "[quick-scaffold] step 4/4: skipping xtask build-aomi (pass --build to run it)."
fi
echo

# ============================================================================
# Next steps
# ============================================================================

cat <<EOF
[quick-scaffold] done.

Next steps:
  1. Edit apps/$APP_NAME/src/lib.rs   — write the PREAMBLE for your app
  2. Edit apps/$APP_NAME/src/client.rs — define the App struct, HTTP client, auth, models
  3. Edit apps/$APP_NAME/src/tool.rs   — implement DynAomiTool for each user-facing tool

Reference docs:
  - sdk/examples/app-template-http  — canonical HTTP-API shape
  - sdk/examples/hello-app           — async tools and cancellation
  - apps/binance, apps/oneinch       — real-world references
  - docs/host-interop.md             — host tool contract for execution apps
  - docs/sdk-version-compatibility.md — exact-match SDK version gate

Build loop:
  cargo build --manifest-path apps/$APP_NAME/Cargo.toml          # quick compile check
  cargo run -p xtask -- build-aomi --app $APP_NAME               # full plugin build

Test loop:
  cargo test -p $APP_NAME

Commit when ready:
  git add apps/$APP_NAME/
  git commit -m "feat: add $APP_NAME app"
EOF
