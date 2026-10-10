# Error Log:  The  change  file permission error 

**Date:** 2026-09-28 |  **Day:** Week 1 Monday  |  **Severity:** Low

## 1. Symptom (what I saw)
```
$ ./script.sh
bash: ./script.sh: Permission denied
```

## 2. Context (what I was doing)
I created a small Bash script with touch script.sh, added echo "Hello DevOps" inside it, and tried to run it directly with ./script.sh.

## 3. Investigation (how I debugged)
 Read the error carefully: it says "Permission denied", not "command not found", so the file exists but is not allowed to run
 Checked the file permissions
 Checked logs (not needed for this error)
 

Commands tried:
```bash
 ls -l script.sh
# -rw-r--r-- 1 shubham shubham 25 Oct 8 script.sh   -> no 'x' anywhere, so nobody can execute it

bash script.sh
# Hello DevOps   -> works, because bash reads the file instead of executing it
```

## 4. Root Cause
New files are created with mode 644 (rw-r--r--). The execute (x) bit was missing for owner, group and others, so the kernel refused to run the file as a program.

## 5. Fix
```bash
ls -l script.sh
# -rw-r--r-- 1 shubham script.sh   -> no 'x' anywhere, so nobody can execute it

bash script.sh
# Hello DevOps   -> works, because bash reads the file instead of executing it
```

## 6. Prevention / Lesson Learned
NAlways run chmod +x on new scripts, or use chmod 755 script.sh.
Read ls -l before guessing: the first 10 characters tell exactly who can read, write or execute.
bash script.sh is a quick test, but the real fix is the execute bit.

