# Notes: Package mgmt, cron, disk & memory

## Key Concepts
- Pakage Management 
- cron job 
- Disk and Memory management commands

## Important Commands
```bash
sudo apt update                  # refresh the package list (does NOT install anything)
sudo apt upgrade -y              # upgrade installed packages
sudo apt install nginx -y        # install
sudo apt remove nginx            # remove, keep config files
sudo dnf check-update            # see what can be updated
sudo dnf install httpd -y        # install
sudo dnf remove httpd            # remove
sudo dnf update -y               # update everything
df -h                    # disk space of each file system (human readable)
df -hT                   # also show file system type
du -sh /var/log          # size of one folder
du -sh * | sort -h       # sizes of everything here, smallest to biggest
```

## Diagram / Screenshot
(add images under `documentation/images/`)

## Interview-style Q&A
- **Q:** 
  **A:** 
# Notes: Day 3 - Package Management, Cron, Disk and Memory

**Week 1 | Wednesday** | Topic: apt/dnf packages, cron jobs, disk and memory commands

---

## 1. What is a Package Manager?
- A **package** is a ready-to-install program with its dependencies.
- A **package manager** installs, updates and removes packages for us, so we do not download and build by hand.
- Packages come from **repositories** (online software stores for the distro).

| Distro family | Package format | Tool |
|---|---|---|
| Ubuntu, Debian | `.deb` | `apt` (older: `apt-get`), `dpkg` |
| RHEL, CentOS, Fedora, Amazon Linux | `.rpm` | `dnf` (older: `yum`), `rpm` |

---

## 2. apt (Ubuntu / Debian)

```bash
sudo apt update                  # refresh the package list (does NOT install anything)
sudo apt upgrade -y              # upgrade installed packages
sudo apt install nginx -y        # install
sudo apt remove nginx            # remove, keep config files
sudo apt purge nginx             # remove including config files
sudo apt autoremove -y           # remove unused dependencies
apt search htop                  # search
apt show nginx                   # package details
apt list --installed | grep nginx
dpkg -l | grep nginx             # installed check
crontab -e          # edit my cron jobs
crontab -l          # list my cron jobs
crontab -r          # remove ALL my cron jobs (careful)
sudo crontab -u devuser -l    # see another user's jobs
```

## 3. dnf / yum (RHEL / CentOS / Amazon Linux)

```bash
sudo dnf check-update            # see what can be updated
sudo dnf install httpd -y        # install
sudo dnf remove httpd            # remove
sudo dnf update -y               # update everything
dnf search htop
dnf info httpd
rpm -qa | grep httpd             # installed check
```

| Task | apt | dnf |
|---|---|---|
| Refresh list | `apt update` | automatic with `dnf install` |
| Install | `apt install` | `dnf install` |
| Remove | `apt remove` | `dnf remove` |
| Upgrade all | `apt upgrade` | `dnf update` |

> Always run `apt update` before `apt install`, so you get the newest package list.

---

## 4. Cron (scheduling jobs)

**cron** runs commands automatically on a schedule. The jobs live in a **crontab**.

```bash
crontab -e          # edit my cron jobs
crontab -l          # list my cron jobs
crontab -r          # remove ALL my cron jobs (careful)
sudo crontab -u devuser -l    # see another user's jobs
```

### Cron syntax
```
*   *   *   *   *   command
|   |   |   |   |
|   |   |   |   +-- day of week (0-7, Sunday = 0 or 7)
|   |   |   +------ month (1-12)
|   |   +---------- day of month (1-31)
|   +-------------- hour (0-23)
+------------------ minute (0-59)
```

| Schedule | Meaning |
|---|---|
| `* * * * *` | Every minute |
| `*/5 * * * *` | Every 5 minutes |
| `0 2 * * *` | Every day at 2:00 AM |
| `0 2 * * 1` | Every Monday at 2:00 AM |
| `30 6 1 * *` | 1st of every month at 6:30 AM |
| `@reboot` | Once at system start |

### Rules that avoid problems
- Use **full paths** for commands and scripts: `/usr/bin/df`, `/home/shubham/scripts/backup.sh`.
- Cron has a **very small PATH**, so commands that work in my terminal may fail in cron.
- Make the script executable: `chmod +x`.
- Send output to a log file: `>> /home/shubham/cron.log 2>&1`.
- Cron logs: `grep CRON /var/log/syslog` (Ubuntu) or `/var/log/cron` (RHEL).

