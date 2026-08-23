# Codex delegation recipes

Delegation contracts for the coordinator. Codex exposes the named custom agents from
`.codex/agents/`; ask Codex to delegate a bounded prompt to the named agent and wait for
the result before integrating it. The coordinator owns the queue and bookkeeping.

## Common context

Every worker prompt should include only the fields needed for its role:

```text
OUTPUT_DIR: <absolute engagement directory>
TARGET: <one target or asset>
OBJECTIVE: <one bounded mission>
MISSION_ID: m-<number>
EXPERIMENT_ID: E-<number>
```

The coordinator may include the current `attack-chain.md` and `experiments.md` when the
role contract permits them. Read the role file and the one or two specific technique
references first; do not mount the entire skill library into a worker prompt.

## Coordinator

The parent thread creates the engagement tree and delegates one `coordinator` agent per
target. The delegation prompt must tell the coordinator to perform this first action:

1. Create `attack-chain.md` and `experiments.md` in `OUTPUT_DIR`.
2. Run the preflight gate in `preflight-checklist.md`.
3. Delegate executors only after the bookkeeping files exist.

Keep a strict one-to-one relationship between coordinator and target. Queue additional
targets instead of spawning an unbounded pool.

## Executor: explore

Delegate to `executor` with:

```text
ROLE: explore
MISSION_ID: m-<number>
EXPERIMENT_ID: E-<number>
OBJECTIVE: <recon or source-analysis objective>
OUTPUT_DIR: <path>
CHAIN_CONTEXT: <current chain, if allowed>
EXPERIMENTS: <current experiment log, if allowed>
SKILL_FILES: <one or two specific reference paths>
```

Explore workers observe and document; they do not create a finding or write to
`findings/`.

## Executor: exploit

Delegate to `executor` with the confirmed theory, one scenario reference, the target,
and the exact evidence contract. Require a reproducible proof, raw request/response or
equivalent evidence, and a clear limitation statement. Do not ask an exploit worker to
load the full `SKILL.md` when the scenario reference is enough.

## Skeptic

At experiments 5, 15, and 25, delegate to `skeptic` with only:

```text
OBJECTIVE: <current goal>
OUTPUT_DIR: <path>
EXPERIMENT_COUNT: <N>
EXPERIMENTS: <experiment history>
RECON_LISTING: <sanitized listing>
```

The skeptic must not receive `attack-chain.md`, executor reasoning, skill files, or the
research brief. It returns alternative hypotheses and disconfirming tests without
modifying the engagement.

## Validator: finding

Immediately after a candidate finding is materialized, delegate a fresh `validator`:

```text
CLASS: finding
FINDING_ID: <id>
FINDING_DIR: <path>
TARGET_URL: <target>
OUTPUT_DIR: <artifacts path>
VALIDATION_PROCEDURE: skills/coordination/reference/VALIDATION.md
```

The validator receives evidence and the validation procedure only. It must not see the
attack chain, other findings, executor logs, or the coordinator's theory. It writes the
contractual result under `artifacts/validated/`, `artifacts/false-positives/`,
`artifacts/dropped/`, or returns `CURE` with named gaps.

## Executor: cure

On `CURE`, delegate a fresh `executor` with only the named failed checks and missing
evidence. The cure worker closes those gaps and does not re-theorize or expand scope.
Then delegate a fresh blind validator; never reuse the previous validator context.

## Validator: engagement

After every candidate has reached a terminal verdict, delegate `validator` once with:

```text
CLASS: engagement
OUTPUT_DIR: <path>
```

It checks completeness and reporting contracts without reading the coordinator's
private theory. The coordinator returns `PHASE3_SUMMARY` only after this review.

## Cadence and limits

- Run one coordinator per target.
- Run no more than two executors in a normal batch.
- Wait for all workers in a batch before integrating results.
- Validate each candidate before starting the next batch.
- Spawn a fresh validator for every cure round.
- Keep findings and evidence inside the assigned `OUTPUT_DIR`.

## Anti-patterns

- Passing all skills or all references to every worker.
- Letting a validator or skeptic read `attack-chain.md`.
- Treating an executor's claim as a validated finding.
- Running the coordinator workflow inline while pretending it is delegated.
- Spawning workers without a populated `OUTPUT_DIR`.
