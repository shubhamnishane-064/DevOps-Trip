# Notes: Day 4 - Matrix Builds, Variables, Secrets, Caching and Artifacts

**Week 3 | Thursday** | Topic: make pipelines test many combinations, handle configuration and secrets safely, and run faster

---

## 1. What Is New Today

| Feature | Problem it solves |
|---|---|
| **Matrix** | "Does my code work on Python 3.10, 3.11, 3.12... and on Ubuntu 22.04 and 24.04?" Write the job once, GitHub creates every combination |
| **Variables** (`env`, `vars`) | Keep settings out of the scripts, and change them without editing code |
| **Secrets** | Passwords, tokens and keys that must never appear in the repo or the logs |
| **Cache** | Don't download the same dependencies again on every run, so runs are faster |
| **Artifacts** | Keep files from a run (reports, builds) and pass them to another job |

---

## 2. Matrix Builds

### The idea
```yaml
strategy:
  matrix:
    os: [ubuntu-22.04, ubuntu-24.04]
    python-version: ['3.10', '3.11', '3.12']
```
2 values x 3 values = **6 jobs**, each with its own fresh runner, all started from one job definition. Use the values with `${{ matrix.os }}` and `${{ matrix.python-version }}`.

```yaml
runs-on: ${{ matrix.os }}
steps:
  - uses: actions/setup-python@v7
    with:
      python-version: ${{ matrix.python-version }}
```
**Always quote versions:** `'3.10'`, otherwise YAML reads it as the number `3.1`.

### Strategy options
| Option | Meaning |
|---|---|
| `fail-fast: true` (default) | When one combination fails, GitHub **cancels** the others. Fast feedback, but you see only the first failure |
| `fail-fast: false` | Let all combinations finish, so I see **every** failure. Better for finding patterns |
| `max-parallel: 4` | Run at most 4 jobs at once |
| `continue-on-error: ${{ matrix.experimental == true }}` | A combination marked experimental may fail without failing the workflow |

A single matrix can create at most 256 jobs per workflow run.

### `include` and `exclude`
```yaml
matrix:
  os: [macos-latest, windows-latest]
  version: [12, 14, 16]
  exclude:                       # REMOVE combinations (a partial match is enough)
    - os: windows-latest
      version: 16
  include:                       # ADD extra values or extra combinations
    - os: ubuntu-latest
      version: 18
      experimental: true
```
- `exclude` removes every combination that matches **all** the keys of the entry.
- `include` adds the extra keys to every existing combination whose **original** values match. If it matches none, it creates a **new** job.
- **A matrix with only `include`** makes **one job per entry**: a neat way to write a **table of test cases**.

```yaml
matrix:
  include:
    - { cidr: 192.168.1.130/26, usable: 62 }
    - { cidr: 192.168.1.130/30, usable: 2 }
# -> 2 jobs, each with matrix.cidr and matrix.usable
```

### Previewing a matrix: `matrix_preview.py`
The rules for `include` and `exclude` are easy to get wrong, so I wrote a small tool that prints the jobs GitHub will create:
```bash
python3 matrix_preview.py workflows/matrix.yml
# Job 'python-tests': 9 job(s)   fail-fast=False   max-parallel=4
#    1. os=ubuntu-22.04, python-version=3.10
#    ...
#    9. os=ubuntu-24.04, python-version=3.14, experimental=True
# Job 'cidr-table': 5 job(s) ...
```
I checked it against the examples in the GitHub documentation (a 2x3x2 matrix with two excludes gives **9** jobs, and a fruit/animal example with five includes gives **6** jobs), and it matched.
It needs PyYAML (`sudo apt install python3-yaml`).

**A bug I found in my own tool today:** for the include-only table it first printed **1** job instead of 5, because it treated each `include` as an add-on to a single empty combination. With no normal keys, every `include` entry is its own job. I fixed it and re-ran all examples. Lesson: test with known answers, and be careful with the `include` rules.

---

## 3. Variables

