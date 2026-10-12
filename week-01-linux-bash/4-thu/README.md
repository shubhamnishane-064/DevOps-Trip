# Linux & Bash Foundations | Week 1 - Thursday: Bash scripting basics

**Date:** 01-10-2026 |  **Time spent:** 2-3 hrs  |  **Status:** [x] Done

## Today's Goal
Write Bash scripts that use variables, conditions, loops, functions and arguments, and understand exit codes and redirection.

## Plan (checklist)
- [x] Learn the concept (shebang, variables, if, loops, functions, exit codes)
- [x] Hands-on lab: write `sysinfo.sh` and `diskinfo.sh`
- [x] Write notes in `documentation/`
- [x] Log one error in `troubleshooting/`
- [x] Commit and push with a clear message

## What I Did
- Wrote scripts with a shebang and made them runnable with `chmod +x`.
- Practised variables, `read`, command substitution `$(...)` and special variables (`$0`, `$1`, `$#`, `$@`, `$?`).
- Used `if/elif/else`, `case`, `for` and `while` loops, and wrote functions.
- Learned exit codes and `set -euo pipefail`.
- Used redirection (`>`, `>>`, `2>&1`) and pipes with `grep`, `awk`, `cut`, `sort`, `uniq`, `tee`.
- Built `sysinfo.sh` (system overview) and `diskinfo.sh` (disk usage, biggest folders and files, top processes) saved to `~/shel/cronnew.txt`.

## Scripts in this folder
| File | What it does |
|---|---|
| [`sysinfo.sh`](sysinfo.sh) | Hostname, user, uptime, kernel, disk, memory, top 5 CPU processes |
| [`diskinfo.sh`](diskinfo.sh) | Disk space, biggest folders and files, top memory and CPU processes, saved to a file |

## Lab Summary
```bash
chmod +x sysinfo.sh diskinfo.sh
./sysinfo.sh
./diskinfo.sh /home
cat ~/shel/cronnew.txt
```
Result: both scripts ran and printed the information; `diskinfo.sh` also appended the report to `cronnew.txt`. (Add a screenshot in `documentation/images/`.)

## What I Learned
- No spaces around `=` in variables, and always quote `"$var"`.
- Spaces are required inside `[ ]`.
- Exit code 0 means success; `$?` shows the last result.
- `set -euo pipefail` makes scripts fail early instead of continuing with errors.
- Windows line endings (CRLF) break Linux scripts; `dos2unix` fixes them.

## Errors Faced
- `bad interpreter ^M` (Windows line endings): see [`troubleshooting/error-01.md`](troubleshooting/error-01.md)

## Notes
Full notes: [`documentation/notes.md`](documentation/notes.md)

## Tomorrow
Day 5: backup and log-rotation script (`tar`, `rsync`, `find -mtime`, cron).