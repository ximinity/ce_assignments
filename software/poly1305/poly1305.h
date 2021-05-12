#ifndef POLY1305_H
#define POLY1305_H

#define POLY1305_BYTES 16
#define POLY1305_KEYBYTES 32

typedef struct {
  uint32_t limbs[5];
} num_radix_26;

void radix_26_add(const num_radix_26 *const a, const num_radix_26 *const b, num_radix_26 *const out);

void radix_26_mulmod(const num_radix_26 *const a, const num_radix_26 *const b, num_radix_26 *const out);

int crypto_onetimeauth_poly1305(unsigned char *out,const unsigned char *in,unsigned long long inlen,const unsigned char *k);

#endif
