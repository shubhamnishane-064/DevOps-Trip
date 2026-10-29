# Notes: Day 1 - Git Internals, Branching, Merge and Rebase

**Week 3 | Monday** | Topic: how Git really works, so branching, merging and undoing mistakes make sense

---

## 1. Git vs GitHub
- **Git** = a tool on my computer that records the **history** of my files. It works offline.
- **GitHub** = a website that hosts Git repositories, and adds pull requests, issues, code review and **Actions** (CI/CD).
- Git is **distributed**: every clone has the full history, so there is no single point of failure.

Why use it: go back to any earlier version, work on features in parallel (branches), see who changed what and why, and review code before it is merged.

---

## 2. First-Time Setup

```bash
git config --global user.name  "Shubham Nishane"
git config --global user.email "shubhamnishane108@gmail.com"
git config --global init.defaultBranch main
git config --global pull.rebase true          # optional: keep history clean on pull
git config --global core.editor "nano"
git config --list --show-origin               # where each setting comes from
```
Settings live in three levels: **system** < **global** (`~/.gitconfig`) < **local** (`.git/config`). The more local one wins.

**GitHub login:** use an SSH key (Week 1, Day 6) or a personal access token.
```bash
ssh-keygen -t ed25519 -C "shubhamnishane108@gmail.com"
cat ~/.ssh/id_ed25519.pub        # paste into GitHub -> Settings -> SSH keys
ssh -T git@github.com            # "Hi <name>! You've successfully authenticated"
```

---

## 3. The Three Areas (the most important picture)

```
 Working directory  --git add-->  Staging area (index)  --git commit-->  Repository (.git)
 (my files)                       (what the next commit will contain)    (saved history)
        <------------------------ git restore / git checkout ------------------------
```

| Area | Meaning | See it with |
|---|---|---|
| Working directory | The files I edit | `git status` |
| Staging area | A draft of the next commit | `git diff --staged` |
| Repository | Permanent commits | `git log` |

Real output from my practice run:
```
$ git status -s
 M notes.txt            <- modified, NOT staged (space, then M)
$ git add notes.txt
$ git status -s
M  notes.txt            <- staged (M, then space)
```
`UU` means a merge conflict (both sides modified).

---

## 4. Everyday Commands

```bash
git init                         # start a repo in this folder
git clone <url>                  # copy a remote repo
git status                       # what changed?
git add file.txt                 # stage one file
git add -p                       # stage piece by piece (review while staging)
git commit -m "feat: add login"  # save a snapshot
git log --oneline --graph --all  # history as a picture
git diff                         # unstaged changes
git diff --staged                # staged changes
git show <commit>                # one commit in detail
git restore file.txt             # throw away my edits in a file (cannot be undone!)
git restore --staged file.txt    # unstage, keep my edits
git rm file.txt / git mv a b     # delete / rename and stage it
git commit --amend               # fix the last commit (message or content)
git stash / git stash pop        # put changes aside, bring them back
```

### `.gitignore` (files Git should never track)
```
*.pem
.env
*.log
__pycache__/
node_modules/
.terraform/
*.tfstate
.lab/
```
**Never commit secrets** (`.pem` keys, `.env`, tokens, passwords). If it happens, **rotate the secret immediately**, because deleting the file in a new commit does not remove it from history.

---

## 5. How Git Stores Data (internals)

Git is a **content-addressed database**. Everything is an *object* in `.git/objects`, named by the hash of its content.

| Object | Stores | Like |
|---|---|---|
| **blob** | The content of one file | the file |
| **tree** | A folder: names, modes and the hashes of blobs and other trees | the folder |
| **commit** | A pointer to a tree (the snapshot) + parent commit + author + message | a saved version |
| **tag** | A name for a commit (releases) | a label |

A commit is a **full snapshot** of the project, not a list of changes. Unchanged files are shared between commits, so it stays small.

