[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/d5nOy1eX)

# Assignment 2

This repository is organized according to the required submission structure:

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

## Overview

I implemented each question in the required language and file:

- `q1/q1.s`: binary search tree functions in RISC-V assembly
- `q2/q2.s`: next greater element positions in RISC-V assembly
- `q3/a/payload.txt` and `q3/b/payload`: reverse-engineered payloads for the given binaries
- `q4/q4.c`: dynamically loaded calculator in C
- `q5/q5.s`: palindrome checker over `input.txt` in RISC-V assembly using constant extra space

## Q1

### Problem

Implement the following BST functions in assembly:

- `make_node`
- `insert`
- `get`
- `getAtMost`

### Implementation logic

I used the RV64 layout of:

```c
struct Node {
    int val;
    struct Node *left;
    struct Node *right;
};
```

This means:

- `val` is stored at offset `0`
- `left` is stored at offset `8`
- `right` is stored at offset `16`
- total node size is `24` bytes

`make_node`:

- allocates `24` bytes using `malloc`
- stores the given integer in the first word
- initializes `left` and `right` to `NULL`
- returns the new node pointer

`insert`:

- handles the empty-tree case by directly creating and returning a new root
- otherwise walks down the tree iteratively
- compares the value to the current node
- moves left if smaller and right if larger
- inserts the new node when a `NULL` child is reached
- ignores duplicates and keeps the original root unchanged

`get`:

- performs standard BST lookup
- compares the target value with the current node
- moves left or right accordingly
- returns the node pointer if found
- returns `NULL` if the value does not exist

`getAtMost`:

- traverses the tree while maintaining the best candidate found so far
- if the current node value is `<= target`, it becomes a candidate and the search continues to the right
- if the current node value is greater than the target, the search continues to the left
- returns `-1` if no valid candidate exists

### Complexity

- `make_node`: `O(1)`
- `insert`: `O(h)`
- `get`: `O(h)`
- `getAtMost`: `O(h)`

where `h` is the height of the tree.

### How to run

This file is intended to be linked with a small C test program in a Linux RISC-V environment.

Example workflow:

```bash
cd q1
riscv64-linux-gnu-gcc -c q1.s -o q1.o
riscv64-linux-gnu-gcc your_test_file.c q1.o -o q1_test
qemu-riscv64 ./q1_test
```

## Q2

### Problem

Given array elements as command-line arguments, print the position of the next greater element to the right for each index, or `-1` if none exists.

### Implementation logic

I implemented the standard monotonic-stack solution in assembly.

Main steps:

1. Read `argc` and `argv`
2. Let `n = argc - 1`
3. Allocate arrays for:
   - input values
   - answers
   - stack of indices
4. Parse each command-line argument using `strtol`
5. Scan the array from right to left
6. Pop from the stack while the top index does not point to a strictly greater value
7. If the stack becomes empty, the answer is `-1`
8. Otherwise, the stack top is the next greater index
9. Push the current index onto the stack
10. Print the results space-separated

The stack stores indices, not values. That makes it easy to print positions directly and also compare `arr[stack_top]` with `arr[i]`.

### Why this works

When scanning from right to left, the stack always contains indices of elements to the right of the current position. By removing all elements that are less than or equal to the current value, the remaining top element is the first index to the right with a strictly greater value.

Each index is pushed once and popped at most once, so the total running time is linear.

### Complexity

- time: `O(n)`
- extra space: `O(n)`

### How to run

This is a complete assembly program with `main`.

Example workflow:

```bash
cd q2
riscv64-linux-gnu-gcc q2.s -o q2_test
qemu-riscv64 ./q2_test 85 96 70 80 102
```

Expected output:

```text
1 4 3 4 -1
```

Another example:

```bash
qemu-riscv64 ./q2_test 91 10 99 93 109 90 78
```

Expected output:

```text
2 2 4 4 -1 -1 -1
```

## Q3

Q3 required reverse engineering the provided binaries and constructing the correct input payloads.

The repository contains a workflow at `.github/workflows/q3_binaries.yml` that generates the user-specific binaries:

- `q3/a/target_chandranisaha`
- `q3/b/target_chandranisaha`

Once those binaries were available, I analyzed them and created the payload files:

- `q3/a/payload.txt`
- `q3/b/payload`

### Tools used

I primarily used static analysis tools:

- `file` to identify the binary format
- `readelf` to inspect ELF metadata, sections, and symbols
- `strings` to quickly inspect embedded printable strings
- `objdump -d` to disassemble the binaries
- `objdump -s` where useful to inspect data regions
- `qemu-riscv64` to run the binaries for verification

I relied mainly on `objdump`, `readelf`, and runtime verification with `qemu-riscv64`. Static analysis was sufficient, so a debugger was not necessary for my final payload derivation.

### Q3 Part A

#### Goal

Find an input that makes:

```bash
./target_chandranisaha < payload.txt
```

print exactly:

```text
You have passed!
```

#### Process

1. I first identified the binary type to confirm the execution environment.
2. I inspected the disassembly around `main`.
3. I located the input-reading code.
4. I found that the program reads a string token from standard input using `scanf("%63s", buf)`.
5. I followed the code path after input is read.
6. The disassembly showed that the entered string is compared against a fixed secret string.
7. Once I recovered that secret string, I placed it in `q3/a/payload.txt`.

#### Recovered payload

```text
i4/yaaXOeFNb6WfuqmJLnh/itpxuh178dZ11F1EC+hw=
```

#### Why it works

The binary does a direct string comparison. If the input matches the embedded secret exactly, it prints the pass message. Otherwise, it prints the fail message.

#### Verification

I verified it using:

```bash
cd q3/a
qemu-riscv64 ./target_chandranisaha < payload.txt
```

Expected output:

```text
You have passed!
```

### Q3 Part B

#### Goal

Find a payload for:

```bash
./target_chandranisaha < payload
```

such that the program output contains:

```text
You have passed!
```

#### Initial analysis

The assignment hint suggested trying a very large input. That strongly indicated that Part B was not just a direct password check and that the program likely had an unsafe input path.

I started by:

1. examining the binary with `readelf` and `objdump`
2. looking for strings embedded in the binary
3. identifying the control-flow paths that print the success and failure messages

One visible embedded string I recovered was:

```text
Q/4j9if=dfiw3t4FG
```

I tested this directly, but it was not sufficient by itself to satisfy the success condition.

#### Exploit path reasoning

After examining the code more carefully, I found that the binary behavior under large input was consistent with a buffer-overflow style vulnerability.

My approach was:

1. locate the path that prints the failure message
2. locate the code address or path that leads to the pass message
3. determine that a sufficiently long input could overwrite saved control-flow data
4. construct a payload that redirects execution to the pass path

The binary was compiled with flags like `-no-pie` and `-fno-PIE`, which made fixed-address static reasoning much easier because code addresses were not position-independent.

#### Payload refinement

My first exploit-style payload succeeded in the sense that:

- it printed `You have passed!`

but it also crashed afterward.

I then refined the payload so that after reaching the pass code, execution returned more cleanly instead of immediately causing a segmentation fault.

That refined payload is the one stored in:

- `q3/b/payload`

#### Verification

I verified it using:

```bash
cd q3/b
qemu-riscv64 ./target_chandranisaha < payload
```

The assignment only requires that standard output contain `You have passed!`, and the payload satisfies that condition.

### Q3 result

The Q3 payloads were accepted by the GitHub autograder, which confirmed:

```text
Q3 6/6
```

## Q4

### Problem

Implement a calculator that reads lines of the form:

```text
<op> <num1> <num2>
```

and computes the result by dynamically loading a shared library `lib<op>.so` from the current directory.

### Implementation logic

I implemented the calculator loop in C using `fgets`, `sscanf`, `dlopen`, `dlsym`, and `dlclose`.

For each input line:

1. Read the line into a fixed-size buffer
2. Parse the operation name and two integers
3. Reject malformed lines
4. Build the path `./lib<op>.so`
5. Load the library with `dlopen`
6. Resolve the function name `<op>` using `dlsym`
7. Call the function with the two operands
8. Print the integer result
9. Close the library immediately using `dlclose`

### Important details

- The operation name is restricted to at most 5 characters as required by the assignment.
- Invalid input lines are skipped safely.
- Lines with trailing extra junk are rejected.
- Missing libraries and missing symbols print an error to `stderr`, then the program continues.
- I close the shared library after each operation so the process does not keep many large libraries loaded at once.

This is important because the assignment gives a memory constraint and each shared object may be very large.

### How to run

Once the required `lib<op>.so` files are present in the current directory, the program can be compiled and run as follows.

Example on Linux:

```bash
cd q4
gcc -Wall -Wextra -Werror -o q4_test q4.c -ldl
printf 'add 12 9\nmul 3 4\nsub 10 25\nmax -4 -9\n' | ./q4_test
```

Expected output:

```text
21
12
-15
-4
```

Example edge-case checks:

```bash
printf 'badline\nadd 1\nadd 1 2 extra\nmul 2 5\n' | ./q4_test
printf 'nope 1 2\nadd 4 6\n' | ./q4_test
printf 'fake 1 2\nsub 9 4\n' | ./q4_test
```

## Q5

### Problem

Read the contents of `input.txt` and print:

- `Yes` if the string is a palindrome
- `No` otherwise

The string may be arbitrarily long, so the solution must use `O(1)` extra space.

### Implementation logic

I implemented the program as a file-based two-pointer palindrome check.

Main steps:

1. Open `input.txt` with `fopen`
2. Use `fseek(file, 0, SEEK_END)` to move to the end
3. Use `ftell` to get the file length
4. Initialize:
   - a left index at `0`
   - a right index at `length - 1`
5. While `left < right`:
   - seek to `left`
   - read one character using `fgetc`
   - seek to `right`
   - read one character using `fgetc`
   - compare them
6. If a mismatch occurs, print `No`
7. If all mirrored characters match, print `Yes`

### Why this satisfies the space requirement

The program never loads the full input into memory. It only keeps:

- the file pointer
- the two indices
- one character from each end

So the extra memory usage is constant.

### Complexity

- time: `O(n)`
- extra space: `O(1)`

### How to run

Example on Linux:

```bash
cd q5
printf 'abccba' > input.txt
riscv64-linux-gnu-gcc q5.s -o q5_test
qemu-riscv64 ./q5_test
```

Expected output:

```text
Yes
```

Non-palindrome example:

```bash
printf 'abc' > input.txt
qemu-riscv64 ./q5_test
```

Expected output:

```text
No
```

## Running the repository

Because Q1, Q2, Q3, and Q5 involve Linux RISC-V assembly or Linux RISC-V binaries, the intended way to run them is inside a Linux environment with RISC-V support.

A typical setup is:

- `riscv64-linux-gnu-gcc` for compiling assembly
- `qemu-riscv64` for running the produced binaries

For Q4, standard Linux `gcc` is sufficient.

## Autograder submission

To submit the repository:

```powershell
git status
git add q1/q1.s q2/q2.s q3/a/payload.txt q3/a/target_chandranisaha q3/b/payload q3/b/target_chandranisaha q4/q4.c q5/q5.s README.md
git commit -m "final submission"
git push origin main
```
