    .text

    .globl make_node
    .globl insert
    .globl get
    .globl getAtMost

make_node:
    addi sp, sp, -16
    sd ra, 8(sp)
    sd s0, 0(sp)
    mv s0, a0

    # Allocate space for {int val; padding; Node* left; Node* right}.
    li a0, 24
    call malloc
    beqz a0, .make_node_done

    sw s0, 0(a0)
    sd zero, 8(a0)
    sd zero, 16(a0)

.make_node_done:
    ld s0, 0(sp)
    ld ra, 8(sp)
    addi sp, sp, 16
    ret

insert:
    beqz a0, .insert_make_root

    addi sp, sp, -32
    sd ra, 24(sp)
    sd s0, 16(sp)
    sd s1, 8(sp)
    sd s2, 0(sp)

    mv s0, a0
    mv s1, a0
    mv s2, a1

.insert_loop:
    lw t0, 0(s1)
    blt s2, t0, .insert_left
    bgt s2, t0, .insert_right
    # Ignore duplicates and preserve the existing root.
    mv a0, s0
    j .insert_done

.insert_left:
    ld t1, 8(s1)
    beqz t1, .insert_attach_left
    mv s1, t1
    j .insert_loop

.insert_attach_left:
    mv a0, s2
    call make_node
    sd a0, 8(s1)
    mv a0, s0
    j .insert_done

.insert_right:
    ld t1, 16(s1)
    beqz t1, .insert_attach_right
    mv s1, t1
    j .insert_loop

.insert_attach_right:
    mv a0, s2
    call make_node
    sd a0, 16(s1)
    mv a0, s0

.insert_done:
    ld s2, 0(sp)
    ld s1, 8(sp)
    ld s0, 16(sp)
    ld ra, 24(sp)
    addi sp, sp, 32
    ret

.insert_make_root:
    mv a0, a1
    tail make_node

get:
.get_loop:
    beqz a0, .get_not_found
    lw t0, 0(a0)
    beq a1, t0, .get_found
    blt a1, t0, .get_go_left
    ld a0, 16(a0)
    j .get_loop

.get_go_left:
    ld a0, 8(a0)
    j .get_loop

.get_found:
    ret

.get_not_found:
    li a0, 0
    ret

getAtMost:
    # Track the best value seen so far that is <= target.
    li a2, -1

.getatmost_loop:
    beqz a1, .getatmost_done
    lw t0, 0(a1)
    blt a0, t0, .getatmost_left

    mv a2, t0
    ld a1, 16(a1)
    j .getatmost_loop

.getatmost_left:
    ld a1, 8(a1)
    j .getatmost_loop

.getatmost_done:
    mv a0, a2
    ret