### Environment variables (`env`) at three levels
```yaml
env:                      # workflow level: every job
  APP_NAME: devops-trip
jobs:
  build:
    env:                  # job level: every step of this job
      REGION: ap-south-1
    steps:
      - env:              # step level: only this step
          MODE: fast
        run: echo "$APP_NAME $REGION $MODE"
```
The **closest** level wins (step beats job beats workflow). In scripts I read them as normal shell variables (`$APP_NAME`).

### Configuration variables (`vars` context)
Set in **Settings -> Secrets and variables -> Actions -> Variables** (repository, environment or organisation level).
```yaml
env:
  GREETING: ${{ vars.GREETING }}
```
- **Not secret:** values appear in the logs. Use them for region names, URLs, feature flags.
- The same name at a more specific level overrides the broader one: environment > repository > organisation.

### Default variables GitHub gives me
`GITHUB_REPOSITORY`, `GITHUB_REF_NAME`, `GITHUB_SHA`, `GITHUB_ACTOR`, `GITHUB_EVENT_NAME`, `GITHUB_WORKSPACE`, `RUNNER_OS`, `RUNNER_TEMP`, `CI=true`.

### Passing small values between steps and jobs
```yaml
jobs:
  prepare:
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.ver.outputs.version }}          # expose a step output as a JOB output
    steps:
      - id: ver
        run: echo "version=1.4.2" >> "$GITHUB_OUTPUT"
  use:
    needs: prepare
    runs-on: ubuntu-latest
    steps:
      - run: echo "Building ${{ needs.prepare.outputs.version }}"
```
For **files** use artifacts (section 6); outputs are for short text only.

---

## 4. Secrets

### What they are
Encrypted values stored in GitHub: **Settings -> Secrets and variables -> Actions -> Secrets**. They can be set at three levels: repository, **environment** and organisation.

```yaml
steps:
  - name: Deploy
    env:
      API_TOKEN: ${{ secrets.API_TOKEN }}     # map the secret into ONE step
    run: ./deploy.sh                           # the script reads $API_TOKEN
```

### The rules
| Rule | Why |
|---|---|
| Map a secret only into the step that needs it, through `env:` | A smaller exposure |
| Never `echo` a secret, never pass it on a command line you log | It can leak (GitHub masks known values as `***`, but that is a safety net, not a plan) |
| Masking can be defeated by changing the value | A secret that is transformed (base64, split, reversed) may no longer match. Register new values with `echo "::add-mask::$VALUE"` |
| Never commit secrets, and rotate any that were committed | History keeps them forever |
| Secrets are **not** given to workflows triggered by pull requests from **forks** | A stranger's PR must not be able to read them. Expect `secrets.X` to be empty there |
| Use **short-lived** credentials where possible | See OIDC below |
| Secret names: letters, numbers and `_`, not starting with a number or `GITHUB_` | Naming rule |

### The built-in `GITHUB_TOKEN`
GitHub creates a temporary token for **every run**, and it expires when the run ends. Its rights come from `permissions:`.
```yaml
permissions:
  contents: read            # at the top of the workflow
jobs:
  comment:
    permissions:
      pull-requests: write  # more rights ONLY for this job
```
Use it with the `gh` CLI: `env: GH_TOKEN: ${{ github.token }}`.

### Environments (protection for deployments)
```yaml
jobs:
  deploy:
    environment: production
```
An **Environment** (Settings -> Environments) can have its own secrets and variables, **required reviewers** (a person must approve before the job runs), a wait timer, and branch restrictions. This is how "only `main` may deploy to production, after approval" is enforced.

### OIDC: no long-lived cloud keys (preview of Week 6)
Instead of storing AWS access keys as secrets, the workflow asks GitHub for a short-lived identity token and AWS exchanges it for temporary credentials:
```yaml
permissions:
  id-token: write           # allow the workflow to request the identity token
  contents: read
steps:
  - uses: aws-actions/configure-aws-credentials@v6    # check the current version
    with:
      role-to-assume: arn:aws:iam::123456789012:role/github-ci
      aws-region: ap-south-1
```
No secret to leak or rotate. This is the modern way to deploy to AWS from Actions.

