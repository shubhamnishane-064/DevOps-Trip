# Week 1 Quick Revision - Linux & Bash Foundations

Part 1: Cheat sheet. Part 2: Interview questions.

---

# Part 1: Cheat Sheet

## 1. Linux in One Minute
- Linux = open-source **kernel**. A **distro** (Ubuntu, Debian, RHEL, CentOS) = kernel + tools + package manager.
- Flow: **user -> shell (bash) -> kernel -> hardware**.
- `/` is the top of the file system. `~` is my home folder.

| Folder | Holds |
|---|---|
| `/etc` | Configuration files |
| `/var/log` | Logs |
| `/dev` | Device files (`sda`, `null`, `random`) |
| `/home` | Users' personal folders |
| `/root` | Root user's home |
| `/proc`, `/sys` | Virtual kernel info (not on disk) |
| `/tmp` | Temporary files |
| `/usr`, `/bin` | Programs |
| `/opt` | Third-party software |

Key files: `/etc/passwd` (users), `/etc/shadow` (password hashes), `/etc/group` (groups), `/etc/hosts` (local DNS).

---

## 2. Top 30 Commands

| Command | What it does |
|---|---|
| `pwd` / `cd` / `ls -la` | Where am I / move / list all with details |
| `mkdir -p` / `touch` | Make folder / empty file |
| `cp` / `mv` / `rm -r` | Copy / move or rename / delete folder |
| `cat` / `less` / `head` / `tail -f` | Show file / page it / first lines / follow a log |
| `grep -i "error" file` | Search text |
| `find / -name "a.txt"` | Find a file |
| `chmod` / `chown` | Change permissions / owner |
| `useradd -m` / `usermod -aG` / `id` | Create user / add to group / show user info |
| `ps aux` / `top` / `kill` | Processes |
| `systemctl status\|start\|stop\|enable` | Services |
| `journalctl -u nginx -f` | Service logs |
| `apt install` / `dnf install` | Install packages |
| `crontab -e` / `crontab -l` | Edit / list cron jobs |
| `df -h` / `du -sh` | Disk space / folder size |
| `free -m` / `uptime` | Memory / load |
| `tar -czf` / `tar -xzf` / `tar -tzf` | Create / extract / list archive |
| `rsync -avz` / `scp` | Sync / copy over SSH |
| `ssh -i key.pem user@ip` | Remote login |

---

## 3. Permissions

```
-rwxr-xr--   owner=rwx  group=r-x  others=r--
```
| r | w | x |
|---|---|---|
| 4 | 2 | 1 |

| Mode | Meaning | Use |
|---|---|---|
| `755` | rwxr-xr-x | scripts, programs |
| `644` | rw-r--r-- | normal files |
| `700` | rwx------ | private folder (`~/.ssh`) |
| `600` | rw------- | private files (SSH keys) |
| `400` | r-------- | `.pem` key file |
| `770` | rwxrwx--- | shared group folder |

`chmod +x file` = execute for everyone. `chmod u+x` = owner only. `chown user:group file` = change owner.
On a **folder**, `x` means "can enter it".

---

## 4. Root vs sudo vs normal user

| Root | Sudo user | Normal user |
|---|---|---|
| UID 0, no limits | Normal user in `sudo`/`wheel` group, uses `sudo` with own password, logged | Limited, cannot do admin tasks |

`sudo -l` shows what I may run. Edit rules only with `sudo visudo`. Use `-aG`, never `-G` alone.

---

## 5. Processes and Services
- `kill PID` = polite (SIGTERM 15). `kill -9 PID` = force (SIGKILL), last option.
- `start` = now. `enable` = at boot. `enable --now` = both.
- Failed service routine: `systemctl status X` -> `journalctl -u X -n 50` -> fix -> restart.
- Always test Nginx config first: `sudo nginx -t`.

---

## 6. Cron

```
*  *  *  *  *  command
min hour day month weekday
```
| Schedule | Meaning |
|---|---|
| `*/5 * * * *` | every 5 minutes |
| `0 2 * * *` | daily at 2 AM |
| `0 2 * * 1` | Mondays at 2 AM |
| `@reboot` | at startup |

**Cron rules:** full paths, `chmod +x`, log with `>> file 2>&1`, escape `%` as `\%`, test with `* * * * *` first.
Check it ran: `grep CRON /var/log/syslog` (RHEL: `/var/log/cron`).

---

