"""Installable skill mirrors and the read-only recovery template contract."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
TEMPLATE = ROOT / "aomi-transact/templates/aomi-workflow.sh"


class TransactWorkflow(unittest.TestCase):
    def test_plugin_contains_exact_canonical_skill(self):
        canonical = ROOT / "aomi-transact"
        mirror = ROOT / "plugins/aomi/skills/transact"
        source_files = {p.relative_to(canonical) for p in canonical.rglob("*") if p.is_file() and not any(part.startswith(".") for part in p.relative_to(canonical).parts)}
        mirror_files = {p.relative_to(mirror) for p in mirror.rglob("*") if p.is_file() and not any(part.startswith(".") for part in p.relative_to(mirror).parts)}
        self.assertEqual(source_files, mirror_files)
        for path in source_files:
            self.assertEqual((canonical / path).read_bytes(), (mirror / path).read_bytes(), str(path))

    def run_helper(self, script, missing="", chain="1"):
        with tempfile.TemporaryDirectory() as directory:
            directory = Path(directory)
            fake = directory / "aomi"
            fake.write_text('''#!/usr/bin/env bash
printf '%s\\n' "$*" >> "$CALLS"
if [ "$*" = "tx --help" ]; then echo "export submit preflight status"; fi
if [ "$*" = "tx $MISSING --help" ]; then exit 1; fi
if [ "${1:-}" = "tx" ] && [ "${2:-}" = "sign" ]; then exit 99; fi
''')
            fake.chmod(0o755)
            log = directory / "calls"
            env = {**os.environ, "PATH": str(directory) + os.pathsep + os.environ["PATH"], "CALLS": str(log), "MISSING": missing, "USER_ADDR": "approved-sender"}
            env.pop("AOMI_CHAIN_ID", None)
            if chain:
                env["AOMI_CHAIN_ID"] = chain
            result = subprocess.run(["bash", "-c", 'source "$1"; ' + script, "workflow-test", str(TEMPLATE)], env=env, text=True, capture_output=True)
            return result, log.read_text() if log.exists() else ""

    def test_recovery_uses_exact_commit_without_signing_or_installing(self):
        result, calls = self.run_helper('aomi_detect && aomi_resume 43 && aomi_review payment-123 && aomi_status payment-123 "intent with spaces.json"')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("session resume 43\ntx list --json", calls)
        self.assertIn("tx export payment-123 --format commit", calls)
        self.assertIn("tx status payment-123 --payment intent with spaces.json", calls)
        self.assertNotIn("tx sign", calls)

    def test_missing_capability_stops_before_preparing(self):
        result, calls = self.run_helper('aomi_detect && aomi_prepare "approved intent"', missing="status")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("lacks tx status", result.stderr)
        self.assertNotIn("chat ", calls)

    def test_source_chain_is_required_instead_of_defaulting_to_mainnet(self):
        result, calls = self.run_helper('aomi_prepare "approved intent"', chain="")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("explicit source chain ID", result.stderr)
        self.assertEqual(calls, "")


if __name__ == "__main__":
    unittest.main()
