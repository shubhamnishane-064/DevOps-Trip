# Notes: Day 7 - Mega Project (Server Health & Backup Toolkit)

**Week 1 | Sunday** | Topic: combine everything from Week 1 into one  mega project

---

## 1. Goal
Build one tool that:
1. Checks server health (CPU, memory, disk, services, temperature)
2. Backs up a folder and removes old backups
3. Logs every result
4. Runs automatically with cron

Why a project? Recruiters want to see **something that works**, not only notes.

---

## 2. What I Reused from Week 1

| Day | Skill | Where it is used |
|---|---|---|
| Mon | Permissions, `chmod +x`, users | Scripts must be executable; backups readable only by me |
| Tue | Processes, services, logs | `ps`, `systemctl is-active`, `journalctl` in the health check |
| Wed | Cron, `df`, `free`, `uptime` | Disk and memory checks; cron schedule |
| Thu | Bash scripting | Variables, functions, `if`, loops, exit codes |
| Fri | `tar`, `find -mtime` | `backup.sh` and retention |
| Sat | SSH, `scp`, `rsync` | Can copy backups to another server (future step) |

---

## 3. Project Design

```
cron  ->  toolkit.sh  ->  healthcheck.sh   -> reports/
                      ->  temperature.sh
                      ->  backup.sh        -> backups/
                      ->  toolkit.log
          toolkit.conf (settings)
```

| File | Job |
|---|---|
| `toolkit.sh` | Main runner. Reads config, runs the steps, counts problems, sets exit code |
| `toolkit.conf` | All settings in one place |
| `healthcheck.sh` | Load, memory, disk, top processes, services |
| `temperature.sh` | CPU temperature |
| `backup.sh` | Dated `.tar.gz`, verify, delete old |
| `install.sh` | Add or remove the cron jobs |

---

## 4. Ideas Used (simple explanation)

### Config file with `source`
```bash
source toolkit.conf        # runs the file, so its variables become mine
```
Keeps settings out of the code. Rule: **no spaces around `=`**.

### Passing settings to other scripts
```bash
export DISK_LIMIT MEM_LIMIT SERVICES      # child scripts can read them
```

### Finding the script's own folder
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```
Works from cron or any folder, so no relative-path errors.

### Handling exit codes with `case`
```bash
bash temperature.sh
case $? in
  0) echo OK ;;
  1) echo WARN ;;
  3) echo "no sensor" ;;
esac
```
`$?` is the exit code of the last command. Each script reports its result with `exit N`.

### Counting problems
```bash
PROBLEMS=$((PROBLEMS + 1))
[ "$PROBLEMS" -eq 0 ]        # last line = exit code 0 only when nothing is wrong
```

### Safe cron install (no duplicates)
```bash
( crontab -l | grep -vF "# devops-toolkit"; echo "$LINES" ) | crontab -
```
A `# devops-toolkit` tag marks my lines, so install can be repeated and `--remove` only deletes mine.

---

## 5. Commands to Run

```bash
cd week-01-linux-bash/7-sun/mega-project/src
chmod +x *.sh
nano toolkit.conf

./toolkit.sh                  # everything
./toolkit.sh health
./toolkit.sh backup

cat ~/toolkit/toolkit.log     # results
ls ~/toolkit/reports ~/toolkit/backups

./install.sh --print          # preview cron lines
./install.sh --install
crontab -l
./install.sh --remove
```

### Tests to do (and screenshot)
1. Normal run: result "ALL GOOD".
2. Break it: set `SOURCE_DIR` to a folder that does not exist, so the run says "backup skipped", result "1 problem", exit code 1 (`echo $?`).
3. Lower `DISK_LIMIT=10` to force a disk warning.
4. Stop a service from `SERVICES` and see it flagged.
5. Restore test: extract the newest backup into `/tmp/restore` and check the files.

---

## 6. Errors Faced Today
- Example: `SOURCE_DIR: command not found` in `toolkit.conf`
- Cause: spaces around `=` in a shell variable
- Fix: write `SOURCE_DIR="/path"` with no spaces

Full story: `troubleshooting/error-01.md`

---

## 7. Quick Q&A (for interviews)

**Q: Tell me about a project you built.**
"I built a Server Health & Backup Toolkit in Bash. One runner script reads a config file, runs a health check, a temperature check and a backup, logs every result, and returns an exit code. I scheduled it with cron using an installer script. I tested failure cases like a missing backup folder and a full disk."

**Q: How does it know something is wrong?**
Each step returns an exit code. The runner counts problems and exits with 1 if any are found, so cron, CI or a monitoring tool can react.

**Q: Why a config file?**
So limits, folders and services can change without editing the code.

**Q: How do you avoid duplicate cron jobs?**
The installer tags its lines, removes old tagged lines, and adds the new ones.

**Q: How would you improve it?**
Send alerts to email or Slack, copy backups to S3, run it from Jenkins or GitHub Actions, and export metrics to Prometheus and Grafana.

**Q: How do you know the backup works?**
`backup.sh` checks the archive with `tar -tzf`, and I also did a restore test.

---

## 8. Summary in 2 lines
1. I turned the week's commands into one working, automated tool.
2. It checks health, backs up data, logs results and returns exit codes.