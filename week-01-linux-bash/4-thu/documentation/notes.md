# Notes: Day 4 - Bash Scripting Basics

**Week 1 | Thursday** | Topic: variables, conditions, loops, functions, arguments, exit codes, pipes

---

## 1. What is a Bash Script?
- A **script** is a text file with commands that run one after another. It automates work I would type by hand.
- **Bash** is the shell most Linux systems use. Scripts end with `.sh` (the name is only a habit).
- Why DevOps uses scripts: backups, deployments, health checks, log cleanup, server setup.

### My first script
```bash
#!/usr/bin/env bash
echo "Hello DevOps"
```
```bash
chmod +x hello.sh      # give execute permission (Day 1)
./hello.sh             # run it
bash hello.sh          # also works without chmod
```

**Shebang (`#!`)** on the first line tells Linux which program runs the script.
`#!/usr/bin/env bash` finds bash wherever it is installed.

---

## 2. Variables
```bash
name="Shubham"           # NO spaces around =
age=25
echo "Hello $name"       # use $ to read it
echo "Hello ${name}!"    # braces when text follows it
today=$(date +%F)        # command output into a variable
echo "Today is $today"
```

| Rule | Example |
|---|---|
| No spaces around `=` | `a=5` (not `a = 5`) |
| Double quotes keep `$var` working | `"Hi $name"` |
| Single quotes print text exactly | `'Hi $name'` prints `Hi $name` |
| Always quote variables | `"$file"` protects names with spaces |

### Read input
```bash
read -p "Enter your name: " user
echo "Hi $user"
```

### Special variables
| Variable | Meaning |
|---|---|
| `$0` | Script name |
| `$1`, `$2` ... | First, second argument |
| `$#` | Number of arguments |
| `$@` | All arguments |
| `$?` | Exit code of the last command |
| `$$` | PID of the script |

---

## 3. Arguments
```bash
#!/usr/bin/env bash
echo "Script: $0"
echo "First: $1"
echo "Count: $#"
```
```bash
./args.sh apple banana    # $1=apple  $2=banana  $#=2
```
Default value when no argument is given:
```bash
FOLDER="${1:-/var}"       # use $1, or /var if empty
```

---

## 4. Conditions (if / else)
```bash
if [ "$age" -ge 18 ]; then
  echo "Adult"
elif [ "$age" -ge 13 ]; then
  echo "Teen"
else
  echo "Child"
fi
```

**Spaces inside `[ ]` are required.** `[ "$a" -eq 5 ]` works, `["$a"-eq 5]` fails.

| Number test | Meaning |
|---|---|
| `-eq` | equal |
| `-ne` | not equal |
| `-gt` / `-ge` | greater than / greater or equal |
| `-lt` / `-le` | less than / less or equal |

| String test | Meaning |
|---|---|
| `"$a" = "$b"` | equal |
| `"$a" != "$b"` | not equal |
| `-z "$a"` | empty |
| `-n "$a"` | not empty |

| File test | Meaning |
|---|---|
| `-f file` | file exists |
| `-d dir` | directory exists |
| `-r` / `-w` / `-x` | readable / writable / executable |
| `-s file` | file exists and is not empty |

```bash
if [ -f /etc/passwd ]; then echo "found"; fi
[ -d /backup ] || mkdir /backup      # make it only if missing
```

### case
```bash
case "$1" in
  start)   echo "Starting" ;;
  stop)    echo "Stopping" ;;
  *)       echo "Usage: $0 start|stop" ;;
esac
```

---

## 5. Loops
```bash
# for loop over a list
for fruit in apple banana mango; do
  echo "$fruit"
done

# for loop over numbers
for i in {1..5}; do echo "Number $i"; done

# for loop over files
for f in /var/log/*.log; do echo "$f"; done

# while loop
count=1
while [ $count -le 3 ]; do
  echo "Count $count"
  count=$((count + 1))
done

# read a file line by line
while read -r line; do
  echo "$line"
done < users.txt
```
Math uses `$(( ))`: `sum=$((a + b))`.

---

## 6. Functions
```bash
greet() {
  local name="$1"          # local = only inside the function
  echo "Hello $name"
}

greet "Shubham"
greet "DevOps"
```
Write a piece of logic once, reuse it many times.

---

## 7. Exit Codes
Every command ends with a number: **0 = success, anything else = failure**.
```bash
ls /etc
echo $?          # 0
ls /nofolder
echo $?          # 2
```
```bash
if grep -q "root" /etc/passwd; then
  echo "found"
fi

exit 0           # script succeeded
exit 1           # script failed
```