Example:
```
*/5 * * * * /usr/bin/df -h >> /home/shubham/disk_usage.log 2>&1
```

---

## 5. Disk Commands

```bash
df -h                    # disk space of each file system (human readable)
df -hT                   # also show file system type
du -sh /var/log          # size of one folder
du -sh * | sort -h       # sizes of everything here, smallest to biggest
du -ah /var | sort -rh | head -10    # 10 biggest files/folders in /var
lsblk                    # disks and partitions as a tree
mount | grep sda         # what is mounted where
sudo fdisk -l            # partition table (needs root)
```

| Column in `df -h` | Meaning |
|---|---|
| Size | Total size |
| Used | Space in use |
| Avail | Free space |
| Use% | Percent used (watch for above 80%) |
| Mounted on | Folder where the disk appears |

> A full disk (100%) is a very common cause of crashes. `df -h` is the first check.
> Also check inodes with `df -i`, because a disk can "fill" by file count.

---

## 6. Memory and System Load

```bash
free -m                  # memory in MB
free -h                  # memory in human readable form
uptime                   # how long running + load average
cat /proc/meminfo        # detailed memory info
cat /proc/cpuinfo | grep "model name"
nproc                    # number of CPU cores
vmstat 2 5               # system stats every 2 seconds, 5 times
```

Reading `free -m`:

| Column | Meaning |
|---|---|
| total | All RAM |
| used | In use by programs |
| free | Completely unused |
| buff/cache | Used by the kernel as cache (can be freed when needed) |
| **available** | **RAM really available for new programs** (look at this one) |

**Load average** (`uptime` shows 1, 5, 15 minute averages): if the load is higher than the number of CPU cores (`nproc`), the machine is overloaded.

---

## 7. Lab (Hands-on)

**Goal:** record disk usage every 5 minutes using cron, and practise installing and removing packages.

```bash
# packages
sudo apt update
sudo apt install htop tree -y
htop
tree -L 1 /etc | head
sudo apt remove tree -y

# disk and memory checks
df -h
du -sh /var/log
free -m
uptime

# cron job
mkdir -p ~/logs
crontab -e
# add this line:
*/5 * * * * /usr/bin/df -h >> /home/shubham/logs/disk_usage.log 2>&1

# check after 5+ minutes
cat ~/logs/disk_usage.log
grep CRON /var/log/syslog | tail
```

Result: (write what happened here, add a screenshot)

---

## 8. Errors Faced Today
- Example: cron job added but the log file stays empty
- Cause: wrong path / no full path to the command, so cron could not find it
- Fix: used `which df` to find `/usr/bin/df`, used full paths and added `2>&1` to capture errors

Write the full story in `troubleshooting/error-01.md`.

---

## 9. Quick Q&A (for interviews)

**Q: What does `apt update` do?**
It refreshes the list of available packages. It does not install or upgrade anything.

**Q: `apt update` vs `apt upgrade`?**
`update` refreshes the list. `upgrade` installs newer versions of installed packages.

**Q: `apt remove` vs `apt purge`?**
`remove` keeps config files. `purge` deletes them too.

**Q: How do you run a script every Monday at 2 AM?**
`0 2 * * 1 /path/to/script.sh`

**Q: Why does a script work manually but fail in cron?**
Cron has a minimal PATH and environment. Use full paths, check permissions and log output.

**Q: How do you find which folder is using the most space?**
`du -ah /var | sort -rh | head -10`

**Q: What is the difference between `free` and `available` memory?**
`free` is totally unused RAM. `available` also counts cache that can be released, so it shows what programs can really use.

**Q: What does a load average of 4 mean on a 2-core machine?**
The machine is overloaded: more work is waiting than the CPUs can handle.

---

## 10. Summary in 3 lines
1. `apt` (Debian/Ubuntu) and `dnf` (RHEL/CentOS) install and manage software; run `apt update` first.
2. Cron runs jobs on a schedule (`min hour day month weekday`); always use full paths and log the output.
3. `df -h`, `du -sh`, `free -m` and `uptime` are the quick health checks for disk, memory and load.