**Real output from my practice run:**
```
$ git cat-file -p HEAD                    <- the commit
tree 87ee75ad134a458a58b7d048c63f6e88dea893ac
author Practice User <practice@example.com> 1793255114 +0000
committer Practice User <practice@example.com> 1793255114 +0000

first commit

$ git cat-file -p 87ee75a                 <- the tree (folder listing)
100644 blob 8d0e41234f24b6da002d962a26c2495ea16a425f	notes.txt

$ git cat-file -p 8d0e412                 <- the blob (file content)
hello git

$ cat .git/HEAD
ref: refs/heads/main                      <- HEAD points to a branch

$ cat .git/refs/heads/main
7acc7591439cc2eaea86a02971f277b785e682f1  <- the branch is a file holding one commit hash
```

**What this means**
- A **branch** is only a small file with a commit hash, so creating one is instant and cheap.
- **HEAD** says "where I am now" (usually a branch name).
- The hash (SHA-1) changes if the content changes, so history cannot be altered silently.
- Commits form a chain through their **parent** links.

---

## 6. Branches

```bash
git branch                       # list local branches (* = current)
git branch -a                    # include remote branches
git switch -c feature/login      # create and move to a new branch
git switch main                  # move to an existing branch
git branch -d feature/login      # delete (only if merged); -D forces
git branch -m old new            # rename
```
(`git checkout` does the same jobs, but `switch` and `restore` are the newer, clearer commands.)

Branch names: `feature/login`, `fix/null-pointer`, `chore/update-deps`, `docs/readme`.

**Detached HEAD:** if HEAD points to a commit instead of a branch (for example after `git checkout <hash>`), new commits belong to no branch and can get lost. Fix: `git switch -c rescue-branch` to keep them.

```
$ git log --oneline --graph --all          (real output)
* 5ce3684 add login page                    <- feature/login
| * 0c64d05 add main file                   <- main moved on meanwhile
|/
* 2c1f1a4 add second line
* 7acc759 first commit
```

---

## 7. Merge

`git switch main` then `git merge feature/login` brings the feature in.

| Type | When | Result |
|---|---|---|
| **Fast-forward** | `main` has no new commits since I branched | The pointer just moves forward. No new commit |
| **Three-way merge** | Both branches have new commits | A **merge commit** with two parents is created |

```
*   9bba036 Merge branch 'feature/login'        <- merge commit (real output)
|\
| * 5ce3684 add login page
* | 0c64d05 add main file
|/
* 2c1f1a4 add second line
```
`git merge --no-ff` always creates a merge commit; `git merge --ff-only` refuses if a merge commit would be needed.

### Merge conflicts
Happen when **both branches changed the same lines**. Git cannot choose, so it asks me.
```
$ git merge feature/red
CONFLICT (content): Merge conflict in settings.txt
Automatic merge failed; fix conflicts and then commit the result.

$ git status -s
UU settings.txt

$ cat settings.txt
<<<<<<< HEAD
color=green              <- my current branch (main)
=======
color=red                <- the incoming branch (feature/red)
>>>>>>> feature/red
```
**How to resolve**
1. Open the file and decide the final content. Remove the three marker lines (`<<<<<<<`, `=======`, `>>>>>>>`).
2. `git add settings.txt` (this tells Git "resolved").
3. `git commit` (or `git merge --continue`).
4. To give up: `git merge --abort`.

Helpful: `git diff --name-only --diff-filter=U` lists the unresolved files. Always **run the tests after resolving**.

---

## 8. Rebase

**Rebase** takes my commits and **replays them on top of another branch**, so history is a straight line.

```
Before:                          After "git switch feature; git rebase main":
main:    A---B---C               main:    A---B---C
              \                                      \
feature:       D---E             feature:             D'---E'     (new commits, new hashes)
```
```bash
git switch feature/profile
git rebase main                  # replay my commits on the latest main
git switch main
git merge --ff-only feature/profile     # clean fast-forward
```
Real output: after the rebase the graph is a straight line with no merge commit:
```
* 5d2e247 add profile page
* da3cb11 add hotfix
*   c788157 Merge branch 'feature/red'
```

