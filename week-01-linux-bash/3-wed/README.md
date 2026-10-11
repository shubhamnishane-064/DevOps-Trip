# Linux & Bash Foundations | Week 1 - Wednesday: Packages, cron, disk and memory

**Date:** 30-09-2026  |  **Time spent:** 2-3 hrs  |  **Status:** [x] Done

## Today's Goal
Install software with package managers, schedule automatic jobs with cron, and check disk, memory and load.

## Plan (checklist)
- [x] Learn the concept (apt, dnf, cron syntax, df/du/free)
- [x] Hands-on lab: cron job that logs disk usage every 5 minutes
- [x] Write notes in `documentation/`
- [x] Log one error in `troubleshooting/`
- [x] Commit and push with a clear message

## What I Did
- use the `apt`command on  Ubuntu and perform  install, remove, update, search.
- Learned the difference between `apt update` and `apt upgrade`, and `remove` vs `purge`.
- Learned cron syntax (`min hour day month weekday`) and wrote jobs for every 5 minutes, daily and weekly.
- Checked disk with `df -h`, `du -sh` and `lsblk`, and memory/load with `free -m`, `uptime` and `nproc`.
- Built a cron job that writes disk usage to a log file.

## Lab Summary
```bash
sudo apt update && sudo apt install htop tree -y
df -h
du -sh /var/log
free -m
uptime
crontab -e
# */5 * * * * /usr/bin/df -h >> /home/shubham/shel/diskhelth.sh
cat ~/logs/disk_usage.log
```
Result: after the fix, the log file gained a new disk report every 5 minutes. (Add a screenshot in `documentation/images/`.)

## What I Learned
- Run `apt update` before `apt install`.
- Cron has a small PATH, so use full paths (`which <command>` finds them).
- Add `>> file 2>&1` to cron jobs so errors are not lost.
- Look at `available` memory, not `free`, and compare load average with `nproc`.
- `df -h` is the first check when a server behaves strangely: a full disk breaks many things.

## Errors Faced
- Cron job saved but nothing ran: see [`troubleshooting/error-01.md`](troubleshooting/error-01.md)

## Notes
Full notes: [`documentation/notes.md`](documentation/notes.md)

## Tomorrow
Day 4: Bash scripting basics (variables, conditions, loops, functions, exit codes). Write `sysinfo.sh`.