## 7. Disk and Memory
- `df -h` Use% above 80% = warning. `du -ah /var | sort -rh | head` = biggest items.
- `free -m`: look at **available**, not free.
- Load average (`uptime`) higher than `nproc` = overloaded.

---

## 8. Bash Scripting

```bash
#!/usr/bin/env bash
set -euo pipefail          # stop on error / unset variable / failed pipe

name="Shubham"             # NO spaces around =
echo "Hi $name"            # double quotes expand $var, single quotes do not
FOLDER="${1:-/var}"        # first argument or default

if [ -f "$FOLDER" ]; then echo yes; fi    # spaces inside [ ] are required
for i in {1..3}; do echo $i; done
greet() { echo "Hello $1"; }
```
| Variable | Meaning |
|---|---|
| `$0` `$1` `$@` `$#` | script name / first arg / all args / count |
| `$?` | exit code of last command (0 = success) |

Redirection: `>` overwrite, `>>` append, `2>&1` errors to same place, `> /dev/null 2>&1` discard.
Tools: `grep`, `awk`, `cut`, `sed`, `sort | uniq -c`, `wc -l`, `tee`.

---

## 9. Backup and Retention
```bash
tar -czf backup_$(date +%F).tar.gz folder/     # dated archive
tar -tzf backup.tar.gz                         # verify
find /backups -name "*.tar.gz" -mtime +7 -delete   # keep 7 days (run without -delete first)
rsync -avzn src/ dest/                         # -n = dry run
```
3-2-1 rule: 3 copies, 2 media, 1 off-site. A backup is proven only after a **restore test**.

---

## 10. SSH
```bash
ssh-keygen -t ed25519
ssh-copy-id user@ip
chmod 400 mykey.pem && ssh -i mykey.pem ubuntu@<ip>
scp file user@ip:/path/        rsync -avz folder/ user@ip:/path/
```
AWS usernames: Ubuntu = `ubuntu`, Amazon Linux / RHEL = `ec2-user`.
Private key stays with me, public key goes on the server. Security Group: port 22 from **my IP** only.
Shortcut: `~/.ssh/config` with `Host`, `HostName`, `User`, `IdentityFile`.

---

## 11. Errors and Quick Fixes (my Week 1 log)

| Error | Cause | Fix |
|---|---|---|
| `Permission denied` running `./script.sh` | No execute bit | `chmod +x script.sh` |
| `Job for nginx.service failed` | Typo in config (missing `;`) | `nginx -t`, `journalctl -u nginx`, fix, restart |
| Cron job runs nothing | Missing folder / no full path | `mkdir -p`, full paths, `2>&1` |
| Cron backup breaks on `date +%F` | `%` is special in crontab | `\%` or use a script |
| `bad interpreter ^M` | Windows line endings | `dos2unix` or `sed -i 's/\r$//'` |
| `Permission denied (publickey)` | Key too open / wrong user | `chmod 400`, check username, `ssh -v` |
| `SOURCE_DIR: command not found` | Spaces around `=` | `SOURCE_DIR="/path"` |
| `sudo rm` still fails | sudoers rule, immutable flag, wildcard | `sudo -l`, `lsattr`, `sudo sh -c '...'` |

---

## 12. Mega Project (one-paragraph pitch)
> "I built a Server Health & Backup Toolkit in Bash. A runner reads a config file, runs a health check, a temperature check and a verified backup, logs every result with timestamps and returns an exit code. A cron installer schedules it, and a Docker Compose setup runs it in containers with an Nginx page for the reports."

---

# Part 2: Interview Questions

Try to answer **out loud** before reading the answer. Tick the box when you can answer without notes.

---

## Linux basics
- [ ] **1. What is Linux?**
  An open-source operating system kernel. Distros like Ubuntu and RHEL add tools and a package manager on top of it.

- [ ] **2. What does the kernel do?**
  It manages CPU, memory, devices and processes and connects programs to the hardware. The shell passes my commands to it.

- [ ] **3. Where are logs and config files stored?**
  Logs in `/var/log`, configuration in `/etc`.

- [ ] **4. What is `/proc`?**
  A virtual folder created by the kernel that shows live process, CPU and memory info. It uses no disk space.

## Permissions and users
- [ ] **5. What does `chmod 755` mean?**
  Owner can read/write/execute; group and others can read/execute (4+2+1, 4+1, 4+1).

- [ ] **6. A script says "Permission denied". What do you do?**
  Check `ls -l`. The execute bit is usually missing, so `chmod +x script.sh`.

