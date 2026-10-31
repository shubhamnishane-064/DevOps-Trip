# Notes: Day 2 - Pull Requests, Code Review and Commit Messages

**Week 3 | Tuesday** | Topic: how teams get changes into `main` safely

---

## 1. What is a Pull Request (PR)?
- A **pull request** is a request to merge my branch into another branch (usually `main`), with a place to **discuss and review** the change first.
- It is a GitHub (GitLab calls it "merge request") feature, not a Git command. Git only has branches and merges.
- A PR gives the team: a review of the diff, a record of why the change was made, and automatic **CI checks** (Wednesday onwards).

**Why not push straight to `main`?**
`main` should always work. PRs catch bugs, share knowledge, and make sure tests pass before code lands.

---

## 2. The Whole Flow

```
1. git switch -c feature/greeting          create a branch from an up-to-date main
2. edit, test, commit (small commits)      git commit -m "feat: friendlier greeting"
3. git push -u origin feature/greeting     publish the branch
4. open the PR on GitHub                   base: main  <-  compare: feature/greeting
5. CI runs, reviewers comment              fix things with NEW commits, push again
6. approvals + green checks                 
7. merge (squash / merge / rebase)         then delete the branch
8. git switch main && git pull             update my local main
```

**Fork vs branch**
| | Branch in the same repo | Fork |
|---|---|---|
| Used for | My team's repository (I have write access) | Open source (I do not have write access) |
| How | Push a branch to `origin` | Fork on GitHub, push to my fork, PR from my fork to `upstream` |

Fork setup:
```bash
git remote add upstream https://github.com/ORIGINAL/repo.git
git fetch upstream
git switch main && git merge upstream/main      # keep my fork current
```

---

## 3. Making a Good PR

| Do | Why |
|---|---|
| **Keep it small** (about 400 changed lines or fewer) and about one thing | Small PRs get reviewed faster and more carefully |
| Write a clear **title** in Conventional Commit style | `fix(api): handle empty request body` |
| Explain **why**, not only what | Reviewers need the reason |
| Say **how you tested** it | Builds trust |
| Link the issue: `Closes #12` | The issue closes itself on merge |
| Add screenshots or output for visible changes | Easier to review |
| Open a **Draft PR** while still working | Shows progress, blocks merging by accident |
| Read **my own diff** first | I catch silly mistakes before others see them |

Template: `templates/pull_request_template.md`. Put it in `.github/pull_request_template.md`, and GitHub pre-fills every new PR with it.

---

## 4. Code Review

### What the reviewer looks at
Correctness and edge cases, tests, security (secrets, input checks), readability, simplicity, and for infrastructure code: is it safe to run twice, is there logging, can it be rolled back? The full list is in `templates/review_checklist.md`.

### Review outcomes on GitHub
| Choice | Meaning |
|---|---|
| **Comment** | General feedback, no decision |
| **Approve** | Good to merge |
| **Request changes** | Blocking problems must be fixed |

### How to give feedback
- Be **specific** and kind. Comment on the code, not the person.
- Prefer questions: "What happens if the file is empty?"
- Label the weight: `nit:` (tiny), `suggestion:`, `question:`, `blocking:`.
- Use a **suggestion block** so the author can apply the fix with one click:
  ````
  ```suggestion
  greeting: welcome
  ```
  ````
- Say what is good too.

### How to receive feedback
- Don't take it personally. The review is about the code.
- Reply to **every** comment: fix it, or explain why not. Then click **Resolve conversation**.
- Push **new commits** to address feedback. Avoid rewriting (force-pushing) history while someone is reviewing, unless you agreed.
- Ask when something is unclear.

> For my resume: this is the "participate in code reviews" skill. To have real evidence, open PRs on my own repos, review a friend's PR, or contribute a small fix (docs or typos count) to an open-source project.

---

## 5. Ways to Merge a PR (GitHub buttons)

