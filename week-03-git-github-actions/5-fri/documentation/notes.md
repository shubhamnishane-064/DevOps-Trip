# Notes: Day 5 - Reusable Workflows and Composite Actions

**Week 3 | Friday** | Topic: write a pipeline piece once, use it everywhere (the DRY rule: Don't Repeat Yourself)

---

## 1. The Problem
After four days I have several workflows. Many of them repeat the same steps: checkout, install ShellCheck, install actionlint, lint scripts. If I copy and paste:
- fixing a bug means editing 10 files,
- the copies slowly drift apart,
- every new repository starts from a stale copy.

GitHub Actions has two tools to share logic:

| Tool | What it packages | Level |
|---|---|---|
| **Composite action** | A list of **steps** | One step in a job |
| **Reusable workflow** | One or more whole **jobs** | A job (or several) in a workflow |

---

## 2. Choosing a Way to Reuse

Simple rule: **steps -> composite action, jobs -> reusable workflow.**

---

## 3. Composite Actions

### What it is
A action-pipline folder with an `action.yml` that describes inputs, outputs and steps. A workflow uses it like any other action: `uses: ./.github/actions/lint-shell`.

### Anatomy (`actions/lint-shell/action.yml`)
```yaml
name: Lint shell scripts
description: Runs bash -n and ShellCheck on every .sh file under a folder.

inputs:                                   # what the caller can pass in
  path:
    description: Folder to search
    default: '.'
  severity:
    default: warning

outputs:                                  # what the caller can read afterwards
  count:
    description: Number of scripts checked
    value: ${{ steps.lint.outputs.count }}

runs:
  using: composite                        # <- makes it a composite action
  steps:
    - name: Check the scripts
      id: lint
      shell: bash                         # <- REQUIRED on every run step
      env:
        INPUT_PATH: ${{ inputs.path }}
      run: bash "$GITHUB_ACTION_PATH/lint_shell.sh" "$INPUT_PATH"
```

### Rules and gotchas
| Rule | Detail |
|---|---|
| `shell:` is **required** on every `run` step | There is no default shell in a composite action |
| Files that ship with the action | Reach them through `$GITHUB_ACTION_PATH` (the action's own folder), not the caller's workspace |
| It can use other actions | `uses: actions/cache@v6` inside is fine |
| **No `secrets` context** | The action cannot read secrets by itself. The caller passes them as **inputs** |
| Pass inputs through `env:` | Don't paste `${{ inputs.x }}` into the script text (script injection, Day 3) |
| It runs **inside the caller's job**, on the caller's runner and workspace | Same machine, so files made by earlier steps are visible |
| Outputs need a `value:` that points at a step output | Steps write them with `echo "name=value" >> "$GITHUB_OUTPUT"` |
| Call scripts with `bash script.sh` | Then a missing executable bit (Day 3's error) can't break the action |

### Where to put it and how to call it
```
.github/actions/lint-shell/action.yml            <- in the SAME repository
.github/actions/lint-shell/lint_shell.sh
```
```yaml
steps:
  - uses: actions/checkout@v7                    # needed first, so the local action folder exists on the runner
  - uses: ./.github/actions/lint-shell           # local: starts with ./ and has no @version
    with:
      path: week-01-linux-bash
```
From another repository: `uses: owner/repo/.github/actions/lint-shell@v1`, or an action in its own repo: `uses: owner/lint-shell@v1`.

### Keep the logic in a script I can test
The composite action is only a **thin wrapper**. The real work is in `lint_shell.sh`, so I can test it on my laptop without GitHub:
```bash
bash actions/lint-shell/lint_shell.sh week-01-linux-bash warning
```

### My two composite actions
| Action | Job |
|---|---|
| `actions/lint-shell` | Installs ShellCheck if missing, runs `bash -n` and ShellCheck on every `.sh` under a path, outputs the **count** |
| `actions/setup-actionlint` | Downloads a pinned `actionlint` (input `version`), with `actions/cache`, and adds it to the PATH |

---

## 4. Reusable Workflows

### What it is
A normal workflow file that also listens to the `workflow_call` event, so **another workflow can call it like a function**: with inputs, secrets and outputs.

### The called workflow (`workflows/shell-quality.yml`)
```yaml
on:
  workflow_call:
    inputs:
      path:      { type: string,  default: '.' }
      severity:  { type: string,  default: warning }
      lint-workflows: { type: boolean, default: true }
    secrets:                                   # (not needed here) secrets the caller must pass
      TOKEN:
        required: false
    outputs:
      scripts-checked:
        description: Number of scripts checked
        value: ${{ jobs.shell.outputs.count }}   # comes from a JOB output

jobs:
  shell:
    runs-on: ubuntu-latest
    outputs:
      count: ${{ steps.lint.outputs.count }}
    steps:
      - uses: actions/checkout@v7
      - id: lint
        uses: ./.github/actions/lint-shell
        with:
          path: ${{ inputs.path }}
```
Input types allowed in `workflow_call`: `string`, `number`, `boolean`. (`choice` exists only for manual `workflow_dispatch` runs.)

### The caller (`workflows/ci-caller.yml`)
```yaml
jobs:
  quality:                                    # a job that has "uses" and NO runs-on and NO steps
    uses: ./.github/workflows/shell-quality.yml
    with:
      path: .
      severity: warning
    # secrets: inherit                        # or pass them one by one with  secrets: { TOKEN: ${{ secrets.X }} }

  report:
    needs: quality
    runs-on: ubuntu-latest
    steps:
      - run: echo "Checked ${{ needs.quality.outputs.scripts-checked }} scripts"
```
Also possible: a **matrix** on the calling job, which gives one reusable-workflow run per value:
```yaml
  quality-by-week:
    strategy:
      matrix:
        path: [week-01-linux-bash, week-02-networking, week-03-git-github-actions]
    uses: ./.github/workflows/shell-quality.yml
    with:
      path: ${{ matrix.path }}
```

### How to point at it
| Form | Meaning |
|---|---|
| `./.github/workflows/x.yml` | Same repository, **same commit** as the caller (no `@ref`) |
| `owner/repo/.github/workflows/x.yml@main` | Another repository, at a branch, tag or SHA |

### Rules and gotchas
| Rule | Detail |
|---|---|
| The calling job has **no `steps` and no `runs-on`** | The called workflow decides its own runners |
| Secrets are **not** passed automatically | Pass them with `secrets:` or `secrets: inherit` |
| The caller's `env` is **not** passed | Use `inputs` |
| `permissions` can only stay the same or get **smaller** | A called workflow can't give itself more than the caller allows. A mismatch fails when the workflow starts, with an error that says the nested job is requesting more permission than allowed |
| The `github` context is the **caller's** | `github.repository`, `github.sha`, `github.ref` describe the calling repository and run |
| Outputs go through **job outputs** | `workflow_call.outputs` -> `jobs.<id>.outputs` -> `steps.<id>.outputs` |
| With a matrix, outputs from several runs are ambiguous | Don't read outputs from a matrix call |
| Nesting (a reusable workflow calling another) is allowed but **limited** | Check the current limit in the documentation |
| The log shows the called jobs under the caller's run | Each job is visible and re-runnable |

### Cross-repository gotcha (very common)
Inside a reusable workflow that lives in **another** repository, `uses: ./.github/actions/lint-shell` does **not** mean "next to this workflow". It means the action folder in the **caller's** checked-out workspace, which may not exist. For shared workflows, reference the action by its full name:
```yaml
uses: shubhamnishane-064/DevOps-Trip/.github/actions/lint-shell@v1
```
Within a single repository the `./` form is fine (that is what I use).

---

## 5. Reusable Workflow vs Composite Action

| | **Reusable workflow** | **Composite action** |
|---|---|---|
| Packages | Jobs | Steps |
| Called with | `jobs.<id>.uses` | `steps[*].uses` |
| Runs on | Its **own** runner(s) | The **caller's job** runner |
| Can have several jobs, `needs`, matrix, `environment`, services | Yes | No |
| Can read `secrets` | Only those passed in (`secrets:` / `inherit`) | Only through inputs |
| Shares files with earlier steps | No (separate runners) | Yes (same workspace) |
| Inputs | `workflow_call.inputs` (typed) | `inputs` (always strings) |
| Defined in | `.github/workflows/*.yml` | `action.yml` in any folder |
| Typical use | "Run our standard CI", "deploy to AWS" | "Set up our tools", "lint these files" |

They combine well, as in my example:
```
ci-caller.yml
   `--> shell-quality.yml  (reusable workflow: jobs)
           |--> lint-shell        (composite action: steps)
           `--> setup-actionlint  (composite action: steps)
                    `--> lint_shell.sh (a script I can run and test by hand)
```

---

## 6. Versioning, Trust and Sharing

- **Version the shared pieces.** Publish tags such as `v1.0.0` and a moving major tag `v1`; callers use `@v1`, and breaking changes become `v2`. Tomorrow's semantic releases automate this.
- **Pin to a full commit SHA** for anything I do not control, so a moved tag can't change what runs.
- **A reusable workflow runs with the caller's secrets and token** if I pass or inherit them, so only call workflows I trust.
- **Sharing between repositories:** public repositories can use each other's public workflows. For **private** repositories, the repository that owns the shared workflow must allow access (Settings -> Actions -> General -> Access).
- **`secrets: inherit`** passes all of the caller's secrets and works inside the same organisation or enterprise. Prefer passing only what is needed.
- **Dependabot** can open pull requests that update the versions of actions I use.
- **Starter workflows:** an organisation can keep templates in its `.github` repository, and new repos can pick them from the Actions tab.

---

## 7. Where I Use This in My Repo

My Day 3 `ci.yml` has a `lint-scripts` job with its own install and lint steps. With the new pieces I can replace it:
```yaml
jobs:
  lint-scripts:
    uses: ./.github/workflows/shell-quality.yml
    with:
      path: .
      severity: warning
  test-scripts:
    needs: lint-scripts
    ...
```
Now one change to `lint_shell.sh` updates every pipeline that uses it. In Week 5 (Jenkins) and Week 7 (Terraform), the same idea appears as Jenkins shared libraries and Terraform modules.

---

## 8. What I Verified Here

| Check | Result |
|---|---|
| `actionlint` over a copy of my repo with the reusable workflow, the caller and both local composite actions | **No problems** |
| `yamllint` | Clean |
| ShellCheck on `lint_shell.sh`, even at `style` level | Clean |
| A typo in a `with:` block of a **composite action** (`severty`) | actionlint: `input "severty" is not defined in action "Lint shell scripts" ... available inputs are "path", "severity"` |
| A typo in the **caller's** `with:` for the reusable workflow | actionlint: `input "severty" is not defined in "./.github/workflows/shell-quality.yml" reusable workflow` |
| A **required** input left out by the caller | actionlint: `input "path" is required by ... reusable workflow` |
| `lint_shell.sh` on a clean folder | exit 0, `count=11` written to `GITHUB_OUTPUT` |
| A folder with `rm -rf $DIR/*` | exit 1, ShellCheck warning SC2115 |
| A script with a syntax error | exit 1, with a `::error file=...` annotation |
| Severity: a style-only finding (`cat file \| head`) | `warning` -> exit 0, `style` -> exit 1 |
| Bad severity, or a missing path | exit 2 with a clear `::error::` message |
| The whole repo copy (23 scripts) | exit 0, `count=23` |
| The composite step run the way the runner runs it (`bash -eo pipefail`, `GITHUB_ACTION_PATH`) | Works without any executable bit |

I could not run the workflows on GitHub from here, so the first real run is mine to check.

---

## 9. Lab (Hands-on)

```bash
cd ~/DevOps-Trip
mkdir -p .github/actions .github/workflows
cp -r week-03-git-github-actions/5-fri/actions/* .github/actions/
cp week-03-git-github-actions/5-fri/workflows/*.yml .github/workflows/

# test the helper script by hand first
bash .github/actions/lint-shell/lint_shell.sh week-01-linux-bash warning

./week-03-git-github-actions/3-wed/ci_local.sh            # actionlint now also checks the new files
git add .github && git commit -m "ci: add reusable shell-quality workflow and composite actions" && git push
```

**Part 1: watch it run**
1. Open **Actions -> CI (calls the reusable workflow)**.
2. Find the jobs from the called workflow nested under `quality` and the three `quality-by-week` runs. Open each and look at the nested steps of the composite actions.
3. Open the `report` job and find the number of scripts.

**Part 2: break it on purpose**
1. Add a script with `rm -rf $DIR/*` in a branch, open a PR, and watch the check fail with SC2115.
2. Typo an input in `ci-caller.yml` (`severty:`) and see the workflow fail at start-up (a reusable workflow rejects it). Run `actionlint` locally to see the same message.
3. Typo an input in a **step** that uses a composite action, push it, and look in the run for the warning that an input is unexpected. Notice that the run still goes ahead with the default value.

**Part 3: refactor**
1. Replace the `lint-scripts` job in `ci.yml` with `uses: ./.github/workflows/shell-quality.yml` (section 7).
2. Change `lint_shell.sh` (for example add a line that prints the folder name) and see that **both** pipelines change.

**Part 4: share it (optional)**
1. Create a second small repo, and call the workflow with `uses: shubhamnishane-064/DevOps-Trip/.github/workflows/shell-quality.yml@main`.
2. Notice the `./.github/actions/...` problem from section 4, and fix it by referencing the actions with their full name.

Result: (write what happened, add screenshots of the nested jobs and the `report` job)

---

## 10. Errors Faced Today
- Example: a typo in a `with:` input (`severty:` instead of `severity:`)
- A **reusable workflow** rejects an unknown input, but a **composite action** only warns and uses the default value, so the check quietly runs with the wrong setting
- Fix: correct the name, and run `actionlint` locally, because it catches both cases

Full story: `troubleshooting/error-01.md`

---

## 11. Quick Q&A (for interviews)

**Q: What is a reusable workflow?**
A workflow with a `workflow_call` trigger, so other workflows can call it like a function with inputs, secrets and outputs. It lets teams keep one standard pipeline instead of copying it.

**Q: What is a composite action?**
An action defined in `action.yml` with `runs.using: composite` that bundles several steps into one reusable step, with inputs and outputs.

**Q: Reusable workflow vs composite action?**
A reusable workflow packages whole jobs and runs on its own runners; it is called at job level. A composite action packages steps and runs inside the caller's job on the same runner and workspace; it is called at step level.

**Q: How do you pass secrets to a reusable workflow?**
Explicitly with `secrets:` (one by one), or `secrets: inherit` to pass all of them within the same organisation. They are not passed automatically.

**Q: How do you get a result back from a reusable workflow?**
Declare `outputs` under `workflow_call` that point at a job's outputs, which point at a step's outputs. The caller reads `needs.<job>.outputs.<name>`.

**Q: Why does a composite action need `shell:` on every run step?**
There is no default shell for composite actions, so each run step has to name one.

**Q: Can a composite action read secrets?**
Not directly. The caller must pass them as inputs.

**Q: What is wrong with `uses: ./.github/actions/x` inside a reusable workflow that lives in another repo?**
The `./` path refers to the caller's workspace, not the repository that holds the workflow, so the action may not be found. Reference it with its full name and a version instead.

**Q: How do you version shared workflows and actions?**
With Git tags (`v1.2.3`) and a moving major tag (`v1`) for callers, with breaking changes in a new major version. For untrusted code, pin a full commit SHA.

**Q: What permissions can a called workflow have?**
At most what the caller grants. A called workflow can keep or reduce permissions but cannot raise them.

**Q: How do you test a composite action without pushing to GitHub?**
Keep the logic in a script, run the script locally with sample inputs, set `GITHUB_OUTPUT` to a temp file to check outputs, and validate the YAML with `actionlint`, which also checks inputs against the action's definition.

**Q: Can a reusable workflow be used with a matrix?**
Yes, the calling job can use `strategy.matrix` and pass `${{ matrix.x }}` as inputs. But outputs from several matrix runs are ambiguous, so don't rely on them.

**Q: Why share CI logic at all?**
One place to fix bugs, consistent checks across repositories, faster setup for new projects, and a single place to update versions and security settings.

---

## 12. Summary in 3 lines
1. **Steps -> composite action** (`action.yml`, `using: composite`, `shell:` on every run step, inputs through `env:`); **jobs -> reusable workflow** (`on: workflow_call`, typed inputs, explicit secrets, outputs through job outputs).
2. Keep logic in a script I can test by hand, use thin wrappers, remember that `./` paths inside a cross-repo reusable workflow point at the **caller's** workspace, and version shared pieces with tags or SHAs.
3. Run `actionlint` locally: it checks the inputs of local composite actions and reusable workflows, which catches typos before GitHub does.