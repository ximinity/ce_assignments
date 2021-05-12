/*
20080912
D. J. Bernstein
Public domain.
*/
#include <stdint.h>

#include <stdio.h>
#include "hal.h"

#include "poly1305.h"

static void add(uint32_t h[17],const uint32_t c[17])
{
  uint32_t j;
  uint32_t u;
  u = 0;
  for (j = 0;j < 17;++j) { u += h[j] + c[j]; h[j] = u & 255; u >>= 8; }
}

static void squeeze(uint32_t h[17])
{
  uint32_t j;
  uint32_t u;
  u = 0;
  for (j = 0;j < 16;++j) { u += h[j]; h[j] = u & 255; u >>= 8; }
  u += h[16]; h[16] = u & 3;
  u = 5 * (u >> 2);
  for (j = 0;j < 16;++j) { u += h[j]; h[j] = u & 255; u >>= 8; }
  u += h[16]; h[16] = u;
}

static const uint32_t minusp[17] = {
  5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 252
} ;

static void freeze(uint32_t h[17])
{
  uint32_t horig[17];
  uint32_t j;
  uint32_t negative;
  for (j = 0;j < 17;++j) horig[j] = h[j];
  add(h,minusp);
  negative = -(h[16] >> 7);
  for (j = 0;j < 17;++j) h[j] ^= negative & (horig[j] ^ h[j]);
}

static void mulmod(uint32_t h[17],const uint32_t r[17])
{
  uint32_t hr[17];
  uint32_t i;
  uint32_t j;
  uint32_t u;

  for (i = 0;i < 17;++i) {
    u = 0;
    for (j = 0;j <= i;++j) u += h[j] * r[i - j];
    for (j = i + 1;j < 17;++j) u += 320 * h[j] * r[i + 17 - j];
    hr[i] = u;
  }
  for (i = 0;i < 17;++i) h[i] = hr[i];
  squeeze(h);
}

uint32_t r[17] = { 0 };
uint32_t h[17] = { 0 };
uint32_t c[17] = { 0 };

static const uint32_t radix = 26;
static const uint32_t max_num_radix = (1 << radix) - 1;

void radix_26_add(const num_radix_26 *const a, const num_radix_26 *const b, num_radix_26 *const out) {
  uint8_t i = 0;
  uint32_t u = 0;
  
  for (i = 0; i < 5; ++i) {
    u += a->limbs[i] + b->limbs[i]; 
    out->limbs[i] = u & max_num_radix;
    u >>= radix;
  }
}

void radix_26_mulmod(const num_radix_26 *const a, const num_radix_26 *const b, num_radix_26 *const out) {
  uint64_t mul[5];

  const uint32_t* const al = a->limbs;
  const uint32_t* const bl = b->limbs;

  mul[0] = (uint64_t)al[0] * (uint64_t)bl[0] + (uint64_t)5 * ((uint64_t)al[1] * (uint64_t)bl[4] + (uint64_t)al[2] * (uint64_t)bl[3] + (uint64_t)al[3] * (uint64_t)bl[2] + (uint64_t)al[4] * (uint64_t)bl[1]);
  mul[1] = (uint64_t)al[0] * (uint64_t)bl[1] + (uint64_t)al[1] * (uint64_t)bl[0] + 5 * ((uint64_t)al[2] * (uint64_t)bl[4] + (uint64_t)al[3] * (uint64_t)bl[3] + (uint64_t)al[4] * (uint64_t)bl[2]); 
  mul[2] = (uint64_t)al[0] * (uint64_t)bl[2] + (uint64_t)al[1] * (uint64_t)bl[1] + (uint64_t)al[2] * (uint64_t)bl[0] + (uint64_t)5 * ((uint64_t)al[3] * (uint64_t)bl[4] + (uint64_t)al[4] * (uint64_t)bl[3]);
  mul[3] = (uint64_t)al[0] * (uint64_t)bl[3] + (uint64_t)al[1] * (uint64_t)bl[2] + (uint64_t)al[2] * (uint64_t)bl[1] + (uint64_t)al[3] * (uint64_t)bl[0] + (uint64_t)5 * (uint64_t)al[4] * (uint64_t)bl[4];
  mul[4] = (uint64_t)al[0] * (uint64_t)bl[4] + (uint64_t)al[1] * (uint64_t)bl[3] + (uint64_t)al[2] * (uint64_t)bl[2] + (uint64_t)al[3] * (uint64_t)bl[1] + (uint64_t)al[4] * (uint64_t)bl[0];


  uint64_t carry = 0;
  // TODO: leak
  do {
      mul[0] += carry * 5;  carry = mul[0] >> 26;  mul[0] -= carry << 26;
      mul[1] += carry    ;  carry = mul[1] >> 26;  mul[1] -= carry << 26;
      mul[2] += carry    ;  carry = mul[2] >> 26;  mul[2] -= carry << 26;
      mul[3] += carry    ;  carry = mul[3] >> 26;  mul[3] -= carry << 26;
      mul[4] += carry    ;  carry = mul[4] >> 26;  mul[4] -= carry << 26;
  } while (carry != 0); 

  out->limbs[0] = (uint32_t)mul[0];
  out->limbs[1] = (uint32_t)mul[1];
  out->limbs[2] = (uint32_t)mul[2];
  out->limbs[3] = (uint32_t)mul[3];
  out->limbs[4] = (uint32_t)mul[4];
}

int crypto_onetimeauth_poly1305(unsigned char *out,const unsigned char *in,unsigned long long inlen,const unsigned char *k)
{
  uint32_t j;

  r[0] = k[0];
  r[1] = k[1];
  r[2] = k[2];
  r[3] = k[3] & 15;
  r[4] = k[4] & 252;
  r[5] = k[5];
  r[6] = k[6];
  r[7] = k[7] & 15;
  r[8] = k[8] & 252;
  r[9] = k[9];
  r[10] = k[10];
  r[11] = k[11] & 15;
  r[12] = k[12] & 252;
  r[13] = k[13];
  r[14] = k[14];
  r[15] = k[15] & 15;
  r[16] = 0;

  for (j = 0;j < 17;++j) h[j] = 0;

  while (inlen > 0) {
    for (j = 0;j < 17;++j) c[j] = 0;
    for (j = 0;(j < 16) && (j < inlen);++j) c[j] = in[j];
    c[j] = 1;
    in += j; inlen -= j;
    add(h,c);
    mulmod(h,r);
  }

  freeze(h);

  for (j = 0;j < 16;++j) c[j] = k[j + 16];
  c[16] = 0;
  add(h,c);
  for (j = 0;j < 16;++j) out[j] = h[j];
  return 0;
}
