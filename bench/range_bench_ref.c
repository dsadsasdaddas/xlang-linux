/* range_bench_ref.c — hand-written Sieve of Eratosthenes, the baseline that
 * range_bench.x (compiled by xlang) is compared against. Mirrors the xlang
 * program exactly: 32-bit int counters and the same overflow-safe
 * `p <= n / p` guard, so any timing gap is pure codegen + data-structure
 * difference (Vec<i32> 4 B/entry vs char[] 1 B/entry), not algorithm.
 *
 * Usage: range_bench_ref [N]   (default N = 1000000)
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char **argv) {
    int n = 1000000;
    if (argc >= 2) n = atoi(argv[1]);
    if (n < 2) { printf("0\n"); return 0; }

    char *comp = (char *)malloc((size_t)n);
    memset(comp, 0, (size_t)n);

    int count = 0;
    for (int p = 2; p < n; p++) {
        if (!comp[p]) {
            count++;
            if (p <= n / p) {
                for (int m = p * p; m < n; m += p) comp[m] = 1;
            }
        }
    }

    printf("%d\n", count);
    free(comp);
    return 0;
}
