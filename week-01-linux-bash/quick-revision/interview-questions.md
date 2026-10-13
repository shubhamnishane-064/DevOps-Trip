# Week 1 Interview Questions - Linux & Bash Foundations

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

