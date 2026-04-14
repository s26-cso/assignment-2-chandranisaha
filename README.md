[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/d5nOy1eX)

# Assignment 2 Notes

This repository follows the submission structure required in the PDF. The files that matter for submission are:

```text
q1/q1.s
q2/q2.s
q3/a/payload.txt
q3/a/target_chandranisaha
q3/b/payload
q3/b/target_chandranisaha
q4/q4.c
q5/q5.s
README.md
```

Local helper files such as test scripts, temporary binaries, and sample shared-library sources are for my own verification and are not required by the assignment.

## Current Status

- Q1 is implemented in `q1/q1.s`.
- Q2 is implemented in `q2/q2.s`.
- Q3 payloads are implemented and Q3 was confirmed by the GitHub autograder with `6/6`.
- Q4 is implemented in `q4/q4.c`.
- Q5 is implemented in `q5/q5.s`.

## Q1 Summary

Implemented functions:

- `make_node`
- `insert`
- `get`
- `getAtMost`

Design choices:

- node size assumed as 24 bytes on RV64
- field offsets used:
  - `val` at `0`
  - `left` at `8`
  - `right` at `16`
- duplicate inserts are ignored
- `getAtMost(val, root)` returns the greatest value `<= val`, or `-1` if none exists

Good viva points:

- `make_node` calls `malloc`, initializes both child pointers to `NULL`, and stores the integer value
- `insert` walks the BST iteratively and returns the original root
- `get` performs ordinary BST search
- `getAtMost` keeps track of the best candidate seen so far while traversing

## Q2 Summary

`q2/q2.s` solves next-greater-element positions using a stack.

Approach:

- parse command-line arguments with `strtol`
- store values in an array
- scan from right to left
- maintain a monotonic stack of indices
- print the next-greater position for each index, or `-1` if none exists

Complexity:

- time: `O(n)`
- extra space: `O(n)`

Good viva points:

- scanning from right to left makes the stack useful immediately
- the stack stores candidate indices whose values are strictly greater than the current value
- every index is pushed once and popped at most once, giving linear time overall

## Q3 Detailed Process

Q3 was the reverse-engineering question. The repository already contained a GitHub Actions workflow named `.github/workflows/q3_binaries.yml`, which is important because the assignment template does not initially include the user-specific binaries. That workflow generates:

- `q3/a/target_chandranisaha`
- `q3/b/target_chandranisaha`

### How the binaries appeared

The per-user binaries were not present at the very beginning of the assignment setup. They were produced through the repository workflow for my GitHub username and then committed into the repo. After those files were available, the actual reverse-engineering work could begin.

### Part A process

Goal:

- Find an input that makes `q3/a/target_chandranisaha` print exactly `You have passed!`

What I did:

1. Confirmed the binary should be treated as a Linux RISC-V executable.
2. Examined the binary structure and symbols.
3. Looked at the control flow around `main`.
4. Identified the input path and comparison logic.

What the binary does:

- it reads a token from `stdin`
- the input is read with `scanf("%63s", buf)`
- it compares that token directly against a fixed secret string
- on exact match it prints `You have passed!`
- otherwise it prints `Sorry, try again.`

Recovered secret for Part A:

```text
i4/yaaXOeFNb6WfuqmJLnh/itpxuh178dZ11F1EC+hw=
```

Submission file:

- stored in `q3/a/payload.txt`

Important edge cases:

- empty input fails
- any incorrect string fails
- leading whitespace is ignored by `%s`
- very long input is truncated to the first 63 non-whitespace characters before comparison

### Part B process

Goal:

- Make `q3/b/target_chandranisaha` print output containing `You have passed!`

The assignment hint for Part B explicitly suggested trying a very large input. That strongly suggested memory-unsafety or overflow-related behavior, so I treated Part B differently from Part A.

What I did:

1. Inspected the binary structure and control flow.
2. Checked embedded strings and nearby code/data references.
3. Tried the obvious visible string first.
4. Used the hint about very large input to investigate an exploit path.
5. Built a payload that redirects execution to the success path.

What I found:

- the binary contains an embedded string:

```text
Q/4j9if=dfiw3t4FG
```

- but that string by itself was not enough to reliably satisfy the success condition
- the program behavior under long input indicated unsafe handling, which matched the hint
- the binary had been compiled with flags like `-no-pie` and `-fno-PIE`, which makes fixed-address reasoning easier during static analysis

Exploit-oriented reasoning:

- first I located the fail path and the code label that eventually prints the pass message
- then I built a large input that overwrote the saved return address so execution would jump to the pass path
- the early version worked in the sense that stdout contained `You have passed!`, but it crashed afterward
- I refined the payload so that after reaching the pass code, control returned to a cleaner exit path instead of segfaulting immediately

