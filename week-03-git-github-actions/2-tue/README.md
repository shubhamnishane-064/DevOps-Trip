# Git, GitHub and Actions | Week 3 - Tuesday: Pull requests, code review and commit messages

## Today's Goal
Learn how teams get changes into `main` safely: the pull request workflow, code review, conflict handling, merge options and good commit messages.

## Plan (checklist)
- [x] Learn the PR flow, fork vs branch, merge options, review etiquette
- [x] Simulate a two-person PR workflow locally (`pr_playground.sh`)
- [x] Write `commit_lint.sh` (Conventional Commits checker and Git hook)
- [x] Write a PR template and a review checklist
- [x] Write notes in `documentation/`
- [x] Log one error in `troubleshooting/`
- [x] Commit and push with a clear message

## What I Did
- Learned the full PR flow: branch, small commits, push, open PR, review, new commits for feedback, green checks, merge, delete branch.
- Compared the three GitHub merge options (merge commit, squash and merge, rebase and merge).
- Simulated a team: alice opened a "PR", bob reviewed the diff, `main` moved on, alice resolved a conflict with a rebase, force-pushed with `--force-with-lease`, squash-merged, and bob fixed a `fetch first` rejection with `git pull --rebase`.
- Saw that rebasing a branch with two commits made me resolve the same conflict twice, and learned to squash first or merge `main` in instead.
- Learned Conventional Commits and how `fix`, `feat` and breaking changes map to patch, minor and major versions.
- Built `commit_lint.sh` and installed it as a `commit-msg` hook: it blocked `added a file` and allowed `feat: add a file`.
- Wrote a PR template and a code review checklist, and learned the `gh` CLI commands.

## Files in this folder
| File | What it does |
|---|---|
| [`pr_playground.sh`](pr_playground.sh) | Simulates a PR workflow between two people and a shared remote, in 7 printed steps |
| [`commit_lint.sh`](commit_lint.sh) | Checks commit messages (one message, a file as a Git hook, or a range of commits) |
| [`templates/pull_request_template.md`](templates/pull_request_template.md) | Copy to `.github/pull_request_template.md` |
| [`templates/review_checklist.md`](templates/review_checklist.md) | What to check as an author and as a reviewer, and how to write comments |

## Lab Summary
```bash
./pr_playground.sh
./commit_lint.sh "feat: add login page"
./commit_lint.sh "added login page"
cp commit_lint.sh /path/to/practice-repo/.git/hooks/commit-msg
```
Result: followed the PR workflow end to end, hit and fixed both kinds of rejected push, and enforced commit message rules with a hook. (Add screenshots in `documentation/images/`, and a real PR from my own practice repo.)

## What I Learned
- A PR is a review and CI gate in front of `main`; small, well-described PRs get merged fastest.
- Squash and merge keeps `main` tidy; a rebased branch needs `--force-with-lease`, never plain `--force`.
- `fetch first` means someone pushed before me: `git pull --rebase`, then push.
- Good review comments are specific, kind and labelled (`nit:`, `blocking:`), and every comment gets an answer.
- Conventional Commit messages make history readable and let tools pick version numbers.

## Errors Faced
- `! [rejected] ... (fetch first)` and `(non-fast-forward)`: see [`troubleshooting/error-01.md`](troubleshooting/error-01.md)

## Notes
Full notes: [`documentation/notes.md`](documentation/notes.md)

## Tomorrow
Day 3: GitHub Actions basics: workflows, jobs, steps, triggers and runners, and running `commit_lint.sh` and a shell check in CI.