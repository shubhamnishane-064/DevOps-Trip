# Git, GitHub and Actions | Week 3 - Friday: Reusable workflows and composite actions

## Today's Goal
Stop copying pipeline code: package steps as **composite actions** and whole jobs as a **reusable workflow**, and call them from other workflows.

## Plan (checklist)
- [x] Learn when to use a composite action, a reusable workflow, or neither
- [x] Build two composite actions (`lint-shell`, `setup-actionlint`)
- [x] Build a reusable workflow (`shell-quality.yml`) and a caller (`ci-caller.yml`)
- [x] Keep the logic in a script I can test by hand (`lint_shell.sh`)
- [x] Validate with `actionlint` and test the script
- [x] Write notes in `documentation/`
- [x] Log one error in `troubleshooting/`
- [x] Commit and push with a clear message

## What I Did
- Learned the difference: a composite action packages **steps** and runs inside the caller's job; a reusable workflow packages **jobs** and runs on its own runners.
- Wrote `lint-shell`: installs ShellCheck if needed, runs `bash -n` and ShellCheck on every `.sh` file under a path, and outputs the number of scripts checked.
- Wrote `setup-actionlint`: downloads a pinned `actionlint` with `actions/cache` and puts it on the PATH.
- Wrote `shell-quality.yml` with typed inputs (`path`, `severity`, `lint-workflows`) and an output (`scripts-checked`), and `ci-caller.yml`, which calls it normally, once per folder with a matrix, and reads its output. A cross-repository call is included as a comment.
- Learned the gotchas: `shell:` on every composite run step, no `secrets` context in composite actions, permissions can only shrink in a called workflow, and `./` paths inside a cross-repo reusable workflow point at the **caller's** workspace.
- Kept the real logic in `lint_shell.sh` and called it with `bash`, so it is testable and not dependent on the executable bit.
- Validated everything with `actionlint` and `yamllint`; `actionlint` also caught typos in `with:` for both mechanisms and a missing required input.

## Files in this folder
| File | What it does |
|---|---|
| [`actions/lint-shell/action.yml`](actions/lint-shell/action.yml) | Composite action: lint shell scripts, output the count |
| [`actions/lint-shell/lint_shell.sh`](actions/lint-shell/lint_shell.sh) | The script behind it (runnable by hand) |
| [`actions/setup-actionlint/action.yml`](actions/setup-actionlint/action.yml) | Composite action: install actionlint with a cache |
| [`workflows/shell-quality.yml`](workflows/shell-quality.yml) | Reusable workflow (`workflow_call`) |
| [`workflows/ci-caller.yml`](workflows/ci-caller.yml) | Calls the reusable workflow (plain, matrix, with its output) |

Copy `actions/*` to `.github/actions/` and `workflows/*.yml` to `.github/workflows/` in the **repository root**.

## Lab Summary
```bash
cd ~/DevOps-Trip
mkdir -p .github/actions .github/workflows
cp -r week-03-git-github-actions/5-fri/actions/* .github/actions/
cp week-03-git-github-actions/5-fri/workflows/*.yml .github/workflows/
bash .github/actions/lint-shell/lint_shell.sh week-01-linux-bash warning
./week-03-git-github-actions/3-wed/ci_local.sh
```
Result: the caller started the reusable workflow, which ran the composite actions; the nested jobs and the output were visible in the Actions tab. (Add screenshots in `documentation/images/`.)

## What I Learned
- One fix in a shared piece updates every pipeline that uses it.
- Composite actions run on the caller's runner; reusable workflows get their own.
- Inputs typos: a reusable workflow rejects them, but a composite action only warns and uses the default, so validate with `actionlint`.
- Keep logic in a testable script and make the YAML a thin wrapper.
- Version shared pieces (`v1` tags), and pin SHAs for code I don't control.

## Errors Faced
- A typo in `with:` (`severty`) is a hard error for a reusable workflow but a silent warning for a composite action: see [`troubleshooting/error-01.md`](troubleshooting/error-01.md)

## Notes
Full notes: [`documentation/notes.md`](documentation/notes.md)

## Tomorrow
Day 6: branch protection and required status checks, semantic versioning and automatic releases (tags, changelogs, GitHub Releases).