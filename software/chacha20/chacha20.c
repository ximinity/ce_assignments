/* Based on the public domain implemntation in
 * crypto_stream/chacha20/e/ref from http://bench.cr.yp.to/supercop.html
 * by Daniel J. Bernstein */

#include <stdint.h>
#include "chacha20.h"

typedef uint32_t uint32;

uint32_t x[16] /*__attribute__((section(".ccm_data")))*/ = { 0 };
uint32_t j[16] /*__attribute__((section(".ccm_data")))*/ = { 0 };

int crypto_core_chacha20(
        unsigned char *out,
  const unsigned char *in,
  const unsigned char *k,
  const unsigned char *c
);

static const unsigned char /*__attribute__((section(".ccm_rodata")))*/ sigma[16] = "expand 32-byte k";
static unsigned char in[16] /*__attribute__((section(".ccm_data")))*/ = { 0 };
static unsigned char block[64] /*__attribute__((section(".ccm_data")))*/ = { 0 };
static unsigned char kcopy[32] /*__attribute__((section(".ccm_data")))*/ = { 0 };

/*__attribute__((section(".ccm")))*/
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
