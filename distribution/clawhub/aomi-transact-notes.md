# ClawHub — update existing aomi-transact listing

Run from this repository root after signing into the owning account:

```bash
clawhub login
clawhub skill publish ./plugins/aomi/skills/transact \
  --slug aomi-transact \
  --name "Aomi Transact" \
  --version 0.14.2 \
  --changelog "Use the dedicated Agent and Pipeline MCP URLs." \
  --tags latest \
  --source-repo aomi-labs/skills \
  --source-ref main \
  --source-path plugins/aomi/skills/transact
```

Use the exact source commit with `--source-commit` when publishing. Confirm the
public latest version and served SKILL.md after the registry finishes review.
Do not overwrite the registry's published version in _registry.yaml beforehand.

## Listing copy

Use Aomi through the CLI or hosted MCP to prepare EVM transactions, review the
returned Commit and simulation results, and hand off authorized execution to
the user's signer.

Website: https://aomi.dev
Chat and sign-in: https://aomi.chat
Agent MCP: https://mcp.aomi.dev/
Pipeline MCP: https://mcp.aomi.dev/pipeline
CLI: npm install -g @aomi-labs/cli@latest
CLI production configuration: aomi config set-backend https://aomi.chat

The two MCP resources require separate OAuth authorization. Existing connections
to the retired origin must change URL and authorize again. Review the returned
Commit and simulation results before an explicitly authorized signing/submission
step. The TypeScript SDK is @aomi-labs/client; it is not the CLI package.
