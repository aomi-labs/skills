# codex-marketplace.com — `aomi-build` (separate) submission

> **Manual step**: open [codex-marketplace.com](https://codex-marketplace.com) → Submit Plugin form, paste the field values below.
>
> **When to use this packet**: only after the bundle (`aomi`) submission has been processed. Submit this if codex-marketplace allows multiple submissions per repo OR if you want narrower discovery for the developer-tooling audience that doesn't care about on-chain transactions.
>
> **Structural caveat**: same as `aomi-transact` — legacy `aomi-build/` has `SKILL.md` at root rather than `skills/aomi-build/SKILL.md`. Codex's `skills` field in `.codex-plugin/plugin.json` is optional. If their validator requires the canonical layout, restructure before submitting.

---

## Form fields

### GitHub repository URL

```
https://github.com/aomi-labs/skills/tree/main/aomi-build
```

### Plugin name

```
aomi-build
```

### Plugin description

Use **Tier 2 short** (~400 chars):

```
Build new Aomi apps and plugins from API docs, OpenAPI/Swagger specs, SDK docs, runtime interfaces, or product requirements. aomi-build scaffolds production-ready Rust SDK crates (lib.rs, client.rs, tool.rs) with tool schemas, preambles, host-interop flows, and validation steps — turning a vendor's full API surface into AI-agent-callable tools. Same runtime that aomi-transact drives.
```

### Author

- **Name:** aomi-labs
- **URL:** https://aomi.dev

### Homepage

```
https://github.com/aomi-labs/skills/tree/main/aomi-build
```

### License

```
MIT
```

### Tags / keywords

```
aomi, sdk, scaffold, openapi, rust, code-generation, agent-tools, developer-tools
```

### Category

`Developer Tools` or `AI Agents` — whichever fits their taxonomy.

### Notes for reviewer

```
aomi-build is the developer-tooling skill from the Aomi bundle, submitted
separately for narrower discovery — surfaces under "OpenAPI", "scaffold",
"Rust SDK" search terms.

The skill takes API docs / OpenAPI/Swagger specs / SDK docs / product
requirements as input and generates production-ready Rust SDK crates that
plug into the Aomi runtime as new tool surfaces. Output: lib.rs (app
exports), client.rs (HTTP/RPC client), tool.rs (agent-callable tool
definitions), Cargo.toml, plus tool schemas, preambles, host-interop flows,
and validation steps.

Risk profile: risk_tier L1 (writes Rust source code, no runtime side
effects, no network access, no transaction signing). Full OWASP AST03
permission manifest in the SKILL.md frontmatter; per-control walkthrough in
SECURITY.md against AST01–AST10.

Independent scanner reports for this skill (live in the source repo at
.scanner-reports/aomi-build/):
  - Cisco AI Defense skill-scanner: SAFE (0 findings)
  - NMitchem/SkillScan: PASS — Risk 0.0/10
  - pors/skill-audit: PASS (0 errors / 2 doc-pattern WARNs)
  - Snyk agent-scan: pending (lower-priority L1 skill)

If you also accepted the `aomi` bundle submission, this is the same skill
inside that bundle, surfaced as a standalone listing for discoverability.
The bundle remains the canonical install for users who want both transact +
build.
```
