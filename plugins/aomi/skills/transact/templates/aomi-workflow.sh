#!/usr/bin/env bash
# Read-only helpers. Source this file, then call aomi_detect before use.
# Uses only an explicitly installed aomi binary; never installs or auto-signs.
# USER_ADDR and AOMI_CHAIN_ID must be supplied for a new payment preparation.

# Check commands, not semver: standalone and embedded CLI versions differ.
aomi_detect() {
    command -v aomi >/dev/null 2>&1 || {
        echo 'aomi is missing; check public @aomi-labs/cli availability before installing.' >&2
        return 1
    }
    local capability help list_help
    help=$(aomi tx --help) || return 1
    for capability in export submit preflight; do
        case "$help" in
            *"$capability"*) ;;
            *) echo "Installed aomi lacks tx $capability." >&2; return 1 ;;
        esac
        aomi tx "$capability" --help >/dev/null 2>&1 || {
            echo "Installed aomi lacks tx $capability; a Commit-capable standalone CLI is required." >&2
            return 1
        }
    done
    list_help=$(aomi tx list --help) || {
        echo 'Installed aomi lacks tx list; recovery requires transaction listing.' >&2
        return 1
    }
    case "$list_help" in
        *--json*) ;;
        *) echo 'Installed aomi lacks tx list --json.' >&2; return 1 ;;
    esac
    aomi session resume --help >/dev/null 2>&1 || {
        echo 'Installed aomi lacks session resume.' >&2
        return 1
    }
}

# Read live token and gas balances for the wallets listed in a key-free intent file.
aomi_funding() {
    aomi tx preflight "${1:?payment intent file required}"
}

# Deliberately requires explicit wallet and chain, and only prepares a new task.
aomi_prepare() {
    : "${USER_ADDR:?set the approved operational sender}"
    : "${AOMI_CHAIN_ID:?set the explicit source chain ID}"
    aomi chat "${1:?exact approved payment intent required}" --new-session \
        --public-key "$USER_ADDR" --chain "$AOMI_CHAIN_ID"
}

# Refresh the existing session's durable Commits, including outstanding attempts.
aomi_pending() {
    aomi tx list --json
}

# Export one exact Commit for review. Output is not proof of payment.
aomi_review() {
    aomi tx export "${1:?full Commit ID required}" --format commit
}

aomi_resume() {
    aomi session resume "${1:?original local session ID required}" >/dev/null && aomi_pending
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    aomi_detect
fi
