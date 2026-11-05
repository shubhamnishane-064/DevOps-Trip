# Git, GitHub and Actions | Week 3 - Thursday: Matrix, variables, secrets, caching and artifacts
## Today's Goal
Make pipelines test many combinations at once (matrix), handle configuration and secrets safely, run faster with caching, and keep or pass files with artifacts.

## Plan (checklist)
- [x] Learn matrix, `include`/`exclude`, `fail-fast`, `max-parallel`
- [x] Learn `env`, `vars`, secrets, `GITHUB_TOKEN`, Environments and OIDC
- [x] Learn caching (`key`, `hashFiles`, `restore-keys`) and artifacts (upload, download, retention)
- [x] Write three workflows, unit tests and a matrix preview tool
- [x] Validate everything locally and simulate the workflow steps
- [x] Write notes in `documentation/`
- [x] Log one error in `troubleshooting/`
- [x] Commit and push with a clear message

## What I Did
- Built `matrix.yml`: Python 3.10 to 3.13 on Ubuntu 22.04 and 24.04, plus an experimental 3.14 that may fail (9 jobs), and a 5-job table that checks `cidr.sh` for /8, /16, /24, /26 and /30.
- Wrote `tests/test_backend.py`, 5 unit tests for the Week 2 Python backend using only the standard library.
- Wrote `matrix_preview.py` to show how many jobs a matrix creates, and checked it against the GitHub documentation's examples (9 and 6 jobs). It also had a bug with include-only matrices that I found and fixed.
- Wrote `secrets-vars.yml` (variables, a secret checked without printing it, masking, an Environment, `GITHUB_TOKEN` with `gh`).
- Wrote `cache-artifacts.yml` (cache the `actionlint` binary, lint workflows, upload a report, download it in a second job).
- Checked the current action versions (`checkout` v7, `cache` v6, `upload-artifact` v7, `download-artifact` v8, `setup-python` v7) instead of copying old ones.
- Validated with `actionlint` and `yamllint`, ran the tests, and simulated the runner's download and lint steps, including a failing case that still writes the report.

## Files in this folder
| File | What it does |
|---|---|
| [`workflows/matrix.yml`](workflows/matrix.yml) | Matrix of Python and Ubuntu versions, and a table-driven `cidr.sh` test |
| [`workflows/secrets-vars.yml`](workflows/secrets-vars.yml) | Variables, secrets, masking, Environment, `GITHUB_TOKEN` (manual run) |
| [`workflows/cache-artifacts.yml`](workflows/cache-artifacts.yml) | Cache, report artifact, and passing it to a second job |
| [`tests/test_backend.py`](tests/test_backend.py) | Unit tests for `backend.py` |
| [`matrix_preview.py`](matrix_preview.py) | Prints the jobs a workflow's matrix will create |

Copy the workflows to `.github/workflows/` in the repository root of DevOps-Trip.

## Lab Summary
```bash
python3 matrix_preview.py workflows/matrix.yml
python3 -m unittest -v week-03-git-github-actions/4-thu/tests/test_backend.py     # from the repo root
cp workflows/*.yml ~/DevOps-Trip/.github/workflows/
../3-wed/ci_local.sh
```
Result: 9 + 5 matrix jobs ran in parallel, the cache went from a miss to a hit on the second run, and the lint report was downloaded by a second job. (Add screenshots in `documentation/images/`.)

## What I Learned
- A matrix writes the job once and tests every combination; `fail-fast: false` shows all failures.
- An include-only matrix is a neat table of test cases.
- Secrets go into single steps through `env:`, are empty for fork PRs, and are better replaced by OIDC for cloud access.
- Cache keys need a hash of the dependency file; a cache is an optimisation, not a data store.
- Steps after a failure are skipped, so upload steps that save evidence need `if: always()`.
- Check action versions instead of copying old ones, and let Dependabot update them.

## Errors Faced
- `show-report` failed with a missing artifact because the upload step was skipped after a failed step: see [`troubleshooting/error-01.md`](troubleshooting/error-01.md)
- Also fixed: a wrong job count in my matrix preview, and `actionlint` needing a Git repository.

## Notes
Full notes: [`documentation/notes.md`](documentation/notes.md)

## Tomorrow
Day 5: reusable workflows and composite actions, so one pipeline can be shared by many repositories.