| Option | Result on `main` | Use when |
|---|---|---|
| **Create a merge commit** | All commits + a merge commit | I want the full history |
| **Squash and merge** | **One** new commit for the whole PR | Branch has messy "fix typo" commits (most teams' default) |
| **Rebase and merge** | Commits replayed one by one, no merge commit | I want a straight history and my commits are clean |

Real example from my practice run: two commits on a branch were squashed into one on `main`:
```
* 5486733 feat: friendlier greeting and app rename (#1)    <- the squash commit
* 16a7b54 feat: welcome message
* 7e7dfdc chore: add config
```
After merging: **delete the branch** (GitHub has a button), then `git fetch --prune` and `git branch -d feature/greeting` locally.

---

## 6. "This branch has conflicts" - Fix It in a PR

A conflict appears when `main` changed the same lines after I branched. Update my branch with `main`, fix the conflict, and push.

**Option A: rebase (clean history)**
```bash
git fetch origin
git rebase origin/main            # resolve conflicts commit by commit
# edit the file, remove markers
git add config.txt
git rebase --continue
git push --force-with-lease       # needed because the history was rewritten
```
**Option B: merge main into my branch (no rewriting)**
```bash
git fetch origin
git merge origin/main             # resolve once, then commit
git push
```

| | Rebase | Merge main in |
|---|---|---|
| History | Straight | Has a merge commit |
| Push | Needs `--force-with-lease` | Normal push |
| Conflicts | May need fixing **once per commit** | Fixed **once** |
| Safe if others share my branch? | No | Yes |

**Real output from my practice run** (my branch had 2 commits, so the same conflict came up twice):
```
$ git rebase origin/main
Rebasing (1/2)
CONFLICT (content): Merge conflict in config.txt
error: could not apply c7a2ade... feat: friendlier greeting

$ git rebase --continue
Rebasing (2/2)
CONFLICT (content): Merge conflict in config.txt
error: could not apply 66ccbc7... feat: rename app after review
```
Tip: if a branch has many commits touching the same lines, **squash first** (`git rebase -i`) or use Option B, to avoid solving the same conflict repeatedly.

GitHub's web editor can fix simple conflicts. Always run the tests afterwards.

---

## 7. Push Rejected (the most common PR error)

```
$ git push
 ! [rejected]        main -> main (fetch first)
error: failed to push some refs ...
hint: Updates were rejected because the remote contains work that you do not have locally.
```
```
 ! [rejected]        feature/greeting -> feature/greeting (non-fast-forward)
hint: Updates were rejected because the tip of your current branch is behind its remote counterpart.
```
| Message | Meaning | Fix |
|---|---|---|
| `(fetch first)` | The remote has commits I don't have | `git pull --rebase`, then `git push` |
| `(non-fast-forward)` after I rebased or amended | My history differs from the remote's | `git push --force-with-lease` (only on **my own** branch) |

Real fix from my run:
```
$ git pull --rebase origin main
Successfully rebased and updated refs/heads/main.
$ git push -q origin main            <- works now
```
**Never** `--force` on `main` or on a branch other people use. `--force-with-lease` refuses if the remote moved since my last fetch.

---

## 8. Commit Messages That Help

### The format (Conventional Commits)
```
<type>(<scope>): <short description>

<body: explain WHY, wrap at about 72 characters>

<footer: Closes #12>
```
| Type | Use for | Version effect (semantic versioning) |
|---|---|---|
| `feat` | New feature | **minor** (1.2.0 -> 1.3.0) |
| `fix` | Bug fix | **patch** (1.2.0 -> 1.2.1) |
| `docs` | Documentation only | none |
| `style` | Formatting, no logic change | none |
| `refactor` | Restructure, same behaviour | none |
| `perf` | Faster | patch |
| `test` | Add or fix tests | none |
| `build` / `ci` | Build system, pipelines | none |
| `chore` | Maintenance | none |
| `revert` | Undo an earlier commit | depends |

**Breaking change:** `feat(api)!: drop the v1 endpoint` or a footer `BREAKING CHANGE: ...` means a **major** version (1.x -> 2.0).

### Good habits
- First line: **under about 50 to 72 characters**, imperative mood ("add", not "added"), no full stop.
- One logical change per commit.
- Body answers **why**, not what (the diff shows what).

| Bad | Good |
|---|---|
| `update` | `fix(health): ignore tmpfs in disk check` |
| `fixed stuff` | `fix(backup): keep 7 days of archives` |
| `WIP` (in a PR to main) | `feat(lb): add backup upstream server` |

### My checker
`commit_lint.sh` validates the format and can run as a **Git hook** or on a range of commits:
```bash
./commit_lint.sh "feat: add login"                  # OK
./commit_lint.sh "added login."                     # FAIL (format, trailing period)
./commit_lint.sh --range origin/main..HEAD          # check every commit of a PR
cp commit_lint.sh .git/hooks/commit-msg             # block bad messages as I commit
```
Real test: with the hook installed, `git commit -m "added a file"` was **blocked** (exit code 1, no commit made), and `git commit -m "feat: add a file"` worked. On Wednesday this same idea runs in **CI**, so the rule is enforced for everyone.

### Fixing messages and history before a PR
```bash
git commit --amend -m "fix: better message"      # last commit only
git rebase -i HEAD~3                             # reword / squash / drop older commits
git commit --fixup <hash>                        # a "fix" for an earlier commit
git rebase -i --autosquash origin/main           # puts fixups in the right place
```

---

## 9. Other GitHub PR Features

| Feature | What it does |
|---|---|
| **Draft PR** | Work in progress; can't be merged until marked ready |
| **Reviewers / Assignees / Labels** | Who reviews, who owns it, how to filter |
| **CODEOWNERS** (`.github/CODEOWNERS`) | Automatically requests review from the owners of the changed files |
| **Required reviews and status checks** | Part of branch protection (Saturday) |
| **Issues linking** | `Closes #12`, `Fixes #12` in the description |
| **Resolve conversation** | Marks a comment thread as done |
| **Auto-merge** | Merges automatically when checks pass and approvals exist |
| **Dependabot PRs** | Automatic PRs that update dependencies |

---

## 10. GitHub CLI (`gh`)

```bash
gh auth login                                       # sign in once
gh repo create devops-lab --public --source=. --push
gh pr create --fill --base main                     # open a PR using my commit message
gh pr create --title "feat: add lb" --body "Why: ..." --draft
gh pr list
gh pr view 12 --web                                 # open in the browser
gh pr checkout 12                                   # fetch someone's PR branch locally
gh pr diff 12
gh pr checks 12                                     # CI status
gh pr review 12 --approve
gh pr review 12 --request-changes --body "Please add a test"
gh pr merge 12 --squash --delete-branch
gh issue create --title "Bug: backup fails" --body "Steps..."
```

---

## 11. Lab (Hands-on)

**Part 1: local simulation (no GitHub needed)**
```bash
./pr_playground.sh                     # alice, bob and a shared remote in /tmp/pr-playground
cd /tmp/pr-playground/alice
git log --oneline --graph --all
```
Read each of the 7 steps: open PR, review, `main` moves on, conflict by rebase, rejected push, squash merge, `fetch first` rejection.

**Part 2: a real PR on GitHub (my own practice repo)**
```bash
git switch -c docs/add-contributing
echo "# Contributing" > CONTRIBUTING.md
git add CONTRIBUTING.md
./commit_lint.sh "docs: add contributing guide"
git commit -m "docs: add contributing guide"
git push -u origin docs/add-contributing
gh pr create --fill --base main            # or use the button on GitHub
```
Then:
1. Copy `templates/pull_request_template.md` to `.github/pull_request_template.md`, push it, and open another PR to see it pre-filled.
2. Ask a friend to review, or review one of my own with a self-comment, using a `suggestion` block.
3. **Squash and merge**, delete the branch, then `git switch main && git pull && git fetch --prune`.
4. Cause a conflict on purpose with two branches changing the same line, and fix it in the PR.

Install the hook in a practice repo and try bad and good messages:
```bash
cp commit_lint.sh .git/hooks/commit-msg && chmod +x .git/hooks/commit-msg
git commit -m "added a file"           # blocked
git commit -m "feat: add a file"       # works
```

Result: (write what happened, add screenshots of the PR, a review comment and the merged result)

---

## 12. Errors Faced Today
- Example: `! [rejected] main -> main (fetch first)` / `non-fast-forward`
- Cause: the remote had commits I did not have (or I rewrote my branch's history)
- Fix: `git pull --rebase` then push; for my own rebased branch use `--force-with-lease`

Full story: `troubleshooting/error-01.md`

---

## 13. Quick Q&A (for interviews)

**Q: What is a pull request?**
A request to merge my branch into another, with a place to review and discuss the diff and run automated checks first. It keeps `main` stable.

**Q: Walk me through your workflow for a change.**
Update `main`, create a feature branch, make small commits with clear messages, push, open a PR with a description of what, why and how I tested, respond to review with new commits, wait for green CI and approval, squash and merge, delete the branch, then pull `main`.

**Q: Merge commit vs squash vs rebase merge?**
Merge commit keeps all commits plus a merge commit. Squash turns the whole PR into one commit, which keeps `main` tidy. Rebase merge replays commits one by one for a straight history.

**Q: What makes a good PR?**
Small, one purpose, a clear title and description (why and how tested), linked issue, passing tests, no secrets.

**Q: What do you look for in a code review?**
Correctness and edge cases, tests, security (secrets, input validation), readability, and for infrastructure code whether it is idempotent, logged and reversible. I give specific, kind feedback and label how important each point is.

**Q: How do you handle review comments you disagree with?**
Explain my reasoning politely, with evidence, and ask for their view. If we still differ, I follow the team's decision or ask a third person, and I keep the discussion on the code.

**Q: Your PR says "branch has conflicts". What do you do?**
Fetch, then rebase on or merge `origin/main`, fix the conflicts, run the tests, and push (with `--force-with-lease` if I rebased). I keep PRs small and update often to avoid it.

**Q: `git push` says "rejected (fetch first)". Why?**
Someone pushed commits I don't have. I run `git pull --rebase`, fix any conflict, and push again.

**Q: Why `--force-with-lease` instead of `--force`?**
It only overwrites the remote if it still matches what I last fetched, so I can't erase a teammate's new commits.

**Q: What are Conventional Commits and why use them?**
A format like `feat(scope): description`. It makes history readable and lets tools choose the next version (fix = patch, feat = minor, breaking = major) and write changelogs automatically.

**Q: How do you stop bad commit messages or broken code reaching `main`?**
Locally with Git hooks, and for everyone with CI checks and branch protection (required reviews and passing status checks), which we set up later this week.

**Q: Fork vs branch workflow?**
In a team repo I push a branch to `origin`. In open source I fork, push to my fork, and open a PR to the original repository, keeping my fork updated through an `upstream` remote.

---

## 14. Summary in 3 lines
1. A PR is how changes reach `main`: small branch, clear description, review, green CI, then squash and merge and delete the branch.
2. Conflicts and rejected pushes are normal: `fetch`, rebase or merge `origin/main`, fix, test, and push (`--force-with-lease` only on my own rebased branch).
3. Good commit messages (`feat:`, `fix:`, `docs:`) make history readable and drive automatic versioning, and I can enforce them with a hook or CI.