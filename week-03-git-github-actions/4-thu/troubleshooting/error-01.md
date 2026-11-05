# Error Log: the report artifact is missing after a failed step

## 1. Symptom (what I will see)
The lint step fails (that is expected, I broke a workflow on purpose). Then the *next* job fails too, with a message about a missing artifact. The wording differs between versions, but it looks like this:
```
lint-workflows   ... Lint the workflows and write a report   FAILED (exit code 1)
lint-workflows   ... Upload the report                       SKIPPED
show-report      ... Download the report
                     Error: Unable to download artifact(s): Artifact not found for name: lint-report
```
Now there are two red marks, and the second one hides the real problem (the lint failure).

## 2. Context (what I was doing)
I built `cache-artifacts.yml`: one job lints the workflows and writes `reports/actionlint.txt`, uploads it as an artifact, and a second job downloads and prints it. The upload step was written like a normal step, without a condition.

## 3. Investigation (how I debugged)
- [x] Read the **first** red step, not the last: the lint step failed
- [x] Looked at the status of the upload step: **skipped**
- [x] Remembered the rule from Day 3: a step runs only if all earlier steps succeeded
- [x] Reproduced the behaviour locally in a runner-like shell

```bash
bash --noprofile --norc -eo pipefail -c '
mkdir -p reports
actionlint -no-color 2>&1 | tee reports/actionlint.txt
'
# .github/workflows/broken.yml:3:3: job "a" needs job "ghost" which does not exist in this workflow [job-needs]
echo $?
# 1                                    -> the step fails (pipefail passes actionlint'"'"'s exit code on)

ls reports; wc -l reports/actionlint.txt
# actionlint.txt   4 lines              -> the report WAS written, so the file exists and is worth uploading
```

## 4. Root Cause
- GitHub's default for a step is `if: success()`. After the failed lint step, the **upload step was skipped**, so no artifact named `lint-report` existed.
- The second job `show-report` then tried to download an artifact that was never created and failed with a **second, misleading** error.
- The useful file (the report) existed on the runner the whole time. It was simply never uploaded.

## 5. Fix
```yaml
- name: Upload the report (also when linting failed)
  if: always()                          # run even if an earlier step failed
  uses: actions/upload-artifact@v7
  with:
    name: lint-report
    path: reports/
    if-no-files-found: error            # fail loudly if the report is really missing

# in the second job
show-report:
  needs: lint-workflows
  if: always()                          # a job that needs a failed job is skipped unless I say so
```
- `if: always()` also runs when the workflow is **cancelled**. `if: ${{ !cancelled() }}` runs after success or failure but not after a cancel, and is often a better choice.
- `if-no-files-found: error` makes a missing report an obvious failure instead of a silent warning.

## 6. Prevention / Lesson Learned
- **Always read the first failing step.** Later failures can be consequences.
- Steps that save evidence (reports, logs, test results) need `if: always()` or `if: failure()`.
- A job that depends (`needs`) on a failed job is skipped by default. Add `if: always()` when it must still run.
- Make reports from failing steps with `| tee file` so the output is both shown and saved (`pipefail` is on by default in the runner's bash, so the step still fails).
- In a matrix, give each artifact a **unique name** (`report-${{ matrix.python-version }}`), because the same name cannot be uploaded twice in one run.

## 7. Other problems I solved while building today (real output)

**a) My matrix preview counted 1 job instead of 5**
```
Job 'cidr-table': 1 job(s)
   1. cidr=192.168.1.130/30, usable=2        <- expected 5 jobs
```
Cause: with only `include` entries and no normal keys, each entry is its **own job**. My tool merged them all into one combination. Fix: when the matrix has no normal keys, start with an empty list. Result: `cidr-table: 5 job(s)`, and the documented examples still give 9 and 6.

**b) `actionlint` could not find the project**
```
no project was found in any parent directories of "/tmp/ca/repo". check workflows directory is put correctly in your Git repository
```
Cause: actionlint looks for a Git repository around `.github/workflows`. On GitHub the checkout step provides one. Locally I ran `git init` first.

**c) ShellCheck found a style issue inside a workflow `run:` block**
```
matrix.yml:44:9: shellcheck reported issue in this script: SC2002:style:2:5: Useless cat.
```
Fix: `cat /etc/os-release | head -2` became `head -n 2 /etc/os-release`. `actionlint` runs ShellCheck on `run:` scripts automatically.
