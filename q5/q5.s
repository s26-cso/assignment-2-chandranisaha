    .section .rodata
input_path:
    .asciz "input.txt"
read_mode:
    .asciz "r"
yes_text:
    .asciz "Yes"
no_text:
    .asciz "No"

    .text
    .globl main

main:
    addi sp, sp, -48
    sd ra, 40(sp)
    sd s0, 32(sp)
    sd s1, 24(sp)
    sd s2, 16(sp)
    sd s3, 8(sp)
    sd s4, 0(sp)

    la a0, input_path
    la a1, read_mode
    call fopen
    beqz a0, .print_no
    mv s0, a0

    mv a0, s0
    li a1, 0
    li a2, 2
    call fseek
    bnez a0, .close_and_no

    mv a0, s0
    call ftell
    bltz a0, .close_and_no
    mv s1, a0

    li s2, 0
    addi s3, s1, -1

.compare_loop:
    bge s2, s3, .close_and_yes

    mv a0, s0
    mv a1, s2
    li a2, 0
    call fseek
    bnez a0, .close_and_no

    mv a0, s0
    call fgetc
    bltz a0, .close_and_no
    mv s4, a0

    mv a0, s0
    mv a1, s3
    li a2, 0
    call fseek
    bnez a0, .close_and_no

    mv a0, s0
    call fgetc
    bltz a0, .close_and_no
    bne s4, a0, .close_and_no

    addi s2, s2, 1
    addi s3, s3, -1
    j .compare_loop

.close_and_yes:
    mv a0, s0
    call fclose
    la a0, yes_text
    call puts
    j .done

.close_and_no:
    mv a0, s0
    call fclose

.print_no:
    la a0, no_text
    call puts

.done:
    ld s4, 0(sp)
    ld s3, 8(sp)
    ld s2, 16(sp)
    ld s1, 24(sp)
    ld s0, 32(sp)
    ld ra, 40(sp)
    addi sp, sp, 48
    li a0, 0
    ret
