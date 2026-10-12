# Notes: Day 5 - Backup and Log Rotation

**Week 1 | Friday** | Topic: tar, gzip, rsync, find -mtime, dated backups, retention, cron

---

## 1. Why Backups?
- Disks fail, people delete files by mistake, and servers get attacked. A backup lets us recover.
- A good backup is **automatic** (cron), **dated** (we can pick a day), **checked** (we know it can be restored) and **cleaned** (old ones removed so the disk does not fill).
- Rule of thumb, the **3-2-1 rule**: 3 copies, on 2 different types of storage, 1 copy off-site (for example S3 in AWS).

| Term | Meaning |
|---|---|
| **Full backup** | Copy of everything |
| **Incremental** | Only what changed since the last backup |
| **Retention** | How long we keep old backups (for example 7 days) |
| **Restore** | Getting the data back from a backup |

> A backup that was never tested for restore is only a hope.

---

## 2. tar (make one archive from many files)

`tar` packs files and folders into one file. With `gzip` it also compresses them (`.tar.gz`).

```bash
tar -czf backup.tar.gz myfolder/        # create + compress
tar -tzf backup.tar.gz                  # list contents (also a quick check)
tar -xzf backup.tar.gz                  # extract here
tar -xzf backup.tar.gz -C /tmp/restore  # extract to another folder
tar -xzf backup.tar.gz myfolder/a.txt   # extract only one file
```

| Letter | Meaning |
|---|---|
| `c` | create |
| `x` | extract |
| `t` | list (test) |
| `z` | use gzip compression |
| `f` | file name follows (always last before the name) |
| `v` | verbose, show files |
| `-C dir` | change to this directory first |

Memory trick: **c**reate = `czf`, e**x**tract = `xzf`, lis**t** = `tzf`.

Other tools: `gzip file` (compress one file, creates `file.gz`), `gunzip file.gz`, `zip -r a.zip folder`, `unzip a.zip`.

> `tar` prints "Removing leading `/' from member names". It is a **warning, not an error**. It just means paths are stored without the starting `/`. Using `-C` avoids it.

---

## 3. Dates in File Names
```bash
date                   # Mon Oct 12 03:45:05 UTC 2026
date +%F               # 2026-10-12
date +%F_%H-%M-%S      # 2026-10-12_03-45-05
date +%Y%m%d           # 20261012
```
Dated names mean backups never overwrite each other and sort in time order:
```bash
tar -czf backup_$(date +%F).tar.gz /home/shubham/projects
```

---

## 4. rsync (copy only what changed)

`rsync` copies files and skips the ones that are already the same. It is faster than `cp` for repeated backups, and it works over SSH.

```bash
rsync -av /home/shubham/projects/ /backup/projects/            # local copy
rsync -av --delete /src/ /backup/src/                          # mirror (deletes extra files in target)
rsync -avz /src/ user@server:/backup/src/                      # to another server over SSH
rsync -avn /src/ /backup/src/                                  # -n = dry run, shows what WOULD happen
```

| Option | Meaning |
|---|---|
| `-a` | archive: keep permissions, times, owners, folders |
| `-v` | verbose |
| `-z` | compress while sending |
| `-n` | dry run (test first!) |
| `--delete` | remove files from target that no longer exist in source |

**Trailing slash matters:** `/src/` copies the *contents*, `/src` copies the *folder itself*.

| Use | Tool |
|---|---|
| One compressed, dated archive | `tar` |
| Keep a synced copy / copy to a remote server | `rsync` |

---

## 5. Cleaning Old Backups (retention) with find

```bash
find /backups -name "*.tar.gz" -mtime +7              # list files older than 7 days
find /backups -name "*.tar.gz" -mtime +7 -delete      # delete them
find /backups -type f -size +100M                     # files bigger than 100 MB
find /var/log -name "*.log" -mtime +30 -exec gzip {} \;   # compress old logs
```

| Option | Meaning |
|---|---|
| `-mtime +7` | modified **more than** 7 days ago |
| `-mtime -1` | modified in the last day |
| `-mmin +60` | modified more than 60 minutes ago |
| `-name` | match the name (use quotes around `*`) |
| `-type f` | files only |
| `-delete` | delete matches |

> **Safety rule:** run the `find` line **without** `-delete` first and read the list. Then add `-delete`.

---

## 6. Log Rotation
Logs grow forever. **Log rotation** renames the old log, compresses it, and deletes very old ones.

### The simple way (my own commands)
```bash
find /var/log/myapp -name "*.log" -mtime +7 -exec gzip {} \;     # compress logs older than 7 days
find /var/log/myapp -name "*.log.gz" -mtime +30 -delete          # delete after 30 days
```

