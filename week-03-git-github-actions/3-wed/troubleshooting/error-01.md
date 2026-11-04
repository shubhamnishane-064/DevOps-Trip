# Error Log: "Permission denied" in CI for a script that works on my laptop
## 1. Symptom (what I saw)
The CI job failed on the step that runs my script:
```
Run ./deploy.sh
/home/runner/work/_temp/xxxx.sh: line 1: ./deploy.sh: Permission denied
Error: Process completed with exit code 126.
```
The same script ran fine on my computer.

## 2. Context (what I was doing)
I added `deploy.sh` to the repository and a workflow step `run: ./deploy.sh`. I had edited the file with an editor on a system (and with Git settings) that did not keep the executable permission.

## 3. Investigation (how I debugged)
- [x] Read the exit code: **126** means "found, but cannot be executed" (a permission problem), unlike **127** ("command not found")
- [x] Remembered Week 1, Day 1: `Permission denied` on `./script.sh` means no execute bit
- [x] Checked what Git recorded for the file
- [x] Compared with a fresh clone, which is what the runner has

Commands tried:
```bash
git ls-files -s deploy.sh
# 100644 0f5c6aef... 0	deploy.sh        -> mode 100644 = NOT executable (an executable file shows 100755)

git clone origin.git runner && cd runner
ls -l deploy.sh
# -rw-r--r-- deploy.sh                   -> no "x" anywhere
./deploy.sh
# bash: ./deploy.sh: Permission denied   (exit code 126)

git config core.fileMode
# false                                  -> Git was ignoring permission changes on my machine
```

## 4. Root Cause
Git stores only one permission detail: whether a file is executable (`100755`) or not (`100644`). My commit recorded `100644`, because `core.fileMode` was `false` on my machine (common on Windows, WSL on `/mnt/c`, and some shared drives). The CI runner clones the repository fresh, so the script arrived **without** the execute bit.

## 5. Fix
Record the executable bit in Git (works on any system):
```bash
git update-index --chmod=+x deploy.sh
git ls-files -s deploy.sh
# 100755 0f5c6aef... 0	deploy.sh        -> now executable
git commit -m "fix(ci): make deploy.sh executable"
git push
```
Fresh clone after the fix:
```
-rwxr-xr-x deploy.sh
deploying...                             (exit code 0)
```
Quick workaround in the workflow: `run: bash deploy.sh` (does not need the execute bit).

Check every script at once:
```bash
git ls-files -s '*.sh'                   # every line should start with 100755 if it is meant to be run directly
```

## 6. Prevention / Lesson Learned
- **Exit code 126 = cannot execute (permissions). Exit code 127 = command not found.** The number tells me which.
- Run `git ls-files -s` to see the mode Git stored, since `ls -l` on my machine may lie when `core.fileMode=false`.
- Set `git config core.fileMode true` (the default on Linux and macOS).
- For scripts, call them with `bash script.sh` in CI, so a missing execute bit can't break the pipeline.
- Add a check to `ci_local.sh` or CI that lists scripts with mode `100644` that start with a shebang.

## 7. A second problem I solved today: YAML "mapping values are not allowed"
```
triggers-demo.yml:62:26: could not parse as YAML: mapping values are not allowed in this context
62 |       - run: echo "Careful: a manual run for prod"
```
**Cause:** after `run:`, the value was not quoted as a whole, and the `: ` inside the text looks like the start of a new key.
**Fix:** quote the value or use a block (`run: |`). I reworded the text so there is no `: `.
**Found by:** `actionlint` and `yamllint`, before pushing. That is why `ci_local.sh` runs them.