### Demo workflow: `secrets-vars.yml`
Manual run. It prints variables, checks that a secret exists **without printing it** (only its length), shows masking, and uses `GITHUB_TOKEN` with `gh repo view`. Before running it, add variables `GREETING` and `DEPLOY_REGION` and a secret `DEMO_TOKEN`.

---

## 5. Caching

### The idea
Each job starts on an empty machine, so installing dependencies (pip, npm, downloads) repeats on every run. A **cache** stores files under a **key**. If the key exists next time, the files are restored in seconds.

```yaml
- name: Cache downloads
  id: cache
  uses: actions/cache@v6
  with:
    path: ~/.cache/pip
    key: pip-${{ runner.os }}-${{ hashFiles('**/requirements.txt') }}
    restore-keys: |
      pip-${{ runner.os }}-
- name: Install (only when needed)
  if: steps.cache.outputs.cache-hit != 'true'
  run: pip install -r requirements.txt
```
| Part | Meaning |
|---|---|
| `path` | What to save and restore |
| `key` | Exact name of the cache. **Include a hash of the dependency file**, so when `requirements.txt` changes the key changes and a new cache is made |
| `restore-keys` | Fallback prefixes: if the exact key is missing, restore the most recent cache that starts with this, then update it |
| `cache-hit` output | `'true'` only on an **exact** key match |

`hashFiles('**/requirements.txt')` makes a hash of the file contents.

**Shortcut:** many `setup-*` actions have caching built in:
```yaml
- uses: actions/setup-python@v7
  with:
    python-version: '3.12'
    cache: pip
```

### Facts to remember
- A cache is **saved at the end of a successful job**, and restored at the start of the next.
- **Scope:** a run can restore caches from its own branch and from the default branch (and from the base branch for PRs). Caches made in a PR branch are not visible to `main`.
- **Limits:** the total cache size per repository is limited (10 GB by default), and caches not used for 7 days are removed. Check the current limits in the GitHub documentation.
- **Never cache secrets or credentials.**
- A cache is an **optimisation**: the workflow must still work on a cache miss.
- Cache is **not** for passing results between jobs. Use artifacts.

My demo (`cache-artifacts.yml`) caches the `actionlint` program, keyed by its version number: the first run downloads it (miss), later runs restore it (hit). Changing `ACTIONLINT_VERSION` creates a new cache.

---

## 6. Artifacts

### The idea
Files produced by a job (test reports, built programs, logs) are lost when the runner is destroyed. **Upload them as an artifact** to keep them, download them from the run's page, or pass them to another job.

```yaml
# job 1: save
- uses: actions/upload-artifact@v7
  if: always()                        # also upload after a failure: that is when I want the report most
  with:
    name: lint-report
    path: reports/
    retention-days: 7
    if-no-files-found: error

# job 2 (a different machine): get it
- uses: actions/download-artifact@v8
  with:
    name: lint-report
    path: downloaded
```

### Things to know
| Point | Detail |
|---|---|
| Same major version | Upload and download actions must be a **matching generation** (v4 and newer are not compatible with older artifacts) |
| Names are **unique per run** | You cannot upload the same name twice in one run. In a matrix, add the matrix value to the name: `name: report-${{ matrix.python-version }}` |
| Collect matrix results | `download-artifact` with `pattern: report-*` and `merge-multiple: true` gathers them into one folder |
| Retention | Default is long (up to 90 days, configurable). Set `retention-days` to save storage |
| Size | Artifacts count towards storage. Do not upload huge folders or secrets |
| Skipped upload | By default a step runs only if all earlier steps **succeeded**. Add `if: always()` (or `failure()`) to the upload step |

### Cache vs artifact vs output

| | **Cache** | **Artifact** | **Job output** |
|---|---|---|---|
| Purpose | Speed up repeated downloads | Keep or pass **files** | Pass **short text** |
| Shared between runs? | Yes | Download manually, or in the same run | Same run only |
| Between jobs of one run? | Not for results | Yes | Yes (`needs.x.outputs.y`) |
| Example | pip packages, a tool binary | test report, a build | a version number |