| Code | Usual meaning |
|---|---|
| 0 | Success |
| 1 | General error |
| 2 | Wrong usage |
| 126 | Found but not executable (permission) |
| 127 | Command not found |

### Safer scripts
```bash
set -euo pipefail
```
| Option | Effect |
|---|---|
| `-e` | Stop when a command fails |
| `-u` | Stop when a variable is not set |
| `-o pipefail` | A pipe fails if any part fails |

---

## 8. Redirection and Pipes
```bash
echo "hi" > file.txt        # write (overwrite)
echo "hi" >> file.txt       # append
command 2> errors.txt       # send errors to a file
command > out.txt 2>&1      # output and errors to one file
command > /dev/null 2>&1    # throw all output away
cat file | grep "x"         # pipe: output of one -> input of next
```

### Text tools
| Tool | Example | Use |
|---|---|---|
| `grep` | `grep -i "error" app.log` | search |
| `cut` | `cut -d: -f1 /etc/passwd` | pick a column |
| `awk` | `awk '{print $1}' file` | columns and calculations |
| `sed` | `sed 's/old/new/g' file` | find and replace |
| `sort` | `sort -rn` | sort |
| `uniq` | `sort \| uniq -c` | count duplicates |
| `wc` | `wc -l file` | count lines |
| `tee` | `cmd \| tee out.txt` | screen and file |

Example: top 5 users by count in a log
```bash
awk '{print $1}' access.log | sort | uniq -c | sort -rn | head -5
```

---

## 9. Lab (Hands-on)

**Goal:** write `sysinfo.sh` (hostname, user, uptime, kernel, disk, memory, top 5 CPU processes).

```bash
#!/usr/bin/env bash
set -euo pipefail

print_line() { echo "------------------------------------------"; }

echo "SYSTEM INFO for $(hostname)"
print_line
echo "User     : $(whoami)"
echo "Date     : $(date)"
echo "Uptime   : $(uptime -p)"
echo "Kernel   : $(uname -r)"
print_line
echo "Disk (root /):"
df -h / | tail -n 1
print_line
echo "Memory:"
free -m | awk 'NR==2 {printf "Used %s MB of %s MB\n", $3, $2}'
print_line
echo "Top 5 processes by CPU:"
ps -eo pid,comm,%cpu --sort=-%cpu | head -n 6
```
```bash
chmod +x sysinfo.sh
./sysinfo.sh
./sysinfo.sh > report.txt     # save the output
```
Also try my own `diskinfo.sh` (disk space, biggest folders and files, top processes) saved in this folder.

Result: (write what happened here, add a screenshot)

---

## 10. Errors Faced Today
- Example: `bash: ./sysinfo.sh: /bin/bash^M: bad interpreter: No such file or directory`
- Cause: the file was saved with Windows line endings (CRLF)
- Fix: `sed -i 's/\r$//' sysinfo.sh` (or `dos2unix sysinfo.sh`)

Write the full story in `troubleshooting/error-01.md`.

---

## 11. Quick Q&A (for interviews)

**Q: What is a shebang?**
The first line (`#!/usr/bin/env bash`) that tells the system which interpreter runs the script.

**Q: `$1`, `$@`, `$#`, `$?` ?**
First argument, all arguments, number of arguments, exit code of the last command.

**Q: What does `set -e` do?**
Stops the script when any command fails. Often used as `set -euo pipefail`.

**Q: Single quotes vs double quotes?**
Double quotes expand variables (`"$name"`), single quotes print text exactly.

**Q: What is an exit code?**
A number a command returns. 0 means success, any other number means failure.

**Q: `>` vs `>>`?**
`>` overwrites the file, `>>` appends to it.

**Q: What is `2>&1`?**
Sends errors (stream 2) to the same place as normal output (stream 1).

**Q: Why quote variables?**
Without quotes, a value with spaces is split into several words and can break the command.

**Q: How do you run a script with no execute permission?**
`bash script.sh`. The real fix is `chmod +x script.sh`.

---

## 12. Summary in 3 lines
1. A script is commands in a file; the shebang picks the interpreter and `chmod +x` makes it runnable.
2. Variables, `if`, loops and functions give logic; `$1`, `$#` and `$?` give arguments and results.
3. Use `set -euo pipefail`, quote variables, check exit codes and redirect output to logs.