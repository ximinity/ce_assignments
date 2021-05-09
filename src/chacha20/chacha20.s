.syntax unified

.macro QUARTERROUND_1 x,a,b,c,d,stAddr,ldAddr
    add     \a, \a, \b
    eor     \d, \d, \a
    add     \c, \c, \d, ror #16
    eor     \b, \b, \c
    add     \a, \a, \b, ror #20
    str     \a, [\x, \stAddr]
    eor     \d, \a, \d, ror #16
    add     \c, \c, \d, ror #24
    ldr     \a, [\x, \ldAddr]
    eor     \b, \c, \b, ror #20
.endm

.macro QUARTERROUND_2 x,a,b,c,d,stAddr,ldAddr,ldNext
    add     \a, \a, \b, ror #25
    eor     \d, \a, \d, ror #24
    add     \c, \c, \d, ror #16
    eor     \b, \c, \b, ror #25
    add     \a, \a, \b, ror #20
    str     \a, [\x, \stAddr]
    eor     \d, \a, \d, ror #16
    add     \c, \c, \d, ror #24
    ror     \d, \d, #24
.if \ldNext
    ldr     \a, [\x, \ldAddr]
.endif
    eor     \b, \c, \b, ror #20
    ror     \b, \b, #25
.endm


.macro DOUBLE_FULLROUND
    // Main optimization for fullround is that we can
    // a great deal of rotates with the barrel shifter
    // We also do as much intermediate
    // loads and stores to ensure the pipeline is filled.
    // We also much more efficiently use registers
    // We only need to do 8 stores and 8 loads
    // For a single double full round.
    // With 17 useable registers
    // We could do it with no loads and stores
    // But we only have 13 registers.
    // So we have to load/store 4 values twice.
    // It's possible to do with with 6 loads and stores
    // since x15 is used twice in two subsequent
    // quarterrounds. But doing this means
    // you store x12-x15 in the non-constant
    // register. In the last 4 quarterrounds
    // however x12-x15 are used as `d`. `d`
    // cannot be conveniently modified with
    // the barrel shifter so it always requires
    // a ror instruction before being stored.
    // This means we have to choose:
    //    - Single store and load less.
    //    - 4 less ror instructions.
    // We have chosen to have 4 less ror instructions.

    ldr     r12, [r0, #0]

    QUARTERROUND_1 r0, r12, r4, r8,  lr, #0,  #4
    QUARTERROUND_1 r0, r12, r5, r9,  r1, #4,  #8
    QUARTERROUND_1 r0, r12, r6, r10, r2, #8,  #12
    QUARTERROUND_1 r0, r12, r7, r11, r3, #12, #0

    QUARTERROUND_2 r0, r12, r5, r10, r3, #0,  #4,  1
    QUARTERROUND_2 r0, r12, r6, r11, lr, #4,  #8,  1
    QUARTERROUND_2 r0, r12, r7, r8,  r1, #8,  #12, 1
    QUARTERROUND_2 r0, r12, r4, r9,  r2, #12, #0,  0

.endm

//.section .ccm, "ax"
.global ten_double_fullround
ten_double_fullround:
    push    {lr}
    // Load x4-x15 into registers
    ldr     r4,  [r0, #16]
    ldr     r5,  [r0, #20]
    ldr     r6,  [r0, #24]
    ldr     r7,  [r0, #28]
    ldr     r8,  [r0, #32]
    ldr     r9,  [r0, #36]
    ldr     r10, [r0, #40]
    ldr     r11, [r0, #44]
    ldr     lr,  [r0, #48]
    ldr     r1,  [r0, #52]
    ldr     r2,  [r0, #56]
    ldr     r3,  [r0, #60]

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

    str     r4,  [r0, #16]
    str     r5,  [r0, #20]
    str     r6,  [r0, #24]
    str     r7,  [r0, #28]
    str     r8,  [r0, #32]
    str     r9,  [r0, #36]
    str     r10, [r0, #40]
    str     r11, [r0, #44]
    str     lr,  [r0, #48]
    str     r1,  [r0, #52]
    str     r2,  [r0, #56]
    str     r3,  [r0, #60]

    pop     {lr}
    bx      lr

.global crypto_core_chacha20
crypto_core_chacha20:
    push {r0, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}

    ldr r0,  =x
    ldr r9,  =j
    // `load_littleendian` loads
    // Since our platform is little endian
    // We can just do LDR without any manual
    // endian conversion.
    // We do intermediate loads and stores as much
    // as possible to achieve maximum pipelining
    ldr r4,  [r3] 
    ldr r5,  [r3, #4] 
    ldr r6,  [r3, #8] 
    ldr r7,  [r3, #12] 
    ldr r8,  [r2] 
    ldr r10, [r2, #4] 
    ldr r11, [r2, #8] 
    ldr r12, [r2, #12] 
    str r4,  [r0] 
    str r4,  [r9] 
    ldr r4,  [r2, #16] 
    str r5,  [r0, #4] 
    str r5,  [r9, #4] 
    ldr r5,  [r2, #20] 
    str r6,  [r0, #8] 
    str r6,  [r9, #8] 
    ldr r6,  [r2, #24] 
    str r7,  [r0, #12] 
    str r7,  [r9, #12] 
    ldr r7,  [r2, #28] 
    str r8,  [r0, #16] 
    str r8,  [r9, #16] 
    ldr r8,  [r1, #8] 
    str r10, [r0, #20] 
    str r10, [r9, #20] 
    ldr r10, [r1, #12] 
    str r11, [r0, #24] 
    str r11, [r9, #24] 
    ldr r11, [r1] 
    str r12, [r0, #28] 
    str r12, [r9, #28] 
    ldr r12, [r1, #4] 
    str r4,  [r0, #32] 
    str r4,  [r9, #32] 
    str r5,  [r0, #36] 
    str r5,  [r9, #36] 
    str r6,  [r0, #40] 
    str r6,  [r9, #40] 
    str r7,  [r0, #44] 
    str r7,  [r9, #44] 
    str r8,  [r0, #48] 
    str r8,  [r9, #48] 
    str r10, [r0, #52] 
    str r10, [r9, #52] 
    str r11, [r0, #56] 
    str r11, [r9, #56] 
    str r12, [r0, #60] 
    str r12, [r9, #60]

    // Run 10x double fullrounds
    // r0 is allready the correct
    // value. We also don't have
    // to restore any other registers
    // since in the next part we don't
    // use them anyway.
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
    add r3,  r3,  r4
    str r3,  [r0]
    ldr r3,  [r1, #20]
    ldr r4,  [r2, #20]
    add r5,  r5,  r6
    str r5,  [r0, #4]
    ldr r5,  [r1, #24]
    ldr r6,  [r2, #24]
    add r7,  r7,  r8
    str r7,  [r0, #8]
    ldr r7,  [r1, #28]
    ldr r8,  [r2, #28]
    add r9,  r9,  r10
    str r9,  [r0, #12]
    ldr r9,  [r1, #32]
    ldr r10, [r2, #32]
    add r11, r11,  r12
    str r11, [r0, #16]
    ldr r11, [r1, #36]
    ldr r12, [r2, #36]
    add r3,  r3,  r4
    str r3,  [r0, #20]
    ldr r3,  [r1, #40]
    ldr r4,  [r2, #40]
    add r5,  r5,  r6
    str r5,  [r0, #24]
    ldr r5,  [r1, #44]
    ldr r6,  [r2, #44]
    add r7,  r7,  r8
    str r7,  [r0, #28]
    ldr r7,  [r1, #48]
    ldr r8,  [r2, #48]
    add r9,  r9,  r10
    str r9,  [r0, #32]
    ldr r9,  [r1, #52]
    ldr r10, [r2, #52]
    add r11, r11, r12
    str r11, [r0, #36]
    ldr r11, [r1, #56]
    ldr r12, [r2, #56]
    add r3,  r3,  r4
    str r3,  [r0, #40]
    ldr r3,  [r1, #60]
    ldr r4,  [r2, #60]
    add r5,  r5,  r6
    str r5,  [r0, #44]
    add r7,  r7,  r8
    str r7,  [r0, #48]
    add r9,  r9,  r10
    str r9,  [r0, #52]
    add r11, r11, r12
    str r11, [r0, #56]
    add r3,  r3,  r4
    str r3,  [r0, #60]

    pop {r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
    bx  lr
