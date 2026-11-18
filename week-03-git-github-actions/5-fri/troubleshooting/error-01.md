# Error Log: a typo in `with:` is rejected by one reuse mechanism and silently ignored by the other

## 1. Symptom (what I saw)
**Case A: calling the reusable workflow with a wrong input name**
```yaml
quality:
  uses: ./.github/workflows/shell-quality.yml
  with:
    path: .
    severty: warning            # typo: should be "severity"
```
`actionlint` (run locally):
```
.github/workflows/ci-caller.yml:23:7: input "severty" is not defined in "./.github/workflows/shell-quality.yml"
reusable workflow. defined inputs are "lint-workflows", "path", "severity" [workflow-call]
```
On GitHub, the run does not start at all and shows an invalid workflow file error that names the unknown input.

**Case B: using the composite action with a wrong input name**
```yaml
- uses: ./.github/actions/lint-shell
  with:
    path: week-01-linux-bash
    severty: error              # typo
```
`actionlint`:
```
.github/workflows/shell-quality.yml:43:11: input "severty" is not defined in action "Lint shell scripts"
defined at "./.github/actions/lint-shell". available inputs are "path", "severity" [action]
```
On GitHub, a step using an action with an unknown input does **not** fail. It shows a warning about unexpected inputs (the exact wording varies by version), and the step **runs with the default** (`severity: warning`), so my "error only" setting was never applied.

**Case C: forgetting a required input**
```
.github/workflows/ci-caller.yml:20:11: input "path" is required by "./.github/workflows/shell-quality.yml" reusable workflow [workflow-call]
```

## 2. Context (what I was doing)
I was refactoring my CI to use a reusable workflow (`shell-quality.yml`) and two composite actions. I renamed inputs while writing them, and I called them from several places.

## 3. Investigation (how I debugged)
- [x] Compared the name in `with:` with the name under `inputs:` of the thing I was calling
- [x] Read the "defined inputs are ..." list that `actionlint` prints
- [x] Checked whether the run failed or only warned
- [x] Remembered Day 3: validate workflows locally before pushing

```bash
actionlint                              # run in the repository root; it reads .github/workflows
# the three messages above appear at once
```

## 4. Root Cause
Two different behaviours:
- A **reusable workflow** has a strict contract. Unknown or missing required inputs are errors, so the mistake is loud.
- A **composite action's** unknown input is only a warning, because an action can't tell a typo from an input meant for something else. The step runs with the default value, so the mistake is **silent**.

The dangerous case is B: everything looks green while the setting I asked for is not used.

## 5. Fix
```yaml
with:
  path: .
  severity: warning               # the name must match "inputs:" exactly
```
Then:
```bash
actionlint                         # no output = no problems
```
`actionlint` knows the inputs of **local** composite actions and **local** reusable workflows (it reads their definitions), so it catches all three cases before I push.

## 6. Prevention / Lesson Learned
- Run `actionlint` in `ci_local.sh` and in CI, so typos in `with:` never reach `main`.
- Read warnings in the run log, even when the run is green. "Unexpected input(s)" means a setting was ignored.
- Print the effective settings at the start of a shared script (my script prints `ShellCheck severity: ...`), so the log shows what was really used.
- Validate inputs inside the script (it rejects an unknown severity with exit code 2), so a wrong **value** fails loudly too.
- Keep input names short, consistent and documented in the `description:` field.

## 7. Another error to expect: caller and called permissions
When a reusable workflow asks for more token permissions than the caller allows, GitHub refuses to start it with an error that says the nested job is requesting a permission but is only allowed a smaller one (for example `id-token: write` requested, `none` allowed). I could not reproduce this one here, so the exact wording may differ.
Fix: give the **calling job or workflow** the permission as well:
```yaml
jobs:
  deploy:
    permissions:
      contents: read
      id-token: write
    uses: ./.github/workflows/deploy.yml
```
A called workflow can only keep or reduce the permissions it receives, never raise them.