---

## 7. Versions of the Actions I Use

Action versions change quickly. When I checked (mid-2026), the current majors were:

| Action | Major version used |
|---|---|
| `actions/checkout` | `v7` |
| `actions/cache` | `v6` |
| `actions/upload-artifact` | `v7` |
| `actions/download-artifact` | `v8` |
| `actions/setup-python` | `v7` (I saw v6.3.0 move to v7.0.0 in a dependency update; check the Releases page) |

- Newer majors run on **Node 24**, which needs runner version **2.327.1 or newer**. GitHub-hosted runners are fine. **Self-hosted** runners must be updated first.
- `download-artifact@v8` now fails on a **digest mismatch** instead of only warning.
- **Dependabot** keeps these current. Add `.github/dependabot.yml` with `package-ecosystem: github-actions` (see Day 3).
- Always read the release notes for a major bump.

---

## 8. My Workflows Today

| File | What it shows |
|---|---|
| `workflows/matrix.yml` | `python-tests`: 4 Python versions x 2 Ubuntu versions + 1 experimental (Python 3.14, allowed to fail) = **9 jobs**, `fail-fast: false`, `max-parallel: 4`. `cidr-table`: **5 jobs** from an include-only table checking `cidr.sh` usable-host counts (/8, /16, /24, /26, /30) |
| `workflows/secrets-vars.yml` | `env`, `vars`, a secret checked without printing, masking, `environment: staging`, `GITHUB_TOKEN` with `gh` |
| `workflows/cache-artifacts.yml` | Cache the `actionlint` binary, lint the workflows, write a report, **upload** it, and a second job **downloads** it (with `if: always()` so a failed lint still produces a report) |
| `tests/test_backend.py` | 5 unit tests for the Week 2 Python backend (`/health`, response text, `X-Backend` header, forwarded IP, content length) |
| `matrix_preview.py` | Prints the jobs a matrix will create |

**What I verified here**
- `actionlint` and `yamllint` accept all three workflows. (`actionlint` also ran ShellCheck inside the `run:` blocks and caught a style issue, `cat file | head`, which I fixed.)
- The 5 unit tests pass with Python 3.12 (written with only the standard library, so they should run on every version in the matrix).
- All 5 `cidr.sh` table cases pass locally.
- I ran the workflow's download and lint steps in a shell like the runner's (`bash -eo pipefail`): a clean repo gave exit 0 and an empty report, and a broken workflow gave a non-zero exit **and still wrote the report**.
- I could not run them on GitHub from here, so the first real run is mine to check.

---

## 9. Lab (Hands-on)

```bash
cd ~/DevOps-Trip
mkdir -p .github/workflows
cp week-03-git-github-actions/4-thu/workflows/*.yml .github/workflows/
python3 week-03-git-github-actions/4-thu/matrix_preview.py .github/workflows/matrix.yml
./week-03-git-github-actions/3-wed/ci_local.sh
git add .github && git commit -m "ci: add matrix, secrets and cache workflows" && git push
```

**Part 1: matrix**
1. Open **Actions -> Matrix tests** and look at the 9 + 5 jobs and their names.
2. Break one test on purpose (change a `grep` expectation, or edit `backend.py`), push, and watch which combinations fail. Then switch `fail-fast` to `true` and compare.
3. Add `exclude` for one combination and run `matrix_preview.py` to see the new count before pushing.

**Part 2: variables and secrets**
1. **Settings -> Secrets and variables -> Actions**: add variables `GREETING`, `DEPLOY_REGION` and secret `DEMO_TOKEN`.
2. Run **Secrets and variables demo** from the Actions tab. Read the logs: the secret is checked by length and any attempt to print it shows `***`.
3. Create an **Environment** called `staging`, add a required reviewer, and run again: it should wait for approval.

