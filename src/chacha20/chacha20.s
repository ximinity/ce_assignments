.syntax unified

.macro DOUBLE_FULLROUND
    // Main optimization for fullround is that we can
    // a great deal of rotates with the barrel shifter
    // We also do as much intermediate
    // loads and stores to ensure the pipeline is filled.
    // We also much more efficiently use registers
    // We only need to do 20 stores and 20 loads
    // For a single double full round.
    // With 17 useable registers
    // We could do it with 16 loads and 16 stores
    // But we only have 13 registers.
    // So we have to load 4 values twice.
    // It's possible to do with with 15 loads and stores
    // since x15 is used twice in two subsequent
    // quarterrounds. But doing this means
    // you store x12-x15 in the non-constant
    // register. In the last 4 quarterrounds
    // however x12-x15 are used as `d`. `d`
    // cannot be conventiently modified with
    // the barrel shifter so it always requires
    // a ror instruction before being stored.
    // This means we have to choose:
    //    - Single store and load less.
    //    - 4 less ror instructions.
    // We have chosen to have 4 less ror instructions.

    ldr     r4,  [r0, #16]
    ldr     r12, [r0, #0]

    @ First quarterround
    @ a = r12, b = r4, c = r8, d = lr
    add     r12, r12, r4
    ldr     lr, [r0, #48]
    eor     lr, lr, r12
    ldr     r8, [r0, #32]
    add     r8, r8, lr, ror #16
    ldr     r5,  [r0, #20]
    eor     r4, r4, r8
    ldr     r9,  [r0, #36]
    add     r12, r12, r4, ror #20
    str     r12, [r0, #0]
    eor     lr, r12, lr, ror #16
    ldr     r1,  [r0, #52]
    add     r8, r8, lr, ror #24
    ldr     r12, [r0, #4]
    eor     r4, r8, r4, ror #20

    // Second quarterround
    // a = r12, b = r5, c = r9, d = r1
    add     r12, r12, r5
    ldr     r6,  [r0, #24]
    eor     r1, r1, r12
    add     r9, r9, r1, ror #16
    ldr     r10, [r0, #40]
    eor     r5, r5, r9
    add     r12, r12, r5, ror #20
    ldr     r2,  [r0, #56]
    eor     r1, r12, r1, ror #16
    str     r12, [r0, #4]
    add     r9, r9, r1, ror #24
    ldr     r12, [r0, #8]
    eor     r5, r9, r5, ror #20

    // Third quarterround
    // a = r12, b = r6, c = r10, d = r2
    add     r12, r12, r6
    eor     r2, r2, r12
    ldr     r7,  [r0, #28]
    add     r10, r10, r2, ror #16
    ldr     r11, [r0, #44]
    eor     r6, r6, r10
    add     r12, r12, r6, ror #20
    ldr     r3,  [r0, #60]
    eor     r2, r12, r2, ror #16
    add     r10, r10, r2, ror #24
    str     r12, [r0, #8]
    eor     r6, r10, r6, ror #20
    ldr     r12, [r0, #12]

    // Fourth quarterround
    // a = r12, b = r7, c = r11, d = r3
    add     r12, r12, r7
    eor     r3, r3, r12
    add     r11, r11, r3, ror #16
    eor     r7, r7, r11
    add     r12, r12, r7, ror #20
    str     r12, [r0, #12]
    eor     r3, r12, r3, ror #16
    add     r11, r11, r3, ror #24
    ldr     r12, [r0, #0]
    eor     r7, r11, r7, ror #20

    // Fifth quarterround
    // a = r12, b = r5, c = r10, d = r3
    add     r12, r12, r5, ror #25
    eor     r3, r12, r3, ror #24
    add     r10, r10, r3, ror #16
    eor     r5, r10, r5, ror #25
    add     r12, r12, r5, ror #20
    str     r12, [r0, #0]
    eor     r3, r12, r3, ror #16
    ldr     r12, [r0, #4]
    add     r10, r10, r3, ror #24
    ror     r3, r3, #24
    str     r10, [r0, #40]
    eor     r5, r10, r5, ror #20
    ror     r5, r5, #25
    str     r3, [r0, #60]

    // Sixth quarterround
    // a = r12, b = r6, c = r11, d = lr
    add     r12, r12, r6, ror #25
    eor     lr, r12, lr, ror #24
    str     r5, [r0, #20]
    add     r11, r11, lr, ror #16
    eor     r6, r11, r6, ror #25
    add     r12, r12, r6, ror #20
    str     r12, [r0, #4]
    eor     lr, r12, lr, ror #16
    add     r11, r11, lr, ror #24
    ldr     r12, [r0, #8]
    ror     lr, lr, #24    
    eor     r6, r11, r6, ror #20
    str     lr, [r0, #48]
    ror     r6, r6, #25

    // Seventh quarterround
    // a = r12, b = r7, c = r8, d = r1
    add     r12, r12, r7, ror #25
    eor     r1, r12, r1, ror #24
    str     r11, [r0, #44]
    add     r8, r8, r1, ror #16
    eor     r7, r8, r7, ror #25
    str     r6, [r0, #24]
    add     r12, r12, r7, ror #20
    eor     r1, r12, r1, ror #16
    str     r12, [r0, #8]
    add     r8, r8, r1, ror #24
    ror     r1, r1, #24
    str     r1, [r0, #52]
    eor     r7, r8, r7, ror #20
    ror     r7, r7, #25
    ldr     r12, [r0, #12]

    // Eighth quarterround
    // a = r12, b = r4, c = r9, d = r2
    add     r12, r12, r4, ror #25
    eor     r2, r12, r2, ror #24
    str     r8, [r0, #32]
    add     r9, r9, r2, ror #16
    eor     r4, r9, r4, ror #25
    str     r7, [r0, #28]
    add     r12, r12, r4, ror #20
    eor     r2, r12, r2, ror #16
    str     r12, [r0, #12]
    add     r9, r9, r2, ror #24
    ror     r2, r2, #24
    str     r9,  [r0, #36]
    eor     r4, r9, r4, ror #20
    str     r2, [r0, #56]
    ror     r4, r4, #25
    str     r4, [r0, #16]
.endm

//.section .ccm, "ax"
.global ten_double_fullround
ten_double_fullround:
    push    {lr}
    DOUBLE_FULLROUND
    DOUBLE_FULLROUND
    DOUBLE_FULLROUND
    DOUBLE_FULLROUND
    DOUBLE_FULLROUND
    DOUBLE_FULLROUND
    DOUBLE_FULLROUND
    DOUBLE_FULLROUND
    DOUBLE_FULLROUND
    DOUBLE_FULLROUND
    pop     {lr}
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
    // We do not have to keep setting
    // r0 to r3 because double_fullround
    // does not set these registers
    bl ten_double_fullround

    // This is adding every element in j to x.
    // The original code stored this result in x
    // but this is not necessary since x is never
    // read out afterwards. So we just load
    // every element from x and j, add them and
    // then store them directly into out.
    mov r1, r0
    ldr r2, =j
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
