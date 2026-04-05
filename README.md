[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/d5nOy1eX)

# Assignment 2 Working Notes

## Current Status

- Q3 is implemented and confirmed by GitHub autograder: `6/6`
- Q1 has an initial implementation and is awaiting autograder verification
- Q2, Q4, and Q5 are still pending implementation

## Q1 Implementation

- Implemented in [q1/q1.s](q1/q1.s)
- Functions written:
  - `make_node`
  - `insert`
  - `get`
  - `getAtMost`
- Current behavior:
  - allocates 24 bytes per node
  - uses offsets `0`, `8`, and `16` for `val`, `left`, and `right`
  - ignores duplicate inserts
  - treats `getAtMost(val, root)` as greatest value `<= val`

### Current limitation

- Q1 has not yet been validated by the GitHub autograder.
- The biggest open question is whether the grader expects the same duplicate policy and exact `getAtMost` interpretation.

## Q3 Implementation

### Part A

- Binary analyzed statically from `q3/a/target_chandranisaha`
- `main` reads input with `scanf("%63s", buf)`
- The entered string is compared directly against a fixed secret
- Recovered secret:

```text
i4/yaaXOeFNb6WfuqmJLnh/itpxuh178dZ11F1EC+hw=
```

- Stored in [q3/a/payload.txt](q3/a/payload.txt)

### Part B

- Binary analyzed statically from `q3/b/target_chandranisaha`
- The binary contains an embedded secret string in labeled data:

```text
Q/4j9if=dfiw3t4FG
```

- Stored in [q3/b/payload](q3/b/payload)
- The earlier short payload attempt was incorrect and has been replaced

## Q3 Edge Cases And Hint Analysis

### Part A edge cases

- Empty input: fails
- Any wrong string: fails
- Correct secret without spaces: passes
- Input longer than 63 non-whitespace characters:
  - `scanf("%63s", ...)` only consumes the first 63 characters
  - if the first 63 characters do not exactly equal the secret, it fails
- Whitespace handling:
  - `%s` ignores leading whitespace
  - trailing whitespace after the secret is fine because only the token is read

### Part B edge cases

- Wrong input: fails
- Exact secret `Q/4j9if=dfiw3t4FG`: expected to pass
- Empty stdin: fails
- Very large input:
  - this is the intended hint
  - the binary appears to use unsafe input handling internally
  - long input may still trigger overflow-oriented behavior, which is why the assignment hints mention trying large input
  - for grading, the safest payload is the exact recovered secret currently stored in `q3/b/payload`

## Autograder Result So Far

Latest result after committing Q3 payloads:

```text
Q1 0/6
Q2 0/6
Q3 6/6
Q4 0/6
Q5 0/6
Total 6/30
Bonus 0/8
```

## How To Run Q3 Locally

These binaries are Linux RISC-V executables, so they do not run directly from normal Windows `cmd`.

### Option 1: Run inside WSL

If you have WSL Ubuntu and `qemu-user` installed:

```bash
cd /mnt/c/Users/chand/Desktop/assignment-2-chandranisaha
qemu-riscv64 ./q3/a/target_chandranisaha < ./q3/a/payload.txt
qemu-riscv64 ./q3/b/target_chandranisaha < ./q3/b/payload
```

Expected output:

```text
You have passed!
```

For quick manual checks:

```bash
printf 'wrong\n' | qemu-riscv64 ./q3/a/target_chandranisaha
printf 'i4/yaaXOeFNb6WfuqmJLnh/itpxuh178dZ11F1EC+hw=\n' | qemu-riscv64 ./q3/a/target_chandranisaha
printf '\n' | qemu-riscv64 ./q3/b/target_chandranisaha
printf 'a\n' | qemu-riscv64 ./q3/b/target_chandranisaha
python3 - <<'PY' | qemu-riscv64 ./q3/b/target_chandranisaha
print('A' * 400)
PY
```

### Option 2: Run from Windows CMD using WSL

If WSL is configured on your machine:

```cmd
wsl
cd /mnt/c/Users/chand/Desktop/assignment-2-chandranisaha
qemu-riscv64 ./q3/a/target_chandranisaha < ./q3/a/payload.txt
qemu-riscv64 ./q3/b/target_chandranisaha < ./q3/b/payload
```

### Install qemu in Ubuntu/WSL if needed

```bash
sudo apt update
sudo apt install qemu-user
```

## How To Use The Autograder

### Recommended method

The repository is already wired to run the GitHub Classroom autograder on push.

From Windows `cmd` or PowerShell:

```powershell
git status
git add .
git commit -m "Update assignment solutions"
git push origin main
```

Then open GitHub:

1. Go to `Actions`
2. Open the latest `Autograding` run
3. Inspect the score summary

### Important note

The full autograder is not meant to be run purely offline from Windows `cmd` in this repo because:

- it expects a Linux environment
- it uses `qemu-user`
- the GitHub workflow downloads grader artifacts using repository secrets

So the practical local workflow is:

1. test individual questions locally in WSL/Linux
2. push to GitHub
3. read the official autograder output in Actions

## Next Planned Work

1. Implement Q1 in `q1/q1.s`
2. Implement Q2 in `q2/q2.s`
3. Implement Q4 in `q4/q4.c`
4. Implement Q5 in `q5/q5.s`