**Part 3: cache and artifacts**
1. Run **Cache and artifacts** twice. In the first run `cache-hit: false`, in the second `true`, and the "Download actionlint" step is skipped.
2. Open the run page, scroll to **Artifacts**, and download `lint-report`.
3. Break a workflow on purpose (a wrong `needs:`), run again, and confirm that the job fails **but the report is still uploaded and shown in `show-report`**.
4. Remove `if: always()` from the upload step, break the workflow again, and watch what happens in `show-report` (the artifact is missing). Then put it back.

Result: (write what happened, add screenshots of the matrix, a cache hit and the artifact)

---

## 10. Errors Faced Today
- Example: `show-report` fails because the artifact is missing (the upload step was skipped after a failed step)
- Cause: steps run only after success by default, and the upload had no `if: always()`
- Fix: `if: always()` on the upload step (and on the job that downloads it)
- Also solved today: an include-only matrix counted wrongly in my preview tool, and `actionlint` refusing to run outside a Git repository

Full story: `troubleshooting/error-01.md`

---

## 11. Quick Q&A (for interviews)

**Q: What is a matrix strategy and when do you use it?**
It runs one job definition many times with different values (for example Python versions and operating systems), so I test all combinations without copying the job.

**Q: `fail-fast` true vs false?**
With `true` (the default) the first failure cancels the other combinations, which gives quick feedback. With `false` all combinations finish, so I see every failure.

**Q: How do `include` and `exclude` work?**
`exclude` removes combinations that match its keys. `include` adds extra keys to matching combinations or creates a new combination if none match. A matrix with only `include` makes one job per entry.

**Q: Variables vs secrets?**
Variables are plain configuration visible in logs. Secrets are encrypted and masked. Both can be set at repository, environment or organisation level, and I map secrets into only the steps that need them.

**Q: Why are secrets empty in pull requests from forks?**
So that a stranger's PR can't run code that reads my secrets. For trusted automation, use `pull_request_target` carefully, or require maintainer approval.

**Q: How do you stop secrets leaking in logs?**
Never echo them, map them through `env:` into single steps, rely on masking only as a safety net, mask derived values with `::add-mask::`, and prefer short-lived credentials (OIDC) over stored keys.

**Q: What is `GITHUB_TOKEN`?**
A temporary token created for each run whose rights are controlled by `permissions:`. I give it the minimum, such as `contents: read`.

**Q: What is an Environment in GitHub?**
A named target such as `staging` or `production` with its own secrets and variables, and protection rules like required reviewers, wait timers and allowed branches.

**Q: How does caching work and how do you choose a key?**
`actions/cache` saves a path under a key and restores it when the key matches. The key should include a hash of the dependency file, for example `hashFiles('**/requirements.txt')`, so it changes when dependencies change. `restore-keys` provides fallback prefixes.

**Q: Cache vs artifact?**
A cache speeds up repeated downloads between runs. An artifact keeps or passes files produced by a run, between jobs or for download. Job outputs pass only short text.

**Q: Why use `if: always()` on an upload step?**
By default a step is skipped if an earlier step failed. When a test fails I most want the report, so the upload must run anyway.

**Q: How does one job pass a file to another?**
Upload it as an artifact in the first job and download it in the second, because each job runs on a different machine.

**Q: Why quote `python-version: '3.10'`?**
YAML would read 3.10 as the number 3.1, and the wrong version would be installed.

**Q: How do you deploy to AWS from Actions without storing access keys?**
Use OIDC: give the workflow `id-token: write`, configure an IAM role that trusts GitHub, and use `configure-aws-credentials` to get short-lived credentials.

---

## 12. Summary in 3 lines
1. A **matrix** runs one job over many combinations (`include`/`exclude`, `fail-fast: false`, `max-parallel`), and I can preview the job count before pushing.
2. Use `env` and `vars` for configuration, **secrets** only through `env:` in the steps that need them, a least-privilege `GITHUB_TOKEN`, Environments for approvals, and OIDC instead of long-lived cloud keys.
3. **Cache** dependencies (a key with `hashFiles`), **upload artifacts** to keep or pass files (`if: always()`), and keep action versions current with Dependabot.