# Transilience AI Community Security Tools

<div align="center">

[![Built by Transilience](https://img.shields.io/badge/Built%20by-Transilience.ai-4A90D9)](https://www.transilience.ai)
[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://choosealicense.com/licenses/mit/)
[![GitHub stars](https://img.shields.io/github/stars/transilienceai/communitytools)](https://github.com/transilienceai/communitytools/stargazers)
[![OpenAI Codex](https://img.shields.io/badge/Powered%20by-OpenAI%20Codex-blue)](https://developers.openai.com/codex/)

**Open-source Codex skills and agents for AI-powered penetration testing, bug bounty hunting, AI threat testing, and security reconnaissance — from the team at [Transilience.ai](https://www.transilience.ai)**

[Quick Start](#-quick-start) | [Skills](#-skills) | [Architecture](#-architecture) | [Contributing](CONTRIBUTING.md) | [Website](https://www.transilience.ai)

</div>

---

## Announcement

**Practice Makes Perfect: Teaching an AI to Hack by Learning from Its Mistakes** (March 2026)

We built an autonomous pentesting agent that scores **100% (104/104)** on a published CTF benchmark suite — using only structured markdown skill files, no fine-tuning. Starting from a bare 89.4% baseline, we ran a simple loop roughly 15 times: run the benchmarks, find a failure, diagnose the missing technique, write it into a skill file, and run again. The same skills transfer cross-model: Claude Sonnet 4.6 reaches 96.2% and Claude Haiku 4.5 reaches 62.5%. This repository contains the full skill set described in the paper.

**[Read the paper](papers/practice-makes-perfect.pdf)**

---

## Overview

**Transilience AI Community Tools** is a Codex-compatible security testing suite — **43 skills** and **3 tool integrations** that cover the full penetration testing lifecycle from reconnaissance to reporting. Agent roles (coordinator, executor, skeptic, validator) are defined in `skills/coordination/` and wired to Codex custom agents in `.codex/agents/`.

### Why Choose Transilience Community Tools?

- **AI-Powered Automation** — Codex coordinates intelligent security testing workflows
- **Complete OWASP Coverage** — 100% OWASP Top 10 + OWASP LLM Top 10
- **Professional Reporting** — CVSS 4.0 (primary; v3.1/v3.0/v2.0 fallback), CWE, MITRE ATT&CK, Transilience-branded PDF reports
- **Playwright Integration** — Browser automation for client-side vulnerability testing
- **Payload-Enriched References** — 160+ reference files with inline PayloadsAllTheThings techniques
- **Open Source** — MIT licensed for commercial and personal use

---

## Prerequisites

### Local Setup

- **Codex CLI** — [Install Codex](https://developers.openai.com/codex/cli/)
- **Playwright** — Required for client-side testing, HackTheBox/HackerOne automation, and browser-based evidence capture. Install via: `npm install -g @playwright/mcp && npx playwright install chromium`
- **Python 3** — Required for tools (`env-reader.py`, `nvd-lookup.py`, `slack-send.py`)
- **Kali Linux tools** (optional) — nmap, gobuster, ffuf, sqlmap, testssl, etc. Only needed for network/infrastructure testing

### Docker Setup (Recommended)

A single script spins up a Kali Linux container with Codex, Playwright (headed via Xvfb), and all Kali security tools pre-installed:

```bash
bash scripts/kali-codex-setup.sh projects/pentest
```

This builds a Docker image with Kali Rolling + Node.js + Codex + Playwright + Chromium, mounts the project workspace, and launches Codex in the project. Use `--rebuild` to force a fresh image build.

---

## Quick Start

### 1. Clone and enter the project

```bash
git clone https://github.com/transilienceai/communitytools.git
cd communitytools/projects/pentest
```

### 2. Open Codex and run a skill

```bash
codex     # Launch Codex from the current project directory
```

Then browse skills with `/skills` or mention one explicitly with `$`:

```text
Run an authorized pentest against https://target.com using $pentest-engagement
$hackthebox                          # HackTheBox challenge automation
$hackerone                           # Bug bounty workflow
$techstack-identification            # Passive tech stack recon
$reconnaissance target.com           # Attack surface mapping
$source-code-scanning ./app          # Static code analysis
```

---

## Using Codex Skills

### How skill discovery works

Codex reads the nearest `AGENTS.md` files before working. This repository provides:

- `AGENTS.md` — repository-wide safety, scope, and workflow instructions.
- `projects/*/AGENTS.md` — project-specific operating rules.
- `.agents/skills/` — Codex discovery links.
- `skills/` — the canonical skill source; edit this directory, not the symlinked mirror.
- `.codex/agents/` — named coordinator, executor, skeptic, and validator agents.

Start Codex from the repository root or from a project directory:

```bash
codex --cd projects/pentest
```

Codex walks from the Git root to the current directory, loads layered `AGENTS.md`
files, and discovers the repository skills. Start a new Codex session after changing
instructions or adding a skill.

### Select the right skill

Use `/skills` to browse available skills, or mention a skill explicitly:

```text
$reconnaissance example.com
$api-security Review the authorized API surface in ./api/
$source-code-scanning Audit ./src for security issues and dependency CVEs
$cve-poc-generator Research CVE-YYYY-NNNN and produce a safe PoC report
```

For a complete authorized engagement, start with the orchestration skill:

```text
Use $pentest-engagement for this authorized scope.
Read the scope file, create the required OUTPUT_DIR, and stop if authorization
or the non-destructive rules are unclear.
```

Use the smallest relevant skill set. A skill's `SKILL.md` is the entry point; read
the linked `reference/` files only when the selected workflow requires them.

### Use the custom agents

The coordination workflow uses the named agents in `.codex/agents/`. Ask Codex to
delegate bounded work when the task benefits from independent context:

```text
Use $coordination for this authorized target.
Delegate one coordinator per scope unit, keep executors bounded,
and require a blind validator before accepting any finding.
```

The coordinator maintains engagement bookkeeping and delegates to:

| Agent | Use |
|-------|-----|
| `coordinator` | Owns one target, scope, attack chain, and output directory |
| `executor` | Performs one bounded reconnaissance or validation mission |
| `skeptic` | Challenges the current theory without seeing private reasoning |
| `validator` | Blindly verifies findings and evidence |

### Use the local MCP server

The optional Transilience vulnerability server is configured in
`.codex/config.toml`. Install its dependencies, export the API key, then inspect
the connection with `/mcp`:

```bash
cd mcp/transilience-vuln
python -m venv .venv
source .venv/bin/activate
pip install -e .
cd ../..

export TRANSILIENCE_API_KEY="your-key"
codex
```

Ask Codex: `What MCP tools are available for CVE enrichment?`

Keep credentials in environment variables. Do not place API keys in
`AGENTS.md`, skill files, `.codex/config.toml`, or reports.

### Create or update a skill

Create the canonical skill directory and entry point:

```text
skills/my-skill/SKILL.md
```

The entry point must contain YAML frontmatter with `name` and `description`.
Use `$skill-update` when creating or improving a skill:

```text
$skill-update
Create a skill for <workflow>. Keep the entry point concise,
link detailed material from reference/, and run the skill checks.
```

Validate the repository wiring after structural changes:

```bash
python3 scripts/test_codex_integration.py
python3 scripts/test_skill_linter.py
```

### Troubleshooting

- **Skill missing from `/skills`:** start Codex from this repository or a child
  project directory, confirm `.agents/skills/<name>` points into `skills/<name>`,
  and start a new session.
- **Project rules missing:** run `codex --cd <project>` and check the nearest
  `AGENTS.md`.
- **MCP tools missing:** run `/mcp`, confirm dependencies are installed, and
  verify `TRANSILIENCE_API_KEY` is exported before launching Codex.
- **Delegation unavailable:** confirm the named files in `.codex/agents/` exist
  and use a new Codex session after changing them.

Official references: [Codex CLI](https://developers.openai.com/codex/cli/),
[Skills](https://developers.openai.com/codex/skills/),
[AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md), and
[MCP](https://learn.chatgpt.com/docs/extend/mcp).

---

## Skills

All canonical skill and tool definitions live at the **repo root** (`skills/`, `tools/`). Each project under `projects/` symlinks only the ones it needs — see [Repository Structure](#repository-structure) for details.

Agent roles (coordinator, executor, skeptic, validator) are defined in `skills/coordination/` and exposed as Codex custom agents in `.codex/agents/`. Ask Codex to delegate bounded work to them in parallel.

### Selected Skills by Category (26 of 43)

#### Vulnerability Testing (10)

| Skill | Coverage |
|-------|----------|
| `$injection` | SQL, NoSQL, OS Command, SSTI, XXE, LDAP/XPath |
| `$client-side` | XSS (Reflected/Stored/DOM), CSRF, Clickjacking, CORS, Prototype Pollution |
| `$server-side` | SSRF, HTTP Smuggling, Path Traversal, File Upload, Deserialization, Host Header |
| `$authentication` | Auth Bypass, JWT, OAuth, Password Attacks, 2FA Bypass, CAPTCHA Bypass |
| `$api-security` | GraphQL, REST API, WebSockets, Web LLM |
| `$web-app-logic` | Business Logic, Race Conditions, Access Control, Cache Poisoning/Deception, IDOR |
| `$cloud-containers` | AWS, Azure, GCP, Docker, Kubernetes |
| `$system` | Active Directory, Privilege Escalation (Linux/Windows), Exploit Development |
| `$infrastructure` | Port Scanning, DNS, MITM, VLAN Hopping, IPv6, SMB/NetBIOS |
| `$social-engineering` | Phishing, Pretexting, Vishing, Physical Security |

#### Reconnaissance (3)

| Skill | Purpose |
|-------|---------|
| `$reconnaissance` | Subdomain discovery, port scanning, endpoint enumeration, API discovery, attack surface mapping |
| `$osint` | Repository enumeration, secret scanning, git history analysis, employee footprint |
| `$techstack-identification` | Passive tech stack inference across 17 intelligence domains |

#### Specialized (5)

| Skill | Purpose |
|-------|---------|
| `$ai-threat-testing` | OWASP LLM Top 10 — prompt injection, model extraction, data poisoning, supply chain |
| `$blockchain-security` | Smart contract security, EVM storage, delegatecall, CREATE/CREATE2, DeFi exploits |
| `$cve-poc-generator` | CVE research, NVD lookup, safe Python PoC generation, vulnerability reports |
| `$dfir` | Digital forensics, incident response, Windows event logs, PCAP analysis, AD attack detection |
| `$source-code-scanning` | SAST — OWASP Top 10, CWE Top 25, dependency CVEs, hardcoded secrets |

#### Platform Integrations (2)

| Skill | Purpose |
|-------|---------|
| `$hackerone` | Scope CSV parsing, parallel asset testing, PoC validation, platform-ready submissions |
| `$hackthebox` | Playwright-based login, challenge browsing, VPN management, automated solving |

#### Tooling (6)

| Skill | Purpose |
|-------|---------|
| `$essential-tools` | Burp Suite, Playwright automation, methodology, reporting standards |
| `$patt-fetcher` | On-demand payload extraction from PayloadsAllTheThings |
| `$script-generator` | Optimized, syntax-validated script generation |
| `formats/transilience-report-style` | Transilience-branded PDF report generation (ReportLab) |
| `$github-workflow` | Git branching, commits, PRs, issues, code review |
| `$skill-update` | Skill scaffolding, validation, GitHub workflow automation |

### Tool Integrations (3)

| Tool | Purpose |
|------|---------|
| **Playwright** | Browser automation for client-side testing via MCP |
| **Kali Linux Tools** | nmap, masscan, nikto, gobuster, ffuf, sqlmap, testssl, and more |
| **NVD / CVE Risk Score** | Auto-invoked CVE lookup (`$cve-risk-score`) — CVSS score, severity, CWE from NVD |

### MCP Servers

Local Model Context Protocol servers expose Transilience APIs to MCP-capable clients. Codex reads the project-scoped configuration in `.codex/config.toml`; each server is self-contained under `mcp/<name>/` with its own `pyproject.toml` and install instructions.

| Server | Purpose |
|--------|---------|
| [`mcp/transilience-vuln`](./mcp/transilience-vuln) | Single-CVE and bulk CVE enrichment (CVSS, EPSS, KEV, impact taxonomy, vendor advisories) via the Transilience Vulnerability API. |

---

## Architecture

The suite uses a **skills-only** architecture with canonical definitions at the repo root, symlinked into isolated project environments:

- **Skills** (`skills/` at root, symlinked into `.agents/skills/`) — Codex-discoverable workflows. Each skill contains a `SKILL.md` definition and a `reference/` directory with attack techniques, cheat sheets, payloads, and role prompts.
- **Coordination** (`skills/coordination/`) — Defines the coordinator, executor, skeptic, and validator contracts used by the custom agents in `.codex/agents/`.
- **Tools** (`tools/` at root) — Utility scripts for environment reading, integrations, deterministic gates, and report generation.

### Multi-Agent Execution Flow

```mermaid
sequenceDiagram
    participant User
    participant Coord as Coordinator (inline)
    participant Roles as Role Definitions (skills/coordination/)
    participant Agents as Spawned Agents
    participant Output as Standardized Outputs

    User->>Coord: Pentest https://target.com
    Coord->>Roles: Read skills/coordination/SKILL.md
    Coord->>Coord: Execute coordinator workflow inline

    Coord->>Roles: Read skills/coordination/reference/executor-role.md
    Coord->>Agents: Codex executor subagent(prompt + chain + skills) × N
    Note over Agents: SQL/XSS/SSRF/JWT/OAuth/SSTI/XXE...
    Agents-->>Output: findings/*.json + evidence/*.png

    Coord->>Roles: Read skills/coordination/reference/validator-role.md
    Coord->>Agents: Codex validator subagent(prompt + evidence ONLY) × N
    Note over Agents: Blind review — no attack chain context
    Agents-->>Output: validated/*.json

    Coord->>Output: Phase 6: Generate reports
    Output-->>User: Executive + technical reports
```

### Repository Structure

```
communitytools/
├── AGENTS.md                        # Codex project instructions
├── .codex-plugin/plugin.json        # Codex plugin manifest
├── .codex/config.toml               # Project MCP + subagent configuration
├── .codex/agents/                    # Coordinator/executor/skeptic/validator agents
├── .agents/skills/                   # Codex discovery links to canonical skills/
├── papers/                          # Research papers
├── benchmarks/                      # XBOW benchmark runner
│
├── skills/                          # ← Canonical skill definitions (source of truth)
│   ├── coordination/               # ← Agent roles + coordination reference
│   │   ├── SKILL.md                # Coordinator logic (entry point)
│   │   └── reference/
│   │       ├── executor-role.md    # Executor role prompt
│   │       ├── validator-role.md   # Validator role prompt (blind review)
│   │       ├── context-injection.md # What context each role receives
│   │       ├── ATTACK_INDEX.md     # 53 attack types mapped to skills
│   │       ├── OUTPUT_STRUCTURE.md # Engagement output directory spec
│   │       ├── VALIDATION.md       # 5-check finding validation framework
│   │       ├── GIT_CONVENTIONS.md  # Branch/commit/PR standards
│   │       └── PATT_STANDARD.md    # PayloadsAllTheThings integration
│   ├── injection/
│   │   ├── SKILL.md
│   │   └── reference/
│   ├── reconnaissance/
│   ├── server-side/
│   └── ...                          # 43 skill directories total
│
├── tools/                           # ← Canonical tool integrations (source of truth)
│   ├── env-reader.py
│   └── slack-send.py
│
└── projects/                        # ← Isolated project environments
    └── pentest/
        └── AGENTS.md                # Project-specific Codex instructions
```

### Why This Structure?

**Canonical root directories** (`skills/`, `tools/`) hold the single source of truth for all definitions. No duplication, no drift.

**Project directories** (`projects/`) are isolated environments designed to be run independently with `codex` from within the project folder. Codex walks from the current directory to the repository root, loads layered `AGENTS.md` instructions, and discovers the root `.agents/skills/` links.

This design gives you:

- **Isolation** — Each project is a self-contained working directory. Run `codex` from `projects/pentest/` and it inherits the root and project-specific instructions.
- **Single source of truth** — Edit a skill once in `skills/`, and every project that symlinks it gets the update immediately.
- **Progressive disclosure** — Codex loads skill descriptions first and reads full `SKILL.md` files only when a workflow is selected.
- **Codex compatibility** — Codex scans `.agents/skills/` and follows symlinked skill folders.

**Adding a new project:**

```bash
mkdir -p projects/myproject/.agents/skills
cd projects/myproject/.agents/skills

# Symlink only the skills this project needs
ln -s ../../../../skills/injection injection
# Coordination is a skill like any other — symlink if needed
ln -s ../../../../skills/coordination coordination
ln -s ../../../../skills/reconnaissance reconnaissance
# ... add more as needed

# Keep reusable scripts in the repository-level tools/ directory.
```

---

## Contributing

We welcome contributions from the security community!

**Read the full guide:** [CONTRIBUTING.md](CONTRIBUTING.md)

**Quick path using Skill Update:**
```text
$skill-update
# Select: CREATE → provide details → automated GitHub workflow
# Handles: issue creation, branch, skill generation, validation, commit, PR
```

---

## Security & Legal

**IMPORTANT: These tools are designed for authorized security testing ONLY.**

**Authorized & Legal Use:**
- Penetration testing with written authorization
- Bug bounty programs within scope
- Security research on your own systems
- CTF competitions and training environments
- Educational purposes with proper permissions

**Prohibited & Illegal Use:**
- Unauthorized testing of any systems
- Malicious exploitation of vulnerabilities
- Data theft or system disruption
- Any use that violates local or international laws

**Users are solely responsible for compliance with all applicable laws and regulations.**

### Responsible Disclosure

If you discover a vulnerability using these tools:
1. Do not exploit beyond proof-of-concept
2. Report immediately to the vendor/organization
3. Follow responsible disclosure timelines (typically 90 days)
4. Document thoroughly for remediation

---

## Community & Support

- [GitHub Discussions](https://github.com/transilienceai/communitytools/discussions) — Ask questions, share ideas
- [GitHub Issues](https://github.com/transilienceai/communitytools/issues) — Report bugs, request features
- [Transilience.ai](https://www.transilience.ai) — See what else we're building
- [LinkedIn](https://linkedin.com/company/transilienceai) — Follow our work
- [Email](mailto:contact@transilience.ai) — Get in touch

---

## Project Stats

| Category | Count |
|----------|-------|
| **Skills** | 43 |
| **Role Prompts** | 4 (coordinator, executor, skeptic, validator) |
| **Tool Integrations** | 3 |
| **Attack Types** | 53 |
| **Reference Files** | 160+ |

**Coverage:**
- OWASP Top 10 (2021) — 100%
- OWASP LLM Top 10 (2025) — 100%
- SANS Top 25 CWE — 90%+
- MITRE ATT&CK TTPs — mapped for all findings

---

## License

MIT License — Copyright (c) 2026 Transilience AI. See [LICENSE](LICENSE) for details.

---

## Contributors

<a href="https://github.com/transilienceai/communitytools/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=transilienceai/communitytools" />
</a>

---

<div align="center">

**Built by [Transilience AI](https://www.transilience.ai)**

We build AI-driven cloud security and compliance automation. These open-source tools reflect how we think about security — if you're curious about the platform behind them, [take a look](https://www.transilience.ai).

[![Star this repository](https://img.shields.io/badge/Star%20this%20repo-yellow?style=for-the-badge)](https://github.com/transilienceai/communitytools)

[Website](https://www.transilience.ai) | [Issues](https://github.com/transilienceai/communitytools/issues) | [Discussions](https://github.com/transilienceai/communitytools/discussions)

`codex` `ai-security` `penetration-testing` `bug-bounty` `owasp` `llm-security` `ai-threat-testing` `security-automation` `ethical-hacking` `cybersecurity` `appsec` `web-security` `hackerone` `hackthebox` `multi-agent`

</div>
