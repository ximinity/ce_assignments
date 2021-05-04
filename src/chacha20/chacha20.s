.syntax unified
.set ROUNDS, 20

.section .ccm, "ax"
.global double_fullround
double_fullround:
    // Main optimization for fullround is that we can
    // replace the rotate function with a single ror
    // instruction. We also do as much intermediate
    // stores to ensure the pipeline is filled.
    push    {r4, r5, r6, r7, r8, r10, r11, r12, lr}
    mov     r8, r0
    mov     r10, r1
    mov     r11, r2
    mov     r12, r3

    ldr     r4, [r8]
    ldr     r5, [r10]
    ldr     r6, [r11]
    ldr     r7, [r12]
    add     r4, r4, r5
    eor     r7, r7, r4
    ror     r7, r7, #16
    add     r6, r6, r7
    eor     r5, r5, r6
    ror     r5, r5, #20
    add     r4, r4, r5
    str     r4,  [r8]
    eor     r7, r7, r4
    ror     r7, r7, #24
    str     r7, [r12]
    add     r6, r6, r7
    str     r6, [r11]
    eor     r5, r5, r6
    ror     r5, r5, #25
    str     r5, [r10]

    ldr     r4, [r8,  #4]
    ldr     r5, [r10, #4]
    ldr     r6, [r11, #4]
    ldr     r7, [r12, #4]
    add     r4, r4, r5
    eor     r7, r7, r4
    ror     r7, r7, #16
    add     r6, r6, r7
    eor     r5, r5, r6
    ror     r5, r5, #20
    add     r4, r4, r5
    str     r4,  [r8, #4]
    eor     r7, r7, r4
    ror     r7, r7, #24
    str     r7, [r12, #4]
    add     r6, r6, r7
    str     r6, [r11, #4]
    eor     r5, r5, r6
    ror     r5, r5, #25
    str     r5, [r10, #4]

    ldr     r4, [r8,  #8]
    ldr     r5, [r10, #8]
    ldr     r6, [r11, #8]
    ldr     r7, [r12, #8]
    add     r4, r4, r5
    eor     r7, r7, r4
    ror     r7, r7, #16
    add     r6, r6, r7
    eor     r5, r5, r6
    ror     r5, r5, #20
    add     r4, r4, r5
    str     r4,  [r8, #8]
    eor     r7, r7, r4
    ror     r7, r7, #24
    str     r7, [r12, #8]
    add     r6, r6, r7
    str     r6, [r11, #8]
    eor     r5, r5, r6
    ror     r5, r5, #25
    str     r5, [r10, #8]

    ldr     r4, [r8,  #12]
    ldr     r5, [r10, #12]
    ldr     r6, [r11, #12]
    ldr     r7, [r12, #12]
    add     r4, r4, r5
    eor     r7, r7, r4
    ror     r7, r7, #16
    add     r6, r6, r7
    eor     r5, r5, r6
    ror     r5, r5, #20
    add     r4, r4, r5
    str     r4,  [r8, #12]
    eor     r7, r7, r4
    ror     r7, r7, #24
    str     r7, [r12, #12]
    add     r6, r6, r7
    str     r6, [r11, #12]
    eor     r5, r5, r6
    ror     r5, r5, #25
    str     r5, [r10, #12]

    ldr     r4, [r8]
    ldr     r5, [r10, #4]
    ldr     r6, [r11, #8]
    ldr     r7, [r12, #12]
    add     r4, r4, r5
    eor     r7, r7, r4
    ror     r7, r7, #16
    add     r6, r6, r7
    eor     r5, r5, r6
    ror     r5, r5, #20
    add     r4, r4, r5
    str     r4,  [r8]
    eor     r7, r7, r4
    ror     r7, r7, #24
    str     r7, [r12, #12]
    add     r6, r6, r7
    str     r6, [r11, #8]
    eor     r5, r5, r6
    ror     r5, r5, #25
    str     r5, [r10, #4]

    ldr     r4, [r8,  #4]
    ldr     r5, [r10, #8]
    ldr     r6, [r11, #12]
    ldr     r7, [r12]
    add     r4, r4, r5
    eor     r7, r7, r4
    ror     r7, r7, #16
    add     r6, r6, r7
    eor     r5, r5, r6
    ror     r5, r5, #20
    add     r4, r4, r5
    str     r4,  [r8, #4]
    eor     r7, r7, r4
    ror     r7, r7, #24
    str     r7, [r12]
    add     r6, r6, r7
    str     r6, [r11, #12]
    eor     r5, r5, r6
    ror     r5, r5, #25
    str     r5, [r10, #8]

    ldr     r4, [r8,  #8]
    ldr     r5, [r10, #12]
    ldr     r6, [r11]
    ldr     r7, [r12, #4]
    add     r4, r4, r5
    eor     r7, r7, r4
    ror     r7, r7, #16
    add     r6, r6, r7
    eor     r5, r5, r6
    ror     r5, r5, #20
    add     r4, r4, r5
    str     r4,  [r8, #8]
    eor     r7, r7, r4
    ror     r7, r7, #24
    str     r7, [r12, #4]
    add     r6, r6, r7
    str     r6, [r11]
    eor     r5, r5, r6
    ror     r5, r5, #25
    str     r5, [r10, #12]

    ldr     r4, [r8,  #12]
    ldr     r5, [r10]
    ldr     r6, [r11, #4]
    ldr     r7, [r12, #8]
    add     r4, r4, r5
    eor     r7, r7, r4
    ror     r7, r7, #16
    add     r6, r6, r7
    eor     r5, r5, r6
    ror     r5, r5, #20
    add     r4, r4, r5
    str     r4,  [r8, #12]
    eor     r7, r7, r4
    ror     r7, r7, #24
    str     r7, [r12, #8]
    add     r6, r6, r7
    str     r6, [r11, #4]
    eor     r5, r5, r6
    ror     r5, r5, #25
    str     r5, [r10]

    pop     {r4, r5, r6, r7, r8, r10, r11, r12, lr}
    bx      lr

.global crypto_core_chacha20
crypto_core_chacha20:
    push {r0, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
    ldr r0, =x
    ldr r9, =j
    // `load_littleendian` loads
    // Since our platform is little endian
    // We can just do LDR without any manual
    // endian conversion.
    // We do intermediate loads and stores as much
    // as possible to achieve maximum pipelining
    ldr r4, [r3] 
    ldr r5, [r3, #4] 
    ldr r6, [r3, #8] 
    ldr r7, [r3, #12] 
    ldr r8, [r2] 
    ldr r10, [r2, #4] 
    ldr r11, [r2, #8] 
    ldr r12, [r2, #12] 
    str r4, [r0] 
    str r4, [r9] 
    ldr r4, [r2, #16] 
    str r5, [r0, #4] 
    str r5, [r9, #4] 
    ldr r5, [r2, #20] 
    str r6, [r0, #8] 
    str r6, [r9, #8] 
    ldr r6, [r2, #24] 
    str r7, [r0, #12] 
    str r7, [r9, #12] 
    ldr r7, [r2, #28] 
    str r8, [r0, #16] 
    str r8, [r9, #16] 
    ldr r8, [r1, #8] 
    str r10, [r0, #20] 
    str r10, [r9, #20] 
    ldr r10, [r1, #12] 
    str r11, [r0, #24] 
    str r11, [r9, #24] 
    ldr r11, [r1] 
    str r12, [r0, #28] 
    str r12, [r9, #28] 
    ldr r12, [r1, #4] 
    str r4, [r0, #32] 
    str r4, [r9, #32] 
    str r5, [r0, #36] 
    str r5, [r9, #36] 
    str r6, [r0, #40] 
    str r6, [r9, #40] 
    str r7, [r0, #44] 
    str r7, [r9, #44] 
    str r8, [r0, #48] 
    str r8, [r9, #48] 
    str r10, [r0, #52] 
    str r10, [r9, #52] 
    str r11, [r0, #56] 
    str r11, [r9, #56] 
    str r12, [r0, #60] 
    str r12, [r9, #60]

    // Run 10x double fullrounds
    mov r5, r0
    add r6, r0, #16
    add r7, r0, #32
    add r8, r0, #48
    mov r4, #ROUNDS
.core_loop_cond:
    cmp r4, #1
    blt .core_loop_done
.core_loop_inner:
    mov r0, r5
    mov r1, r6
    mov r2, r7
    mov r3, r8
    bl double_fullround
.core_loop_incr:
    sub r4, r4, #2
    b .core_loop_cond
.core_loop_done:

    // This is adding every element in j to x.
    // The original code stored this result in x
    // but this is not necessary since x is never
    // read out afterwards. So we just load
    // every element from x and j, add them and
    // then store them directly into out.
    mov r1, r5
    mov r2, r9
    pop {r0}
    // Load 5 initial
    ldr r3,  [r1]
    ldr r4,  [r2]
    ldr r5,  [r1, #4]
    ldr r6,  [r2, #4]
    ldr r7,  [r1, #8]
    ldr r8,  [r2, #8]
    ldr r9,  [r1, #12]
    ldr r10, [r2, #12]
    ldr r11, [r1, #16]
    ldr r12, [r2, #16]
    // intermediate stores and loads
    add r3, r3, r4
    str r3, [r0]
    ldr r3, [r1, #20]
    ldr r4, [r2, #20]
    add r5, r5, r6
    str r5, [r0, #4]
    ldr r5, [r1, #24]
    ldr r6, [r2, #24]
    add r7, r7, r8
    str r7, [r0, #8]
    ldr r7, [r1, #28]
    ldr r8, [r2, #28]
    add r9, r9, r10
    str r9, [r0, #12]
    ldr r9, [r1, #32]
    ldr r10, [r2, #32]
    add r11, r11, r12
    str r11, [r0, #16]
    ldr r11, [r1, #36]
    ldr r12, [r2, #36]
    add r3, r3, r4
    str r3, [r0, #20]
    ldr r3,  [r1, #40]
    ldr r4,  [r2, #40]
    add r5, r5, r6
    str r5, [r0, #24]
    ldr r5, [r1, #44]
    ldr r6, [r2, #44]
    add r7, r7, r8
    str r7, [r0, #28]
    ldr r7, [r1, #48]
    ldr r8, [r2, #48]
    add r9, r9, r10
    str r9, [r0, #32]
    ldr r9, [r1, #52]
    ldr r10, [r2, #52]
    add r11, r11, r12
    str r11, [r0, #36]
    ldr r11, [r1, #56]
    ldr r12, [r2, #56]
    add r3, r3, r4
    str r3, [r0, #40]
    ldr r3,  [r1, #60]
    ldr r4,  [r2, #60]
    add r5, r5, r6
    str r5, [r0, #44]
    add r7, r7, r8
    str r7, [r0, #48]
    add r9, r9, r10
    str r9, [r0, #52]
    add r11, r11, r12
    str r11, [r0, #56]
    add r3, r3, r4
    str r3, [r0, #60]

    pop {r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
    bx lr
