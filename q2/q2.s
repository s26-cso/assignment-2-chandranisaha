    .section .rodata
fmt_int:
    .asciz "%d"
fmt_last:
    .asciz "%d\n"
fmt_nl:
    .asciz "\n"

    .text
    .globl main

main:
    addi sp, sp, -80
    sd ra, 72(sp)
    sd s0, 64(sp)
    sd s1, 56(sp)
    sd s2, 48(sp)
    sd s3, 40(sp)
    sd s4, 32(sp)
    sd s5, 24(sp)
    sd s6, 16(sp)
    sd s7, 8(sp)
    sd s8, 0(sp)

    mv s0, a0              # argc
    mv s1, a1              # argv
    addi s2, s0, -1        # n = argc - 1

    blez s2, .print_empty

    # Allocate arrays for values, answers, and stack of indices.
    slli a0, s2, 2
    call malloc
    mv s3, a0              # values

    slli a0, s2, 4
    call malloc
    mv s4, a0              # answers as 64-bit entries

    slli a0, s2, 4
    call malloc
    mv s5, a0              # stack as 64-bit entries

    # Parse argv[1..argc-1] into values[].
    li s6, 0
.parse_loop:
    bge s6, s2, .parse_done
    addi t0, s6, 1
    slli t0, t0, 3
    add t0, s1, t0
    ld a0, 0(t0)
    li a1, 0
    li a2, 10
    call strtol
    slli t1, s6, 2
    add t1, s3, t1
    sw a0, 0(t1)
    addi s6, s6, 1
    j .parse_loop

.parse_done:
    li s6, 0               # stack size
    addi s7, s2, -1        # i = n - 1

.nge_outer:
    bltz s7, .print_results

    slli t0, s7, 2
    add t0, s3, t0
    lw t1, 0(t0)           # current value

.nge_pop_loop:
    beqz s6, .nge_stack_empty
    addi t2, s6, -1
    slli t3, t2, 3
    add t3, s5, t3
    ld t4, 0(t3)           # stack top index
    slli t5, t4, 2
    add t5, s3, t5
    lw t6, 0(t5)           # values[stack_top]
    blt t1, t6, .nge_found_top
    mv s6, t2
    j .nge_pop_loop

.nge_stack_empty:
    slli t2, s7, 3
    add t2, s4, t2
    li t3, -1
    sd t3, 0(t2)
    j .nge_push

.nge_found_top:
    slli t2, s7, 3
    add t2, s4, t2
    sd t4, 0(t2)

.nge_push:
    slli t2, s6, 3
    add t2, s5, t2
    sd s7, 0(t2)
    addi s6, s6, 1
    addi s7, s7, -1
    j .nge_outer

.print_results:
    li s8, 0
.print_loop:
    bge s8, s2, .done
    slli t0, s8, 3
    add t0, s4, t0
    ld a1, 0(t0)
    addi t1, s2, -1
    bne s8, t1, .print_mid
    la a0, fmt_last
    call printf
    j .done

.print_mid:
    la a0, fmt_int
    call printf
    li a0, ' '
    call putchar
    addi s8, s8, 1
    j .print_loop

.print_empty:
    la a0, fmt_nl
    call printf

.done:
    ld s8, 0(sp)
    ld s7, 8(sp)
    ld s6, 16(sp)
    ld s5, 24(sp)
    ld s4, 32(sp)
    ld s3, 40(sp)
    ld s2, 48(sp)
    ld s1, 56(sp)
    ld s0, 64(sp)
    ld ra, 72(sp)
    addi sp, sp, 80
    li a0, 0
    ret