### The system way: `logrotate`
Config files are in `/etc/logrotate.d/`. Example `/etc/logrotate.d/myapp`:
```
/var/log/myapp/*.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
}
```
```bash
sudo logrotate -d /etc/logrotate.d/myapp   # -d = debug / dry run
sudo logrotate -f /etc/logrotate.d/myapp   # force a rotation now
```

| Setting | Meaning |
|---|---|
| `daily` / `weekly` | how often |
| `rotate 7` | keep 7 old logs |
| `compress` | gzip old logs |
| `missingok` | no error if the log is missing |
| `notifempty` | skip empty logs |

---

## 7. Lab (Hands-on)

**Goal:** write `backup.sh` that archives a folder with a date in the name, checks the archive, keeps only the last 7 days, and runs from cron.

Script (saved as `backup.sh` in this folder):
```bash
#!/usr/bin/env bash
set -euo pipefail

SOURCE="${1:-}"
DEST="${2:-$HOME/backups}"
KEEP_DAYS="${3:-7}"

[ -z "$SOURCE" ] && { echo "Usage: $0 <source> [dest] [keep_days]"; exit 2; }
[ -d "$SOURCE" ] || { echo "ERROR: $SOURCE not found"; exit 1; }

mkdir -p "$DEST"
NAME="$(basename "$SOURCE")"
ARCHIVE="$DEST/${NAME}_$(date +%F_%H-%M-%S).tar.gz"

tar -czf "$ARCHIVE" -C "$(dirname "$SOURCE")" "$NAME"
tar -tzf "$ARCHIVE" >/dev/null && echo "OK: $ARCHIVE"

find "$DEST" -name "${NAME}_*.tar.gz" -type f -mtime +"$KEEP_DAYS" -delete
```

Steps:
```bash
mkdir -p ~/projects && echo "test" > ~/projects/a.txt
chmod +x backup.sh
./backup.sh ~/projects ~/backups 7
ls -lh ~/backups
tar -tzf ~/backups/projects_*.tar.gz        # check the contents

# test the cleanup: make a fake old backup, run again, it must disappear
touch -d "10 days ago" ~/backups/projects_old.tar.gz
./backup.sh ~/projects ~/backups 7
ls ~/backups

# test a restore
mkdir /tmp/restore && tar -xzf ~/backups/projects_*.tar.gz -C /tmp/restore
ls -R /tmp/restore

# schedule it: every day at 2 AM (note the full paths)
crontab -e
0 2 * * * /home/shubham/DevOps-Trip/week-01-linux-bash/5-fri/backup.sh /home/shubham/projects /home/shubham/backups 7 >> /home/shubham/backups/cron.log 2>&1
```
My finished script `backup.sh` also writes a log file (`backup.log`) with start, result, size and cleanup count.

Result: (write what happened here, add a screenshot)

---

## 8. Errors Faced Today
- Example: a cron backup that uses `$(date +%F)` fails with `unexpected EOF while looking for matching ')'`
- Cause: in a crontab line, `%` has a special meaning (it means a new line)
- Fix: escape it as `\%` (`date +\%F`) or put the date inside the script

Write the full story in `troubleshooting/error-01.md`.

---

## 9. Quick Q&A (for interviews)

**Q: `tar -czf` vs `tar -xzf`?**
`czf` creates a compressed archive, `xzf` extracts one.

**Q: `tar` vs `rsync`?**
`tar` makes one compressed archive (good for dated backups). `rsync` syncs only the changes (good for repeated copies and remote servers).

**Q: What does `-mtime +7` mean?**
Files last modified more than 7 days ago.

**Q: How do you keep only 7 days of backups?**
`find /backups -name "*.tar.gz" -mtime +7 -delete`, run after each backup.

**Q: How do you know a backup is good?**
List it with `tar -tzf`, and test a restore to another folder. A backup that was never restored is untested.

**Q: What is the 3-2-1 rule?**
3 copies of data, on 2 different media, with 1 copy off-site (for example in S3).

**Q: What is log rotation?**
Renaming, compressing and deleting old logs on a schedule so they do not fill the disk. `logrotate` does it.

**Q: Why use a dry run (`rsync -n`, `find` without `-delete`)?**
To see what will happen before anything is changed or deleted.

**Q: Why does a backup that works by hand fail in cron?**
Cron has a small PATH and its own environment, relative paths break, and `%` must be escaped. Use full paths and log the output.

---

## 10. Summary in 3 lines
1. `tar -czf` makes a dated, compressed backup; `rsync -av` syncs changes; always test with `tar -tzf` and a restore.
2. `find -mtime +7 -delete` removes old backups (retention); `logrotate` or `find` rotates logs.
3. Automate with cron using full paths, log the output, and escape `%` as `\%`.