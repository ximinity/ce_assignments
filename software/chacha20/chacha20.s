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

    ldr     lr, [r0, #0]

    QUARTERROUND_1 r0, lr, r4, r8,  r12, #0,  #4
    QUARTERROUND_1 r0, lr, r5, r9,  r1, #4,  #8
    QUARTERROUND_1 r0, lr, r6, r10, r2, #8,  #12
    QUARTERROUND_1 r0, lr, r7, r11, r3, #12, #0

    QUARTERROUND_2 r0, lr, r5, r10, r3, #0,  #4,  1
    QUARTERROUND_2 r0, lr, r6, r11, r12, #4,  #8,  1
    QUARTERROUND_2 r0, lr, r7, r8,  r1, #8,  #12, 1
    QUARTERROUND_2 r0, lr, r4, r9,  r2, #12, #0,  0

.endm

.global crypto_core_chacha20
crypto_core_chacha20:
    push {r2, r0, r1, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}

    ldr r0,  =x
    // `load_littleendian` loads
    // Since our platform is little endian
    // We can just do LDR without any manual
    // endian conversion.
    ldr     lr,  [r3, #0]
    ldr     r4,  [r2, #0]
    str     lr,  [r0, #0]
    ldr     r5,  [r2, #4]
    ldr     lr,  [r3, #4]
    ldr     r6,  [r2, #8]
    str     lr,  [r0, #4]
    ldr     r7,  [r2, #12]
    ldr     lr,  [r3, #8]
    ldr     r8,  [r2, #16]
    str     lr,  [r0, #8]
    ldr     r9,  [r2, #20]
    ldr     r10, [r2, #24]
    ldr     lr,  [r3, #12]
    ldr     r11, [r2, #28]
    ldr     r12, [r1, #48]
    str     lr,  [r0, #12]
    ldr     r2,  [r1, #56]
    ldr     r3,  [r1, #60]
    ldr     r1,  [r1, #52]


    // Run 10x double fullrounds
    // r0 is allready the correct
    // value. We also don't have
    // to restore any other registers
    // since in the next part we don't
    // use them anyway.
    // Load x4-x15 into registers

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

    pop     {r0}  // *k

    ldr     lr,  [r0, #0]
    add     lr,  lr, r4
    pop     {r4} // *out
    str     lr,  [r4, #16]

    ldr     lr,  [r0, #4]
    add     lr,  lr, r5
    str     lr,  [r4, #20]

    ldr     lr,  [r0, #8]
    add     lr,  lr, r6
    str     lr,  [r4, #24]

    ldr     lr,  [r0, #12]
    add     lr,  lr, r7
    str     lr,  [r4, #28]

    ldr     lr,  [r0, #16]
    add     lr,  lr, r8
    str     lr,  [r4, #32]

    ldr     lr,  [r0, #20]
    add     lr,  lr, r9
    str     lr,  [r4, #36]

    ldr     lr,  [r0, #24]
    add     lr,  lr, r10
    str     lr,  [r4, #40]

    ldr     lr,  [r0, #28]
    add     lr,  lr, r11
    str     lr,  [r4, #44]

    pop     {r0} // *in

    ldr     lr,  [r0, #0]
    add     lr,  lr, r12
    str     lr,  [r4, #48]

    ldr     lr,  [r0, #4]
    add     lr,  lr, r1
    str     lr,  [r4, #52]

    ldr     lr,  [r0, #8]
    add     lr,  lr, r2
    str     lr,  [r4, #56]

    ldr     lr,  [r0, #12]
    add     lr,  lr, r3
    str     lr,  [r4, #60]

    pop     {r0}   // *c
    ldr     r1, =x

    ldr     lr,  [r0, #0]
    ldr     r2,  [r1, #0]
    add     lr,  lr, r2
    str     lr,  [r4, #0]

    ldr     lr,  [r0, #4]
    ldr     r2,  [r1, #4]
    add     lr,  lr, r2
    str     lr,  [r4, #4]

    ldr     lr,  [r0, #8]
    ldr     r2,  [r1, #8]
    add     lr,  lr, r2
    str     lr,  [r4, #8]

    ldr     lr,  [r0, #12]
    ldr     r2,  [r1, #12]
    add     lr,  lr, r2
    str     lr,  [r4, #12]

    pop {r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
    bx  lr
