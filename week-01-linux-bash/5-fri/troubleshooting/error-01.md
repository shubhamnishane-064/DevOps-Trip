# Error Log: cron backup fails because of % in the date command

**Date:** 02-10-2026 |  **Day:** Week 1 Friday  |  **Severity:** Medium

## 1. Symptom (what I saw)
The backup worked when I ran it by hand, but cron never created a file. The cron log showed:
```
/bin/sh: 1: Syntax error: end of file unexpected
# or
/bin/sh: -c: line 0: unexpected EOF while looking for matching `)'
```

## 2. Context (what I was doing)
I added a daily backup to my crontab and put the date directly in the file name:
```
0 2 * * * tar -czf /home/shubham/backups/proj_$(date +%F).tar.gz /home/shubham/projects
```

## 3. Investigation (how I debugged)
- [x] Ran the same command by hand: it worked
- [x] Checked that cron ran the job
- [x] Looked for what is different in cron: environment and special characters
- [x] Searched the crontab manual

Commands tried:
```bash
tar -czf /home/shubham/backups/proj_$(date +%F).tar.gz /home/shubham/projects
# works in the terminal

crontab -l
# 0 2 * * * tar -czf ...proj_$(date +%F).tar.gz ...

grep CRON /var/log/syslog | tail
# CRON ... CMD (tar -czf ...proj_$(date +)
# the command is cut at the % sign

man 5 crontab
# "Percent-signs (%) in the command, unless escaped with backslash (\), will be changed into newline characters"
```

## 4. Root Cause
In a crontab line, an unescaped `%` is turned into a **newline**. So `date +%F` was cut in half and the command became broken (`$(date +`), which gives the syntax error.

## 5. Fix
Option 1: escape each `%` with a backslash.
```
0 2 * * * tar -czf /home/shubham/backups/proj_$(date +\%F).tar.gz /home/shubham/projects
```
Option 2 (better): move the command into a script and call the script from cron. No `%` problem and it is easier to test.
```
0 2 * * * /home/shubham/DevOps-Trip/week-01-linux-bash/5-fri/backup.sh /home/shubham/projects /home/shubham/backups 7 >> /home/shubham/backups/cron.log 2>&1
```
Result: the next run created `proj_2026-..._.tar.gz` and logged `OK`.

## 6. Prevention / Lesson Learned
- Keep cron lines short; put the real work in a script.
- If a command must contain `%` in a crontab, write `\%`.
- Always test the **exact** cron line with `* * * * *` first, then switch to the real schedule.
- Redirect output with `>> logfile 2>&1` so errors are visible.
- `man 5 crontab` explains cron's special rules.

