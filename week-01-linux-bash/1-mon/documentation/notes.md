What is Linux?
Linux is a free, open-source operating systei[200~# Notes: Day 1 - Linux Basics, File System, Permissions, Users

**Week 1 | Monday** | Topic: File system, permissions, users

---

## 1. What is Linux?
- Linux is a free, **open-source operating system kernel**. Anyone can see, change and share its code.
- A **distribution (distro)** = Linux kernel + tools + package manager. Examples: Ubuntu, Debian, RHEL, CentOS.
- Most servers in the world run on Linux (cloud, websites, containers).
- It is great for **automation**, because everything can be done from the command line (CLI) and written in scripts.

> Remember: Linux is an *operating system kernel*, not a "distributed system".

---

## 2. Linux Architecture (simple view)

```
 User / Application Programs
          |
        Shell (bash)      <- we type commands here
          |
        Kernel            <- the brain of the OS
          |
        Hardware (CPU, RAM, Disk, Network)
```

| Layer | Job |
|---|---|
| **Applications** | Programs the user runs (browser, Nginx, Docker) |
| **Shell / Bash** | Takes our commands and passes them to the kernel |
| **Kernel** | Manages CPU, memory, disk, devices and processes |
| **Hardware** | The real machine |

Flow: **We type a command -> shell -> kernel -> hardware does the work -> result comes back.**

---

## 3. Directory Layout (where things live)

Everything starts from **`/`** (called "root"). `~` means **my home folder** (like `/home/shubham`).

| Directory | What is inside |
|---|---|
| `/` | Top of the whole file system |
| `/home` | Personal folders of normal users |
| `/root` | Home folder of the root (admin) user |
| `/etc` | **Configuration files** (users, groups, hosts, services) |
| `/var` | Data that changes: **logs**, cache, spool, databases |
| `/dev` | **Device files**: `sda`, `nvme0n1` (disks), `null`, `zero`, `random` |
| `/proc`, `/sys` | **Virtual** files made by the kernel (not on disk). Show CPU, memory, process info |
| `/tmp` | Temporary files |
| `/usr`, `/bin` | Programs and commands |
| `/opt` | Extra / third-party software |

### Important files inside `/etc`
| File | Meaning |
|---|---|
| `/etc/passwd` | List of users |
| `/etc/shadow` | Encrypted passwords (only root can read) |
| `/etc/group` | List of groups |
| `/etc/hosts` | Local name-to-IP list |

---

## 4. Basic Commands

```bash
pwd                 # where am I?
ls -la              # list all files with details
cd /etc             # go to a folder
cd ~                # go to my home folder
mkdir project       # make a folder
touch a.txt         # make an empty file
cp a.txt b.txt      # copy
mv b.txt c.txt      # move or rename
rm c.txt            # delete a file
rm -r project       # delete a folder
cat a.txt           # show file content
less a.txt          # read a long file page by page
head -n 5 a.txt     # first 5 lines
tail -f app.log     # watch the end of a log live
grep "error" app.log       # search text
find / -name "a.txt"       # find a file
```

---

## 5. File Permissions

Run `ls -l` and you see something like:

```
-rwxr-xr--  1  shubham  devops  120  Oct 8  script.sh
```

| Part | Meaning |
|---|---|
| `-` | Type (`-` file, `d` directory) |
| `rwx` | **Owner** can read, write, execute |
| `r-x` | **Group** can read and execute |
| `r--` | **Others** can only read |

### Numbers
| Letter | Number |
|---|---|
| r (read) | 4 |
| w (write) | 2 |
| x (execute) | 1 |

- `7 = 4+2+1 = rwx`, `6 = rw-`, `5 = r-x`, `4 = r--`
- `chmod 755 file` -> owner `rwx`, group `r-x`, others `r-x`
- `chmod 644 file` -> owner `rw-`, group `r--`, others `r--`
- `chmod +x script.sh` -> make a script runnable
- `chown user:group file` -> change owner and group

---

## 6. Users and Groups

```bash
sudo useradd -m devuser          # create user with home folder
sudo passwd devuser              # set password
sudo groupadd devops             # create group
sudo usermod -aG devops devuser  # add user to group
id devuser                       # show user and groups
whoami                           # who am I?
sudo su - devuser                # switch to that user
```

- `sudo` = run a command as admin.
- Normal users should not work as root all the time.

---

## 7. Lab (Hands-on)

**Goal:** make a shared folder only the `devops` group can write to.

```bash
sudo groupadd devops
sudo useradd -m devuser
sudo usermod -aG devops devuser

sudo mkdir /srv/shared
sudo chown root:devops /srv/shared
sudo chmod 770 /srv/shared

ls -ld /srv/shared
sudo -u devuser touch /srv/shared/test.txt   # works
```

Result: (write what happened here, add a screenshot)

---

## 8. Errors Faced Today
- Example: `Permission denied` when running `./script.sh`
- Cause: file had no execute permission
- Fix: `chmod +x script.sh`

Write the full story in `troubleshooting/error-01.md`.

---

## 9. Quick Q&A (for interviews)

**Q: What is Linux?**
An open-source operating system kernel. Distros like Ubuntu and RHEL are built on it.

**Q: What does the kernel do?**
It manages CPU, memory, devices and processes, and connects programs to hardware.

**Q: Where are logs stored?**
Mostly in `/var/log`.

**Q: Where are configuration files stored?**
In `/etc`.

**Q: What does `chmod 755` mean?**
Owner can read/write/execute; group and others can read/execute.

**Q: What is `/proc`?**
A virtual folder where the kernel shows live system and process info.

---

## 10. Summary in 3 lines
1. Linux = open-source kernel; distros make it usable.
2. Shell talks to kernel, kernel talks to hardware.
3. Know the key folders (`/etc`, `/var`, `/dev`, `/home`, `/proc`) and how `rwx` permissions work.

---

## 11. Key Folders and Permissions (in a paragraph)

Linux keeps its files in a tree that starts at `/`, and a few folders matter most. `/etc` holds configuration files, like the user list in `/etc/passwd` and the settings for services such as Nginx. `/var` holds data that keeps changing, mainly logs in `/var/log`, which is the first place I look when something breaks. `/dev` contains device files such as `sda` for a disk, and special ones like `null` and `random`. `/home` is where each normal user keeps their personal files. `/proc` is a virtual folder made by the kernel that shows live information about processes, CPU and memory, and it does not take up space on disk. Every file and folder also has permissions for three groups: the owner, the group and everyone else. Each group can have `r` (read, value 4), `w` (write, value 2) and `x` (execute, value 1), and adding the values gives a number, so `chmod 755` means the owner can read, write and run, while the group and others can only read and run. If a script gives "Permission denied", I check its permissions with `ls -l` and fix them with `chmod`.
