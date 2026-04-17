# Build Plugin

This example shows how to use Aomi to build an app or plugin from docs, specs, or repository notes.

## When to use this example

Use this flow when the user wants to:

- scaffold an Aomi app from API docs
- turn a runtime interface into a client
- build an integration plugin
- translate product requirements into code structure

## Prerequisites

- A real source of truth such as API docs, SDK docs, or a runnable repo
- A clear target surface such as REST, JSON-RPC, GraphQL, CLI, or a local service
- The smallest useful tool surface identified up front

## Flow

1. Identify the actual executable target.
2. Decide whether the app is read-only, execution-oriented, or mixed.
3. Map the user intent into a small tool set.
4. Scaffold the app or plugin.
5. Normalize inputs and outputs.
6. Validate against one representative workflow.

## Example

```bash
aomi chat "Build an Aomi plugin from these OpenAPI docs" --new-session
```

The builder workflow should then:

- identify the callable surface
- extract the core entities
- map user intents to tools
- produce typed inputs and stable outputs
- keep `lib.rs`, `client.rs`, and `tool.rs` cleanly separated

## What good output looks like

- the tool surface matches user intent
- the client normalizes upstream quirks
- the preamble explains the workflow
- the output is ready for a real integration target

## Notes

- Do not invent endpoints that the source does not publish.
- Prefer the real runtime or service over docs-only summaries.
- Keep the first pass small and useful.
