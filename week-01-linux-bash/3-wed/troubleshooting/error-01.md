# Error Log: Cron job added but nothing runs

**Date:** 2026-09-30 |  **Day:** Week 1 Wednesday  |  **Severity:** Medium

## 1. Symptom (what I saw)
The cron job was saved, but after 10 minutes the log file was empty or missing.
```
$ cat ~/logs/disk_usage.log
cat: /home/shubham/logs/disk_usage.log: No such file or directory
```

## 2. Context (what I was doing)
I wanted to record disk usage every 5 minutes. I added this line with `crontab -e`:
```
*/5 * * * * df -h >> ~/logs/disk_usage.log
```

## 3. Investigation (how I debugged)
- [x] Confirmed the job was saved: `crontab -l`
- [x] Checked the cron service: `systemctl status cron`
- [x] Checked cron logs
- [x] Compared cron's environment with my terminal

Commands tried:
```bash
crontab -l
# */5 * * * * df -h >> ~/logs/disk_usage.log      -> job is there

systemctl status cron
# active (running)                                 -> cron itself is fine

grep CRON /var/log/syslog | tail
# CRON[2481]: (shubham) CMD (df -h >> ~/logs/disk_usage.log)   -> cron DID run it

ls -ld ~/logs
# ls: cannot access '/home/shubham/logs': No such file or directory   -> folder missing
```

## 4. Root Cause
Two problems:
1. The `~/logs` folder did not exist, so the redirect `>>` failed silently.
2. I used a relative command (`df`) and `~`, while cron has a very small PATH and its own environment. Full paths are safer.

## 5. Fix
```bash
mkdir -p ~/logs
which df                      # /usr/bin/df

crontab -e
# replace the line with:
*/5 * * * * /usr/bin/df -h >> /home/shubham/logs/disk_usage.log 2>&1

# wait 5 minutes
cat ~/logs/disk_usage.log     # now shows disk usage with timestamps from each run
```

## 6. Prevention / Lesson Learned
- Create the log folder first and test the command manually before putting it in cron.
- Use full paths for every command and file (`which <command>` shows the path).
- Always add `2>&1` so errors are written to the log instead of disappearing.
- Test with `* * * * *` (every minute) first, then change to the real schedule.
- Check `grep CRON /var/log/syslog` to confirm whether cron ran the job.
