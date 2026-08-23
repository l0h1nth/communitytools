# Transilience Community Security Tools

This repository is Codex-native. Codex loads this file before work and discovers the
repository skills through `.agents/skills/`. The canonical content remains in `skills/`;
the `.agents/skills/` entries are symlinks so there is one source of truth.

## Operating boundary

Use these workflows only for systems the operator owns or has explicit authorization to
test: scoped penetration tests, bug-bounty assets, CTFs, and defensive research. Keep
testing non-destructive, respect the declared scope, and stop when authorization or
evidence is insufficient. Never turn a hypothesis into a finding without reproducible
evidence and an independent validation pass.

## Skill selection

1. Read [`skills/INDEX.md`](skills/INDEX.md) to route the request.
2. Select one or two matching skills and load their `SKILL.md` files through Codex's
   skill selector (`$skill-name`) or by reading the files directly.
3. Read only the relevant `reference/` material for the current target or technique.
4. Use repository tools from `tools/` and keep engagement artifacts inside the declared
   `OUTPUT_DIR`.

Do not load the entire skill library into one prompt. Do not inject a navigation
`SKILL.md` into an executor when a specific reference file is sufficient.

## Coordination and delegation

The engagement roles are available as Codex custom agents in `.codex/agents/`:

| Role | Codex agent | Contract |
|---|---|---|
| Coordinator | `coordinator` | `skills/coordination/SKILL.md` |
| Executor | `executor` | `skills/coordination/reference/executor-role.md` |
| Skeptic | `skeptic` | `skills/coordination/reference/skeptic-role.md` |
| Validator | `validator` | `skills/coordination/reference/validator-role.md` |

Delegate independent work in parallel when useful, but keep one coordinator per target,
no more than two executors per batch, and a fresh blind validator for each cure round.
The coordinator must maintain `attack-chain.md` and `experiments.md` before delegation.

## Cross-cutting rules

- Load credentials with `python3 tools/env-reader.py`; do not print or inline secrets.
- On every CVE ID, run `python3 tools/nvd-lookup.py <CVE-ID>` before relying on its score.
- Store findings, evidence, logs, and reports under `OUTPUT_DIR`, never in the reusable
  skill or repository root.
- Prefer deterministic tools and explicit evidence chains over speculative automation.
- Review generated reports for client data and secrets before committing or sharing them.

## Codex integration

- `.codex/config.toml` enables the optional local `transilience_vuln` MCP server and
  bounded subagent concurrency. Set `TRANSILIENCE_API_KEY` in the environment when
  CVE enrichment through that server is needed.
- Install the repository plugin from `.codex-plugin/plugin.json` when you want to use
  the skill set outside this checkout. The plugin is skills-only; local MCP configuration
  remains project-scoped so credentials are never packaged.
- Codex commands use `$skill-name`, `/skills`, `/mcp`, and `/agent`. The Codex path
  does not depend on client-specific slash-command or hook conventions.