| | **Merge** | **Rebase** |
|---|---|---|
| History | Keeps the real branching, adds a merge commit | Straight line |
| Rewrites commits? | No | **Yes** (new hashes) |
| Safe on shared branches? | Yes | **No** |
| Good for | Joining finished work, keeping context | Cleaning up my own branch before a pull request |

### The golden rule
> **Never rebase commits that other people already have** (a branch already pushed and used by others). Rebase only your own local or private branch.

If a rebase conflicts: fix the file, `git add`, `git rebase --continue` (or `git rebase --abort` to cancel).

### Interactive rebase (tidy my commits before a PR)
```bash
git rebase -i HEAD~3
# pick = keep, reword = change message, squash = merge into the previous commit, drop = delete
```
After rebasing a branch that is already on GitHub (mine only):
```bash
git push --force-with-lease      # safer than --force: refuses if someone else pushed meanwhile
```

`git pull --rebase` = fetch, then replay my local commits on top of the remote ones (no extra merge commit).

---

## 9. The Undo Toolbox

| I want to... | Command | Safe? |
|---|---|---|
| Discard edits in a file | `git restore file` | Edits are lost for good |
| Unstage a file | `git restore --staged file` | Safe |
| Fix the last commit message or add a forgotten file | `git commit --amend` | Safe if not pushed |
| Undo a commit but keep the changes (staged) | `git reset --soft HEAD~1` | Safe |
| Undo a commit, keep changes unstaged | `git reset HEAD~1` (mixed) | Safe |
| Undo a commit **and delete the changes** | `git reset --hard HEAD~1` | **Dangerous** |
| Undo a commit that is **already pushed** | `git revert <hash>` | Safe: makes a new "undo" commit |
| Copy one commit onto another branch | `git cherry-pick <hash>` | Safe |
| Put work aside | `git stash`, `git stash pop` | Safe |
| Find "lost" commits | `git reflog` | A lifesaver |

**Rule:** for history that is already shared, use `revert`. Use `reset` and `rebase` only on my own unpushed work.

### Recovering with reflog (real example)
`git reset --hard HEAD~1` removed my commit and its file:
```
$ git reset --hard HEAD~1
HEAD is now at 5d2e247 add profile page
$ ls important.txt
ls: cannot access 'important.txt': No such file or directory

$ git reflog -4
5d2e247 HEAD@{0}: reset: moving to HEAD~1
23e9bdc HEAD@{1}: commit: add important work      <- still remembered!
5d2e247 HEAD@{2}: merge feature/profile: Fast-forward
...
$ git reset --hard 23e9bdc
HEAD is now at 23e9bdc add important work
$ ls important.txt
important.txt                                     <- back
```
`reflog` is a private log of every place HEAD has been. It works for committed work for about 90 days by default. **Uncommitted changes are not in the reflog**, so commit often.

---

## 10. Working With a Remote

```bash
git remote -v                          # show remotes
git remote add origin git@github.com:shubhamnishane-064/DevOps-Trip.git
git push -u origin main                # first push, sets the upstream branch
git push                               # later pushes
git fetch                              # download new commits, change nothing locally
git pull                               # fetch + merge (or rebase with pull.rebase true)
git branch -vv                         # which remote branch each local one tracks
```

**Rejected push** (`! [rejected] ... (fetch first)` or `non-fast-forward`): the remote has commits I don't have. Fix: `git pull --rebase`, solve any conflict, then `git push`. Do not use `--force` on a shared branch.

---

## 11. Commit Messages (Conventional Commits)

```
<type>: <short summary in the present tense>

feat: add login page
fix: handle empty config file
docs: update README with run steps
chore: update dependencies
test: add backup script tests
refactor: split health check into functions
ci: add GitHub Actions workflow
```
- Summary under about 50 characters; add a body after a blank line to explain **why**.
- One logical change per commit.
- Bonus: tools can read these types to pick the next version number and write release notes automatically (Saturday: semantic releases).

---

## 12. Lab (Hands-on)

**Goal:** see the objects, create and merge branches, cause and fix a conflict, rebase, and recover from a bad reset.

