# Error Log: git push rejected - "fetch first" / "non-fast-forward"

## 1. Symptom (what I saw)
Case A, pushing `main` after a teammate pushed first:
```
$ git push
To /tmp/pr-playground/origin.git
 ! [rejected]        main -> main (fetch first)
error: failed to push some refs to '/tmp/pr-playground/origin.git'
hint: Updates were rejected because the remote contains work that you do not
hint: have locally. This is usually caused by another repository pushing to
hint: the same ref. If you want to integrate the remote changes, use
hint: 'git pull' before pushing again.
```
Case B, pushing my feature branch after I rebased it onto `main`:
```
$ git push
 ! [rejected]        feature/greeting -> feature/greeting (non-fast-forward)
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart.
```

## 2. Context (what I was doing)
- **A:** Two people worked on `main`. My teammate (alice) pushed her commit first, then I tried to push mine.
- **B:** My PR branch had conflicts with `main`, so I rebased it onto `origin/main` and tried to push it again.

## 3. Investigation (how I debugged)
- [x] Read the word in brackets: `fetch first` or `non-fast-forward`
- [x] Compared my branch with the remote
- [x] Decided whether the remote has commits I need (A) or whether I rewrote my own history (B)

Commands tried:
```bash
git fetch origin
git status
# Your branch and 'origin/main' have diverged,
# and have 1 and 1 different commits each, respectively.     -> case A

git log --oneline --graph --all
# * 770ae68 docs: add docs notes          <- my commit
# | * d93a85e ci: add ci notes             <- the remote's new commit
# |/

git log --oneline origin/feature/greeting..feature/greeting    # case B: my rebased commits
git log --oneline feature/greeting..origin/feature/greeting    # case B: the old commits on the remote
```

## 4. Root Cause
Git only lets a push move the remote branch **forward** along a straight line (a fast-forward).
- **A:** The remote branch contained a commit I didn't have, so my push would have thrown it away. Git refused.
- **B:** Rebasing **rewrote** my commits (new hashes), so my branch and the remote's copy no longer shared the same history. That is expected after a rebase.

## 5. Fix
**Case A (shared branch): bring in the remote work, then push**
```bash
git pull --rebase origin main        # replay my commit on top of the new remote commit
git push origin main                 # now it is a fast-forward
git log --oneline --graph -5
# * 770ae68 docs: add docs notes
# * d93a85e ci: add ci notes
```
**Case B (my own PR branch, after a rebase): safe force push**
```bash
git push --force-with-lease
# + 66ccbc7...ac401ac feature/greeting -> feature/greeting (forced update)
```
`--force-with-lease` only overwrites the remote if it still matches what I last fetched, so I can't erase someone's new commits.

## 6. Prevention / Lesson Learned
- `git pull --rebase` (or `git fetch` and rebase) **before** pushing and before opening a PR.
- Keep PR branches short-lived and **small**, so conflicts and rejections are rare.
- **Never** use `git push --force` on `main` or on a branch other people use. Use `--force-with-lease`, and only on my own branch.
- Set `git config --global pull.rebase true` so `git pull` keeps history straight.
- Tell teammates before rewriting a branch they might have checked out.
- Branch protection (Saturday) can block force pushes to `main` completely.
