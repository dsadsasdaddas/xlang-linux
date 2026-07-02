/* bitcount_bench_ref.c — hand-written baseline for bitcount_bench.x. Identical
 * algorithm (32-iteration popcount, i ^ (i>>3) mixing) so the timing gap is
 * pure codegen, not algorithm. Uses `unsigned` shift so the reference is
 * unambiguous; results match the xlang version (both examine all 32 bits).
 *
 * Usage: bitcount_bench_ref [N]   (default N = 10000000)
 */
#include <stdio.h>
#include <stdlib.h>

static int popcount(int x) {
    int c = 0;
    unsigned v = (unsigned)x;
    for (int b = 0; b < 32; b++) {
        if (v & 1u) c++;
        v >>= 1;
    }
    return c;
}

int main(int argc, char **argv) {
    int n = 10000000;
    if (argc >= 2) n = atoi(argv[1]);
    int total = 0;
    for (int i = 0; i < n; i++) {
        int v = i ^ (i >> 3);
        total += popcount(v);
    }
    printf("%d\n", total);
    return 0;
}