```bash
# run my guided practice repo (creates /tmp/git-playground)
./git_playground.sh
cd /tmp/git-playground
git log --oneline --graph --all
git cat-file -p HEAD
find .git/objects -type f | head

# now do it by hand in a new folder
mkdir ~/git-lab && cd ~/git-lab && git init -b main
echo "v1" > app.txt && git add app.txt && git commit -m "feat: first version"
git switch -c feature/a && echo "from A" >> app.txt && git commit -am "feat: change from A"
git switch main && git switch -c feature/b && echo "from B" >> app.txt && git commit -am "feat: change from B"
git switch main && git merge feature/a        # fast-forward
git merge feature/b                           # CONFLICT: fix it, git add, git commit
git reflog                                    # see everything you did

# push my own practice work to GitHub (a new empty repo)
git remote add origin git@github.com:shubhamnishane-064/git-lab.git
git push -u origin main
```
Do **not** practise destructive commands (`reset --hard`, `push --force`) in the real DevOps-Trip repo.

Result: (write what happened, add a screenshot of the graph and the conflict markers)

---

## 13. Errors Faced Today
- Example: `CONFLICT (content): Merge conflict in settings.txt` / `Automatic merge failed`
- Cause: two branches changed the same line
- Fix: edit the file, remove the markers, `git add`, `git commit`

Full story: `troubleshooting/error-01.md`

---

## 14. Quick Q&A (for interviews)

**Q: Git vs GitHub?**
Git is the version control tool that runs locally. GitHub is a hosting service built around Git, with pull requests, issues and Actions.

**Q: What are the three areas in Git?**
Working directory (my files), staging area (what the next commit will contain), and the repository (saved commits).

**Q: How does Git store data?**
As objects named by the hash of their content: blobs for file contents, trees for folders, commits for snapshots with a parent link and a message. Branches and HEAD are small pointer files.

**Q: What is a branch, really?**
A movable pointer to a commit (a file containing one hash). That is why branches are cheap.

**Q: `git fetch` vs `git pull`?**
`fetch` downloads new commits without changing my files. `pull` fetches and then merges (or rebases) them into my branch.

**Q: Merge vs rebase?**
Merge joins branches with a merge commit and keeps true history. Rebase replays my commits on top of another branch for a straight history, but rewrites commits, so I never rebase shared branches.

**Q: What is a fast-forward merge?**
When the target branch has no new commits, Git just moves its pointer forward, with no merge commit.

**Q: How do you resolve a merge conflict?**
Open the file, choose the final content, remove the conflict markers, `git add` the file, and commit. Then run the tests. `git merge --abort` cancels.

**Q: `reset` vs `revert`?**
`reset` moves the branch back and rewrites history (use on my local work only). `revert` creates a new commit that undoes an earlier one, which is safe for shared branches.

**Q: I ran `git reset --hard` by mistake. Can I get my commits back?**
Usually yes: `git reflog` shows where HEAD was, and `git reset --hard <hash>` returns there. Uncommitted changes can't be recovered this way.

**Q: What is a detached HEAD?**
HEAD points straight at a commit, not a branch. New commits there belong to no branch, so I create one (`git switch -c name`) to keep them.

**Q: Why `--force-with-lease` and not `--force`?**
It refuses to overwrite the remote if someone else pushed in the meantime, so I don't destroy their work.

**Q: I committed a password by mistake. What do I do?**
Treat it as leaked: rotate it immediately, then remove it from history (for example with `git filter-repo`) and add the file to `.gitignore`. A new commit that deletes the file is not enough.

---

## 15. Summary in 3 lines
1. Git stores snapshots as objects (blob, tree, commit); branches and HEAD are just pointers, which is why branching is cheap.
2. Merge keeps history and adds a merge commit; rebase gives a straight line but rewrites commits, so never rebase shared branches; conflicts are fixed by editing, `git add`, and committing.
3. `reflog` recovers most mistakes, `revert` is the safe undo for pushed work, and secrets must never be committed.