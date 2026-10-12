# Linux & Bash Foundations | Week 1 - Friday: Backup and log rotation

**Date:** 02-10-2026  |  **Time spent:** 2-3 hrs  |  **Status:** [x] Done

## Today's Goal
Write a backup script that makes dated, compressed backups, verifies them, removes old ones, and runs automatically from cron.

## Plan (checklist)
- [x] Learn the concept (tar, gzip, rsync, find -mtime, retention, logrotate)
- [x] Hands-on lab: build and test `backup.sh`
- [x] Write notes in `documentation/`
- [x] Log one error in `troubleshooting/`
- [x] Commit and push with a clear message

## What I Did
- Learned `tar` (`czf`, `xzf`, `tzf`), `gzip`, and `rsync -av` (including a dry run with `-n`).
- Used `date +%F_%H-%M-%S` to put the date in file names so backups never overwrite each other.
- Used `find -mtime +7 -delete` to keep only the last 7 days of backups.
- Learned log rotation with `find` + `gzip` and with `logrotate` (`/etc/logrotate.d/`).
- Wrote `backup.sh`: checks input, creates the archive, verifies it with `tar -tzf`, deletes old backups, and writes `backup.log`.
- Tested a restore into another folder to prove the backup works.
- Scheduled the script with cron.

## Scripts in this folder
| File | What it does |
|---|---|
| [`backup.sh`](backup.sh) | `./backup.sh <source> [dest] [keep_days]` - dated `.tar.gz`, verification, retention cleanup, log file |

## Lab Summary
```bash
chmod +x backup.sh
./backup.sh ~/projects ~/backups 7
ls -lh ~/backups
tar -tzf ~/backups/projects_*.tar.gz
touch -d "10 days ago" ~/backups/projects_old.tar.gz   # fake old backup
./backup.sh ~/projects ~/backups 7                      # old one is deleted
mkdir /tmp/restore && tar -xzf ~/backups/projects_*.tar.gz -C /tmp/restore
```
Result: archive created with a timestamp, verified, and the 10-day-old test backup was removed. Restore recovered the files. (Add a screenshot in `documentation/images/`.)

## What I Learned
- `czf` creates, `xzf` extracts, `tzf` lists (and checks) an archive.
- `-mtime +7` means "older than 7 days"; run `find` without `-delete` first.
- A backup is only proven when I have restored it once.
- `%` in a crontab line must be written `\%`, or the command is cut in half.
- The 3-2-1 rule: 3 copies, 2 media, 1 off-site (S3 later in the course).

## Errors Faced
- cron backup failed because of an unescaped `%` in `date +%F`: see [`troubleshooting/error-01.md`](troubleshooting/error-01.md)

## Notes
Full notes: [`documentation/notes.md`](documentation/notes.md)

## Tomorrow
Day 6: SSH, key-based login, `ssh_config`, `scp`/`rsync` over SSH and basic hardening.