- [ ] **7. Root vs sudo user vs normal user?**
  Root (UID 0) has no limits. A sudo user is a normal account in the `sudo`/`wheel` group that runs admin commands with `sudo` using its own password, and each command is logged. A normal user can't do admin tasks.

- [ ] **8. How do you add a user to a group?**
  `sudo usermod -aG groupname user`. The `-a` is important, because without it the user's other groups are replaced.

- [ ] **9. `sudo rm -rf` still fails. Why?**
  Read the error first. Possible causes: the sudoers rule doesn't allow `rm` (check `sudo -l`), the file is immutable (`lsattr`, `chattr -i`), the file system is read-only or busy, or the wildcard was expanded by my own shell (use `sudo sh -c '...'`).

## Processes, services, logs
- [ ] **10. `kill` vs `kill -9`?**
  `kill` sends SIGTERM and asks the program to stop cleanly. `kill -9` sends SIGKILL and forces it with no cleanup, so it is the last option.

- [ ] **11. `start` vs `enable` in systemctl?**
  `start` runs the service now. `enable` makes it start at boot.

- [ ] **12. A service failed to start. How do you debug it?**
  `systemctl status X`, then `journalctl -u X -n 50` to find the reason, fix it, restart. For Nginx I run `nginx -t` first.

- [ ] **13. How do you find which process uses port 80?**
  `sudo ss -tulpn | grep :80` or `sudo lsof -i :80`.

## Cron, disk, memory
- [ ] **14. How do you run a script every Monday at 2 AM?**
  `0 2 * * 1 /full/path/script.sh >> /path/log 2>&1`

- [ ] **15. Why does a script work manually but fail in cron?**
  Cron has a tiny PATH and environment. Use full paths, check execute permission, log output with `2>&1`, and escape `%` as `\%`.

- [ ] **16. How do you find what is filling the disk?**
  `df -h` to find the full disk, then `du -ah /var | sort -rh | head -10` for the biggest items.

- [ ] **17. How do you read `free -m`?**
  Look at **available**, because it includes cache the kernel can release. Plain "free" looks too low.

- [ ] **18. What does a load average of 4 mean on a 2-core machine?**
  The machine is overloaded. More work is waiting than the CPUs can handle.

## Bash scripting
- [ ] **19. What is a shebang?**
  The first line (`#!/usr/bin/env bash`) that tells the system which interpreter runs the script.

- [ ] **20. What does `set -euo pipefail` do?**
  Stops the script when a command fails (`-e`), when an unset variable is used (`-u`), or when any part of a pipe fails (`pipefail`).

- [ ] **21. What are `$1`, `$@`, `$#`, `$?`?**
  First argument, all arguments, number of arguments, exit code of the last command.

- [ ] **22. What is an exit code?**
  A number returned by every command. 0 means success, anything else means failure. Cron, CI and monitoring tools use it.

- [ ] **23. `>` vs `>>` vs `2>&1`?**
  `>` overwrites a file, `>>` appends, `2>&1` sends errors to the same place as normal output.

## Backup and SSH
- [ ] **24. How do you keep only 7 days of backups?**
  `find /backups -name "*.tar.gz" -mtime +7 -delete`. I run it without `-delete` first to check the list.

- [ ] **25. `tar` vs `rsync`?**
  `tar` makes one compressed, dated archive. `rsync` copies only the changes, so it is better for repeated syncs and remote copies.

- [ ] **26. How do you know a backup is good?**
  List it with `tar -tzf` and test a restore into another folder. An untested backup is only a hope.

- [ ] **27. How does SSH key login work?**
  I keep the private key and put the public key on the server. The server checks that I own the matching private key, and the private key is never sent.

- [ ] **28. How do you connect to an EC2 instance?**
  `chmod 400 key.pem`, then `ssh -i key.pem ubuntu@<public-ip>` (`ec2-user` for Amazon Linux). The Security Group must allow port 22 from my IP.

- [ ] **29. What do you do for `Permission denied (publickey)`?**
  Check the username, the key file and its permissions (`chmod 400`), then run `ssh -v` and read the server log.

## About my project
- [ ] **30. Tell me about a project you built.**
  "I built a Server Health & Backup Toolkit in Bash. A runner reads a config file, runs a health check, a temperature check and a verified backup, and logs every result with an exit code. I scheduled it with a cron installer and also ran it with Docker Compose, with an Nginx page for the reports. I tested the failure cases, like a missing folder and high disk usage."

---
