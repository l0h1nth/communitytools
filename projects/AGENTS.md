# Project workspaces

Project directories are scoped working environments under the repository root. The
root [`AGENTS.md`](../AGENTS.md) is inherited automatically by Codex; this file adds
the project-level boundary.

Keep reusable skills, tools, formats, and instructions free of client-specific data.
Write live engagement artifacts only inside that engagement's `OUTPUT_DIR`. Read the
nearest project `AGENTS.md` when one exists, then select the smallest relevant skill set.

When a task is independent and read-heavy, ask Codex to delegate it to a named custom
agent. Keep writes coordinated in the main thread or in a single assigned executor.
