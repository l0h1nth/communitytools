---
name: hackerone
description: HackerOne bug bounty automation - parses scope CSVs, deploys parallel pentesting agents per asset, validates PoCs, and generates platform-ready submission reports.
---

# HackerOne Bug Bounty

Automates: scope parsing → parallel testing per asset → **authoritative finding validation** → submission reports.

## Quick start

1. Input: HackerOne program URL or scope CSV.
2. Parse scope and program guidelines.
3. Delegate one `coordinator` agent per eligible asset (parallel).
4. Each coordinator runs the standard engagement flow (see `skills/coordination/SKILL.md`).
5. Run the **`validate-findings` workflow per asset** (authoritative submission gate). Generate HackerOne reports from the validated set ONLY — never submit a finding that is not `VALID`/`REPAIRED`.

## Scope CSV format

Expected columns:
- `identifier` — asset URL/domain.
- `asset_type` — URL, WILDCARD, API, CIDR.
- `eligible_for_submission` — must be `true`.
- `max_severity` — critical / high / medium / low.
- `instruction` — asset-specific notes.

Parse with `skills/hackerone/tools/csv_parser.py`. Filter for `eligible_for_submission=true`.

## Agent deployment

One coordinator per asset, delegated in parallel:

```text
Delegate to the custom Codex agent `coordinator`:
Read skills/coordination/SKILL.md first.
TARGET: <asset_url>
SCOPE: <program_guidelines>
OUTPUT_DIR: <asset output directory>
Return PHASE3_SUMMARY when complete.
```

10 assets → 10 parallel coordinators (~2-4 h vs 20-40 h sequential). Each coordinator follows `skills/coordination/SKILL.md` and `reference/role-matrix.md`.

## Finding validation (authoritative submission gate)

Every finding requires `poc.py` (executable exploit), `poc_output.txt` (timestamped execution proof), manual repro steps, and evidence (screenshots / HTTP captures / video). This is the input the validator consumes.

**After each asset's coordinator returns, the parent runs the `validate-findings` workflow for that asset and submits ONLY findings it marks `VALID` or `REPAIRED`:**

The parent Codex thread runs the validation workflow from
`workflows/validate-findings.js` for each returned asset, passing `output_dir`,
`target`, `business_tier`, `votes`, `repair`, and `strict`. It accepts
only `VALID` or `REPAIRED` verdicts and reads the result from
`{asset_output_dir}/artifacts/validated/` plus the validation report.

`validate-findings` is the authoritative gate because it directly preempts the most common HackerOne rejections: it verifies each CVE against **NVD + a recomputed CVSS base score (from the vector) + CISA KEV + the vendor advisory**, **runs (and repairs) every PoC** until it emits the evidence that proves the issue, **recomputes the risk/severity**, corroborates every claim against raw evidence, and kills false positives via **adversarial refutation**.

The parent thread is the only layer that runs this workflow. To avoid double work,
coordinators may treat their **interleaved per-finding validators** as a provisional
self-check; the standalone validation verdict is authoritative for submission. A
`REJECTED` finding is a false positive and never enters a submission, appendix, or count.

The HackerOne PoC contract is a superset of the standard finding contract (`skills/coordination/reference/validator-role.md`).

## Submission report format

Build each report from a validated finding only. Required sections per HackerOne standard:
1. Summary (2-3 sentences).
2. Severity (CVSS + business impact; v4.0 primary, v3.1 → v3.0 → v2.0 fallback) — use the score `validate-findings` recomputed from the vector and the risk bucket it assigned, not a hand-typed number.
3. Steps to Reproduce (numbered, clear) — mirror the validated `verification-script.py`.
4. Visual Evidence (from `evidence/validation/`).
5. Impact (realistic attack scenario).
6. Remediation (actionable fixes).

Validate report *format* with `skills/hackerone/tools/report_validator.py` (complements the finding validation).

## Output structure

Standard `OUTPUT_DIR` (`skills/coordination/reference/output-discipline.md`) plus a per-asset `reports/submissions/` containing the platform-ready markdown. `validate-findings` writes the verdicts under `artifacts/validated|false-positives/` and the asset `reports/validation-report.md`.

```
{OUTPUT_DIR}/
├── findings/
│   └── finding-NNN/evidence/validation/   # validate-findings proof packages
├── reports/
│   ├── submissions/                        # built ONLY from artifacts/validated/
│   │   ├── H1_CRITICAL_001.md
│   │   └── H1_HIGH_001.md
│   ├── validation-report.md                # validate-findings asset report
│   └── SUBMISSION_GUIDE.md
├── recon/
├── logs/
└── artifacts/
    ├── validated/          # {id}.json — submit these
    └── false-positives/    # {id}.json — never submit these
```

## Program selection

**High-value:** new programs (< 30 days), fast response (< 24 h), high bounties, large attack surface. **Avoid:** slow response (> 1 week), low bounties, restrictive scope.

## Submission checklist

- [ ] **`validate-findings` verdict = `VALID` or `REPAIRED`** (`artifacts/validated/{id}.json` exists). Never submit a `REJECTED` finding.
- [ ] CVSS **recomputed from the vector** (v4.0 primary; v3.1 → v3.0 → v2.0 fallback) and matching NVD when a CVE applies (`evidence/validation/cve-verification.md`).
- [ ] Working PoC with `poc_output.txt` (the validator re-ran/repaired it and confirmed the evidence token).
- [ ] Step-by-step reproduction.
- [ ] Visual evidence.
- [ ] Realistic impact (risk score/bucket from `evidence/validation/risk-assessment.md`).
- [ ] Remediation guidance.
- [ ] Sensitive data sanitized.
- [ ] Asset is `eligible_for_submission=true`.

## Common rejections (preempt)

| Rejection | Prevention |
|-----------|------------|
| Out of Scope | Verify `eligible_for_submission=true` and asset-type match |
| Cannot Reproduce | `validate-findings` re-runs (and repairs) the PoC 3× and requires a vuln-class evidence token — only reproducible findings pass the gate |
| Duplicate | Search disclosed reports before submission; submit quickly |
| Insufficient Impact | Document realistic attack scenario; `validate-findings` recomputes risk/severity so the rating is defensible |
| Incorrect severity / CVSS | `validate-findings` recomputes the base score from the vector and cross-checks NVD + KEV; any mismatch is flagged before you submit |

## Tools

- `skills/hackerone/tools/csv_parser.py` — parse HackerOne scope CSVs.
- **`validate-findings` workflow** — authoritative per-asset finding validation (NVD/CVSS-math/KEV/exploit-run/repair/risk/adversarial). The submission gate; run once per asset.
- `skills/hackerone/tools/report_validator.py` — validate report *format* completeness (the 6 submission sections). Complements `validate-findings` (which validates the *finding*); run it on each report built from a validated finding.
- `skills/coordination/SKILL.md` — coordinator scaffold.

## Usage

```bash
/hackerone <program_url_or_csv_path>
```
