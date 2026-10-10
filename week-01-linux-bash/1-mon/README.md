# Linux & Bash Foundations | Week 1 - Monday: File system, permissions, users

**Date:** 2026-09-28  |  **Time spent:** 2-3 hrs  |  **Status:** [x] Done

## Today's Goal
Understand how Linux is built, where important files live, how permissions work, and how to manage users and groups.

## Plan (checklist)
- [x] Learn the concept (what Linux is, architecture, directory layout)
- [x] Hands-on lab: shared folder for the `devops` group
- [x] Write notes in `documentation/`
- [x] Log one error in `troubleshooting/`
- [x] Commit and push with a clear message

## What I Did
- Studied what Linux is: an open-source OS kernel, with distros like Ubuntu, Debian and RHEL built on top.
- Learned the architecture: applications -> shell (bash) -> kernel -> hardware.
- Explored the main directories: `/etc` (config), `/var` (logs), `/dev` (devices), `/home` (users), `/proc` and `/sys` (virtual kernel info).
- Practised basic commands: `pwd`, `ls -la`, `cd`, `mkdir`, `touch`, `cp`, `mv`, `rm`, `cat`, `less`, `head`, `tail`, `grep`, `find`.
- Learned `rwx` permissions, numeric modes (755, 644), `chmod` and `chown`.
- Created a user and a group, then built a shared folder that only the group can write to.

## Lab Summary
```bash
sudo groupadd devops
sudo useradd -m devuser
sudo usermod -aG devops devuser
sudo mkdir /srv/shared
sudo chown root:devops /srv/shared
sudo chmod 770 /srv/shared
sudo -u devuser touch /srv/shared/test.txt   # works
```
Result: `devuser` can create files in `/srv/shared`; users outside the `devops` group get "Permission denied". (Add a screenshot in `documentation/images/`.)

## What I Learned
- Linux is a kernel, not a "distributed system".
- `/` is the top of the file system; `~` is my home folder.
- `/etc` is for config, `/var/log` is the first place to check when something breaks.
- Permission numbers: r=4, w=2, x=1, so `755` = `rwxr-xr-x`.
- `ls -l` tells me exactly who can read, write or run a file.

## Errors Faced
- `Permission denied` on `./script.sh`: see [`troubleshooting/error-01.md`](troubleshooting/error-01.md)

## Notes
Full notes: [`documentation/notes.md`](documentation/notes.md)

## Tomorrow
Day 2: processes, systemd services and logs (`ps`, `top`, `systemctl`, `journalctl`).