# Anthropic — update existing Aomi listings

The community marketplace contains standalone aomi-transact and aomi-build
entries. Its GitHub repository is a read-only mirror; direct PRs are auto-closed.
Manage existing listings through https://claude.ai/directory/manage.

For submissions originally made in Claude Console, follow the official migration
instructions before creating a replacement listing. A submission without a
Withdraw button requires migration by Anthropic support; avoid duplicate listings.

Reference: https://claude.com/docs/directory/publish

## Source fields

- Repository: https://github.com/aomi-labs/skills
- Existing transaction plugin path: aomi-transact (version 0.14.1)
- Existing build plugin path: aomi-build (version 0.1.1)
- Combined bundle path, if migrating to a combined listing: plugins/aomi
- Author: Aomi Labs
- Homepage: https://aomi.dev
- License: MIT

Preserve each existing listing's source path when updating its version. The
transaction plugin and combined bundle include `.mcp.json` and remote MCP
references in their manifests; include these files in review.

## Description and connection details

Use Aomi through the CLI or hosted MCP to prepare EVM transactions, review
returned Commit artifacts and simulations, and hand off authorized execution
to the user's signer. The build skill scaffolds Rust integrations from API specs.

Website: https://aomi.dev
Chat and sign-in: https://aomi.chat
Agent MCP: https://aomi.chat/v1/agent/mcp
Pipeline MCP: https://aomi.chat/v1/pipeline/mcp
CLI: npm install -g @aomi-labs/cli@latest
CLI production configuration: aomi config set-backend https://aomi.chat

The two MCP resources require separate OAuth authorization. Existing connections
to the retired origin must change URL and authorize again. Review the returned
Commit and simulation results before an explicitly authorized signing/submission
step. The TypeScript SDK is @aomi-labs/client; it is not the CLI package.
