# Third-party Codex marketplace — update existing Aomi listing

Edit the existing listing through the owning publisher account.

- Source: https://github.com/aomi-labs/skills/tree/main/plugins/aomi
- Version: 0.14.2
- Author: Aomi Labs
- Homepage: https://aomi.dev
- License: MIT

## Description

Use Aomi through the CLI or hosted Agent and Pipeline MCP servers to prepare
EVM transactions, review Commit artifacts and simulations, and execute with
explicit user authorization. The Aomi bundle also includes aomi-build for
scaffolding Rust integrations from API specifications.

## Connection details

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

The bundle includes `.mcp.json`; preserve it when packaging or importing.
