# Error Log: bad interpreter ^M when running a script

**Date:** 01-10-2026 |  **Day:** Week 1 Thursday  |  **Severity:** Low

## 1. Symptom (what I saw)
```
$ ./sysinfo.sh
bash: ./sysinfo.sh: /usr/bin/env: 'bash\r': No such file or directory
```
(older systems show: `/bin/bash^M: bad interpreter: No such file or directory`)

## 2. Context (what I was doing)
I wrote `sysinfo.sh` in a Windows editor and copied it to my Linux machine. The file had `chmod +x` and the shebang was correct, but it still would not run.

## 3. Investigation (how I debugged)
- [x] Read the error carefully: it says `bash\r` or `^M`, which is not a real program name
- [x] Checked the permissions: they were fine, so this was not "Permission denied"
- [x] Looked at the file type
- [x] Searched for the `^M` character

Commands tried:
```bash
ls -l sysinfo.sh
# -rwxr-xr-x ...                     -> execute permission is fine

file sysinfo.sh
# sysinfo.sh: Bourne-Again shell script, ASCII text executable, with CRLF line terminators

cat -A sysinfo.sh | head -3
# #!/usr/bin/env bash^M$             -> hidden ^M at end of every line
```

## 4. Root Cause
Windows ends each line with two characters (CR+LF, shown as `^M`), but Linux uses only LF. Linux read the interpreter name as `bash^M` (or `bash\r`), which does not exist.

## 5. Fix
```bash
sed -i 's/\r$//' sysinfo.sh        # remove the carriage returns
# or
dos2unix sysinfo.sh                # sudo apt install dos2unix

file sysinfo.sh                    # no more "CRLF" in the output
./sysinfo.sh                       # runs
```

## 6. Prevention / Lesson Learned
- In VS Code, set the end of line to **LF** (bottom-right corner, click "CRLF", choose "LF").
- In Git on Windows: `git config --global core.autocrlf input`.
- Add a `.gitattributes` file with `*.sh text eol=lf`.
- Use `file script.sh` and `cat -A script.sh` when a script fails with a strange name in the error.