Observed progression:

- initial short guess: failed
- direct use of the visible embedded string: failed
- first overflow payload: printed pass message but crashed after
- refined overflow payload: printed pass message cleanly enough for the assignment criterion

Submission file:

- stored in `q3/b/payload`

### Q3 result

Latest confirmed autograder result for Q3:

```text
Q3 6/6
```

## Q4 Summary

`q4/q4.c` implements a calculator that supports arbitrary operations through runtime-loaded shared libraries.

Expected input format per line:

```text
<op> <num1> <num2>
```

How it works:

- read one line at a time with `fgets`
- parse the operation name and two integers
- construct the path `./lib<op>.so`
- load the library with `dlopen`
- resolve symbol `<op>` with `dlsym`
- call the loaded function
- print the returned integer
- close the library immediately using `dlclose`

Why `dlclose` matters:

- the assignment gives a memory constraint
- each library can be large
- closing after each operation prevents memory use from growing as more operations are processed

Parser behavior:

- malformed lines are skipped
- extra junk like `add 1 2 extra` is rejected
- glued tokens like `add2147483647 1` are rejected
- missing libraries print an error to `stderr`
- missing symbols print an error to `stderr`
- the program continues processing later lines after such errors

### Q4 local verification

I wrote `q4/test_q4.py` for local checks. It covers:

- normal valid operations
- negative operands
- malformed lines
- missing library files
- missing symbols inside existing libraries
- whitespace variations
- repeated operations
- edge integer inputs

### Run Q4 on Windows

From PowerShell:

```powershell
cd C:\Users\chand\Desktop\assignment-2-chandranisaha\q4
gcc -Wall -Wextra -Werror -shared -o libadd.so libadd.c
gcc -Wall -Wextra -Werror -shared -o libmul.so libmul.c
gcc -Wall -Wextra -Werror -shared -o libsub.so libsub.c
gcc -Wall -Wextra -Werror -shared -o libmax.so libmax.c
gcc -Wall -Wextra -Werror -shared -o libfake.so libfake.c
gcc -Wall -Wextra -Werror -o q4_test.exe q4.c
python test_q4.py .\q4_test.exe
```

To try custom input interactively:

```powershell
.\q4_test.exe
```

Example custom input:

```text
add 12 9
mul 3 4
sub 10 25
max -4 -9
```

Press `Ctrl+Z` and Enter to finish stdin on Windows console.

## Q5 Summary

`q5/q5.s` checks whether the contents of `input.txt` form a palindrome while using constant extra space.

Approach:

- open `input.txt` using `fopen`
- move to end using `fseek`
- get file length using `ftell`
- keep two indices:
  - one from the front
  - one from the back
- seek to both positions and compare one character from each side
- if any mismatch occurs, print `No`
- if the indices cross without mismatch, print `Yes`

Complexity:

- time: `O(n)`
- extra space: `O(1)`

Good viva points:

- the file is never loaded fully into memory
- only a constant number of registers and one character at a time are used
- this directly matches the problem’s memory requirement

I also prepared `q5/test_q5.py` with:

- empty string
- single character
- even-length palindromes
- odd-length palindromes
- non-palindromes
- very long palindromes
- mismatches near the middle

## Toolchain Notes

For plain Windows:

- Q4 can be compiled and demonstrated directly using MinGW `gcc`
- Q1, Q2, and Q5 are assembly tasks intended for the Linux/RISC-V assignment environment
- Q3 binaries are Linux RISC-V executables

So for actual end-to-end execution of Q1, Q2, Q3, and Q5, a Linux-based environment with RISC-V support is the correct setup. On this laptop, WSL with Ubuntu is the intended route.

## How To Use The Autograder

From PowerShell:

```powershell
cd C:\Users\chand\Desktop\assignment-2-chandranisaha
git status
git add q1/q1.s q2/q2.s q3/a/payload.txt q3/a/target_chandranisaha q3/b/payload q3/b/target_chandranisaha q4/q4.c q5/q5.s README.md
git commit -m "Finalize assignment 2 submission"
git push origin main
```

Then on GitHub:

1. Open `Actions`
2. Open the latest `Autograding` run
3. Check the score per question

## Viva Cheatsheet

If asked why each question is correct:

- Q1:
  BST traversal and insertion follow the BST invariant, and `getAtMost` tracks the best valid candidate.
- Q2:
  next-greater-element is solved with a monotonic stack in linear time.
- Q3:
  Part A was a direct secret recovery; Part B required static analysis plus a large-input exploit path guided by the assignment hint.
- Q4:
  dynamic loading is necessary because the operations are unknown at compile time, and `dlclose` is necessary for memory bounds.
- Q5:
  two-pointer comparison over file offsets gives palindrome checking in `O(1)` extra space.
