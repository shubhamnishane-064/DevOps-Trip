# Git, GitHub and Actions | Week 3 - Wednesday: GitHub Actions basics

## Today's Goal
Understand how GitHub Actions works (events, workflows, jobs, steps, runners) and build a first CI pipeline that lints and tests my scripts and checks commit messages on pull requests.

## Plan (checklist)
- [x] Learn the vocabulary, YAML rules and triggers
- [x] Write `hello.yml`, `triggers-demo.yml` and `ci.yml`
- [x] Validate the workflows locally with `actionlint` and `yamllint`
- [x] Write `ci_local.sh` to run the same checks before pushing
- [x] Write notes in `documentation/`
- [x] Log one error in `troubleshooting/`
- [x] Commit and push with a clear message

## What I Did
- Learned the six words: workflow, event, job, step, action, runner; and that a runner starts empty, so `actions/checkout` comes first.
- Learned YAML gotchas (tabs, indentation, `: ` inside values, quoting versions like `'3.10'`).
- Wrote three workflows: `hello.yml` (basics and contexts), `triggers-demo.yml` (push filters, pull requests, manual inputs, schedule, `needs`, `if`), and `ci.yml` (lint, test, commit-message check, summary).
- Used security basics: `permissions: contents: read`, `concurrency`, `timeout-minutes`, and passing values through `env:` instead of pasting them into scripts.
- Checked the workflows with `actionlint` (real catches: untrusted input in scripts, a misspelled action input, a `needs:` typo) and `yamllint`.
- Ran ShellCheck over all my scripts and fixed a real warning in `git_playground.sh`.
- Built `ci_local.sh`, which runs the CI checks on my computer, and tested clean and failing cases.
- Reproduced and fixed a `Permission denied` (exit code 126) caused by a missing executable bit in Git.

## Files in this folder
| File | What it does |
|---|---|
| [`workflows/hello.yml`](workflows/hello.yml) | First workflow: runner info, contexts, step summary |
| [`workflows/triggers-demo.yml`](workflows/triggers-demo.yml) | Triggers, filters, manual inputs, schedule, `needs`, `if` |
| [`workflows/ci.yml`](workflows/ci.yml) | CI: bash -n + ShellCheck, script tests, commit message check on PRs, summary |
| [`ci_local.sh`](ci_local.sh) | Runs the CI checks locally; exit code 0 means safe to push |

To use a workflow, copy it to `.github/workflows/` in the **repository root** of DevOps-Trip.

## Lab Summary
```bash
cd ~/DevOps-Trip
mkdir -p .github/workflows
cp week-03-git-github-actions/3-wed/workflows/ci.yml .github/workflows/
./week-03-git-github-actions/3-wed/ci_local.sh origin/main
git add .github && git commit -m "ci: add shell lint and script tests" && git push
```
Result: the CI ran on GitHub, I made it fail on purpose (a bad script, a bad commit message), read the logs, fixed it, and watched it turn green. (Add screenshots in `documentation/images/`.)

## What I Learned
- Jobs run in parallel on fresh machines unless `needs:` is used; steps run in order.
- Never paste untrusted values (PR title, branch name) into `run:`; use `env:`.
- Validate workflows locally with `actionlint` and run the CI checks before pushing.
- Exit code 126 means "cannot execute" (permissions), 127 means "command not found".
- Git tracks the executable bit (`100755`); fix it with `git update-index --chmod=+x`.
- Action versions change quickly (`actions/checkout` is on v7), so let Dependabot update them.

## Errors Faced
- `./deploy.sh: Permission denied` in CI (exit code 126, missing executable bit): see [`troubleshooting/error-01.md`](troubleshooting/error-01.md)
- `mapping values are not allowed in this context` (YAML): described in the same file

## Notes
Full notes: [`documentation/notes.md`](documentation/notes.md)

## Tomorrow
Day 4: matrix builds, secrets and variables, caching, and artifacts in GitHub Actions.