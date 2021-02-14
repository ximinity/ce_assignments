/* Based on the public domain implemntation in
 * crypto_stream/chacha20/e/ref from http://bench.cr.yp.to/supercop.html
 * by Daniel J. Bernstein */

#include <stdint.h>
#include "chacha20.h"

#define ROUNDS 20

__attribute__((section(".ccm")))
static uint32_t load_littleendian(const unsigned char *x)
{
  return
      (uint32_t) (x[0]) \
  | (((uint32_t) (x[1])) << 8) \
  | (((uint32_t) (x[2])) << 16) \
  | (((uint32_t) (x[3])) << 24);
}

__attribute__((section(".ccm")))
static void store_littleendian(unsigned char *x, uint32_t u)
{
  x[0] = u; u >>= 8;
  x[1] = u; u >>= 8;
  x[2] = u; u >>= 8;
  x[3] = u;
}

__attribute__((section(".ccm")))
static uint32_t rotate(uint32_t a, int d)
{
  uint32_t t;
  t = a >> (32-d);
  a <<= d;
  return a | t;
}

__attribute__((section(".ccm")))
static void quarterround(uint32_t *a, uint32_t *b, uint32_t *c, uint32_t *d)
{
  *a = *a + *b;
  *d = *d ^ *a;
  *d = rotate(*d, 16);

  *c = *c + *d;
  *b = *b ^ *c;
  *b = rotate(*b, 12);

  *a = *a + *b;
  *d = *d ^ *a;
  *d = rotate(*d, 8);

  *c = *c + *d;
  *b = *b ^ *c;
  *b = rotate(*b, 7);
}

static uint32_t x[16] __attribute__((section(".ccm_data"))) = { 0 };
static uint32_t j[16] __attribute__((section(".ccm_data"))) = { 0 };

__attribute__((section(".ccm")))
static int crypto_core_chacha20(
        unsigned char *out,
  const unsigned char *in,
  const unsigned char *k,
  const unsigned char *c
)
{
  int i;

  j[0]  = x[0]  = load_littleendian(c +  0);
  j[1]  = x[1]  = load_littleendian(c +  4);
  j[2]  = x[2]  = load_littleendian(c +  8);
  j[3]  = x[3]  = load_littleendian(c + 12);
  j[4]  = x[4]  = load_littleendian(k +  0);
  j[5]  = x[5]  = load_littleendian(k +  4);
  j[6]  = x[6]  = load_littleendian(k +  8);
  j[7]  = x[7]  = load_littleendian(k + 12);
  j[8]  = x[8]  = load_littleendian(k + 16);
  j[9]  = x[9]  = load_littleendian(k + 20);
  j[10] = x[10] = load_littleendian(k + 24);
  j[11] = x[11] = load_littleendian(k + 28);
  j[12] = x[12] = load_littleendian(in+  8);
  j[13] = x[13] = load_littleendian(in+ 12);
  j[14] = x[14] = load_littleendian(in+  0);
  j[15] = x[15] = load_littleendian(in+  4);

  for (i = ROUNDS;i > 0;i -= 2) {
    quarterround(&x[0], &x[4], &x[8],&x[12]);
    quarterround(&x[1], &x[5], &x[9],&x[13]);
    quarterround(&x[2], &x[6],&x[10],&x[14]);
    quarterround(&x[3], &x[7],&x[11],&x[15]);
    quarterround(&x[0], &x[5],&x[10],&x[15]);
    quarterround(&x[1], &x[6],&x[11],&x[12]);
    quarterround(&x[2], &x[7], &x[8],&x[13]);
    quarterround(&x[3], &x[4], &x[9],&x[14]);
  }

  x[0]+= j[0];
  x[1]+= j[1];
  x[2]+= j[2];
  x[3]+= j[3];
  x[4]+= j[4];
  x[5]+= j[5];
  x[6]+= j[6];
  x[7]+= j[7];
  x[8]+= j[8];
  x[9]+= j[9];
  x[10] += j[10];
  x[11] += j[11];
  x[12] += j[12];
  x[13] += j[13];
  x[14] += j[14];
  x[15] += j[15];

  store_littleendian(out + 0,  x[0]);
  store_littleendian(out + 4,  x[1]);
  store_littleendian(out + 8,  x[2]);
  store_littleendian(out + 12, x[3]);
  store_littleendian(out + 16, x[4]);
  store_littleendian(out + 20, x[5]);
  store_littleendian(out + 24, x[6]);
  store_littleendian(out + 28, x[7]);
  store_littleendian(out + 32, x[8]);
  store_littleendian(out + 36, x[9]);
  store_littleendian(out + 40, x[10]);
  store_littleendian(out + 44, x[11]);
  store_littleendian(out + 48, x[12]);
  store_littleendian(out + 52, x[13]);
  store_littleendian(out + 56, x[14]);
  store_littleendian(out + 60, x[15]);

  return 0;
}

static const unsigned char __attribute__((section(".ccm_rodata"))) sigma[16] = "expand 32-byte k";
static unsigned char in[16] __attribute__((section(".ccm_data"))) = { 0 };
static unsigned char block[64] __attribute__((section(".ccm_data"))) = { 0 };
static unsigned char kcopy[32] __attribute__((section(".ccm_data"))) = { 0 };

__attribute__((section(".ccm")))
int crypto_stream_chacha20(unsigned char *c,unsigned long long clen, const unsigned char *n, const unsigned char *k)
{
  unsigned long long i;
  unsigned int u;

  if (!clen) return 0;

  for (i = 0;i < 32;++i) kcopy[i] = k[i];
  for (i = 0;i < 8;++i) in[i] = n[i];
  for (i = 8;i < 16;++i) in[i] = 0;

  while (clen >= 64) {
    crypto_core_chacha20(c,in,kcopy,sigma);

    u = 1;
    for (i = 8;i < 16;++i) {
      u += (unsigned int) in[i];
      in[i] = u;
      u >>= 8;
    }

    clen -= 64;
    c += 64;
  }

  if (clen) {
    crypto_core_chacha20(block,in,kcopy,sigma);
    for (i = 0;i < clen;++i) c[i] = block[i];
  }
  return 0;
}
