# Git, GitHub and Actions | Week 3 - Monday: Git internals, branching, merge and rebase

## Today's Goal
Understand how Git really stores data, so that branching, merging, rebasing and undoing mistakes make sense, and practise them safely.

## Plan (checklist)
- [x] Learn the concept (three areas, objects, branches as pointers)
- [x] Hands-on lab: branches, merge, conflict, rebase, reflog recovery
- [x] Write `git_playground.sh`, a guided practice repo
- [x] Write notes in `documentation/`
- [x] Log one error in `troubleshooting/`
- [x] Commit and push with a clear message

## What I Did
- Set up Git identity, default branch and an SSH key for GitHub.
- Learned the three areas: working directory, staging area, repository, and read `git status -s` codes (` M`, `M `, `UU`).
- Looked inside Git with `git cat-file -p` and saw a commit, a tree and a blob, and that a branch is a file holding one commit hash.
- Created branches, made a fast-forward and a three-way merge, and read the history with `git log --oneline --graph --all`.
- Caused a merge conflict on purpose, read the markers, and resolved it.
- Rebased a branch onto `main` and compared the straight history with the merge history.
- Deleted a commit with `git reset --hard` and recovered it with `git reflog`.
- Learned `reset` vs `revert`, `stash`, `cherry-pick`, `commit --amend`, `--force-with-lease` and Conventional Commits.


## Lab Summary
```bash
./git_playground.sh
cd /tmp/git-playground
git log --oneline --graph --all
git cat-file -p HEAD
git reflog
```
Result: saw the commit, tree and blob objects, a three-way merge, a conflict and its resolution, a straight-line rebase, and a recovered commit. (Add screenshots in `documentation/images/`.)

## What I Learned
- A commit is a full snapshot; a branch is just a pointer to a commit.
- Merge keeps history and adds a merge commit; rebase rewrites my commits into a straight line, so never rebase shared branches.
- `reflog` can bring back "lost" commits; uncommitted changes cannot be recovered.
- Use `revert` for pushed work and `reset` only for my own local work.
- Never commit secrets; rotate them if it happens.

## Errors Faced
- `CONFLICT (content): Merge conflict` (the same line changed in two branches): see [`troubleshooting/error-01.md`](troubleshooting/error-01.md)

## Notes
Full notes: [`documentation/notes.md`](documentation/notes.md)

## Tomorrow
Day 2: pull requests, code review, resolving conflicts in a PR, and writing good commit messages and PR descriptions.